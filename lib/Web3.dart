import 'dart:convert';

final String JPYCAddress = "0xE7C3D8C9a439feDe00D2600032D5dB0Be71C3c29";

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
  final base = BigInt.from(10).pow(18);
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