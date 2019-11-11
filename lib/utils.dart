
/// 默认淘宝链接
class TaobaoUrls {
  /// 登录页面
  static const String loginPage = "https://login.m.taobao.com/login.htm";
  /// 主页,用于判断登录成功
  static const String homePage = "https://h5.m.taobao.com/mlapp/mytaobao.html";
  /// 订单页
  static const String orderPage = "https://buyertrade.taobao.com/trade/itemlist/list_bought_items.htm";
}

/// 默认执行js
class TaobaoJsCode {
  /// 加载完成自动插入
  /// 
  /// 点击登录按钮隐藏webview
  static const String loginPage = "";
  // 订单页
  static const String orderPage = """((_) => {
    _._im_zoe = {
        taobao_page: {
            getOrder: (page = 1, count = 20) => {
                let r = new XMLHttpRequest()
                r.open(
                    'POST',
                    'https://buyertrade.taobao.com/trade/itemlist/asyncBought.htm?action=itemlist/BoughtQueryAction&event_submit_do_query=1&_input_charset=utf8',
                    null
                )
                r.setRequestHeader('content-type', 'application/x-www-form-urlencoded; charset=UTF-8')
                r.send(`pageNum=\${page}&pageSize=\${count}`)
                if ( r.status === 200 ) {
                    return r.responseText
                }
                return null
            },
        }
    }
})(window)""";

  /// 主动调用
  /// 
  /// 获取订单数据
  static String getOrder(int page, int count) {
    return "_im_zoe.taobao_page.getOrder($page, $count)";
  }
}