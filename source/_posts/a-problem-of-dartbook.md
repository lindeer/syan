title: dartbook遇到的问题
date: 2022-07-10 09:00:27
category: Tech
---

实现dartbook立即遇到了很大的挑战：dart竟然没有解析`nunjucks`模板的库！pub中支持的模板语言有，`liquid`的解析库[liquid_engine](https://pub.flutter-io.cn/packages/liquid_engine)和`jinja`的解析库[jinja](https://pub.flutter-io.cn/packages/jinja)。实现一个`nunjucks`的解析库感觉也非常不现实。现在已经到了页面生成阶段，我需要把markdown转化成的html文本填充进不同类型的html模板文件中，而gitbook所用的模板语言是`nunjucks`。看起来`nunjucks`挺完备，还有继承语法，但没有在`liquid`看到，要继续进行有2个途径：

1. 实现一个`nunjucks`解析库

    显然这个方案几乎不可能。
2. 把已有的`nunjucks`模板文件转成`liquid`的文件

    因为没有解析库，只能手动转，所幸的是一共只有6个文件；然而另一个问题是我和了解2种模板语法及其差别，这很繁琐，但不得不这么做。

想到这里马上没有继续进行这个项目的动力……坚持，再坚持一下……

17:29
---
花了不少时间熟悉了一下`jinja`,发现和`nunjucks`非常像，几乎可以无缝集成。用`jinja`的时候，`template.renderMap()`需要显式的传`Map<String, dynamic>`类型，否则就会抛出类型转换错误，花了好长时间发现自己的类型没有显式声明，真是太讨厌了。

7.11
---
当前的jinja版本0.3.4不支持宏，无法解析`summary.html`

7.12
---
今天看了一下`markdown-it`中关于footnotes的实现[markdown-it-footnote](https://github.com/markdown-it/markdown-it-footnote/blob/master/index.js)，看起来逻辑似乎不是特别麻烦，这让我对对dart官方的markdown库提交源码有了信心！官方库是用正则表达式进行匹配，所以下午试了好长时间的正则匹配，似乎这个正则就可以很好的满足我的需要:`r'\[\^\S+\]:?'`。

但是现在最关键的还不是markdown的实现，而是模板库的宏功能。看jinjia库一时半会应该还无法实现这个功能，今天刚好查到可以用模板语法中的`with`语句进行替代，于是赶紧验证了一下。然而0.3.4版本并不支持这个语法，于是换成0.4.0-dev.31，但是折腾了半天，运行报错。不确定是用法的问题还是库的bug，一整天就这么过去了。

7.14 22:28
