import 'Web3.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Page3 extends StatefulWidget {
  const Page3({super.key, required this.title});

  final String title;

  @override
  State<Page3> createState() => _MPSsState_Index();
}

class _MPSsState_Index extends State<Page3> {
  bool isShow = false;
  final ScrollController _scrollController_R = ScrollController();
  final ScrollController _scrollController_L = ScrollController();

  List<indexController> List_index = [];

  void Clean_index(){
    List_index.clear();
  }


  Widget indexlist(int i){
    return Row(
      children: <Widget>[
        Text(
          "TxHash:",
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: TextFormField(
            textAlign: TextAlign.center,
            controller: List_index[i].hashController,
            onChanged: (text)=> setState(() {
              List_index[i].index.hash = text;
            }),
            style: TextStyle(
              fontSize: 24,
            ),
          ),
        ),
        const SizedBox(height: 100),
        IconButton(
          icon: const Icon(Icons.add, size: 28),
          onPressed: () {
            if(isShow == false){
              if(List_index[i].index.hash.isNotEmpty){
                setState(() {
                  List_index.add(new indexController(""));
                });
              }
            }
          },
        ),
      ],
    );
  }

  Widget Right_View() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text("索引",
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(height: 20),
        Expanded(
            child: Scrollbar(
              controller: _scrollController_R,
              child: SingleChildScrollView(
                controller: _scrollController_R,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: List_index.length,
                  itemBuilder: (context, index) {
                    return Table(
                        children: [
                          TableRow(
                              children: [
                                indexlist(index)
                              ]
                          )
                        ]
                    );
                  },
                ),
              ),
            ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              backgroundColor: Colors.blue[200],
            ),
            onPressed:() async{
              for(var C_index in List_index){
                if(C_index.index.hash.isNotEmpty){
                  if(C_index.index.isConvert == false){
                    String? inputHex = await getInputDataDirectly(C_index.index.hash);
                    Convert(inputHex!, C_index.index);
                  }
                }
              }

              setState(() {
                isShow =! isShow;
              });
            },
            child: Text(
              isShow ? '編集' : '検索',
              style: const TextStyle(fontSize: 28),
            )
        )
      ],
    );
  }

  Widget Left_View() {
    return Scrollbar(
      controller: _scrollController_L,
      child: SingleChildScrollView(
        controller: _scrollController_L,
        child: ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: List_index.length,
          itemBuilder: (context, i) {
            return Table(
                children: [
                  TableRow(
                    children: [
                      indexContainer(i, List_index[i])
                    ]
                )
              ]
            );
          },
          separatorBuilder: (context, index) => SizedBox(height: 16), // ここで間隔を指定
        ),
      )
    );
  }

  Widget indexContainer(int num, indexController Index){
    return Container(
      width: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "${(num+1).toString()}:",
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 20),
          Text(
            "Status: ${Index.index.Status}",
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Address: ${Index.index.Address}",
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: () {
                  // クリップボードにテキストをコピー
                  Clipboard.setData(ClipboardData(text: Index.index.Address));
                  // スナックバーを表示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('テキストがクリップボードにコピーされました')),
                  );
                },
                icon: const Icon(Icons.copy, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "支払額: ${Index.index.Amount} JPYC",
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          Text(
            Index.index.tag.isNotEmpty && Index.index.tag.length == 16
            ? "tag: ${filltag(Index.index.tag)}"
            : "no tag or Undefined tag",
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController_R.dispose();
    _scrollController_L.dispose();
    List_index.forEach((i){
      i.dispose();
    });
    super.dispose();
  }

  @override
  void initState(){
    super.initState();
    Clean_index();
    List_index.add(new indexController(""));
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
                flex: 3,
                child: isShow == false ? const SizedBox.shrink() : Left_View()
            ),
            Expanded(
                flex: 2,
                child:Right_View()
            ),
          ],
        ),
      ),
    );
  }
}