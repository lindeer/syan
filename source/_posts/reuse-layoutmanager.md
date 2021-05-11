title: 重用LayoutManager
date: 2017-11-10 19:32:23
category: Tech
---
在RecyclerView嵌套RecyclerView的情况中，里层RecyclerView(Secondary RecyclerView)所在的ViewHolder将会与数据进行绑定，它当然需要设置一个LayoutManager。然而在onBindViewHolder方法中创建LayoutManger实例毕竟不太好，每次调用onBindViewHolder都有实例生成容易产生内存碎片。于是每个数据Item去持有一个LayoutManger实例是自然而然的。但是问题来了：
如果一个数据Item已经和一个ViewHolder绑定过或者说该位置的LayoutManager已经和一个recyclerView绑定过，这时在onBindViewHolder中要和另外一个ViewHolder实例进行绑定，直接设置会有异常抛出:
```
java.lang.IllegalArgumentException: LayoutManager android.support.v7.widget.GridLayoutManager@33d32b28 is already attached to a RecyclerView:
```
我们很自然的想到需要在Viewholder被回收的时候将RecyclerView的LayoutManger置空:
```java
@Override
public void onBindViewHolder(ViewHolder viewHolder, int position) {
    viewHolder.recyclerView.setLayoutManager(null);
}
```
然而是不行的！原因是时机的问题：复用ViewHolder未必需要先将ViewHolder回收，在ViewHolder移出ViewPort后并且有同一类型的ViewHolder需要展示当然直接被绑定。
所以我们需要先把LayoutManager中已经绑定的RecyclerView移除，但是找不到方法可以这么做！
查看源码LayoutManager持有一个recyclerView的实例，所以只要设置这个实例为空就可以了，而这个recyclerView的成员是包名访问的，只要创建一个同名包的方法就可以了:
```
package android.support.v7.widget;
public final class RecyclerViewUtils {
}
```
这样就可以访问LayoutManger的`mRecyclerView`和它的`setRecyclerView`方法了。
然而直接调用setRecyclerView也是不行的！
RecyclerView在和LayoutManger绑定后作了很多设置和状态记录需要将其一并清除，否则在视图上会有紊乱。正确的作法是调用recyclerView的`setLayoutManager`方法。
于是终于有:
```java
  public static void detachLayoutManager(LayoutManager manager) {
    RecyclerView old = manager == null ? null : manager.mRecyclerView;
    if (old != null) {
      old.setLayoutManager(null);
    }
  }
```
这样在onBind的时候终于可以不用再创建LayoutManger了！而且运行的很好～
