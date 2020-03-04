library flutter_taobao_page;

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_taobao_page/utils.dart';

import 'utils.dart';
import 'utils.dart';
import 'utils.dart';
import 'utils.dart';
import 'utils.dart';
import 'utils.dart';
import 'utils.dart';
import 'utils.dart';

typedef void PageFinishCallback(InAppWebViewController controller, String url);

typedef void OnCreatedCallback(TaobaoPageController controller);
typedef void InitCallback();
typedef void ReadyCallback();

/// 淘宝数据webview.
/// !!!最小化实现，不要考虑太多.
class TaobaoPage extends StatefulWidget {
  /// 参数 `child` 不能为空
  TaobaoPage({
    Key key,
    @required this.child,
    this.loginPage = TaobaoUrls.loginPage,
    this.homePage = TaobaoUrls.homePage,
    this.orderPage = TaobaoUrls.orderPage,
    this.onCreated,
    this.onInit,
    this.onReady,
  })  : assert(child != null),
        super(key: key);

  /// iOS 和 Android 返回值有差异
  /// inapp 不需要
  final isAndroid = false; // Platform.isAndroid;

  /// 创建初始化函数
  final OnCreatedCallback onCreated;

  /// 初始化函数, 登录页面加载完成
  final InitCallback onInit;

  /// ready函数, 订单页数据可用
  final ReadyCallback onReady;

  /// 显示的内容,不能为空
  final Widget child;

  /// 数据页面地址
  final String loginPage;
  final String homePage;
  final String orderPage;

  @override
  _TaobaoPageState createState() => _TaobaoPageState();
}

class _TaobaoPageState extends State<TaobaoPage>
    with AutomaticKeepAliveClientMixin<TaobaoPage> {

  final Completer<TaobaoPageController> _controller =
      Completer<TaobaoPageController>();

  @override
  bool get wantKeepAlive => true;

  /// webview 控制器
  /// 后续所有操作都是通过她来进行
  InAppWebViewController _webview;

  /// TODO: 
  InAppWebViewController _webview2;

  /// 路径回调函数
  /// 通过注册的方式添加
  /// TODO: 封装,优化匹配规则
  Map<String, PageFinishCallback> _callbacks = {};

  /// js code
  String _jscode = "";

  /// 是否显示webview, 初始化的时候会设置,其他的时候也可以手动设置
  bool _showWebview = false;

  /// 是否已经登录
  /// TODO: add user infomation
  bool _isLogin = false;

  /// 订单抓取准备就绪
  /// TODO: hard code
  bool _ready;
  bool _ready2; // 详情页面就绪

  /// debug
  bool debug;

  /// 保存Cookies
  String Cookies;

  @override
  void initState() {
    super.initState();

    /// 添加默认的回调函数
    /// TODO: 注册成资源,所有的操作都可以通过资源的接口
    /// TODO: widget中的可以添加过来
    _callbacks[widget.loginPage] = _afterLoginPage;
    _callbacks[widget.homePage] = _afterHomePage;
    _callbacks[widget.orderPage] = _afterOrderPage;

    // webview2 也用这个, TODO: 更改状态
    _callbacks[TaobaoUrls.homePageMain] = null;

    _initAsync();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(Widget old) {
    super.didUpdateWidget(old);
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    _webview = controller;

    final TaobaoPageController m = TaobaoPageController._(this, _webview);
    _controller.complete(m);
    if (widget.onCreated != null) widget.onCreated(m);
  }

  /// 异步初始化
  void _initAsync() async {
    _jscode = TaobaoJsCode.orderPage;
  }

  /// 处理回调函数
  /// TODO: 使用精准方式匹配
  void _onPageFinished(InAppWebViewController controller, String url) {
    String _url = url.split("?")[0];
    PageFinishCallback fn = _callbacks[_url];
    if (fn != null) fn(_webview, url);
  }

  /// 登录页加载完成
  void _afterLoginPage(InAppWebViewController controller, String url) {
    /// 设置为显示webview
    setState(() {
      _showWebview = true;
      _showIndex = 1;
    });

    /// 插入js: 点击登录时自动隐藏webview

    if (widget.onInit != null) widget.onInit();
  }

  /// 主页加载完成
  void _afterHomePage(InAppWebViewController controller, String url) {
    setState(() {
      /// 这里隐藏
      _showWebview = false;
      _showIndex = 0;

      /// 设置登录成功
      _isLogin = true;
    });

    /// 加载到订单页面
    _webview.loadUrl(url: widget.orderPage);
  }

  /// 订单页加载完成
  void _afterOrderPage(InAppWebViewController controller, String url) async {

    /// 插入js: 插入函数可以获取订单
    _webview.evaluateJavascript(source: _jscode).then((_) {
      print("im.zoe.taobao_page [INFO] insert javascipt code");

      /// 设置为ready
      setState(() {
        _ready = true;
      });

      if (widget.onReady != null) widget.onReady();
    }).catchError((e) {
      print("im.zoe.taobao_page [ERROR] insert javascript code: $e");
    });
  }

  void _afterHomePageMain(InAppWebViewController controller, String url) async {
    _webview.evaluateJavascript(source: _jscode).then((_) {
      print("im.zoe.taobao_page [INFO] insert javascipt code");
    });
  }

  Map<String, Completer> _waitCompleters = {};

  /// 内容处理
  dynamic _onPostDataHandler(List<dynamic> arguments) {
    _waitCompleters.remove(arguments[0])?.complete(arguments[1]);
    return "";
  }

  /// 增加多个webview

  int _showIndex = 0;

  void toggleWebview({bool show}) {
    setState(() {
      // page max
      _showIndex = _showIndex == 2 ? 0 : (_showIndex+1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _showIndex,
      children: <Widget>[
        /// 显示内容
        widget.child,

        /// webview
        InAppWebView(
          initialUrl: widget.loginPage,
          initialOptions: InAppWebViewWidgetOptions(inAppWebViewOptions: InAppWebViewOptions(javaScriptEnabled: true)),
          onWebViewCreated: _onWebViewCreated,
          onLoadStop: _onPageFinished,
        ),

        /// TODO: 自动管理页面标签
        InAppWebView(
          initialUrl: TaobaoUrls.homePageMain, // 登录前前面不要做任何事情
          initialOptions: InAppWebViewWidgetOptions(inAppWebViewOptions: InAppWebViewOptions(javaScriptEnabled: true)),
          onWebViewCreated: (controller) {
            _webview2 = controller;
            _webview2.addJavaScriptHandler(handlerName: "PostData", callback: _onPostDataHandler);
          },
          onLoadStop: _onPageFinished,
        ),
      ],
    );
  }
}

/// 控制器
class TaobaoPageController {
  TaobaoPageController._(
    this._widget,
    this._webview,
  );

  _TaobaoPageState _widget;

  InAppWebViewController _webview;

  /// 获取订单数据
  /// TODO: 缓存
  Future<Map<String, dynamic>> getOrder(int page, {int count = 20, String type = ""}) async {
    /// 请求js
    var res =
        await _webview.evaluateJavascript(source: TaobaoJsCode.getOrder(page, count, type));

    /// 反序列化
    try {
      Map<String, dynamic> _map =
          _widget.widget.isAndroid ? json.decode(json.decode(res)) : json.decode(res);
      return _map;
    } catch (e) {
      return Future.error(e);
    }
  }

  /// 获取订单物流数据
  /// TODO: 缓存
  Future<Map<String, dynamic>> getTranSteps(String orderId) async {
    /// 请求js
    var res =
        await _webview.evaluateJavascript(source: TaobaoJsCode.getTranSteps(orderId));

    /// 反序列化
    try {
      Map<String, dynamic> _map = 
          _widget.widget.isAndroid ? json.decode(json.decode(res)) : json.decode(res);
      return _map;
    } catch (e) {
      return Future.error(e);
    }
  }

  /// 获取订单详情
  Future<dynamic> getOrderDetail(String orderId, {Duration timeout: const Duration(seconds: 10)}) async {
    Completer completer = Completer();
    _widget._waitCompleters["order_detail_$orderId"] = completer;
    await _widget._webview2.evaluateJavascript(source: TaobaoJsCode.apiOrderDetail(orderId));
    return completer.future.timeout(timeout, onTimeout: () {
      _widget._waitCompleters.remove("order_detail_$orderId");
      return Future.error("执行任务超时($timeout)");
    });
  }

  /// 获取物流详情
  Future<dynamic> getTradeDetail(String orderId, {Duration timeout: const Duration(seconds: 10)}) async {
    Completer completer = Completer();
    _widget._waitCompleters["trade_detail_$orderId"] = completer;
    await _widget._webview2.evaluateJavascript(source: TaobaoJsCode.apiTradeDetail(orderId));
    return completer.future.timeout(timeout, onTimeout: () {
      _widget._waitCompleters.remove("order_detail_$orderId");
      return Future.error("执行任务 $orderId 超时($timeout)");
    });
  }

  /// 重置
  void reset() {
    /// TODO: 初始化变量

    /// 重新加载
    _webview.loadUrl(url: _widget.widget.loginPage);
  }

  /// debug
  void toggleWebview({bool show}) {
    _widget.toggleWebview(show: show);
  }
}


class HackKeepAlive extends StatefulWidget {

  HackKeepAlive();

  @override
  _HackKeepAliveState createState() => _HackKeepAliveState();
}

class _HackKeepAliveState extends State<HackKeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      child: InAppWebView(
        initialUrl: TaobaoUrls.homePageMain,
        initialOptions: InAppWebViewWidgetOptions(inAppWebViewOptions: InAppWebViewOptions(javaScriptEnabled: true)),
      ),
    );
  }

  // Setting to true will force the tab to never be disposed. This could be dangerous.
  @override
  bool get wantKeepAlive => true;
}