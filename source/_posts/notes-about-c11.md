title: C++11笔记
date: 2017-06-14 10:49:55
category: Tech
---
# 友元类是模板类的声明
有一个类成员私有，希望指定的模板类可以访问，比如:
```
class A {
    A* next;
};

template<T>
class Container {
    T array[5];
public:
    typedef T container_type;
    T access() {
        T a = array[0];
        a.next = ...;
        return a;
    }
};

Container<A> container;
```
只希望Container能访问私有成员, 其它的任何类不可以。直接声明会有编译错误，当然如果把`A`声明成`struct`可以解决问题，但是要达到数据封装的目的就必须用到friend关键字:
```
class A {
    template<typename T>
    friend class Container;
    A* next;
};
```
这样就可以编译通过了，如果有另一个类`B`也希望只有`Container`能访问私有, 那么`B`也必须作如此的声明, 于是每个特化的模板参数必须都在模板参数的类中作如此的声明否则就有编译错误，而且需要注意`typename`的情况:
```
template<typename C>
class Array {
    C c;
public:
    typename C::container_type access() {
        return c.access();
    }
};

template<typename T>
using ArrayContainer = Array<Container<T>>;

ArrayContainer<A> array;
A a = array.access();
```
`Container<T>`本身作为模板参数传给另一个类`Array`，并且`Array`实现了同一个接口方法，这时候A对应的friend类依然是`Container`而不能是其它的类，否则会有编译错误，这意味着我们需要找到实际操纵A这个类型的类，在它范围内声明friend。
实际的应用会比这个复杂，如果作为模板参数类型的A本身也是一个`typename`那就需要既找到外部操纵类的原始类型,还要找到被操作类型的原始类型。



#typedef类型的前置声明
```
class A;
class B {
public:
    void foo(A::value_type& v);
};

class A {
    typedef something value_type;
};
```
`typedef`定义的类型**无法**前置声明。这意味着必须把`typedef`定义语句头文件include进来, 相关的信赖引用就得都include进来



#new操作封装(wrapper)
在new一个对象的时候希望作跟踪或者其它操作，最好是封装成一个函数，在函数体内部再做其他操作。但是类的构造函数的类型和个数都是不定的，为了实现就必须用到模板类不定参数:
```
template<typename T, typename... ARGS>
static T* alloc(ARGS&&... args) {
    return new T(std::forward<ARGS>(args)...);
}

alloc<int>()...
```
std::forward<ARGS>表示ARGS的各个类型继续保持传入函数时的类型，以作为T的构造函数参数类型，主要是为了解决右值问题。



#不定参数函数的封装
说到不定参数，怎么样封装一个不定参数的函数？比如想给指定的格式化输出带颜色，但格式化输出的参数是不定参数，这时候不能直接使用printf，而要用vprintf
```
#include <cstdarg>
#include <cstdio>
void log(const char *format, ...) {
    printf("\033[1;33m"); // 文本以黄色输出
    va_list args;
    va_start(args, format);
    vprintf(format, args);
    va_end(args);
}
```
#模板形式的面向接口编程
无论C++还是Java典型的面向接口是将接口声明成虚函数：
```
//c++
class listener {
    virtual void on_click() = 0;
};

//java
public interface listener {
    void onClick();
}
```
于是各种子类以继承形式来实现接口，再在运行时找到实际对应的成员函数实体。而现代C++的形式则是利用模板, 在[友元类是模板类的声明]()这个例子中充分说明了这种实现方式, 无论是`Container`还是`Array`, 都实现了`A access()`这个函数接口,只是在`Array`中以`typename C::container_type`形式假定了模板参数类型提供了真实的操纵类型,所以`Container`及类似的外部操纵类型都强制提供一个`container_type`。
这个例子中`Array`也可以写成如下形式:
```
template<typename C>
class Array: private C {
public:
    typename C::container_type access() {
        return C::access();
    }
};
```
但模板编程有一个原则: 钟爱组合而不是继承, 组合能够提供更大的灵活性。



#线程存储对象的定义与声明
通过`thread_local`关键字的修饰，可以将一个类型的某一变量声明成线程对象:
```
class ThreadObject {
};

//全局对象的外部初始化
thread_local ThreadObject _t_obj;
```
在linux上线程对象用了写时拷贝，在任何一个线程内引用_t_obj时才调用ThreadObject的构造函数。

现在问题来了，希望这个类只能作为线程对象存在，不能在堆或栈自行定义，也就是说构造函数必须私有。构造函数一旦私有上述代码就会有`error: ‘ThreadObject::ThreadObject()’ is private`的编译错误。我们即使提供静态函数来返回这个全局变量还是会有编译错误：
```
// ThreadObject.hh
class ThreadObject {
    static thread_local ThreadObject _t_obj;
public:
    static ThreadObject& get_obj();
};

// ThreadObject.cc
static thread_local ThreadObject _t_obj;
ThreadObject &ThreadObject::get_obj() {
    return _t_obj;
}
```
另外thread_local**不能**声明在类中！这样写会引起`TLS wrapper function for ...`的链接错误。
怎样才能既把构造函数私有又能静态全局引用？最关键的问题是不同的线程调用返回的是不同的对象？
乍看挺棘手的，其实却很简单，利用函数静态变量！
加上thread_local修饰，这样它是全局引用的但能够保持构造私有(因为是在类的作用域内)，关键是不同线程调用返回的是不同的对象!
```
// ThreadObject.hh
class ThreadObject {
public:
    static ThreadObject& get_obj();
};

// ThreadObject.cc
ThreadObject &ThreadObject::get_obj() {
    static thread_local ThreadObject _t_obj;
    return _t_obj;
}
```
#精度不同的时间比较
我们知道在`chrono`中，`时间点(time_point)+时间段(duration)=时间点`, 并且时间点的精度类型(duration)和时间段的精度类型可以不一致:
```
#include <iostream>
#include <chrono>

int main() {
    using milli_time = std::chrono::time_point<std::chrono::system_clock, std::chrono::milliseconds>;
    milli_time tp(std::chrono::milliseconds(1));
    std::cout << "milli_time_since_epoch: " << tp.time_since_epoch().count() << std::endl;
    tp += std::chrono::seconds(1);
    std::cout << "milli_time_since_epoch: " << tp.time_since_epoch().count() << std::endl;

    using micro_time = std::chrono::time_point<std::chrono::system_clock, std::chrono::microseconds>;
    micro_time tp2(std::chrono::milliseconds(1));
    std::cout << "micro_time_since_epoch: " << tp2.time_since_epoch().count() << std::endl;
    tp2 += std::chrono::seconds(1);
    std::cout << "micro_time_since_epoch: " << tp2.time_since_epoch().count() << std::endl;

    std::cout << "compare1: " << (tp + std::chrono::microseconds(1) < tp2) << std::endl;

    using hour_time = std::chrono::time_point<std::chrono::system_clock, std::chrono::hours>;
    hour_time tp3(std::chrono::hours(0));
    milli_time p(std::chrono::milliseconds(0));
    std::cout << "compare2: " << (p + std::chrono::microseconds(1) < tp3) << std::endl;
    return 0;
}
```
时间的比较有以下结论:
1. 低精度的时间不能用高精度的时间段初始化。
`milli_time tp(std::chrono::microseconds(1));` 编译是错误的
2. 低精度的时间也不能与高精度的时间段加合。
`milli_time += std::chrono::microseconds(1)` 也是不正确的
3. 精度不同的时间点可以比较。
4. 精度不同的时间点可与精度的不同的时间段相加并与精度不同的时间点比较。

#根据类型选择的模板选择
很多时候我们需要根据定义的类型自动匹配需要的函数,这时候就要用到模板特化来进行模板的选择。
仍以时间精度为例, 比如在某个系统上精度为milliseconds, 而在另一个系统上就保持默认的精度即可, 操作的接口应当是一致的, 所以我们很自然的用`typedef`:
```
#ifdef SOME_OS
typedef std::chrono::milliseconds       duration;
#else
typedef std::chrono::system_clock:duration       duration;
#endif
typedef std::chrono::time_point<std::chrono::system_clock, duration>       time_point;
```
现在希望一个now()接口返回当前时间点,时间点是我们自定义精度对应的time_point, 如果是默认的精度直接返回`std::chrono::system_clock::now`避免一个`time_point_cast`的操作。
```
template<typename T>
time_point cast_now(T) {
    return std::chrono::time_point_cast<message::duration>(
            sys_clock::now());
}
// 特化的模板函数
inline
sys_clock::time_point cast_now(std::chrono::nanoseconds) {
    return std::chrono::system_clock::now();
}


time_point now() {
    return cast_now<duration>(duration(0));
}
```
如果我们定义duration为`std::chrono::milliseconds`则匹配默认的模板函数, 否则调用特化模板函数。当然只是一个例子,如果直接用宏更简单。
在不能用宏来区别的情况下, 假如有种情况是`std::chrono::milliseconds`或者`std::chrono::nanoseconds`是一个比较大的对象, 我们只是生成一个临时变更进行模板选择,这样会有无谓的开销,不是我们希望的。
原理还是按照模板类型匹配,只不过我们用以匹配的类型变成简单类型就可以了, 这里用到`std::conditional`和`std::is_same`
```
typedef std::conditional<std::is_same<std::chrono::system_clock::duration,
            duration>::value, void*, int>::type         now_type;

time_point message::now() {
    return cast_now<now_type>(0);
}
```
如果duration是和系统精度一样, 定义now_type为void*, 否则为int, 用now_type来进行模板匹配, 它的临时对象的开销是非常小的。

#lambda返回类型自动推断
一个函数通过一个lambda表达式返回一个模板类对象, 那么能否仅通过lambda表达式自动推断出模板类对象的类型?
```
template<typename T>
class Job {
public:
    Job(T&& t) {
    }
};

template<typename T>
Job<T> create_job(std::function<T()>&& f) {
    return Job<T>(f());
}

int main(int argc, char** argv) {
    Job<int> t = create_job([] {
        return 0;
    });
}
```
答案是不行。会有`error: no matching function for call to ‘create_job ...`的错误, 根本原因是生成的lambda类型根本没带返回值的类型, 所以无法自动推断出返回的`Job<T>`类型, 只能明确把类型给带上: `create_job<int>([] {`, ,这实在不美观。
通用的解决办法是把整个可调用对象声明成模板参数:
```
template<typename _Call>
auto create_job(_Call&& call) -> Job<decltype(call())> {
    using T = decltype(call());
    return Job<T>(call());
}

int main(int argc, char **argv) {
    Job<int> j = create_job([] {
        return 0;
    });
}
```
虽然美观了, 可这样写意味着我们没法维持一个固定的接口, 随着各种lambda或者可调用对象的模板特化,会生成大量的`create_job`对应的代码, 感觉容易引起代码膨胀。

#避免条件变量唤醒后又阻塞
假如多线程的代码在某一点A处于等待状态:
```
std::unique_lock<std::mutex> lk(_lock);
_cv.wait(lk)
```
另一处B需要改变数据:
```
std::lock_guard<std::mutex> lk(_lock);
var = ...;
_cv.notify_one();
```
这里有一个细节需要注意:
当`notify_one`执行的时候, 锁是没有释放的, `notify_one`是立即执行的,也就是说A处代码会立马得到通知,从等待状态唤醒过来, 开始从wait返回, 然而返回需要获取锁,由于锁没有释放, A处代码又立即变为阻塞状态, 等待锁的释放。这样是有比较大的开销的, 我们需要在通知前就释放锁:
```
{
    std::lock_guard<std::mutex> lk(_lock);
    var = ...;
}
_cv.notify_one();
```
