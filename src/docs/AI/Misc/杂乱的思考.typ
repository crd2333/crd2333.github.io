#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "misc",
  lang: "zh",
)

= 一些杂乱的思考
== Embedding: add / concat?
- 总是在疑惑，embedding 什么时候用加法，什么时候用拼接
  - 从直觉上来看，似乎加法很容易扰乱数据原本的信息但不会增大模型复杂度；而拼接则恰好想法
  - 可以参考这个问答 #link("https://www.zhihu.com/question/374835153")[为什么 Bert 的三个 Embedding 可以进行相加？]如果我们把 embbeding 理解成 one-hot 为输入的单层全连接，那么是可以等效的，区别只是全连接映射的权重不同
  - 因此更多还是看具体任务、看实验效果、看老中医的经验（x

