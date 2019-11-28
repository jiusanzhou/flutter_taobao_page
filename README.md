<div align="center">

# taobao_page

A flutter package 淘宝个人数据抓取.

</div>

`flutter_taobao_page`是一个通过Webview来抓取淘宝数据的Flutter插件。

### 特性

- flutter插件
- 原始Webview淘宝登录
- 提供数据API
- 多种Webview插件支持
- 数据驱动

### 数据项

- [ ] 数据接口
  - [x] 订单
  - [ ] 登录
- [ ] 主要功能
  - [ ] 多种Webview插件支持
  - [ ] 数据驱动

如有更多接口需求欢迎提issue.

### 依赖

- flutter_webview

### 要求



### 准备

#### iOS

在 `Info.plist` 文件中添加
```
<key>io.flutter.embedded_views_preview</key>
<true/>
<key>NSAllowsArbitraryLoads</key>
<true/>
<key>NSAllowsArbitraryLoadsInWebContent</key>
<true/>
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

#### Android

在 `AndroidManifest.xml` 文件中添加
```
android:usesCleartextTraffic="true"
```

### 使用

```
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  TaobaoPageController _controller;

  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
      return Scaffold(
          body: TaobaoPage(
            onCreated: (TaobaoPageController controller) {
                _controller = controller;
            },
            child: ... // 调用 _controller.getOrder(_currentPage, count: 5) 获取订单
          )
      )
  }
}
```

详细内容参考示例: [example/lib/main.dart](./example/lib/main.dart)


### 订单数据

示例

```
{
  "error": "",
  "extra": {},
  "page": {
    "currentPage": 2,
    "pageSize": 15,
    "prefetchCount": 31,
    "queryForTitle": false,
    "totalNumber": 718,
    "totalPage": 48
  },
  "mainOrders": [
    {
      "extra": {
        "batchGroup": "0",
        "batchGroupTips": "预售商品和普通商品不支持合并付款",
        "batchMaxCount": 20,
        "bizType": 200,
        "currency": "CNY",
        "currencySymbol": "￥",
        "finish": true,
        "id": 51329xxxxxx7671500,
        "inHold": false,
        "isShowSellerService": false,
        "needDisplay": true,
        "tradeStatus": "TRADE_FINISHED",
        "visibility": true
      },
      "id": "51329xxxxxx7671464",
      "operations": [
        {
          "style": "t0",
          "text": "追加评论",
          "type": "operation",
          "url": "//rate.taobao.com/appendRate.htm?bizOrderId=51329xxxxxx7671464&subTradeId=51329xxxxxx7671464&isArchive=true"
        },
        {
          "id": "share",
          "style": "thead",
          "text": "分享",
          "type": "operation"
        },
        {
          "id": "resell",
          "style": "thead",
          "text": "卖了换钱",
          "type": "operation",
          "url": "//sell.2.taobao.com/publish/outer_site_resell.htm?bizOrderId=51329xxxxxx7671464&isArchive=true"
        },
        {
          "id": "flag",
          "style": "thead",
          "text": "编辑标记信息，仅自己可见",
          "type": "operation",
          "url": "//trade.taobao.com/trade/memo/update_buy_memo.htm?bizOrderId=51329xxxxxx7671464&buyerId=720676414&user_type=0&pageNum=2&auctionTitle=null&daetBegin=0&dateEnd=0&commentStatus=&sellerNick=&auctionStatus=&isArchive=true&logisticsService=&visibility=true"
        },
        {
          "action": "a7",
          "data": {
            "body": "删除后，您可在订单回收站找回，或永久删除。",
            "crossOrigin": false,
            "height": 0,
            "title": "您确定要删除该订单吗？",
            "width": 0
          },
          "dataUrl": "/trade/itemlist/asyncBought.htm?action=itemlist/RecyleAction&event_submit_do_delete=1&_input_charset=utf8&order_ids=51329xxxxxx7671464&isArchive=true",
          "id": "delOrder",
          "style": "thead",
          "text": "删除订单",
          "type": "operation"
        }
      ],
      "orderInfo": {
        "archive": true,
        "b2C": true,
        "createDay": "2019-07-02",
        "createTime": "2019-07-02 08:35:17",
        "id": "51329xxxxxx7671464"
      },
      "payInfo": {
        "actualFee": "23.80",
        "icons": [
          {
            "title": "您已使用信用卡付款",
            "type": 1,
            "url": "//assets.alicdn.com/sys/common/icon/trade/xcard.png"
          },
          {
            "linkTitle": "手机订单",
            "linkUrl": "http://www.taobao.com/m?sprefer=symj28",
            "type": 3,
            "url": "//img.alicdn.com/tps/i1/T1xRBqXdNAXXXXXXXX-46-16.png"
          }
        ],
        "postFees": [
          {
            "prefix": "(含运费",
            "suffix": ")",
            "value": "￥0.00"
          }
        ]
      },
      "seller": {
        "alertStyle": 0,
        "guestUser": false,
        "id": 3064702580,
        "nick": "山山森泰克专卖店",
        "notShowSellerInfo": false,
        "opeanSearch": false,
        "shopDisable": false,
        "shopImg": "//gtd.alicdn.com/tps/i2/TB1aJQKFVXXXXamXFXXEDhGGXXX-32-32.png",
        "shopName": "山山森泰克专卖店",
        "shopUrl": "//store.taobao.com/shop/view_shop.htm?user_number_id=3064702580",
        "wangwangType": "nonAlipay"
      },
      "statusInfo": {
        "operations": [
          {
            "id": "viewDetail",
            "style": "t0",
            "text": "订单详情",
            "type": "operation",
            "url": "//tradearchive.taobao.com/trade/detail/trade_item_detail.htm?bizOrderId=51329xxxxxx7671464"
          }
        ],
        "text": "交易成功",
        "type": "t0",
        "url": "//tradearchive.taobao.com/trade/detail/trade_item_detail.htm?bizOrderId=51329xxxxxx7671464"
      },
      "subOrders": [
        {
          "id": 51329xxxxxx7671500,
          "itemInfo": {
            "id": 553854055233,
            "itemUrl": "//item.taobao.com/item.htm?id=553854055233&_u=blf99hu330f",
            "pic": "//img.alicdn.com/imgextra/i1/3064702580/O1CN01OrqYj11UvgOBUtGWb_!!0-item_pic.jpg_80x80.jpg",
            "serviceIcons": [
              {
                "linkTitle": "七天退换",
                "linkUrl": "//pages.tmall.com/wow/seller/act/seven-day",
                "name": "七天退换",
                "title": "七天退换",
                "type": 3,
                "url": "//img.alicdn.com/tps/i3/T1Vyl6FCBlXXaSQP_X-16-16.png"
              },
              {
                "linkTitle": "如实描述",
                "linkUrl": "//www.taobao.com/go/act/315/xfzbz_rsms.php?ad_id=&am_id=130011830696bce9eda3&cm_id=&pm_id=",
                "name": "如实描述",
                "title": "如实描述",
                "type": 3,
                "url": "//img.alicdn.com/tps/TB1PDB6IVXXXXaVaXXXXXXXXXXX.png"
              },
              {
                "linkTitle": "正品保证",
                "linkUrl": "//rule.tmall.com/tdetail-4400.htm",
                "name": "正品保证",
                "title": "正品保证",
                "type": 3,
                "url": "//img.alicdn.com/tps/i2/T1SyeXFpliXXaSQP_X-16-16.png"
              }
            ],
            "skuId": -1,
            "skuText": [],
            "snapUrl": "//buyertrade.taobao.com/trade/detail/tradeSnap.htm?tradeID=51329xxxxxx7671464&snapShot=true",
            "title": "家用甲醛检测盒检测仪试纸测试仪器专业室内空气自测盒一次性新房",
            "xtCurrent": false
          },
          "operations": [
            {
              "action": "a3",
              "dataUrl": "//refund2.tmall.com/dispute/disputeRedirect.htm?tradeId=51329xxxxxx7671464",
              "style": "t0",
              "text": "申请售后"
            }
          ],
          "priceInfo": {
            "original": "39.00",
            "realTotal": "23.80"
          },
          "quantity": "1"
        }
      ]
    }
  ]
}
```

详细定义参考[数据schema](./data/schema.json)

