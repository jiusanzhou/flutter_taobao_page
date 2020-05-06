import 'dart:async';

import 'package:example/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_taobao_page/event.dart';
import 'package:flutter_taobao_page/hack.dart';
import 'package:flutter_taobao_page/taobao/h5.dart';
import 'package:flutter_taobao_page/taobao_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '淘宝数据 Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primaryColor: Colors.blue,
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: '淘宝'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loading = true;
  bool _canFetch = false;

  bool _busy = false;

  List<List<String>> _orderTypes = [["", "全部"], ["waitConfirm", "待收货"]];

  Map<String, List<dynamic>> _allOrders = {};
  Map<String, int> _currentPages = {};
  Map<String, bool> _hasMores = {};

  TaobaoPageController _controller;

  void _fetchOrder(int index) {
    if (_busy) return;
    String type = _orderTypes[index][0];
    if (_hasMores[type]!=null&&!_hasMores[type]) {
      print("$index - $type 没有更多内容~");
      return;
    }

    setState(() {
      _busy = true;
    });
    int _page = _currentPages[type] ?? 0;
    _controller.pcweb.order(_page + 1, count: 5, type: type).then((data) {
      if (_allOrders[type] == null) _allOrders[type] = [];
    
      setState(() {
        _hasMores[type] = data["mainOrders"].length>=5;
      });

      _allOrders[type].addAll(data["mainOrders"]);
      print("====> request type: $type, index: $index");
      setState(() {
        _currentPages[type] = _page + 1;
      });
    }).catchError((_) {
      print("抓取第 $_page 页订单失败: $_");
    }).whenComplete((){
      setState(() {
        _busy = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return DefaultTabController(
      length: _orderTypes.length,
      initialIndex: 0,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              // Here we take the value from the MyHomePage object that was created by
              // the App.build method, and use it to set our appbar title.
              title: GestureDetector(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("${widget.title} v0.3.0"),
                    HackKeepAlive(),
                  ],
                ),
                onDoubleTap: () {
                  _controller.setDebug(!_controller.isDebug);
                },
              ),
              bottom: _canFetch ? AppBar(
                title: TabBar(
                  tabs: List.generate(_orderTypes.length, (index) => Tab(text: _orderTypes[index][1]))
                )
              ) : null,
              actions: <Widget>[
                IconButton(
                  onPressed: () {
                    _controller.pages[0].webviewController.reload();
                    setState(() {
                      _currentPages = {};
                      _loading = true;
                      _canFetch = false;
                      _allOrders = {};
                    });
                  },
                  icon: Icon(Icons.refresh),
                ),
              ],
            ),
            body: TaobaoPage(
              /// 抓取模块创建: 这里拿到controller
              onCreated: (TaobaoPageController controller) {
                _controller = controller;

                _controller.on<EventPageLoadStop>().listen((event) {
                  // 是否是登录页面
                  if (H5PageUrls.isLogin(event.url)) {
                    setState(() {
                      _loading = false;
                    });
                  }
                });
              },

              child: NotificationListener(
                onNotification: (ScrollNotification note) {
                  if (note.metrics.pixels == note.metrics.maxScrollExtent) {
                    _fetchOrder(DefaultTabController.of(context).index);
                  }
                  return true;
                },
                child: !_canFetch
                    ? Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: List.generate(
                          _orderTypes.length,
                          (index) => _buildItemListWidget(context, _orderTypes[index][0]),
                        )
                      ),
              ),
            ),
          );
        },
      )
    );
  }

  StreamController<Map<String, dynamic>> _transDataController = StreamController<Map<String, dynamic>>.broadcast();

  Widget _buildItemListWidget(BuildContext context, String type) {
    var _orders = _allOrders[type] ?? [];

    return CustomScrollView(
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              if (index == _orders.length) {
                return _buildMoreWidget(context);
              }
              Map<String, dynamic> order = _orders[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(width: 1.0, color: Colors.grey[200]),
                  ),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 0),
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                // color: Colors.lightBlue[100],
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("${order["seller"]["shopName"] ?? '未知'}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(order["id"], style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    FlatButton(
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                      onPressed: () {
                        // 加载数据
                        _loadTradeDetail("${order["id"]}");
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: Text('物流信息'),
                                  content: _buildTransWidget2(context),
                                  actions: <Widget>[
                                    FlatButton(
                                      child: Text('关闭'),
                                      onPressed: () {
                                        // reset
                                        // _transDataController.sink()
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                      child: Text("查看物流")
                    )
                  ],
                ),
              );
            },
            childCount: _orders.length + 1,
          ),
        ),
      ],
    );
  }

  void _loadTradeDetail(String orderId) async {
    print("===> 即将获取订单物流详情 $orderId");
    _controller.h5api.logisDetail(orderId).then((value) {
      print("得到订单物流详情 $value");
      _transDataController.add(value);
    }).catchError((e) {
      print("获取订单物流详情错误: $e");
    });
  }

  Widget _buildTransWidget2(BuildContext context) {
    return StreamBuilder(
      stream: _transDataController.stream,
      builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        return _buildTransWidget(context, snapshot.data);
      },
    );
  }

  // 物流信息
  Widget _buildTransWidget(BuildContext context, Map<String, dynamic> _currentTransData) {
    if (_currentTransData == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        ],
      );
    }

    if (_currentTransData["ret"][0]!="SUCCESS::调用成功") {
      // 失败
      return Container(
        child: Text(_currentTransData["ret"][0]),
        padding: EdgeInsets.all(20),
      );
    }

    Map<String, dynamic> order = _currentTransData["data"]["orderList"][0];
    List<dynamic> steps = order["transitList"]??[];

    return SingleChildScrollView(
      child: ListBody(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text("${order["partnerName"]}: ${order["subTitle2"]}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text("${order["subtitle1"]}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text("收获地址: ${order["addr"]}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          Column(
            children: List.generate(steps.length, (index) {
              Map<String, dynamic> info = steps[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(width: 1.0, color: Colors.grey[200]),
                  ),
                ),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("${info["message"]}"),
                    Text("${info["time"]}"),
                  ]
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Center(
            child: _busy?CircularProgressIndicator(strokeWidth: 2):Text("~加载更多~"),
          ),
        ],
      ),
    );
  }
}
