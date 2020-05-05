import 'package:flutter/material.dart';
import 'package:flutter_taobao_page/action_page.dart';

class TaobaoPageView extends StatefulWidget {

  final int stackIndex; // 当前显示栈 index
  // final List<Page> children; // 
  final bool scrollable;
  final Widget title;
  final TabController tabController;

  final List<List<Page>> groupedPages;

  TaobaoPageView({
    // this.children,
    this.groupedPages,
    this.stackIndex,
    this.scrollable: true,
    this.title: const Text("淘宝数据"),
    this.tabController,
  });

  @override
  _TaobaoPageViewState createState() => _TaobaoPageViewState();
}

class _TaobaoPageViewState extends State<TaobaoPageView> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // build tabs with page groups, if only one maybe we just render with stack?
    // final _grps = _buildPageGroups(context);

    // if (_grps.length==0) return Container(child: Text("no pages")); 
    // if (_grps.length==1) return _buildStack(context, _grps[0]);

    final _grps = widget.groupedPages;

    return TabBarView(
      controller: widget.tabController,
      physics: widget.scrollable?const AlwaysScrollableScrollPhysics():const NeverScrollableScrollPhysics(),
      children: List.generate(_grps.length, (index) => _buildStack(context, _grps[index])),
    );

    // build tabs
    // return DefaultTabController(
    //   length: _grps.length,
    //   initialIndex: widget.tabIndex, // alway make sure each tab rendered
    //   // how to add title
    //   child: Scaffold(
    //     appBar: AppBar(
    //       automaticallyImplyLeading: false,
    //       title: TabBar(
    //         tabs: List.generate(_grps.length, (index) => Tab(text: _grps[index][0].options.title??"-")),
    //       ),
    //     ),
    //     body: TabBarView(
    //       physics: widget.scrollable?const AlwaysScrollableScrollPhysics():const NeverScrollableScrollPhysics(),
    //       children: List.generate(_grps.length, (index) => _buildStack(context, _grps[index])),
    //     ),
    //   ),
    // );
  }

  // TDO: more custommize
  // List<List<Page>> _buildPageGroups(BuildContext context) {
  //   List<List<Page>> tabs = [];
  //   List<Page> _tmp = [];
  //   int _idx = 0; // TODO: more customize, now always be the first one.
  //   widget.children.forEach((p) {
  //     p.options.visible?tabs.add([p]):tabs[_idx]==null?_tmp.add(p):tabs[_idx].add(p);
  //   });
  //   tabs[_idx]==null?tabs.add(_tmp):tabs[_idx].addAll(_tmp);
  //   return tabs;
  // }

  // [ 0 ]
  // [ 1 ]
  // [ 2 ]
  // [ 3 ]

  // [ 0 ] [ 1 ] [ 2 ] [ 3 ]
  // [ 4 ] [ 5 ] [ 6 ] [ 7 ]
  // [ 8 ] [ 9 ]
  Widget _buildStack(BuildContext context, List<Page> pages) {
    return IndexedStack(
      index: widget.stackIndex,
      children: List.generate(pages.length, (index) => pages[index].webview),
    );
  }
}