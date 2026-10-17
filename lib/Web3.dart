import 'dart:convert';
import 'package:erc681pay_dx/reown.dart';

import "dart:js_interop";

@JS('writeContractJS')
external JSPromise<JSString> _writeContractJS(JSString contractAddress,JSString abiJson,JSString functionName,JSString args);

final String jpycAddress = "0xE7C3D8C9a439feDe00D2600032D5dB0Be71C3c29";

final String contract = "0xC09EA87910aE6B99A7FFC49Ca4BaF164E59D40ba";

final JPYCDecimal = 18;

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


const AbiMap_Create =
[
  {
    "type": "function",
    "name": "registerInvoice",
    "inputs": [
      {"name": "tag16", "type": "uint256"},
      {"name": "tokenAddress", "type": "address"},
      {"name": "amount", "type": "uint256"},
      {"name": "deadline", "type": "uint256"}
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
];
// jsonEncode で完全に文字列化してから渡す
final abiJson_create = jsonEncode(AbiMap_Create);

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


const AbiMap_approve =
[
  {
    "constant": false,
    "inputs": [
      {"name": "spender", "type": "address"},
      {"name": "amount", "type": "uint256"}
    ],
    "name": "approve",
    "outputs": [{"name": "", "type": "bool"}],
    "type": "function"
  }
];
// jsonEncode で完全に文字列化してから渡す
final abiJson_approve = jsonEncode(AbiMap_approve);

//インボイスの作成
Future<void>CreateInvoice({
  required String tag16,
  required BigInt amountWei,
  required BigInt DeadlineUnix
}) async{
// 文字列を 32 バイトの Uint8List (bytes32) にパディング

  BigInt tag16Int = BigInt.from(num.parse(tag16));

  // 例: [tag16Int.toString(), amountWei.toString(), deadlineUnix.toString()] などをJSON化
  final argsJson = jsonEncode([tag16Int.toString(),jpycAddress, amountWei.toString(), DeadlineUnix.toString()]);

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

  // 5. 引数の配列をJSON化
  final String argsJson = jsonEncode([
    contract,
    amountWei.toString(),
  ]);

  // 送信先 (to) は JPYC のアドレス！
  final approveTxHash = await _writeContractJS(
      jpycAddress.toJS,
      abiJson_approve.toJS,
      "approve".toJS,
      argsJson.toJS
  ).toDart;

  print('Approve 送信完了! Hash: ${approveTxHash.toDart}');

  // ★重要: オンチェーンで Approve トランザクションが承認（Blockに採り込まれる）されるまで数秒待ちます
  print('Approve の承認待ち...');
  await Future.delayed(Duration(seconds: 30));


  final argsJson_pay = jsonEncode([Address, tag16.toString()]);


  final txHash = await _writeContractJS(
      contract.toJS,
      abiJson_pay.toJS,
      "payInvoice".toJS,
      argsJson_pay.toJS
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


