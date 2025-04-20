#import "fonts.typ": *
#import "utils.typ": *
#import "math.typ": *
#import "figures.typ": *

#let project(
  title: "",
  lang: "zh",
  body
) = {

  set document(title: title,)
  set page(
    paper: "a4",
    height: auto,
    margin: (x: 1cm, y: 0cm),
  )

  // 导入 show 规则
  show: checklist.with(fill: luma(95%), stroke: blue, radius: .2em, show-list-set-block:(above: 0.8em))
  show: shorthand // 导入 math shorthand
  show: show-theorion.with()
  show: zebraw-init.with(
    background-color: (luma(240), luma(250)),
    highlight-color: yellow.lighten(90%),
    comment-color: blue.lighten(90%),
    extend: false,
  )
  show: zebraw
  // 行间公式、原始文本与文字之间的自动空格
  show raw.where(block: false): it => h(0.25em, weak: true) + it + h(0.25em, weak: true)
  show math.equation.where(block: false): it => h(0.25em, weak: true) + it + h(0.25em, weak: true)
  // 矩阵用方括号显示
  set math.mat(delim: "[")
  set math.vec(delim: "[")
  // 引用与链接字体蓝色显示
  show ref: set text(colors.blue)
  show link: it => {
    set text(fill: colors.blue)
    it + h(2pt) + text(size: 7pt, fajumplink)
  }
  // 设置字体与语言
  set text(font: 字体.宋体, size: 字号.小五, lang: lang)
  set par(first-line-indent: 0em, spacing: 1.2em, leading: 0.65em)
  // 设置 bullet list 和 enum 的 marker，相比默认更像 markdown，另外刻意调大了一点（适合老年人
  // 关于 spacing，list 和 enum 的 spacing，如果设为 auto，会使用 par 的 leading (tight: true) / spacing，另外 tight 这个值在这里赋是没用的，在 markup mode 下会根据是否空行自动决定（那 tm 开放给 set 又有什么意义。。。）
  set list(marker: ([●], [○], [■], [□], [►]), spacing: 0.8em)
  set enum(numbering: numbly("{1}.", "{2:a}.", "{3:i}."), full: true, spacing: 0.8em)
  // 将 list and enum 用 block 撑开 (for math.equation and figures)
  show: align_list_enum

  // 设置标题
  show heading.where(level: 1): it => {
    set block(spacing: 1em)
    align(center, text(weight: "bold", font: 字体.黑体, size: 18pt, it))
  }
  show heading.where(level: 2): set text(weight: "bold", font: 字体.黑体, size: 14pt)
  show heading.where(level: 3): set text(weight: "bold", font: 字体.黑体, size: 13pt)
  show heading.where(level: 4): set text(weight: "bold", font: 字体.黑体, size: 12pt)
  show heading.where(level: 5): set text(weight: "bold", font: 字体.黑体, size: 11pt)
  set heading(numbering: (..nums) => { // 设置标题编号
    nums.pos().map(str).join(".") + " "
  })
  show heading.where(level: 1): it => it + v(3pt)

  // 行内代码，灰色背景
  show raw.where(block: false): box.with(
    fill: colors.gray,
    inset: (x: 3pt, y: 0pt),
    outset: (y: 3pt),
    radius: 2pt,
  )
  show raw: set text(font: (字体.meslo-mono, 字体.思源宋体)) // 代码中文字体
  show raw.where(block: true): set text(size: 字号.小五 - 2pt)  // 代码块字体小一点
  show raw: it => {
    show regex("pin\d"): it => pin(eval(it.text.slice(3))) // pinit package for raw
    it
  }

  v(1em)

  body
  v(10em)
}
