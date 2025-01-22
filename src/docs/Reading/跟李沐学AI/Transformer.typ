// ---
// order: 4
// ---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "d2l_paper",
  lang: "zh",
)

#let QKV = $Q K V$
#let qkv = QKV
#let head = $"head"$
#let dm = $d_"model"$
#let PE = math.text("PE")

= Attention is All You Need
- 时间：2017.6

== 创新点
#grid(
  columns: 2,
  grid.cell(align: left)[
    - seq2seq 模型一般使用 encoder-decoder 结构，过去的一些工作使用 CNN 和 RNN 辅以 seq2seq 模型，而 Transformer 模型则完全基于 attention 机制，并且效果很好。另外，自注意力机制很重要，但并不是本文第一次提出
    - 卷积好的地方在于可以做多个输出通道，每个输出通道认为是识别一种特定的模式。Transformer 吸收这一思想而提出 multi-head 概念
    - 可以看到，Tranformer 的特点在于并行度高但计算消耗大
  ],
  fig("/public/assets/Reading/limu_paper/Transformer/img-2024-09-16-23-42-29.png", width: 90%)
)

== 模型结构
- 总体模型架构
#grid2(
  fig("/public/assets/Reading/limu_paper/Transformer/img-2024-09-16-23-42-29.png.png", width: 80%),
  fig("/public/assets/Reading/limu_paper/Transformer/2024-09-19-11-34-06.png"),
)
- 左边是编码器右边是解码器，解码器之前的输出作为当前的输入（所以这里最下面写的是output）
- Nx 表示由 $N$ 个 Block 构成，字面意思上的堆叠，最后一层 encoder 的输出将会作为每一层 decoder 的输入
- 一共有三种 Attention，但区别之在于输入 #qkv 来源以及 Attention score 是否采用掩码
- 具体注意力的计算，一般有两种做法，一种是如果 #qkv 长度不同可以用 addictive attention（可学参数较多）；另一种是如果长度相同可以用 scaled dot-product attention

=== 形状解释与步骤细分
#grid2(
  fig("/public/assets/Reading/limu_paper/Transformer/img-2024-09-16-23-55-54.png", width: 70%),
  fig("/public/assets/Reading/limu_paper/Transformer/img-2024-09-16-23-56-14.png", width: 70%)
)
- 首先是 Q K V 的形状
  $
  Q: RR^(n times d_k), K: RR^(m times d_k), V: RR^(m times d_v)
  $
  - $K, V$ 个数成配对，$Q, K$ 长度都为 $d_k$ 允许 scaled dot-product attention

- 对单个注意力头而言，经过
  $
  Attention(Q, K, V) = softmax((Q K^T) / sqrt(d_k))V
  $
  - 中间 $Q, K$ 得到形状为 $n times m$ 的矩阵，表示 $n$ 个 query 对 $m$ 个 key 的相似度
  - 经过 (masked) softmax 后与 $V$ 相乘，得到了 $n times d_v$ 的输出，也即对每个 query，我们都得到了 $V$ 的某种加权平均
  - 这里除以 $sqrt(d_k)$ 的原因是：算出来的权重差距较大，经过 softmax 后 $1, 0$ 差距悬殊，采用这个数字从实践上刚好适合
- 对多头注意力而言
  $
  MultiHead(Q, K, V) = Concat(head_1, head_2, ..., head_h)W^O \
  "where" head_i = Attention(Q W_i^Q, K W_i^K, V W_i^V)
  $
  - 令 $h=8$ 也就是有 8 个头，论文中 $dm=512$ 指的是多头拼接后的向量长度，于是 $d_k = d_v = dm \/ h = 64$，每次我们把 #QKV 经过 Linear 从 $512$ 变为 $64$，然后再在最后一维 concat 起来，最后再经过一个 Linear 从 $512$ 到 $512$
  - 实际上 dot-product attention 的注意力层可学的参数就在 Linear 中，我们希望将它分出 $h$ 个通道让它在不同的语义空间上学习不同的模式

- 然后是 Position-wise Feed-Forward Networks
  $
  FFN(x) = max(0, x W_1 + b_1)W_2 + b_2
  $
  #grid(
    columns: 2,
    [
      - 经过（自或交叉）注意力后，再经过 concat 和 Linear 后将通道融合得到 $n times dm$ 的输出
      - 随后过两个全连接层，从 $dm (512) -> d_(f f) (2048) -> dm (512)$
      - 这里的 Position-wise 的是说，每个样本用的是同一个 MLP（而不是真的全连接）
        - 可以这么想：通过注意力层学到了不同 query 的语义特征（汇聚所有我感兴趣的信息），然后用同一个 MLP 将它们做变换（但 query 之间不能融合）来减少参数量，并且一定程度上有助于泛化
    ],
    fig("/public/assets/Reading/limu_paper/Transformer/img-2024-09-17-00-47-10.png")
  )
  - 当然上图是训练的时候（$n$ 个 query 并行），测试的时候则是一个个来，但依旧是同一个 MLP，有点像 RNN

=== 位置编码
- 参考
  + #link("https://zhuanlan.zhihu.com/p/352233973")[详解自注意力机制中的位置编码（第一部分）]
  + #link("https://zhuanlan.zhihu.com/p/354963727")[详解自注意力机制中的位置编码（第二部分）]
  + #link("https://zhuanlan.zhihu.com/p/454482273")[Transformer 学习笔记一：Positional Encoding（位置编码）]
  + #link("https://kexue.fm/archives/8130")[让研究人员绞尽脑汁的 Transformer 位置编码]
- Transformer 中的位置编码
  $ PE_(t,2i) &= sin(t/10000^(2i\/d)), \ PE_(t,2i+1) &= cos(t/10000^(2i\/d)) $
  - 即采用 $sin, cos$ *交替*的方式做*固定位置编码*，在波长上形成了从 $2pi$ 到 $10000 dot 2pi$ 的*几何级数*
  - 它有两个性质
    + 两个位置编码的点积可以反应出*两个位置编码间的距离*（因此虽然是绝对位置编码，但多少也携带了一些相对位置信息）；用一个不依赖于 $t$ 而是依赖于 $De t$ 的线性变换矩阵可以把 $t$ 位置变换到 $t+De t$ 位置
    + 位置编码的点积是*无向的*
  - 采用*外置位置编码*的形式，可以推出*标准 Transformer 的自注意力机制*如下
    $
    q_i &= (x_i + p_i) W_Q \
    k_j &= (x_j + p_j) W_K \
    v_j &= (x_j + p_j) W_V \
    a_(i,j) &= softmax((q_i k_j^T) / sqrt(d_k)) \
    o_i &= sum_j a_(i,j) v_j
    $
- 其它位置编码，可以大体这样分类（个人理解）
  - 根据位置编码的可学习与否
    + 固定位置编码：直接使用固定方式产生的位置编码，不参与训练
    + 可学习位置编码：位置编码作为模型的一部分，参与训练
  - 根据位置编码加入的形式
    + 外置位置编码：位置编码直接加到模型输入上
    + 内置位置编码：位置编码加到模型的某一层中，比如作为模型权重的 bias（可学习）
  - 根据位置关系
    + 绝对位置编码：考虑绝对位置
    + 相对位置编码：仅靠虑相对位置

=== Batch Norm & Layer Norm
- BatchNorm，在train的时候，一般是取小批量里的均值和方差，在预测的时候用的是全局的均值和方差。#link("https://zhuanlan.zhihu.com/p/24810318")[什么是批标准化 (Batch Normalization) - 知乎]
- 在输入为变长的情况下我们不使用 BatchNorm，而是使用 LayerNorm
  #fig("/public/assets/Reading/limu_paper/Transformer/2024-09-19-11-45-41.png")

- 一个简单的记法：xxx-norm 就是按 xxx 方向进行归一化，或者说按 xxx 方向切，还可以说是不分解 xxx。对于二维和三维的 xxx-norm 都是适用的
- 以 batch-norm 为例，二维就是顺着 batch 方向切，即纵切；三维需要注意，一定保留了序列方向不被分解，再结合按照 batch 方向切，就得出了蓝色框切法
- 而 Layer-norm 顺着 Layer 的方向，在这里就是 seq 方向切，即横切
#fig("/public/assets/Reading/limu_paper/Transformer/2024-09-19-12-11-20.png")
- 但事实上好像这种理解还是有问题，似乎文本的 LN 是一行而不是一个面

- 关于 BN 和 LN 以及它们的代码可以参考 #link("https://zhuanlan.zhihu.com/p/656647661")[对比pytorch中的BatchNorm和LayerNorm层]
- 文本中的 LayerNorm 本质上是一种 InstanceNorm

#note(caption: "Group Norm")[
  实际上还有一个更新、更强大的 Group Norm，是恺明大佬提出的，可以参考 #link("https://zhuanlan.zhihu.com/p/35005794")[这篇文章]
]

== （李沐版）代码实现的一些细节
- 论文里没有代码，不过有开源，但不看那个，看得是李沐的版本

- 之前以为多头注意力就是一个 attention 里有多个 attention，但其实多头还是一个整体大的 attention，然后在里面把 $d$ 拆分成多个。之所以可以这样写是因为分数计算使用的是 DotProductAttention，这个是 $Q K$直接做内积，不需要学习参数。所以代码本质还是使用一个 attention，只不过因为每个 attention 本质都一样，所以可以并行计算。本质上就是重用batch这一维的并行性来做多头的同时计算
- 具体来说：输入是 $b,n,d$，把它拆分成$b,n,h,d_i$，permute 成 $b,h,n,d_i$，再融合前两维成 $b h,n,d_i$。这样送进 attention 模块使得它并没感知到输入被分头了。最后将输出做逆操作回去就行了

- Encoder 按下不表，而 Decoder 部分相对复杂
  - 训练阶段，输出序列的所有 token 在同一时间处理，但在算 softmax 的时候使用 mask，因此 `key_values` 等于完整的 `X`，然后需要做 `dec_valid_lens`
  - 预测阶段，输出序列是一句话内一个一个 token 处理的，输入 `X` 的 shape 为$(b, n_t, d)$，其 $n$ 是变化的，`key_values` 通过 concat 包含直到当前时间步 $t$ 为止第 $i$ 个 decoder 块的输出表示
    - 这里多多少少有点体现出 Transformer 对于变长数据的灵活性
  - 我们利用 `state` 三元组来传输块与块之间 enc 与 dec 之间的数据，分别保存：encoder 输出，encoder 输出的有效长度以及每个 decoder 块的输出表示
  ```python
  class DecoderBlock(nn.Module):
      # ...
      def forward(self, X, state):
          enc_outputs, enc_valid_lens = state[0], state[1]

          if state[2][self.i] is None:
              key_values = X
          else:
              key_values = torch.cat((state[2][self.i], X), axis=1)
          state[2][self.i] = key_values
          if self.training:
              batch_size, num_steps, _ = X.shape
              # dec_valid_lens的形状:(batch_size,num_steps),
              # 其中每一行是[1,2,...,num_steps]
              dec_valid_lens = torch.arange(
                  1, num_steps + 1, device=X.device).repeat(batch_size, 1)
          else:
              dec_valid_lens = None
  ```
