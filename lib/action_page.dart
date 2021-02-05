import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_taobao_page/utils.dart';
import 'package:flutter_taobao_page/webview.dart';

class ActionJob {
  String vid;
  String url;
  String code;

  // allow execute with login
  bool noLogin;
  bool isAsync;

  // 直接请求原始数据
  bool headless;
  bool json;

  dynamic body;

  // bind page for this action
  // Page page; , @required this.page

  ActionJob(this.url, {
    this.code,
    this.noLogin: false,
    this.isAsync: true,
    this.headless: false,
    this.json: false,
    this.body,
  });
}

class PageOptions {

  bool keepalive;

  bool visible;

  String title;

  // max page of my
  int max;

  // timeout for page load
  Duration timeout;

  // refresh if exits
  bool refresh;

  List<ContentBlocker> blockers;

  // use mobile mode or not
  bool useMobile;

  // method
  String method;
  Map<String, String> headers;
  dynamic pattern;
  bool isRegex;
  bool gbk;

  PageOptions({
    this.keepalive: false,
    this.visible: false,
    this.title,
    this.max: 1,
    this.timeout,
    this.refresh: false,
    this.blockers: const [],
    this.useMobile: false, // we need to set for webviewpage
    this.method: "GET",
    this.headers,
    this.pattern,
    this.gbk: false,
    this.isRegex: false
  });
}

class WebviewPage {

  // TODO: auto load scripts

  int id;

  int groupId;
  int stackId;

  PageOptions options;

  String _url;

  String _normalizeUrl;

  final Queue<ActionJob> _actionsQueue = Queue<ActionJob>();
  bool _queuePaused = true;
  
  final Map<String, Completer> _waitCompleters = {};

  Duration _actInterval = const Duration(microseconds: 100);

  Timer _actTimer;

  // NOTE: make sure stop fucntion run once
  bool _stopped = false;

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

  Widget webview;

  InAppWebViewController webviewController;

  // page last action for cleaner
  DateTime lastActive;

  // TOOD: with android low version
  bool _missES6 = Platform.isAndroid;

  WebviewPage(
    this.id,
    this._url,
    {
      this.onWebViewCreated,
      this.onLoadStart,
      this.onLoadStop,
      this.onLoadError,
      this.options,
    }
  ) {
    init();
  }

  init() {
    _setUrl(_url);
    print("[action page] init a new page => $_url");

    // create a webview widget
    webview = TaobaoWebview(
      initialUrl: _url,
      onWebViewCreated: _onWebViewCreated,
      onLoadStart: _onLoadStart,
      onLoadStop: _onLoadStop,
      onLoadError: _onLoadError,
      blockers: options.blockers,
      useMobile: options.useMobile,
    );

    // set a timeout
    if (options.timeout != null) Timer(options.timeout, () {
      if (webviewController==null) {
        print("[action page] create webveiw timeout => $_url");
        return;
      }
      // timeout, stop laoding
      webviewController.isLoading().then((value) {
        print("[action page] laod timeout ${options.timeout} => $_url");
        if (value) {
          // call directlly
          _onLoadStop(webviewController, _url);
        }
      });
    });

    // start a routine to execute
    _actTimer = Timer.periodic(_actInterval, (timer) {
      _runAction();
    });
  }

  // manual destroy this page
  Future<bool> destroy() {
    _actTimer.cancel();
    
    // clean others

    return Future.value(true);
  }

  // match current url
  bool match(String _url) {
    return _url.split("?")[0] == _normalizeUrl;
  }

  // run action
  Future<dynamic> doAction(ActionJob action, {Duration timeout: const Duration(seconds: 60)}) {

    // if with code to execute just return
    if (action.code == null) return Future.value(null);

    // generate a id
    String vid = "callback_${Helper.randomString()}";

    action.vid = vid;
  
    // new a future
    _waitCompleters[vid] = Completer();

    _actionsQueue.add(action);

    // with timeout future
    return _waitCompleters[vid].future.timeout(timeout, onTimeout: () {
      // remove completer
      _waitCompleters.remove(vid);
      return Future.error("[action] timeout: $timeout");
    });
  }

  String get url => _url;
  String get normalizeUrl => _normalizeUrl;

  void _setUrl(String url) {
    _url = url;

    _normalizeUrl = url.split("?")[0];
  }

  // receive data from js, need to return string, inapp has' bug
  dynamic _onJsResultHandler(List<dynamic> args) {
    // NOTE: we need 3 arguments
    if (args.length != 3) return "";

    Completer c = _waitCompleters.remove(args[0]);
    if ( c == null ) return Future.error("[action page] unregister action id: ${args[0]}");
    // error should return current page.
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

  // all result need to use channel
  void _runJS(String vid, String code, {bool isAsync: true}) {
    // 
    // check if type is promise: typeof subject.then == 'function'
    //
    // let callback = (data) => flutter_inappwebview.callHandler('js_result', vid, data);
    // let res = code;
    // if (typeof res.then !== 'function') return callback({data: res})
    // res.then((r) => callback({data: r})).catch((e) => callback({error: e}))
    // (()=>{})()
    //

    // some lower android don't supported es6
    // but the inappwebview has inject polyfill for promise
    // NOTE: try not to use arrow function and `let`.


    // if not isAsync we just eval the code and return
    if (!isAsync) {
      webviewController.evaluateJavascript(source: "(function(){ $code })()").then((value) {
        _onJsResultHandler([vid, value, null]);
      }).catchError((e) {
        _onJsResultHandler([vid, null, e]);
      });
      return;
    }

    // (()=>{})(), return, res,
    String vcode = """(function() {
  var callback = function(data, err) { return ${_fncallback(vid)} };
  try {
    var res = (function() {
      ${code.indexOf("return")<0?"return "+code:code}
    })();
    if (typeof res.then !== 'function') {
      callback(res);
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
      // TODO: some value we just call _callHandler?
      if (value == "") {
        print("[action js] evalute result success => $value");
      } else {
        print("[action js] evaluate error, shoud't return null");
      }
    }).catchError((e) {
      print("[action js] evaluate error => $e");
    });
  }

  void _runAction() {
    if (_queuePaused) return;
    if (_actionsQueue.isEmpty) return;
    // FIFO
    ActionJob act = _actionsQueue.removeFirst();
    _runJS(act.vid, act.code, isAsync: act.isAsync);
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    _queuePaused = true;

    webviewController = controller;
    webviewController.addJavaScriptHandler(handlerName: "js_result", callback: _onJsResultHandler);
    onWebViewCreated?.call(webviewController);
  }

  _onLoadStart(InAppWebViewController controller, String url) {
    // NOTE: must reset for call
    _stopped = false;

    _queuePaused = true;

    if (_missES6) controller.evaluateJavascript(source: """if (!Array.from) {
    Array.from = function (object) { return [].slice.call(object) };
}""");

    onLoadStart?.call(controller, url);
  }

  _onLoadStop(InAppWebViewController controller, String url) {
    // NOTE: make sure run once 
    if (_stopped) return;

    _stopped = true;

    _queuePaused = false;

    // 一定要处理吗???
    // _setUrl(url);

    onLoadStop?.call(controller, url);
  }

  _onLoadError(InAppWebViewController controller, String url, int code, String message) {
    print("[action page] load page error => $url, $message");
    onLoadError?.call(controller, url, code, message);
  }
}