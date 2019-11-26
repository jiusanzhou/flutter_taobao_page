library flutter_taobao_page;

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_taobao_page/utils.dart';

typedef void PageFinishCallback(WebViewController controller, String url);

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
  final isAndroid = Platform.isAndroid;

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
  WebViewController _webview;

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

  // debug
  bool debug;

  @override
  void initState() {
    super.initState();

    /// 添加默认的回调函数
    /// TODO: 注册成资源,所有的操作都可以通过资源的接口
    /// TODO: widget中的可以添加过来
    _callbacks[widget.loginPage] = _afterLoginPage;
    _callbacks[widget.homePage] = _afterHomePage;
    _callbacks[widget.orderPage] = _afterOrderPage;

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

  void _onWebViewCreated(WebViewController controller) {
    _webview = controller;

    final TaobaoPageController m = TaobaoPageController._(widget, _webview);
    _controller.complete(m);
    if (widget.onCreated != null) widget.onCreated(m);
  }

  /// 异步初始化
  void _initAsync() async {
    _jscode = TaobaoJsCode.orderPage;
  }

  /// 处理回调函数
  /// TODO: 使用精准方式匹配
  void _onPageFinished(String url) {
    String _url = url.split("?")[0];
    PageFinishCallback fn = _callbacks[_url];
    if (fn != null) fn(_webview, url);
  }

  /// 登录页加载完成
  void _afterLoginPage(WebViewController controller, String url) {
    /// 设置为显示webview
    setState(() {
      _showWebview = true;
    });

    /// 插入js: 点击登录时自动隐藏webview

    if (widget.onInit != null) widget.onInit();
  }

  /// 主页加载完成
  void _afterHomePage(WebViewController controller, String url) {
    setState(() {
      /// 这里隐藏
      _showWebview = false;

      /// 设置登录成功
      _isLogin = true;
    });

    /// 加载到订单页面
    _webview.loadUrl(widget.orderPage);
  }

  /// 订单页加载完成
  void _afterOrderPage(WebViewController controller, String url) async {
    /// 插入js: 插入函数可以获取订单
    _webview.evaluateJavascript(_jscode).then((_) {
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

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _showWebview ? 1 : 0,
      children: <Widget>[
        /// 显示内容
        widget.child,

        /// webview
        WebView(
          initialUrl: widget.loginPage,
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: _onWebViewCreated,
          onPageFinished: _onPageFinished,
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

  TaobaoPage _widget;

  WebViewController _webview;

  /// 获取订单数据
  /// TODO: 缓存
  Future<Map<String, dynamic>> getOrder(int page, {int count = 20}) async {
    /// 请求js
    var res =
        await _webview.evaluateJavascript(TaobaoJsCode.getOrder(page, count));

    /// 反序列化
    try {
      Map<String, dynamic> _map =
          _widget.isAndroid ? json.decode(json.decode(res)) : json.decode(res);
      return _map;
    } catch (e) {
      return Future.error(e);
    }
  }

  /// 重置
  void reset() {
    /// TODO: 初始化变量

    /// 重新加载
    _webview.loadUrl(_widget.loginPage);
  }
}
