import "package:flutter/material.dart";
import "package:reown_appkit/reown_appkit.dart";


String maskMiddle(String text, {int head = 6, int tail = 6}) {
  if (text.length <= head + tail) {
    return text; // 短すぎる場合はそのまま
  }
  return text.substring(0, head) +
      '...' +
      text.substring(text.length - tail);
}

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


  ReownAppKitModal? appKitModal;

  Set<String> supportedWalletIds = <String>{
    'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask ID
  };

  Future appKitInit(BuildContext context) async {

    final appKit = await ReownAppKit.createInstance(
      projectId: const String.fromEnvironment("ProjectId"),

      metadata: const PairingMetadata(
        name: "JPYC Invoice App",
        description: "Generate EIP-681",
        url: "https://github.com/ChocoTanaka/Metamask_EIP-681_Pay_Web",
        icons: ['https://chocotanaka.github.io/Metamask_EIP-681_Pay_Web/assets/images/JPYCPay_512.png'],
        redirect: Redirect(
          //delete native
          universal: 'https://chocotanaka.github.io/Metamask_EIP-681_Pay_Web/'
        ),
      ),
    );

    appKitModal = ReownAppKitModal(
      context: context,
      appKit: appKit,
      includedWalletIds: supportedWalletIds,
      featuredWalletIds: supportedWalletIds,
    );

    print("Connecting to Relay...");
// initを呼ぶ前にCoreの状態を確認
    print("Relay Endpoint: ${appKitModal?.appKit?.core.relayUrl}");

    try {
      await appKitModal?.init();
    } on ReownAppKitModalException catch (e) {
      print("AppKitModal専用エラー: ${e.message}"); // ここに具体的な理由が出るはずです
    } catch (e) {
      print("その他のエラー: $e");
    }
    final isConnected = appKitModal?.appKit?.core.relayClient.isConnected ?? false;
    print("AppKit Initialized: $isConnected");


    appKitModal?.appKit?.onSessionConnect.subscribe((_) {
      final session = appKitModal?.session;
      if (session == null) {
        print('session is null');
        return;
      } else {
        final accounts =
            session.namespaces!['eip155']?.accounts ?? [];

        if (accounts.isEmpty) return;

        final address = accounts.first.split(':')[2];
        addressNotifier.value = address;
      }
    });
  }

  void Openview() async{
    if (appKitModal?.session != null) {
      await appKitModal?.disconnect();
    }
    print("WC URI: ${appKitModal?.wcUri}");
    await appKitModal?.openModalView();
  }

  void Disconnect() async{
    await appKitModal?.disconnect();
  }

  Future<String> RequestTx(Map<String, dynamic> tx) async{
    final response = await appKitModal?.request(
      topic: appKitModal?.session!.topic,
      chainId: 'eip155:137',
      request: SessionRequestParams(
          method: "eth_sendTransaction",
          params: [tx]
      ),
    );
    // 成功すると、トランザクションハッシュが返ってきます
    print('Transaction Hash: $response');
    return "Success : ${response.toString()}";
  }
}