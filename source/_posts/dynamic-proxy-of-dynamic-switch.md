title: 动态切换的动态代理
date: 2019-05-22 19:40:29
category: Tech
---
名字看着有点绕, 但目的其实很简单明确: 就是想实现动态代理的对象实例, 在运行时也能够切换.
先理解前提条件和程序上下文, 譬如有如下接口:
```java
public interface Responder {
    void onMethod1(String s);
    int onMethod2();
    void onMethod3();
}
```
我们将接口的一个实例`Responder r1`传入了一个别的类`p1 = new Presenter(r1)`(或者外部SDK), 在运行时我们生成了不同的Responder实例r2, 现在希望r2能够替换r1, 但对于Presenter类是无法感知, 不用关心的. 显然我们的程序上下文能够实现对于Responder实例的控制(创建/传递), 但现在问题是Presenter类仅有构造参数对Responder的传入, 没有`setResponder(Responder r)`这样的方法(如果存在`setResponder`这样的方法, 但就没这坨事了:). 能不能再创建一个Presenter实例p2再传入r2呢? 如果程序上下文允许的话也没这坨事了.

所以条件是这样: ***接口的不同实例需要传入一个对象, 但这个对象持有的实例却无法更改, 同时这个对象也无法再次创建***.

说这么多不就是要用代理模式吗? 不错, 代理模式正是可以解决这类问题的. 表述这么累赘是想关注问题的场景, 而不是为了生搬硬套模式.

于是一个简单的代理类出来了:
```java
public class ResponderWrapper implements Responder {
    private final Responder impl;
    public ResponderWrapper(Responder r) {
        impl = r;
    }
    @Override
    void onMethod1(String s) {
        impl.onMethod1(s);
    }
    @Override
    int onMethod2() {
        return impl.onMethod2();
    }
    @Override
    void onMethod3() {
        impl.onMethod3();
    }
}
```
因为还要动态的改变代理对象所以添加一个set方法:
```java
    void setResponder(Responder r) {
        impl = r;
    }
```
那么传入Presenter对象的实例就不再是r1了, 而是
```
wrapper = new ResponderWrapper(r1);
p1 = new Presenter(wrapper);
```
这时创建了新的Responder实例r2, 我们只需要
```
wrapper.setResponder(r2);
```
就能够达到我们的目的了! p1还是p1, p1持有的实例还是同一个实例, 在切换前p1调的是r1的实现, 切换后自然就调用了r2的实现.
这种代理就是非常常见的静态代理, 仅就功能实现来说这已经完全OK了, 没有任何问题了.  是不是非得用动态代理? 并不是!

那动态代理是干吗的? 为了适应变化, 什么的变化? 接口的变化! 如果接口Responder新增一个方法, ResponderWrapper再增加同样一个接口; 如果修改Responder一个方法的参数, ResponderWrapper再接着修改并调用接口实例的新方法, 如此类推, 也没任何问题. 但接口的方法一旦变的很多, 接口的实现类一旦变的很多, 就需要做大量繁琐重复的工作, 那么动态代理就能够解决这种重复繁琐的工作.
以动态代理的形式写一个ResponderWrapper非常简单:
```java
public final class ResponderWrapper {
    public static Responder wrap(final Responder responder) {
        return (Responder) Proxy.newProxyInstance(Responder.class.getClassLoader(),
                Responder.class.getInterfaces(),
                new InvocationHandler() {
                    @Override
                    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                        return method.invoke(responder, args);
                    }
                });
    }
}
```
但是这样写无法满足动态切换的需求, 所以我们的最终目的这才出来了: ***以动态代理形式创建的代理实例能够动态切换持有的对象实例***
但一旦`ResponderWrapper.wrap`传入r1那么匿名对象持有的Responder对象就只能一直是r1, 所以希望`method.invoke(responder, args)`这里的`responder`能够动态切换, 这种"动态"能力一般都是以接口的形式实现, 于是有:
```java
public final class ResponderWrapper {
    public interface Provider {
        Responder get();
    }

    public static Responder wrap(final Provider provider) {
        return (Responder) Proxy.newProxyInstance(Responder.class.getClassLoader(),
                Responder.class.getInterfaces(),
                new InvocationHandler() {
                    @Override
                    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                        return method.invoke(provider.get(), args);
                    }
                });
    }
```
程序上下文实现`ResponderWrapper.Provider`接口, 当接口方法被调用时返回的实例是当前的Responder, 不用关心什么时候切换:
```java
mResonder = r1;
wrapper = ResponderWrapper.wrap(new ResponderWrapper.Provider() {
    @Override
    public ResponderWrapper.Responder get() {
        return mResponder;
    }
});
p1 = new Presenter(wrapper);
...
mResonder = r2;
```
如果觉得接口太重, 其实这种形式也完全可以不用接口的方式实现, 因为我们最终需要的其实是一个Responder实例, 在接口方法被调用的时候能够调用这个实例的对应的方法而已, 所以可以写成这样:
```java
public final class ResponderWrapper {
    public static final class Holder {
        public Responder responder;
    }

    public static Responder wrap(final Holder holder) {
        return (Responder) Proxy.newProxyInstance(Responder.class.getClassLoader(),
                Responder.class.getInterfaces(),
                new InvocationHandler() {
                    @Override
                    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                        return method.invoke(holder.responder, args);
                    }
                });
    }
}
```
程序上下文持有ResponderWrapper.Holder的实例, 再在需要的时候设置不同的Resonder实例:
```java
mHolder = new ResponderWrapper.Holder(r1);
wrapper = ResponderWrapper.wrap(holder)
p1 = new Presenter(wrapper);
...
mHolder.responder = r2
```
如果用范型抽象所有接口类, 就可以写的更通用一点:
```java
public final class ResponderWrapper {
    public static final class Holder<T> {
        public T responder;
    }

    @SuppressWarnings("unchecked")
    public static <T> T wrap(final Holder<T> holder) {
        T r = holder.responder;
        return (T) Proxy.newProxyInstance(r.getClass().getClassLoader(),
                r.getClass().getInterfaces(),
                new InvocationHandler() {
                    @Override
                    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                        return method.invoke(holder.responder, args);
                    }
                });
    }
}
```
这里临时利用`holder.responder`来获取`ClassLoade`r和`Class<?>[]`, 也完全可以将Class对象传入:
```java
public final class ResponderWrapper {
    public static final class Holder<T> {
        public T responder;
    }

    @SuppressWarnings("unchecked")
    public static <T> T wrap(final Holder<T> holder, final Class<T> clazz) {
        return (T) Proxy.newProxyInstance(clazz.getClassLoader(),
                clazz.getInterfaces(),
                new InvocationHandler() {
                    @Override
                    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                        return method.invoke(holder.responder, args);
                    }
                });
    }
}
```
这就是我们所谓的**动态切换的动态代理**了.
