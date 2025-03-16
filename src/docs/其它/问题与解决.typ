#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: none,
  lang: "zh",
)

#let s(caption, bug, fix) = success(caption: caption, bug, fix)
#let w(caption, bug, fix) = warning(caption: caption, bug, fix)
#let f(caption, bug, fix) = failure(caption: caption, bug, fix)

= 问题与解决
这里记录平时遇到的一些杂乱（不好归类）问题，以及它们的解决。

#grid(
  columns: 3,
  column-gutter: 8pt,
  s([Success],[这样表示问题完全解决],[喜大普奔 #emoji.face.happy]),
  w([Warning],[这样表示问题基本解决],[但可能有隐患 #emoji.face.sad]),
  f([Failure],[这样表示问题目前没法解决],[或者说解决办法我完全不认可 #emoji.face.angry]),
)
#v(2em)

#w([Edge 浏览器页面过曝], [Edge 浏览器的 bug，在双屏使用且打开 HDR 功能时出现，没开 HDR 的那台显示器打开 edge 会时不时出现过曝问题], [解决方法详见 #link("先 `git fetch` 然后手动操作")[这篇文章]，但似乎这样用不了 HDR 了（虽然我这个笔记本屏也没想过要开 HDR 就是了）])

#f([Windows 与第三方输入法的冲突], [Windows 自动更新后的 bug，傻逼微软，而且一直不修，详见 #link("https://blog.csdn.net/alan16356/article/details/143787272")[Win11 24H2/23H2 输入法 首字母变成英文/首字母打不出汉字/首击键不被认定为拼音 临时解决方案]], [暂时没有好的解决办法])

#s([VSCode Copilot 功能受限], [在新电脑上下了 VSCode 之后，发现它的 copilot 是以往的版本（即 chat view 显示在左侧工具栏，没有上方的 copilot 按钮，没有 edit mode，也无法切换模型），上网搜了好久都没有找到类似的问题和解决办法], [最后发现，卸载重新安装解决一切问题，大概是一开始下的老版本，它的设置覆盖了新版本吧 #emoji.face.sweat])

#s([C盘清理], [老生常谈的问题了], [
  - 最常见的例如软件安装地址迁移、用 Windows 自带和一些相关扫描清理工具等方法这里就不赘述了
  - 再进阶一点，可以用 `mklink` 软链接来实现迁移。一般来说，在 cmd 里面用 administrator 权限先 `cp -r` 再 `rm -r`，之后运行 `mklink /D <目标文件夹> <源文件夹>` 就可以了
  - 还有一些容易忽略清除、扫描也扫不到、删了问题也不大的例子
    + `C:\Users\<你的用户名>\AppData\Local\Microsoft\Edge\User Data\Default\Service Worker\CacheStorage`，#link("https://zhuanlan.zhihu.com/p/613382188")[安全性参考]
    + `C:\Users\<你的用户名>\AppData\Local\Microsoft\vscode-cpptools\ipch`（最好 VSCode 改个位置），#link("https://blog.csdn.net/qq_42257666/article/details/138031699")[安全性参考]
    + `C:\Users\<你的用户名>\AppData\Roaming\Code` 下的*某些*文件，#link("https://blog.csdn.net/Tisfy/article/details/126082324")[安全性参考]
    + `C:\Users\moonwolf\AppData\Roaming\Tencent\` 下的某些文件，#link("https://www.cnblogs.com/jeakon/archive/2013/02/19/2917584.html")[QQ 参考这个] #link("https://www.cnblogs.com/jeakon/archive/2013/02/19/2917584.html")[`WeChat\XPlugin` 参考这个]
])

