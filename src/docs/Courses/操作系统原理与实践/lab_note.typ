---
draft: true
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "实验笔记",
  lang: "zh",
)

= RISCV 汇编
- 汇编文件的后缀是 `.s` 或 `.S`。
- 参考
  + #link("https://lgl88911.github.io/2021/02/28/RISC-V%E6%B1%87%E7%BC%96%E5%BF%AB%E9%80%9F%E5%85%A5%E9%97%A8/")[RISC-V汇编快速入门]
  + #link("https://mp.weixin.qq.com/s/jyI-SSm_5Gg-KQyjKsIj5Q")[RISC-V嵌入式开发入门篇2：RISC-V汇编语言程序设计（上）]
  + #link("https://zhuanlan.zhihu.com/p/337147166")[RISC-V 汇编语言程序设计基础简析]

- 一些常见的写法已经很熟悉，这里不再赘述，如
  ```
  start:
    bnez  x1, dummy
    beq   x0, x0, pass_0
    li    x31, 0
    auipc x30, 0
    j     dummy
  ```
- 主要关注伪操作


= 链接脚本
- 链接脚本的后缀是 `.ld` 或 `.lds`。
- 参考
  + #link("https://zhuanlan.zhihu.com/p/504742628")[ld - 链接脚本学习笔记与实践过程]
  + #link("https://www.cnblogs.com/jianhua1992/p/16852784.html")[链接脚本(Linker Scripts)语法和规则解析（翻译自官方手册）]