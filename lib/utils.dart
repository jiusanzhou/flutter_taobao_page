import 'dart:math';

/// 默认淘宝链接
class TaobaoUrls {
  /// 登录页面
  static const String loginPage = "https://login.m.taobao.com/login.htm";

  /// 主页,用于判断登录成功
  static const String homePage = "https://h5.m.taobao.com/mlapp/mytaobao.html";

  /// 主页
  static const String homePageMain = "https://main.m.taobao.com";

  /// 订单页
  static const String orderPage =
      "https://buyertrade.taobao.com/trade/itemlist/list_bought_items.htm";

  // 天猫订单详情
  static String tmallOrderDetailPage(String id) {
    return "https://trade.tmall.com/detail/orderDetail.htm?bizOrderId=$id";
  }

  // 淘宝订单详情
  static String taobaoOrdderDetailPage(String id) {
    return "https://trade.taobao.com/trade/detail/trade_order_detail.htm?biz_order_id=$id";
  }

  static bool isLoginPage(String url) {
    return url.indexOf("login.m.taobao.com/login.htm") > 0;
  }

  static bool isMyHomePage(String url) {
    return url.indexOf("h5.m.taobao.com/mlapp/mytaobao.htm") > 0;
  }
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
        postdata: (channel, data) => {
          window.flutter_inappwebview.callHandler('PostData', channel, data)
        },
        taobao_api: {
          getOrderDetail: (orderId) => {
            let data = {
                api: 'mtop.order.querydetail',
                v: '4.0',
                data: {appVersion:'1.0',appName:'tborder',bizOrderId:`\${orderId}`},
                ttid: "2018@taobao_h5_7.9.1",
                isSec: '0',
                ecode: '0',
                AntiFlood: true,
                AntiCreep: true,
                needLogin: true,
                LoginRequest: true,
            }
            lib.mtop.H5Request(data).then(r => {
              _._im_zoe.postdata(`order_detail_\${orderId}`, r)
            }).catch(e => {
              _._im_zoe.postdata(`order_detail_\${orderId}`, e)
            })

            return '=='
          }
        },
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
  /// 获取订单详情
  static String apiOrderDetail(String orderId) {
    return "lib.mtop.H5Request({api:'mtop.order.querydetail',v:'4.0',timeout:30000,data:{appVersion:'1.0',appName:'tborder',bizOrderId:'$orderId'},dataType:'json',ttid:'##h5',H5Request:true,isSec:'0',ecode:'0',AntiFlood:true,AntiCreep:true,needLogin:true,LoginRequest:true}).then(r=>{flutter_inappwebview.callHandler('PostData','order_detail_$orderId',r)}).catch(e=>flutter_inappwebview.callHandler('PostData','order_detail_$orderId',e));''";
  }

  /// 主动调用
  /// 
  /// 获取物流信息
  static String apiTradeDetail(String orderId) {
    return "lib.mtop.H5Request({api:'mtop.cnwireless.cnlogisticdetailservice.querylogisdetailbytradeid',v:'1.0',timeout:30000,data:{orderId:'$orderId'},dataType:'json',ttid:'##h5',H5Request:true,isSec:'0',ecode:'0',AntiFlood:true,AntiCreep:true,needLogin:true,LoginRequest:true}).then(r=>{flutter_inappwebview.callHandler('PostData','trade_detail_$orderId',r)}).catch(e=>flutter_inappwebview.callHandler('PostData','trade_detail_$orderId',e));''";
  }
}


class Utils {
    static final Random _random = Random.secure();

    static String randomString([int length = 12]) {
      var codeUnits = new List.generate(length, (index) => _random.nextInt(23)+65);
      return String.fromCharCodes(codeUnits);
    }
}