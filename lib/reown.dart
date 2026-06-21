import "dart:async";
import "dart:js_interop";
import "dart:js_interop_unsafe";
import 'package:web/web.dart' as web;
import "package:flutter/material.dart";


String maskMiddle(String text, {int head = 6, int tail = 6}) {
  if (text.length <= head + tail) {
    return text; // 短すぎる場合はそのまま
  }
  return text.substring(0, head) +
      '...' +
      text.substring(text.length - tail);
}

// index.htmlの window.initReownApp をDartの関数として定義
@JS('initReownApp')
external void jsInitReownApp(JSString projectId);
// JSの関数を定義
@JS('connectMetaMask')
external JSPromise<JSString?> jsConnectMetaMask();
// 💡 window.getWalletAddress を定義
@JS('getWalletAddress')
external JSString? jsGetWalletAddress();
// 💡 window.disconnectWalletJS を定義
@JS('disconnectWalletJS')
external JSPromise<JSBoolean> jsDisconnectWalletJS();
@JS('sendTransactionJS')
external JSPromise<JSString?> _sendTransactionJS(JSAny tx);
class Appkit{
// 1. クラス内部で自分自身の唯一のインスタンスを作る
  static final Appkit _instance = Appkit._internal();

  // 2. コンストラクタが呼ばれたら、必ず上のインスタンスを返す
  factory Appkit() {
    return _instance;
  }

  // 3. 内部用コンストラクタ
  Appkit._internal();

  // 4. これが共有される唯一の箱
  final ValueNotifier<String> addressNotifier = ValueNotifier<String>("");

  String get userAddress => addressNotifier.value;


  void waitForJsAndInit() {
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
        print("ウォレット処理を開始します...");

        // JSの関数を呼び出し、Promiseが解決するのを待つ（新規なら承認待ち、接続済みなら即返る）
        final JSString? result = await jsConnectMetaMask().toDart;

        if (result != null) {
          final String address = result.toDart;
          print("ウォレットアドレスを認識しました: $address");

          if (address == "NOT_INSTALLED") {
            print("MetaMaskが見つかりません");
          } else {
            // 取れたアドレスをAppkitの状態管理（Notifier）に安全に注入
            Appkit().addressNotifier.value = address;
          }
        } else {
          print("接続がキャンセルされたか、タイムアウトしました。");
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
            print("ウォレット処理を開始します...");

            // JSの関数を呼び出し、Promiseが解決するのを待つ（新規なら承認待ち、接続済みなら即返る）
            final JSString? result = await jsConnectMetaMask().toDart;

            if (result != null) {
              final String address = result.toDart;
              print("ウォレットアドレスを認識しました: $address");

              if (address == "NOT_INSTALLED") {
                print("MetaMaskが見つかりません");
              } else {
                // 取れたアドレスをAppkitの状態管理（Notifier）に安全に注入
                Appkit().addressNotifier.value = address;
              }
            } else {
              print("接続がキャンセルされたか、タイムアウトしました。");
            }
          } catch (e) {
            print("JS Interop Error: $e");
          }
        }
      });
    }
    return completer.future;
  }

  Future<void> logoutWallet() async {
    try {
      // JSの切断処理を呼び出して await する
      final JSBoolean isSuccess = await jsDisconnectWalletJS().toDart;

      if (isSuccess.toDart) {
        print("ウォレットの接続解除に成功しました！");
        // ここでDart側の状態（アドレス保持用変数など）をクリアする
      } else {
        print("ウォレットの接続解除に失敗しました。");
      }
    } catch (e) {
      print("切断処理中にエラーが発生しました: $e");
    }
  }

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
}