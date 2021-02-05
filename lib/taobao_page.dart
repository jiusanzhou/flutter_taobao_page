import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_taobao_page/action_page.dart';
import 'package:flutter_taobao_page/event.dart';
import 'package:flutter_taobao_page/login.dart';
import 'package:flutter_taobao_page/page_view.dart';
import 'package:flutter_taobao_page/taobao/h5.dart';
import 'package:flutter_taobao_page/taobao/pc.dart';
import 'package:flutter_taobao_page/utils.dart';
import 'package:flutter_taobao_page/webview.dart';
import 'package:universal_html/html.dart' as html;
import 'package:universal_html/parsing.dart';
import 'package:gbk2utf8/gbk2utf8.dart';

class ParserPattern {
  final dynamic pattern;

  // the real single one
  String _realPattern;
  // value func
  String _valfn = "text";

  ParserPattern _singlePattern;
  List<ParserPattern> _arrayPatterns;
  Map<String, ParserPattern> _mapPatterns;

  ParserPattern(this.pattern) {
    if (pattern is String) {
      _singlePattern = this;
      _realPattern = pattern as String;
      var parts = _realPattern.split("@");
      if (parts.length < 2) {
        return;
      }
      _realPattern = parts[0];
      _valfn = parts[1];
      return;
    }

    if (pattern is List) {
      _arrayPatterns = (pattern as List).map((e) => ParserPattern(e)).toList();
      return;
    }

    if (pattern is Map) {
      _mapPatterns =
          (pattern as Map).map((k, v) => MapEntry(k, ParserPattern(v)));
      return;
    }

    print("Error: Pattern type is ${pattern.runtimeType}");
  }

  dynamic _genVal(html.HtmlElement ele) {
    if (ele == null) return;
    switch (_valfn) {
      case "text":
        return ele.text;
        break;
      case "innerText":
        return ele.innerText;
      case "html":
      case "innerHtml":
        return ele.innerHtml;
      default:
        return ele.getAttribute(_valfn);
    }
  }

  dynamic parse(html.HtmlElement ele) {
    // try each one to parse
    if (_singlePattern != null) {
      var e = ele.querySelector(_realPattern);
      return _genVal(e);
      // take value out
    }

    if (_arrayPatterns != null) {
      return _arrayPatterns.map((e) => e.parse(ele)).toList();
    }

    if (_mapPatterns != null) {
      return _mapPatterns.map((k, v) => MapEntry(k, v.parse(ele)));
    }

    return null;
  }
}

class Parser {
  // type: jsonpath, xpath, css

  // map array
  final dynamic pattern;
  final bool isRegex;

  ParserPattern _parserPattern;
  RegExp _regexp;

  bool get _isRegex => pattern is String && isRegex;

  Parser(this.pattern, {this.isRegex: false}) {
    if (_isRegex) {
      _regexp = RegExp(this.pattern);
    } else {
      _parserPattern = ParserPattern(pattern);
    }
  }

  dynamic parse(String content) {
    // TODO:
    if (_isRegex) return _regexp.firstMatch(content).group(1);
    return _parserPattern.parse(parseHtmlDocument(content).documentElement);
  }
}

class HttpClient extends http.BaseClient {
  http.Client _httpcli;

  HttpClient() {
    _httpcli = http.Client();
  }

  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['cookie'] = await CookieManager.instance()
        .getCookies(url: request.url.toString())
        .then((ck) {
      return ck.map((e) => "${e.name}=${e.value}").join(";");
    });
    if (request.headers['user-agent'] != null)
      request.headers['user-agent'] = UA_PC;
    return _httpcli.send(request);
  }

  Future<http.Response> request(
    String method,
    String url, {
    bool useMobile = false,
    Map<String, String> headers,
    body,
    Encoding encoding,
  }) {
    if (headers == null) headers = {};
    if (headers['user-agent'] == null) {
      headers['user-agent'] = useMobile ? UA_IOS : UA_PC;
    }

    switch (method) {
      case "get":
      case "GET":
        return this.get(url, headers: headers);
        break;
      case 'post':
      case 'POST':
        return this.post(url, headers: headers, body: body, encoding: encoding);
      default:
        return this.noSuchMethod(null);
    }
  }
}

class TaobaoPage extends StatefulWidget {
  final int maxTab;

  final Widget child;

  final LoginPage loginPage;

  final void Function(TaobaoPageController controller) onCreated;

  TaobaoPage({
    @required this.child,
    @required this.loginPage,
    this.maxTab: 20,
    this.onCreated,
  });

  @override
  _TaobaoPageState createState() => _TaobaoPageState();
}

class _TaobaoPageState extends State<TaobaoPage>
    with
        TickerProviderStateMixin<TaobaoPage>,
        AutomaticKeepAliveClientMixin<TaobaoPage> {
  @override
  bool get wantKeepAlive => true;

  TaobaoPageController _controller;

  TabController _tabController;

  List<WebviewPage> _pages = [];
  List<List<WebviewPage>> _pageGroups = [];

  bool get _isLogon => widget.loginPage.isLogin;

  bool _debug = false;

  bool _scrollable = false;

  int _tabIndex = 0;
  int _stackIndex = 0;

  bool get _showWebview => _debug;

  @override
  void initState() {
    super.initState();
    // create controller once
    _controller = TaobaoPageController._(this);
    // we need to subscribe event in this function
    widget.onCreated?.call(_controller);

    // CookieManager.instance().getCookies(url: null);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // groups
  List<List<WebviewPage>> _buildPageGroups(BuildContext context) {
    List<List<WebviewPage>> tabs = [];
    List<WebviewPage> _tmp = [];
    int _idx = 0; // TODO: more customize, now always be the first one.
    _pages.forEach((p) {
      p.options.visible
          ? tabs.add([p])
          : tabs.isEmpty
              ? _tmp.add(p)
              : tabs[_idx].add(p);
    });
    (tabs.isEmpty || tabs[_idx].isEmpty)
        ? tabs.add(_tmp)
        : tabs[_idx].addAll(_tmp);

    // set group id and stack id
    tabs.asMap().forEach((_grpid, element) {
      element.asMap().forEach((_stkid, value) {
        value.groupId = _grpid;
        value.stackId = _stkid;
      });
    });

    // update the _tab controller
    // _tabController?.dispose();
    if (_tabController == null || tabs.length != _tabController.length) {
      _tabController = TabController(
          initialIndex: tabs.length - 1, length: tabs.length, vsync: this);
      _controller.emit(EventTabControllerUpdate(_tabController));
    }

    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // rebuild pages, TODO: remove not nece
    _pageGroups = _buildPageGroups(context);
    return IndexedStack(
      index: _showWebview ? 1 : 0,
      children: <Widget>[
        widget.child,
        TaobaoPageView(
          scrollable: _scrollable,
          stackIndex: _stackIndex,
          groupedPages: _pageGroups,
          tabController: _controller.tabController,
          // children: List.generate(min(widget.maxTab, _pages.length), (index) => _pages[index])
        ),
      ],
    );
  }

  void _addPage(WebviewPage page) {
    setState(() {
      _pages.add(page);
    });
  }

  void _setDebug(bool v) {
    setState(() => _debug = v);
  }

  void _setScrollable(bool v) {
    setState(() => _scrollable = v);
  }

  void _changePage(WebviewPage page) {
    setState(() {
      _tabIndex = page.groupId;
      _tabController.animateTo(page.groupId);
      _stackIndex = page.stackId;
    });
  }

  void _reset() {
    // clean all state and call initAsync again
    _stackIndex = 0;

    // romove alll pages;
    _pages.forEach((p) {
      // must destroy
      p.destroy();
    });

    // clean it
    setState(() {
      _pages.clear();
    });
  }
}

class TaobaoPageController {
  _TaobaoPageState _state;

  EventBus _eventBus;

  HttpClient _httpcli;

  // is login
  PCWeb pcweb;
  H5API h5api;

  TaobaoPageController._(
    this._state,
  ) {
    _eventBus = EventBus();
    _httpcli = HttpClient();

    // TODO: start timer to clean inactive page
    pcweb = PCWeb(this);
    h5api = H5API(this);
  }

  // pages return pages we have
  List<WebviewPage> get pages => _state._pages;

  // grooups pages
  List<List<WebviewPage>> get pageGroups => _state._pageGroups;

  TabController get tabController => _state._tabController;

  WebviewPage get currentViewPage =>
      _state._pageGroups[_state._tabIndex][_state._stackIndex];

  // debug
  bool get isDebug => _state._debug;

  // subscribe event, add filter with field
  Stream<T> on<T>() {
    return _eventBus.on<T>();
  }

  // emit event
  void emit(event) {
    _eventBus.fire(event);
  }

  void setDebug(bool v) {
    _state._setDebug(v);
  }

  void showWebview(bool v) {
    setDebug(v);
  }

  void setScrollable(bool v) {
    _state._setScrollable(v);
  }

  Future<dynamic> doAction(
    BuildContext context,
    ActionJob action, {
    CreatedCallback onCreated,
    LoadStartCallback onLoadStart,
    LoadStopCallback onLoadStop,
    LoadErrorCallback onLoadError,
    PageOptions options,
  }) async {
    if (options == null) options = PageOptions();

    // 如果是headless模式，就使用client直接发送请求
    // 但是很明显，action是不一样的
    if (action.headless) {
      return _httpcli
          .request(
        options.method,
        action.url,
        body: action.body,
        useMobile: options.useMobile,
        headers: options.headers,
      )
          .then((v) async {
        // 编码处理
        var content = v.body;

        // 先判断是否出现了验证码
        // 订单的暂时不处理
        if (PCWeb.isVerify(content)) {
          print("出现了验证码 ======> 需要弹出来划过去");
          // 出现验证码的化，就直接弹出来页面进行验证，但是这里没有context好像不行

          await openVerifyPage(context, action.url);

          print("=====> 已经划过了验证码");

          // 等待验证码划过
          return doAction(context, action, options: options);
        }

        if (options.gbk ||
            v.headers["content-type"].toLowerCase().contains("gbk")) {
          content = gbk.decode(v.bodyBytes);
        }

        if (action.json) {
          return json.decode(content);
        } else {
          return options.pattern == null
              ? content
              : Parser(options.pattern, isRegex: options.isRegex)
                  .parse(content);
        }
      });
    }

    // check if we are already login
    if (!_state._isLogon && !action.noLogin)
      return Future.error("not account login");

    // find match
    WebviewPage curp = _state._pages
        .firstWhere((p) => p.match(action.url), orElse: () => null);
    // if we found matched page, just do action
    // TODO: check pages overload, try another page
    if (curp != null) return curp.doAction(action);

    // open a new page to do this action
    // 这里是核心，打开页面然后做动作
    return openPage(
      action.url,
      options: options,
      onCreated: onCreated,
      onLoadStart: onLoadStart,
      onLoadStop: onLoadStop,
      onLoadError: onLoadError,
    ).then((WebviewPage page) {
      return page.doAction(action);
    });
  }

  // 直接就叫做滑动验证码好了
  Future<dynamic> openVerifyPage(BuildContext context, String url) {
    // InAppWebViewController  cc;

    // 当页面出现自动刷新时，就说明已经通过了验证
    bool _autoReload = false;

    return Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text("淘宝验证码"),
                  ),
                  body: TaobaoWebview(
                    initialUrl: url,
                    useMobile: true,
                    // onWebViewCreated: (c) => cc = c,
                    onLoadStart: (c, url) {

                      print("验证码 webview 开始加载 $url");

                      // 怎么判断是否已经恢复了而没有验证码
                      // if (url.endsWith("https//www.taobao.com")) {
                      //   // 对于订单类型的就是滑动成功了
                      //   return Navigator.pop(context);
                      // }
                      // 其他的呢
                      
                      if (!_autoReload) {
                        _autoReload = true;
                        return;
                      }

                      // 第二次就是自动加载了
                      // 应该就是验证成功 TODO:
                      return Navigator.pop(context);
                    },
                    onLoadStop: (c, url) {
                      print("验证码 webview 加载结束! $url");
                    },
                  ),
                )));
  }

  Future<WebviewPage> openPage(
    String url, {
    CreatedCallback onCreated,
    LoadStartCallback onLoadStart,
    LoadStopCallback onLoadStop,
    LoadErrorCallback onLoadError,
    PageOptions options,
  }) {
    // NOTE: fix bug in getter null
    if (options == null) options = PageOptions();

    // if (H5PageUrls.isLogin(url)) return Future.error("don't allow open login page");

    // TODO: reuse page with empty job queue, except which has keepalive

    if (_state._pages.length > _state.widget.maxTab) {
      // TODO: make a page can be turn to a new one
      return Future.error("max tab ${_state.widget.maxTab}");
    }

    if (options != null && options.max > 0) {
      List<WebviewPage> ps = _state._pages.where((p) => p.match(url)).toList();
      if (ps.length >= options.max) {
        // TODO: get the random page
        if (options.refresh)
          ps[0].webviewController.reload(); // TODO: should replace onHandler?
        return Future.value(ps[0]);
      }
    }

    // get the new page's index
    final _len = _state._pages.length;

    // event filter page with id

    // init the new page
    WebviewPage page;
    page = WebviewPage(
      _len,
      url,
      onWebViewCreated: (controller) {
        emit(EventPageCreated(page));
        onCreated?.call(controller);
      },
      onLoadStart: (controller, url) {
        emit(EventPageLoadStart(page, url));
        onLoadStart?.call(controller, url);
      },
      onLoadStop: (controller, url) {
        emit(EventPageLoadStop(page, url));
        onLoadStop?.call(controller, url);
      },
      onLoadError: (controller, url, code, message) {
        emit(EventPageLoadError(page, url, code, message));
        onLoadError?.call(controller, url, code, message);
      },
      options: options,
    );

    print("[controller] open the ${_len + 1} page");

    // TODO: handle load page error, this page need be destroy

    _state._addPage(page);

    return Future.value(page);
  }

  // show special page
  void showPage(WebviewPage page) {
    // set with tab index and stack index
    // for now just auto display with our hook
    _state._changePage(page);
  }

  // show special page with url
  void showPageWithUrl(String url) {
    WebviewPage page = getPageWithUrl(url);
    if (page != null) return showPage(page);
    print("can't found page with url: $url, maybe you should open it first.");
  }

  WebviewPage getPageWithUrl(String url) {
    return _state._pages
        .firstWhere((element) => element.match(url), orElse: () => null);
  }

  // clean and reset
  void reset() {
    _state._reset();
  }
}
