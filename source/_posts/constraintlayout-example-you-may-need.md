title: 可能是你最需要的ConstraintLayout示例集锦
date: 2019-06-30 19:10:21
category: Tech
---
以往的关于`ConstraintLayout`的文章都是讲解它的各种属性的用法，到底这些用法和属性怎么达到效果却说不清，只干巴巴说些属性的作用有什么用，希望直接能上手来用，因此以目标为导向，来看看这个控件如何展示它强大的功能!

# 说明
* 有些效果完全可以用嵌套实现，但却不能仅用一个层次的控件实现，所以可以多用`ConstraintLayout`进行视图层次的优化, 最好就是一开始直接用`ConstraintLayout`不用再推到后面
* 都以水平方向作为示例，竖直方向不言自明
* 关注关键属性（代码块中的行没法标红，所以靠悟性了）
* 不对各个属性单独说明了

# 相对父亲居中
![相对父亲居中](https://user-gold-cdn.xitu.io/2019/7/29/16c3e075629a8dd1?w=550&h=126&f=png&s=11686)

```xml
    <TextView
        android:id="@+id/left"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="AAAAA"
        android:textColor="#333"
        android:textSize="30sp"
        android:maxLines="1"
        android:ellipsize="end"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintLeft_toLeftOf="parent"
        app:layout_constraintRight_toRightOf="parent"/>
```
# 相对兄弟居中
A相对B水平居中，注意必须是平级的兄弟视图，其实就是中线对齐中线
![相对兄弟居中](https://user-gold-cdn.xitu.io/2019/7/29/16c3e06ddcf0bc5e?w=552&h=126&f=png&s=13734)

```xml
    <TextView
        android:id="@+id/left"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="AAAAA"
        android:textColor="#333"
        android:textSize="30sp"
        android:maxLines="1"
        android:ellipsize="end"
        app:layout_constraintTop_toTopOf="@+id/right"
        app:layout_constraintBottom_toBottomOf="@+id/right"
        app:layout_constraintLeft_toLeftOf="parent"
        app:layout_constraintRight_toLeftOf="@+id/right"/>

    <TextView
        android:id="@+id/right"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="BBBBBBBBB"
        android:textColor="#999"
        android:textSize="20sp"
        android:layout_marginTop="16dp"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintRight_toRightOf="parent"/>
```

# 中线对齐中线
A的中线与B的中线对齐， 不管AB大小
![中线对齐中线](https://user-gold-cdn.xitu.io/2019/6/30/16ba818d7b8fcce2?w=634&h=144&f=png&s=17042)
```xml
    <TextView
        android:id="@+id/left"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="AAAAAAAAAA"
        android:textSize="30sp"
        app:layout_constraintLeft_toLeftOf="parent"
        app:layout_constraintTop_toTopOf="@+id/right"
        app:layout_constraintBottom_toBottomOf="@+id/right"/>

    <TextView
        android:id="@+id/right"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="BBBBBBB"
        android:textSize="20sp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintRight_toRightOf="parent"
        app:layout_constraintTop_toTopOf="parent" />
```

# 中线对齐边
A的中线与B的上边对齐
![中线对齐边](https://user-gold-cdn.xitu.io/2019/6/30/16ba818d7c3c84e6?w=648&h=152&f=png&s=17014)
```xml
    <TextView
        android:id="@+id/left"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="AAAAAAAAAA"
        android:textSize="30sp"
        app:layout_constraintLeft_toLeftOf="parent"
        app:layout_constraintTop_toTopOf="@+id/right"
        app:layout_constraintBottom_toTopOf="@+id/right"/>

    <TextView
        android:id="@+id/right"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="BBBBBBB"
        android:textSize="20sp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintRight_toRightOf="parent"
        app:layout_constraintTop_toTopOf="parent" />
```

# 边对齐中线
A的上边与B的中线对齐（有时由于锚点的原因不能简单的与上一条相反）
这时我们需要一个辅助View了，然而并不是`android.support.constraint.Guideline`
参看[这篇文章](https://www.tuicool.com/articles/EZBZzmZ)
![边对齐中线](https://user-gold-cdn.xitu.io/2019/6/30/16ba818d7b92463e?w=630&h=132&f=png&s=1480)
```xml
    <TextView
        android:id="@+id/left"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="AAAAAAAAAA"
        android:textColor="#333"
        android:textSize="23sp"
        app:layout_constraintLeft_toLeftOf="parent"
        app:layout_constraintTop_toTopOf="@+id/middle"/>

    <View
        android:id="@+id/middle"
        android:layout_width="match_parent"
        android:layout_height="0.5dp"
        app:layout_constraintRight_toRightOf="@id/right"
        android:visibility="invisible"
        app:layout_constraintTop_toTopOf="@id/right"
        app:layout_constraintBottom_toBottomOf="@id/right"/>

    <TextView
        android:id="@+id/right"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="BBBBBBB"
        android:textColor="#999"
        android:textSize="20sp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintRight_toRightOf="parent"
        app:layout_constraintTop_toTopOf="parent" />
```

# 边占比
A的右边对齐B整体宽度的30%处，不管A，B宽度变化
![边占比](https://user-gold-cdn.xitu.io/2019/6/30/16ba818d7c9edcca?w=636&h=138&f=png&s=16369)
```xml
    <TextView
        android:id="@+id/left"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="AAAAAAAAAA"
        android:textColor="#333"
        android:textSize="30sp"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintRight_toLeftOf="@+id/percent_30"/>

    <View
        android:id="@+id/percent_30"
        android:layout_width="0.5dp"
        android:layout_height="match_parent"
        android:visibility="invisible"
        app:layout_constraintLeft_toLeftOf="@id/right"
        app:layout_constraintRight_toRightOf="@id/right"
        app:layout_constraintHorizontal_bias="0.3"/>

    <TextView
        android:id="@+id/right"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="BBBBBBB"
        android:textColor="#999"
        android:textSize="20sp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintRight_toRightOf="parent"
        app:layout_constraintTop_toTopOf="parent" />
```
# 整体占比
A的整体宽度占在B整体宽度的30%
![整体占比](https://user-gold-cdn.xitu.io/2019/6/30/16ba818d7c6381b2?w=654&h=126&f=png&s=1843)
```xml
    <TextView
        android:id="@+id/left"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        tools:text="AAAAAAAAAA"
        android:textColor="#333"
        android:textSize="30sp"
        android:maxLines="1"
        android:ellipsize="end"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintLeft_toLeftOf="@+id/right"
        app:layout_constraintRight_toLeftOf="@+id/percent_30"/>

    <View
        android:id="@+id/percent_30"
        android:layout_width="0.5dp"
        android:layout_height="match_parent"
        android:visibility="invisible"
        app:layout_constraintLeft_toLeftOf="@id/right"
        app:layout_constraintRight_toRightOf="@id/right"
        app:layout_constraintHorizontal_bias="0.3"/>

    <TextView
        android:id="@+id/right"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="BBBBBBBBBBBBBB"
        android:textColor="#999"
        android:textSize="20sp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintRight_toRightOf="parent"
        app:layout_constraintTop_toTopOf="parent" />
```
# 整体中线占比
A整体始终处于B整体宽度的30%处，不管A宽度如何变化，即A的中线对齐B的水平30%处
![整体中线占比](https://user-gold-cdn.xitu.io/2019/6/30/16ba818d7c855285?w=638&h=152&f=png&s=2957)
```xml
    <TextView
        android:id="@+id/left"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="AAAAAAAAAA"
        android:textColor="#333"
        android:textSize="30sp"
        android:maxLines="1"
        android:ellipsize="end"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintLeft_toLeftOf="@+id/percent_30"
        app:layout_constraintRight_toLeftOf="@+id/percent_30"/>

    <View
        android:id="@+id/percent_30"
        android:layout_width="0.5dp"
        android:layout_height="match_parent"
        android:visibility="invisible"
        app:layout_constraintLeft_toLeftOf="@id/right"
        app:layout_constraintRight_toRightOf="@id/right"
        app:layout_constraintHorizontal_bias="0.3"/>

    <TextView
        android:id="@+id/right"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="BBBBBBBBBBBBBB"
        android:textColor="#999"
        android:textSize="20sp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintRight_toRightOf="parent"
        app:layout_constraintTop_toTopOf="parent" />
```
# 跟随消失
B设置为Gone，A跟随B也为Gone
这时需要用到辅助控件`android.support.constraint.Group`, 同时也不是直接操作B，而且操作`Group`；用`Group`将两个控件绑定，设置`Group`消失时两个一同消失
```xml
    <TextView
        android:id="@+id/left"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="AAAAAAAAAA"
        android:textColor="#333"
        android:textSize="30sp"
        android:maxLines="1"
        android:ellipsize="end"
        app:layout_constraintLeft_toLeftOf="parent"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"/>

    <android.support.constraint.Group
        android:id="@+id/group"
        android:layout_width="0dp"
        android:layout_height="0dp"
        app:constraint_referenced_ids="left,right"/>

    <TextView
        android:id="@+id/right"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="BBBBBBBBB"
        android:textColor="#999"
        android:textSize="20sp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintRight_toRightOf="parent"
        app:layout_constraintTop_toTopOf="parent" />
```
代码处的设置为
```
view.findViewById(R.id.group).setVisibility(View.GONE);
```
# 视图均分
大小各自均分
![视图均分](https://user-gold-cdn.xitu.io/2019/7/29/16c3e10d49b57ef5?w=550&h=122&f=png&s=11269)
```xml
    <TextView
        android:id="@+id/left"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        tools:text="AAAAAAAA"
        android:textColor="#333"
        android:textSize="30sp"
        android:maxLines="1"
        android:ellipsize="end"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintLeft_toLeftOf="parent"
        app:layout_constraintRight_toLeftOf="@+id/middle"/>

    <TextView
        android:id="@+id/middle"
        android:layout_width="0dp"
        android:layout_height="60dp"
        tools:text="C"
        android:textColor="#999"
        android:textSize="20sp"
        android:gravity="center"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintLeft_toRightOf="@+id/left"
        app:layout_constraintRight_toLeftOf="@id/right"/>

    <TextView
        android:id="@+id/right"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        tools:text="BBBBB"
        android:textColor="#999"
        android:textSize="20sp"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintLeft_toRightOf="@+id/middle"
        app:layout_constraintRight_toRightOf="parent"/>
```

# 视图间隔均分
大小各自不固定，相邻间隔均分
![视图间隔均分](https://user-gold-cdn.xitu.io/2019/7/29/16c3e130d281609b?w=546&h=122&f=png&s=9840)
```xml
    <TextView
        android:id="@+id/left"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="AAAAAAAA"
        android:textColor="#333"
        android:textSize="30sp"
        android:maxLines="1"
        android:ellipsize="end"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintLeft_toLeftOf="parent"
        app:layout_constraintRight_toLeftOf="@+id/middle"/>

    <TextView
        android:id="@+id/middle"
        android:layout_width="wrap_content"
        android:layout_height="60dp"
        tools:text="C"
        android:textColor="#999"
        android:textSize="20sp"
        android:gravity="center"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintLeft_toRightOf="@+id/left"
        app:layout_constraintRight_toLeftOf="@id/right"/>

    <TextView
        android:id="@+id/right"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="BBBBB"
        android:textColor="#999"
        android:textSize="20sp"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintLeft_toRightOf="@+id/middle"
        app:layout_constraintRight_toRightOf="parent"/>
```

# 紧靠, 整体居中
AB紧靠，各自宽度不固定，但整体居中
![紧靠, 整体居中](https://user-gold-cdn.xitu.io/2019/7/29/16c3e05b7979910a?w=550&h=122&f=png&s=9318)

单纯这种效果用`LinearLayout`最简单，以下以三个视图相对父亲居中为例:（也可变成相对平级其它视图居中）
![整体水平居中](https://user-gold-cdn.xitu.io/2019/7/29/16c3e04d625bdb0c?w=546&h=128&f=png&s=9087)
```xml
    <TextView
        android:id="@+id/left"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="AAAAAAAAA"
        android:textColor="#333"
        android:textSize="30sp"
        android:maxLines="1"
        android:ellipsize="end"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintLeft_toLeftOf="parent"
        app:layout_constraintRight_toLeftOf="@+id/middle"
        app:layout_constraintHorizontal_chainStyle="packed"/>

    <TextView
        android:id="@+id/middle"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="CCC"
        android:textColor="#999"
        android:textSize="20sp"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintLeft_toRightOf="@+id/left"
        app:layout_constraintRight_toLeftOf="@+id/right"/>

    <TextView
        android:id="@+id/right"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="BBBBBBBBB"
        android:textColor="#999"
        android:textSize="20sp"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintRight_toRightOf="parent"
        app:layout_constraintLeft_toRightOf="@+id/middle"/>
```
# 紧靠, 边居中
AB紧靠，各自宽度不固定，但相邻边居中，以平级其它视图居中为例（也可变成相对父亲居中，相对父亲居中即可用`android.support.constraint.Guideline`）
![紧靠, 边居中](https://user-gold-cdn.xitu.io/2019/7/29/16c3e0446923d01e?w=552&h=124&f=png&s=9602)

`@+id/back_ground`为平级其他视图，用特殊背景色标识。
问题来了：如果是3个视图要如何实现？
```xml
    <View
        android:id="@+id/back_ground"
        android:layout_width="350dp"
        android:layout_height="60dp"
        app:layout_constraintRight_toRightOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"
        android:background="#E6E4E4"/>

    <View
        android:id="@+id/middle"
        android:layout_width="0.5dp"
        android:layout_height="match_parent"
        app:layout_constraintLeft_toLeftOf="@+id/back_ground"
        app:layout_constraintRight_toRightOf="@+id/back_ground"/>

    <TextView
        android:id="@+id/left"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="AAAAAAAA"
        android:textColor="#333"
        android:textSize="30sp"
        android:maxLines="1"
        android:ellipsize="end"
        app:layout_constraintTop_toTopOf="@+id/back_ground"
        app:layout_constraintBottom_toBottomOf="@+id/back_ground"
        app:layout_constraintRight_toLeftOf="@+id/middle"/>

    <TextView
        android:id="@+id/right"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="BBBBB"
        android:textColor="#999"
        android:textSize="20sp"
        app:layout_constraintTop_toTopOf="@+id/back_ground"
        app:layout_constraintBottom_toBottomOf="@+id/back_ground"
        app:layout_constraintLeft_toRightOf="@+id/middle"/>
```

# 紧靠, 动态最大宽度
#### 说明：该效果只能为ConstraintLayout实现!
希望达到以下效果
B紧靠A，各自宽度非固定值，一旦B到达边沿A宽度不能再增长，即A有最大宽度，但其由B决定（和LinearLayout的紧靠效果有点类似但完全不同!）
即：
![AB紧靠](https://user-gold-cdn.xitu.io/2019/6/30/16ba818d998876b6?w=618&h=136&f=png&s=2452)

![AB各自大小不固定紧靠](https://user-gold-cdn.xitu.io/2019/6/30/16ba818d99780f5c?w=618&h=134&f=png&s=3134)

![B自身到达边沿A达到最大宽度](https://user-gold-cdn.xitu.io/2019/6/30/16ba818da63ea10a?w=618&h=142&f=png&s=3283)

![A推B到达边沿A达到最大宽度](https://user-gold-cdn.xitu.io/2019/6/30/16ba818d9ee33d43?w=622&h=144&f=png&s=3327)

这种效果以往任何控件都无法以属性声明的方式实现，除非配合代码，但现在用`ConstraintLayout`了之后，爽了一啤!
展示`ConstraintLayout`强大功能的时候到了，上完整代码
```xml
<android.support.constraint.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <TextView
        android:id="@+id/left"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        tools:text="AAAAAAAAAAAAADDDDDDD"
        android:textColor="#333"
        android:textSize="30sp"
        android:maxLines="1"
        android:ellipsize="end"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintLeft_toLeftOf="parent"
        app:layout_constraintRight_toLeftOf="@+id/right"
        app:layout_constraintHorizontal_chainStyle="packed"
        app:layout_constraintWidth_default="wrap"
        app:layout_constraintHorizontal_bias="0"/>

    <TextView
        android:id="@+id/right"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="BBB"
        android:textColor="#999"
        android:textSize="20sp"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintLeft_toRightOf="@+id/left"
        app:layout_constraintRight_toRightOf="parent"/>
</android.support.constraint.ConstraintLayout>
```
