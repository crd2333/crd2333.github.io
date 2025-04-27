---
order: 1
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GAMES104 笔记",
  lang: "zh",
)

- #link("https://games104.boomingtech.com/sc/course-list/")[GAMES104] 可以参考这些笔记
  + #link("https://www.zhihu.com/column/c_1571694550028025856")[知乎专栏]
  + #link("https://www.zhihu.com/people/ban-tang-96-14/posts")[知乎专栏二号]
  + #link("https://blog.csdn.net/yx314636922?type=blog")[CSDN 博客]（这个写得比较详细）
- 这门课更多是告诉你有这么些东西，但对具体的定义、设计不会展开讲（广但是浅，这也是游戏引擎方向的特点之一）
- 感想：做游戏引擎真的像是模拟上帝，上帝是一个数学家，用无敌的算力模拟一切。或许我们的世界也是个引擎？（笑
- [ ] TODO: 有时间把课程中的 QA（课后、课前）也整理一下

#let QA(..args) = note(caption: [QA], ..args)

= 游戏引擎导论

= 引擎架构分层

= 如何构建游戏世界
#QA(
  [物理和动画互相影响的时候怎么处理],
  [一个比较典型的问题，更多算是业务层面的问题而不是引擎层面，但引擎也要对这种 case 有考虑。以受击被打飞为例，被打到的一瞬间要播放受击动画，击飞后要考虑后续的物理模拟。这么剖析的话怎么做也已经呼之欲出了，也就是做一个权重的混合，一开始是动画的占比较大，把动画的结果作为物理的初始输入，越到后面物理模拟的占比增大（更深入一点，就是 FK 和 IK 的权重变化）。最终能做到受击效果跟预定义的动画很像，但后续的动作变化也很物理、合理。]
)
