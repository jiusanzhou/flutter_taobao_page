import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("${widget.title} v0.3.0"),
            ],
          ),
          onDoubleTap: () {
            // _controller.toggleWebview();
          },
        ),
      ),
      body: TaobaoPage(
        onCreated: (TaobaoPageController controller) {
          // 淘宝控制器
          _controller = controller;
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

  void _startProcess() {
    // 开始准备去验证号
    print("开始去验号");
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

    // _controller.pcweb.order(1).then((value) {
    //   print("order => $value");
    // }).catchError((e) {
    //   print("[error] order => $e");
    // });
  }
}