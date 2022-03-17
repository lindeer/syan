title: 怎么又制作起电子书？
date: 2021-12-08 16:49:13
category: Life
---

突然之间，自己的雄心壮志又膨胀了起来。因为发觉还要了解更多前提性的历史知识，所以觉得有必要再看看其他一些德国历史书。正好在特丽菲丝的微博里看到《德意志史》，于是在网上又疯狂搜索了一阵。同时也找到了她和史海一直推荐的《德意志皇帝史 卷一》。这2本书都是pdf，《皇帝史》都是16年出的书，到现在也没有电子版，而且文件很大下载都要很长时间；而一旦买实体书，没办法做到随时随地打开就看，更希望是随时能看那种，而且《德意志史》二手书都卖到好几百，我只想看中世纪特别是霍亨斯陶芬时期的内容，感觉划不来。于是把他们全部电子化的想法立刻涌上心头。正好可以把它们以gitbook的形式托管在gitlab上，随时随地可以打开看，爽歪歪。

说干就干。这2个pdf都是扫描件不是可以拷贝文本的那种，那这种电子化最好的办法当然是ocr了，试了几个在线ocr的工具，或者不支持pdf，或者转成文本的质量很差，对比了一下还是扫描全能王是当中最准确的。但扫描全能王不是在线的，也不能将整本pdf直接转化，只能一页一页的手动处理。我只得用它附带的pdf工具把pdf转成它所谓的“文档”，再将“文档”切换成“word”，再将“word”中的文本拷贝。（因为直接提取文本要收费，通过“文档”切换成“word”也能达到转化文本的效果）然而这个过程还没有完，全能王是个手机app，我还需要把文本传到电脑上才方便编辑和操作，于是得利用起IM软件把文本传输到电脑端。其间因为全能王需要的存储空间过大，让一直使用的P20手机的空间不足了。我不得不换另外一台手机（正好新买了手机），但安装上最新的全能王之后发现居然强迫用户登录！这些狗屎一样的玩艺！于是重新安装了原手机对应版本的全能王app，这条通路才完整起来。

但是在手机上转化文本，再传送到电脑这个过程实在太过低效了，还是必须在电脑端直接转化文本才能提高效率。后来发现原来全能王有网页版，看来是上线没多久，因为还在提示试用。要使用的话必须注册登录，只要真的好用，把自己的手机号或者隐私泄漏给你们也值了！然而登录后还有问题，免费空间只有200M，pdf转的文档轻易的就把这点空间占满了！手机上的app则没有这个限制，结果就是一边转化，一边把不再使用的文档删除。如果一开始把整个pdf上传到网页，后面三，四百页的内容没办法显示到网页上，最后就是在app里导入pdf，利用账户同步功能让网页显示出最开始的一百多页，当我在电脑端操作完这些文档的时候，再在手机端把这一百多页文档删除，账户同步功能再把后面一百多页显示到电脑端，这样完成整部书的文本转化功能。更加操蛋的是，上周六的时候，网页端转化文本只能操作100页了，而我在周一周二操作的时候还没有这个限制！

电脑端拷贝出文本之后，它的段落格式都是不对的，我需要把分散的段落粘连起来，把对应的注释标记出来，并单独处理到文章的末尾，虽然都可以用正则或者sublime批量处理，但因为需要重复处理六百多页，反而是工作量最大的部分了。

今天当我跌跌撞撞完成了[《皇帝史》](https://mittelalter.gitlab.io/geschichte-der-deutschen-kaiserzeit)的电子化后，突然又陷入空虚当中：我花了这么多时间与精力究竟是为了什么呢……想当初，我只是想着能够方便的随时阅读，并且还抱着知识共享的热情——也许有人想像我一样看到这些呢？我们的很多内容都隐藏在浩如烟海的各种书籍当中的，是无法在网上方便的检索出来的，也许我做的这些内容有可能有一天出现在别人的搜索结果当中呢？现在我想，如果一个人真想了解还是自买书去吧，就算不知道要买什么书，也不能期望别人去无偿劳作把需要了解的东西免费展示在网上。也许我应该花点小钱，珍惜一下自己的时间与精力……

我只能从自己找到意义。就像我在翻译过程中不知道某个词应该翻译成什么，我在阅读这些作品的过程中，应当整理出术语，找到对应的中文表达，这些是我自己能够沉淀和积累的。当然我还得找到原文进行比照（这又是一项艰苦的工作）。感到空虚也许是对的，人也不能仅凭一腔热情就做自己认为有意义的事，虽然做一做似乎是释放天性的一种好的方式，但是必须得有判断和取舍了。

我又想到很多年前看到一个外国人自己将汉字演变的过程全部电子化，展示在互联网上的事。那时觉得为什么我们中国人自己却没有人做这样有重大意义的事情，自己对身边经常使用的东西熟视无睹？！我今天做的应当是个起步，是个开始。假如有一天，出版社出了《皇帝史》的电子书，我耗费三周做的事会立马作废，我不应该懊悔。


就这样，我本来想了解更多康拉丁的事迹，却搞起了翻译，翻译过程中却又看起了腓特烈二世，接着发现还得再看看霍亨斯陶芬的历史，又发现还得再看看整个德国古代历史，最后又开始搞起了书籍电子化，当然，翻译也随之暂停……