---
order: 2
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "VAE",
  lang: "zh",
)

= VAE (Variational Autoencoder)
#fig("/public/assets/Reading/limu_paper/DALLE2/2024-10-09-11-40-22.png")
- VAE
  - VAE 学习概率分布，它先假设这个分布符合高斯分布（有点添加语义先验的意思），于是 VAE 的 encoder 部分的学习目标简化成学习高斯分布的均值和方差
  - 具体方法如下：
    + 原始图片 $x$ encode 之后经过 FC 层预测得到均值 $mu$、方差 $sigma$
    + 从该高斯分布采样得到 $z$
    + 通过 decoder 生成 $x'$，训练目标是 $x'$ 逼近 $x$
  - 整个过程从数学上看比较优雅。第一步，从 $x$ 得到 $z$，可以写作 $P(z|x)$，是（$z$ 的）后验概率。中间的 $P(z)$ 是先验概率 prior。后面一步可以写作 $P(x'|z)$，是 likelihood
  - VAE 提出之后，有很多基于它的工作，包括 VQ-VAE、VQ-VAE2 等。DALLE-1 就是在 VQ-VAE 的基础上做的
- VQ-VAE
  - VQ 的含义是 Vector Quantised，就是把 VAE 做量化
  - 虽然现实世界的很多信号，例如语音、图像等都是连续信号，但是我们在计算机处理它们时大多已经把它们处理成离散信号，那不如干脆就做离散任务。VQ-VAE 把针对连续信号的回归任务转化成针对离散信号的分类任务，把高斯连续分布的先验转化成 codebook 的离散分布先验
  - 在 VQ-VAE 中，不是直接学习中间变量的分布，而是用一个 codebook 代替它。codebook 的大小是 $K * D$(e.g. $8192 * 512$)。codebook 存储的向量可以理解为聚类的中心，也可以看作是 embedding（$K$ 个长度为 $D$ 的 embedding向量）
  - $x$ encode 之后得到特征图 $f$，$f$ 中的每一维向量都从 codebook 中找一个离它最近的向量 $D$ 替换，这样得到量化之后的特征向量 $f_c$，和原始特征图 $f$ 维度一样，语义相似，只不过它的元素取值只能从 codebook 中来，相当于缩小了空间
