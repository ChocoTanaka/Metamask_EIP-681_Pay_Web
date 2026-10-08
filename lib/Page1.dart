import 'dart:convert';

import 'package:flutter/services.dart';
import 'reown.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'Web3.dart';



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


  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
                "Metamask JPYC Sub-Payment System v2 Payment",
                style: const TextStyle(fontSize: 36),
            ),
            SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                    "管理番号：",
                  style: const TextStyle(fontSize: 28),
                ),
                Text(
                  EIP712Data().tag_read.isNotEmpty ? EIP712Data().tag_read : "NO DATA",
                  style: const TextStyle(fontSize: 28),
                ),
            ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "アドレス：",
                  style: const TextStyle(fontSize: 28),
                ),
                Text(
                  EIP712Data().Address_read.isNotEmpty ? EIP712Data().Address_read : "NO DATA",
                  style: const TextStyle(fontSize: 28),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "金額：",
                  style: const TextStyle(fontSize: 28),
                ),
                Text(
                  EIP712Data().wei_read != BigInt.from(0) ? EIP712Data().wei_read.toString() : "NO DATA",
                  style: const TextStyle(fontSize: 28),
                ),
              ],
            ),
            SizedBox(height: 100),
            Container(
              width: 200,
              height: 50,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    backgroundColor: (Appkit().userAddress !="") ? Colors.blue[200] : Colors.grey,
                  ),
                  onPressed: (){
                    print("こっから実験する");
                  },
                  child: Text(
                    '支払う',
                    style: const TextStyle(fontSize: 28),
                  )
              ),
            )

            ],
        )
    );
  }
}

