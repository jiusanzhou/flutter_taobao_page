import 'dart:io';

import 'package:flutter_taobao_page/taobao/pc.dart';
import 'package:flutter_taobao_page/taobao_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account account_profile html', () {
    var content = File('data/account_profile.htm').readAsStringSync();
    var data = Parser({
      "realname": "#ah\\:addressForm > li:nth-child(1) > strong@text",
      "email": "#ah\\:addressForm > li:nth-child(2) > strong@text",
      "gender":
          "#ah\\:addressForm > li:nth-child(3) > input[type='hidden']@value",
      "birth": [
        "#ah\\:addressForm > li:nth-child(4) > input:nth-child(2)@value",
        "#ah\\:addressForm > li:nth-child(4) > input:nth-child(3)@value",
        "#ah\\:addressForm > li:nth-child(4) > input:nth-child(4)@value",
      ],
    }).parse(content);
    print(data);
  });
  test('account account_security html', () {
    var content = File('data/account_security.htm').readAsStringSync();
    var data = Parser([
      "#main-content > dl > dd:nth-child(2) > ul > li:nth-child(1) > span:nth-child(2)@text",
      "#main-content > dl > dd:nth-child(2) > ul > li:nth-child(2) > span:nth-child(2)@text",
      "#main-content > dl > dd:nth-child(2) > ul > li:nth-child(3) > span:nth-child(2)@text",
      "#main-content > dl > dd:nth-child(2) > ul > li:nth-child(4) > span:nth-child(2)@text",
    ]).parse(content);
    print(data);
  });
  test('account certify_info html', () {
    var content = File('data/certify_info.htm').readAsStringSync();
    var data = Parser([
      "#main-content > div > div.certify-info > div.msg-box-content > div.explain-info:nth-child(2) > div",
      "#main-content > div > div.certify-info > div.msg-box-content > div.explain-info:nth-child(3) > div",
      "#main-content > div > div.certify-info > div.msg-box-content > div.explain-info:nth-child(4) > div",
      "#main-content > div > div.certify-info > div.msg-box-content > div.explain-info:nth-child(5) > div",
      "#main-content > div > div.certify-info > div.msg-box-content > div.explain-info:nth-child(6) > div",
      "#main-content > div > div.certify-info > div.msg-box-content > div.explain-info:nth-child(7) > div",
    ]).parse(content);
    print(data);
  });
  test('account myRate html', () {
    var content = File('data/myRate2.htm').readAsStringSync();
    var data = Parser({
      "seller": [
        // 是卖家的情况
        "#new-rate-content > div.personal-info > div.personal-rating > table:nth-child(7) > tbody > tr:nth-child(1) > td",
        "#new-rate-content > div.personal-info > div.personal-rating > table:nth-child(7) > tbody > tr:nth-child(1) > td > img@src",
        "#new-rate-content > div.personal-info > div.personal-rating > table:nth-child(7) > tbody > tr:nth-child(2) > td",
      ],
      "only-buyer": [
        // 是买家的情况
        "#new-rate-content > div.personal-info > div.personal-rating > table:nth-child(4) > tbody > tr:nth-child(1) > td",
        "#new-rate-content > div.personal-info > div.personal-rating > table:nth-child(4) > tbody > tr:nth-child(1) > td > img@src",
        "#new-rate-content > div.personal-info > div.personal-rating > table:nth-child(4) > tbody > tr:nth-child(2) > td",
      ]
    }).parse(content);
    print(data);
  });
  test('account dispute html', () {
    var content = File('data/buyerDisputeList.htm').readAsStringSync();
    var data = Parser("var disputeData =(.+);", isRegex: true).parse(content);
    print(data);
  });

  test('is verify html', () {
    var content = File('data/verify.htm').readAsStringSync();
    var data = PCWeb.isVerify(content);
    print(data);
  });

  test('is seller json', () {
    var content = 'seller_layout_head({"status":1,"data":{"sellerType":3}})';
    var data = Parser("(\{.+\})", isRegex: true).parse(content);
    print(data);
  });
}
