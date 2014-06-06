title: C++模板示例二则
date: 2014-06-06 11:37:17
category: Tech
---
1. 模板实例化时针对成员函数的特化
---
形如如下的一个类
```cpp
template<class T>
class Point {
private:
    T x, y;
public:
    inline bool operator == (const point_t& v) const {
        return x_ == v.x_ && y_ == v.y_;
    }

    Point operator + (const Point& v) const {
        return Point(x_ + v.x_, y_ + v.y_);
    }
};
```
显然`Point<float>, Point<double>` 的数值比较判断不可以用如此的方式，但是其他的成员还是可以继续使用模板的定义
所以我们的目的是实例化一个类的模板时，针对某些成员函数有不同的函数体。
如下的直接特化类模板等于重新定义了一个新类，不能重用类模板的一些定义（示例2）：
```cpp
template<>
class Point<float> {
...
};
```
查了查才知道得用这样的写法，直接定义函数实体，参数和返回值要和类模板的函数完全一致，类写成显示特化：
```cpp
template<>
bool Point<float>::operator == (const Point<float>& v) const {
    return fabs(x - v.x) < DELTA && fabs(y - v.y) < DELTA;
}
```
这样声明还有一个要求，就是不能够再写一个示例2那样的直接特化类了。这叫做**全局成员特化**，《*C++ Templates*》 12.3.3节有讲。

2. 函数模板引用参数的默认值
---
形如 `bool intersects(const Rect& r1, const Rect& r2, Rect& interRect)` 的函数。
我们希望能够给最右的参数赋以默认值，这样可以只在需要获得相交矩形的时候才给函数传以对象，否则只是判断是否相交没必要再传一个参数。
要达到这一目的可以有很多种写法，最好是一个函数就能搞定，简单明了。但是直接写成这种形式是不对的：
`bool intersects(const Rect& r1, const Rect& r2, Rect& interRect = Rect())`
因为使用默认参数的时候传进来的是不可修改的对象，这种错误类似于这样: `int& a = 10` , 写成这样是可以编译的：
`bool intersects(const Rect& r1, const Rect& r2, const Rect& interRect = Rect())`
但显然无法得到相交矩形了。
我们必须赋值一个变量，既然是默认的和任何对象无关，所以应当是全局变量，所以
```cpp
Rect g_rcDefalut = Rect();
bool intersects(const Rect& r1, const Rect& r2, Rect& interRect = g_rcDefalut);
```
是可以达到我们的目的的。
但是有另外一个问题就是模板，如果矩形是一个形如`Rect<int>`的类模板，函数也是函数模板，那这个默认值要怎么写。不可能预先的写下所有实例类型的Rect以作全局变量。
模板的问题还是要靠模板来解决，我们想得到的是一个全局变量而已，至于是怎么获得,可以直接引用也可以通过函数返回。但函数返回的是一个临时变量，和直接写`Rect& r = Rect()` 效果是一样的，这就得用C/C++的语法：函数内的静态变量，于是有如下的式子:
```cpp

template<class T>
bool intersects(const Rect<T>& r1, const Rect<T>& r2, Rect<T>& interRect = getDefault< Rect<T> >()) {
}

template<class T>
static inline T& getDefault() {
    static T s = T();
    return s;
}
```
妙的是`getDefault<T>()`可以返回各种全局默认类型比如 `Point<float>, Rect<double>` 。
