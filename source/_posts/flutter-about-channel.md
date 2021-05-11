title: 'flutter: 平台层与运行层的双向通信Channel'
date: 2019-06-24 23:27:57
category: Tech
---
```
sdk: v1.5.4-hotfix.1@stable
engine: 52c7a1e849a170be4b2b2fe34142ca2c0a6fea1f
```

存在这样的情形: flutter应用的视图控件响应用户的输入(比如KeyEvent), 需要将平台的按键数据传递到flutter的dart环境并响应, 同时应用可能因为某个操作需要调用平台的接口让手机震动. 但是flutter的App视图运行dart代码,平台(Android)运行Java代码, 同时dart层无法识别java层定义的对象类, 这就需要将数据在不同的运行环境中传递, flutter框架中的channel机制其实就是实现这个目的的.

一些文章和部分代码可能会让人感到困扰, 为什么已经有send接口了还要添加一个setMessageHander接口, 同时send已经有回调reply了, 怎么MessageHandler除了数据还有带一个reply.

理解的关键其实就是这个channel, 顾名思义, 就是进行数据传送的通道, 在平台层(java)与运行层(dart)进行数据通信. 一旦涉及通信就涉及对象传递, 而在不同运行时(runtime)环境进行对象传递就必然涉及对象序列化了. 所以不用被名称迷惑, **所谓的`MessageCodec`其实就是专门作对象序列化的实例**, 而通道既然能发送数据也必须能够接收数据,  如此的双向通信, 仅此而已.

一个通道关联3个对象： 名称, 操作与序列化, 操作即具体做收发消息的工作, 即`Messenger`. 而消息按类型又分为普通对象, 操作方法, 数据流, 对应着3种基本通道: `BasicMessageChannel<T>, MethodChannel, EventChannel`

####发送有时机, 接收无定时
平台端(android)可以显式的创建一个通道, 通道建立后既可作为发送端又可作为接收端, 作为发送端可以主动的传送相关数据, 是为**有时机**, 作为接收端, 只能被动等待数据到来, 是为**无定时**

####数据发送
调用一个通道的send方法,即为发送数据了, 有时发送完数据需要一个反馈, 于是有另一个回调参数`Reply<T>`, 这个回复是接收端反馈给发送端后发送端作的响应, 可以叫做**发送回复**.

####数据接收
每种通道都设置了一个`setMessageHandler`的方法, `MessageHandler<T>`其实就是通道的数据接收器, 更容易理解的名字应该是`MessageReceiver`, 专门等待发送端发送的数据; 表示通道建立后作为接收方接收数据后进行的处理, 数据处理完之后可能需要再反馈给发送端, 所以`MessageHandler<T>.onMessage(T message, Reply<T> reply)`中的`Reply<T>`是接收端反馈给发送端的回复, 可以叫做**接收回复**

####通道解码
理解了通道本质, 通道的解码`MessageCodec`就显而易见了, 也就显得不那么重要了: 在数据通信过程中针对各种各样的数据对象进行序列化和反序列化. 我们自己也完全可以定制自己的序列方式(比如gson), 因为无论是c++层java层还是dart层, 只能读写字节.

可以总结如下：
通道的本质即数据通信
通道的解码即对数据进行序列化和反序列化
通道可作为发送端也可作为接收端
通道最终是以二进制字节的形态传送数据
c++消弥平台的差异(android,ios), 同时提供统一的接口和方式供dart使用

####数据发送示例
**普通对象传递**-以Android端传递按键事件至dart端为例
按键数据被包装成一个对象实例，通道对象类型是`BinaryMessenger<Object>`调用序列如下：
```
FlutterView.onKeyDown
  AndroidKeyProcessor.onKeyDown
    KeyEventChannel.keyDown
     BasicMessageChannel.send
       BinaryMessenger.send -> DartExecutor.send
         DartMessenger.send
           FlutterJNI.dispatchPlatformMessage
```
最终调用了`BinaryMessenger`的send方法, 其实现体是`DartExecutor`, `DartExecutor`是平台层与运行层交互的点, 它实现了平台向dart调用, dart向平台的响应.

**调用dart方法**-以Android端传递导航事件至dart端为例
activity响应打开页面的方法onNewIntent被flutter定义了一个导航方法，通道对象类型是`MethodChannel`, 调用序列如下：
```
FlutterActivityDelegate.onNewIntent
  FlutterActivityDelegate.loadIntent
    FlutterView.setInitialRoute
      NavigationChannel.setInitialRoute
        MethodChannel.invokeMethod
          new MethodCall
          JSONMethodCodec.encodeMethodCall
          BinaryMessenger.send -> DartExecutor.send
            DartMessenger.send
              FlutterJNI.dispatchPlatformMessage
```
可以看到方法的名称与参数被包装成了`MethodCall`, 结构体被序列化成了字节之后传递给dart, 最终还是调用了`DartMessenger`的send方法

此外还有`EventChannel`，但是在代码中没有实例化(2019.06.24 flutter-engine:52c7a1e8)就先不分析了，本质与原理还是一样的。

####响应发送回复
可以看到`DartMessenger`用`pendingReplies:Map<>`缓存了`BinaryMessenger.BinaryReply`, 待dart代码执行完发送端操作后响应`handlePlatformMessageResponse`时取出, 完成发送反馈, 在`MethodChannel`中即为方法返回值.

####数据接收示例
**接收dart层通知**
目前代码中只有`AccessibilityChannel`有用到`BasicMessageChannel.MessageHandler`, 这是为了设置android视图`View`的`Accessibility`属性, 平常开发不怎么用到, 但毫无疑问,最终调用的还是平台层的相关代码

**接收dart层调用**-以Android端调用平台类PlatformChannel为例
`PlatformChannel`负责dart层向平台层调用的统一操作, 其创建过程如下
```
FlutterView.FltterView()
  new PlatformChannel
    new MethodChannel
    MethodChannel.setMethodCallHandler
      BinaryMessenger.setMessageHandler -> DartExecutor.setMessageHandler
        DartMessenger.setMessageHandler
  new PlatformPlugin
    PlatformChannel.setPlatformMessageHandler
```
`DartMessenger`用`messageHandlers`根据通道名称缓存了`BinaryMessenger.BinaryMessageHandler`, 平台层作为接收方不定时等待dart层发送数据, 方法调用流程如下:
```
DartMessenger.handleMessageFromDart
  BinaryMessenger.BinaryMessageHandler.onMessage -> MethodChannel.IncomingMethodCallHandler.onMessage
    MethodCallHandler.onMethodCall -> PlatformChannel.parsingMethodCallHandler.onMethodCall
      PlatformMessageHandler.vibrateHapticFeedback -> PlatformPlugin.mPlatformMessageHandler.vibrateHapticFeedback
        PlatformPlugin.vibrateHapticFeedback
          View.performHapticFeedback
```
由上可见`DartMessenger`是channel机制中最为重要的核心类, 是在平台层负责与运行层通信的最关键角色.
