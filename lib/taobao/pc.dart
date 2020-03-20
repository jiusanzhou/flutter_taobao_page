import 'package:flutter_taobao_page/action_page.dart';
import 'package:flutter_taobao_page/taobao_page.dart';

class PCWeb {
  final TaobaoPageController controller;

  PCWeb(this.controller);

  Future<dynamic> userBaseInfo() {
    return controller.doAction(ActionJob(PCPageUrls.userBaseInfo, code: PCCode.userBaseInfo()));
  }

  Future<dynamic> accountProfile() {
    return controller.doAction(ActionJob(PCPageUrls.accountProfile, code: PCCode.accountProfile()));
  }

  Future<dynamic> accountSecurity() {
    return controller.doAction(ActionJob(PCPageUrls.accountSecurity, code: PCCode.accountSecurity()));
  }

  Future<dynamic> certityInfo() {
    return controller.doAction(ActionJob(PCPageUrls.certityInfo, code: PCCode.certityInfo()));
  }

  Future<dynamic> vipScore() {
    return controller.doAction(ActionJob(PCPageUrls.vipScore, code: PCCode.vipScore()));
  }

  Future<dynamic> rateScore() {
    return controller.doAction(ActionJob(PCPageUrls.rateScore, code: PCCode.rateScore()));
  }

  Future<dynamic> aliStar() {
    return controller.doAction(ActionJob(PCPageUrls.aliStar, code: PCCode.aliStar()));
  }

  Future<dynamic> dispute() {
    return controller.doAction(ActionJob(PCPageUrls.dispute, code: PCCode.dispute()));
  }

  Future<dynamic> order(int page, {int count = 20, String type = ""}) {
    return controller.doAction(ActionJob(PCPageUrls.order, code: PCCode.order(page, count: count, type: type)));
  }
}

class PCCode {
  static String userBaseInfo() {
    return """let _tmp_nick = document.querySelector('#J_uniqueName');
let _tmp_logo = document.querySelector('a.pf-avatar > img');
return {nickname: _tmp_nick?_tmp_nick.value:null, logo: _tmp_logo?_tmp_logo.src:null}""";
  }

  static String accountProfile() {
    return """let tmp = document.querySelector('#ah\\\\:addressForm');
      if ( !tmp ) throw("查询DOM节点失败");
      let _score = document.querySelector('.tao-score');
      return {
        tao_score: _score?_score.innerText:null,
        realname: tmp.querySelector('li:nth-child(1) > strong').innerText,
        email: tmp.querySelector('li:nth-child(2) > strong').innerText,
        gender: tmp.querySelector('li:nth-child(3) > input[type=hidden]').getAttribute('value'),
        birth: Array.from(tmp.querySelectorAll('li:nth-child(4) > input')).map(i=>i.value).join('-'),
        avatar: document.querySelector('#J_MtAvatarBox > a > img').src,
      }
""";
  }

  static String accountSecurity() {
    return """let data = {};
let _get = (obj, key) => { return obj?obj[key]:null }
Array.from(document.querySelectorAll('#main-content > dl > dd:nth-child(2) > ul > li')).map(i => {
    if (!i) return
    data[_get(i.querySelector('span:nth-child(1)'), 'innerText')] = _get(i.querySelector('span:nth-child(2)'), 'innerText')
});
return data
""";
  }

  static String certityInfo() {
    return """let tmps = document.querySelectorAll('#main-content > div > div.certify-info > div.msg-box-content > .explain-info');
let _score = document.querySelector('.tao-score');
return {
  tao_score: _score?_score.innerText:null,
  idcard_infos: Array.from(tmps).map(i => i.innerText),
}""";
  }

  static String vipScore() {
    // TODO: request can be in common
    return """let r = new XMLHttpRequest();
r.open('GET', 'https://vip.taobao.com/ajax/getGoldUser.do?_input_charset=utf-8&from=diaoding', null);
r.send(null);
if ( r.status === 200 ) { let res = JSON.parse(r.responseText); return res.data }
throw(r.responseText)
""";
  }

  static String rateScore() {
    return """let buyertmp = document.querySelector('#new-rate-content > div.clearfix.personal-info > div.personal-rating > h4.tb-rate-ico-bg.ico-buyer');
let sellertmp = document.querySelector('#new-rate-content > div.clearfix.personal-info > div.personal-rating > h4.tb-rate-ico-bg.ico-seller');
let _score = document.querySelector('.tao-score');
let data = {
    buyer: {
        tao_score: _score?_score.innerText:null,
        summary: buyertmp.querySelector('a:nth-child(1)').innerText,
        rankimg: buyertmp.querySelector('a:nth-child(2) > img').src,
        ratings: Array.from(document.querySelectorAll('#new-rate-content > div.clearfix.personal-info > div.personal-rating > table.tb-rate-table.align-c.thm-plain > tbody > tr')).map(i => Array.from(i.querySelectorAll('td')).map(i => i.innerText)),
    },
};
if (sellertmp) {
    data.seller = {
        summary: sellertmp.querySelector('a:nth-child(1)').innerText,
        rankimg: sellertmp.querySelector('img').src,
    }
    data.buyer.ratings = Array.from(document.querySelectorAll('#new-rate-content > div.clearfix.personal-info > div.personal-rating > table:nth-child(8) > tbody > tr')).map(i => Array.from(i.querySelectorAll('td')).map(i => i.innerText))
}
return data
""";
  }

  static String aliStar() {
    return """
return {
    star: document.querySelector('span.star').innerText,
}    
""";
  }

  /// 退款管理
  static String dispute() {
    return """let keys = Object.keys(disputeData.data||{}).filter(i => i.indexOf('disputeListGrid') === 0);
return { orders: keys.map(i=>disputeData.data[i]) }
""";
  }

  static String order(int page, {int count = 20, String type = ""}) {
    return """let r = new XMLHttpRequest()
r.open(
    'POST',
    'https://buyertrade.taobao.com/trade/itemlist/asyncBought.htm?action=itemlist/BoughtQueryAction&event_submit_do_query=1&_input_charset=utf8&tabCode=$type',
    null
);
r.setRequestHeader('content-type', 'application/x-www-form-urlencoded; charset=UTF-8')
r.send(`pageNum=$page&pageSize=$count`)
return r.status === 200 ? r.responseText : null;
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