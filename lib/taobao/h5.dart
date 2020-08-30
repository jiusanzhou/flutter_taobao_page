
import 'package:flutter_taobao_page/action_page.dart';
import 'package:flutter_taobao_page/taobao_page.dart';

class H5API {
  final TaobaoPageController controller;

  H5API(this.controller);

  // check if we are logon page

  // h5 login action and show result with pc
  // open a login page should add to the pages flow?
  // NO!
  // So, we need to open a login page and execute insert password and username
  // if offered, on stop load, check if is home page, if true, we have load
  // success, we need to close the login page webview imme

  Future<dynamic> userProfile({bool check}) {
    return controller.doAction(ActionJob(H5PageUrls.home, code: H5APICode.userProfile(), noLogin: check));
  }

  Future<dynamic> orderList({int page: 1, String type: "all"}) {
    return controller.doAction(ActionJob(H5PageUrls.home, code: H5APICode.orderList(page: page, type: type)));
  }

  Future<dynamic> orderDetail(String orderId) {
    return controller.doAction(ActionJob(H5PageUrls.home, code: H5APICode.orderDetail(orderId)));
  }

  Future<dynamic> logisDetail(String orderId) {
    return controller.doAction(ActionJob(H5PageUrls.home, code: H5APICode.logisDetail(orderId)));
  }

  Future<dynamic> vipScore() {
    return  controller.doAction(ActionJob(H5PageUrls.home, code: H5APICode.vipScore()));
  }
}

class H5APICode {

  static String userProfile() {
    return _basicRequest("mtop.taobao.mclaren.getuserprofile", "1.0", "{}");
  }

  // 订单列表
  // all, waitRate, waitConfirm, waitSend, waitPay
  static String orderList({int page: 1, String type: "all"}) {
    // "spm":"a215s.7406091.toolbar.i1"
    return _basicRequest("mtop.order.queryboughtlist", "4.0", """{
      appVersion: "1.0",
      appName: "tborder",
      page: $page,
      tabCode: "$type",
    }""");
  }

  // 订单详情
  static String orderDetail(String orderId) {
    return _basicRequest("mtop.order.querydetail", "4.0", """{
      appVersion:'1.0',
      appName:'tborder',
      bizOrderId:'$orderId'
    }""");
  }

  // 物流详情
  static String logisDetail(String orderId) {
    return _basicRequest(
      "mtop.cnwireless.cnlogisticdetailservice.querylogisdetailbytradeid",
      "v1.0", """{
        orderId: '$orderId',
      }""");
  }

  // 淘气值
  static String vipScore() {
    return _basicRequest(
      "mtop.vip.gold.user.customize",
      "1.0", 
      """{"source":"vipDayNew"}""",
    );
  }

  static String _basicRequest(String api, String ver, String data) {
    return """return lib.mtop.H5Request({api:'$api',v:'$ver',timeout:30000,data:$data,
      dataType:'json',ttid:'##h5',H5Request:true,isSec:'0',
      ecode:'0',AntiFlood:true,AntiCreep:true,needLogin:true,LoginRequest:true})""";
  }
}

class H5PageUrls {
  static String login = "https://login.m.taobao.com/login.htm";
  static String home = "https://h5.m.taobao.com/mlapp/mytaobao.html"; // redirect from login
  static String mhome = "https://main.m.taobao.com/mytaobao/index.html";
  static String olist = "https://main.m.taobao.com/olist/index.html";

  static bool isLogin(String url) {
    return url.indexOf("https://login.m.taobao.com") >= 0;
    // return url.split("?")[0] == login;
  }

  static bool isHome(String url) {
    String _norm = url.split("?")[0];
    return _norm == home || _norm == mhome;
  }
}