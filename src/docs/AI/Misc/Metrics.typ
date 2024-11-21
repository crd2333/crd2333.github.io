#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Metrics",
  lang: "zh",
)

= Introduction
- Metrics，直接翻译作“韵律学”，在 AI, ML, DL 领域指的是一种评价指标，衡量模型输出的好坏
- Metrics 和 Loss functions 有什么区别？
  - 前者更注重评判模型，后者更注重可微性并通过求梯度、反向传播来指导模型训练
  - 但是其实大差不差，有时候如果 metrics 可微性够好，都直接拿来当 loss 用，这里我不会对它们做显式区分。本文之所以取名为 metrics，主要是因为更 fashion（x
- 因此，如同 RL 那边的评价函数一样，好的指标直接指导了模型训练和优化的方向，甚至直接决定了模型可否训练
  - 比如，通过加入正则项，能够减轻模型过拟合的风险
  - 又比如，监督信息强弱不同有时直接影响模型会不会崩，比如使用 image-level 还是 pixel-level 的信息
- 在这个页面，我想要先介绍一些常用的 metrics(losses)，然后记录一些“现代”论文里经常用到的 metrics(losses)

- 先贴几个链接
  + #link("https://zhuanlan.zhihu.com/p/476927099")[Evaluation metrics——机器学习中常见的评估指标]
  + #link("https://zhuanlan.zhihu.com/p/206470186")[论文阅读：[CVPR 2018] 图像感知相似度指标 LPIPS]
  + #link("https://zhoutimemachine.github.io/note/readings/miscs/metrics/")[学长的笔记]
- [ ] todo

