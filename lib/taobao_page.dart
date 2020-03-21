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

  final Widget child;

  final void Function(TaobaoPageController controller) onCreated;

  final void Function(TaobaoPageController controller, dynamic data) onUserLogon;

  TaobaoPage({
    @required this.child,
    this.maxTab: 20,
    this.onCreated,
    this.onUserLogon,
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

  // if we have any login apge
  bool _hasLoginPage = false;

  // we have logn success
  bool _isLogon = false;

  bool _debug = false;

  bool _scrollable = false;

  int _tabIndex = 0; // 当前显示的 index
  int _stackIndex = 0; // 当前显示栈 index

  // TODO: display webview or not, can be with more params：readdy, debug etc.
  bool get _showWebview => _debug || _hasLoginPage;

  @override
  void initState() {
    super.initState();

    initAsync();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  initAsync() async {
    _controller = TaobaoPageController._(this);

    // we need to subscribe event in this function
    widget.onCreated?.call(_controller);

    // first create a login page for all state.
    Page _homepage;
    _homepage = await _controller.openPage(
      H5PageUrls.mhome,
      options: PageOptions(
        keepalive: true,
        visible: true,
      ),
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
          // set the page's url to be home page???
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

  // groups
  List<List<Page>> _buildPageGroups(BuildContext context) {
    List<List<Page>> tabs = [];
    List<Page> _tmp = [];
    int _idx = 0; // TODO: more customize, now always be the first one.
    _pages.forEach((p) {
      p.options.visible?tabs.add([p]):tabs[_idx]==null?_tmp.add(p):tabs[_idx].add(p);
    });
    tabs[_idx]==null?tabs.add(_tmp):tabs[_idx].addAll(_tmp);

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
      _tabController.animateTo(page.groupId);
      _stackIndex = page.stackId;
    });
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

  // grooups pages
  List<List<Page>> get pageGroups => _state._pageGroups;

  TabController get tabController => _state._tabController;

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

  void setScrollable(bool v) {
    _state._setScrollable(v);
  }

  Future<dynamic> doAction(ActionJob action) async {
    
    // check if we are already login
    if (!_state._isLogon && !action.noLogin) return Future.error("not account login");

    // find match
    Page curp = _state._pages.firstWhere((p) => p.match(action.url), orElse: () => null);
    // if we found matched page, just do action
    // TODO: check pages overload, try another page
    if (curp != null) return curp.doAction(action);

    // open a new page to do this action
    return openPage(action.url, options: PageOptions()).then((Page page) {
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

    // if (H5PageUrls.isLogin(url)) return Future.error("don't allow open login page");

    // TODO: reuse page with empty job queue, except which has keepalive

    if (_state._pages.length>_state.widget.maxTab) {
      // TODO: make a page can be turn to a new one
      return Future.error("max tab ${_state.widget.maxTab}");
    }

    if (options.max > 0) {
      List<Page> ps = _state._pages.where((p) => p.match(url)).toList();
      if (ps.length >= options.max) {
        // TODO: get the random page
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
    Page page = _state._pages.firstWhere((element) => element.match(url), orElse: () => null);
    if (page!=null) return showPage(page);
    print("can't found page with url: $url, maybe you should open it first.");
  }
}