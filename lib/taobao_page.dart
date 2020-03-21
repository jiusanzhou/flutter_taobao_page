import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_taobao_page/action_page.dart';
import 'package:flutter_taobao_page/event.dart';
import 'package:flutter_taobao_page/page_view.dart';
import 'package:flutter_taobao_page/taobao/h5.dart';
import 'package:flutter_taobao_page/taobao/pc.dart';
import 'package:flutter_taobao_page/utils.dart';
import 'package:flutter_taobao_page/webview.dart';

class TaobaoPage extends StatefulWidget {

  final int maxTab;

  final ViewMode mode;

  final Widget child;

  final void Function(TaobaoPageController controller) onCreated;

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

  TaobaoPageController _controller;

  List<Page> _pages = [];

  int _index = 0; // current display webview

  // if we have any login apge
  bool _hasLoginPage = false;

  // we have logn success
  bool _isLogon = false;

  bool _debug = false;

  // TODO: display webview or not, can be with more params：readdy, debug etc.
  bool get _showWebview => _debug || _hasLoginPage;

  @override
  void initState() {
    super.initState();

    initAsync();
  }

  initAsync() async {
    _controller = TaobaoPageController._(this);

    // we need to subscribe event in this function
    widget.onCreated?.call(_controller);

    // first create a login page for all state.
    Page _homepage;
    _homepage = await _controller.openPage(
      H5PageUrls.login,
      onLoadStop: (controller, url) {
        if (H5PageUrls.isLogin(url)) {
          // has login page
          print("[taobao page] has login page");
          _controller.emit(EventHasLoginPage(_homepage, url));
          setState(() => _hasLoginPage = true);
        } else {
          if (_hasLoginPage) setState(() => _hasLoginPage = false);
        }

        if (H5PageUrls.isHome(url)) {
          print("[taobao page] guess we have login success => $url");
          // TODO: trick, in some low version android, we can't check use h5api
          setState(() {
            _isLogon = true;
          });
          // check if we have logon success
          _controller.h5api.userProfile(check: true).then((value) {
            // TODO: notify all page we have logon success
            _controller.emit(EventUserLogon(_homepage, value));
            setState(() => _isLogon = true );
            widget.onUserLogon?.call(_controller, value);
            print("[taobao page] confirm we have login success");
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

  void _addPage(Page page) {
    setState(() {
      _pages.add(page);
    });
  }

  void _setDebug(bool v) {
    setState(() => _debug = v);
  }
}

class TaobaoPageController {

  _TaobaoPageState _state;

  EventBus _eventBus;

  PCWeb pcweb;
  H5API h5api;

  TaobaoPageController._(
    this._state,
  ) {

    _eventBus = EventBus();

    // TODO: start timer to clean inactive page
    pcweb = PCWeb(this);
    h5api = H5API(this);
  }

  // pages return pages we have
  List<Page> get pages => _state._pages;

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

  Future<dynamic> doAction(ActionJob action) async {
    
    // check if we are already login
    if (!_state._isLogon && !action.noLogin) return Future.error("not account login");

    // TODO: optmize, use hashmap
    int _index;
    for (var i=0; i<_state._pages.length; i++) {
      if (_state._pages[i].match(action.url)) {
        _index = i;
        break;
      }
    }

    // if we found matched page, just do action
    // TODO: check pages overload, try another page
    if (_index != null) return _state._pages[_index].doAction(action);

    // open a new page to do this action
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

    // TODO: reuse page with empty job queue, except which has keepalive

    if (_state._pages.length>_state.widget.maxTab) {
      // TODO: make a page can be turn to a new one
      return Future.error("max tab ${_state.widget.maxTab}");
    }

    // get the new page's index
    final _len = _state._pages.length;

    // event filter page with id

    // init the new page
    Page page;
    page = Page(
      _len, url,
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
    );

    print("[controller] open the ${_len+1} page");

    // TODO: handle load page error, this page need be destroy

    _state._addPage(page);

    return Future.value(page);
  }

  Future<dynamic> checkUserLogin() {
  }
}