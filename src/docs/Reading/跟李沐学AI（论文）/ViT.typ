// ---
// order: 8
// ---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "d2l_paper",
  lang: "zh",
)

= ViT: Vision Transformer
- 主要论文为 《An Image is Worth 16x16 Words: Transformers for Image Recognition at Scale》
- ViT 是过去一年 CV 最有影响力的工作
  + 推翻了 2012 Alexnet 以来 CNN 在 CV 的统治地位
  + 有足够多的预训练数据，NLP 的 Transformer 直接搬运到 CV，效果也很好（模型迁移）
  + 打破 CV 和 NLP 的壁垒，给 CV、多模态 挖坑

== 标题 & 摘要
- 原本的 CV：Attention + CNN, or Attention 替换 CNN components 但依然保持 CNN 整体结构，但现在是完全的 Transformer
- 标题的意思：每一个方格都是 $16 * 16$ 大小(patch)，用 Transformer 去做大规模的图像识别
- 摘要中说“计算资源消耗少”是相对的概念，实际上还是很大（凡尔赛）
