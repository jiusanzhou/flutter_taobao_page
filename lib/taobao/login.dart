import 'dart:async';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_taobao_page/login.dart';
import 'package:flutter_taobao_page/taobao/h5.dart';
import 'package:flutter_taobao_page/webview.dart';
import 'package:flutter_taobao_page/webview_hack.dart';

abstract class TaobaoLoginPage extends LoginPage {
  // all in one
}

class AccountInfo {

  String login;
  String nickname;
  String password;
  bool smsMode;

  AccountInfo.fromJson(Map<String, dynamic> config) {
    login = config["login"] ?? "";
    nickname = config["nickname"] ?? "";
    password = config["password"] ?? "";
    smsMode = config["smsMode"] == null ? false : config["smsMode"];
  }
}

class HttpClient extends http.BaseClient {
  http.Client _httpcli;

  HttpClient() {
    _httpcli = http.Client();
  }

  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['user-agent'] = UA_IOS;
    request.headers['cookie'] = await CookieManager.instance().getCookies(url: Uri.parse(URLCheckSession)).then((ck) {
      return ck.map((e) => "${e.name}=${e.value}").join(";");
    });
    print("====> cookie: ${request.headers['cookie']}");
    return _httpcli.send(request);
  }
}

// 判断是否需要登录: FAIL_SYS_SESSION_EXPIRED::Session过期
const URLCheckSession = "https://h5api.m.taobao.com/h5/mtop.taobao.mclaren.index.data.get.h5/1.0/?jsv=2.5.1&appKey=12574478&t=&sign=&api=mtop.taobao.mclaren.index.data.get.h5&v=1.0&ttid=2018%40taobao_iphone_9.9.9&isSec=0&ecode=1&timeout=5000&AntiFlood=true&AntiCreep=true&H5Request=true&LoginRequest=true&needLogin=true&type=json&dataType=json&data=%7B%22mytbVersion%22%3A%224.0.1%22%2C%22moduleConfigVersion%22%3A-1%2C%22dataConfigVersion%22%3A-1%2C%22requestType%22%3A1%7D";


class H5PasswordTaobaoLoginPage extends TaobaoLoginPage {

  final void Function(dynamic data) onUserLogon;
  final void Function(String url) onLoginPageOpend;
  HttpClient _cli;


  H5PasswordTaobaoLoginPage({this.onUserLogon, this.onLoginPageOpend}) {
    _cli = HttpClient();
  }
      
  bool _isLogon = false;
  double _progress = 0;

  bool get isLogin => _isLogon;

  clear() {
    _isLogon = false;
    _progress = 0;
  }
  
  open(BuildContext context, {bool isRecent = false, bool smsMode = true, Map<String, dynamic> config, Function(Map<String, dynamic> data) onLoginSubmit }) async {

    // TODO: 使用其他 widget 显示加载中的状态
    // 先判断是否需要登录

    if (isRecent) {
      print("是最近的帐号登录，可以先检查是否cookie有效");
      bool expired = await _cli.get(Uri.parse(URLCheckSession)).then((res) {
        print("====> ${res.body}");
        return res.body.contains("FAIL_SYS_SESSION_EXPIRED");
      });

      if (!expired) {
        // 没有过期 就直接返回验证通过
        print("没有过期，直接返回登录成功");
        _isLogon = true;
        onUserLogon?.call(null);
        return;
      }
    }

    // open a new web page
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: new Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          title: Text("淘宝登录"),
          actions: <Widget>[
            FlatButton(onPressed: () => Navigator.of(context).pop(null), child: Text("完成", style: TextStyle(color: Colors.white))),
          ],
        ),
        body: WebviewHack(
          builder: (context, hacker) {
            return TaobaoWebview(
              useMobile: true, // TODO: vivo部分机型使用 mobile 会出现加载超时,不true的话又没法登录??
              // 必须通过mhome来判断？有诶有其他方式判断是否需要重新登录
              // 必须实现headless模式 ?
              initialUrl: H5PageUrls.login,
              onWebViewCreated: (controller) {
                hacker?.onWebViewCreated(controller);

                // 注册一个用于通信的channel
                controller.addJavaScriptHandler(handlerName: "login_submit", callback: (args) {
                  // 反序列化第一个, 自行确保参数正确
                  print("收到  登录请求 => ${args[0]}");
                  onLoginSubmit?.call(json.decode(args[0]));
                  return "";
                });
              },
              onLoadStart: (controller, url) {
                hacker?.onLoadStart(controller, url);
              },
              onLoadStop: (controller, url) {
                hacker?.onLoadStop(controller, url);

                if (H5PageUrls.isLogin(url)) {
                  // has login page
                  print("[taobao page] has login page");
                  _isLogon = false;
                  onLoginPageOpend?.call(url);

                  AccountInfo info = config!=null?AccountInfo.fromJson(config):null;
                  
                  // 如果是短信模式，切换至
                  if (smsMode || (info != null && info.smsMode)) {
                    Future.delayed(Duration(milliseconds: 50), () {
                      controller.evaluateJavascript(source: """
                      let i = document.querySelector('.sms-login-link'); i && i.click();''
                      """);
                    });
                  }

                  // 在这里去绑定时间，点击登录按钮后把表单内内容拿到
                  controller.evaluateJavascript(source: """
                  // 给登录按钮注册点击事件通知登录输入的信息
                  var _installsubmit = function() {
                    var _submitbtn = document.querySelector("#login-form > div.fm-btn > button");
                    if (_submitbtn != null && !_submitbtn.getAttribute('_bind_click')) {
                      _submitbtn.setAttribute("_bind_click", true)
                      _callhackerback("echo", "安装按钮点击事件成功!");
                      _submitbtn.addEventListener("click", function(){
                        // 查询所有表单
                        _callhackerback("echo", "点击登录按钮!");
                        var data = {};
                        var ins = document.querySelectorAll('input');
                        for (var i=0; i< ins.length; i++) {
                          var item = ins[i];
                          // 处理表单值
                          if (item.id === "fm-sms-login-id") {
                            data["login"] = item.value;
                            data["smsMode"] = true;
                          } else if (item.id === "fm-login-id") {
                            // 账户名
                            data["login"] = item.value;
                          } else if (item.id === "fm-login-password") {
                            // 保存密码
                            data["password"] = item.value;
                          }
                        };

                        _callhackerback("echo", "查询到所有数据!");

                        // 向上通知
                        // flutter_inappwebview._callHandler("login_submit", setTimeout(function(){}), JSON.stringify([JSON.stringify(data)]));
                        _callhackerback("login_submit", data);
                      })
                    }
                  }

                  // 启动定时器，100ms查询一次是否绑定
                  setInterval(_installsubmit, 100);
                  '_____submithandle'
                  """).then((value) => print("安装登录按钮监听 执行成功: $value"));

                  // 这里去自动填充表单
                  if (info != null) {
                    print("自动填充帐号登录信息 $config");

                    // 短信模式和普通模式不一样的表单, 短信模式实现自己点击发送短信按钮
                    String code = info.smsMode?"""
                      // 刚切换完，不一定马上就渲染出来了，所有需要定时处理
                      let _smstimer = setInterval(function() {
                        let i = document.querySelector('#fm-sms-login-id');
                        if (!i) return; // 未渲染完成
                        clearInterval(_smstimer); // 清楚定时器
                        i.value="${info.login}";
                        setTimeout(function() {
                          document.querySelector(".send-btn-link").click(); // 点击获取短信验证码
                        }, 500)
                      }, 100);
                      '___短信模式插入'
                    """:"""
                      let i;
                      i = document.querySelector('#fm-login-id'); i.value="${info.login}";
                      i = document.querySelector('#fm-login-password'); i.value="${info.password}";
                      setTimeout(function() {
                        document.querySelector("#login-form > div.fm-btn > button").click(); // 点击登录按钮
                      }, 500)
                      '___普通模式插入'
                    """;

                    // 执行
                    Future.delayed(Duration(milliseconds: 50), () {
                      controller.evaluateJavascript(source: code).then((value) => print("填充密码执行成功: $value"));
                    });
                  }

                  return;
                }

                if (url.contains("h_5_expired.htm")) {
                  // 需要怎么办???
                  // reload to home page?
                  return;
                }

                // 有时候会出现 https://passport.taobao.com/iv/static/h_5_expired.htm
                if (H5PageUrls.isHome(url)) {
                  
                  print("[taobao page] guess we have login success => $url");
                  _isLogon = true;
                  onUserLogon?.call(null);
                  Navigator.pop(context);

                  // controller.evaluateJavascript(source: """
                  //   var v = "false";
                  //   var _frms = document.querySelectorAll("iframe");
                  //   for (var i=0; i<_frms.length-1;i++) {
                  //     if (_frms[i].src && _frms[i].src.indexOf("login.m.taobao.com") >= 0) {
                  //       break;
                  //     }
                  //   }
                  //   v = "true";
                  //   v;
                  // """).then((value) {
                  //   print("判断Cookie是否有效: $value");
                  //   // 有登录窗口或者数据登录名不是想要的
                  //   if (value == "true") {
                  //     // 不需要登录
                  //   } else {
                  //     // 需要登录
                  //     onLoginPageOpend?.call(url);
                  //     print("需要登录，跳转到登录页面");
                  //     var rr = "https%3A%2F%2Fh5.m.taobao.com%2Fother%2Floginend.html%3Forigin%3Dhttps%253A%252F%252Fh5.m.taobao.com";
                  //     controller.evaluateJavascript(source:
                  //     "window.location.href='${H5PageUrls.login}?redirectURL=$rr'; '__ load to login'").then((value) {
                  //       print("重新加载登录页: $value");
                  //     });
                  //     // controller.loadUrl(url: H5PageUrls.login);
                  //   }
                  // }).catchError((e) {
                  //   print("判断是否是登录页错误: $e");
                  // });

                }
              },
              onProgressChanged: (_, v) {
                hacker?.onProcessChange(_, v);
              },
              blockers: [
                // getPatternBlocker("um\.js\$"),
                // getPatternBlocker("\.gif\$"),
                // // "gm\.mmstat\.com|ynuf\.aliapp\.org|\.gif\$",
                // getPatternBlocker("gm\.mmstat\.com"),
                // getPatternBlocker("ynuf\.aliapp\.org"),
              ],
            );
          }
        ),
      ),
    ));
  }
}

class H5MsgTaobaoLoginPage extends TaobaoLoginPage {

  bool _isLogon = false;

  bool get isLogin => _isLogon;

}

class OneClickTaobaoLoginPage extends TaobaoLoginPage {

  bool _isLogon = false;

  bool get isLogin => _isLogon;

}

class QrcodeTaobaoLoginPage extends TaobaoLoginPage {

  bool _isLogon = false;

  bool get isLogin => _isLogon;

}