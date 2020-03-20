import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

typedef void CreatedCallback(InAppWebViewController controller);
typedef void LoadStartCallback(InAppWebViewController controller, String url);
typedef void LoadStopCallback(InAppWebViewController controller, String url);
typedef void LoadErrorCallback(InAppWebViewController controller, String url, int code, String message);

class TaobaoWebview extends StatefulWidget {
  ///Event fired when the [InAppWebView] is created.
  final void Function(InAppWebViewController controller) onWebViewCreated;

  ///Event fired when the [InAppWebView] starts to load an [url].
  final void Function(InAppWebViewController controller, String url)
      onLoadStart;

  ///Event fired when the [InAppWebView] finishes loading an [url].
  final void Function(InAppWebViewController controller, String url) onLoadStop;

  ///Event fired when the [InAppWebView] encounters an error loading an [url].
  final void Function(InAppWebViewController controller, String url, int code,
      String message) onLoadError;

  final String initialUrl;

  TaobaoWebview({
    this.initialUrl: "about:blank",

    this.onWebViewCreated,
    this.onLoadStart,
    this.onLoadStop,
    this.onLoadError,
  });

  @override
  _TaobaoWebviewState createState() => _TaobaoWebviewState();
}

class _TaobaoWebviewState extends State<TaobaoWebview> {

  void _onWebViewCreated(InAppWebViewController controller) {

    // 
    if (widget.onWebViewCreated!=null) widget.onWebViewCreated(controller);
  }

  void _onLoadStart(InAppWebViewController controller, String url) {

    // 
    if (widget.onLoadStart!=null) widget.onLoadStart(controller, url);
  }

  void _onLoadStop(InAppWebViewController controller, String url) {

    // 
    if (widget.onLoadStop!=null) widget.onLoadStop(controller, url);
  }

  void _onLoadError(InAppWebViewController controller, String url, int code, String message) {

    // 
    if (widget.onLoadError!=null) widget.onLoadError(controller, url, code, message);
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrl: widget.initialUrl,
      initialOptions: InAppWebViewWidgetOptions(inAppWebViewOptions: InAppWebViewOptions(javaScriptEnabled: true, debuggingEnabled: false)),
      onWebViewCreated: _onWebViewCreated,
      onLoadStart: _onLoadStart,
      onLoadStop: _onLoadStop,
      onLoadError: _onLoadError,
    );
  }
}

// 添加webview控制器