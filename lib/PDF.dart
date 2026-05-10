import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:printing/printing.dart';

Future makePdf(
    String Name,
    int amount,
    String tag1,String tag2,String tag3,String tag4,
    String uri,
    String Reciever
    ) async {
  final pdf = pw.Document();

  final fontData = await rootBundle.load('fonts/NotoSansJP-Regular.ttf');
  final font = pw.Font.ttf(fontData);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (pw.Context context) {
        return pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 20.0),
          child: pw.Text(
            "発行日: ${DateFormat('YYYY年 MM月 dd日', 'ja_JP').format(DateTime.now())}",
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        );
      },
      footer: (pw.Context context) {
        return pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20.0),
          child: pw.Column(
            children: [
              pw.Text(
                Reciever,
                style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        );
      },
      build: (pw.Context context) => [
        pw.Header(
          level: 0,
          child:pw.Text("請求書", style: pw.TextStyle(font: font, fontSize: 36)),
        ),
        pw.Divider(),
        pw.SizedBox(height: 20),
        pw.Text("$Name 様", style: pw.TextStyle(font: font,fontSize: 28)),
        pw.SizedBox(height: 20),
        pw.Text("金額: $amount JPYC", style: pw.TextStyle(font: font)),
        pw.Text("管理番号: ${tag1} - ${tag2} - ${tag3} - ${tag4}", style: pw.TextStyle(font: font,fontSize: 28)),
        pw.SizedBox(height: 20),
        pw.Text("ネットワーク: Polygon", style: pw.TextStyle(font: font)),
        pw.SizedBox(height: 50),
        pw.Container(
          width: 300,
          height: 300,
          child: pw.BarcodeWidget(
            data: uri, // ここにQRコードの文字列を渡す
            barcode: pw.Barcode.qrCode(), // QRコード形式を指定
            width: 250,
            height: 250,
          )
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
