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
    login = config["nickname"] ?? "";
    login = config["password"] ?? "";
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
  
  open(BuildContext context, { bool smsMode = true, Map<String, dynamic> config }) {

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
              onWebViewCreated: (controller) => hacker?.onWebViewCreated(controller),
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

                  // 在这里搞事情
                  if (config != null) {

                    print("自动填充帐号登录信息");
                    AccountInfo info = AccountInfo.fromJson(config);

                    // 填入帐号密码等信息
                    Future.delayed(Duration(milliseconds: 50), () {
                      controller.evaluateJavascript(source: """
                      let i;
                      i = document.querySelector('#fm-login-id'); i.value="${info.login}";
                      i = document.querySelector('#fm-login-password'); i.value="${info.password}";
                      '_____'
                      """).then((value) => print("执行成功: $value"));
                    });
                  }

                  // set password input to text
                  if (smsMode) {
                    Future.delayed(Duration(milliseconds: 50), () {
                      controller.evaluateJavascript(source: """
                      let i = document.querySelector('.sms-login-link'); i && i.click();''
                      """);
                    });
                  }

                  return;
                }

                if (H5PageUrls.isHome(url)) {
                  print("[taobao page] guess we have login success => $url");
                  _isLogon = true;
                  onUserLogon?.call(null);
                  Navigator.pop(context);
                }
              },
              onProgressChanged: (_, v) {
                // setState(() {
                //   _progress = v / 100;
                // });
                hacker?.onProcessChange(_, v);
              },
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