import 'package:flutter_taobao_page/action_page.dart';
import 'package:flutter_taobao_page/taobao_page.dart';

class PCWeb {
  final TaobaoPageController controller;

  PCWeb(this.controller);

  static ActionJob userBaseInfoAction = ActionJob(PCPageUrls.userBaseInfo, code: PCCode.userBaseInfo(), isAsync: false);
  static ActionJob accountProfileAction = ActionJob(PCPageUrls.accountProfile, code: PCCode.accountProfile(), isAsync: false);
  static ActionJob accountSecurityAction = ActionJob(PCPageUrls.accountSecurity, code: PCCode.accountSecurity(), isAsync: false);
  static ActionJob rateScoreAction = ActionJob(PCPageUrls.rateScore, code: PCCode.rateScore(), isAsync: false);
  static ActionJob certityInfoAction = ActionJob(PCPageUrls.certityInfo, code: PCCode.certityInfo(), isAsync: false);
  static ActionJob vipScoreAction = ActionJob(PCPageUrls.vipScore, code: PCCode.vipScore(), isAsync: false);
  static ActionJob aliStarAction = ActionJob(PCPageUrls.aliStar, code: PCCode.aliStar(), isAsync: false);
  static ActionJob disputeAction = ActionJob(PCPageUrls.dispute, code: PCCode.dispute(), isAsync: false);

  Future<dynamic> userBaseInfo() {
    return controller.doAction(userBaseInfoAction);
  }

  Future<dynamic> accountProfile() {
    return controller.doAction(accountProfileAction);
  }

  Future<dynamic> accountSecurity() {
    return controller.doAction(accountSecurityAction);
  }

  Future<dynamic> certityInfo() {
    return controller.doAction(certityInfoAction);
  }

  Future<dynamic> vipScore() {
    return controller.doAction(vipScoreAction, options: PageOptions(timeout: const Duration(seconds: 10)));
  }

  Future<dynamic> rateScore() {
    return controller.doAction(rateScoreAction);
  }

  Future<dynamic> aliStar() {
    return controller.doAction(aliStarAction);
  }

  Future<dynamic> dispute() {
    return controller.doAction(disputeAction);
  }

  // we need to check if we has verify code
  Future<dynamic> order(int page, {int count = 20, String type = "", bool isAsync = false, Function() onVerifyConfirm}) {
    var _wc;
    return controller.doAction(
      ActionJob(PCPageUrls.order, code: PCCode.order(page, count: count, type: type), isAsync: isAsync),
      onLoadStop: (controller, url) {
        _wc = controller;
        // check verify code
        if (url.indexOf("_____tmd_____/verify") > 0) {
          print("[page taobao order] verify code, need to reload");
          // just reload
          controller.loadUrl(url: PCPageUrls.order);

          // call verify back
          onVerifyConfirm?.call();
          return;
        }
      },
      options: PageOptions(useMobile: true),
    ).then((value) {
      // check verify code
      if (value["rgv587_flag"]=="sm" && value["url"]!="" && value["url"].indexOf("_____tmd_____") > 0) {
        // we nee to show web, how to pass the page instance out
        // TODO: sometime we don't display verify page on webview, but get error data in api.
        _wc.loadUrl(url: value["url"]);
        return Future.error("verify_code");
      }
      return value;
    });
  }
}

class PCCode {

  // TODO: improve use scripts auto load to page

  static String userBaseInfo() {
    return """var _tmp_nick = document.querySelector('#J_uniqueName');
var _tmp_logo = document.querySelector('a.pf-avatar > img');
return {nickname: _tmp_nick?_tmp_nick.value:null, logo: _tmp_logo?_tmp_logo.src:null}""";
  }

  static String accountProfile() {
    return """var tmp = document.querySelector('#ah\\\\:addressForm');
      if ( !tmp ) throw("查询DOM节点失败");
      var _score = document.querySelector('.tao-score');
      return {
        tao_score: _score?_score.innerText:null,
        realname: tmp.querySelector('li:nth-child(1) > strong').innerText,
        email: tmp.querySelector('li:nth-child(2) > strong').innerText,
        gender: tmp.querySelector('li:nth-child(3) > input[type=hidden]').getAttribute('value'),
        birth: Array.from(tmp.querySelectorAll('li:nth-child(4) > input')).map(function(i){return i.value}).join('-'),
        avatar: document.querySelector('#J_MtAvatarBox > a > img').src,
      }
""";
  }

  static String accountSecurity() {
    return """var data = {};
var _get = function(obj, key) { return obj?obj[key]:null }
Array.from(document.querySelectorAll('#main-content > dl > dd:nth-child(2) > ul > li')).map(function(i) {
    if (!i) return
    data[_get(i.querySelector('span:nth-child(1)'), 'innerText')] = _get(i.querySelector('span:nth-child(2)'), 'innerText')
});
return data
""";
  }

  static String certityInfo() {
    return """var tmps = document.querySelectorAll('#main-content > div > div.certify-info > div.msg-box-content > .explain-info');
var _score = document.querySelector('.tao-score');
return {
  tao_score: _score?_score.innerText:null,
  idcard_infos: Array.from(tmps).map(function(i) {return i.innerText}),
}""";
  }

  static String vipScore() {
    return """var r = new XMLHttpRequest();
r.open('GET', 'https://vip.taobao.com/ajax/getGoldUser.do?_input_charset=utf-8&from=diaoding', null);
r.send(null);
if ( r.status === 200 ) { var res = JSON.parse(r.responseText); return res.data }
throw(r.responseText)
""";
  }

  static String rateScore() {
    return """var buyertmp = document.querySelector('#new-rate-content > div.clearfix.personal-info > div.personal-rating > h4.tb-rate-ico-bg.ico-buyer');
var sellertmp = document.querySelector('#new-rate-content > div.clearfix.personal-info > div.personal-rating > h4.tb-rate-ico-bg.ico-seller');
var _score = document.querySelector('.tao-score');
var data = {
    buyer: {
        tao_score: _score?_score.innerText:null,
        summary: buyertmp.querySelector('a:nth-child(1)').innerText,
        rankimg: buyertmp.querySelector('a:nth-child(2) > img').src,
        ratings: Array.from(document.querySelectorAll('#new-rate-content > div.clearfix.personal-info > div.personal-rating > table.tb-rate-table.align-c.thm-plain > tbody > tr')).map(function(i) {return Array.from(i.querySelectorAll('td')).map(function(i) {return i.innerText})}),
    },
};
if (sellertmp) {
    data.seller = {
        summary: sellertmp.querySelector('a:nth-child(1)').innerText,
        rankimg: sellertmp.querySelector('img').src,
    }
    data.buyer.ratings = Array.from(document.querySelectorAll('#new-rate-content > div.clearfix.personal-info > div.personal-rating > table:nth-child(8) > tbody > tr')).map(function(i) {return Array.from(i.querySelectorAll('td')).map(function(i) {return i.innerText})})
}
return data
""";
  }

  static String aliStar() {
    return """return { star: document.querySelector('span.star').innerText }""";
  }

  /// 退款管理
  static String dispute() {
    return """${scaleViewPort()};var keys = Object.keys(disputeData.data||{}).filter(function(i) {return i.indexOf('disputeListGrid') === 0});
return { orders: keys.map(function(i) {return disputeData.data[i]}) }
""";
  }

  static String order(int page, {int count = 20, String type = ""}) {
    return """var r = new XMLHttpRequest()
r.open(
    'POST',
    'https://buyertrade.taobao.com/trade/itemlist/asyncBought.htm?action=itemlist/BoughtQueryAction&event_submit_do_query=1&_input_charset=utf8&tabCode=$type',
    null
);
r.setRequestHeader('content-type', 'application/x-www-form-urlencoded; charset=UTF-8')
r.send(`pageNum=$page&pageSize=$count`)
return r.status === 200 ? JSON.parse(r.responseText) : null;
""";
  }

  static String transitStep(String orderId) {
    return """var r = new XMLHttpRequest();
r.open(
  'GET',
  "https://buyertrade.taobao.com/trade/json/transit_step.do?bizOrderId=$orderId",
  null
);
r.send();
return r.status === 200 ? JSON.parse(r.responseText) : null
""";
  }

  static String scaleViewPort() {
    return """var _meta = document.querySelector('head > meta[name=viewport]')
if ( _meta ) _meta.setAttribute('content', 'width=device-width, initial-scale=0.4, maximum-scale=1.0, user-scalable=0');
window.scroll(0, 0); // scroll to left 0 top 0
""";
  }
}

class PCPageUrls {
  static String userBaseInfo = "https://i.taobao.com/user/baseInfoSet.htm";
  static String accountProfile = "https://member1.taobao.com/member/fresh/account_profile.htm";
  static String accountSecurity = "https://member1.taobao.com/member/fresh/account_security.htm";
  static String certityInfo = "https://member1.taobao.com/member/fresh/certify_info.htm";
  static String vipScore = "https://vip.taobao.com/ajax";
  static String rateScore = "https://rate.taobao.com/myRate.htm";
  static String aliStar = "https://h5.m.taobao.com/alistar/intro-pc.html";
  static String dispute = "https://refund2.taobao.com/dispute/buyerDisputeList.htm";
  static String order = "https://buyertrade.taobao.com/trade/itemlist/list_bought_items.htm";
}