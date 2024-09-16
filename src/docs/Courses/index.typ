#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: none,
  lang: "zh",
)

- 很多笔记都是用 typst 写的而不是 md，由于 typst 是个比较新兴的标记语言，对 html 导出做得不够好（或者说官方压根还不支持）。使用社区自制方案以 svg 导出，会有明显的卡顿。
- 同时，目前也没有足够好的像 MkDocs 之于 Markdown 那样的模板。
