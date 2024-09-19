#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Deep Learning Basics",
  lang: "zh",
)

= Deep Learning Networks
== CNN

== TCN
- Temporal Convolutional Networks，是一种用于处理时间序列数据的卷积神经网络
- 参考 #link("https://blog.csdn.net/weixin_39910711/article/details/124678538")[TCN（Temporal Convolutional Network，时间卷积网络）]

== RNN
- RNN 主要用于处理序列数据，比如时间序列数据，它的高级变种包括 LSTM 和 GRU 等。
=== Basic RNN
- RNN 的基本结构如下，其中 $W_"in", W_h, W_"out"$ 都是共享的，以此减少参数量。
#fig("/public/assets/AI/AI_DL/img-2024-07-03-16-29-29.png")
- RNN 最大的问题是梯度消失和梯度爆炸
- RNN 本身的改进有：多层 RNN 和双向 RNN
  - 多层 RNN：将许多 RNN 层堆叠得到，在纵向上也进行序列化学习
  - 双向 RNN：当排列顺序固定，文本意义一般是固定的，人类习惯于从左往右阅读，但对于 RNN 来说，从左往右或从右往左并没有本质的区别，且二者可以并行。
  #grid(
    columns:2,
    fig("/public/assets/AI/AI_DL/img-2024-07-03-16-33-24.png"),
    grid.cell(align: horizon, fig("/public/assets/AI/AI_DL/img-2024-07-03-16-32-55.png"))
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
#fig("/public/assets/AI/AI_DL/img-2024-07-03-22-06-17.png")
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
#fig("/public/assets/AI/AI_DL/img-2024-07-03-22-09-41.png")

== Transformer
- #link("https://zhuanlan.zhihu.com/p/338817680")[参考链接]
- Transformer 是一个基于注意力机制的模型。Attention is all you need.
- 原始版本的 Transformer 由 encoder 和 decoder 组成，BERT 等模型只使用了 encoder 部分；GPT 等模型只使用了 decoder 部分。
#fig("/public/assets/AI/AI_DL/img-2024-07-03-22-14-26.png")
- Transformer 在训练和推断时刻是不同的
  + 训练时：第$i$个decoder的输入 = encoder输出 + ground truth embeding
  + 预测时：第$i$个decoder的输入 = encoder输出 + 第$i-1$个decoder输出
  - 训练时因为知道ground truth embeding，相当于知道正确答案，网络可以一次训练完成（并且相比多步序列学习，结果不至于偏差太远），并且可以并行；
  - 预测时，首先输入start，输出预测的第一个单词 然后start和新单词组成新的query，再输入decoder来预测下一个单词，循环往复直至end
- 多头自注意力机制：将输入的序列映射到多个子空间，然后分别进行注意力计算，最后将结果拼接起来。

= Deep Learning Tasks
- Deep Learning 最主要的任务是 CV 和 NLP，当然后面就五花八门了起来，这里仅做引入
- 最开始可以这么理解：CV 是处理空间信息，由此发展了卷积神经网络；NLP 是处理时序信息，由此发展了循环神经网络和 Transformer(Attention)
- 但是到了后面，二者的边界逐渐模糊（比如，有用卷积做时序的，有用 Transformer 做视觉的）。它们逐渐融合于多模态和大模型的发展中
- 目前的基础机制依旧是 Transformer 和 Attention，似乎还没有探测出它的极限

== CV: Computer Vision
- CV 这一块的任务主要分为：图像分类、目标检测、语义分割、风格迁移（or 图像生成）

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
    + Fast RCNN：仅在整张图象上执行卷积神经网络的前向传播，仍使用选择性搜索选择提议区域
    + Faster RCNN：将生成提议区域的方法从选择性搜索改为了区域提议网络（RPN，相当于一个糙一点的目标检测模型），也即 two-stage 方法
    + Mask RCNN：利用数据集中的像素级信息提升目标检测精度
  - SSD（Single Shot MultiBox Detector，单发多框检测）：使用CNN提取多尺度特征块（特征金字塔），然后在每个特征块上预测目标的类别和位置
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
- 关于 Transformer 的基础可以参考 #link("http://crd2333.github.io/note/Reading/%E8%B7%9F%E6%9D%8E%E6%B2%90%E5%AD%A6AI%EF%BC%88%E8%AE%BA%E6%96%87%EF%BC%89/Transformer")[原论文阅读笔记]

