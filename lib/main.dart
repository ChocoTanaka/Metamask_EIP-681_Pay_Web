import 'dart:async';
import 'dart:io';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'reown.dart';
import 'Page1.dart';
import 'Page2.dart';
import 'Page3.dart';
import 'package:web/web.dart' as web;

// index.htmlの window.initReownApp をDartの関数として定義
@JS('initReownApp')
external void jsInitReownApp(JSString projectId);
// JSの関数を定義
@JS('connectMetaMask')
external JSPromise<JSString?> jsConnectMetaMask();
// 💡 window.getWalletAddress を定義
@JS('getWalletAddress')
external JSString? jsGetWalletAddress();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitForJsAndInit();
    });
    Appkit().addressNotifier.addListener(_handleAppKitUpdate);
  }

  void _waitForJsAndInit() {
    // 💡 window 直下に 'initReownApp' というプロパティ（関数）が生えたかチェック
    final bool isJsReady = web.window.hasProperty('initReownApp'.toJS).toDart;

    if (isJsReady) {
      jsInitReownApp(const String.fromEnvironment("ProjectId").toJS);
    } else {
      // ② まだなら、JS側がロード完了したタイミング（イベント）を検知して実行する
      web.window.addEventListener('reown_script_ready', (web.Event event) {
        jsInitReownApp(const String.fromEnvironment("ProjectId").toJS);
      }.toJS);
      print("ready");
    }
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

  // 接続ボタンが押された時の非同期ロジック
  Future<void> onConnectPressed() async {
    try {
      // 💡 準備ができていなければ自動で待機し、準備ができ次第モーダルが開いて結果が返る
      final String? result = await connectWeb3();

      if (result == "OPENED") {
        print("モーダルが正常に開きました。ユーザーのウォレット操作を待っています...");
      } else {
        print("モーダルの起動に失敗、またはキャンセルされました。");
      }
    } catch (e) {
      print("ウォレット接続処理中にエラーが発生しました: $e");
    }
  }

  Future<String?> connectWeb3() async {
    final completer = Completer<String?>();
    // ① すでにJS側の関数（connectMetaMask）が存在するかチェック
    final bool isFnReady = web.window
        .hasProperty('connectMetaMask'.toJS)
        .toDart;
    if (isFnReady) {
      try {
        // JSの関数を呼び出し（PromiseをawaitするためにtoDartを使用）
        final JSString? result = await jsConnectMetaMask().toDart;

        if (result != null) {
          // JavaScriptからアドレスを取得
          final JSString? jsAddress = jsGetWalletAddress();

          if (jsAddress != null) {
            final String address = jsAddress.toDart;
            print("現在のウォレットアドレスを取得しました: $address");

            if (address == "NOT_INSTALLED") {
              print("MetaMaskが見つかりません");
            } else {
              Appkit().addressNotifier.value = address;
            }
          }
        }
      } catch (e) {
        print("JS Interop Error: $e");
      }
    } else {
      print("⏳ JS版の接続関数がまだ未定義のため、ロードを待機します...");

      // ② まだ準備ができていなければ、100msごとに監視して生えてきた瞬間に実行する
      Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        final bool isNowReady = web.window
            .hasProperty('connectMetaMask'.toJS)
            .toDart;
        if (isNowReady) {
          timer.cancel(); // 監視をストップ
          print("ready");
          try {
            // JSの関数を呼び出し（PromiseをawaitするためにtoDartを使用）
            final JSString? result = await jsConnectMetaMask().toDart;

            if (result != null) {
              final String address = result.toDart;
              completer.complete(result.toDart);
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
      });
    }
    return completer.future;
  }



  @override
  void dispose() {
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
                  height: constraints.maxHeight >=700 ? constraints.maxHeight : 700,
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
                  if(Appkit().userAddress.isEmpty){
                    await onConnectPressed(); // これだけで MetaMask が起動し、userAddress に値が入る
                    print('Connected Address: ${Appkit().userAddress}');
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