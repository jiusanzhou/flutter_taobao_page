import 'package:flutter/material.dart';
import 'package:flutter_taobao_page/action_page.dart';

// define taobao page event

class EventPageCreated {
  WebviewPage page;

  EventPageCreated(this.page);
}

class EventPageLoadStart {
  WebviewPage page;
  String url;

  EventPageLoadStart(this.page, this.url);
}

class EventPageLoadStop {
  WebviewPage page;
  String url;

  EventPageLoadStop(this.page, this.url);
}

class EventPageLoadError {
  WebviewPage page;
  String url;
  int code;
  String message;

  EventPageLoadError(this.page, this.url, this.code, this.message);
}

class EventHasLoginPage {
  WebviewPage page;
  String url;

  EventHasLoginPage(this.page, this.url);
}

class EventUserLogon {
  WebviewPage page;
  dynamic data;

  EventUserLogon(this.page, this.data);
}

class EventTabControllerUpdate {
  TabController tabController;

  EventTabControllerUpdate(this.tabController);
}