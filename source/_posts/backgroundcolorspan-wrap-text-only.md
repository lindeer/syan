title: 只包裹文本的BackgroundColorSpan
date: 2017-12-22 11:06:27
category: Tech
---
`BackgroundColorSpan`可以实现文本加底色的一个效果，没有问题，然而问题是文本增加间距的时候效果会变成这样:
![](http://upload-images.jianshu.io/upload_images/19161-0bb74bacf2a8bdf7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
所以我们期望达到的效果是一个只包裹文本的的背景底色。
研究了一下，发现必须得到文本相关的信息，才能在指定的位置填充颜色，所以无法再利用`BackgroundColorSpan`这个类了，而要用`ReplacementSpan`，于是有:
```
public class BorderSpan extends ReplacementSpan {
    private int mWidth;
    private int mBackgroundColor;

    public BorderSpan(@ColorInt int backgroundColor) {
        mBackgroundColor = backgroundColor;
    }

    @Override
    public int getSize(@NonNull Paint paint, CharSequence text, int start, int end,
                       Paint.FontMetricsInt fm) {
        mWidth = (int) paint.measureText(text, start, end);
        return mWidth;
    }

    @Override
    public void draw(@NonNull Canvas canvas, CharSequence text, int start, int end,
                     float x, int top, int y, int bottom, @NonNull Paint paint) {
        int color = paint.getColor();
        if (mBackgroundColor != 0) {
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(mBackgroundColor);
            canvas.drawRect(x, top, x + mWidth, bottom, paint);
        }
    }
}
```
然而发现效果竟然和`BackgroundColorSpan`一样！显然这里需要在`bottom`上作文章。这时候需要了解一些字体相关的知识:
![](http://upload-images.jianshu.io/upload_images/19161-3fe6386ac331457b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
并且需要知道的是`ascent`，`descent`是相对于baseline的值，所以`ascent`经常是负值，而对应的类便是`Paint.getFontMetrics()`的`FontMetrics`, 在类字段描述中有这样一段:
![](http://upload-images.jianshu.io/upload_images/19161-7577b2fed36609fe.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
所以最终用到的是这个字段，`draw`方法需要知道的重要一点是，这里的`y`就是字体信息对应的`baseline`，于是有:
```

    @Override
    public void draw(@NonNull Canvas canvas, CharSequence text, int start, int end,
                     float x, int top, int y, int bottom, @NonNull Paint paint) {
        int color = paint.getColor();
        bottom = (int) (y + paint.getFontMetrics().bottom);
        ....
    }
```
效果终于达到了:
![](http://upload-images.jianshu.io/upload_images/19161-77992934e1917cc0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
如果不用bottom而用descent呢？
大家可以试验下，只是包裹的边界很靠近文本而已。
