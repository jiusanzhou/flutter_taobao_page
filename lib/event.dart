import 'package:flutter_taobao_page/action_page.dart';

// define taobao page event

class EventPageCreated {
  Page page;

  EventPageCreated(this.page);
}

class EventPageLoadStart {
  Page page;
  String url;

  EventPageLoadStart(this.page, this.url);
}

class EventPageLoadStop {
  Page page;
  String url;

  EventPageLoadStop(this.page, this.url);
}

class EventPageLoadError {
  Page page;
  String url;
  int code;
  String message;

  EventPageLoadError(this.page, this.url, this.code, this.message);
}

class EventHasLoginPage {
  Page page;
  String url;

  EventHasLoginPage(this.page, this.url);
}

class EventUserLogon {
  Page page;
  dynamic data;

  EventUserLogon(this.page, this.data);
}