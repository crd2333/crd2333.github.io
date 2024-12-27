#import "@preview/fletcher:0.5.2" as fletcher: diagram, node, edge
#import "@preview/tablem:0.1.0": tablem
#import "@preview/lovelace:0.3.0": pseudocode-list, pseudocode, line-label
#import "@preview/truthfy:0.5.0": truth-table, truth-table-empty
#import "@preview/codly:1.0.0": *
#import "@preview/timeliney:0.1.0": timeline, headerline, group, taskgroup, task, milestone

// 插入图片
#let fig(alignment: center, ..args) = align(alignment, image(..args))

// 正则捕捉自动设置数学环境，对表格等使用
#let automath_rule = it => {
  show regex("\d+(.\d+)*"): it => $it$
  it
}
// 普通表，包含居中
#let tbl(alignment: center, align_content: center + horizon, automath: false, ..args) = {
  let fig = align(alignment, table(align: align_content, ..args))
  if automath {
    show table.cell: automath_rule
    fig
  } else {fig}
}
// 三线表，包含居中
#let tlt(alignment: center, align_content: center + horizon, automath: false, ..args) = {
  let fig = align(alignment, table(
    stroke: none,
    align: align_content,
    table.hline(y: 0),
    table.hline(y: 1),
    ..args,
    table.hline(),
  ))
  if automath {
    show table.cell: automath_rule
    fig
  } else {fig}
}
// 类 markdown 表格，使用 tablem 实现
#let tblm(alignment: center, align_content: center + horizon, automath: false, ..args) = {
  let fig = align(alignment, tablem(align: align_content, ..args))
  if automath {
    show table.cell: automath_rule
    fig
  } else {fig}
}

// 真值表，使用 truthfy 实现
#let truth-tbl(alignment: center, ..args) = align(alignment, truth-table(..args))
#let truth-tbl-empty(alignment: center, ..args) = align(alignment, truth-table-empty(..args))

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

// 代码块，使用 codly 实现
#let code(body) = [#body]

// icons for codly
#let codly_icon(codepoint) = {
  box(
    height: 1em,
    baseline: 0.1em,
    image(codepoint)
  )
  h(0.2em)
}
#let c_svg = codly_icon("/public/assets/c.svg")
#let cpp_svg = codly_icon("/public/assets/cpp.svg")
#let python_svg = codly_icon("/public/assets/python.svg")
#let rust_svg = codly_icon("/public/assets/rust.svg")
#let java_svg = codly_icon("/public/assets/java.svg")
#let sql_svg = codly_icon("/public/assets/sql.svg")
#let typst_svg = codly_icon("/public/assets/typst.svg")
#let verilog_svg = codly_icon("/public/assets/verilog.svg")

#let diagram(..args) = align(center, fletcher.diagram(
  node-stroke: 1pt,
  edge-stroke: 1pt,
  mark-scale: 70%,
  ..args
))
#let edge(..args, marks: "-|>") = fletcher.edge(..args, marks: marks)
