title: 百行以内——超轻量级的多类型列表视图框架
date: 2019-07-06 22:27:48
category: Tech
---
名字有点唬人，其实就是组合了几个封装类能够方便实现`RecyclerView`的多视图，毕竟“框架”这个词在我看来还是指具有一定规模量级及重点技术的代码体系，但仅就解决特定问题而言也不妨被冠以这个名号。同时它真的是“超轻量”总共不过4个类，不超过130行代码~

# 视图抽象
我们已经有了一个[无需类型强转的通用ViewHolder](https://juejin.im/post/6844903858452316168)(ItemViewHolder)，一个ViewHolder对象可以找到所有视图实例。而且它是完全独立的， 没有引入任何自定义类或者任何第三方依赖；即使没有这个“框架”，也完全可以拆出来用在其他地方。

# 控件适配器
适配器(Adapter)是与控件关联的, 是控件对其子视图列表的一种抽象。抽象了什么？由具体定义决定。比如列表控件的适配器（无论是以前的`ListView`, 现在`RecyclerView`, 以及其它的如`ViewPager`）一般抽象了三个属性：
1. 数量 getItemCount()
2. 操作 onBindView(ViewHolder holder, int position)，onCreateView
3. 类型 getViewType(int position)

控件适配是SDK关联的，框架的`ItemAdapter`也是基于`RecyclerView.Adapter`

# 元素抽象
适配器(Adapter) 是容器控件对子控件的整体抽象，相应位置的元素没有作出任何限制，`position`对应的元素可以是接口返回的一个具体数据，也可以是从本地获取的应用数据。框架要做的一个工作就是对元素数据类型进行抽象, 但是数据类型千差万别，无法对数据元素本身的属性做统一操作，结果就是变成像[`MultiType`](https://github.com/drakeet/MultiType)库那样，用范型抽象所有的数据元素，然后通过注册数据类型(`.class`)到数据绑定器类型(`ItemViewBinder.class`)的映射，反射得到绑定器实例，其中有大量的对象类型强转。

框架不对数据元素做抽象，而是针对操作作抽象，即adapter对每个`position`元素的操作作抽象；用一个简单的`List`数据结构持有抽象实例；因为同样有绑定操作，所以姑且也叫做绑定器`ItemBinder`。ViewHolder就用我们之前的通用ViewHolder(`ItemViewHolder`)，结合前面说到adapter有三个重要属性，于是有:
```java
public interface ItemBinder {
    void onBindViewHolder(ItemViewHolder holder, int position);
    int getViewType();
}

public class ItemAdapter extends RecyclerView.Adapter<ItemViewHolder> {
    private final List<ItemBinder> mBinders = new ArrayList<>(10);

    @Override
    public void onBindViewHolder(@NonNull ItemViewHolder holder, int position) {
        ItemBinder binder = mBinders.get(position);
        binder.onBindViewHolder(holder, position);
    }

    @Override
    public int getItemCount() {
        return mBinders.size();
    }

    @Override
    public int getItemViewType(int position) {
        return mBinders.get(position).getViewType();
    }

    public void setBinders(List<ItemBinder> binders) {
        mBinders.clear();
        mBinders.addAll(binders);
    }
}
```
对于Adapter而言，元素仅仅是`ItemBinder`，它不关心`ItemBinder`是用哪种数据类型，又是怎样把数据填充到ViewHolder中。

# 视图类型
`RecyclerView`通过`RecyclerView.Adapter`的`getItemViewType`接口返回的数值来标识一个视图类型。与`ListView`不同的是这个viewType可以**不是连续的**，`RecyclerView`可以自己感知设置了多少种`viewType`（内部其实就是用了`SparseArray`）。通过`viewType`的标识, `RecyclerView.Adapter`的`onCreateViewHolder`来创建相应的视图类型。通常我们不得不自己建立`viewType`和`RecyclerView.ViewHolder`的映射关系，除了稍有点烦琐之外并没有多大的问题。

**注意**：我们走到了到框架的一个关键点，就是建立`viewType`和视图实例创建之间的关系。

已经找不到是在哪个库里，当看到把视图资源id(layoutId)直接作为`viewType`返回的时候，被这种天才想法折服了。首先就是用资源id本身就可以创建视图；其次是充分利用了`viewType`可以**不连续**的性质；再次是不同的资源id天然的对应不同的视图类型，也就是说，本身就是多视图类型的；最后的最后就是这种实现提供了巨大的灵活性，包括代码复用和资源的复用，这点后面专门说一下。于是有：
```java
public interface ItemBinder {
    void onBindViewHolder(ItemViewHolder holder, int position);

    @LayoutRes
    int getLayoutId();
}

public class ItemAdapter extends RecyclerView.Adapter<ItemViewHolder> {
    private final List<ItemBinder> mBinders = new ArrayList<>(10);

    @NonNull
    @Override
    public ItemViewHolder onCreateViewHolder(@NonNull ViewGroup container, int viewType) {
        return new ItemViewHolder(LayoutInflater.from(container.getContext()).inflate(
                viewType, container, false));
    }

    @Override
    public void onBindViewHolder(@NonNull ItemViewHolder holder, int position) {
        ItemBinder binder = mBinders.get(position);
        binder.onBindViewHolder(holder, position);
    }

    @Override
    public int getItemCount() {
        return mBinders.size();
    }

    @Override
    public int getItemViewType(int position) {
        return mBinders.get(position).getLayoutId();
    }

    public void setBinders(List<ItemBinder> binders) {
        mBinders.clear();
        mBinders.addAll(binders);
    }
}
```

我们之前被`getItemViewType`的默认值0给误导了，思维惯性让我们认为`viewType`可以和`ViewHolder`是割裂的，但其实它们可以是统一的！

剩下的工作简单明了，实现具体的`ItemBinder`类型，将具体的数据填充到视图，比如:
```java
public HomeBannerBinder implements ItemBinder {
    private final HomeBanner mItem;
    HomeBannerBinder(HomeBanner banner) {
        mItem = banner;
    }

    void onBinderViewHolder(ItemViewHolder holder, int position) {
        ImageView bg = holder.findViewById(R.id.background);
        if (bg != null) {
            ImageManager.load(bg, mItem.bg_url);
        }
    }
}
```

# 灵活复用
这里的**复用**不是`recyclerView `对视图内存对象的复用，而是代码层面的复用，包括声明资源的xml代码。

把layoutId作为`viewType`到底带来怎样的灵活复用呢？

可以先举例常见的微信朋友圈列表：显然，很多朋友圈内容都是不同的，有视频有图片有文本，或者它们的结合，处理2张图片的布局和处理9张图片的布局显示也是不同的；但是每一条朋友圈布局有很多相同的地方：都有顶部的用户头像与用户名称，都有底部点赞和评论布局。那么问题来了：怎样声明不同的视图类型，但不必重复书写这些一样的地方？

这当然不是难事，比如一个视频朋友圈布局可写成这样`circle_item_video.xml`
```xml
<RelativeLayout>
     <include layout="@layout/circle_item_top" />
     <include layout="@layout/circle_item_layer_video" />
     <include layout="@layout/circle_item_bottom" />
</RelativeLayout>
```
音频朋友圈布局`circle_item_audio.xml`就把`@layout/circle_item_layer_video`换成`@layout/circle_item_layer_audio`，依次类推。

这么做完全可以实现，随着类型的增多，布局文件相应增加即可；然而一旦发生变更呢？只要涉及相同布局的部分都必须改一遍！(比如把`RelativeLayout`变成`android.support.constraint.ConstraintLayout`)而且实际的情况不一定这么简单，可能因为各种原因视图的层次比较深，并且都没办法放在include中，一旦视图对象变多，视图层次变深， 这种冗余就让人难以忍受了，对一个有追求的码畜来说，肯定希望只更改一处地方即可。

## 视图复用
如果layoutId作为viewType要如何实现刚才的复用呢？显然他们必须是不同的`viewType`（如果一样会发生什么？），那么他们当然是不同的layoutId，但不同的layoutId就无法避免上面那样的问题，这时候就用到android的**匿名资源(anonymous)**，就是对一个资源声明一个引用，而这个引用本身作为一个资源，即`<item name="def" type="drawable">@drawable/abc</item>`，结合以上的例子就是
`circle_item.xml`:
```xml
<RelativeLayout>
     <include layout="@layout/circle_item_top" />
     <ViewStub />
     <include layout="@layout/circle_item_bottom" />
</RelativeLayout>
```
中间的部分可通过延迟加载的方式设置成不同的View，甚至所有不同的部分都可以以`ViewStub`的形式嵌在布局当中。
`refs.xml`:
```xml
<resources>
    <item name="circle_item_video" type="layout">@layout/circle_item</item>
    <item name="circle_item_audio" type="layout">@layout/circle_item</item>
    <item name="circle_item_pic_1" type="layout">@layout/circle_item</item>
    <item name="circle_item_pic_9" type="layout">@layout/circle_item</item>
</resources>
```
也就是说都引用同一份的布局资源！可他们因为不同的`layoutId`进而可以被`recyclerView`当作不同的`viewType`！
## 代码复用
按照之前的思路也必然希望只在一处更改点赞和评论功能。所以有一个基类：
```java
public class CircleItemBinder implements ItemBinder {
    @Override
    public getLayoutId() {
        return R.layout.circle_item;
    }

    @Override
    void onBindViewHolder(ItemViewHolder holder, int position) {
        bindComment(holder);
        bindLike(holder);
    }

    private void bindComment(ItemViewHolder holder) {
    }

    private void bindLike(ItemViewHolder holder) {
    }
}
```
各类型的binder类似:
```java
public class CircleVideoBinder extends CircleItemBinder {
    private final YourVideoData mItem;

    public CircleVideoBinder(YourVideoData data) {
        mItem = data;
    }

    @Override
    public getLayoutId() {
        return R.layout.circle_item_video;
    }

    @Override
    void onBindViewHolder(ItemViewHolder holder, int position) {
        super.onBindViewHolder(holder, position);
        TextView title = holder.findViewById(R.id.video_title);
        if (title != null) {
            title.setText(mItem.title);
        }
        ...
    }
}

public class CircleAudioBinder extends CircleItemBinder {
    private final YourAudioData mItem;

    public CircleAudioBinder(YourAudioData data) {
        mItem = data;
    }

    @Override
    public getLayoutId() {
        return R.layout.circle_item_audio;
    }

    @Override
    void onBindViewHolder(ItemViewHolder holder, int position) {
        super.onBindViewHolder(holder, position);
        ImageView album = holder.findViewById(R.id.audio_album);
        if (album != null) {
            ImageLoader.load(album, mItem.album_background);
        }
        ...
    }
}
```
点赞和评论功能的代码就可完全复用！这一切只是用了layoutId作为了viewType!
至此，框架的全貌已呈现：
```java
public interface ItemBinder {
    @LayoutRes
    int getLayoutId();

    void onBindViewHolder(ItemViewHolder holder, int position);
}

public class ItemAdapter extends RecyclerView.Adapter<ItemViewHolder> {
    private final List<ItemBinder> mBinders = new ArrayList<>(10);

    @NonNull
    @Override
    public ItemViewHolder onCreateViewHolder(@NonNull ViewGroup container, int viewType) {
        return new ItemViewHolder(LayoutInflater.from(container.getContext()).inflate(
                viewType, container, false));
    }

    @Override
    public void onBindViewHolder(@NonNull ItemViewHolder holder, int position) {
        ItemBinder binder = mBinders.get(position);
        binder.onBindViewHolder(holder, position);
    }

    @Override
    public int getItemCount() {
        return mBinders.size();
    }

    @Override
    public int getItemViewType(int position) {
        return mBinders.get(position).getLayoutId();
    }

    public void setBinders(List<ItemBinder> binders) {
        mBinders.clear();
        appendBinders(binders);
    }
}
```
我们之前的通用ViewHolder也罗列在这里:
```java
public class ItemViewHolder extends RecyclerView.ViewHolder {
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
一般都还要定义一个基础类`ItemBaseBinder`，所有派生类的可能会共享某个操作, 这个基础类接收资源id作为构造函数参数:
```java

public class ItemBaseBinder implements ItemBinder {
    private final int mLayoutId;

    public ItemBaseBinder(@layoutRes int layoutId) {
        mLayoutId = layoutId;
    }

    @Override
    public void onBindViewHolder(ItemViewHolder holder, int position) {
    }

    @Override
    public int getLayoutId() {
        return mLayoutId;
    }
}
```
其余的工作就只是派生具体的业务类了，就像之前举例那样！这一切不过130行代码！

# 与`MutiType`的差异
### 实例一对一
`MutiType`库同样有绑定器`ItemViewBinder`但注意他的绑定是只有一个实例，而我们的`ItemAdapter`是把绑定器作为元素对象，一个数据对应一个绑定器所以他有多个实例，实际上这个绑定器是对数据的抽象。

### 无类型转换无反射操作
真的，`MutiType`把这一切搞的太复杂了！可悲的是还有很多人在用……

# 结语
有了这个框架，灵活性不仅一点没有损失，而且更加简洁，`MutiType`那坨类型强转和反射操作可以进博物馆了。

一大篇说下来有点累赘，直接上代码就能看明白的，关键是思考的过程与解决问题的思路。所有的框架到底解决了什么问题，这才是最需要了解和学习的，否则框架是学不完的。而一旦我们有了思路与目标，实现一个框架也并不是难事。这套小框架实践已经很长时间了，可以覆盖绝大多数情况，效果出奇的好，比`MutiType`那坨“不知道高到哪里去了”。

需要注意的有2点
1. `onBindViewHolder`方法只做数据填充不应该做数据处理
这点其实和框架没有关系，照样还是有许多人在Adapter的`onBindViewHolder`做着数据处理
2. 动态的更换视图类型
因为方法`getLayoutId`是接口，意味着在运行时可以返回不同的layoutId，从而动态的更改视图类型，不过需要与Adatper的`notifyItemChanged`配合使用
3. 外部通知更新
`ItemAdapter.setBinders`的方法实现体在更新了实例后没有调用`notifyDataSetChanged`， 这个操作应该由外部决定，虽然此处是必要的，但很容易造成冗余的更新。

# 扩展
框架也非常容易根据具体的需要和场景进行扩展。
### 嵌套
列表嵌套列表的情况下，要如何抽象呢，其实只要对应视图就行。最外层的列表（一级列表）有一个特殊`ItemBinder`类型，这个类型本身也可以持有多个`ItemBinder`提供给内层列表(二级列表)：
```java
public class ItemContainerBinder extends ItemBaseBinder {
    private final ItemAdapter mAdapter = new ItemAdapter();

    @Override
    public void onBinderViewHolder(ItemViewHolder holder, int position) {
        RecyclerView secondary = holder.findViewById(R.id.secondary);
        if (secondary != null) {
            if (secondary.getAdapter() != mAdapter) {
                secondary.setAdapter(mAdapter);
            }
            if (secondary.getLayoutManager() == null) {
                secondary.setLayoutManager(new LinearLayoutManager(secondary.getContext());
            }
        }
    }

    public void setBinders(List<ItemBinder> binders) {
        mAdapter.setBinders(binders);
    }
...
}
```
在这里还可以利用以前提过的[重用LayoutManager](https://www.jianshu.com/p/d74f25215004)！

### 局部更新
在运行过程中只需要更新列表某一项的情况其实非常常见，很多时候不能只通过调用视图对象的方法来直接更新视图，还要调用`Adapter.notifyItemChanged`（像前文所提的动态更新列表视图类型）。也就是Adapter持有`ItemBinder`，而`ItemBinder`需要再调用Adapter的方法，如果再让`ItemBinder`去引用`Adapter`，这种强耦合必然不是一个好的设计。

针对这个框架的实现，这时候首先需要将`ItemBinder`内部的变化通知出来，但是通知的时机应该由`ItemBinder`实现体来决定，外部去被动响应。这当然是最简单的观察者模式了，于是有：
```java
public interface ItemBinder {
...
    void setOnChangeListener(OnChangeListener listener);

    interface OnChangeListener {
        void onItemChanged(ItemBinder item, int payload);
    }
}

public class ItemBaseBinder implements ItemBinder {
...
    private OnChangeListener mChangeListener;

    @Override
    publi final void setChangeListener(OnChangeListener listener) {
        mChangeListener = listener;
    }

    public final void notifyItemChange(int payload) {
        if (mChangeListener != null) {
            mChangeListener.onItemChanged(this, payload);
        }
    }
}
```
这里的`payload`借鉴了`RecyclerView.Adapter`，只不过类型由`Object`变成了`int`，代表了局部更新需要携带的信息。在`ItemBinder`实现体内部，因为某项数据变更需要通知到外部就只需调用`notifyItemChange`方法，将变更传递出去，由外部作出具体响应:
```java
List<ItemBinder> binders = new ArrayList<>();
...
ItemBinder special = new XXXYYYBinder(...);
specail.setChangeListener(new ItemBinder.OnChangeListener() {
    @Override
    public void onItemChanged(ItemBinder item, int payload) {
        int pos = mAdapter.indexOf(item);
        if (pos >= 0) {
            mAdapter.notifyItemChanged(pos,...);
        }
    }
});
binders.add(special);
...
mAdapter.setBinders(binders);
```
