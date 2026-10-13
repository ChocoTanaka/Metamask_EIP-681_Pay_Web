import 'dart:convert';
import 'package:web3dart/web3dart.dart';
import 'package:convert/convert.dart';
import "dart:js_interop";

@JS('sendTransactionJS')
external JSPromise<JSString?> _sendTransactionJS(JSString to, JSString data);

final String jpycAddress = "0xE7C3D8C9a439feDe00D2600032D5dB0Be71C3c29";

final String contract = "0x0a56120d6E1863cE8c80B78778675eCB761E9f19";

final jpycTokenAddress = EthereumAddress.fromHex(jpycAddress);
final JPYCDecimal = 18;

final contractAddress = EthereumAddress.fromHex(contract);

class EIP712Data{
  // 1. クラス内部で自分自身の唯一のインスタンスを作る
  static final EIP712Data _instance = EIP712Data._internal();

  // 2. コンストラクタが呼ばれたら、必ず上のインスタンスを返す
  factory EIP712Data() {
    return _instance;
  }

  // 3. 内部用コンストラクタ
  EIP712Data._internal();

  late String wei_read = "";
  late String Address_read = "";
  late String tag_read ="";

  bool GotStatus(){
    if(this.wei_read !="" && this.tag_read !="" && this.Address_read !=""){
      return true;
    }
    return false;
  }
}

// 1. ERC-20 の approve 関数用 ABI
const erc20AbiMap = [
  {
    "inputs": [
      {"name": "spender", "type": "address"},
      {"name": "amount", "type": "uint256"}
    ],
    "name": "approve",
    "outputs": [
      {"name": "", "type": "bool"}
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

String generateApproveCallData(BigInt trueamount) {
  // Sepolia JPYC トークンのコントラクトアドレス

  // DeployedContract の作成
  final jpycContract = DeployedContract(
    ContractAbi.fromJson(jsonEncode(erc20AbiMap), 'ERC20'),
    jpycTokenAddress,
  );

  // ★ ここで approve 関数オブジェクト（approveFunction）を取得！
  final approveFunction = jpycContract.function('approve');

  // Call Data のエンコード
  final approveCallData = approveFunction.encodeCall([
    contractAddress,
    trueamount,
  ]);

  print('Approve CallData: 0x${hex.encode(approveCallData)}');
  return "0x${hex.encode(approveCallData)}";
}

const AbiMap_Create =
[
  {
    "type": "function",
    "name": "registerInvoice",
    "inputs": [
      {"name": "tag16", "type": "uint256"},
      {"name": "amount", "type": "uint256"},
      {"name": "deadline", "type": "uint256"}
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
];
// jsonEncode で完全に文字列化してから渡す
final abiJson_create = jsonEncode(AbiMap_Create);
final contract_create = DeployedContract(
  ContractAbi.fromJson(abiJson_create, 'InvoiceTx'),
  contractAddress,
);

const AbiMap_Pay =
[
  {
    "type": "function",
    "name": "payInvoice",
    "inputs": [
      {"name": "payee", "type": "address"},
      {"name": "tag16", "type": "uint256"}
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
];
// jsonEncode で完全に文字列化してから渡す
final abiJson_pay = jsonEncode(AbiMap_Pay);
final contract_create2 = DeployedContract(
  ContractAbi.fromJson(abiJson_create, 'InvoiceTx'),
  contractAddress,
);

/*
const AbiMap_Status =
[
  {
    "type": "function",
    "name": "getInvoiceStatus",
    "inputs": [
      {"name": "payee", "type": "address"},
      {"name": "tag16", "type": "uint256"}
    ],
    "outputs": [
      {"name": "", "type": "uint8"}
    ],
    "stateMutability": "view"
  }
];

// jsonEncode で完全に文字列化してから渡す
final abiJson_status = jsonEncode(AbiMap_Status);
final contract_create3 = DeployedContract(
  ContractAbi.fromJson(abiJson_create, 'InvoiceTx'),
  contractAddress,
);
*/

//インボイスの作成
Future<void>CreateInvoice({
  required String tag16,
  required BigInt amountWei,
  required BigInt DeadlineUnix
}) async{
// 文字列を 32 バイトの Uint8List (bytes32) にパディング

  BigInt tag16Int = BigInt.from(num.parse(tag16));

  final functionCall = contract_create.function('registerInvoice');
  final transactionData = functionCall.encodeCall([
    tag16Int,
    amountWei,
    DeadlineUnix
  ]);

  print('Encoded Transaction Data: 0x${hex.encode(transactionData)}');

  final String callDataHex = "0x${hex.encode(transactionData)}";

  final txHash = await _sendTransactionJS(
      contract.toJS,
      callDataHex.toJS
  ).toDart;
  print(txHash);
}

//支払
Future<void>Pay({
  required String Address,
  required String tag16,
  required BigInt amountWei
}) async{
  final Address_contract = EthereumAddress.fromHex(Address);
  BigInt tag16BInt = BigInt.from(num.parse(tag16));

  String approveCallDataHex = generateApproveCallData(amountWei);

  // 送信先 (to) は JPYC のアドレス！
  final approveTxHash = await _sendTransactionJS(
      jpycAddress.toJS,
      approveCallDataHex.toJS
  ).toDart;

  print('Approve 送信完了! Hash: ${approveTxHash?.toDart}');

  // ★重要: オンチェーンで Approve トランザクションが承認（Blockに採り込まれる）されるまで数秒待ちます
  print('Approve の承認待ち...');
  await Future.delayed(Duration(seconds: 15));

  // 4. トランザクションデータのエンコード (MetaMask等に渡すデータ)
  final functionCall = contract_create.function('createEscrow');
  final transactionData = functionCall.encodeCall([
    Address_contract,
    tag16BInt
  ]);

  print('Encoded Transaction Data: 0x${hex.encode(transactionData)}');

  final String callDataHex = "0x${hex.encode(transactionData)}";

  final txHash = await _sendTransactionJS(
      contract.toJS,
      callDataHex.toJS
  ).toDart;
  print(txHash);

}


//締め切りの次の日の00:00まで
BigInt SetDeadline(DateTime time){
  return BigInt.from((time.add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000));
}

BigInt SetWei(int Amount){
  BigInt Wei = BigInt.from(Amount) * BigInt.from(10).pow(JPYCDecimal);

  return Wei;
}


String filltag(String tag) {
  List<String> tags = [tag.substring(4*0,4*1),tag.substring(4*1,4*2),tag.substring(4*2,4*3),tag.substring(4*3,4*4)];
  return '${tags[0]} - ${tags[1]} - ${tags[2]} - ${tags[3]}';
}


bool isValid18Decimals(BigInt amount) {
  final base = BigInt.from(10).pow(JPYCDecimal);
  return amount % base == BigInt.zero;
}

String buildErc20TransferData(String to, BigInt amount, String tag) {
  // function selector
  final methodId = 'a9059cbb';

  // address（20byte → 32byte）
  final toClean = to.replaceFirst('0x', '');
  final toPadded = toClean.padLeft(64, '0');

  // amount（uint256 → 32byte）
  final amountHex = amount.toRadixString(16);
  final amountPadded = amountHex.padLeft(64, '0');

  String dat = '0x$methodId$toPadded$amountPadded';


  if(tag.isNotEmpty){
    dat += toHex(tag);
  }

  return dat;
}



String toHex(String tag) {
  final bytes = utf8.encode(tag);   // 文字列 → バイト列
  final hex = bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return hex.padRight(64,'0');
}


Map<String, dynamic> buildTransaction({
  required String from,
  required String tokenAddress,
  required String to,
  required BigInt amount,
  required String tag
}) {
  final data = buildErc20TransferData(to, amount,tag);

  return {
    "from": from,
    "to": tokenAddress,
    "data": data,
    "value": "0x0",
    "chainId": "0x89", // 137
    'gas': '0x493E0', // 1,000,000（送金のみならこれくらい）
    // 'gasPrice' ではなく、こちらを指定すると計算が早まる場合があります
    'maxFeePerGas': '0x746A528800', // 500 Gwei (環境に合わせて調整)
    'maxPriorityFeePerGas': '0x746A528800', // 500 Gwei
  };
}


class Erc681Request {
  final String token;
  final int chainId;
  final String function;
  final String to;
  final BigInt amount;
  final String tag;

  Erc681Request({
    required this.token,
    required this.chainId,
    required this.function,
    required this.to,
    required this.amount,
    required this.tag
  });

}

Erc681Request parseErc681(String uri) {
  final noScheme = uri.replaceFirst('ethereum:', '');

  final parts = noScheme.split('?');
  final path = parts[0];
  final query = Uri.splitQueryString(parts[1]);

  // 0x...@137/transfer
  final pathParts = path.split('/');
  final addressAndChain = pathParts[0];
  final function = pathParts[1];

  final addrSplit = addressAndChain.split('@');

  final token = addrSplit[0];
  final chainId = int.parse(addrSplit[1]);

  final to = query['address']!;
  final amount = parseScientific(query['uint256']!);

  final tag = query.containsKey('tag') ? query['tag']! : "";

  return Erc681Request(
      token: token,
      chainId: chainId,
      function: function,
      to: to,
      amount: amount,
      tag: tag
  );
}

BigInt parseScientific(String input) {
  if (!input.contains('e')) {
    return BigInt.parse(input);
  }

  final parts = input.split('e');
  final base = BigInt.parse(parts[0]);
  final exponent = int.parse(parts[1]);

  return base * BigInt.from(10).pow(exponent);
}

String ShowAmount(BigInt Amount, {int Div = 18}){
  final s = Amount.toString().padLeft(Div + 1, '0');

  var integer = s.substring(0, s.length - Div);
  var decimal = s.substring(s.length - Div);

  // 末尾ゼロ削除
  decimal = decimal.replaceFirst(RegExp(r'0+$'), '');

  // 先頭ゼロ削除（重要）
  integer = integer.replaceFirst(RegExp(r'^0+'), '');
  if (integer.isEmpty) integer = '0';

  return decimal.isEmpty ? integer : '$integer.$decimal';
}
