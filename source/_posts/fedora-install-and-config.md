title: Fedora轻松安装与配置
date: 2016-08-04 12:46:56
category: Tech
---
主要是用来做点记录，长点记性，不然每次都从头开始安装的时候都忘记一些小点，结果把整个过程拖的老长，浪费了不少时间。
# UEFI安装系统
#### 0. 准备工作－设置BIOS
1. 设置启动顺序
不同的机器有不同的BIOS，对应的名称位置都不太一样，需要自己能找到。一般在boot option -> 高级 里面，将从USB启动放在从磁盘驱动前面。
2. 打开UEFI启动开关
有些BIOS需要专门设置UEFI的启动开关，当前所用的HP 430 G3就是这样。
3. 打开虚拟化设置
在Boot Option -> Advanced -> System Option中勾选Virtualization Technology(VTx), 这主要是为了以后方便安装其它工具。
4. 安全启动设置
在Boot Option -> Advanced 在 -> Secure Boot Configuration 中选择legacy enable and secure boot disable， 不然可能引起无线网络的问题。

#### 1. 下载[liveusb-creator](https://mbriza.fedorapeople.org/liveusb-creator.zip)来刻录ISO文件
<font color="#f00"> 一定要用Fedora的专属软件否则无法成功制作启动U盘！</font> 被这个问题坑了很多次， 每次都忘记用...
#### 2. 分区
Fedora自20(?)版本之后都用GPT的磁盘分区格式， 这意味着如果机器要装双系统就没法再装MBR分区的系统比如Win7, 已经装了Win7也没法再装fedora了，但是再装Win8, Win10就没有问题， GPT应该是以后的标准配置，苹果也用的它。
在安装过程中会提示划分挂载点， 这个只要有足够多空余磁盘空间，点击“自动划分”一般没啥问题。

# 安装无线网卡驱动
遇到的一个问题是系统成功安装在HP 430 G3的垃圾机器上却没有区域内的WIFI列表。首先要确定是否是硬件的问题，由于之前的系统装过windows并且能连wifi所以可以确定硬件没有问题。这样的情况一般就是驱动软件没安装合适，可能是镜像文件内的默认驱动没法正常工作。
1. 找到网卡驱动
运行`lspci | grep -i "network"`
2. 安装源内驱动
`dnf search $Verdor` 搜索厂商驱动包再分别安装
3. 安装厂商驱动
遇到的问题是已经安装了Broadcom的驱动还是不能工作，这样就只能从厂商网站上下载正确的Linux驱动安装包。网上搜索到[这篇文章](https://onpub.com/install-broadcom-linux-wi-fi-driver-on-fedora-23-s7-a192)可以了解下，虽然针对23但实际操作没有关系，脚本做了以下4个操作：
1. 下载包
2. 编译并安装包（安装需要root）
3. 删除已有wireless内核模块并安装新模块
4. 写入新配置
重启后终于看到wifi了。

# 启动ssh服务
```
# systemctl stop sshd.service
# systemctl start sshd.service
```

# 安装输入法
1. 安装输入法包比如极点五笔 `dnf install ibus-table-chinese-wubi-jidian.noarch`
2. 运行`ibus-setup` 在配置界面加入新的输入法，没有ibus再安装ibus包
```
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus
```
3. 重启机器后配置好的输入法还是无法显示？
需要加入ibus-daemon到自动重启，每种桌面环境的自动重启配置界面不同， 在Xfce中Applications -> Settings -> Session&Startup, 添加命令`ibus-daemon -d`
可是有时系统重启以后明明已经有输入法的图标在任务栏上显示，可是就是无法输入汉字，再重启后又可以使用了，不知道啥原因...

# 安装Docker
所有操作都需要root权限, $USER对应的是当前普通用户
```
dnf install docker
systemctl start docker
systemctl enable docker
groupadd docker
chown root:docker /var/run/docker.sock
usermod -a -G docker $USER
```
重启机器，这样就能够以普通用户执行docker操作了。
#### docker加载本地存储卷错误
`docker run -v /path/to/volume:/path/to/dest`之前需要执行
`chcon -Rt svirt_sandbox_file_t /path/to/volume`

# 安装Android32位兼容包
`dnf install glibc.i686 zlib.i686 libgcc.i686`

# 运行samba
`smbclient -N //10.140.60.128/<share_name>`
share_name一定要是服务器上根目录，不能带路径

# 安装quart
```
dnf install redhat-rpm-config Cython python2-devel
```
# 安装VirtualBox
```
dnf install kernel-devel dkms kernel-headers
/sbin/rcvboxdrv setup
```
下载[VM VirtualBox Extension Pack](https://www.virtualbox.org/wiki/Downloads)
# 安装Bochs
```
dnf install bochs bochs-debugger
```

# 编译Bochs
```
dnf install libX11-devel libXrandr-devel
```

# 升级
[fedoraproject](https://docs.fedoraproject.org/en-US/quick-docs/dnf-system-upgrade/)
```
dnf upgrade --refresh
dnf install dnf-plugin-system-upgrade
rpmkeys --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-34-x86_64
dnf system-upgrade download --releasever=34
dnf system-upgrade reboot
```

# 升级后
[fedoramagazine](https://fedoramagazine.org/upgrading-fedora-30-to-fedora-31/)

```
dnf copr enable librehat/shadowsocks
dnf update && dnf install shadowsocks-libev
```
Fedora 34:
```
snap install shadowsocks
shadowsocks.sslocal -c shadowsock.json -d start
```
