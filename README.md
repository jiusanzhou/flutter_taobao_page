<div align="center">

# taobao_page

A flutter package 淘宝个人数据抓取.

</div>

`flutter_taobao_page`是一个通过Webview来抓取淘宝数据的Flutter插件。

### 特性

- Flutter 插件
- 原始 Webview 淘宝登录
- 提供数据API
- 数据驱动

### 数据项

- [ ] 数据接口
  - [x] 订单列表
  - [x] 订单详情
  - [x] 订单物流信息
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

- 订单详情

  ```_controller.apiOrderDetail("xxxx")```

- 订单物流

  ```_controller.apiTradeDetail("xxxx")```

  更详细的收获地址信息,如收货人可在订单详情内获得.

详细内容参考示例: [example/lib/main.dart](./example/lib/main.dart)

### :attention: 注意

目前存在比较大的问题:
- webview在未激活的情况下，物流详情等h5类请求会异常

目前的解决方案是：
- 让`HackKeepAlive`组件一直在激活的状态，比如在渲染PageTitle中
- 缩短超时时间，并重试