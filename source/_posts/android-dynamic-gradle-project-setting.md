title: Android动态改变工程依赖
date: 2019-06-11 22:02:32
category: Tech
---
在`app/build.gradle`有如下库依赖:
```groovy
dependencies {
    compile "com.xxx.yyy:somelib:$version"
}
```
现在如果要改成源码依赖(工程依赖)需要改2处地方:
`app/build.gradle`:
```groovy
dependencies {
    compile project(':somelib')
}
```
`settings.gradle`:
```
include ':somelib'
project(":somelib").projectDir = new File("/lib/dir", "/some/path/somelib")
```
现在依赖的库非常多, 而且还存在依赖嵌套, 希望**只改一处配置就能够切换库依赖与源码依赖**

显然用库依赖`settings.gradle`里不需要`include`那坨语句, 那么必然需要在`settings.gradle`里定义一个变量来作条件判断, 这里需要解决的一个核心问题是`app/build.gradle`能够访问到`settings.gradle`里的这个变量来继续来作`compile "com.xxx.yyy:somelib:$version"`还是`compile project(':somelib')`的判断, 也就是需要一个***全局可访问的gradle变量***

网上搜索了一圈竟然没找到!

研究了一下发现以下重要2点:
1. `settings.gradle`对象生成早于`app/build.gradle`甚至早于根目录的`build.gradle`, 所以在build.gradle里声明`ext { someVar=xxx }`变量无效, settings无法访问
2. `app/build.gradle`上下文依赖的`project`对象与`settings.gradle`共享同一个gradle对象

于是有如下配置:
`settings.gradle`:
```groovy
def module_config = [
    'somelib': '',
    'aaa': '1.0.0',
    'bbb': '0.2.0',
    'ccc': '0.0.3',
]
module_config.each { k, v ->
    if (!v) {
        include ":${k}"
        project(":${k}").projectDir = new File(rootDir.getParent(), "/some/path/${k}")
    }
}
gradle.ext.dependon = { project, name ->
    def ver = module_config[name]
    def handler = project.dependencies
    if (!ver) {
        handler.compile project.project(":$name")
    } else {
        handler.compile "com.xxx.yyy:$name:$ver"
    }
}
```
这里用`gradle.ext`定义了一个全局的方法而不是一个变量, 这样在引用的时候直接调用:
`app/build.gradle`:
```groovy
dependencies {
    gradle.ext.dependon(this, "somelib")
    gradle.ext.dependon(this, "aaa")
    gradle.ext.dependon(this, "ccc")
}
```
这样我们只需更改`module_config`中对应模块的版本就可以实现一动态改变工程依赖的功能了!

注意`gradle.ext.dependon`传入的是`org.gradle.apiProject`对象, 而project.dependencies是`org.gradle.api.artifacts.dsl.DependencyHandler`对象, 分别是gradle配置类

最根本最重要最核心的其实是`gradle.ext`这个全局可访问变量, 只要有了它完全可以用任何方式实现.
