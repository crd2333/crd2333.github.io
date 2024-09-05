---
order: 1
---

#set page(margin: 1em, height: auto)
#let typst  = {
  text(font: "Linux Libertine", weight: "semibold", fill: eastern)[typst]
}

#set text(font: "/public/fonts/LXGWWenKaiMono-Regular.ttf")

= Typst 笔记

== #typst: Compose paper faster

$ cases(
dot(x) = A x + B u = mat(delim: "[", 0, 0, dots.h.c, 0, - a_n; 1, 0, dots.h.c, 0, - a_(n - 1); 0, 1, dots.h.c, 0, - a_(n - 2); dots.v, dots.v, dots.down, dots.v, dots.v; 0, 0, dots.h.c, 1, - a_1) x + mat(delim: "[", b_n; b_(n - 1); b_(n - 2); dots.v; b_1) u,

y = C x = mat(delim: "[", 0, 0, dots.h.c, 1) x
) $

#import "@preview/tablem:0.1.0": tablem

#tablem[
  | *English* | *German* | *Chinese* | *Japanese* |
  | --------- | -------- | --------- | ---------- |
  | Cat       | Katze    | 猫        | 猫         |
  | Fish      | Fisch    | 鱼        | 魚         |
]

等解决文件读取问题后可以用 tag 语法来分类，不对，用文件夹分类明显更好，这是笔记不是博客

#text(font: "LXGW WenKai Mono")[中文测试]

#text(font: "/public/fonts/LXGWWenKaiMono-Regular.ttf")[中文测试]