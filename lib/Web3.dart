import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

final String JPYCAddress = "0xE7C3D8C9a439feDe00D2600032D5dB0Be71C3c29";

final JPYCDecimal = 18;

enum UriCheckError {
  notEVMUri,
  differentNetwork,
  invalidToken,
  invalidFormat,
  invalidDecimal,
  invalidFunction,
}

String errorMessage(UriCheckError e) {
  switch (e) {
    case UriCheckError.notEVMUri:
      return 'Not ERC-681 Recipt';
    case UriCheckError.differentNetwork:
      return 'Another Network';
    case UriCheckError.invalidToken:
      return 'Not JPYC';
    case UriCheckError.invalidFormat:
      return 'Invalid URI';
    case UriCheckError.invalidDecimal:
      return 'Invalid Digits';
    case UriCheckError.invalidFunction:
      return 'Unsupported Function';
  }
}

String filltag(String tag) {
  List<String> tags = [tag.substring(4*0,4*1),tag.substring(4*1,4*2),tag.substring(4*2,4*3),tag.substring(4*3,4*4)];
  return '${tags[0]} - ${tags[1]} - ${tags[2]} - ${tags[3]}';
}

UriCheckError? validateRawUri(String uri) {

  try {
    final req = parseErc681(uri);
    if (!uri.startsWith('ethereum:')) {
      return UriCheckError.notEVMUri;
    }

    if (req.chainId != 137) {
      return UriCheckError.differentNetwork;
    }

    if (!(req.token == JPYCAddress)) {
      return UriCheckError.invalidToken;
    }

    if (!isValid18Decimals(req.amount)) {
      return UriCheckError.invalidDecimal;
    }

    if (req.function != "transfer") {
      return UriCheckError.invalidFunction;
    }
  }catch(e){
    return UriCheckError.invalidFormat;
  }

  return null; // OK
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



void Convert(String inputHex, Class_index index){
  // 138文字目（インデックスだと138）から、パディング(0000)の手前までを切り出す
  String hexAddress = inputHex.substring(10, 74); // 64文字分（32バイト分）
  print(hexAddress);
  String address = "0x" + hexAddress.substring(24);
  print("抽出されたアドレス: $address");
  index.Address = address;

  String hexAmount = inputHex.substring(74, 74 + 64); // 64文字分（32バイト分）
  print(hexAmount);
  BigInt amount = hexToInt(hexAmount);
  BigInt decimals = BigInt.from(10).pow(JPYCDecimal);
  final BigInt amountWei = BigInt.from(amount / decimals);
  print("抽出された量: $amountWei");
  index.Amount = amountWei.toString();

  if(inputHex.length >138){
    String hexMarker = inputHex.substring(138, 138 + 32); // 32文字分（16バイト分）
    print(hexMarker);
    try{
      String invoiceID = utf8.decode(hexToBytes("0x" +hexMarker));
      print("抽出された管理番号: $invoiceID");
      index.tag = invoiceID;
    }catch(e){
      index.tag = "No TAG";
    }
  }else{
    index.tag = "No TAG";
  }
  index.isConvert = true;
  index.Status = "Completed.";
}

Future<String?> getInputDataDirectly(String txHash) async {
  final rpcUrl = "https://polygon.drpc.org"; // または別のRPC URL

  // 念のためハッシュを綺麗にする
  final cleanHash = txHash.trim().startsWith('0x') ? txHash.trim() : '0x${txHash.trim()}';

  try {
    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "method": "eth_getTransactionByHash",
        "params": [cleanHash],
        "id": 1
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['result'] != null && data['result']['input'] != null) {
        // ここで生（String型）の input データが確実に取れます！
        String inputData = data['result']['input'];
        return inputData; // "0xa9059cbb..."
      }
    }
    print(response.statusCode);
    return null;
  } catch (e) {
    print("RPC直叩きエラー: $e");
    return null;
  }
}


class Class_index{
  late String Status ="";
  late String hash = "";
  late String Address ="";
  late String Amount ="";
  late String tag ="";
  late bool isConvert = false;

  Class_index();

}

class indexController{
  final Class_index index;
  // 各行専用のコントローラーをクラス内に持たせる
  final TextEditingController hashController;

  indexController(String initialHash)
      : index = new Class_index(),
        hashController = TextEditingController(text: initialHash);

  void dispose(){
    hashController.dispose();
  }
}