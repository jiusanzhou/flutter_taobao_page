

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

  final FocusNode _inputFocus = FocusNode();
  TextEditingController _inputController = TextEditingController();

  _updateStyle(TextStyle st, Map<String, dynamic> data) {
    setState(() {
      _obscureText = data["type"] == "password";

      _textStyle = st.copyWith(fontSize: st.fontSize - 0 );
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

  _displayInput(bool v) {
    if (!v) {
      // 隐藏fake
        setState(() {
        _display = false;
        _textStyle = _textStyle?.copyWith(color: Colors.transparent);
        });
    } else {
      // 显示fake
        setState(() {
        _display = true;
        _textStyle = _textStyle?.copyWith(color: Colors.black);
      });
    }
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

    _inputFocus.addListener(() {
      print("获得焦点 ${_inputFocus.hasFocus}");

      // 如果失去焦点，就隐藏 fake
      if (!_inputFocus.hasFocus) {
        // 隐藏fake, 显示html
        _displayInput(false);
        _controller.hiddenInput(false);
      }
    });
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
              autofocus: false, /// don't works well
              style: _textStyle,
              controller: _inputController,
              obscureText: _obscureText,
              focusNode: _inputFocus,
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
    controller.addJavaScriptHandler(handlerName: "echo", callback: _onEcho);
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
    var _sbonfocus = setInterval(function(){
      // var _ins = document.querySelectorAll("input"); // focus
      if (!document) return;
      clearInterval(_sbonfocus);
      var _ins = [document];
      // touchstart
      _ins.forEach((e) => e.addEventListener("touchend", function(i) {
        // _callhackerback("echo", i.target.tagName);

        if (i.target.tagName === "FORM") {
          i.preventDefault();
          return;
        }

        if (i.target.tagName !== "INPUT") return;

        // rect, style
        if (window.__inputelement) window.__inputelement.style.color = "#000"; //  恢复颜色
        window.__inputelement = i.target;
        // i.target.setAttribute("zoe-fake-input", setTimeout(function(){}))
        var __style = getComputedStyle(i.target);
        var __tmpstyle = {
          fontSize: parseFloat(__style.fontSize),
        };
        _callhackerback("input_fouce", "", {
          "rect": __inputelement.getBoundingClientRect().toJSON(),
          "style": __tmpstyle,
          "value": i.target.value,
          "type": i.target.getAttribute("type"),
          "screen": { width: screen.availWidth, height: screen.availHeight },
        });
        i.preventDefault();
      }, true));
    },500);
    '_____onfoucejs'
  """;

  final _onscrolljs = """
    // onscroll, hidden fake input
    window.addEventListener("scroll", function(e) {
      _callhackerback("scroll", "", __inputelement.getBoundingClientRect().toJSON())
    });
    '_____onscrolljs'
  """;

  void onLoadStart(InAppWebViewController controller, String url) {
    print("webview hacker, webviwe start url: $url");
    // must install, js can call  _callhackerback(...args);
    controller.evaluateJavascript(source: _installcallback()).then((value) => print("执行成功 => $value"));

    // 安装监听事件, 设置定时器重复执行, 什么时候去执行呢?
    controller.evaluateJavascript(source: _onfocusjs).then((value) => print("执行成功 => $value"));
    controller.evaluateJavascript(source: _onscrolljs).then((value) => print("执行成功 => $value"));

  }

  void onLoadStop(InAppWebViewController controller, String url) {
    print("webview hacker, webviwe finish url: $url");
  }

  Rect _orginalRect;

  dynamic _onInputFouce(List<dynamic> args) {
    String path = args[0];
    print("==== 点击了 input ===> ${args[1]}");
    var data = json.decode(args[1]);
    _orginalRect = Rect.fromJson(data["rect"]);
    _state._updatePosAndSize(_orginalRect.left, _orginalRect.top, width: _orginalRect.width, height: _orginalRect.height);

    _state._updateStyle(getTextStyleFromJson(data["style"]), data);

    _state._updateValue(data["value"]);
    // 保存 hacker id, 便于找到唯一 element


    // 这里去显示fake，hidden real

    hiddenInput(true);

    return "";
  }

  dynamic _onScroll(List<dynamic> args) {
    Rect rect = Rect.fromJson(json.decode(args[1]));
    _state._updatePosAndSize(rect.left, rect.top);
    return "";
  }

  dynamic _onEcho(List<dynamic> args) {
    print("[ECHO] ===> $args");
    return "";
  }

  setValueToInput(String v) {
    var code = """
    __inputelement.value = "$v"; '____setvaluetoinput'
    """;
    _webcontroller.evaluateJavascript(source: code).then((value) => print("执行成功 => $value"));
  }

  hiddenInput(bool v) {
    var code = """
__inputelement.style.color = "${v?"transparent":"#000"}";
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
    x = checkDouble(data["x"]).toDouble();
    y = checkDouble(data["y"]).toDouble();
    width = checkDouble(data["width"]).toDouble();
    height = checkDouble(data["height"]).toDouble();
    top = checkDouble(data["top"]).toDouble();
    right = checkDouble(data["right"]).toDouble();
    left = checkDouble(data["left"]).toDouble();
  }

  static double checkDouble(dynamic value) {
    if (value is String) {
      return double.parse(value);
    } else if (value is int) {
      return value.toDouble();
    } else {
      return value;
    }
  }
}

TextStyle getTextStyleFromJson(Map<String, dynamic> data) {
  TextStyle t = TextStyle(
    fontSize: (data["fontSize"] as int).toDouble(),
  );
  return t;
}