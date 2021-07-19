import 'package:flutter/material.dart';
import 'package:flutter_taobao_page/webview.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class DebugWebview extends StatefulWidget {
  @override
  _DebugWebviewState createState() => _DebugWebviewState();
}

class _DebugWebviewState extends State<DebugWebview> {
  InAppWebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Webview调试"),
      ),
      body: TaobaoWebview(
        initialUrl: "https://market.m.taobao.com/app/tbhome/common/error.html",
        onLoadStop: (controller, url) {
          // viewport
        },
        onWebViewCreated: (controller) {
          _controller = controller;
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.evaluateJavascript(source: """
          var _meta = document.querySelector('head > meta[name=viewport]');
          if ( _meta ) {
            _meta.setAttribute('content', '');
          } else {
            var metaTag=document.createElement('meta');
            metaTag.name = "viewport"
            metaTag.content = "width=2000, initial-scale=0.5, maximum-scale=1.0, user-scalable=0"
            document.getElementsByTagName('head')[0].appendChild(metaTag);
          }
          ; '_______'
          """).then((value) => print("执行结果: $value"));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
