import 'package:flutter/material.dart';
import 'package:flutter_taobao_page/action_page.dart';
import 'package:flutter_taobao_page/event.dart';
import 'package:flutter_taobao_page/taobao/pc.dart';
import 'package:flutter_taobao_page/taobao_page.dart';

class HomePage extends StatefulWidget {

  final String title;

  HomePage({Key key, this.title}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  TaobaoPageController _controller;

  @override
  void initState() {
    super.initState();
  }

  List<List<String>> _tabbar = [
    [ "认证", "" ],
    [ "评价", PCPageUrls.rateScore ],
    [ "退款", PCPageUrls.dispute ],
    [ "订单", PCPageUrls.order ],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.max,
          // mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              child: GestureDetector(
                child: Text("${widget.title} ${_controller?.pageGroups?.length??0}"),
                onDoubleTap: () {
                  _controller.setDebug(!_controller.isDebug);
                },
              ),
            ),
            DefaultTabController(
              length: _tabbar.length,
              child: Container(
                margin: EdgeInsets.only(left: 5),
                child: TabBar(
                  isScrollable: true,
                  onTap: (int idx) {
                    _controller.showPageWithUrl(_tabbar[idx][1]);
                  },
                  tabs: List.generate(_tabbar.length, (i) {
                    return Tab(child: Text(_tabbar[i][0], style: TextStyle(fontSize: 11)));
                  }),
                ),
              ),
            ),
            // Container(
            //   margin: EdgeInsets.only(left: 5),
            //   child: _controller!=null?TabBar(
            //     isScrollable: true,
            //     controller: _controller.tabController,
            //     onTap: (int idx) {
            //       _controller.tabController.index = idx;
            //     },
            //     tabs: List.generate(_controller.pageGroups.length, (i) {
            //       return Tab(text: _controller.pageGroups[i][0].options.title??'我的淘宝');
            //     }),
            //   ):null,
            // ),
            // Row(
            //   children: List.generate(_tabbar.length, (i) => Tab(child: InkWell(onTap: (){
            //     _controller.showPageWithUrl(_tabbar[i][1]);
            //   }, child: Text(_tabbar[i][0])))),
            // ),
          ],
        ),
      ),
      body: TaobaoPage(
        onCreated: (TaobaoPageController controller) {
          // 淘宝控制器
          _controller = controller;

          _controller.on<EventTabControllerUpdate>().listen((event) {
            // 创建新页面了重新渲染
            print("tab controller updated ===>");
            setState(() { });
          });
        },
        onUserLogon: (_, data) {
          // 自动启动验号
          print("可以验证号了");
        },
        child: Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _startProcess();
        }, child: Icon(Icons.add),
      ),
    );
  }

  void _startProcess() async {
    // 开始准备去验证号
    print("开始去验号");
    
    // _controller.showPageWithUrl(PCPageUrls.certityInfo);
    // _controller.showPageWithUrl(PCPageUrls.dispute);

    // int index = 1;
    // _controller.pages.forEach((page) {
    //   int i = index;
    //   page.webviewController.getTitle().then((value) {
    //     print("第 $i 个标签的标题是 => $value");
    //   });
    //   index += 1;
    // });

    _controller.pcweb.userBaseInfo().then((value) {
      print("[1] user base info => $value");
    }).catchError((e) {
      print("[error] use base unfo => $e");
    });

    _controller.pcweb.accountProfile().then((value) {
      print("[2] account profile => $value");
    }).catchError((e) {
      print("[error] account profile => $e");
    });

    _controller.pcweb.accountSecurity().then((value) {
      print("[3] account security => $value");
    }).catchError((e) {
      print("[error] account security => $e");
    });

    _controller.pcweb.certityInfo().then((value) {
      print("[4] certityInfo => $value");
    }).catchError((e) {
      print("[error] certityInfo => $e");
    });

    _controller.pcweb.aliStar().then((value) {
      print("[5] aliStar => $value");
    }).catchError((e) {
      print("[error] aliStar => $e");
    });

    _controller.pcweb.vipScore().then((value) {
      print("[6] vipScore => $value");
    }).catchError((e) {
      print("[error] vipScore => $e");
    });

    _controller.pcweb.rateScore().then((value) {
      print("[7] rateScore => $value");
    }).catchError((e) {
      print("[error] rateScore => $e");
    });

    // _controller.pcweb.dispute().then((value) {
    //   print("[error] dispute => $e");
    // });

    // 订单信息
    // _controller.openPage(PCPageUrls.order, options: PageOptions(visible: true, title: "订单信息")).then((value) {
    //   _controller.pcweb.order(1).then((value) {
    //     print("order => $value");
    //   }).catchError((e) {
    //     print("[error] order => $e");
    //   });
    // }); //   print("[8] dispute => $value");
    // }).catchError((e) {
   

    // 评价
    // openPage(PCPageUrls.rateScore, "评价", PCWeb.rateScoreAction).then((value) {
    //   print("[7] dispute => $value");
    // });

    // 退款管理
    openPage(PCPageUrls.dispute, "退款管理", PCWeb.disputeAction).then((value) {
      print("[8] dispute => $value");
    });
  }

  Future<dynamic> openPage(String url, String title, ActionJob act) {
    return _controller.openPage(url, options: PageOptions(visible: false, title: title)).then((page) {
      return page.doAction(act);
    });
  }
}