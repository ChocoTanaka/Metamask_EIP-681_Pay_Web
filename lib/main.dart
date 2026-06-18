import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'reown.dart';
import 'Page1.dart';
import 'Page2.dart';
import 'Page3.dart';
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
      title: 'MetaMask JPYC Sub-Payment System',
      theme: ThemeData(
        fontFamily: "Noto Sans JP",
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MPSs_Stateful(),
    );
  }
}


class MPSs_Stateful extends StatefulWidget {
  const MPSs_Stateful({super.key});


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
          Appkit().addressNotifier.value = address;
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

  Widget MyDrawer(){
    return Drawer(
        child:ListView(
          padding: EdgeInsetsGeometry.all(5.0),
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple[200]),
              child: Text(
                "項目",
                style: TextStyle(
                    fontSize: 28
                ),
              ),
            ),
            ListTile(
              onTap: () {
                _onItemTapped(0);
              },
              leading: Icon(Icons.qr_code_2,size: 36),
              title: Text('Write',style: const TextStyle(fontSize: 24)),
            ),
            ListTile(
              onTap: () {
                _onItemTapped(1);
              },
              leading: Icon(Icons.attach_money_outlined,size: 36),
              title: Text('Read',style: const TextStyle(fontSize: 24)),
            ),
            ListTile(
              onTap: () {
                _onItemTapped(2);
              },
              leading: Icon(Icons.book,size: 36),
              title: Text('Index',style: const TextStyle(fontSize: 24)),
            ),
          ],
        )
    );
  }

  Widget build(BuildContext context) {
    final _screens = [
      Page2(),
      Page1(),
      Page3()
    ];

    // 各画面のタイトルのリスト
    final List<String> _titles = [
      'WriteQR Metamask JPYC Sub-Payment System',
      'ReadQR Metamask JPYC Sub-Payment System',
      'Index Metamask JPYC Sub-Payment System'
    ];

    const double targetWidth = 1200.0; // 固定したいPCの横幅


    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: PreferredSize(
            preferredSize: Size.fromHeight(60.0),
            child: AppBar(
              title: Text(_titles[_selectedIndex]), // 親のAppBarのタイトルを動的に変える
              backgroundColor: Colors.deepPurple[200],
            ),
        ),
        drawer: MyDrawer(),
        backgroundColor: Colors.grey[300],
        body: LayoutBuilder(
          builder: (context, constraints) {
            return   Center(
              child: InteractiveViewer(
                alignment: Alignment.center,
                constrained: false,
                minScale: 0.5,      // 最小縮小倍率（ピンチインで全体を見渡せるようにする）
                maxScale: 1.0,      // 最大拡大倍率
                child: Container(
                  // ここでPC基準のサイズ（キャンバスの大きさ）を完全に固定する
                  width: constraints.maxWidth >= 1000 ? constraints.maxWidth : 1000,
                  height: constraints.maxHeight,
                  color: Colors.white,
                  child: _screens[_selectedIndex],
                ),
              ),
            );
          }
        ),
        floatingActionButton: ValueListenableBuilder(
            valueListenable: Appkit().addressNotifier,
            builder: (context, address, _){
              return FloatingActionButton(
                isExtended: true,
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
                child: const Icon(Icons.cable,size: 36),
                backgroundColor: Appkit().userAddress.isNotEmpty ? Colors.blue : Colors.grey[200],
              );
            }
        )
    );
  }
}