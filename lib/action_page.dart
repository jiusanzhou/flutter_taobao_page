import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_taobao_page/utils.dart';
import 'package:flutter_taobao_page/webview.dart';

class ActionJob {

  // vid 设置action id
  String vid;

  // url规则,用于筛选执行code的page, 如果未匹配到则打开新标签
  String url;

  // code,即为执行的代码
  String code;

  // 可以在未登录情况下调用
  bool noLogin;

  // 绑定用于执行的page
  // Page page; , @required this.page

  // 初始化动作
  ActionJob(this.url, { this.code, this.noLogin: false });
}


// 需要打开渲染的页面配置
// 打开的页面,包含等
// 需要需要改成 widget?
class Page {

  // TODO: auto load scripts

  // 当前页面的链接地址
  String _url;

  String _normalizeUrl;

  // 永久的页面不被复用也不被回收
  bool keepalive;

  // 执行的任务队列
  final Queue<ActionJob> _actionsQueue = Queue<ActionJob>();

  // 暂停任务队列的执行
  bool _queuePaused = true;
  
  // 执行结果的等待feature
  final Map<String, Completer> _waitCompleters = {};

  // 任务队列执行频率
  Duration _actInterval = const Duration(microseconds: 100);

  // 任务执行 timre
  Timer _actTimer;

  // 插入额外脚本

  // page 需不需要被销毁???

  // 出现任意验证码就可以stop the world

  ///Event fired when the [InAppWebView] is created.
  final void Function(InAppWebViewController controller) onWebViewCreated;

  ///Event fired when the [InAppWebView] starts to load an [url].
  final void Function(InAppWebViewController controller, String url)
      onLoadStart;

  ///Event fired when the [InAppWebView] finishes loading an [url].
  final void Function(InAppWebViewController controller, String url) onLoadStop;

  ///Event fired when the [InAppWebView] encounters an error loading an [url].
  final void Function(InAppWebViewController controller, String url, int code,
      String message) onLoadError;

  // webview 视图
  Widget webview;

  // webview 控制器
  InAppWebViewController webviewController;

  // 用于清理，上次活动时间
  DateTime lastActive;

  bool _missES6 = Platform.isAndroid;

  Page(
    this._url,
    {
      this.onWebViewCreated,
      this.onLoadStart,
      this.onLoadStop,
      this.onLoadError,

      this.keepalive: false,
    }
  ) {
    init();
  }

  // init 初始化
  init() {

    // 初始化URL
    _setUrl(_url);
    print("初始化一个新页面: $_url");

    // 初始化webview
    webview = TaobaoWebview(
      initialUrl: _url,
      onWebViewCreated: _onWebViewCreated,
      onLoadStart: _onLoadStart,
      onLoadStop: _onLoadStop,
      onLoadError: _onLoadError,
    );

    // 启动任务执行器
    _actTimer = Timer.periodic(_actInterval, (timer) {
      _runAction();
    });
  }

  // 主动调用销毁
  Future<bool> destroy() {
    _actTimer.cancel();
    return Future.value(true);
  }

  // 匹配当前url是否合适
  bool match(String _url) {
    return _url == _normalizeUrl;
  }

  // 执行动作
  Future<dynamic> doAction(ActionJob action, {Duration timeout: const Duration(seconds: 60)}) {

    // 判断是否要执行代码，不执行代码生成 action 扔进来干嘛?
    if (action.code == null) return Future.value(null);

    // 生成 js 执行 vid
    String vid = "callback_${Utils.randomString()}";

    action.vid = vid;
  
    // 生成 feature
    _waitCompleters[vid] = Completer();

    // 不立即去执行代码，扔到队列去: _runJS(vid, action.code);
    _actionsQueue.add(action);

    // 返回超时future
    return _waitCompleters[vid].future.timeout(timeout, onTimeout: () {
      // remove completer
      _waitCompleters.remove(vid);
      return Future.error("timeout: $timeout");
    });
  }

  void _setUrl(String url) {
    _url = url;
    _normalizeUrl = url.split("?")[0];
  }

  // 接收js从返回的数据: 这里比需要返回字符串，inapp有bug
  dynamic _onJsResultHandler(List<dynamic> args) {
    // 长度需要为3
    if (args.length != 3) return "";

    // 判断返回正常还是错误: vid, data, error
    Completer c = _waitCompleters.remove(args[0]);
    if ( c == null ) return Future.error("unregister action id: ${args[0]}");
    args[2] == null ? c.complete(args[1]) : c.completeError(args[2]);
    return "";
  }

  String _fncallback(String vid) {
    if (Platform.isAndroid) {
      return "flutter_inappwebview._callHandler('js_result', setTimeout(function(){}), JSON.stringify(['$vid', data, err]))";
    } else {
      return "flutter_inappwebview.callHandler('js_result', '$vid', data, err)";
    }
  }

  // 运行 js, 这里不直接返回结果，全部走 js_result
  void _runJS(String vid, String code) {
    // 
    // 拼装最终执行的 js 代码
    //
    // 判断结果是否是 promise: typeof subject.then == 'function' 这个做法不够严谨但在这里够用
    //
    // let callback = (data) => flutter_inappwebview.callHandler('js_result', vid, data);
    // let res = code;
    // if (typeof res.then !== 'function') return callback({data: res})
    // res.then((r) => callback({data: r})).catch((e) => callback({error: e}))
    // (()=>{})()
    //

    // 一种是直接在这里返回就可以了

    // Android 部分低版本 不支持 es6： 箭头函数，let等???
    // 不过promise 装了polyfill

    // (()=>{})(), return, res,
    String vcode = """(function() {
  var callback = function(data, err) { return ${_fncallback(vid)} };
  try {
    var res = (function() {
      ${code.indexOf("return")<0?"return "+code:code}
    })();
    if (typeof res.then !== 'function') {
      callback({data: res});
    } else {
      res.then(function(r) {callback(r)}).catch(function(e) {callback(null, e)});
    }
  } catch(e) {
    callback(null, '错误:'+e);
  }
  return "";
})()""";

    // vcode = """(function (){flutter_inappwebview._callHandler('js_result', setTimeout(function(){}), JSON.stringify(['$vid', 'a', null])); return ''})()""";
    // vcode = """(function(){ var a = function(){ return 1 }; return a() })()""";
    // vcode = "typeof let";
    // vcode = "var a;try{a=1;x}catch(e){a=2}; a";
    // vcode = "typeof Array.from";
    // print("$vcode");


    webviewController.evaluateJavascript(source: vcode).then((value) {
      // print("evaluate result => $value");
    }).catchError((e) {
      print("evaluate error => $e");
    });
  }

  // 从任务队列去任务并执行
  void _runAction() {
    // 判断是否暂停
    if (_queuePaused) return;
    // 判断是否为空
    if (_actionsQueue.isEmpty) return;
    // FIFO
    ActionJob act = _actionsQueue.removeFirst();
    // 执行代码
    _runJS(act.vid, act.code);
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    // 暂停队列
    _queuePaused = true;

    webviewController = controller;
    webviewController.addJavaScriptHandler(handlerName: "js_result", callback: _onJsResultHandler);
    onWebViewCreated?.call(webviewController);
  }

  _onLoadStart(InAppWebViewController controller, String url) {
    // 暂停队列
    _queuePaused = true;

    if (_missES6) controller.evaluateJavascript(source: """if (!Array.from) {
    Array.from = function (object) { return [].slice.call(object) };
}""");

    onLoadStart?.call(controller, url);
  }

  _onLoadStop(InAppWebViewController controller, String url) {
    // 启动队列
    _queuePaused = false;

    _setUrl(url);

    onLoadStop?.call(controller, url);
  }

  _onLoadError(InAppWebViewController controller, String url, int code, String message) {
    print("加载错误 => $url, $message");
    onLoadError?.call(controller, url, code, message);
  }
}