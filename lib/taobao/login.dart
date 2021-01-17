import 'dart:convert';

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

class H5PasswordTaobaoLoginPage extends TaobaoLoginPage {

  final void Function(dynamic data) onUserLogon;
  final void Function(String url) onLoginPageOpend;

  H5PasswordTaobaoLoginPage({this.onUserLogon, this.onLoginPageOpend});

  bool _isLogon = false;
  double _progress = 0;

  bool get isLogin => _isLogon;

  clear() {
    _isLogon = false;
    _progress = 0;
  }
  
  open(BuildContext context, { bool smsMode = true, Map<String, dynamic> config, Function(Map<String, dynamic> data) onLoginSubmit }) {

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
              useMobile: true,
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
                }

                if (H5PageUrls.isHome(url)) {
                  print("[taobao page] guess we have login success => $url");
                  _isLogon = true;
                  onUserLogon?.call(null);
                  Navigator.pop(context);
                }
              },
              onProgressChanged: (_, v) {
                hacker?.onProcessChange(_, v);
              },
              blockers: [
                getPatternBlocker("um\.js\$"),
                getPatternBlocker("\.gif\$"),
                // "gm\.mmstat\.com|ynuf\.aliapp\.org|\.gif\$",
                getPatternBlocker("gm\.mmstat\.com"),
                getPatternBlocker("ynuf\.aliapp\.org"),
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