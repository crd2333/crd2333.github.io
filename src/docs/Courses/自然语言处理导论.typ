#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "自然语言处理导论",
  lang: "zh",
)

= 自然语言处理导论

== Chapter 1
第一节课主要讨论一些基本常识以及简单的课程梗概。

== Chapter 2: Deep Learning Basics
因为比较基础所以没怎么听，但是听到一个有意思的观点：其实现在的大模型相比以前的路子来说更适合叫做 "Wide Learning"，比如 deepseek 才六十几层（虽然每一层内部其实也是个大块），其巨大参数量来自 Transformer 的连接。总之，不再是我以前所了解到的深度无脑优于宽度的情况了。

究其原因，主要还是梯度的问题，继续做深效果没有太大提升了，所以开始往宽拓展了。
