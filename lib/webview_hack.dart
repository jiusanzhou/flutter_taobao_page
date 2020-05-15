

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
      _inputController.selection = TextSelection.fromPosition(TextPosition(offset: value.length));
      
      // _inputController.selection = _inputController.selection.copyWith(baseOffset: value.length);
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
      // 隐藏fake, 最好把他移走
      setState(() {
        _display = false;
        _textStyle = _textStyle?.copyWith(color: Colors.transparent);

        print("隐藏键盘后移动走");
        _posTop = -100;
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
        // 隐藏fake, 显示html,最好把他移走
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
            color: Colors.blueAccent[300],
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


  String _installcallback() {

    String code;

    if (Platform.isAndroid) {
      code = "flutter_inappwebview._callHandler(args[0], setTimeout(function(){}), JSON.stringify(args.slice(1).map(function(e){return JSON.stringify(e)})))";
    } else {
      code = "flutter_inappwebview.callHandler(...args)";
    }

    return """var _callhackerback = function(...args) { return $code }; '_____installbackchannel'""";
  }

  final _fakeInputName = "zoe-fake-input";

  String _fakeInputID = "";

  final _onprocesshandlejs = """
  window.__onprocesshandler = function(event) {
    let i = event;

    // 调试打印
    _callhackerback("echo", "TAG: " + i.target.tagName + " <=== on touched");

    // FORM 需要取消事件，防止边缘触发
    if (i.target.tagName === "FORM") {
      i.preventDefault();
      _callhackerback("echo", "点击对象为 FORM，防止边缘点击，取消事件");
      return;
    }

    // 非 INPUT 输入框 就不处理
    if (i.target.tagName !== "INPUT") {
      _callhackerback("echo", "非INPUT点击，不处理");
      return;
    }

    // 硬编码: 目前只处理淘宝帐号/密码的输入框
    if (i.target.id !== "fm-login-password" && i.target.id !== "fm-login-id") {
      _callhackerback("echo", "INPUT的ID为:"+i.target.id+",不是登录框，不处理");
      return;
    }

    _callhackerback("echo", "进入处理流程...");

    // 取得INPUT的完整样式
    var __style = getComputedStyle(i.target);

    // 如果原来有节点保存，将其颜色恢复, 这里懒得备份用当前节点的颜色
    if (window.__inputelement) {
      _callhackerback("echo", "[*] 原来点击过，将其颜色恢复");
      window.__inputelement.style.color = __style.color;
    }

    _callhackerback("echo", "[*] 取得样式");

    // 生成需要的样式
    var __tmpstyle = {
      fontSize: parseFloat(__style.fontSize), // 目前只返回字体大小
    };

    _callhackerback("echo", "[*] 取得字体大小");

    // 保存节点，以便接受控制
    window.__inputelement = i.target;

    try {
      // 报告事件: ID目前没有设置，使用全局变量保存当前节点
      let rect = __inputelement.getBoundingClientRect();

      // 判断是否获取成功
      if (!rect.x) {
        _callhackerback("echo", "[*] 点击对象获取 Rect 失败");
        function getPosition( el ) {
            var x = 0;
            var y = 0;
            while( el && !isNaN( el.offsetLeft ) && !isNaN( el.offsetTop ) ) {
              x += el.offsetLeft - el.scrollLeft;
              y += el.offsetTop - el.scrollTop;
              el = el.offsetParent;
            }
            return { top: y, left: x, y, x };
        }
        // 使用其他办法尝试获取
        rect = getPosition(__inputelement);
        rect.height = __inputelement.clientHeight;
        rect.width = __inputelement.clientWidth;
      }

      _callhackerback("input_fouce", "", {
        "rect": rect, // 大小和位置
        "style": __tmpstyle, // 样式
        "value": i.target.value, // 数据值
        "type": i.target.getAttribute("type"), // 表单类型
        "screen": { width: screen.availWidth, height: screen.availHeight }, // 屏幕大小
      });
      _callhackerback("echo", "[*] 报告 input_fouce 成功");
    } catch(e) {
      _callhackerback("echo", "[*] 报告 input_fouce 失败:"+e);
    }


    // 停止事件
    i.preventDefault();

    _callhackerback("echo", "[*] 处理完成");
  };
  '_____install process handler'
  """;

  final _onclickinputjs = """
    // try{flutter_inappwebview._callHandler("echo", "xxxx", JSON.stringify(["测试执行 ===>"]));}catch(e) {alert(e)}
    var _sbclickinput = setInterval(function(){
      var _ins = document.querySelectorAll("input"); // focus
      if (_ins.length === 0) return;

      clearInterval(_sbclickinput);

      // _callhackerback("echo", "给所有 input (" + _ins.length + ") 添加 事件监听");

      _ins.forEach(function(e) {
        e.addEventListener("touchend", __onprocesshandler, true)
      });
    },500);
    '________clickinputjs'
  """;

  final _onclickdocumentjs = """
    var _sbclickdocument = setInterval(function(){
      if (!document) return;
      clearInterval(_sbclickdocument);

      // _callhackerback("echo", "给 document 添加 事件监听");

      // touchstart
      document.addEventListener("touchend", __onprocesshandler, true);
    }, 500);
    '_____onclickdocumentjs'
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

    // 安装回调工具函数
    controller.evaluateJavascript(source: _installcallback()).then((value) => print("执行成功 => $value"));

    // 安装滚动事件触发监听
    controller.evaluateJavascript(source: _onscrolljs).then((value) => print("执行成功 => $value"));

    // 安装点击/fouce处理函数
    controller.evaluateJavascript(source: _onprocesshandlejs).then((value) => print("执行成功 => $value"));

    // 安装点击/fouce监听
    // 在start中可以监听document来处理
    controller.evaluateJavascript(source: _onclickdocumentjs).then((value) => print("执行成功 => $value"));
  }

  void onLoadStop(InAppWebViewController controller, String url) {
    print("webview hacker, webviwe finish url: $url");

    // 安装回调工具函数
    controller.evaluateJavascript(source: _installcallback()).then((value) => print("执行成功 => $value"));

    // 安装滚动事件触发监听
    controller.evaluateJavascript(source: _onscrolljs).then((value) => print("执行成功 => $value"));

    // 安装点击/fouce处理函数
    controller.evaluateJavascript(source: _onprocesshandlejs).then((value) => print("执行成功 => $value"));

    // 安装点击/fouce监听
    // 查找到所有的input表单进行处理
    controller.evaluateJavascript(source: _onclickinputjs).then((value) => print("执行成功 => $value"));
  }

  bool runned = false;
  void onProcessChange(InAppWebViewController controller, int process) {
    print("[LOADING] ====> $process");
  }

  Rect _orginalRect;

  dynamic _onInputFouce(List<dynamic> args) {
    print("==== 点击了 input ===> ${args[1]}");
    var data = json.decode(args[1]);
    _orginalRect = Rect.fromJson(data["rect"]);
    _state._updatePosAndSize(_orginalRect.left, _orginalRect.top, width: _orginalRect.width, height: _orginalRect.height);

    _state._updateStyle(getTextStyleFromJson(data["style"]), data);

    _state._updateValue(data["value"]);

    hiddenInput(true);

    return "";
  }

  dynamic _onScroll(List<dynamic> args) {
    Rect rect = Rect.fromJson(json.decode(args[1]));
    _state._updatePosAndSize(rect.left, rect.top);

    print("[SCROLL] ======> ${rect.y}");
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
  // double right;
  // double bottom;
  double left;

  Rect.fromJson(Map<String, dynamic> data) {
    x = checkDouble(data["x"]).toDouble();
    y = checkDouble(data["y"]).toDouble();
    width = checkDouble(data["width"]).toDouble();
    height = checkDouble(data["height"]).toDouble();
    top = checkDouble(data["top"]).toDouble();
    // right = checkDouble(data["right"]).toDouble();
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