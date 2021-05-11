title: GestureDetector无法取消长按
date: 2017-06-29 18:58:20
category: Tech
---
期望对RecyclerView中的item可以做单击, 长按, 和拖拽操作, 利用`OnItemTouchListener`可以达到一个在外部总控的目的。一般的对Item的操作都是在Item内部定义一个OnClickListener，如果Item的点击之类的操作与外部无关并且Item内部状态各不相同， 那这样做是最好的，但如果需要和外部关联并且这些操作不会对个别的Item另作处理，这样做就有些不足，通常这样的操作是各个Item持有同一个操作实例， 这就是所谓“外部总控”。

比如：对一个Item长按，item自己状态变成selected或者checked, 同时外部界面变成编辑界面，Item的操作各不相同，但变成编译界面不区别具体某个Item，这样一个操作不仅涉及Item内部状态数据的变化，也涉及外部操作响应。`OnItemTouchListener`的好处就是能够统一在recyclerView层进行Touch事件的操作而同时不影响Item内部设置的各个Touch事件。
**但是**，现实却是另一回事，实践了一下`OnItemTouchListener`却没有达到预想的目的。

一般的，利用`OnItemTouchListener`这个接口需要再用到GestureDetector这个对象。
声明了对一个Item的操作接口
```java
    public interface OnItemClickListener {
        void onItemClick(RecyclerView.ViewHolder holder);

        void onItemLongClick(RecyclerView.ViewHolder holder);

        boolean startDragging(RecyclerView.ViewHolder holder, MotionEvent e);
    }
```
在`GestureDetector.SimpleOnGestureListener`的`onSingleTapUp`响应`onItemClick`, `onLongPress`响应`onItemLongClick`，`onDown`里外部决定是否可拖拽`startDragging`。

```java
private static class RecyclerItemTouchHandler implements RecyclerView.OnItemTouchListener {
    private final OnItemClickListener mListener;
    private final GestureDetectorCompat mGestureDetector;

    public RecyclerItemTouchHandler(final RecyclerView rv, OnItemClickListener listener) {
        mListener = listener;
        GestureDetector.OnGestureListener gestureListener = new GestureDetector.SimpleOnGestureListener() {
            @Override
            public boolean onSingleTapUp(MotionEvent e) {
                android.util.Log.d("wesley", "RecyclerItemTouchHandler.onSingleTapUp");
                View child = rv.findChildViewUnder(e.getX(), e.getY());
                if (child != null) {
                    mListener.onItemClick(rv.getChildViewHolder(child));
                }
                return super.onSingleTapUp(e);
            }

            @Override
            public void onLongPress(MotionEvent e) {
                View child = rv.findChildViewUnder(e.getX(), e.getY());
                if (child != null) {
                    mListener.onItemLongClick(rv.getChildViewHolder(child));
                }
                android.util.Log.d("wesley", "RecyclerItemTouchHandler.onLongPress");
            }

            @Override
            public boolean onDown(MotionEvent e) {
                View child = rv.findChildViewUnder(e.getX(), e.getY());
                boolean handled = child != null && mListener.startDragging(rv.getChildViewHolder(child), e);
                if (handled) {
                    mGestureDetector.setIsLongpressEnabled(false);
                    android.util.Log.d("wesley", "RecyclerItemTouchHandler.onDown");
                }
                return handled || super.onDown(e);
            }
        };
        mGestureDetector = new GestureDetectorCompat(rv.getContext().getApplicationContext(),
                gestureListener);
    }

    @Override
    public boolean onInterceptTouchEvent(RecyclerView rv, MotionEvent e) {
        return mGestureDetector.onTouchEvent(e);
    }

    @Override
    public void onTouchEvent(RecyclerView rv, MotionEvent e) {
        android.util.Log.d("wesley", "RecyclerItemTouchHandler.onTouchEvent");
        mGestureDetector.onTouchEvent(e);
    }

    @Override
    public void onRequestDisallowInterceptTouchEvent(boolean disallowIntercept) {
    }

    public static boolean hitTest(View view, float x, float y) {
        int location[] = new int[2];
        view.getLocationOnScreen(location);
        int viewX = location[0];
        int viewY = location[1];
        return (x > viewX && x < (viewX + view.getWidth())) &&
                (y > viewY && y < (viewY + view.getHeight()));
    }
}
```
在`startDragging`的实现中利用`ItemTouchHelper`的来做具体操作：

```java
view.addOnItemTouchListener(new RecyclerItemTouchHandler(view, new RecyclerItemTouchHandler.OnItemClickListener() {
    @Override
    public void onItemClick(RecyclerView.ViewHolder holder) {
        if (mPresenter.isEdit()) {
            int pos = holder.getAdapterPosition();
            boolean selected = !mPresenter.isSelected(pos);
            mPresenter.selectProvider(pos, selected);
        }
    }

    @Override
    public void onItemLongClick(RecyclerView.ViewHolder holder) {
        if (mPresenter.setEdit(true) &&
                mPresenter.selectProvider(holder.getAdapterPosition(), true)) {

        }
    }

    @Override
    public boolean startDragging(RecyclerView.ViewHolder holder, MotionEvent e) {
        View drag = holder.itemView.findViewById(R.id.drag_icon);
        boolean handled = drag != null && RecyclerItemTouchHandler.hitTest(drag,
                e.getRawX(), e.getRawY());
        if (handled) {
            mTouchHelper.startDrag(holder);
        }
        return handled;
    }
}));

```
这一切是那么的完美，**然而**实现的效果却是在拖拽的过程中响应了`onLongPress`的事件！费了半天劲找原因，看了下`GestureDetector`源码，原来是因为在`onDown`中并没有取消`LONG_PRESS`的消息:
```java
case MotionEvent.ACTION_DOWN:
...
if (mIsLongpressEnabled) {
    mHandler.removeMessages(LONG_PRESS);
    mHandler.sendEmptyMessageAtTime(LONG_PRESS, mCurrentDownEvent.getDownTime()
            + TAP_TIMEOUT + LONGPRESS_TIMEOUT);
}
mHandler.sendEmptyMessageAtTime(SHOW_PRESS, mCurrentDownEvent.getDownTime() + TAP_TIMEOUT);
handled |= mListener.onDown(ev);
break;
```
也就是说即使onDown返回`true`，`LONG_PRESS`的消息还是发出了。这与我们通常对Touch事件的理解有些不同，为啥要这样写呢？我认为应该改成这样：
```java
handled |= mListener.onDown(ev);
if (!handled && mIsLongpressEnabled) {
    mHandler.removeMessages(LONG_PRESS);
    mHandler.sendEmptyMessageAtTime(LONG_PRESS, mCurrentDownEvent.getDownTime()
            + TAP_TIMEOUT + LONGPRESS_TIMEOUT);
}
break;
```
但是不管怎样，因为GestureDetector无法取消长按，没法用这种实现了，最后在外部还是用了`View.OnClickListener`，`View.OnLongClickListener`，`View.OnTouchListener`，显然，在`OnTouchListener`中由于返回了`true`, `OnLongClickListener`无法被响应。但是这种实现有个不好的点是在执行`onBindViewHolder`时不能在对应的View上再设置或者覆盖其它的Listener了，否则操作失效。
