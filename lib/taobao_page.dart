import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_taobao_page/action_page.dart';
import 'package:flutter_taobao_page/page_view.dart';
import 'package:flutter_taobao_page/taobao/h5.dart';
import 'package:flutter_taobao_page/taobao/pc.dart';
import 'package:flutter_taobao_page/webview.dart';

class TaobaoPage extends StatefulWidget {

  // 最大同时打开页面数, 默认 1
  final int maxTab;

  // 显示模式, 默认 stack
  final ViewMode mode;

  // 显示的元素, 替换webview内容
  final Widget child;

  // 注册初始化函数
  final void Function(TaobaoPageController controller) onCreated;

  // 注册帐号登录函数
  final void Function(TaobaoPageController controller, dynamic data) onUserLogon;

  TaobaoPage({
    @required this.child,
    this.maxTab: 20,
    this.mode: ViewMode.stack,
    this.onCreated,
    this.onUserLogon,
  });

  @override
  _TaobaoPageState createState() => _TaobaoPageState();
}

class _TaobaoPageState extends State<TaobaoPage> with AutomaticKeepAliveClientMixin<TaobaoPage> {

  @override
  bool get wantKeepAlive => true;

  // 控制器用于控制
  TaobaoPageController _controller;

  List<Page> _pages = [];

  int _index = 0; // 当前显示页

  // 只要登录页面开始加载那就显示webview
  bool _loginPage = false;

  // myhome出现即可认为是登录成功
  bool _isLogon = false; // TODO: 调试都是登录

  bool _debug = false;

  // TODO: 是否显示webview，可以有多个参数合成：readdy, debug等
  bool get _showWebview => _debug || _loginPage;

  @override
  void initState() {
    super.initState();

    _controller = TaobaoPageController._(this);
    // 初始化状态

    widget.onCreated?.call(_controller);

    // 添加默认的登录页面: code 为空,
    // 加载完成是显示登录页面,显示登录页面
    _controller.openPage(
      H5PageUrls.login,
      onLoadStop: (controller, url) {
        if (H5PageUrls.isHome(url)) {
          print("应该登录成功 ====> $url");
          // 查询帐号信息的数据, 判断是否登录成功
          _controller.h5api.userProfile(check: true).then((value) {
            // TODO: 通知所有页面刷新
            setState(() {
              _isLogon = true;
            });
            widget.onUserLogon?.call(_controller, value);
            print("确认登录成功 => $value");
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return IndexedStack(
      index: _showWebview?1:0,
      children: <Widget>[
        widget.child,
        TaobaoPageView(
          mode: widget.mode,
          index: _index,
          children: List.generate(min(widget.maxTab, _pages.length), (index) => _pages[index].webview)
        ),
      ],
    );
  }

  void _setLoginPage(int index) {
    setState(() {
      _index = index;
      _loginPage = true;
    });
  }

  void _addPage(Page page) {
    setState(() {
      _pages.add(page);
    });
  }
}

// 控制器: 暴露页面控制
class TaobaoPageController {

  _TaobaoPageState _state;

  // 执行淘宝执行代码
  PCWeb pcweb;
  H5API h5api;

  TaobaoPageController._(
    this._state,
  ) {
    // TODO: 启动定时器，清理不活跃的 page
    pcweb = PCWeb(this);
    h5api = H5API(this);
  }

    // 如果 action is done 从数组移除
  Future<dynamic> doAction(ActionJob action) async {
    
    // 检查是否登录
    if (!_state._isLogon && !action.noLogin) return Future.error("not account login");

    // 提高效率 使用 hash
    int _index;
    for (var i=0; i<_state._pages.length; i++) {
      if (_state._pages[i].match(action.url)) {
        _index = i;
        break;
      }
    }
    // 找到页面直接去执行
    if (_index != null) return _state._pages[_index].doAction(action);

    // 打开新页面来执行
    return openPage(action.url).then((Page page) {
      return page.doAction(action);
    });
  }

  Future<Page> openPage(
    String url,
    {
      CreatedCallback onCreated,
      LoadStartCallback onLoadStart,
      LoadStopCallback onLoadStop,
      LoadErrorCallback onLoadError,
    }
  ) {

    // if (H5PageUrls.isLogin(url)) return Future.error("don't allow open login page");

    // TODO: 复用已经没有任务的页面，除非 keepalive

    if (_state._pages.length>_state.widget.maxTab) {
      // 如果大于maxTab？
      return Future.error("max tab ${_state.widget.maxTab}");
    }

    final _len = _state._pages.length;

    final page = Page(
      url,
      onWebViewCreated: onCreated,
      onLoadStart: onLoadStart,
      onLoadStop: (controller, url) {
        onLoadStop?.call(controller, url);
        _checkIsLoginPage(_len, controller, url);
      },
      onLoadError: onLoadError,
    );

    print("打开第 ${_len+1} 个标签");

    // 初始化
    // TODO: 初始化返回状态
    // page.init();

    // TODO: 加载失败怎么算?
    _state._addPage(page);

    return Future.value(page);
  }

  // 判断是否存在登录页面
  void _checkIsLoginPage(int index, InAppWebViewController controller, String url) {
    if (H5PageUrls.isLogin(url)) {
      print("是登录页面需要显示 => webview");
      // 设置存在登录页面
      _state._setLoginPage(index);
    }
  }
}