title: 'flutter: 深入通信-接收端'
date: 2019-07-02 12:07:29
category: Tech
---
```
sdk: [v1.5.4-hotfix.1](https://github.com/flutter/flutter/commit/7a4c33425ddd78c54aba07d86f3f9a4a0051769b)@stable
engine: [52c7a1e849a170be4b2b2fe34142ca2c0a6fea1f](https://github.com/flutter/engine/commit/52c7a1e849a170be4b2b2fe34142ca2c0a6fea1f)
```

# 前言
通过[PlatformChannel为平台层作为接收端的例子](https://juejin.im/post/6844903873950253069#heading-6)我们已经了解到`DartMessenger`通过响应接口`handleMessageFromDart`来把Dart层的消息/操作发送到平台层，而这个方法是`PlatformMessageHandler`这个接口对象的，持有接口实例的对象正是`FlutterJNI`。

作为被动调用的一方，平台层等待消息接收，并不知道消息的来源和用途，所以我们只需要按图索骥，找出调用方，就可追踪接收过程的完整流程。

# 追溯
容易看到`FlutterJN.handlePlatformMessage`调用了`handleMessageFromDart`，此函数被标记成`@SuppressWarnings("unused")`，很大可能与C++层有关了，搜索方法名称果然在``中找到`"handlePlatformMessage"`, 函数签名是`"(Ljava/lang/String;[BI)V"`正是些方法，方法对象被全局变量`g_handle_platform_message_method`持有，又被`FlutterViewHandlePlatformMessage`引用， 至此又进入到C++层。

这里`HandlePlatformMessage`这个名称实在太让人产生误解，感觉像是C++层在处理平台层发来的消息，然而实际却是传递Dart层的消息到平台，虽然`handlePlatformXXX`这种风格都表示处理Dart层的消息，并且保持的很好，但还是没有`receiveXXX`来的简单直观明了。

为便于理解以下是**被调用序列**
```
DartMessenger.handleMessageFromDart => PlatformMessageHandler
  FlutterJNI.handlePlatformMessage => g_handle_platform_message_method
    FlutterViewHandlePlatformMessage
      PlatformViewAndroid::HandlePlatformMessage <= PlatformView::HandlePlatformMessage
       ...Shell::OnEngineHandlePlatformMessage <= PlatformView::Delegate::OnEngineHandlePlatformMessage
         Engine::HandlePlatformMessage <= RuntimeDelegate::HandlePlatformMessage
           RuntimeController::HandlePlatformMessage <= WindowClient::HandlePlatformMessage
             ::SendPlatformMessage
             ...tonic::DartCallStatic(::_SendPlatformMessage
             ...Window::RegisterNatives
```
这与发送端的序列层次完全一样，从上到下分别是Shell -> PlatformView -> Engine -> RuntimeController -> Window。

可知`FlutterViewHandlePlatformMessage`是C++调用的终点，全局变量`g_handle_platform_message_method`其实是平台java方法，所以需要知道java方法何时与C++方法关联起来的， 即`g_handle_platform_message_method`何时被设置的:
以下是**被调用序列**
```
g_handle_platform_message_method = env->GetMethodID(,"handlePlatformMessage",)
  ::RegisterApi
    PlatformViewAndroid::Register
      JNI_OnLoad
        System.loadLibrary("flutter") (library_loader.cc:23)
          FlutterMain.startInitialization (FlutterMain.java:161)
            FlutterApplication.onCreate (FlutterApplication.java:22)
```
`JNI_OnLoad`被声明在了链接器脚本(android_exports.lst)中，表示被加载时执行的操作。

# 结语
结合前2篇的调用细节分析（精确到函数），及一些关键类的创建时机做一个简明flutter通道数据通信类图如下：
左边是java类,右边是C++类

![Flutter-Channel.jpg](https://user-gold-cdn.xitu.io/2019/7/2/16bb0cdbc662c481?w=854&h=1095&f=jpeg&s=91118)
