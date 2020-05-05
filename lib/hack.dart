
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_taobao_page/taobao/h5.dart';

class HackKeepAlive extends StatefulWidget {

  HackKeepAlive();

  @override
  _HackKeepAliveState createState() => _HackKeepAliveState();
}

class _HackKeepAliveState extends State<HackKeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      child: InAppWebView(
        initialUrl: H5PageUrls.home,
        initialOptions: InAppWebViewWidgetOptions(inAppWebViewOptions: InAppWebViewOptions(javaScriptEnabled: true)),
      ),
    );
  }

  // Setting to true will force the tab to never be disposed. This could be dangerous.
  @override
  bool get wantKeepAlive => true;
}