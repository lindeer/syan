title: 'flutter: 彻底解决Wrong full snapshot version问题'
date: 2019-06-22 18:03:53
category: Tech
---
环境: flutter-sdk(v1.5.4-hotfix.1@stable)

运行flutter脚本的时候有时会遇见`Wrong full snapshot version, expected '…' found '…'`的错误, 其实这时候是因为在`${FLUTTER_ROOT}/bin/cache`里缓存的快照过期或者无效了导致的.

网上有把`${FLUTTER_ROOT}/bin/cache`目录删除了的, 有用`git clean -xfd`[命令解决的](https://juejin.im/post/5cedf49af265da1bab299027), 其实还是删除了`${FLUTTER_ROOT}/bin/cache`目录, 这样的做法不太好, fluter脚本会重新下载dartSDK等一系列工具,整个过程会持续很长时间.

`${FLUTTER_ROOT}/bin/cache`有8个标识用的时间戳
bin/cache/android-sdk.stamp
bin/cache/flutter_sdk.stamp
bin/cache/flutter_version_check.stamp
bin/cache/ios-sdk.stamp
bin/cache/engine-dart-sdk.stamp
bin/cache/flutter_tools.stamp
bin/cache/gradle_wrapper.stamp
bin/cache/material_fonts.stamp
其中`android-sdk.stamp,flutter_sdk.stamp,os-sdk.stamp,engine-dart-sdk.stamp`一般内容一致, 是`${FLUTTER_ROOT}/bin/internal/engine.version`中的字串, 相对来说sdk中的内容我们一般不会变更, 如果这几个stamp文件内空不一样改成一致即可.

最容易出问题的其实是`flutter_tools.stamp`, 我们有时在`${FLUTTER_ROOT}/packages/flutter_tools/lib`
中的文件添加了一些log, 结果运行时内容打印不出来, 这时只要删除`flutter_tools.stamp`即可, flutter脚本(`${FLUTTER_ROOT}/bin/flutter`)会自行生成stamp并重建snapshot(`${FLUTTER_ROOT}/bin/cache/flutter_tools.snapshot`), 而dart最终运行的是snapshot文件.

所以一般情况下删除`flutter_tools.stamp`即可解决问题

另外如果想让`${FLUTTER_ROOT}/packages/flutter_tools/lib`里更改的内容实时生效, 将`${FLUTTER_ROOT}/bin/flutter`中引用的`$SNAPSHOT_PATH`改成`$SCRIPT_PATH`就可以实时查看dart脚本怎样同步工程, 怎样诊断环境等等所有事情:
![](https://upload-images.jianshu.io/upload_images/19161-87db51a1cbe54ff0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

这意味着**一旦脚本运行出现难懂的错误,我们就可以很容易的定位问题了**!
