import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'reown.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'Web3.dart';
import 'dart:js_interop';

@JS('sendTransactionJS')
external JSPromise<JSString?> _sendTransactionJS(JSAny tx);

class Page1 extends StatefulWidget {
  const Page1({super.key});


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
  final _controller = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal, // 連続検知を防ぐために速度を調整
    autoStart: true
  );


  Future<String> requestSignatureJS(Map<String, dynamic> tx) async {
    // DartのMapをJSオブジェクトに変換
    // js_interopのユーティリティを使って変換するか、単純なjs_util等を使用
    final jsTx = tx.jsify()!;

    final JSString? txHash = await _sendTransactionJS(jsTx).toDart;

    if (txHash != null) {
      print('Transaction Hash: ${txHash.toDart}');
      // 成功後の処理
      return "Success : ${txHash.toDart}";
    } else {
      print('Transaction failed or rejected');
      return "Failure";
    }
  }

  @override
  void initState(){
    super.initState();
  }

  @override
  void dispose() {
    // 画面を離れる時に必ずリソースを解放する
    _controller.dispose();
    super.dispose();
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
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Address: ${maskMiddle(tx_R.to)}",
                  style: TextStyle(
                    fontSize: 32.0,
                  ),
                  overflow: TextOverflow.ellipsis, // 長いテキストを省略
                ),
                const SizedBox(height: 20),
                tx_R.tag !="" &&  tx_R.tag.length == 16 ?
                Text(
                  "tag: ${filltag(tx_R.tag)}",
                  style: TextStyle(
                    fontSize: 32.0,
                  ),
                )
                    : SizedBox(),
                const SizedBox(height: 20),
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
          const SizedBox(height: 50),
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
              String hash = "";
              hash = await Appkit().RequestTx(tx);
              Navigator.pop(context);
              if(hash.isNotEmpty){
                Check_Hash(context, "送金完了", hash);
              }
            },
          )
        ],
      );
    });
  }

  void Check_Hash(BuildContext context, String title, String hash) {
    showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
          title: Text(
              title,
            style: TextStyle(
              fontSize: 36,
            ),
          ),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Tx hash:",
                style: TextStyle(
                  fontSize: 42,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hash,
                    style: TextStyle(
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 40),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 50),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: hash));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Text Copied")),
                      );
                    },
                  ),
                ],
              )
            ],
          ),
          actions: <Widget>[
            GestureDetector(
              child: const Text(
                  '閉じる',
                style: TextStyle(
                  fontSize: 36,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ]
      );
    },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }


  SizedBox Camera_Viewer(){
    switch(i_situ){
      case 0:
        return SizedBox(
            height:400,
            width:400,
            child: Center(
                child:ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Appkit().userAddress !="" ? Colors.deepPurple[200] : Colors.grey
                  ),
                  onPressed: () async{
                    if(Appkit().userAddress !="") {
                      setState(() {
                        i_situ = 1;
                      });
                    }
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
          height:400,
          width:400,
          child: MobileScanner(
            controller: _controller, // ここで指定
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              // 最初のバーコードを取得
              final String? code = barcodes.first.rawValue;
              if (code == null) return;

              // i_situ が 1（待機中）の時だけ処理を行う
              if (i_situ == 1) {
                // 1. まずカメラを止める（Webでの安定動作に重要）
                await _controller.stop();
                // 1. 読み取り開始状態へ
                setState(() {
                  i_situ = 2;
                  Read_Text = "Now reading Tx...";
                });

                print("Scanned Code: $code");

                // 2. バリデーションチェック
                final error = validateRawUri(code);

                if (error != null) {
                  // --- エラーの場合 ---
                  setState(() {
                    Text_Error = errorMessage(error);
                    URI = "";
                  });

                  await Future.delayed(const Duration(milliseconds: 1500));

                  if (mounted) {
                    // カメラを再開
                    await _controller.start();
                    setState(() {
                      Text_Error = "";
                      i_situ = 1; // 読み取り待機に戻す
                    });
                  }
                } else {
                  // --- 成功の場合 ---
                  setState(() {
                    Text_Error = "";
                  });

                  await Future.delayed(const Duration(milliseconds: 1500));

                  if (mounted) {
                    setState(() {
                      URI = code;
                      Read_Text = "Checking Phase";
                      // 必要に応じてここで i_situ を次のステップへ進める
                    });
                  }
                }
              }
            },
          ),
        );
      case 2:
        return SizedBox(
            height:400,
            width:400,
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
            height:400,
            width:400,
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

