// ---
// order: 4
// ---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "d2l_paper",
  lang: "zh",
)

#let softmax = math.op("softmax")
#let QKV = $Q K V$
#let qkv = QKV
#let Concat = math.op("Concat")
#let MultiHead = math.op("MultiHead")
#let Attention = math.op("Attention")
#let head = $"head"$
#let dm = $d_"model"$
#let FFN = math.op("FFN")

= Transformer(Attention is All You Need)
== 创新点

#grid(
  columns: 2,
  grid.cell(align: left)[
    - seq2seq 模型一般使用 encoder-decoder 结构，过去的一些工作使用 CNN 和 RNN 辅以 seq2seq 模型，而 Transformer 模型则完全基于 attention 机制，并且效果很好。另外，自注意力机制很重要，但并不是本文第一次提出
    - 卷积好的地方在于可以做多个输出通道，每个输出通道认为是识别一种特定的模式。Transformer 吸收这一思想而提出 multi-head 概念
    - 可以看到，Tranformer 的特点在于并行度高但计算消耗大
  ],
  fig("/public/assets/Reading/limu_paper/img-2024-09-16-23-42-29.png")
)

== 模型结构
- 总体模型架构
#grid2(
  fig("/public/assets/Reading/limu_paper/img-2024-09-16-23-42-29.png.png"),
  fig("/public/assets/Reading/limu_paper/2024-09-19-11-34-06.png"),
)
- 左边是编码器右边是解码器，解码器之前的输出作为当前的输入（所以这里最下面写的是output）
- Nx 表示由 $N$ 个 Block 构成，字面意思上的堆叠，最后一层 encoder 的输出将会作为每一层 decoder 的输入
- 一共有三种 Attention，但区别之在于输入 #qkv 来源以及 Attention score 是否采用掩码
- 具体注意力的计算，一般有两种做法，一种是如果 #qkv 长度不同可以用 addictive attention（可学参数较多）；另一种是如果长度相同可以用 scaled dot-product attention

=== 形状解释与步骤细分
#grid2(
  fig("/public/assets/Reading/limu_paper/img-2024-09-16-23-55-54.png"),
  fig("/public/assets/Reading/limu_paper/img-2024-09-16-23-56-14.png")
)
- 首先是 Q K V 的形状
$
Q: RR^(n times d_k), K: RR^(m times d_k), V: RR^(m times d_v)
$
$K, V$ 个数成配对，$Q, K$ 长度都为 $d_k$ 允许 scaled dot-product attention。

- 对单个注意力头而言，经过
$
Attention(Q, K, V) = softmax((Q K^T) / sqrt(d_k))V
$
中间 $Q, K$ 得到形状为 $n times m$ 的矩阵，表示 $n$ 个 query 对 $m$ 个 key 的相似度，经过 (masked) softmax 后与 $V$ 相乘，得到了 $n times d_v$ 的输出，也即对每个 query，我们都得到了 $V$ 的某种加权平均。这里除以 $sqrt(d_k)$ 的原因是：算出来的权重差距较大，经过 softmax 后 $1, 0$ 差距悬殊，采用这个数字从实践上刚好适合。

- 对多头注意力而言
$
MultiHead(Q, K, V) = Concat(head_1, head_2, ..., head_h)W^O \
"where" head_i = Attention(Q W_i^Q, K W_i^K, V W_i^V)
$
令 $h=8$ 也就是有 8 个头，论文中 $dm=512$ 指的是多头拼接后的向量长度，于是 $d_k = d_v = dm \/ h = 64$，每次我们把 #QKV 经过 Linear 从 $512$ 变为 $64$，然后再在最后一维 concat 起来，最后再经过一个 Linear 从 $512$ 到 $512$。实际上点积型 attention 的注意力层可学的参数就在 Linear 中，我们希望将它分出 $h$ 个通道让它在不同的语义空间上学习不同的模式。

- 然后是 Position-wise Feed-Forward Networks
$
FFN(x) = max(0, x W_1 + b_1)W_2 + b_2
$
#grid(
  columns: 2,
  [
    经过（自或交叉）注意力后，再经过 concat 和 Linear 后将通道融合得到 $n times dm$ 的输出，随后经过两层全连接层，从 $dm$ 到 $d_(f f)=2048$，再从 $d_(f f)$ 到 $dm$。这里的 Position-wise 的是说，每个样本用的是同一个 MLP（而不是真的全连接）。可以这么想：通过注意力层学到了不同 query 的语义特征（汇聚所有我感兴趣的信息），然后用同一个 MLP 将它们做变换（但 query 之间不能融合）来减少参数量并一定程度有助于泛化
  ],
  fig("/public/assets/Reading/limu_paper/img-2024-09-17-00-47-10.png")
)
当然上图是训练的时候（$n$ 个 query 并行），测试的时候则是一个个来，但依旧是同一个 MLP，有点像 RNN

=== Batch Norm & Layer Norm
- BatchNorm，在train的时候，一般是取小批量里的均值和方差，在预测的时候用的是全局的均值和方差。#link("https://zhuanlan.zhihu.com/p/24810318")[什么是批标准化 (Batch Normalization) - 知乎]
- 在输入为变长的情况下我们不使用 BatchNorm，而是使用 LayerNorm
  #fig("/public/assets/Reading/limu_paper/2024-09-19-11-45-41.png")

- 一个简单的记法：xxx-norm 就是按 xxx 方向进行归一化，或者说按 xxx 方向切，还可以说是不分解 xxx。对于二维和三维的 xxx-norm 都是适用的。
- 以 batch-norm 为例，二维就是顺着 batch 方向切，即纵切；三维需要注意，一定保留了序列方向不被分解，再结合按照 batch 方向切，就得出了蓝色框切法
- 而 Layer-norm 顺着 Layer 的方向，在这里就是 seq 方向切，即横切
  #fig("/public/assets/Reading/limu_paper/2024-09-19-12-11-20.png")
