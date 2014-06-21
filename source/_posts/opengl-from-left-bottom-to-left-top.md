title: OpenGL的左下坐标原点转成窗口系统的左上坐标
date: 2014-06-21 11:42:22
category: Tech
---
想当然的写成`gluOrtho2D(0, width, height, 0);` 但这是不对的。验证的方法是，只要画四条直线, width, height分别是窗口宽高：
```c
glBegin(GL_LINE_LOOP);
    glColor3ub(0xFF, 0, 0);
    glVertex2i(0, 0);
    glVertex2i(width, 0);
    glVertex2i(width, height);
    glVertex2i(0, height);
glEnd();
```
应该只有左上两条直线能显示才对。但结果是右下两条显示了出来,把width+1, 则右边线条去掉了，所以整体的显示结果是向期望的向左上偏移了一个像素。
调整成这样才是正确的：
```c
gluOrtho2D(-1, width - 1, height - 1, -1);
```
显然`gluOrtho2D`对于整数的取值区间是`(m, n]`。

程序在这种情况下真正做到了精确至像素，一个像素的错误（不是误差）让结果产生重大影响。真正的精确到像素只有可能是实在的数据运算而不是感觉和观察，不知设计湿看了作何想。
