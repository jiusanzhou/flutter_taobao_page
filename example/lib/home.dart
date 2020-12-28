import 'package:flutter/material.dart';
import 'package:flutter_taobao_page/action_page.dart';
import 'package:flutter_taobao_page/taobao/pc.dart';
import 'package:flutter_taobao_page/taobao/login.dart';
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

  H5PasswordTaobaoLoginPage _loginPage = H5PasswordTaobaoLoginPage(
    onLoginPageOpend: (_) {
      print("打开了登录页面 => $_");
    },
    onUserLogon: (_) {
      print("可以验证号了");
    },
  );

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
          ],
        ),
      ),
      body: TaobaoPage(
        onCreated: (TaobaoPageController controller) {
          // 淘宝控制器
          _controller = controller;
        },
        loginPage: _loginPage,
        child: Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _loginPage.isLogin?_startProcess():_loginPage.open(context);

          // Navigator.push(context, MaterialPageRoute(builder: (context) => DebugWebview()));

        }, child: Icon(Icons.add),
      ),
    );
  }

  void _startProcess() async {
    // 开始准备去验证号
    print("开始去验号");

    // _controller.pages.forEach((element) { print("page url => ${element.url} - ${element.normalizeUrl}"); });

    // _controller.pcweb.vipScore().then((value) {
    //   print("[6] vipScore => $value");
    // }).catchError((e) {
    //   print("[error] vipScore => $e");
    // });
    
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

    _controller.pcweb.dispute().then((value) {
      print("[8] dispute => $value");
    }).catchError((e) {
      print("[error] dispute => $e");
    });

    _controller.pcweb.order(1).then((value) {
      print("[9] order => $value");
    }).catchError((e) {
      print("[error] order => $e");
    });
  }

  Future<dynamic> openPage(String url, String title, ActionJob act) {
    return _controller.openPage(url, options: PageOptions(visible: false, title: title)).then((page) {
      return page.doAction(act);
    });
  }
}