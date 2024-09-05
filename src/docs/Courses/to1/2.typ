---
order: 2
---

#import "/src/components/TypstTemplate/lib.typ": *
#show: project.with(
  title: "This is a title",
  // show_toc: false,
  lang: "zh",
)

Pay attention to the order.

This file has order: $3$.

从第三方包中（or自己编写）预先挑选了一些比较实用的工具，比如：

= Fletcher
Typst 中的 cetz 就像 LaTeX 中的 tikz 一样，提供强大的画图功能，但是个人感觉略繁琐。#link("https://github.com/Jollywatt/typst-fletcher")[Fletcher] 基于 cetz 提供了 diagrams with arrows 的简单画法。

#import fletcher.shapes: diamond
#diagram(
  node-stroke: .1em,
  node-fill: gradient.radial(blue.lighten(80%), blue, center: (30%, 20%), radius: 80%),
  spacing: 4em,
  edge((-1,0), "r", "-|>", [open(path)], label-pos: 0, label-side: center),
  node((0,0), [reading], radius: 2em),
  edge([read()], "-|>"),
  node((1,0), [eof], radius: 2em),
  edge([close()], "-|>"),
  node((2,0), [closed], radius: 2em, extrude: (-2.5, 0)),
  edge((0,0), (0,0), [read()], "--|>", bend: 130deg),
  edge((0,0), (2,0), [close()], "-|>", bend: -40deg),
)
#align(center, grid(
  columns: 3,
  gutter: 8pt,
  diagram(cell-size: 15mm, $
    G edge(f, ->) edge("d", pi, ->>) & im(f) \
    G slash ker(f) edge("ur", tilde(f), "hook-->")
  $),
  diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    node((0,0), [Start], corner-radius: 2pt, extrude: (0, 3)),
    edge("-|>"),
    node((0,1), align(center)[
      Hey, wait,\ this flowchart\ is a trap!
    ], shape: diamond),
    edge("d,r,u,l", "-|>", [Yes], label-pos: 0.1)
  ),
  diagram($
    e^- edge("rd", "-<|-") & & & edge("ld", "-|>-") e^+ \
    & edge(gamma, "wave") \
    e^+ edge("ru", "-|>-") & & & edge("lu", "-<|-") e^- \
  $)
))

= syntree & treet
语法树，像这样，可以用字符串解析的方式来写，不过个人更喜欢后一种自己写 `tree` 的方式，通过合理的缩进更加易读。
#let bx(col) = box(fill: col, width: 1em, height: 1em)

#grid(
  columns:2,
  gutter: 4em,
  syntree(
    nonterminal: (font: "Linux Biolinum"),
    terminal: (fill: red),
    child-spacing: 3em, // default 1em
    layer-spacing: 2em, // default 2.3em
    "[S [NP This] [VP [V is] [^NP a wug]]]"
  ),
  tree("colors",
    tree("warm", bx(red), bx(orange)),
    tree("cool", bx(blue), bx(teal)))
)

#tab 文件夹型的树，像这样

#tree-list(root: "root")[
- 1
  - 1.1
  - 1.2
    - 1.2.1
- 2
- 3
  - 3.1
    - 3.1.1
]

= 伪代码（算法）
lovelace包，可以用来写伪代码，body 最好用 typ，比如：

#algo(
  caption: [caption for algorithm],
  ```typ
  #no-number
  *input:* integers $a$ and $b$
  #no-number
  *output:* greatest common divisor of $a$ and $b$
  <line:loop-start>
  *if* $a == b$ *goto* @line:loop-end
  *if* $a > b$ *then*
    $a <- a - b$ #comment[and a comment]
  *else*
    $b <- b - a$ #comment[and another comment]
  *end*
  *goto* @line:loop-start
  <line:loop-end>
  *return* $a$
  ```
)

= wrap_content
文字图片包裹，不用自己考虑分栏了。在大多数时候是比较有效的，但有的时候不是很好看，可能还是得自己手动 grid。

#let fig = figure(
  rect(fill: teal, radius: 0.5em, width: 8em),
  caption: [A figure],
)
#let body = lorem(40)

#wrap-content(
  align: bottom + right,
  column-gutter: 2em,
  fig
)[
  #indent #body
]

#wrap-top-bottom(fig, fig, body)

= 真值表

快速制作真值表，只支持 $not and or xor => <=>$。
#truth-tbl($A and B$, $B or A$, $A => B$, $(A => B) <=> A$, $ A xor B$)

#tab 更复杂的用法（自己填data），三个参数分别是样式函数、表头、表内容：
#truth-tbl-empty(
  sc: (a) => {if (a) {"T"} else {"F"}},
  ($a and b$, $a or b$),
  (false, [], true, [] , true, false)
)

= todo(checklist)
- [ ] 加入更多layouts，比如前言、附录
- [x] 重构代码，使得可以根据语言切换文档类型

= Pinit

#v(2em)

$ (#pin(1)q_T^* p_T#pin(2))/(p_E#pin(3))#pin(4)p_E^*#pin(5) >= (c + q_T^* p_T^*)(1+r^*)^(2N) $

#pinit-highlight-equation-from((1, 2, 3), 3, height: 3.5em, pos: bottom, fill: rgb(0, 180, 255))[
  In math equation
]

#pinit-highlight-equation-from((4, 5), 5, height: 1.5em, pos: top, fill: rgb(150, 90, 170))[
  price of Terran goods, on Trantor
]

`print(pin6"hello, world"pin7)`

#pinit-highlight(6, 7)
#pinit-point-from(7)[In raw text]

#v(4em)

这玩意儿的用法略灵活，可以看它的仓库 #link("https://github.com/typst/packages/tree/main/packages/preview/pinit/0.1.4")[pinit]

= mitex
使用 #link("https://github.com/typst/packages/tree/main/packages/preview/mitex/0.2.4")[mitex] 包渲染 LaTeX 数学环境，比如：

通过这个包，可以快速把已经在 Markdown 或 LaTeX 中的公式重复利用起来；同时，利用市面上众多的 LaTeX 公式识别工具，可以减少很多工作。

#mitex(`
  \newcommand{\f}[2]{#1f(#2)}
  \f\relax{x} = \int_{-\infty}^\infty
    \f\hat\xi\,e^{2 \pi i \xi x}
    \,d\xi
`)
#mitext(`
  \iftypst
    #set math.equation(numbering: "(1)", supplement: "equation")
  \fi

  A \textbf{strong} text, a \emph{emph} text and inline equation $x + y$.

  Also block \eqref{eq:pythagoras}.

  \begin{equation}
    a^2 + b^2 = c^2 \label{eq:pythagoras}
  \end{equation}
`)
