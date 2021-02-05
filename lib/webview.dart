import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

typedef void CreatedCallback(InAppWebViewController controller);
typedef void LoadStartCallback(InAppWebViewController controller, String url);
typedef void LoadStopCallback(InAppWebViewController controller, String url);
typedef void LoadErrorCallback(InAppWebViewController controller, String url, int code, String message);

const UA_PC = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.135 Safari/537.36";
const UA_IOS = "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1";

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

  final void Function(InAppWebViewController controller, int progress) onProgressChanged;

  final String initialUrl;

  final bool useMobile;

  final List<ContentBlocker> blockers;

  final bool quickOnFinish;

  TaobaoWebview({
    this.initialUrl: "about:blank",
    this.useMobile: false,

    this.onWebViewCreated,
    this.onLoadStart,
    this.onLoadStop,
    this.onLoadError,

    this.onProgressChanged,

    this.quickOnFinish: true,

    this.blockers: const [],
  });

  @override
  _TaobaoWebviewState createState() => _TaobaoWebviewState();
}

class _TaobaoWebviewState extends State<TaobaoWebview> with AutomaticKeepAliveClientMixin<TaobaoWebview> {

  @override
  bool get wantKeepAlive => true;

  void _onWebViewCreated(InAppWebViewController controller) {

    // 
    if (widget.onWebViewCreated!=null) widget.onWebViewCreated(controller);
  }

  void _onLoadStart(InAppWebViewController controller, String url) {
    tmpurl = url;

    if (widget.onLoadStart!=null) widget.onLoadStart(controller, url);
  }

  void _onLoadStop(InAppWebViewController controller, String url) {

    // 
    if (widget.onLoadStop!=null) widget.onLoadStop(controller, url);
  }

  String tmpurl;
  int tmpval;
  void _onProcessChanged(InAppWebViewController controller, int v) {
    if (widget.onProgressChanged!=null) widget.onProgressChanged(controller, v);

    // 不是快速就不处理
    if (!widget.quickOnFinish) return;

    if (v == 100 && tmpval < 100) {
      // 应该就是第一次到达100，调用 onFinished
      _onLoadStop(controller, tmpurl);
    }

    // 保存 当前进度
    tmpval = v;
  }

  void _onLoadError(InAppWebViewController controller, String url, int code, String message) {

    // 
    if (widget.onLoadError!=null) widget.onLoadError(controller, url, code, message);
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrl: widget.initialUrl,
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          javaScriptEnabled: true,
          debuggingEnabled: false,
          contentBlockers: widget.blockers,
          preferredContentMode: widget.useMobile ? UserPreferredContentMode.MOBILE:UserPreferredContentMode.DESKTOP,
          // userAgent: widget.useMobile ? UA_IOS : UA_PC// we need to set correct ua for page to load
        ),
        android: AndroidInAppWebViewOptions(
          useWideViewPort: true,
          domStorageEnabled: true,
          hardwareAcceleration: false,
          // useHybridComposition: true,
        ),
      ),
      onWebViewCreated: _onWebViewCreated,
      onLoadStart: _onLoadStart,
      onLoadStop: widget.quickOnFinish?null:_onLoadStop, // 快速不绑定真实的 onStop
      onLoadError: _onLoadError,
      onProgressChanged: _onProcessChanged,
    );
  }
}

final killerBlocker = ContentBlocker(
  trigger: ContentBlockerTrigger(
    resourceType: [
      ContentBlockerTriggerResourceType.STYLE_SHEET,
      ContentBlockerTriggerResourceType.IMAGE,
      ContentBlockerTriggerResourceType.FONT,
      ContentBlockerTriggerResourceType.SCRIPT,
      ContentBlockerTriggerResourceType.MEDIA,
    ],
    urlFilter: "gm\.mmstat\.com|ynuf\.aliapp\.org|\.gif\$",
  ),
  action: ContentBlockerAction(
    type: ContentBlockerActionType.BLOCK,
  ),
);

ContentBlocker getPatternBlocker(String pattern) {
  return ContentBlocker(
    trigger: ContentBlockerTrigger(
      resourceType: [
        ContentBlockerTriggerResourceType.STYLE_SHEET,
        ContentBlockerTriggerResourceType.IMAGE,
        ContentBlockerTriggerResourceType.FONT,
        ContentBlockerTriggerResourceType.SCRIPT,
        ContentBlockerTriggerResourceType.MEDIA,
        ContentBlockerTriggerResourceType.RAW,
        ContentBlockerTriggerResourceType.DOCUMENT,
        ContentBlockerTriggerResourceType.SVG_DOCUMENT,
      ],
      urlFilter: pattern,
    ),
    action: ContentBlockerAction(
      type: ContentBlockerActionType.BLOCK,
    ),
  );
}

// 添加webview控制器