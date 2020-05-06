

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// listen event on fouce
// dispath the event from html
// create a proxy input field with `getBoundingClientRect()`

class WebviewHack extends StatefulWidget {

  final Widget child;
  final Widget Function(BuildContext context, WebviewHackController controller) builder;

  WebviewHack({
    this.child,
    this.builder,
  }) : assert(child!=null || builder != null);

  @override
  _WebviewHackState createState() => _WebviewHackState();
}

class _WebviewHackState extends State<WebviewHack> {

  WebviewHackController _controller;

  bool _display = false;

  double _posTop = 0;
  double _posLeft = 0;
  double _sizeHeight = 1;
  double _sizeWidth = 61;

  bool _obscureText  = false;

  TextStyle _textStyle;

  TextEditingController _inputController = TextEditingController();

  _updateStyle(TextStyle st, Map<String, dynamic> data) {
    setState(() {
      _obscureText = data["type"] == "password";

      _textStyle = st.copyWith(fontSize: st.fontSize - 2 );
    });
  }

  _updateValue(String value) {
    setState(() {
      _inputController.text = value;
    });
  }

  _updatePosAndSize(double x, double y, { double width, double height }) {
    setState(() {
      _posTop = y; //.toDouble();
      _posLeft = x; //.toDouble();
      if (width!=null) _sizeWidth = width; //.toDouble();
      if (height!=null) _sizeHeight = height; //.toDouble();
    });
  }

  _toggleDisplay({bool flag}) {
    setState(() {
      _display = flag != null ? flag : !_display;
    });
  }

  @override
  void initState() {
    super.initState();

    _controller = WebviewHackController(this);

    // KeyboardVisibilityNotification().addNewListener(
    //   onChange: (bool visible) {
    //     var h = MediaQuery.of(context).viewInsets.bottom;
    //     print("================> 键盘${visible?"弹":"缩"}起来了 ($h) <<<<<<");
    //   },
    // );
  }

  @override
  Widget build(BuildContext context) {
    // TOOD:
    // if (MediaQuery.of(context).viewInsets.bottom>0) {
    //   print("================> 键盘弹起来了 <<<<<<");
    // }

    return Stack(
      children: <Widget>[
        widget.child ?? widget.builder(context, _controller),
        Positioned(
          top: _posTop,
          left: _posLeft,
          height: _sizeHeight,
          width: _sizeWidth == null ? null : _sizeWidth - 60, // TODO: FIXME hardcode
          child: Container(
            // color: Colors.blueAccent,
            padding: EdgeInsets.symmetric(horizontal: 5), // TODO: FIXME hardcode
            child: TextField(
              cursorColor: Colors.black,
              cursorWidth: 1,
              autofocus: true, /// don't works well
              style: _textStyle,
              controller: _inputController,
              obscureText: _obscureText,
              decoration: InputDecoration(border: InputBorder.none),
              onChanged: (v) {
                // set value to element
                _controller.setValueToInput(v);
              },
            )
          )
        ),
      ],
    );

  }
}

class WebviewHackController {

  _WebviewHackState _state;

  WebviewHackController(this._state);

  InAppWebViewController _webcontroller;

  // 安装 input proxy

  void onWebViewCreated(InAppWebViewController controller) {
    _webcontroller = controller;
    print("webview hacker, webviwe created");
    controller.addJavaScriptHandler(handlerName: "input_fouce", callback: _onInputFouce);
    controller.addJavaScriptHandler(handlerName: "scroll", callback: _onScroll);
  }


  /// flow: onfouce => set .... =>
  /// 
  /// 
  /// 


  String _installcallback() {

    String code;

    if (Platform.isAndroid) {
      code = "flutter_inappwebview._callHandler(args[0], setTimeout(function(){}), JSON.stringify(args.slice(1).map(e=>JSON.stringify(e))))";
    } else {
      code = "flutter_inappwebview.callHandler(...args)";
    }

    return "window._callhackerback = function(...args) { return $code }; '_____hackerback'";
  }

  final _fakeInputName = "zoe-fake-input";

  String _fakeInputID = "";

  final _onfocusjs = """
    var _ins = document.querySelectorAll("input"); // focus
    var __inputelement;
    // touchstart
    _ins.forEach((e) => e.addEventListener("touchend", function(i) {
      // rect, style
      __inputelement = i.target;
      // __inputelement.setAttribute("zoe-fake-input", setTimeout(function(){}))
      var __style = getComputedStyle(i.target);
      var __tmpstyle = {
        fontSize: parseFloat(__style.fontSize),
      };
      _callhackerback("input_fouce", "", {
        "rect": __inputelement.getBoundingClientRect().toJSON(),
        "style": __tmpstyle,
        "value": __inputelement.value,
        "type": __inputelement.getAttribute("type"),
        "screen": { width: screen.availWidth, height: screen.availHeight },
      });
      i.preventDefault();
    }, true));
    '_____onfoucejs count:' + _ins.length
  """;

  final _onscrolljs = """
    // onscroll, hidden fake input
    window.addEventListener("scroll", function(e) {
      _callhackerback("scroll", "", __inputelement.getBoundingClientRect().toJSON())
    });
    '_____onscrolljs'
  """;

  void onLoadStop(InAppWebViewController controller, String url) {
    print("webview hacker, webviwe finish url: $url");

    // must install, js can call  _callhackerback(...args);
    controller.evaluateJavascript(source: _installcallback()).then((value) => print("执行成功 => $value"));

    // 安装监听事件, 设置定时器重复执行, 什么时候去执行呢?
    controller.evaluateJavascript(source: _onfocusjs).then((value) => print("执行成功 => $value"));

    controller.evaluateJavascript(source: _onscrolljs).then((value) => print("执行成功 => $value"));
  }

  Rect _orginalRect;

  dynamic _onInputFouce(List<dynamic> args) {
    String path = args[0];
    print("=======> ${args[1]}");
    var data = json.decode(args[1]);
    _orginalRect = Rect.fromJson(data["rect"]);
    _state._updatePosAndSize(_orginalRect.left, _orginalRect.top, width: _orginalRect.width, height: _orginalRect.height);

    _state._updateStyle(getTextStyleFromJson(data["style"]), data);

    _state._updateValue(data["value"]);
    // 保存 hacker id, 便于找到唯一 element
    return "";
  }

  dynamic _onScroll(List<dynamic> args) {
    Rect rect = Rect.fromJson(json.decode(args[1]));
    _state._updatePosAndSize(rect.left, rect.top);
  }

  setValueToInput(String v) {
    var code = """
    __inputelement.value = "$v"; '____setvaluetoinput'
    """;
    _webcontroller.evaluateJavascript(source: code).then((value) => print("执行成功 => $value"));
  }
}

class Rect {
  double x;
  double y;
  double width;
  double height;
  double top;
  double right;
  double bottom;
  double left;

  Rect.fromJson(Map<String, dynamic> data) {
    x = (data["x"] as int).toDouble();
    y = (data["y"] as int).toDouble();
    width = (data["width"] as int).toDouble();
    height = (data["height"] as int).toDouble();
    top = (data["top"] as int).toDouble();
    right = (data["right"] as int).toDouble();
    left = (data["left"] as int).toDouble();
  }
}

TextStyle getTextStyleFromJson(Map<String, dynamic> data) {
  TextStyle t = TextStyle(
    fontSize: (data["fontSize"] as int).toDouble(),
    color: Colors.transparent, // important!!!!!
  );
  return t;
}