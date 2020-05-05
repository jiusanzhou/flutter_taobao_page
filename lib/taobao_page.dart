import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_taobao_page/action_page.dart';
import 'package:flutter_taobao_page/event.dart';
import 'package:flutter_taobao_page/login.dart';
import 'package:flutter_taobao_page/page_view.dart';
import 'package:flutter_taobao_page/taobao/h5.dart';
import 'package:flutter_taobao_page/taobao/pc.dart';
import 'package:flutter_taobao_page/utils.dart';
import 'package:flutter_taobao_page/webview.dart';

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
  with TickerProviderStateMixin<TaobaoPage>, AutomaticKeepAliveClientMixin<TaobaoPage> {

  @override
  bool get wantKeepAlive => true;

  TaobaoPageController _controller;

  TabController _tabController;

  List<Page> _pages = [];
  List<List<Page>> _pageGroups = [];

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // groups
  List<List<Page>> _buildPageGroups(BuildContext context) {
    List<List<Page>> tabs = [];
    List<Page> _tmp = [];
    int _idx = 0; // TODO: more customize, now always be the first one.
    _pages.forEach((p) {
      p.options.visible?tabs.add([p]):tabs.isEmpty?_tmp.add(p):tabs[_idx].add(p);
    });
    (tabs.isEmpty||tabs[_idx].isEmpty)?tabs.add(_tmp):tabs[_idx].addAll(_tmp);

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
      _tabController = TabController(initialIndex: tabs.length-1, length: tabs.length, vsync: this);
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
      index: _showWebview?1:0,
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

  void _addPage(Page page) {
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

  void _changePage(Page page) {
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

  // is login
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

  // grooups pages
  List<List<Page>> get pageGroups => _state._pageGroups;

  TabController get tabController => _state._tabController;

  Page get currentViewPage => _state._pageGroups[_state._tabIndex][_state._stackIndex];

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
    ActionJob action,
    {
      CreatedCallback onCreated,
      LoadStartCallback onLoadStart,
      LoadStopCallback onLoadStop,
      LoadErrorCallback onLoadError,
      PageOptions options,
    }
  ) async {
    
    // check if we are already login
    if (!_state._isLogon && !action.noLogin) return Future.error("not account login");

    // find match
    Page curp = _state._pages.firstWhere((p) => p.match(action.url), orElse: () => null);
    // if we found matched page, just do action
    // TODO: check pages overload, try another page
    if (curp != null) return curp.doAction(action);

    // open a new page to do this action
    return openPage(
      action.url,
      options: options,
      onCreated: onCreated,
      onLoadStart: onLoadStart,
      onLoadStop: onLoadStop,
      onLoadError: onLoadError,
    ).then((Page page) {
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
      PageOptions options,
    }
  ) {

    // NOTE: fix bug in getter null
    if (options==null) options = PageOptions();

    // if (H5PageUrls.isLogin(url)) return Future.error("don't allow open login page");

    // TODO: reuse page with empty job queue, except which has keepalive

    if (_state._pages.length>_state.widget.maxTab) {
      // TODO: make a page can be turn to a new one
      return Future.error("max tab ${_state.widget.maxTab}");
    }

    if (options!=null && options.max > 0) {
      List<Page> ps = _state._pages.where((p) => p.match(url)).toList();
      if (ps.length >= options.max) {
        // TODO: get the random page
        if (options.refresh) ps[0].webviewController.reload(); // TODO: should replace onHandler?
        return Future.value(ps[0]);
      }
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
      options: options,
    );

    print("[controller] open the ${_len+1} page");

    // TODO: handle load page error, this page need be destroy

    _state._addPage(page);

    return Future.value(page);
  }

  // show special page
  void showPage(Page page) {
    // set with tab index and stack index
    // for now just auto display with our hook
    _state._changePage(page);
  }

  // show special page with url
  void showPageWithUrl(String url) {
    Page page = getPageWithUrl(url);
    if (page!=null) return showPage(page);
    print("can't found page with url: $url, maybe you should open it first.");
  }

  Page getPageWithUrl(String url) {
    return _state._pages.firstWhere((element) => element.match(url), orElse: () => null);
  }

  // clean and reset
  void reset() {
    _state._reset();
  }
}