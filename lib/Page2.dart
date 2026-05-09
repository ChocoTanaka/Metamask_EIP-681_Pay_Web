import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'reown.dart';
import 'Web3.dart';


class Page2 extends StatefulWidget {
  const Page2({super.key, required this.title});

  final String title;

  @override
  State<Page2> createState() => _MPSsState_Write();
}

class _MPSsState_Write extends State<Page2> {

  final TextEditingController amountController = TextEditingController();
  final TextEditingController tag1 = TextEditingController();
  final TextEditingController tag2 = TextEditingController();
  final TextEditingController tag3 = TextEditingController();
  final TextEditingController tag4 = TextEditingController();
  final TextEditingController tag_name = TextEditingController();

  late String tag1_s = "",tag2_s = "",tag3_s = "",tag4_s ="", tag_name_s = "";
  String? generatedUri;
  int amount = 0;
  bool isShow = false;
  bool isTag = false;

  String URI(BigInt Wei, String tag){
    String uri = 'ethereum:$JPYCAddress@137/transfer?address=${Appkit().userAddress}&uint256=$Wei';
    if(tag.isNotEmpty && tag.length ==16){
      uri += '&tag=$tag';
    }
    return uri;
  }


  @override
  void initState(){
    super.initState();
  }

  Widget Left_View(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          '請求書',
          style: const TextStyle(fontSize: 36),
        ),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Text(
              tag_name_s,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 20),
            Text(
              '様',
              style: const TextStyle(fontSize: 28),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Text(
              '請求額：',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Text(
                  amount.toString(),
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  'JPYC',
                  style: const TextStyle(fontSize: 28),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Text(
              '請求書番号：',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 20),
            Text(
              '${tag1_s} - ${tag2_s} - ${tag3_s} - ${tag4_s}',
              style: const TextStyle(fontSize: 28),
            )
          ],
        ),
        const SizedBox(height: 30),
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2), // 黒い枠線
          ),
          child: QrImageView(
            data: generatedUri!,
            size: 250,
          ),
        ),
      ],
    );
  }

  Widget Right_View(){
    return Column(
      children: [
        Row(
          children: [
            Text(
              "Address:",
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 10),
            Text(
              Appkit().userAddress.isNotEmpty ? maskMiddle(Appkit().userAddress, head: 6, tail: 6) : "Not Connected",
              style: const TextStyle(fontSize: 28),
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
        const SizedBox(height: 50),
        Row(
          children: [
            Flexible(
                child: Row(
                  children: <Widget>[
                    Flexible(
                        child: Row(
                          children: [
                            Flexible(
                                child: Row(
                                  children: [
                                    Text(
                                      "宛名:",
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        textAlign: TextAlign.center,
                                        controller: tag_name,
                                        onChanged: (text)=> setState(() {
                                          tag_name_s =tag_name.text;
                                        }),
                                        style: TextStyle(
                                          fontSize: 28,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                            )
                          ],
                        )
                    )
                  ],
                )
            )
          ],
        ),
        const SizedBox(height: 50),
        Row(
          children: [
            Flexible(
                child: Row(
                  children: <Widget>[
                    Text(
                      "tag:",
                      style: const TextStyle(fontSize: 28),
                    ),
                    Expanded(
                      child: TextFormField(
                          textAlign: TextAlign.center,
                          controller: tag1,
                          onChanged: (text)=> setState(() {
                            tag1_s =tag1.text;
                          }),
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 22,
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(4),
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]'),)
                          ]
                      ),
                    ),
                    Text(
                      "-",
                      style: const TextStyle(fontSize: 28),
                    ),
                    Expanded(
                      child: TextFormField(
                          textAlign: TextAlign.center,
                          controller: tag2,
                          onChanged: (text)=> setState(() {
                            tag2_s =tag2.text;
                          }),
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 22,
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(4),
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]'),)
                          ]
                      ),
                    ),
                    Text(
                      "-",
                      style: const TextStyle(fontSize: 28),
                    ),
                    Expanded(
                      child: TextFormField(
                          textAlign: TextAlign.center,
                          controller: tag3,
                          onChanged: (text)=> setState(() {
                            tag3_s =tag3.text;
                          }),
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 22,
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(4),
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]'),)
                          ]
                      ),
                    ),
                    Text(
                      "-",
                      style: const TextStyle(fontSize: 28),
                    ),
                    Expanded(
                      child: TextFormField(
                          textAlign: TextAlign.center,
                          controller: tag4,
                          onChanged: (text)=> setState(() {
                            tag4_s =tag4.text;
                          }),
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 22,
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(4),
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]'),)
                          ]
                      ),
                    )
                  ],
                )
            )
          ],
        ),
        const SizedBox(height: 50),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: amountController,
                onChanged: (text)=> setState(() {
                  amount =int.parse(amountController.text);
                }),
                decoration: const InputDecoration(
                  labelText: 'Amount (JPYC)',
                  border: UnderlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "JPYC",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black
              ),
            ),
          ],
        ),
        const SizedBox(height: 100),
        Container(
          width: 300,
          height:75,
          child: ElevatedButton(
              onPressed:() {
                if(Appkit().userAddress != "" &&
                    amount !=0
                ){
                  setState(() {
                    final BigInt amountWei = BigInt.from(amount * 1e18);
                    final tag = tag1_s+tag2_s+tag3_s+tag4_s;
                    final uri =
                    URI(amountWei,tag);
                    print(uri);
                    generatedUri = uri;

                    isShow = !isShow;
                  });
                }else{
                  null;
                }
              },
              child: Text(
                isShow ? "RESET" : "SET",
                style: TextStyle(
                    fontSize: 30,
                    color: Colors.black
                ),
              )
          ),
        )
      ],
    );
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
          child:Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: isShow == false ? const SizedBox.shrink() : Left_View()
              ),
              Expanded(
                flex: 1,
                child:Right_View()
              ),
            ],
          ),
      ),
    );
  }
}