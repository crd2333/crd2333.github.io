# 1. Linux 系统学习
## 1.1. Linux 文件与目录管理
### 1.1.1. Linux 文件权限与目录配置
- `/usr` 不是 user 的缩写，而是 unix software resources 的缩写
- LINUX 的 root 用户和普通用户
  - 之前 wsl 里两个密码设置成了一样，就没体会到 sudo 和 su 的区别
    - 用 `passwd [用户名]` 更改密码

### 1.1.2. 文件系统与挂载
- 文件系统
  - `/mnt` 用于挂载设备，当然也可以挂在其他地方，但建议这里
  - `/opt` 第三方软件常存储于此
- List Block
  - `lsblk` 显示设备信息
  - `df -h` 磁盘使用情况
  - 用 root 权限 `# mount /dev/sda1 /mnt/<文件系统名>`，同理 `unmount`
  - 也可以通过网络挂载

### 1.1.3. /bin, /sbin, /usr/sbin, /usr/bin 目录
- **/bin** 是系统的一些指令。bin 为 binary 的简写，主要放置一些系统的必备执行档。例如:cat、cp、chmod df、dmesg、gzip、kill、ls、mkdir、more、mount、rm、su、tar 等
- **/sbin** 一般是指超级用户指令。主要放置一些系统管理的必备程式。例如:cfdisk、dhcpcd、dump、e2fsck、fdisk、halt、ifconfig、ifup、ifdown、init、insmod、lilo、lsmod、mke2fs、modprobe、quotacheck、reboot、rmmod、runlevel、shutdown 等
- **/usr/bin** 是你在后期安装的一些软件的运行脚本。主要放置一些应用软体工具的必备执行档。例如 c++、g++、gcc、chdrv、diff、dig、du、eject、elm、free、gnome*、 gzip、htpasswd、kfm、ktop、last、less、locale、m4、make、man、mcopy、ncftp、 newaliases、nslookup passwd、quota、smb*、wget 等
- **/usr/sbin** 放置一些用户安装的系统管理的必备程式。例如:dhcpd、httpd、imap、inetd、lpd、named、netconfig、nmbd、samba、sendmail、squid、swap、tcpd、tcpdump 等

### 1.1.4. Linux 文件权限
- 我的有些文件夹发绿，很丑，我一开始以为是主题的原因
  - 实际上是因为其他组权限里面有写入的权限，**linux 系统认为这是一个高风险的目录文件，因为任何人都可以进入到该目录并进行写入操作**，所以就将该目录用绿色高亮显示，警示用户这个文件存在可能被恶意写入的风险。
- chmod 权限设置
  -  -rw------- (600)      只有拥有者有读写权限。
  - -rw-r--r-- (644)      只有拥有者有读写权限；而属组用户和其他用户只有读权限。
  - -rwx------ (700)     只有拥有者有读、写、执行权限。
  - -rwxr-xr-x (755)    拥有者有读、写、执行权限；而属组用户和其他用户只有读、执行权限。
  - -rwx--x--x (711)    拥有者有读、写、执行权限；而属组用户和其他用户只有执行权限。
  - -rw-rw-rw- (666)   所有用户都有文件读、写权限。
  - -rwxrwxrwx (777)  所有用户都有读、写、执行权限。

### 1.1.5. Linux 查看文件（夹）大小
- 直接用 ls 貌似没法查看文件夹的大小，文件好像是可以的，但是文件夹会显示 4.0K，意思是文件夹本身的大小？
- 用命令 `du -sh <direcory_name>` 查看文件夹总大小，其中删去 `-s` 参数则是分开展示

### 1.1.6. linux 以树形展示目录结构
- 下载软件 tree：`sudo apt-get install tree`
- `tree -L N` 以当前目录为起点展示 N 层

### 1.1.7. linux 下的解压与压缩 (tar)
- [Linux 下的 tar 压缩解压缩命令详解 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/34841993)
- 基本上，压缩和解压缩就这样用就好了
  - `tar -zcf xxx.tar xxx` 压缩
  - `tar -zxf xxx.tar` 解压缩

## 1.2. Linux 下查找文件
- find, grep, which, whereis, locate

!!! note
    1. find 命令是根据文件的属性进行查找，如文件名，文件大小，所有者，所属组，是否为空，访问时间，修改时间等。
    2. grep 是根据文件的内容进行查找，会对文件的每一行按照给定的模式 (patter) 进行匹配查找。
    3. which 查看可执行文件的位置，只有设置了环境变量的程序才可以用
    4. whereis 寻找特定文件，只能用于查找二进制文件、源代码文件和 man 手册页
    5. locate 配合数据库查看文件位置 ,详情：`locate -h` 查看帮助信息
    - 最常用的还是 find 和 grep
### 1.2.1. find
- 语法：**find** **【路径】 【选项】 【表达式】 【描述】**
- 按照**文件名**查找 `find [directory] -name [filename]`
- 按照**文件特征**查找，直接举例子

!!! example
    1. `find / -amin -10` 查找在系统中最后 10 分钟访问的文件 (access time)
    2. `find / -atime -2` 查找在系统中最后 48 小时访问的文件
    3. `find / -mmin -5` 查找在系统中最后 5 分钟里修改过的文件 (modify time)
    4. `find / -mtime -1` 查找在系统中最后 24 小时里修改过的文件
    5. `find / -empty` 查找在系统中为空的文件或者文件夹
    6. `find / -group cat` 查找在系统中属于 group 为 cat 的文件
    7. `find / -user fred` 查找在系统中属于 fred 这个用户的文件
    8. `find /etc -type l` 查找 /etc 下文件类型为链接文件（l）的文件
    9. `find / -size +10000c` 查找出大于 10000 字节的文件
       - `c`:字节，`w`:双字，`k`:KB，`M`:MB，`G`:GB
       - `+` 大于；`-` 小于
    10. `find / -size -1000k` 查找出小于 1000KB 的文件
    11. `find / -perm 644` 查找所有权限为 644 的文件，这里 `-perm` 是精确权限的意思

- **混合**查找，参数有：!, -and(-a), -or(-o)

!!! example
    1. `find /tmp -size +10000c -and -mtime +2` 在 /tmp 目录下查找大于 10000 字节并在最后 2 分钟内修改的文件
    2. `find / -user fred -or -user george` 在 / 目录下查找用户是 fred 或者 george 的文件文件
    3. `find /tmp ! -user panda` 在 /tmp 目录中查找所有不属于 panda 用户的文件

- 查找到文件后对其进行**处理**

!!! example
    `find . -perm 714 -delete` 查找当前目录下权限为 714 的文件删除
    `find / -perm 714 -ls` 查找所有文件权限为 714 的文件并显示路径

### 1.2.2. grep
- 语法：**grep 【options】 【pattern】 【files】**

!!! abstract
    title: 常用选项
    - `-i`：忽略大小写进行匹配。
    - `-v`：反向查找，只打印不匹配的行。
    - `-n`：显示匹配行的行号。
    - `-r`：递归查找子目录中的文件。
    - `-l`：只打印匹配的文件名。
    - `-c`：只打印匹配的行数。

!!! example
    `grep -n '2019-10-24 00:01:11' *.log` 查找日志中特定时间并显示行数
    `grep –i "error" out.txt` 不区分大小写，查找错误信息
    `grep –e "正则表达式" test` 从文件内容查找与正则表达式匹配的行


## 1.3. 进程
- `ps` 显示进程的各个参数，常搭配 `grep` 使用
- `htop` 可交互、实时动态地查看工具
- `kill` 杀死进程


## 1.4. 终端
### 1.4.1. Shell 知识
#### 1.4.1.1. 快捷键
!!! ad-info
    `Ctrl +A`   跳转到行首
    `Ctrl +E`   跳转到行尾
    `Alt + B（<-）`   跳转到前一个单词的开头
    `Alt + F（->）`   跳转到下一个单词的开头
    `Ctrl + U`   剪切到行首
    `Ctrl + K`   剪切到行尾
    `Ctrl + W`   剪切到前一个单词
    `Ctrl + P`   恢复到前一个键入的命令
    `Ctrl + R`   查找过往命令
    `Ctrl + Y`   粘贴缓冲区内容（即前面剪切的），注意这里跟 `Ctrl + C/V` 不是一套体系

#### 1.4.1.2. Head & Tail
- 用于打印文件首尾内容
- `head -n <number> <filename>` 打印文件的前 n 行
  - 如果不指定 `-n`，默认是 10
  - 也可以将 `-n` 改为 `-c`，意思是以字节计数
- `tail -n <number> <filename>` 打印文件的后 n 行
  - 如果不指定 `-n`，默认是 10
  - 也可以将 `-n` 改为 `-c`，意思是以字节计数
  - 比 head 多一些参数，比如 `-f`，在打印完已有内容后会阻塞，等待目标文件更新
#### 1.4.1.3. 重定向
- 标准输入（出）流重定向，`< << > >>` stdin 与 stdout 的覆写与追加
- 标准错误流重定向，`2> 2>>`
- 合并，`<& >&`（没懂）
- 管道符，`|`，从命令重定向到命令

#### 1.4.1.4. exec 命令
- 顾名思义，execute，执行命令
- 可以看看这篇文章：[在 Shell 脚本中使用 `exec` 命令的方法和用途_exec 命令_wljslmz 的博客-CSDN 博客](https://blog.csdn.net/weixin_43025343/article/details/130951691)
- 学到了一种把命令作为字符串然后执行的方法，在这里配合 exec 的话可以这样 `exec command -c 'command'`

### 1.4.2. bash, sh, source, . 的不同
- 这也是关于部分 `.sh` 文件运行报错问题
- 一些 `.sh` 文件内的内容手动执行是正常的，`bash <name>.sh` 执行也是正常的，唯独 sh 会报错，即使在内部设置了 `#!/bin/bash` 也一样
- 这是因为 ubuntu 和 debian 系中 sh 被软连接到了 dash，可以用 `ls -al /bin/sh` 来验证
- 如果要重新软连接回 bash 的话见 [linux 总结 02-关于 ubuntu 中 sh 执行 shell 脚本报错问题_dylloveyou 的博客-CSDN 博客](https://blog.csdn.net/dylloveyou/article/details/53393906)
- 至于为什么：
    > Speed and POSIX compliance (in other words, portability) are the main factors.
- For more:
  - 除了上述两种方法外（都是新开终端执行），还有 `source` 和 `.` 的执行方法，其不同之处可参考：[详解 shell 中 source、sh、bash、./执行脚本的区别 - 随风听雨 - 博客园 (cnblogs.com)](https://www.cnblogs.com/lxsjl/p/9304947.html)

### 1.4.3. Shell 选择 —— Zsh 和 Bash
- [（Manjaro）zsh 终端和 bash 共存时的环境变量配置 - fay 小站 (laoluoli.cn)](http://www.laoluoli.cn/2022/01/10/%ef%bc%88manjaro%ef%bc%89zsh%e7%bb%88%e7%ab%af%e5%92%8cbash%e5%85%b1%e5%ad%98%e6%97%b6%e7%9a%84%e7%8e%af%e5%a2%83%e5%8f%98%e9%87%8f%e9%85%8d%e7%bd%ae/)
- [.zprofile, .zshrc 和.zshenv 之间的区别 - 掘金 (juejin.cn)](https://juejin.cn/post/7128574050406367269)
- [Linux 的环境变量.bash_profile .bashrc profile 文件 - lvmenghui001 - 博客园 (cnblogs.com)](https://www.cnblogs.com/lmh001/p/9999859.html)
- [Zsh 自动补全脚本入门 | 楚权的世界 (chuquan.me)](http://chuquan.me/2020/10/02/zsh-completion-tutorial/)    不太懂
- [用 zsh 提高生产力的 5 个技巧 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/45457383)
- pipdeptree -p <包名>  可以查看包的依赖关系

### 1.4.4. zsh 的使用
- 命令提示和补全是两个完全不同的系统！很多时候提示比补全更有用
  - 如果你觉得它提示的正确，你可以 CTRL+F 表示采纳
- d：跳转最近历史目录
  - 用 `cd -`  可以跳转回到之前的路径，但这只有单次记忆
  - `d` 命令会列出我们最近进入的目录历史，再输入序号即可快速跳转
- z：记忆你曾经进入过的目录，模糊匹配快速进入你想要的目录
  - 插件 'z' 的功能，自带但需要开启
    - 其实不只是 zsh 能用，它就只是一个 .sh 脚本，别的 shell 装了也能用
  - `z` ：列出自开始用 zsh 进入过的目录和它们的权重，进入次数越多，权重越大
  - `z [key]` ：跳转到所有匹配关键字的历史路径中权重最高的那个
    - 按 `tab` 后回车，确认再跳转
  - `z -l key` ：列出包含关键词的所有历史路径及其权重
    - 关键词可以有多个，使用空格间隔： `z -l [key1] [key2] ...` 会先匹配第一个，再匹配第二个，直到最后锁定
- zsh-incr :命令动态提示和自动增量补全
  - incr 插件本身不依赖于 oh-my-zsh 框架，只需要原始的 zsh(zshell) 就可以驱动该插件
  - 可能会卡，所以不设置成自启动（笑死，直接禁用）
  - 用 `source ~/.oh-my-zsh/custom/plugins/incr/incr*.zsh` 开启
- 快捷操作
  - `bindkey -s '\eo'   'cd ..\n'`     按下 ALT+O：cd ..
  - `bindkey -s '\el'   'ls\n'`     按下 ALT+L：ls（默认自带）
  - `bindkey -s '\e;'   'ls -l\n'`     按下 ALT+；：ls -l
  - `bindkey '\e[1;3D' backward-word`       ALT+ 左键：向后跳一个单词
  - `bindkey '\e[1;3C' forward-word`        ALT+ 右键：前跳一个单词
  - `bindkey '\e[1;3A' beginning-of-line`   ALT+ 上键：跳至行首
  - `bindkey '\e[1;3B' end-of-line`   ALT+ 下键：跳至行尾

### 1.4.5. Z-Shell ys 主题的修改及与 conda 的适配
- 通过 `conda config --set auto_activate_base true` 默认每次打开 wsl 都启动 conda activate
- 首先通过 `conda config --set changeps1 False` 取消掉默认的 conda 环境显示
- 然后修改 ys 主题配置，参考了 [myys.zsh-theme/myys_v2.zsh-theme at master · zhiweichen0012/myys.zsh-theme (github.com)](https://github.com/zhiweichen0012/myys.zsh-theme/blob/master/myys_v2.zsh-theme)
  - 或者 [修改 oh-my-zsh 主题使其正确显示 Conda 环境信息 - Glowming - 博客园 (cnblogs.com)](https://www.cnblogs.com/glowming/p/display-conda-env-name-in-zsh.html)
  - 其实就只是加了 conda 信息的获取和一行 `%{$fg[magenta]%}${conda_info}\`
- 有个缺点，那就是当我 `conda deactivate` 后，按理来说应该回到我安装 anaconda 之前的 python 版本 (?) 然而问题是，我这样之后 `which pip` 返回的还是 base 的 python。GPT 说 `conda deactivate` 后就是 base，和文心一言的答复出现了矛盾。
  - 问题在于，如果我 deactivate 后是默认的 python 而不是 base，那我这里的显示就出问题了。我只能说我以后尽量不退出 base 环境，只在 base 和其他环境之间切换，以免出现显示问题

### 1.4.6. Zsh 和 Bash 的切换
- 首先使用 `echo $0` 查看当前 shell
- 然后用 `chsh -s /bin/bash`  和 `chsh -s /bin/zsh` 进行默认 shell 的切换（下次登录时生效），密码注意输当前用户的密码而不都是 root 的密码
- 如果不是切换默认而只是临时切换的话，其实直接输入 `bash` 或 `zsh` 即可
  - 配合 `exec` 达到更复杂的效果
  - 如果不希望终端嵌套的话，就用 `exec bash` 来切换 bash，或者使用脚本来起一个子 shell 运行任务

## 1.5. 一些工具的安装与使用
### 1.5.1. tmux
- 昨天 (23.8.25) tmux 浅用了一下解决了 lab 里的一个任务要求，今天来深入了解一下它的用法
- 参考 [Tmux 使用教程 - 阮一峰的网络日志 (ruanyifeng.com)](https://www.ruanyifeng.com/blog/2019/10/tmux.html)
  - [Tmux 配置：打造最适合自己的终端复用工具 - zuorn - 博客园 (cnblogs.com)](https://www.cnblogs.com/zuoruining/p/11074367.html)
  - [tmux 配置文件.tmux.conf - 谁说我是二师兄 - 博客园 (cnblogs.com)](https://www.cnblogs.com/zhchy89/p/9835249.html)
  - 后二者有一些关于配置的信息参考
- tmux 的作用是：将“终端窗口”与会话解绑
- tmux 中，从大到小分为四个层级：server（服务）→session（会话）→window（窗口）→pane（窗格）
- 实例：
![[Pasted image 20230826132550.png]]
- 所有快捷键都要用前缀键 `Ctrl+b` 唤起
- tmux 的操作主要依靠输入命令或快捷键，输入命令有两种方式：
  1. 直接在命令行输入 `tmux + xxx`
  2. `ctrl + b + :` 进入命令模式，输入的命令可以省去 tmux 开头
- `tmux list-keys` 列出所有快捷键，及其对应的 Tmux 命令
- `tmux list-commands` 列出所有 Tmux 命令及其参数
- `tmux source-file ~/.tmux.conf` 重新加载当前的 Tmux 配置

#### 1.5.1.1. 会话管理
- 使用 `tmux` 创建编号命名会话，使用 `tmux -new -s <name>` 创建名字命名会话
-  `tmux detach` 或 `Ctrl+b d` 将会话与窗口分离
- `tmux kill-session -t <name or num>` 杀死会话
- `tmux switch -t <name or num>` 切换会话
- `tmux rename-session -t <old-name> <new-name>` 或 `Ctrl+b $` 重命名会话
- `tmux info` 或 `Ctrl+b s`：列出所有会话。

#### 1.5.1.2. 窗格操作
!!! info
    - `tmux split-window -h` 或 `Ctrl+b %`：划分左右两个窗格。
    - `tmux split-window` 或 `Ctrl+b "`：划分上下两个窗格。
    - `tmux select-pane -U(D、L、R)` 或 `Ctrl+b <arrow key>`：光标切换到其他窗格。
    - `Ctrl + b ;`：光标切换到上一个窗格。
    - `Ctrl + b o`：光标切换到下一个窗格。
    - `Ctrl + b x`：关闭当前窗格。
    - `tmux swap-pane -U` 或 `Ctrl + b {`：当前窗格与上一个窗格交换位置。
    - `tmux swap-pane -D` 或 `Ctrl + b }`：当前窗格与下一个窗格交换位置。
    - `Ctrl + b Ctrl + o`：所有窗格向前移动一个位置，第一个窗格变成最后一个窗格。
    - `Ctrl + b Alt + o`：所有窗格向后移动一个位置，最后一个窗格变成第一个窗格。
    - `Ctrl + b !`：将当前窗格拆分为一个独立窗口。
    - `Ctrl + b z`：当前窗格全屏显示，再使用一次会变回原来大小。
    - `Ctrl + b Ctrl + <arrow key>`：按箭头方向调整窗格大小。
    - `Ctrl + b q`：显示窗格编号。

#### 1.5.1.3. 窗口操作
!!! ad-info
    - `tmux new-window (-n <name>)` 或 `Ctrl + b c`：创建一个新窗口，状态栏会显示多个窗口的信息。
    - `Ctrl + b p`：切换到上一个窗口（按照状态栏上的顺序）。
    - `Ctrl + b n`：切换到下一个窗口。
    - `tmux select-window -t <name or num>` 或 `Ctrl + b <number>`：切换到指定窗口。
    - `Ctrl + b w`：从列表中选择窗口。
    - `tmux rename-window <new-name>` 或 `Ctrl + b ,`：窗口重命名。

#### 1.5.1.4. 自定义配置
- 新增 `Ctrl + a` 作为前缀键，保留原本的 `Ctrl + b`
- 已经开启的 session 不会重新读取配置文件（有缓存），此时可以 `<prefix> + r` reload
- 支持鼠标
- 使用 `Shift + <arrow>` 来更换 pane
- 使用 `Alt + <arrow>` 来更换 window
- 状态栏的调整

### 1.5.2. 在终端中显示 Linux 信息：Neofetch
- [Neofetch：在终端中显示 Linux 系统信息 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/69777438)

### 1.5.3. 软件包管理器之 aptitude
- aptitude 命令与 apt-get 命令一样，都是 Debian Linux 及其衍生系统中功能极其强大的包管理工具。
- 与 apt-get 不同的是，aptitude 在处理依赖问题上更佳一些。举例来说，aptitude 在删除一个包时，会同时删除本身所依赖的包。这样，系统中不会残留无用的包，整个系统更为干净。它通过文本操作菜单和命令两种方式管理软件包。
- 相对来说，更加推荐使用 aptitude 命令来代替 apt-get，特别是在下载或者删除依赖包的时候，aptitude 都要比 apt-get 更好。
- [Linux 命令之 aptitude -- APT 软件包管理工具_aptitude install-CSDN 博客](https://blog.csdn.net/liaowenxiong/article/details/118963228)
- 以后重装就主用这个

### 1.5.4. cat 增强之 bat
- 使用 apt install 安装，需要创建软连接以使用
- 使用方法见：[bat/doc/README-zh.md at master · sharkdp/bat (github.com)](https://github.com/sharkdp/bat/blob/master/doc/README-zh.md)

### 1.5.5. ncdu —— Linux 下的硬盘空间查看工具
- `sudo apt install ncdu` 即可
- [技术 | 用 ncdu 检查 Linux 中的可用磁盘空间](https://linux.cn/article-13729-1.html)
- 完爆原本的 `du`

### 1.5.6. ls 增强之 exa
- `sudo apt install exa`
- 中文的参数搭配可以参看：[没想到 exa 命令真的这么好用，直接把 ls 替代了 - 腾讯云开发者社区 - 腾讯云 (tencent.com)](https://cloud.tencent.com/developer/article/1944283)
- 其实基本上就是对 github 项目下的翻译：[ogham/exa: A modern replacement for ‘ls’. (github.com)](https://github.com/ogham/exa#command-line-options)
- `alias` 了 `ls` 和 `la`

### 1.5.7. tldr 查看命令帮助
- 直接上例子，不看又臭又长的文档
- 需要注意的是：`sudo apt install tldr` 后需要 `tldr -u` 更新 github 上的东西才能使用，不然会 `No tldr entry for [xxx]`
- [人生苦短，我用 tldr - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/82649746)

### 1.5.8. ranger 的使用与配置
- 用包管理器安装
- 默认配置的复制
- 退出时保留目录 [如何退出 Ranger 文件浏览器回到命令提示符，但保留当前目录？ (qastack.cn)](https://qastack.cn/superuser/1043806/how-to-exit-the-ranger-file-explorer-back-to-command-prompt-but-keep-the-current-directory)
- 想安装那篇博客配置，但是 ta 提到的两个软件无法下载
```shell
sudo apt install poppler
sudo apt install ueberzug
sudo pip install ueberzug
```
- 前者通过 `apt-get install poppler-utils -y` 近似代替
- 后者好像在这里解决了：[w3m - Image preview doesn't work in ranger - Ask Ubuntu](https://askubuntu.com/questions/1222930/image-preview-doesnt-work-in-ranger)
- ~~不知道会不会出问题~~ 依旧不能预览图片
- [把你的终端变成逆天高效神器：Ranger 终极配置方案～_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1b4411R7ck/?vd_source=39c8439d36378fa7ed46eae9e393a316)
- [ranger 使用小记 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/476289339)
- 唉好困难，各种配置都不起作用，反而把自己的电脑搞得一团糟，下载了很多乱七八糟的东西。反正图片显示还是没配起来
- 罢了，跳过吧

### 1.5.9. fd
- 是 find 的替代
- 通过 apt install 安装，但由于防止和其他包命令重名，设置了独特的名字，需要创建软连接以使用
- 使用方法见：[cha0ran/fd-zh: fd Chinese document (github.com)](https://github.com/cha0ran/fd-zh#installation)
### 1.5.10. thefuck
- 下载了但是用不了……
- 用 azure 那台服务器试了一下是正常的，得排查一下是什么问题了，估计是 anaconda 的问题
- 第二天试了一下，发现不是错了，而是响应速度极慢，问题在于 wsl 默认带了主机的 PATH，导致查询极慢（?）
- 解决方法是搜索路径排除 `/mnt/`
- 但为了开启 instant mode 又出现了新的问题 [[WARN] Script not found in output log No fucks given · Issue #714 · nvbn/thefuck (github.com)](https://github.com/nvbn/thefuck/issues/714)
  - 不知道如何解决，我坚信这是这个工具自己的问题，适配不行
  - 重新开了一个页面就可以了（？？？
  - 总之就是 instant mode 用不了
- 跟这个 SB 软件斗智斗勇了好久……

### anaconda
- 这个老早就装了，是个管理 python 的包管理器
- 不过在我安装 GitHub CLI 工具的时候，出现了问题如下，解决方法也一并在下
    ```shell
    The environment is inconsistent, please check the package plan carefully
    The following packages are causing the inconsistency:
    ...... // 省略
    ```
    ```shell
    conda update -n base -c defaults conda --force
    ```

## 1.6. 一些杂项知识点
### 1.6.1. PPA
- 什么是 PPA，可以看一下这篇文章，真的写得很好：[Ubuntu PPA 使用指南 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/55250294)
- `sudo add-apt-repository [repo_name]` 加入
-  `sudo apt-add-repository -r [repo_name]` 删除

***

# 2. WSL: Windows Subsystem for Linux
## 2.1. wsl 启动文件配置
- `/etc/wsl.conf`这个文件里面写命令
- 有`[automount]`、`[network]`、`[interop]`、`[user]`、`[boot]`等节标签
![[uTools_1685153412628.png]]

![[uTools_1685154340231.png]]

![[uTools_1685154399472.png]]
  - 上面这几个看起来都挺有用（Obsidian 里的图片，没导进来）
- 例如，如下面的屏幕快照所示，用户可以使用此新的 WSL 功能来记录其 WSL 发行版的启动时间和日期。
    ![](https://pic2.zhimg.com/80/v2-c96410b7b0bf300ac2d0bc74e9e31cad_720w.webp)
    ```shell
    command="echo WSL booted at $(/bin/date +'%Y-%m-%d %H:%M:%S') >> /home/crd233/wslBootHistory.txt"
    ```
- 一旦类似上面命令被添加到 WSL 发行版的/etc/wsl.conf 文件中，则在发行版启动时将自动运行相关的 Linux 命令。
- `.wsl.conf`与`.wslconfig`
  - 前者是单个 linux 分 发版，`.wsl.conf`装在哪就对哪起作用
  - 后者是对所有 linux 分发版的全局配置，并且后者存放在 windows 的用户目录下（第一次需要自己创建）

## 2.2. wsl 的网络问题
- 在 bash 里面加命令 (`.bashrc` or `.zshrc`)
    ```shell
    host_ip=$(cat /etc/resolv.conf |grep "nameserver" |cut -f 2 -d " ")
    export http_proxy="http://$host_ip:7890"
    export https_proxy="http://$host_ip:7890"
    ```
- 原理似乎是让 wsl 走主机的代理
- 参考 [为 WSL2 一键设置代理 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/153124468)
- 另外一种方法是开启 clash 的 TUN Mode / Mixin，不过有时会导致 DNS 解析失败

## 2.3. wsl 的网络问题——续
- (23.12.18 记)，这几天 wsl 突然开始爆“检测到 localhost 代理配置，但未镜像到 WSL。NAT 模式下的 WSL 不支持 localhost 代理”，然而我实际上用的好好的
- 网上查找，根据 [wsl: 检测到 localhost 代理配置，但未镜像到 WSL。NAT 模式下的 WSL 不支持 localhost 代理。 · Issue #10753 · microsoft/WSL (github.com)](https://github.com/microsoft/WSL/issues/10753) 的解决方法，创建 `.wslconfig` 并添加如下内容：
    ```shell
    [experimental]
    autoMemoryReclaim=gradual  # gradual  | dropcache | disabled
    networkingMode=mirrored
    dnsTunneling=true
    firewall=true
    autoProxy=true
    ```
- 然后本来能用的就不能用了 :(
- 于是我改成了这样
    ```shell
    [experimental]
        #autoMemoryReclaim=gradual  # gradual  | dropcache | disabled
        #networkingMode=mirrored
        #dnsTunneling=true
        #firewall=true
        autoProxy=false
    ```
- 就能用了，而且把那个烦人的报错也关掉了
  - 感觉应该是 wsl 的某次更新（应该是，突然出现的问题，而且那些博客的日期也很近）添加了自动设置代理的功能，但是跟我原本的设置冲突了。这里我选择先直接关掉这个新增的功能，以后有时间再尝试解决吧

## 2.4. wsl 路径问题
- 不知道什么时候开始，我的 PATH 里面就掺杂了主机下的路径，这是为了在 wsl 上也能使用主机的文件
- 但问题在于，有的时候我希望两台机子（真实 & 虚拟）隔离一些。因为有时如果我的 wsl 上没有装某个软件，但执行相关命令的时候执行到了主机下的同软件，导致没有报错（command not find）但是运行时错误，这肯定不是我想要的
- 于是解决方法是：[bash $PATH includes native Windows path entries · Issue #1640 · microsoft/WSL (github.com)](https://github.com/microsoft/WSL/issues/1640#issuecomment-616887435)
- 这样以后，以前可以在 wsl 下使用的 `explorer.exe`、`code`、`notepad` 等命令不再那么方便了
- 思考了一下，决定还是取消掉上面的解决方法，按照默认来好了，毕竟这真的很方便。至少我现在知道有这么一个解决方案，以后遇到问题会长个心眼
- 至于引发我关注这个问题的 thefuck，有另外的解决方案
- 这个东西不知道能不能解决这个问题？
  - [跨文件系统工作 | Microsoft Learn](https://learn.microsoft.com/zh-cn/windows/wsl/filesystems#share-environment-variables-between-windows-and-wsl-with-wslenv)
  - [WSL 中 Linux 与 Windows 间的环境共享_51CTO 博客_windows linux 环境](https://blog.51cto.com/u_15127574/3368874)

## 2.5. WSL 下 sudo 后无法链接至 Xserver
- `cannot connect to X server` 类似这样的报错
- 是从计逻要下的 ISE 的安装中暴露出的问题，不 sudo 没法安装，sudo 了又连不上 GUI
- 这个问题意思是 sudo 后因为环境问题没有办法连接到 GUI 程序
- 可以参考这个链接 [display - Cannot connect to X Server when running app with sudo - Ask Ubuntu](https://askubuntu.com/questions/175611/)
- 我是加的 `Defaults env_keep+="DISPLAY XAUTHORITY"` 这句

## 2.6. WSL 下 ISE 的安装运行与脚本的使用
- 参照 [如何在 Windows 11 上安装 Xilinx 14.7 System Edition | 川虎的博客 (gzblog.tech)](https://www.gzblog.tech/2021/10/31/How-to-config-Xilinx-14-7-on-Windows-11/) 使用 wsl 安装运行
- 首先除了 sudo 无法链接至 Xsever 的问题
- 除了上面的安装问题外又出错了，唉
```shell
$ source /opt/Xilinx/14.7/ISE_DS/settings64.sh && ise
/opt/Xilinx/14.7/ISE_DS/settings64.sh:12: = not found
```
- 经过探索找到了稳定复现的办法，确定原因在于 shell
  - su 之后用 root 可以打开（我的 root 还是用的 bash）
  - 将当前用户的默认 shell 改成 bash 之后就能打开了
- 我的解决办法是编写 sh 脚本临时使用 bash 来打开，执行完后自动回到 zsh
- 这依靠 `exec` 命令，见下
    ```shell
    #!/bin/bash
    exec bash -c 'source /opt/Xilinx/14.7/ISE_DS/settings64.sh && ise; exec zsh'
    ```
> 后来发现并不用 `exec`，直接指定 bash 就好了。但为什么当时我不行呢？可能姿势出了点问题
> 好像是因为我一直用 `source` 来启动脚本的原因，用 `.` 来另起一个 shell 就正常了

## 2.7. WSL 的瘦身与空间转移
- 转移就是把 wsl 虚拟映射文件压缩，然后创建到其它盘，参考 [轻松搬迁！教你如何将 WSL 从 C 盘迁移到其他盘区，释放存储空间！](https://zhuanlan.zhihu.com/p/621873601)
- 瘦身就是释放 wsl 实际不再占用的空间，参考 [清理 WSL2 的磁盘占用](https://zhuanlan.zhihu.com/p/614993276)
- 实际上，新的 wsl 有一个 `sparseVhd=true` 的功能，在 `.wslconfig` 里设置就可以了，这样能让 wsl 的映射文件随着实际使用空间的变化而变化

***

# 3. Powershell 与 Windows CLI
## 3.1. Windows PowerShell 更新命令
- 在 Windows 包管理器中检查所有可用的 PowerShell 安装程序
  - `winget search powershell`
- 安装或升级
  - `winget install powershell`
  - `winget upgrade powershell`
- 使用下面的脚本来获取更新的 Windows PowerShell 包
  - `Invoke-Expression "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"` （图形安装了？）

## 3.2. Powershell 和 Zsh 的一些快捷键
- 虽然也涉及到 zsh，但总归放在 Powershell 部分
- 不太一样甚至有冲突，不过用好了挺方便
- 评价是有点难记
### 3.2.1. Powershell
!!! info
    ctrl + a 选中全部
    ctrl + x(X) 删除整行
    ctrl + w 删除到上一个单词
    ctrl + h 之后内容上移一行
    ctrl + j 之后内容下移一行

### 3.2.2. Zsh
- 同 Emacs

!!! info
    ctrl + u 从光标处删除至开头
    ctrl + k 从光标处删除至结尾
    ctrl + a 将光标移至开头
    ctrl + e 将光标移至结尾
    ctrl + p 同方向键上
    ctrl + n 同方向键下
    ctrl + d 删除光标处字符
    alt + f 将光标移至下个单词
    alt + b 将光标移至上个单词

## 3.3. Windows 下软件包管理器的安装
- 之前已经装过 Chocolatey，但是它的效果不如 Scoop。另外还有自带的 winget
  ![[Pasted image 20230816215859.png]]
- 首先设置 PowerShell 权限 `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- 然后设定 Scoop 安装目录，先 `$env:SCOOP='D:\Scoop'`，再 `[Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')`
- 安装 `iwr -useb get.scoop.sh | iex`
- 其下文件夹的介绍

!!! info
    - apps——所有通过 scoop 安装的软件都在里面。
    - buckets——管理软件的仓库，用于记录哪些软件可以安装、更新等信息，默认添加`main`仓库，主要包含无需 GUI 的软件，可手动添加其他仓库或自建仓库，具体在[推荐软件仓库](https://zhuanlan.zhihu.com/write#%E6%8E%A8%E8%8D%90%E8%BD%AF%E4%BB%B6%E4%BB%93%E5%BA%93)中介绍。
    - cache——软件下载后安装包暂存目录。
    - persit——用于储存一些用户数据，不会随软件更新而替换。
    - shims——用于软链接应用，使应用之间不会互相干扰，实际使用过程中无用户操作不必细究。
- 仓库和网络配置，在 `C:\Users\username\.config\scoop\config.json`
    ```json
    {
      "last_update": "2023-08-16T21:46:14.4658001+08:00",
      "SCOOP_REPO": "https://github.com/ScoopInstaller/Scoop",
      "SCOOP_BRANCH": "master",
      "aria2-enabled":true,
      "proxy": "127.0.0.1:7890"
    }
    ```
- 参考链接：[Scoop——也许是 Windows 平台最好用的软件（包）管理器 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/463284082)

## 3.4. Windows Powershell 下的各种操作
### 3.4.1. powershell 中设置和查看别名
- 首先是从 GPT 口中得知，`$PROFILE` 得到的 `Microsoft.PowerShell_profile.ps1` 可以对标 linux 中的 `.zshrc`？（感觉层次不太对，但效果确实是这样）
- 然后 `get-Alias` 查看别名
- `Set-Alias -Name xxxx -Value yyyy` 设置别名

### 3.4.2. Powershell 的文件查找
- powershell 里用 `where` 没报错但是没用，反而 cmd 能用
- 原来是要用 `where.exe`，吐了
- 参见 [在 PowerShell 中使用 where 命令查找文件](https://blog.csdn.net/mighty13/article/details/119880762)

### 3.4.3. Windows powershell 查看字体
- 输入以下三行命令
```shell
Add-Type -AssemblyName System.Drawing
$installedFonts= New-Object 'System.Drawing.Text.InstalledFontCollection'
$installedFonts.Families
```
- 原理是：将 .NET Framework 类库中的 System.Drawing 程序集添加到当前 powershell 会话中，然后创建一个变量并初始化为 Text.InstalledFontCollection 对象，最后使用 Families 属性获取字体集合

## 3.5. Powershell 下的 conda init 问题修复及 PROFILE 的修改
### 3.5.1. conda init
- 这个问题很早就出现了，今天 (23.9.26) 才去着手修复
-  `D:\�ĵ�`，`conda init` 会生成这样一个文件夹以及 `profile` 内容，来修改 powershell 启动时的操作，但我的 profile 不在这里
- 只要将它生成的文件内容（用于初始化的内容）复制到我真正的 `notepad $PROFILE` 内就行了
- 然后就会发现 powershell 启动巨巨巨慢，足足要花 8s
- 解决方案是，需要的时候再启动 conda，反正平时用的 python 好像也是 conda 里的那个（感觉好像没什么启动 conda 的需求了 orz）
  - 参考 [conda init 导致的 powershell 启动缓慢的问题](https://blog.51cto.com/cquptlei/7178172)
  - 把 conda init 产生的脚本内容单独放到一个脚本文件里，然后设置启动脚本的别名为 `conda`（平时这个命令会显示 conda 的提示罢了，没啥用）
  - 这样以后，powershell 的启动速度和 oh-my-posh 之后一样了
### 3.5.2. VSCode 下的 conda init
- 没想到这样改了以后还是有问题，每次开 Terminal 都会进行 `conda activate base`
  - 而且这个 activate 好像还是用 cmd 执行的，糖丸了
- 解决办法是加一句 `"python.terminal.activateEnvironment": false,` 到 `settings.json` 里面去
- 然后使用方法就跟上面一样了，需要的时候 `conda` 即可
- 我的 VSCode 终于正常起来了，泪目

### 3.5.3. PROFILE
- 此外，我还对 PROFILE 进行了一定的修改，见下
- 可以参考[缩短命令、调整按键、自动补全，这些代码值得你放进 PowerShell 配置文件 - 少数派 (sspai.com)](https://sspai.com/post/73019)
- 主要删去了一些过时已集成的命令以加快速度（可能没用），然后增加了 tab 的菜单补全和 `ctrl+x` 删除整行

## 3.6. 关于 Powershell 和 VSCode 的中文显示
- (23.10.1 记)：这个问题几天前就出现了，根本原因是编码格式的问题
- 如果我的理解没错的话，问题在于 VSCode 的编码格式是 UTF-8，重保存成 GBK 即可正常显示，但我更想要的是全部用 UTF-8
- 下面说一些探索过程中看到的东西，不一定起效，但可作参考
- 终端这边，据说可以用 `chcp` 来显示与更改编码，但是在我这都没有用，可能是被后文所说的东西给覆盖了（？
- Powershell 有两个变量 `$PSDefaultParameterValues`、`$OutputEncoding`，可能与此有关
- `控制面板-时钟和区域-区域-管理-更改系统区域设置` 里可以开启一个功能：`Beta版：使用Unicode UTF-8提供全球语言支持(U)`。但我不太敢动，可能会导致系统内其他中文软件乱码
- 最后是从 Powershell 自己的 $PROFILE 动刀的。这里到底用什么命令众说纷纭，我试了几个终于找到了对我起效的：`[Console]::OutputEncoding = [System.Text.Encoding]::Default`
- 参考资料
  1. [关于字符编码 - PowerShell | Microsoft Learn](https://learn.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/about/about_character_encoding?view=powershell-7.3)
  2. [vscode c 语言 printf 打印中文，终端输出乱码怎么解决？ - 知乎 (zhihu.com)](https://www.zhihu.com/question/330682775)
  3. [win10 下，cmd,power shell 设置默认编码为‘UTF-8’? - 知乎 (zhihu.com)](https://www.zhihu.com/question/54724102)
  4. [控制台程序的中文输出乱码问题，printf,wprintf 与 setlocale - Mr.DejaVu - 博客园 (cnblogs.com)](https://www.cnblogs.com/dejavu/archive/2012/09/16/2687586.html)
  5. [Powershell 改变默认编码_powershell 编码-CSDN 博客](https://blog.csdn.net/u014756245/article/details/100536552)
  6. [powerShell 使用 chcp 65001 之后，还是显示乱码问题解决-CSDN 博客](https://blog.csdn.net/sxzlc/article/details/104880570)
  7. [PowerShell 编码研究与 VSCode 乱码问题 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/456772071)（最终对我起效的）
- (23.11.28 记)，在尝试 java 的时候发现 `java` 这一命令（会输出 help 信息）依然输出乱码
  - 这次，输入 `chcp 65001` 后，`java` 命令输出正常，且直接从 C 语言编译来的文件输出中文也不会乱码
  - 遂将 `chcp 65001 > $null`（后面的 null 是为了不输出信息）写入 `$PROFILE`，每次启动 powershell 自动执行

## 3.7. Powershell 和 Windows Terminal 美化
- 又到了喜闻乐见的客制化时间，这次不是 wsl 的 zsh，而是本机环境
- 在 windows 下 `notepad $PROFILE` 会打开 `D:\文档\PowerShell` 下的 `Microsoft.PowerShell_profile.ps1`，这是 powershell 的启动项
- 然后我回忆了一下以前的 powershell 的启动项好像是在 `C:\Program Files\PowerShell\7\Microsoft.powerShell_profile.ps1`，到底 tm 是哪个？
  - 我觉得用现在这个挺好的，我已经掌握了现在这个的修改方法。以前的那个被我删了
- `winget install JanDeDobbeleer.OhMyPosh -s winget` 安装
- 下载之后，管理员身份能找到 `oh-my-posh` 命令，非管理员不行，需要重启，不知道什么逼毛病
- 后续设置可以参考 [oh-my-posh 安装过程问题及注意事项_Every DAV inci 的博客-CSDN 博客](https://blog.csdn.net/ahahayaa/article/details/125470204)
- [Set-PSReadLineOption (PSReadLine) - PowerShell | Microsoft Learn](https://learn.microsoft.com/zh-cn/powershell/module/psreadline/set-psreadlineoption?view=powershell-7.3)这里可以查看一些 powershell 的设置
  - 基于此我实现了命令提示颜色的更改
  - 不过我发现好像有另外一种办法 `scoop install colortool` 😓
- 我换了一个背景，因此需要更改 wsl 里面和 powershell 里面的 InlinePrediction 的颜色
  - 对此，powershell 可以用上面说的方法改
  - wsl 里面是 zsh-autosuggestions 这个插件提供的，更改 `~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh` 这个文件里的 `typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'`，把 `8` 改为 `#438a55` （其实好像可以在 `.zshrc` 里直接覆盖，不过肯定是不如这里清净啦）
    - 但是问题是，这个方法只更改了提示命令的颜色，其他类型的颜色暂时不知道在哪改
    - `ys.zsh-theme` 里面似乎只是改了 prompt 的颜色
    - 哦应该可以通过 `zsh-syntax-highlighting` 来改，但是我看不太懂代码
      - 但是看了看 issues 好像也不管这个 [How to change the color of directories in the output of "ls" command? · Issue #864 · zsh-users/zsh-syntax-highlighting (github.com)](https://github.com/zsh-users/zsh-syntax-highlighting/issues/864)
    - 暂时无法解决
- 用这个看颜色
```
for i in {0..255} ; do
    printf "\x1b[38;5;${i}mcolour${i}\n"
done
```