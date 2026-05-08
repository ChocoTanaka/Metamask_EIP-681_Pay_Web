import 'package:flutter/foundation.dart';
import 'reown.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'Web3.dart';
import 'dart:js_interop';

@JS('sendTransactionJS')
external JSPromise<JSString?> _sendTransactionJS(JSAny tx);

class Page1 extends StatefulWidget {
  const Page1({super.key, required this.title});

  final String title;

  @override
  State<Page1> createState() => _MPSsState_Read();
}

class _MPSsState_Read extends State<Page1> {

  int i_situ = 0;
  String Text_Error="";
  String Read_Text = "";
  String URI = "";
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  Future<void> requestSignatureJS(Map<String, dynamic> tx) async {
    // DartのMapをJSオブジェクトに変換
    // js_interopのユーティリティを使って変換するか、単純なjs_util等を使用
    final jsTx = tx.jsify()!;

    final JSString? txHash = await _sendTransactionJS(jsTx).toDart;

    if (txHash != null) {
      print('Transaction Hash: ${txHash.toDart}');
      // 成功後の処理
    } else {
      print('Transaction failed or rejected');
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    controller!.pauseCamera();
  }

  void _onQRViewCreated(QRViewController controller){
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async{
      if(i_situ==1){
        setState(() {
          i_situ=2;
          Read_Text = "Now reading Tx...";
        });
        result = scanData;
        print(result!.code);
        setState(() async{
          if(validateRawUri(result!.code!) != null){
            Text_Error = errorMessage(validateRawUri(result!.code!)!);
            URI = "";
            await Future.delayed(const Duration(milliseconds: 1500));
            setState(() {
              Text_Error = "";
              i_situ=1;
            });
          }else{
            Text_Error = "";
            await Future.delayed(const Duration(milliseconds: 1500));
            setState(() {
              URI = result!.code!;
              Read_Text = "Checking Phase";
            });
          }
        });

      }
    });
  }

  Future<void> CheckTx(BuildContext context, Erc681Request tx_R) async {
    await showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Tx Check'),
        content: SizedBox(
          width: double.maxFinite,
          height: 600,
          child: Container(
            width: 600,
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.black // 枠線の色を設定
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  "Address: ${maskMiddle(tx_R.to)}",
                  style: TextStyle(
                    fontSize: 32.0,
                  ),
                  overflow: TextOverflow.ellipsis, // 長いテキストを省略
                ),
                tx_R.tag !="" ?
                Text(
                  "tag: ${tx_R.tag}",
                  style: TextStyle(
                    fontSize: 32.0,
                  ),
                )
                    : SizedBox(),
                Text(
                  "${ShowAmount(tx_R.amount)} JPYC",
                  style: TextStyle(
                    fontSize: 32.0,
                  ),
                ),
                SizedBox(
                  height: 10,
                )
              ],
            ),
          ),
        ),
        actions: <Widget>[
          GestureDetector(
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 32,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          GestureDetector(
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 42,
              ),
            ),
            onTap: () async {
              final tx = buildTransaction(
                  from: Appkit().userAddress,
                  tokenAddress: tx_R.token,
                  to: tx_R.to,
                  amount: tx_R.amount,
                  tag: tx_R.tag
              );
              if(kIsWeb){
                // WebならJS Interop経由
                await requestSignatureJS(tx);
              }else{
                await Appkit().RequestTx(tx);
              }
              Navigator.pop(context);
            },
          )
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text(
                "Read ERC-681 Recipt",
                style: TextStyle(
                  fontSize: 24.0,
                ),
              ),
              Text(
                Text_Error,
                style: TextStyle(
                    fontSize: 22.0,
                    color: Colors.greenAccent[200]
                ),
              ),
              Camera_Viewer(),
              URI.isNotEmpty ?
              ElevatedButton(
                  onPressed: () async {
                    if(URI.isNotEmpty && Appkit().userAddress !=""){
                      setState(() {
                        Text_Error = "";
                        Read_Text = "Check Phase...";
                      });
                      final Tx = parseErc681(URI);
                      URI = "";
                      CheckTx(context,Tx).then((result) async{
                        await Future.delayed(const Duration(milliseconds: 1500));
                        setState(() {
                          i_situ = 0;
                          Read_Text = "";
                        });
                      });
                    }
                  },
                  child: Text(
                    "Check",
                    style: TextStyle(
                      fontSize: 24.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: (URI.isNotEmpty && Appkit().userAddress !="") ? Colors.deepPurple[200] : Colors.grey
                  )
              )
                  :
              const Padding(padding: EdgeInsets.all(10)),
            ],
          )
      ),
    );
  }

  SizedBox Camera_Viewer(){
    switch(i_situ){
      case 0:
        return SizedBox(
            height:500,
            width:500,
            child: Center(
                child:ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Appkit().userAddress !="" ? Colors.deepPurple[200] : Colors.grey
                  ),
                  onPressed: () {
                    setState(() {
                      if(Appkit().userAddress !=""){
                        i_situ = 1;
                      }
                    });
                  },
                  child: Text(
                    "Read_Start",
                    style: TextStyle(
                      fontSize: 26.0,
                    ),
                  ),
                )
            )
        );
      case 1:
        return SizedBox(
          height:500,
          width:500,
          child: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
          ),
        );
      case 2:
        return SizedBox(
            height:500,
            width:500,
            child: Center(
              child:Text(
                Read_Text,
                style: TextStyle(
                  fontSize: 26.0,
                ),
              ),
            )
        );
      default:
        return SizedBox(
            height:600,
            width:600,
            child: Center(
                child:ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Appkit().userAddress !="" ? Colors.deepPurple[200] : Colors.grey
                  ),
                  onPressed: () {
                    setState(() {
                      if(Appkit().userAddress !=""){
                        i_situ = 1;
                      }
                    });
                  },
                  child: Text(
                    "Read_Start",
                    style: TextStyle(
                      fontSize: 36.0,
                    ),
                  ),
                )
            )
        );
    }
  }
}

