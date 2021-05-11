title: TextView多行文本Ellipsize的终极解决方案
date: 2017-11-07 09:24:41
category: Tech
---
Android的TextView提供了ellipse的功能，就是在文本超过指定行数maxLine后增加`...`，然而当`setText`传入是spannable类型的时候，这个功能无法生效。spannable中会包含不少信息，图片，下划线等等，给解决这个问题又增加了不少难度。微信朋友圈的"全文/收起"根本没加`...`。网上有很多人试图解决这个问题，有重写类的，例如 https://stackoverflow.com/a/6763689, 有添加布局监听的，如 https://stackoverflow.com/a/30446822， 但实践下来没一个好用的！只好自己想法。

自己从头写文本布局是绝无可能的，TextView自己的代码就有几千行，更不要说StaticLayout, DynamicLayout工具类了，有些人提到`TextUtils.ellipsize`这个方法，但它只是应用在单行情况。于是想到多行文本是由单行组成，让`TextUtils.ellipsize`测量指定行数次，只在最后一次给出实际测量宽度不就可以了，根据源码写出:
```java
//给定字符串和行数，返回缩略在字符串中的起始位置
  private static int ellipsize(TextPaint tp, CharSequence cs, int line, int lineWidth) {
    final int range[] = {0, cs.length(), 0};
    int row = 0;
    TextUtils.EllipsizeCallback cb = new TextUtils.EllipsizeCallback() {
      @Override
      public void ellipsized(int start, int end) {
        range[0] = start;  // 单行文本缩略起始
        range[1] = end;    // 单行文本缩略结束
        range[2] += start; // 整个文本缩略位置
      }
    };
    float ellipsisWidth = tp.measureText(ELLIPSIS_STRING);
    CharSequence remain = cs.subSequence(range[0], cs.length());
    // 计算每行容纳的文本子串
    while (range[0] < range[1] && row < line) {
      float actualWidth = lineWidth + (row == line - 1 ? 0 : ellipsisWidth);
      remain = remain.subSequence(range[0], remain.length());
      TextUtils.ellipsize(cs.subSequence(range[2], cs.length()),
          tp, actualWidth, TextUtils.TruncateAt.END, false, cb);
      row++;
    }
    return range[0] < range[1] ? range[2] : -1;
  }
```
试验了一下居然很好用，无论是String还是Spannable都可以显示`...`了！然而问题马上来了，当文本中有连续英文字符时，显示有问题！发现验证的几个示例都是中文，换成英文就容易出问题。于是查原因，发现是因为断行，如果有"jisdfls"在行尾的时候需要在`d`这个字符处需要折行，虽然它不是合法的英文单词，但是布局会把整个单词都作为下一行的行首，这样之前的方法整个就错误了，因为这个方法根本没有折行的判断逻辑，而折行的判断逻辑很复杂！于是看StaticLayout这个负责文本布局的类，看能不能抽取些方法单独使用，然而这几乎是不可能的。StaticLayout中断行用了不少非开放的类比如`MeasuredText`，而这些类在不同的API实现还不一样！

#最终
但是办法还是想出来了，就是结合StaticLayout和TextUtils.ellipsize，由StaticLayout负责断行，在指定行数由TextUtils.ellipsize负责判断`...`的起始位置，避免各种实际的CharSequence类型的处理，这样这个问题终于圆满解决了:
```java
private static int ellipsize(TextPaint tp, CharSequence cs, int line, int lineWidth) {
  StaticLayout layout = new StaticLayout(cs, tp, lineWidth, Alignment.ALIGN_NORMAL,
      1.0f, 0.0f, true);
  int count = layout.getLineCount();
  int pos = -1;

  if (count > line) {
    int start = layout.getLineStart(line - 1);
    final int range[] = {0};
    TextUtils.ellipsize(cs.subSequence(start, cs.length()), tp, lineWidth,
        TextUtils.TruncateAt.END, false, new TextUtils.EllipsizeCallback() {
          @Override
          public void ellipsized(int start, int end) {
            range[0] = start;  // 单行文本缩略起始
          }
        });
    pos = start + range[0];
  }
  return pos;
}
```
整个方法相比原有的操作相当于多了一次布局，然而实现简单轻量，甚至带着几分优雅～
#怎样显示在TextView中
首先指定宽度从哪来，View在刚inflate出来后是完全没有宽度的，而GlobalLayoutListener会被多次调用，所以方法只能写在onMeasure中，并且有了onMeasure就可以获取TextPait。知道了缩略起始位置就可以把原始字符串中该位置以后的内容替换成`...`, 再setText().
