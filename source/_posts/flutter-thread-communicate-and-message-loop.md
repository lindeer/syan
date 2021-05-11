title: 'flutter: 线程通信与消息循环(C++)'
date: 2019-07-04 17:43:16
category: Tech
---
```
sdk: [v1.5.4-hotfix.1](https://github.com/flutter/flutter/commit/7a4c33425ddd78c54aba07d86f3f9a4a0051769b)@stable
engine: [52c7a1e849a170be4b2b2fe34142ca2c0a6fea1f](https://github.com/flutter/engine/commit/52c7a1e849a170be4b2b2fe34142ca2c0a6fea1f)
```

这里关注的是flutter在C++层的线程表示, 没有涉及dart层的线程

# 线程创建
flutter底层(C++)的线程(`fml::Thread`)是和消息循环紧密关联的，即每一个`fml::Thead`实例都创建了一个消息循环实例，因此如果要创建一个**裸线程**是不应该用`fml::Thread`的。`fml::Thread`内部即是用C++11的`std::thread`来持有一个线程对象，参看`fml::Thread`构造函数(thread.cc:25)。

线程运行体做了2件事
1. 创建消息循环实例并关联线程`fml::Thread`对象
2. 获取消息循环的`TaskRunner`对象实例并赋值给线程`fml::Thread`，即线程也持有一个`TaskRunner`实例

这个`TaskRunner`是个干啥的，还得看的`fml::MessageLoop`实现
`fml::Thread`的实现非常简单，关键还是看它关联的`fml::MessageLoop`。

# 线程存储
消息循环`fml::MessageLoop`首先用了线程存储来保存一个回调，这个回调的作用是显式释放一个`fml::MessageLoop`内存对象，所以先搞清flutter底层是如何进行线程存储的。

线程存储对象即作用域与线程生命周期一致的存储对象，`fml::ThreadLocal`即为线程存储类，它要保存的值是一个类型为`intptr_t`的对象；
`fml::ThreadLocal`在不同平台用了不同的实现方式
1. 类linux平台
用了pthread的库函数`pthread_key_create`来生成一个标识线程的key键，key对应的值是一个辅助类`Box`，它保存了`intptr_t`对象和传入的回调方法`ThreadLocalDestroyCallback`。`ThreadLocal`使用前需要声明的关键字是`static`
对象析构的顺序稍有点绕, 各对象析构调用序列如下:
```
ThreadLocal::~ThreadLocal()
  ThreadLocal::Box::~Box()
  pthread_key_delete(_key)
    ThreadLocal::ThreadLocalDestroy
        ThreadLocal::Box::DestroyValue
          ThreadLocalDestroyCallback() => [](intptr_t value) {}
            MessageLoop::~MessageLoop()
        ThreadLocal::Box::~Box()
```
这样看似乎`thread_local.cc:27`处的`delete`操作是多余的？

2. windows平台
`ThreadLocal`使用前直接用了C++11标准的关键字`thread_local`。

# 消息循环
消息循环即异步处理模型，在没有消息时阻塞当前线程以节省CPU消耗，否则以轮询的方式空转很浪费CPU资源，消息循环在安卓平台上很常见，其实所有的消息循环都大同小异。

## 关联线程
明白了线程存储，那么在创建`fml::Thread`对象时调用的`MessageLoop::EnsureInitializedForCurrentThread`就很浅显了（名字虽然有点累赘），当前线程是否创建了消息循环对象，如果没有那么创建并保存。这样消息循环就与线程关联起来了， 通过什么关联的？`tls_message_loop`这个线程存储类对象。

## 消息队列
`MessageLoopImpl ::delayed_tasks_`就是实际的消息队列，它被`delayed_tasks_mutex_`这个互斥变量保证线程安全。看着有点累赘，其实就是用了一个优先级队列按执行时间点来插入，如果时间点相同就按FIFO的规则来插入。

队列元素是一个内部类`DelayedTask`, 主要包含消息执行体`task`和执行时间点`target_time`，`order`其实是用来排序的。


## 循环实现
`MessageLoop`对象构造函数创建了2个重要实例，消息循环实现体`MessageLoopImpl`和`fml::TaskRunner`, 而`fml::TaskRunner`内部又引用了`MessageLoopImpl`。`MessageLoopImpl::Create()`创建了不同平台对应的消息循环实现体，于是`MessageLoop`与`MessageLoopImpl`之间的关系也非常清楚了： `MessageLoop`是`MessageLoopImpl`的壳或者`MessageLoopImpl`是`MessageLoop`的代理，`MessageLoopImpl`是不对外暴露的、与平台相关的、真正实现消息读取与处理的对象。

`MessageLoopImpl::Run,Terminate,WakeUp`是纯虚函数，由平台实现，譬如安卓平台的实现`MessageLoopAndroid`调用的是AndroidNDK方法`ALooper_pollOnce`, `MessageLoopLinux`调用是Linux阻塞函数`epoll_wait`。

这里涉及的类和方法有点绕，其实想达到目的很简单：**读取并处理消息的操作是统一的，但线程唤醒或者阻塞的方式是允许平台差异的**
# 发送消息
一个消息循环关联一个`TaskRunner`，而`TaskRunner`细看实现发现全都是`MessageLoopImpl`的方法，再联系之前在`AndroidShellHolder`构造函数里创建的`TaskHost`，就可以发现**所谓的`TaskRunner`无非就是给指定消息循环发送消息**，而一个消息循环是和一个线程(`fml::Thread`)关联的，因而也也就是给指定线程发送消息，没错，正是线程间通信！`TaskRunner`也正是声明成了线程安全对象(`fml::RefCountedThreadSafe<TaskRunner>`)

这样其实一切都串联起来了: `fml::TaskRunner`正如android中的`android.os.Handler`, `fml::closure`正如android中的`Runnable`, `fml::TaskRunner`不断的将各种`fml::closure`对象添加到消息队列当中，并设定消息循环在指定的时间点唤醒并执行。

# 线程结束
`fml::Thread`析构函数调用了自身的`Join`方法， 这个操作初看有点别扭，后来才明白意图：主调线程需要同步的等待被调线程结束，名称不如`Exit`来的言简意赅。`Join`方法先异步发送了一个结束消息循环的请求(`MessageLoop::GetCurrent().Terminate()`)，然后阻塞式等待结束。
结合以上列出线程退出的调用序列:
```
Thread::~Thread()
  Thread::Join()
    TaskRunner::PostTask()
...[异步]
MessageLoop::Terminate()
  MessageLoopImpl::DoTerminate()
    MessageLoopImpl::Terminate() => MessageLoopAndroid::Terminate()
      ALooper_wake()

...[异步，函数开始返回]
    MessageLoopImpl::Run() => MessageLoopAndroid::Run()
    MessageLoopImpl::RunExpiredTasksNow()
  MessageLoopImpl::DoRun()
MessageLoop::Run()

...[异步]
ThreadLocal::~ThreadLocal()
[省略，同线程存储对象析构的调用序列]
```

# 线程体系
回看`AndroidShellHolder`的构造函数，其中涉及`flutter::ThreadHost`, `fml::TaskRunner`, `flutter::TaskRunners`，在创建`Shell`对象之前还创建了一系列线程:`ui_thread`, `gpu_thread`, `io_thread`，并对`TaskRunner`有一系列操作，有点杂乱但现在看其实就非常清晰了。

当前执行`AndroidShellHolder`构造函数的线程被创建了一个消息循环(android_shell_holder.cc:81)并将消息循环的`TaskRunner`赋值给了`platform_runner`（**注意**：并没有创建`platform_thread`对象）。其它的`TaskRunner`则分别是所创建的`fml::Thread`线程的`TaskRunner`对象。

那么问题来了：当某个线程通过`platform_runner`发送一个异步请求时，会在什么时机执行？
