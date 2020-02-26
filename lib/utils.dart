/// 默认淘宝链接
class TaobaoUrls {
  /// 登录页面
  static const String loginPage = "https://login.m.taobao.com/login.htm";

  /// 主页,用于判断登录成功
  static const String homePage = "https://h5.m.taobao.com/mlapp/mytaobao.html";

  /// 订单页
  static const String orderPage =
      "https://buyertrade.taobao.com/trade/itemlist/list_bought_items.htm";

  // 天猫订单详情
}

/// 默认执行js
class TaobaoJsCode {
  /// 加载完成自动插入
  ///
  /// 点击登录按钮隐藏webview
  static const String loginPage = "";

  // 订单列表页
  static const String orderPage = """((_) => {
    _._im_zoe = {
        taobao_page: {
            getOrder: (page = 1, count = 20, tabCode = "") => {
                let r = new XMLHttpRequest()
                r.open(
                    'POST',
                    `https://buyertrade.taobao.com/trade/itemlist/asyncBought.htm?action=itemlist/BoughtQueryAction&event_submit_do_query=1&_input_charset=utf8&tabCode=\${tabCode}`,
                    null
                )
                r.setRequestHeader('content-type', 'application/x-www-form-urlencoded; charset=UTF-8')
                r.send(`pageNum=\${page}&pageSize=\${count}`)
                return r.status === 200 ? r.responseText : null
            },
            getTranStepsByOrderId: (orderId) => {
                let r = new XMLHttpRequest()
                r.open(
                  'GET',
                  `https://buyertrade.taobao.com/trade/json/transit_step.do?bizOrderId=\${orderId}`,
                  null
                )
                r.send()
                return r.status === 200 ? r.responseText : null
            },
            getOrderDetail: () => {
              // we must be called in order detail page
              if (location.host === 'trade.taobao.com') return data
              if (location.host === 'trade.tmall.com') return detailData
              return null
            },
        }
    }
})(window)""";

  /// 主动调用
  ///
  /// 获取订单数据
  static String getOrder(int page, int count, String type) {
    // waitConfirm
    return "_im_zoe.taobao_page.getOrder($page, $count, '$type')";
  }

  /// 主动调用
  /// 
  /// 获取物流信息
  static String getTranSteps(String orderId) {
    return "_im_zoe.taobao_page.getTranStepsByOrderId('$orderId')";
  }

  /// 主动调用
  /// 
  /// 获取订单详情 - 仅在打开后订单详情也后调用
  static String getOrderDetail() {
    return "_im_zoe.taobao_page.getOrderDetail()";
  }
}
