title: 一劳永逸——RecyclerView无类型强转的通用ViewHolder
date: 2019-06-02 18:06:03
category: Tech
---
我们知道在一般的列表视图(recyclerView)中绑定不同类型的列表项子视图是通过各种类型的`ViewHolder`(比如`recyclerView.ViewHolder`). 不同数据对不同视图控件的操作是以实现各种ViewHolder子类的方式实现的.
**能不能只用一种类型的视图来涵盖所有的ViewHolder类型?** 听起来有些不可思议, 每种ViewHolder需要绑定的控件千差万别, 怎么抽象这些控件呢? 但实际上是可以实现的.

在support.v7.preference库中作者就用了一种方式实现这种效果:
```java
public class PreferenceViewHolder extends RecyclerView.ViewHolder {
    private final SparseArray<View> mCachedViews = new SparseArray<>(4);

    public View findViewById(@IdRes int id) {
        final View cachedView = mCachedViews.get(id);
        if (cachedView != null) {
            return cachedView;
        } else {
            final View v = itemView.findViewById(id);
            if (v != null) {
                mCachedViews.put(id, v);
            }
            return v;
        }
    }
}
```
这样外部只需通过`findViewById`来找到各种各样的控件实例来进行数据绑定即可, 但是声明的ViewHolder却只需一种! 仔细想想这种通过SparseArray持有的方式其实非常巧妙, 真正将ViewHolder作为各种视图的持有者(Holder)不用再区分类型, 可谓实至名归.

稍加改造就可以和新API的findViewById风格完全保持一致(我们姑且叫做`ItemViewHolder`, 抽象所有列表视图子视图):
```java
public class ItemViewHolder extends RecyclerView.ViewHolder  {
    private final SparseArrayCompat<View> mCached = new SparseArrayCompat<>(10);

    public ItemViewHolder(View itemView) {
        super(itemView);
    }

    public <T extends View> T findViewById(@IdRes int resId) {
        int pos = mCached.indexOfKey(resId);
        View v;
        if (pos < 0) {
            v = itemView.findViewById(resId);
            mCached.put(resId, v);
        } else {
            v = mCached.valueAt(pos);
        }
        @SuppressWarnings("unchecked")
        T t = (T) v;
        return t;
    }
}
```
其实RecyclerView.ViewHolder本身就应该设计成这种方式, 并且声明成`final`强制移除各种Viewholder类型的强转.

所以还是要多看官方成熟的库, 他们的设计和实现都是经过千锤百炼, 对学习非常有益处.
