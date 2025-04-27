#import "@preview/fletcher:0.5.5" as fletcher: diagram, node, edge
#import "@preview/tablem:0.2.0": tablem
#import "@preview/lovelace:0.3.0": pseudocode-list, pseudocode, line-label
#import "@preview/truthfy:0.6.0": truth-table, truth-table-empty
#import "@preview/zebraw:0.4.3": *
#import "@preview/timeliney:0.2.0": timeline as timeliney, headerline, group, taskgroup, task, milestone
#import "/src/components/TypstLocal/diagbox/lib.typ": *
#import "/src/components/TypstLocal/admonition/lib.typ": *

// 一些图标
#let icon(path) = box(
  baseline: 0.125em,
  height: 1.0em,
  width: 1.25em,
  align(center + horizon, image(path))
)
#let faAngleRight = icon("/public/assets/icons/fa-angle-right.svg")
#let faAward = icon("/public/assets/icons/fa-award.svg")
#let faBuildingColumns = icon("/public/assets/icons/fa-building-columns.svg")
#let faCode = icon("/public/assets/icons/fa-code.svg")
#let faEnvelope = icon("/public/assets/icons/fa-envelope.svg")
#let faGithub = icon("/public/assets/icons/fa-github.svg")
#let faGraduationCap = icon("/public/assets/icons/fa-graduation-cap.svg")
#let faLinux = icon("/public/assets/icons/fa-linux.svg")
#let faPhone = icon("/public/assets/icons/fa-phone.svg")
#let faWindows = icon("/public/assets/icons/fa-windows.svg")
#let faWrench = icon("/public/assets/icons/fa-wrench.svg")
#let faWork = icon("/public/assets/icons/fa-work.svg")
#let falink = icon("/public/assets/icons/fa-link.svg")
#let fajumplink = icon("/public/assets/icons/fa-jumplink.svg")

// 插入图片
#let fig(alignment: center, ..args) = figure(
  kind: image,
  supplement: none,
  image(..args)
)

// 正则捕捉自动设置数学环境，对表格等使用
#let automath_rule = it => {
  show regex("\d+(.\d+)*"): it => $it$
  it
}
// 普通表，包含居中
#let tbl(alignment: center, align_content: center + horizon, automath: false, ..args) = {
  let fig = figure(
    kind: table,
    supplement: none,
    table(align: align_content, ..args)
  )
  if automath {
    show table.cell: automath_rule
    fig
  } else {fig}
}
// 三线表，包含居中
#let tlt(alignment: center, align_content: center + horizon, automath: false, ..args) = {
  let fig = figure(
    kind: table,
    supplement: none,
    table(
      stroke: none,
      align: align_content,
      table.hline(y: 0),
      table.hline(y: 1),
      ..args,
      table.hline(),
    )
  )
  if automath {
    show table.cell: automath_rule
    fig
  } else {fig}
}
// 类 markdown 表格，使用 tablem 实现
#let tblm(alignment: center, align_content: center + horizon, automath: false, ..args) = {
  let fig = figure(
    kind: table,
    supplement: none,
    tablem(align: align_content, ..args)
  )
  if automath {
    show table.cell: automath_rule
    fig
  } else {fig}
}
// csv 表格，使用 csv 处理转为表格
#let csvtbl(alignment: center + horizon, automath: false, columns: 0, raw) = {
  let data = csv(bytes(raw.text))
  let fig = figure(
    kind: table,
    table(
      columns: if columns == 0 {data.at(0).len()} else {columns},
      align: alignment,
      ..data.flatten()
    )
  )
  if automath {
    show table.cell: automath_rule
    fig
  } else {fig}
}

// 真值表，使用 truthfy 实现
#let truth-tbl(alignment: center, ..args) = figure(
  kind: "table",
  supplement: none,
  truth-table(..args)
)
#let truth-tbl-empty(alignment: center, ..args) = figure(
  kind: "table",
  supplement: none,
  truth-table-empty(..args)
)

// 算法框，使用 lovelace 实现
#let my-lovelace-defaults = (
  line-numbering: "1",
  booktabs: true,
  // stroke: none,
  // hooks: 0.5em,
  indentation: 1.5em,
  booktabs-stroke: 2pt + black,
)
#let pseudocode-list = pseudocode-list.with(..my-lovelace-defaults)
#let algo(title: none, body, ..args) = {
  pseudocode-list(
    title: title + h(1fr),
    body,
    ..args
  )
}
#let comment(body) = {
  h(1fr)
  text(size: .85em, fill: gray.darken(50%), sym.triangle.stroked.r + sym.space + body)
}
#let no-number = [- #hide([])] // empty line and no number

// 代码块，使用 zebraw 实现
#let code(
  body,
  ..args
) = figure(
  kind: raw,
  zebraw(
    body,
    ..args
  )
)

#let diagram(..args) = figure(
  kind: "image",
  supplement: none,
  fletcher.diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    mark-scale: 70%,
    ..args
  )
)
#let edge(..args, marks: "-|>") = fletcher.edge(..args, marks: marks)
