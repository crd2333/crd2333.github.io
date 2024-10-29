// ---
// order: 8
// ---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "d2l_paper",
  lang: "zh",
)

= An Image is Worth 16x16 Words: Transformers for Image Recognition at Scale)
- 时间：2020.10
- ViT: Vision Transformer
- ViT 是过去一年 CV 最有影响力的工作
  + 推翻了 2012 Alexnet 以来 CNN 在 CV 的统治地位
  + 有足够多的预训练数据，NLP 的 Transformer 直接搬运到 CV，效果也很好（模型迁移）
  + 打破 CV 和 NLP 的壁垒，给 CV、多模态 挖坑

== 标题 & 摘要
- 原本的 CV：Attention + CNN, or Attention 替换 CNN components 但依然保持 CNN 整体结构，但现在是完全的 Transformer
- 标题的意思：每一个方格都是 $16 * 16$ 大小(patch)，用 Transformer 去做大规模的图像识别
- 摘要中说“计算资源消耗少”是相对的概念，实际上还是很大（凡尔赛）

== 引言 & 相关工作
- Transformers 是目前 NLP 必选模型，主流方式是 BERT 提出的在大规模数据集预训练，在特定领域小数据集做微调。即使在 $5300$ 亿参数的模型中也还没看到饱和现象
- Transformer 应用在 CV 的难点：计算复杂度是 $O(n^2)$，$224$ 分辨率的图片，有 $50176$ 个像素点（2d 图片 flatten），序列长度是 BERT 的近 $100$ 倍
  - 于是自然的想法是，先用卷积抽特征，把变小的特征图再送进 Transformer，如 CVPR Wang et al. 2018, Local Network
  - 另外一种思路是把卷积层整个替换（换句话说，ViT 并不是首个用 Attention 完全替换 CNN 的）：
    + stand-alone attention 孤立自注意力：用 local window 控制 transformer 的计算复杂度（类似卷积也有 locality）
    + axial attention 轴注意力：复杂度来自于 $n = H * W$，于是可以用 $2$ 个 1d 自注意力，先把 2d 矩阵拆分为两个 1d 向量，再分别对 $H$ 和 $W$ 做自注意力
  - 但是这种特殊 Attention 不够通用，因此还没能规模做大
  - 而 ViT 这篇论文就是把图像分成 $16 * 16$ 的 patch，然后直接送进 Transformer，这样就能规模化了。这个思路很简单，之前也有人做过，但区别在于 ViT 团队更有钱，之前那篇工作只在 CIFAR-10 上做了 $2 * 2$ 的 patch
- 结果：在同等规模下，ViT 比 ResNet 还是弱不少，因为少了归纳偏置(inductive bias)即人为结构性先验知识（比如卷积的 locality 和 translation equlity）；但是在大规模下能比 ResNet 相当或更强

- *相关工作*章节里还涉及到其它的一些，这里就不展开了

== 方法
- 模型总览图
  - 把图片切成 patch，过一个全连接层，然后加上（相加而非连接）可学习的 position encoding
  - （借鉴 BERT）加了个 extra token
  - 然后送进 Transformer Encoder，用这个 extra token 输出的特征过一个 MLP 来做分类
  #fig("/public/assets/Reading/limu_paper/ViT/2024-09-23-23-21-08.png")
- Positional Encoding: 1d, 2d, relative
  - 1d, 2d, relative 均可，按理说 2d 更符合图像设定，但消融实验结果差不多
  - 1d 位置编码：图上画的是 1234 这种数字，但实际上类似于一个表，每个对应一个 $D$ 维向量
  - 2d 位置编码：横纵坐标各用 $D/2$ 的向量表示，然后 concat 起来
  - 相对位置编码：顾名思义用相对位置查表
- 如何分类
  - 以前的 CNN 都是得到多个通道的特征图之后，做个 global average pooling 得到一个向量，然后预测特征，这里其实也可以这么做
  - 这里采用 BERT 那种额外 `<cls>` 的方法，其实效果都差不多，不过作者为了更接近原始 Transformer 用了这种方式（不想让人觉得效果好是针对 CV 的某些 trick 带来的）
- 关于 fune-tune
  - transformer 是可以微调变长数据的，但是 ViT 由于用了学习的位置编码，这导致如果 patch size 不变的话，序列长度变化会使得位置编码不够用了，这时做个简单的上采样/差值可以一定程度解决问题

== 实验
- 几个模型与命名
  #tlt(
    columns: 6,
    [Model], [Layers], [Hidden size $D$], [MLP size], [Heads], [Params],
    [ViT-Base], [12], [768], [3072], [12], [86M],
    [ViT-Large], [24], [1024], [4096], [16], [307M],
    [ViT-Huge], [32], [1280], [5120], [16], [632M],
  )
- 最重要的图：在小的数据集上 ViT 不如 ResNet，在大数据集上相近
  #fig("/public/assets/Reading/limu_paper/ViT/2024-09-24-16-39-43.png")
- 和 CNN 大模型比，分数都很高，而 Transformer 训练成本相对低一些
  #fig("/public/assets/Reading/limu_paper/ViT/2024-09-24-16-55-39.png")
- 自监督实验
  - 遮住某个 patch 去预测
  - 效果还可以，但比有监督预训练还是差了不少。后来 MAE 使用自监督来训练 ViT 效果非常好

== 结论
- 和其它 self-attention in CV 的工作不同：除了将图片转成 $16 * 16$ patches + 位置编码之外，没有额外引入图像特有的 inductive bias。好处是不需要对 vision 领域的了解，不需要 domain knowledge
- NLP 中大的 Transformer 模型使用*自监督*预训练，ViT 做了简单的 initial experiments 证明自监督预训练也不错，但和有监督训练 still large gap
- 挖坑
  - 新模型 ViT，Transformer 成为 CV 领域的一个通用的骨干网络(backbone)
  - 新问题 —— Transformer for CV 除了 image classfication 其他的任务，分割、检测
  - 新方向 —— 自监督的预训练方式；以及多模态，用一个 Transformer 处理 CV 和 NLP

#info()[
  - DETR (Carion et al. 2020) 目标检测的力作，改变了目标检测出框的方式。证明 ViT 做其它 CV 任务效果也很好
  - 2020年 12 月(ViT 1.5月之后)
    + ViT-FRCNN 检测 detection
    + SETR 分割 segmentation（CVPR 论文，11.15 完成写作投稿）
    + （3个月后）Swin Transformer 融合 Transformer 和多尺度设计
  - 作者团队自己：ViT-G，把 ViT 变得很大，把 ImageNet 刷到 $90%+$
]
