import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'reown.dart';
import 'Page1.dart';
import 'Page2.dart';
import 'dart:js_interop' as js;

// JSの関数を定義
@js.JS('connectMetaMask')
external js.JSPromise<js.JSString?> _connectMetaMask();

void main() {
  runApp(const MPSs());
}

class MPSs extends StatelessWidget {
  const MPSs({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MetaMask JPYC Payment Sub-system',
      theme: ThemeData(
        fontFamily: "Noto Sans JP",
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MPSs_Stateful(title: 'MetaMask Payment Sub-system'),
    );
  }
}


class MPSs_Stateful extends StatefulWidget {
  const MPSs_Stateful({super.key, required this.title});


  final String title;

  @override
  State<MPSs_Stateful> createState() => MPSs_Home();
}

class MPSs_Home extends State<MPSs_Stateful>{
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  initState() {
    super.initState();
    if(!kIsWeb && (Platform.isAndroid || Platform.isIOS)){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Appkit().appKitInit(context);
      });
    }
    Appkit().addressNotifier.addListener(_handleAppKitUpdate);
  }

  // 通知が来たら呼ばれる関数
  void _handleAppKitUpdate() {
    if (mounted) {
      setState(() {
        // これにより build メソッドが再実行され、
        // _screens 内のウィジェットが新しいアドレスで作成されます。
      });
    }
  }

  Future<void> connectWeb3() async {
    try {
      // JSの関数を呼び出し（PromiseをawaitするためにtoDartを使用）
      final js.JSString? result = await _connectMetaMask().toDart;

      if (result != null) {
        final String address = result.toDart;
        if (address == "NOT_INSTALLED") {
          print("MetaMaskが見つかりません");
        } else {
          print("Connected Address: $address");
          print("WRITING TO: ${Appkit().addressNotifier.hashCode}");
          Appkit().addressNotifier.value = address;
          print("Connected Address: ${Appkit().userAddress}");
        }
      }
    } catch (e) {
      print("JS Interop Error: $e");
    }
  }

  @override
  void dispose() {
    if(!kIsWeb && (Platform.isAndroid || Platform.isIOS)){
      Appkit().Disconnect();
    }
    Appkit().addressNotifier.removeListener(_handleAppKitUpdate); // メモリリーク防止
    super.dispose();
  }

  Widget build(BuildContext context) {


    final _screens = [
      Page2(title: 'WriteQR'),
      Page1(title: 'ReadQR'),
    ];

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body:Row(
          children: <Widget>[
            NavigationRail(
                destinations: [
                  NavigationRailDestination(icon: Icon(Icons.qr_code_2), label: Text('Write')),
                  NavigationRailDestination(icon: Icon(Icons.attach_money_outlined),label: Text('Read')),
                ],
                labelType: NavigationRailLabelType.all,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
            ),
            Expanded(
              child: _screens[_selectedIndex]
            ),
          ],
        ),

        floatingActionButton: ValueListenableBuilder(
            valueListenable: Appkit().addressNotifier,
            builder: (context, address, _){
              return FloatingActionButton(
                onPressed: () async{
                  if (kIsWeb) {
                    await connectWeb3(); // これだけで MetaMask が起動し、userAddress に値が入る
                    print('Connected Address: ${Appkit().userAddress}');
                  } else {
                    print("session");
                    print(Appkit().appKitModal?.session);
                    // Androidなどは従来通り
                    Appkit().Openview();
                  }
                },
                child: const Icon(Icons.cable),
                backgroundColor: Appkit().userAddress.isNotEmpty ? Colors.blue : Colors.grey[200],
              );
            }
        )
    );
  }
}
