import 'package:flutter/material.dart';
import 'package:flutter_taobao_page/login.dart';
import 'package:flutter_taobao_page/taobao/h5.dart';
import 'package:flutter_taobao_page/webview.dart';

abstract class TaobaoLoginPage extends LoginPage {
  // all in one
}

class H5PasswordTaobaoLoginPage extends TaobaoLoginPage {

  final void Function(dynamic data) onUserLogon;
  final void Function(String url) onLoginPageOpend;

  H5PasswordTaobaoLoginPage({this.onUserLogon, this.onLoginPageOpend});

  bool _isLogon = false;

  bool get isLogin => _isLogon;

  clear() {
    _isLogon = false; 
  }
  
  open(BuildContext context) {
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
        body: TaobaoWebview(
          initialUrl: H5PageUrls.login,
          onLoadStop: (controller, url) {
            if (H5PageUrls.isLogin(url)) {
              // has login page
              print("[taobao page] has login page");
              _isLogon = false;
              onLoginPageOpend?.call(url);
              return;
            }

            if (H5PageUrls.isHome(url)) {
              print("[taobao page] guess we have login success => $url");
              _isLogon = true;
              onUserLogon?.call(null);
              Navigator.pop(context);
            }
          },
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