import 'package:flutter/material.dart';
import 'reown.dart';
import 'Page1.dart';
import 'Page2.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appkit.appKitInit(context);
    });
    appkit.addressNotifier.addListener(_handleAppKitUpdate);
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

  @override
  void dispose() {
    appkit.Disconnect();
    super.dispose();
  }

  Widget build(BuildContext context) {


    final _screens = [
      Page2(title: 'WriteQR',address: appkit.userAddress),
      Page1(title: 'ReadQR',address: appkit.userAddress),
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
            valueListenable: appkit.addressNotifier,
            builder: (context, address, _){
              return FloatingActionButton(
                onPressed: () {
                  print("session");
                  print(appkit.appKitModal?.session);
                  appkit.Openview();
                },
                child: const Icon(Icons.cable),
                backgroundColor: address!= null ? Colors.blue : Colors.grey[200],
              );
            }
        )
    );
  }
}
