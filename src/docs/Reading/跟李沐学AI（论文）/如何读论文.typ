---
order: 1
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "d2l_paper",
  lang: "zh",
)

- 李沐的 d2l 课程看完了，但是比较粗略，而且没怎么记笔记，但总归对代码更加熟悉了
- 李沐的读论文系列则希望更加深入地去理解，稍微做点笔记，不会太详细（对着视频一句句抄），而主要对不懂的东西做记录
- 部分内容源自 #link("https://github.com/CSWellesSun/CSNotes/tree/8e3e33b111c2ad7fc098d3ec40b7616fa6eb7635/%E8%B7%9F%E6%9D%8E%E6%B2%90%E5%AD%A6AI")[CSWellesSun 的笔记]

= 如何阅读论文
- 一般的结构
1. title
2. abstract
3. introduction
4. method
5. experiment
6. conclusion

- 三遍读
  + 第一遍：标题摘要结论。可以看一眼 experiment 中的图表，瞄一眼 method
  + 第二遍：对整个文章过一遍，证明公式忽略，图表要细看，和其他人工作的对比，圈出引用的文章。
  + 第三遍：每句话都要理解，如果是我来做应该怎么做，哪些地方可以往前做