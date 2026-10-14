import 'dart:convert';
import 'package:web3dart/web3dart.dart';
import 'package:convert/convert.dart';
import "dart:js_interop";

@JS('sendTransactionJS')
external JSPromise<JSString?> _sendTransactionJS(JSString to, JSString data);

@JS('writeContractJS')
external JSPromise<JSString> _writeContractJS(JSString contractAddress,JSString abiJson,JSString functionName,JSString args);

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

  // 例: [tag16Int.toString(), amountWei.toString(), deadlineUnix.toString()] などをJSON化
  final argsJson = jsonEncode([tag16Int.toString(), amountWei.toString(), DeadlineUnix.toString()]);

  final txHash = await _writeContractJS(
      contract.toJS,
      abiJson_create.toJS,
      "registerInvoice".toJS,
      argsJson.toJS
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


