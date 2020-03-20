import 'package:flutter/material.dart';

class TaobaoPageView extends StatefulWidget {

  final ViewMode mode; // 显示模式
  final int index; // 当前显示的 index
  final List<Widget> children; // 

  TaobaoPageView({
    this.mode,
    this.children,
    this.index
  });

  @override
  _TaobaoPageViewState createState() => _TaobaoPageViewState();
}

class _TaobaoPageViewState extends State<TaobaoPageView> {

  ViewMode _mode; // 显示模式
  int _index; // 当前显示的 index

  @override
  void initState() {
    super.initState();

    _mode = widget.mode;
    _index = widget.index;
  }

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
    case ViewMode.stack:
      return buildStack(context);
    case ViewMode.tabview:
      return buildTabview(context);
    default:
      return buildUnknown(context);
    }
  }

  Widget buildStack(BuildContext context) {
    return IndexedStack(
      index: _index,
      children: widget.children,
    );
  }

  Widget buildTabview(BuildContext context) {
    return buildUnknown(context);
  }

  Widget buildUnknown(BuildContext context) {
    return Center(
        child: Container(
          child: Text("unimplement view mode $_mode"),
        ),
      );
  }
}

// 显示模式
enum ViewMode {
  stack,
  tabview,
}