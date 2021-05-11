title: 'flutter: 深入通信-发送端'
date: 2019-06-30 10:06:17
category: Tech
---
```
sdk: [v1.5.4-hotfix.1](https://github.com/flutter/flutter/commit/7a4c33425ddd78c54aba07d86f3f9a4a0051769b)@stable
engine: [52c7a1e849a170be4b2b2fe34142ca2c0a6fea1f](https://github.com/flutter/engine/commit/52c7a1e849a170be4b2b2fe34142ca2c0a6fea1f)
```

站在平台端的视角对通道有一个通观概览的认知之后就需要深入内里对通信机制需要一个深入剖析了，之前已经了解到`FlutterJNI.dispatchPlatformMessage`是平台层（java）发送数据调用的最后一层，那么继续这个调用序列：
```
FluttereJNI.dispatchPlatformMessage
  nativeDispatchPlatformMessage(FlutterJNI.java)
    DispatchPlatformMessage(platform_view_android_jni.cc:56)
      AndroidShellHolder::GetPlatformView(platform_view_android_jni.cc:421)
      PlatformViewAndroid::DispatchPlatformMessage(platform_view_android.cc:92)
        TaskRunners::GetPlatformTaskRunner => PlatformView::task_runners_
        new PlatformMessageResponseAndroid()
        new flutter::PlatformMessage(name, message, response)
        PlatformView::DispatchPlatformMessage
          PlatformView::Delegate::OnPlatformViewDispatchPlatformMessage() => Shell::On..()
            ::GetUITaskRunner
            TaskRunner::PostTask
            ...Engine::DispatchPlatformMessage
```
发送消息最终调用到了C++层的`PlatformViewAndroid::DispatchPlatformMessage`方法， 又调用了`PlatformViewAndroid`成员`delegate_`的`OnPlatformViewDispatchPlatformMessage`方法， 所以我们要确定`PlatformView::Delegate`抽象类的实现体， 也就是要追踪成员被创建或赋值的地方。

由构造函数可知成员`PlatformView::delegate_`是创建时外部传入，而`PlatformViewAndroid`作为子类把它的delegate传入，所以需要了解
`PlatformViewAndroid`被创建时传入的delegate对象，

`android_shell_holder.cc:63`可知创建`PlatformViewAndroid`时传入的的delegate对象实际为`Shell`，在其方法中又异步调用了成员`engine_`的方法，即`Engine::DispatchPlatformMessage`方法

所以我们需要
1. 明确`PlatformViewAndroid`被创建的流程
2. 明确`Engine`被赋值或创建的时机

### 创建`PlatformViewAndroid`流程:
```
AndroidShellHolder::AndroidShellHolder()
  ThreadHost::ThreadHost
    platform_thread=
  fml::MessageLoop::EnsureInitializedForCurrentThread
  platform_runner=fml::MessageLoop::GetCurrent().GetTaskRunner()
  Shell::Create()
    DartVMRef::Create(settings)
    Shell::Create()
      TaskRunner::RunNowOrPostTask
        lamda() => Shell::CreateShellOnPlatformThread()
          Shell::CreateCallback<PlatformView>(Shell&) => on_create_platform_view
            new PlatformViewAndroid(Shell,...)

```
最重要的是`Shell::Create`这个方法，在调用时传入了一个回调，这个回调调用了`Shell::CreateShellOnPlatformThread()`， 继续回调了`on_create_platform_view`，其实现体上下文在`AndroidShellHolder`构造函数中。

### 创建Shell::engine_[Engine]流程:
第二个问题刚好承接了对每一个问题的分析: 我们是在创建`Shell`的时候创建了`PlatformViewAndroid`对象
`shell.cc:38`可知`engine_`也是外部传入
```
Shell::CreateShellOnPlatformThread()
  new Shell()
  on_create_platform_view  => AndroidShellHolder.on_create_platform_view
    std::make_unique<PlatformViewAndroid>()
  TaskRunner::RunNowOrPostTask
  ...lamda => engine = std::make_unique<Engine>() (shell.cc:131)
  Shell::Setup
    engine_ = std::move(engine); (shell.cc:388)
```
在`Shell::CreateShellOnPlatformThread `中先创建了`Shell`实例, 接着创建了`PlatformView`实例，接着又异步执行了一个lamda，创建了`Engine`实例

这样前面两个重要对象的创建时机问题就终于明确了。

继续我们第一阶段的调用分析, 异步执行了`Engine::DispatchPlatformMessage`
```
Engine::DispatchPlatformMessage
  RuntimeController::DispatchPlatformMessage
    Window::DispatchPlatformMessage
      tonic::DartInvokeField(...,"_dispatchPlatformMessage")
```
最终由此进行到了Dart层调用

---
因为在`AndroidShellHolder `的构造函数中Flutter创建了`Shell`对象，所以同样需要明确：
### 创建`AndroidShellHolder`流程:
```
FlutterActivity.onCreate (FlutterActivity.java:89)
  FlutterActivityDelegate.onCreate() (FlutterActivityDelegate.java:160)
    FlutterView.FlutterView() (FlutterView.java:139)
      new FlutterNativeView(Context) (FlutterNativeView.java:47)
        FlutterNativeView.attach(this, false) (FlutterNativeView.java:165)
          FlutterJNI.attachToNative (FlutterJNI.java:423)
            AttachJNI(platform_view_android_jni.cc:149)
              java_object(env, flutterJNI)
              std::make_unique<AndroidShellHolder>(java_object)
              AndroidShellHolder::IsValid
              reinterpret_cast<jlong>
```
比较容易发现创建的时机正是`FlutterJNI`绑定到`FlutterNativeView`, 而`FlutterJNI`的成员`nativePlatformViewId`代表的正是C++`AndroidShellHolder`对象，在这个过程中重要对象如`Shell`和`Engine`相继被创建。
所以每次发送数据(或者平台调用dart方法)都是`FlutterJNI`对象将成员`nativePlatformViewId`传入c++层，转成`AndroidShellHolder`对象通过`Engine`最终调用到dart层
