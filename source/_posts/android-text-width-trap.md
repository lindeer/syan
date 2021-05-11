title: Android计算文本宽度的坑
date: 2018-04-28 11:48:31
category: Tech
---
想实现自动缩放字体大小的功能，无论用第三方的控件还是`AppCompatTextView`都遇到一个问题：在滚动列表视图中显示有问题，在滚动过程中，明明有更大空间却用了一个小字体。没有时间细查实现，想着很简单就造个轮子。
想法很简单：计算每个非目标child的wrap_content宽度，用父宽度减去得availableWidth，再计算目标child的宽度，如果超过就减小字体值，直至合适的字体大小值出现。
然而实现后实际宽度比预期少那几个像素，使得相邻的文本折行了。

mRight是相邻文本TextView，mLeft是可绽放字体的TextView:
```java
    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        long time = System.currentTimeMillis();

        final int mode = MeasureSpec.getMode(widthMeasureSpec) >> 30;
        final int width = MeasureSpec.getSize(widthMeasureSpec);
        mRight.measure(0, 0);
        int rightMinWidth = mRight.getMeasuredWidth();
        MarginLayoutParams llp = (MarginLayoutParams) mLeft.getLayoutParams();
        MarginLayoutParams rlp = (MarginLayoutParams) mRight.getLayoutParams();
        int available = width - rightMinWidth - rlp.leftMargin - rlp.rightMargin
                - llp.leftMargin - llp.rightMargin;

        Paint textPaint = mLeft.getPaint();
        CharSequence cs = mLeft.getText();
        String text = cs == null ? null : cs.toString();
        float textSize = mOriginTextSize;
        textPaint.setTextSize(textSize);
        for (int bounds = getTextSize(textPaint, text); bounds > available;
             bounds = getTextSize(textPaint, text)) {
            textSize -= 2;
            textPaint.setTextSize(textSize);
        }
        time = System.currentTimeMillis() - time;
        Logger.d(TAG, "onMeasure: mode=%d, width=%d, right=%d," +
                        " available=%d, textSize=%.2f, origin=%.2f, cost=%d",
                mode, width, rightMinWidth, available, textSize, mOriginTextSize, time);

        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
    }

    private static int getTextSize(Paint paint, @Nullable String text) {
        if (text == null) {
            return 0;
        }
        paint.getTextBounds(text, 0, text.length(), sTextBounds);
        return sTextBounds.width();
    }
```

网上查找了下[原因](https://stackoverflow.com/a/15398496)，竟是计算字体宽度的方法使用的不对！在`getTextSize`中应该是`return sTextBounds.left + sTextBounds.width();` 太坑爹。
后来想到字体top和ascent, bottom和descent也是不一样的，是为记……
