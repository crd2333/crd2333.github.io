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

#w([Edge 浏览器页面过曝], [Edge 浏览器的 bug，在双屏使用且打开 HDR 功能时出现，没开 HDR 的那台显示器打开 zdge 会时不时出现过曝问题], [详见 #link("先 `git fetch` 然后手动操作")[这篇文章]，但似乎这样用不了 HDR 了（虽然我这个屏也没想要就是了）])

#f([Windows 与第三方输入法的冲突], [Windows 自动更新后的 bug，傻逼微软，而且一直不修，详见 #link("https://blog.csdn.net/alan16356/article/details/143787272")[Win11 24H2/23H2 输入法 首字母变成英文/首字母打不出汉字/首击键不被认定为拼音 临时解决方案]], [暂时没有好的解决办法])

#s([VSCode Copilot 功能受限], [在新电脑上下了 VSCode 之后，发现它的 copilot 是以往的版本（即 chat view 显示在左侧工具栏，没有上方的 copilot 按钮，没有 edit mode，也无法切换模型），上网搜了好久都没有找到类似的问题和解决办法], [最后发现，卸载重新安装解决一切问题，大概是一开始下的老版本，它的设置覆盖了新版本吧 #emoji.face.sweat])