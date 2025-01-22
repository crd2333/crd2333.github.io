#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Deep Learning Basics",
  lang: "zh",
)

#info(caption: "深度学习领域大致划分")[
  + 深度学习基础
  + 卷积神经网络(CNN）
  + 循环神经网络(RNN)
  + 注意力机制(Attention)
  + 生成式模型(Generative Model)
  + 对比学习与自监督学习(Contrastive & Self-supervised Learning)
  + 图神经网络(GNN)
  + 其它话题
    + 其它模型
    + 迁移学习与终生学习
    + 元学习
    + 机器学习可解释性
    + 机器学习中的攻击与防御
    + 网络压缩
  + 从任务角度看
    + CV: Computer Vision
    + NLP: Natural Language Processing
    + AIGC: AI Generative Content
    + Multimodal & Large Model
]

- 网络上其他人的笔记
  + #link("https://github.com/Michael-Jetson/ML_DL_CV_with_pytorch")[Michael-Jetson/ML_DL_CV_with_pytorch]
  + #link("https://github.com/sotaBrewer824/LHY_MLDL")[sotaBrewer824/LHY_MLDL] 《李宏毅机器学习》极为详尽的笔记，写成一本书了快

= 深度学习基础
...

= CNN
...


= RNN
- RNN 主要用于处理序列数据，比如时间序列数据，它的高级变种包括 LSTM 和 GRU 等。
== Basic RNN
- RNN 的基本结构如下，其中 $W_"in", W_h, W_"out"$ 都是共享的，以此减少参数量。
#fig("/public/assets/AI/AI_DL/basic/img-2024-07-03-16-29-29.png", width: 80%)
- RNN 最大的问题是梯度消失和梯度爆炸
- RNN 本身的改进有：多层 RNN 和双向 RNN
  - 多层 RNN：将许多 RNN 层堆叠得到，在纵向上也进行序列化学习
  - 双向 RNN：当排列顺序固定，文本意义一般是固定的，人类习惯于从左往右阅读，但对于 RNN 来说，从左往右或从右往左并没有本质的区别，且二者可以并行。
  #grid(
    columns:2,
    fig("/public/assets/AI/AI_DL/basic/img-2024-07-03-16-33-24.png", width: 80%),
    grid.cell(align: horizon, fig("/public/assets/AI/AI_DL/basic/img-2024-07-03-16-32-55.png"))
  )

#info(caption: "nn.RNN的参数")[
  + `input_size` 输入特征的维度， 一般 RNN 中输入的是词向量，那么 `input_size` 就等于一个词向量的维度
  + `hidden_size` 隐藏层神经元个数
  + `num_layers=1` 网络的层数
  + `nonlinearity=tanh` 激活函数
  + `bias=True` 是否使用偏置
  + `batch_first=False` 输入数据的形式，默认即 (seq(num_step), batch, input_dim) 的形式，也就是将序列长度放在第一位，batch 放在第二位
  + `dropout=0` 是否应用 dropout, 默认不使用，若使用将其设置成一个0\~1的数字
  + `birdirectional=False` 是否使用双向的 rnn，默认是 False
]
- 使用上分为 `nn.RNN` 和 `nn.RNNCell`，前者后者堆叠而成，后者是单个时间步上的RNN单元，使用更加灵活
- Example
```py
class SimpleClassificationRNN(nn.Module):
    def __init__(self, hidden_size):
        super(SimpleClassificationRNN, self).__init__()
        self.rnn = nn.RNN(input_size=1,
                          hidden_size=hidden_size,
                          batch_first=True,
                          num_layers=1)
        self.linear = nn.Linear(hidden_size, 1)

    def forward(self, seq, hc=None):
        tmp, hc = self.rnn(seq, hc)
        # tmp.shape = (batch, seq_len, hidden_size) = (800, 20, 16)
        # hc.shape = (num_layers, batch, hidden_size) = (1, 800, 16)
        out = torch.sigmoid(self.linear(hc[-1, ... ,:]))
        return out, hc

model = SimpleClassificationRNN(hidden_size=16)
output, _ = model(X) # X.shape = (batch, seq_len, input_dim) = (800, 20, 1)
# ...

# for RNNCell, should input hidden state mannully
output, hc = model(X, hc)
```

== LSTM
- LSTM 通过引入门控机制，缓解 RNN 的梯度消失和梯度爆炸问题，分为输入门、遗忘门、输出门和记忆单元。
#fig("/public/assets/AI/AI_DL/basic/img-2024-07-03-22-06-17.png", width: 90%)
- LSTM 的用法跟 RNN 差不多，也分 `nn.LSTM` 和 `nn.LSTMCell`，以后者为例
```py
lstm_cell = nn.LSTMCell(input_size, hidden_size)
# random input data
x = torch.randn(batch_size, seq_length, input_size)
x = x.transpose(0, 1)
# initialize hidden state and cell state
h_0 = torch.zeros(num_layers, batch_size, hidden_size)
c_0 = torch.zeros(num_layers, batch_size, hidden_size)
h_t, c_t = h_0, c_0
# begin to train
for i in range(seq_length):
    h_t, c_t = lstm_cell(x[i], (h_t, c_t))
```

== GRU
- GRU 是 LSTM 的简化版，只有两个门：重置门和更新门（输入门和遗忘门合并），没有输出门和记忆单元（与隐藏单元合并）。
- 参数更少，性能不减
#fig("/public/assets/AI/AI_DL/basic/img-2024-07-03-22-09-41.png", width: 90%)

= Attention & Transformer
- #link("https://zhuanlan.zhihu.com/p/338817680")[参考链接]
- Transformer 是一个基于注意力机制的模型。Attention is all you need.
- 原始版本的 Transformer 由 encoder 和 decoder 组成，BERT 等模型只使用了 encoder 部分；GPT 等模型只使用了 decoder 部分。
#fig("/public/assets/AI/AI_DL/basic/img-2024-07-03-22-14-26.png", width: 90%)
- Transformer 在训练和推断时刻是不同的
  + 训练时：第$i$个 decoder 的输入 = encoder 输出 + ground truth embeding
  + 预测时：第$i$个 decoder 的输入 = encoder 输出 + 第 $i-1$ 个 decoder 输出
  - 训练时因为知道 ground truth embeding，相当于知道正确答案，网络可以一次训练完成（并且相比多步序列学习，结果不至于偏差太远），并且可以并行；
  - 预测时，首先输入 start，输出预测的第一个单词 然后 start 和新单词组成新的 query，再输入 decoder 来预测下一个单词，循环往复直至 end
- 多头自注意力机制：将输入的序列映射到多个子空间，然后分别进行注意力计算，最后将结果拼接起来。

- 更详细的内容，直接拆分出一个大章 —— LLM


= Generative Model
- #link("https://zhuanlan.zhihu.com/p/577974910")[概论生成网络(GAN/VAE/Flow/Diffusion)]

...


= Contrastive & Self-supervised Learning
...


= GNN
- 参考 #link("https://distill.pub/2021/gnn-intro/")[Distill 2021 GNN Introduction]
- 图这个数据结构相对于之前讨论的文本（序列）、图片（个矩阵），图相对来说更加复杂一点。18 年开始，将神经网络应用在图上这个研究方向逐渐兴起

#info()[
  - 本文旨在探索和解释现代的图神经网络
    - 什么数据可以表示成一张图
    - 图和别的数据有什么不同，为什么要做图神经网络，而不是使用最简单的卷积神经网络等
    - 构建了一个 GNN，看各模块的具体结构
    - 提供了一个 GNN 的 playground
]

== 什么是图，数据怎么表示成图
- 顶点(node)及其属性，边(edge)及其属性，整个图(U)的全局信息，此外还有图的连接性（每条边到底连接的是哪两个点）
- 图神经网络所关注的重点
  + 怎样把所想要的信息表示成向量
  + 这些向量是不是能够通过数据来学到
- image 表示成图：每个像素为顶点，与周围 $8$ 个像素相连边
- text 表示成图：每个词为顶点，每个词和下一个词之间有一条有向边
- 此外还有：社交网络图、分子图、引用图等
- 图的几类问题
  + Graph level，对整个图进行识别
  + Community/Subgraph Level，社区/子图级别的任务
  + Edge level，对边的属性进行判断
  + Node level，对顶点的属性进行判断
- 将神经网路用在图上面最核心的问题是：如何表示图使得它能够和神经网络兼容
  - 用邻接矩阵来表示连接性，其问题是矩阵巨大且稀疏，并且行列顺序无关导致表示不唯一
  - 用邻边列表，每个顶点、边以及全局图的属性都用标量（或向量，不影响）来表示。存储高效且与顺序无关
  #fig("/public/assets/AI/AI_DL/basic/2024-09-24-16-16-29.png", width: 90%)

== 图神经网络
- GNN 对图上所有的属性（顶点、边和全局）进行可优化变换，这个变换能够保持图的对称信息（置换不变性）
- GNN 采用“图入图出”架构，它会对顶点、边和全局的向量进行变换，并逐步转换这些 embeding 信息，而不改变图的连接性

=== GCN
- 接下来逐步推导得到 GCN
- 一个最简单利用了 MLP 的网络层，对顶点向量、边向量和全局向量分别做 MLP
  #fig("/public/assets/AI/AI_DL/basic/2024-09-24-11-04-44.png", width: 90%)
- 最后再加一个分类层，就可以对顶点或边或全局做分类，或者加上*汇聚*操作也可以进行预测
  #fig("/public/assets/AI/AI_DL/basic/2024-09-24-11-07-03.png", width: 90%)
- 一个问题在于：对每个属性做变换的时候，仅仅是每个属性进入自己对应的 MLP，并没有体现出三者之间的相互联系的连接信息
  - 为此进行*汇聚*操作来进行信息传递，例如把每个顶点与其相连的顶点的向量相加，然后再送入 MLP
  - 再复杂一点，顶点和边之间也可以直接进行信息传递（如果维度不同就投影一下，或者干脆 concat 也可以）
  - 当然这是顺序相关的，不过可以交替进行以避免顺序影响
  #grid2(
    fig("/public/assets/AI/AI_DL/basic/2024-09-24-11-16-32.png", width: 90%),
    fig("/public/assets/AI/AI_DL/basic/2024-09-24-11-16-40.png", width: 90%)
  )
  - 和卷积操作有点类似，但是还是有区别（汇聚时权重相等），之所以不做权重是因为图的连接比卷积的位置权重灵活得多
- 加入全局信息 master node，跟所有 node 和 edge 都相连
  #fig("/public/assets/AI/AI_DL/basic/2024-09-24-12-04-15.png", width: 90%)

=== GraphSAGE
...


=== GAT
- graph attention network
- 前面 GCN 的时候说，图对位置信息不敏感因此没有卷积权重，但可以用类似自注意力机制的方法来计算权重（取决于两个顶点向量之间的关系）
- ...


== 相关技术
- 更多种类的图
  - multi graph：顶点之间可以有多条边
  - 分层的图：其中有一些顶点可以能是一个子图（hypernode）
  - 不同的图结构会对神经网络做信息汇聚的时候产生影响
- 对图进行采样
  - 为何需要采样：由于可能有很多层消息传递，在计算梯度的时候，需要把整个 forward 中所有中间变量存下来，导致计算量大到无法承受。通过采样，在小图上做信息汇聚，大大减小计算量
  - 几种采样方法：Random node, Random walk, Random walk with neighborhood, Diffusion Sampling
- 如何做 batch
  - 做 batch 是为了利于并行
  - 存在一个问题：每一个顶点的邻居的个数是不一样的，如何将这些顶点的邻居通过合并变成一个规则的张量是一个具有挑战性的问题
- inductive biases 归纳偏置
  - 图神经网络假设的是：保持了图的对称性（不管怎样交换顶点的顺序，GNN对图的作用都是保持不变的）
- 不同汇聚操作的比较
  - sum, avg, max，但其实没有一种是特别理想的，主要还是根据任务来定
- GCN 作为子图的函数近似
  - 从一定程度上来说，GCN 可以认为是：$n$ 个以自己为中心往前走 $k$ 步的子图，最后求 embeding
- 将点和边做对偶
  - 图论中可以把点变成边、边变成点，邻接关系表示保持不变。这种变换在 GNN 上也可以使用
- 图卷积和矩阵乘法的关系
  - 如何高效实现整个图神经网络的关键点
  - 在图上做卷积或者做 random work，等价于将它的邻接矩阵拿出来做矩阵乘法
- 图的可解释性
  - 可以将子图中的信息抓取出来，看它到底学到的是什么信息
- generative modeling
  - 图神经网络是不改变图的结构的，如果想要生成图，怎样对图的拓扑结构进行有效的建模，有相关的一些算法

= 其它话题
== 其它模型
=== TCN
- Temporal Convolutional Networks，是一种用于处理时间序列数据的卷积神经网络
- 参考 #link("https://blog.csdn.net/weixin_39910711/article/details/124678538")[TCN(Temporal Convolutional Network)时间卷积网络]


#hide[
== 迁移学习与终身学习
== 元学习
== 机器学习可解释性
== 机器学习中的攻击与防御
== 网络压缩
]


= Deep Learning Tasks
- Deep Learning 最主要的任务是 CV 和 NLP，当然后面就五花八门了起来，这里仅做引入
- 最开始可以这么理解：CV 是处理空间信息，由此发展了卷积神经网络；NLP 是处理时序信息，由此发展了循环神经网络和 Transformer(Attention)
- 但是到了后面，二者的边界逐渐模糊（比如，有用卷积做时序的，有用 Transformer 做视觉的）。它们逐渐融合于多模态和大模型的发展中
- 目前的基础机制依旧是 Transformer 和 Attention，似乎还没有探测出它的极限，似乎也还没有更好的压倒性地强于它的模型出现

== CV: Computer Vision
- CV 这一块的任务主要分为：图像分类、目标检测、语义分割、风格迁移（or 图像生成）等

- 传统的 CV 主要用的是 CNN，主要理解*卷积*、池化、全连接、激活函数、Dropout、Batch Normalization 等基本组件；然后目标检测这边引入锚框、NMS、IoU 等概念；语义分割这边引入转置卷积

=== 图像分类
- 图像分类 topic 下比较有里程碑意义的数据集有：
  + MNIST
  + CIFAR-xx
  + ImageNet

- 图像分类 topic 下比较有里程碑意义的网络（按顺序）有：
  + MLP：多层线性网络
  + LeNet：首次采用了卷积层、池化层两个全新的神经网络组件，在 MNIST 数据集上取得瞩目成果
  + AlexNet：2012 年的 ImageNet 冠军，特点有——更深的架构、ReLU 的使用、局部响应归一化(LRN)、数据增强和 Dropout、GPU 加速
  + VGG：规律的设计、简洁可堆叠的小卷积块、更深的架构
  + NiN：网络中的网络，引入了 1x1 卷积核，可以看作是在每个像素的通道上分别使用多层感知机（or 全连接层）
  + GoogLeNet：Inception 模块（多分支学习）
  + ResNet：解决“退化现象”，提出残差连接
  + DenseNet：ResNet 相加方式实现跨层连接的改进，提出密集连接，每一层都与块内所有之前的层相连（好处——梯度复用、梯度传播、参数效率）

=== 目标检测
- 目标检测 topic 下比较有里程碑意义的数据集有：
  + VOC
  + COCO

- 目标检测 topic 下比较有里程碑意义的网络有：
  - RCNN（Region-based Convolutional Neural Networks，区域卷积神经网络） 系列
    + RCNN：使用选择性搜索选择提议区域，然后使用 CNN 提取特征，最后使用 SVM 进行分类
    + Fast RCNN：仅在整张图像上执行卷积神经网络的前向传播，仍使用选择性搜索选择提议区域
    + Faster RCNN：将生成提议区域的方法从选择性搜索改为了区域提议网络（RPN，相当于一个糙一点的目标检测模型），也即 two-stage 方法
    + Mask RCNN：利用数据集中的像素级信息提升目标检测精度
  - SSD（Single Shot MultiBox Detector，单发多框检测）：使用 CNN 提取多尺度特征块（特征金字塔），然后在每个特征块上预测目标的类别和位置
  - YOLO(you only look once) 系列

=== 语义分割
- 语义分割 topic 下比较有里程碑意义的数据集有：
  + Pascal VOC2012
- 语义分割 topic 下比较有里程碑意义的网络是*全卷积网络*(fully convolutional network, FCN)
  - 引入*转置卷积*（有时笼统地翻译为反卷积）
  - 使得网络学习到某种特征后还能恢复到原来的尺寸，最后的输出为对每个像素分类

=== 风格迁移（or 图像生成）
- 风格迁移 or 图像生成后来有 GAN, Diffusion 等更好的方法，这里只是介绍一个很基础的方法
- 将内容图片和风格图片都过一遍网络，要求生成的图像在某些层上与内容图片对齐，有些层上与风格图片对齐。对图像做训练而不是对模型做训练，或者说这里就没有训练、推理的区别了，训练的过程就是生成的过程


== NLP: Natural Language Processing
- NLP 这边对于数据的处理比较复杂
  - 首先要进行文本预处理，然后使用 vocab 来将文本数字化并分词(tokenize)，再做 embeding 化为词向量（或者简单地做 one-hot）
  - 然后还要做 padding，使得每个句子的长度一致才能进行训练，接下来做成 batch 进行训练
  - 然后模型设计和训练过程中还要时刻注意语言数据的 shape 和含义，时不时要利用 `valid_lenth` 做裁剪……

- 对文本数据这种时序信息，我们往往用自回归模型处理

=== 循环神经网络
- RNN，以及它的衍生 LSTM 和 GRU，效果实际上差不多

=== 近代循环神经网络
- Encoder-Decoder 架构
- seq2seq 学习
- 各种优化和概念：束搜索(bin search)，困惑度(perplexity)，BELU score 等

=== Transformer & Attention
- 两种注意力机制
  - Additive Attention
  - Scaled Dot-Product Attention
- 注意力机制的变种
  - self-attention
  - multi-head attention
- 关于 Transformer 的基础可以参考 #link("https://crd2333.github.io/note/Reading/%E8%B7%9F%E6%9D%8E%E6%B2%90%E5%AD%A6AI/Transformer")[原论文阅读笔记]

== AIGC: AI Generative Content
...

== Multimodal & Large Model
...