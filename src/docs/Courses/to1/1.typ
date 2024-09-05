---
order: 1
---

#import "/src/components/TypstTemplate/lib.typ": *
#show: project.with(
  title: "This is a title",
  // show_toc: false,
  lang: "zh",
)

$arrow.t$ 中看不中用的目录（引用问题）

Pay attention to the order.

This file has order: $1$.


= 大标题测试

== 小标题测试

加载到这页有点慢？可能是因为 typst 目前的 “html” 导出有点慢。。。

=== 三级标题测试 <title>

引用的问题很大，目前似乎还不行，点点右边这个 $-> $@title

== 文字测试

=== 关于字体
字体：先在"Arial"中寻找，找不到才在黑体、宋体等中文字体中寻找，通过这种方法实现*先英文字体、后中文字体*的效果。这个字体可以先去搜索下载（#link("https://github.com/notofonts/noto-cjk/releases")[下载链接]，下载Noto Serif CJK和Noto Sans CJK），或者直接在终端中输入"typst fonts"查看你电脑上的字体，然后修改`font.typ`相关内容为你拥有且喜爱的字体。

_斜体_与*粗体*，_Italic_ and *bold*。但是中文没有斜体（事实上，如果字体选择不佳，连粗体都没有），一般用楷体代替 ```typ #show emph: text.with(font: ("Arial", "LXGW WenKai"))```

如果需要真正的斜体，可以使用伪斜体（旋转得到，可能会有 bug？）：#fake-italic[中文伪斜体]。

中英文字体之间正常情况下会自动添加空格，像这样test一下。手动添加空格也可以（对Arial和思源字体而言），像这样 test 一下，间隙增加可以忽略不计。如果换用其它字体，可能会出现手动空格导致间隙过大的情况。

=== 关于缩进
使用一个比较 tricky 的包 #link("https://github.com/flaribbit/indenta")[indenta] 来达到类似 LaTeX 中的缩进效果：两行文字间隔一行则缩进，否则不缩进。可能会遇到一些 bug，此时可以使用```typ #noindent[Something]```来取消缩进，比如下面这样：

#hline()

#noindent[
  这是一个没有缩进的段落。

  空一行，本来应该缩进，但被取消。\
  采用连接符换行。
]

#hline()

而在原始情况下是这样：

这是一个有缩进的段落。

空一行，缩进，但被取消。
不空行，视为跟之前同一段落。\
采用连接符换行。
#hline()

#indent 另外，通过 `#indent`（或`#tab`）能缩进内容，比如在图表之后，需要手动缩进。其实也可以自动缩进，只是个人认为，图表后是否缩进还是由作者手动控制比较好。

== 图表测试
=== 公式
Given an $N times N$ integer matrix $(a_(i j))_(N times N)$, find the maximum value of $sum_(i=k)^m sum_(j=l)^n a_(i j)$ for all $1 <= k <= m <= N$ and $1 <= l <= n <= N$.

$ F_n = floor(1 / sqrt(5) phi.alt^n) $
$ F_n = floor(1 / sqrt(5) phi.alt^n) $ <->


为了更加简化符号输入，有这么一个包 #link("https://github.com/typst/packages/tree/main/packages/preview/quick-maths/0.1.0")[quick-maths]，定义一些快捷方式，比如：

```typ
#show: shorthands.with(
  ($+-$, $plus.minus$),
  ($|-$, math.tack),
  ($<=$, math.arrow.l.double) // Replaces '≤', use =< as '≤'
)
```

$ x^2 = 9 quad <==> quad x = +-3 $
$ A or B |- A $
$ x <= y $

=== 代码
code使用codly实现，会自动捕捉所有成块原始文本，像下面这样，无需调用code命令（调用code命令则是套一层 figure，加上 caption）。

可以手动禁用 codly ```typ #disable-codly()```，后续又要使用则再 ```typ #codly()``` 加回来

#disable-codly()
```raw
disabled code
```
#codly()
```raw
enabled code
```

代码块经过特殊处理，注释内的斜体、粗体、数学公式会启用 eval
```cpp
cout << "look at the comment" << endl; // _italic_, *bold*, and math $sum$
```
```c
#include <stdio.h>
int main() {
  printf("Hello World!");
  return 0;
}
```

=== 表格
表格通过原生 table 封装到 figure 中，并添加自动数学环境参数：```typ automath: true```，通过正则表达式检测数字并用 `$` 包裹。
#tbl(
  automath: true,
  fill: (x, y) => if y == 0 {aqua.lighten(40%)},
  columns: 4,
  [Iteration],[Step],[Multiplicand],[Product / Multiplicator],
  [0],[initial values],[01100010],[00000000 00010010],
  table.cell(rowspan: 2)[1],[0 $=>$ no op],[01100010],[00000000 00010010],
  [shift right],[01100010],[00000000 00001001],
  table.cell(rowspan: 2)[2],[1 $=>$ prod += Mcand],[01100010],[01100010 00001001],
  [shift right],[01100010],[00110001 00000100],
  table.cell(rowspan: 2)[3],[0 $=>$ no op],[01100010],[00110001 00000100],
  [shift right],[01100010],[00011000 10000010],
  table.cell(colspan: 4)[......]
)

#align(center, (stack(dir: ltr)[
  #tbl(
    // automath: true,
    fill: (x, y) => if y == 0 {aqua.lighten(40%)},
    columns: 4,
    [t], [1], [2], [3],
    [y], [0.3s], [0.4s], [0.8s],
  )
  ][
    #h(50pt)
  ][
  #tlt(
    // automath: true,
    columns: 4,
    [t], [1], [2], [3],
    [y], [123.123s], [0.4s], [0.8s],
  )
]))

由于习惯了 markdown 的表格，所以 typst 的表格语法可能不太习惯（其实强大很多），但是也有类 markdown 表格 package 的实现：
#tblm()[
  | *Name* | *Location* | *Height* | *Score* |
  | ------ | ---------- | -------- | ------- |
  | John   | Second St. | 180 cm   |  5      |
  | Wally  | Third Av.  | 160 cm   |  10     |
]

== 列表
Bubble list 语法（更改了图标，使其更类似 markdown，且更大）和 enum 语法：
- 你说
  - 得对
    - 但是
      - 原神
+ 是一款
+ 由米哈游
  + 开发的
  + 开放世界
    + 冒险
    + 游戏

Term list 语法：
/ a: Something
/ b: Something
