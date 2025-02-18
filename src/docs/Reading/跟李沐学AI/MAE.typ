---
order: 9
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "d2l_paper",
  lang: "zh",
)

= Masked Autoencoders Are Scalable Vision Learners
- 时间：2021.11

== 标题 & 摘要 & 引言 & 相关工作
- 标题：Masked Autoencoders Are Scalable Vision Learners
- 与之前读的文章的关系
  - Transformer：纯基于注意力机制的编码器和解码器，在机器翻译任务上，它比基于RNN的架构要更好一些
  - BERT：使用一个 Transformer encoder，拓展到了更一般的 NLP 任务上。使用完形填空的*自监督*的训练机制，这样就不需要使用标号，而是通过预测一个句子里面哪些词不见了，从而获取对文本特征抽取的能力。BERT 极大地扩展了 Transformer 的应用，可以在一个大规模无标号的数据上训练出非常好的模型
  - ViT：将 Transformer 用到 CV 上，将整个图片分割成很多个 $16*16$ 的 patch，放进 Transformer 进行训练。ViT 这篇文章证明：假设训练数据足够大，相对于 CNN 的架构来说，ransformer 架构上限可能高一点
  - MAE：可以认为是 BERT 的 CV 版。基于 ViT 这篇文章，把整个训练拓展到没有标号的数据上面，通过完形填空来获取对于图片的理解。MAE 并不是第一个将 BERT 拓展到 CV 上的工作，但是很有可能是这一系列工作之中影响力最大的一篇
- 标题中 Auto 表示标号和样本来自同一个东西，在语言领域基本都是 auto，但是在 CV 领域比较难做到 auto，一般是另外标注的内容
- 论文技巧：
  + 在写论文的时候假设算法特别快的话，就写 efficient，假设做的东西比较大，就叫 scalable，二选一来使得文章更有 B 格
  + 标题是一句浓缩后的结论（“什么是一个好同志”），非常强有力的句式，比较客观适合当标题
- CV 和 NLP 领域 Masked Autoencoder 不同的原因
  + CNN里的卷积窗口不太好做掩码，因为在 NLP 里面一个 mask 是一个特定的词，但在 CV 里就是（某个像素）转化成一个值，卷积窗口不好识别；而且也不好加入位置信息（但是卷积其实自带位置信息）。不过现在随着 ViT 的出现这些都不是问题了
  + 两者的信息密度不同。语言高度语义化，但图片中有很多冗余甚至可以通过插值还原，解决方法为高比例掩码，迫使模型学习到更有用的信息
  + 解码器的职责不同。在 NLP 中 decoder 只要一个全连接层就可以了，但是 CV 中就比较困难（在 NLP 中，需要还原到词，相对来说在语义层面上比较高一点；而在 CV 中，需要还原到输入也就是原始像素，相对来说是一个比较低层次的表示）
- 相关工作
  + masked language model，BERT and GPT
  + autoencoding in CV，MAE 也是一种形式上的带去噪的自编码，但跟 GAE 还是很不一样的
  + masked image in encoder，比如 iGPT, BEiT
  + self-supervised learning，之前比较火的是 contrastive learning 和数据增强，autoencoder 是另一种路线
  - 提了几个比较大的话题，但没有展开去讲到底有何不同。写作上的建议，最好还是明明白白写出来不要让人去猜

== 方法
- 两个核心的设计
  + 非对称的 encoder-decoder 架构
    - 虽然是一个 Autoencoder 架构，但实际上任何模型都有一个 encoder 和一个 decoder。比如说在 BERT（虽然号称 encoder-only） 中的 decoder 就是最后一个全连接输出层，因为 BERT 预测的东西相对来讲比较简单，所以一个简单的全连接层足矣；但是 CV 中相对复杂，因为需要预测一个 patch 中的所有像素
    - encoder 只作用在可见的 patch 中，对 encoder 这样巨大的模块来说，节省计算成本
    - decoder 比较轻量，能够重构原始的图片
  + 如果只是遮住几块的话，进行插值足矣，模型可能学不到特别的东西；而如果遮住大量的块（比如说把 $75%$ 的块全部遮住），则会得到一个非显然的而且有意义的自监督任务，迫使模型去学习一些更好的特征
- 具体实现
  + Masking：随机采样一些块进行保留，剩下的盖住
  + MAE encoder：用 ViT 的 encoder，把每个可见块拿出来线性投影，加上位置信息
  + MAE decoder：会看到两部分信息：一是变成潜表示的可见块，二是同一向量表示的可学习掩码块，都加上位置信息，送入 Transformer decoder 里。decoder 只在预训练时使用，把它恢复成原始图片
  + Reconstruct target：全连接层输出到 $256$ 维，reshape 成 $16*16$。损失函数为 MSE，只在掩码块上做。然后还提到 normalization 的一个小优化
  + Simple implementation：首先我们通过线性投影和位置编码得到一系列 patch 的 tokens，然后 random shuffle 一下，取出前(e.g.)$25%$ 送入 encoder，用可学习的 mask token 把结果 append 到同样长度，再 unshuffle 回去，加上位置编码并送入 decoder，之后再 reconstruct targets。整个过程避免了稀疏操作非常高效
  #fig("/public/assets/Reading/limu_paper/MAE/2024-09-29-14-55-07.png")

= 实验 & 结论
- 先在 ImageNet-1K（100万张图片）上自监督预训练，然后再应用到下游任务（不用 decoder 复原而是拿去分类）进行有监督地微调(fune-tuning or linear probing)
- Baseline 是 ViT-large + 各种新 technique 使得在小数据集上也奏效的版本（甚至精度更高，从 $72.5%$ 提升到了 $82.5%$）。然后如果先使用 MAE 做预训练，然后再在ImageNet-1K 上做微调，提升到了 $84.9%$
- 各种 ablation study
  + decoder 的深度（辅以 fune-tuning or linear probing）
  + decoder 的宽度，$512$ 比较好
  + 在 encoder 中要不要加入被盖住的那些块，不加比较好
  + 重构时候的目标：简单版本、*正则化版本*、PCA 版本、dVAE 版本（像 BERT 一样做预测）
  + 数据增强：MAE 对 data augmentation 不那么敏感
  + 采样方法：最简单的随机最好
- 然后还有 掩码率、训练时间、掩码采样策略、预训练的轮数(fune-tuning or linear probing)、不同的超参数 等等图片
- 评论：MAE 的算法还是非常简单的，就是利用 ViT 来做和 BERT 一样的自监督学习，ViT 已经做了类似的事情了，但是本文在此基础之上提出了几点
  + 需要盖住更多的块，使得剩下的那些块，块与块之间的冗余度没有那么高，这样整个任务就变得复杂一点
  + 使用一个 Transformer 架构的解码器，直接还原原始的像素信息，使得整个流程更加简单一点
  + 加上 ViT 工作之后的各种技术，使得它的训练更加鲁棒一点
