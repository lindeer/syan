title: typedef的C++类模板的前置声明
date: 2014-06-10 17:13:13
category: Tech
---
前置声明的目的是为了在头文件中不引入其他头文件而让陌生的类型符号得以在编译阶段被解析的。类模板的前置声明和一般的类的前置声明类似，只不过再再一个`template<class T>`的声明头部。
但是针对一个typedef的类模板类型得写成这样：
```cpp
template<class T>
class point;
typedef point<int> Point;
...
...
bool contains(const Point& p) const;
```
定义文件是：
```cpp
template<class T>
class point {
};

typdef point<int> Point;
```
也就是得typedef两次， 我记得以前遇到过typedef重复定义的报错信息，但不知现在为何没有问题了……
