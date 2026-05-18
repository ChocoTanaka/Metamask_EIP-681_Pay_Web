import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:printing/printing.dart';

Future makePdf(
    String Name,
    bool isCompany,
    int amount,
    String tag1,String tag2,String tag3,String tag4,
    String uri,
    String Reciever
    ) async {
  final pdf = pw.Document();

  String s_isCompany(){
    return isCompany ? "様" : "御中";
  }

  final fontData = await rootBundle.load('assets/fonts/NotoSansJP-Regular.ttf');
  final font = pw.Font.ttf(fontData);

  final img = await rootBundle.load('assets/images/JPYCPay_192.png');
  final imageBytes = img.buffer.asUint8List();

  final now = DateTime.now();
  final dateFormatter = DateFormat('yyyy年　MM月　dd日');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (pw.Context context) {
        return pw.Container(
          alignment: pw.Alignment.topRight,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  alignment: pw.Alignment.center,
                  height: 40,
                  child: pw.Image(pw.MemoryImage(imageBytes))
                ),
                pw.Text(
                  "発行日: ${dateFormatter.format(now)}",
                  style: pw.TextStyle(font: font, fontSize: 15),
                ),
              ]
          ),
        );
      },
      footer: (pw.Context context) {
        return pw.Container(
          alignment: pw.Alignment.bottomRight,
          child: pw.Column(
            children: [
              pw.Text(
                Reciever,
                style: pw.TextStyle(font: font, fontSize: 15, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        );
      },
      build: (pw.Context context) => [
        pw.Header(
          level: 0,
          child:pw.Text("支払用紙", style: pw.TextStyle(font: font, fontSize: 36)),
        ),
        pw.SizedBox(height: 10),
        pw.Text("$Name　${s_isCompany}", style: pw.TextStyle(font: font,fontSize: 20)),
        pw.SizedBox(height: 20),
        pw.Text("金額: $amount JPYC", style: pw.TextStyle(font: font,fontSize: 20)),
        pw.Text("管理番号: ${tag1} - ${tag2} - ${tag3} - ${tag4}", style: pw.TextStyle(font: font,fontSize: 20)),
        pw.SizedBox(height: 20),
        pw.Text("ネットワーク: Polygon", style: pw.TextStyle(font: font,fontSize: 20)),
        pw.SizedBox(height: 30),
        pw.Center(
          child: pw.Text(
              "以下のバーコードを Metamask JPYC Sub-Payment Systemで読み込んでお支払いください。", style: pw.TextStyle(font: font,fontSize: 20)
          ),
        ),
        pw.SizedBox(height: 30),
        pw.Center(
          child: pw.Container(
              width: 300,
              height: 300,
              child: pw.BarcodeWidget(
                data: uri, // ここにQRコードの文字列を渡す
                barcode: pw.Barcode.qrCode(), // QRコード形式を指定
                width: 250,
                height: 250,
              )
          ),
        ),
      ],
    )
  );
  // Web版でPDFを表示・ダウンロードさせる
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: '請求書:${Name}_${tag1}-${tag2}-${tag3}-${tag4}.pdf',
  );
}
