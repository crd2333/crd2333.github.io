// ---
// order: 12
// ---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "d2l_paper",
  lang: "zh",
)

= 对比学习串讲
#info(caption: "大致阶段划分")[
  + 百花齐放（18 年到 19 年中）：在这个阶段中，方法、模型、目标函数、代理任务都还没有统一
    - InstDisc(instance discrimination)
    - CPC
    - CMC
  + CV 双雄（19 年到 20 年中）：这个阶段发展非常迅速，这些工作有的间隔一两个月，有的间隔甚至不到一个月，ImageNet 上的成绩基本上每个月都在被刷新
    - MoCo v1
    - SimCLR v1
    - MoCo v2
    - SimCLR v2
    - CPC、CMC 的延伸工作
    - SwAV
  + 不用负样本（20年）
    - BYOL
    - BYOL 后续的一些改进
    - 最后 SimSiam 将所有的方法都归纳总结了一下，融入到它的框架中，基本上是用 CNN 做对比学习的一个总结性工作
  + Transformer（21年）：对于自监督学习，无论是对比学习还是最新的掩码学习，都是用 Vision Transformer 做的
    - MoCo v3
    - DINO
  - 这里只是把最有联系的一些工作串到一起，比较他们的异同，不一定全面（主要是 CV 领域会多一些）
]

== 百花齐放
=== Unsupervised Feature Learning via Non-Parametric Instance Discrimination
- 时间：2018.5
- 取标题后两个词命名为 InstDisc，提出了个体判别任务以及memory bank
- 本文的方法受到有监督学习的启发，让某些待分类图片聚集在一起的原因并不是因为它们有相似的语义标签，而是因为这些照片就是在某一种特征上类似。作者根据这个观察提出了个体判别任务：一种无监督的学习方式，将按照类别走的有监督信号推到了极致，把每一个 instance 都看成是一个类别，目标是学一种特征把每一个图片都区分开来
- 模型总览图
  #fig("/public/assets/Reading/limu_paper/对比学习串讲/2024-10-04-12-03-49.png")
  - 通过一个卷积神经网络把所有图片都编码成一个特征，使得在最后的特征空间里尽可能分开。
  - 使用对比学习训练这个 CNN，对于个体判别这个任务，正样本就是这个图片本身（可能经过一些数据增强），负样本就是数据集里所有其它的图片。大量特征存在 memory bank 里，要求每个样本纬度不能太高(128)
- 前向过程
  - 假如 batch size 是 $256$（$256$ 个正样本），通过一个 Res-50，得到特征维度是 $2048$ 维，把它降维降到 $128$ 维，即为每个图片的特征大小
  - 从 memory bank 里随机抽取 $4096$ 个图片作为负样本。有了正负样本，就可以用 NCE loss 计算对比学习的目标函数
  - 一旦更新完这个网络，就把 mini batch 里的数据样本所对应的 memory bank 中的特征进行更新。
  - 最后不断重复上述过程，使学到的特征尽可能有区分性
- 这篇论文还有一些细节设计得很巧妙，比如 proximal regularization 给模型训练加了一个约束，从而能 memory bank 里的特征进行动量式的更新。超参数的设置，也被后来的 MoCo 严格遵守，可见 Inst Disc 是一个里程碑式的工作

=== Unsupervised Embedding Learning via Invariant and Spreading Instance Feature
- 时间：2019.4
- 本篇论文影响力相对不大，之所以提一下这篇论文，是因为它可以被理解成是 SimCLR 的一个前身。它没有使用额外的数据结构去存储大量的负样本，它负样本就是来自于同一个 minibatch，而且只用一个编码器进行端到端的学习
#fig("/public/assets/Reading/limu_paper/对比学习串讲/2024-10-04-12-11-19.png")
- 前向过程
  - 如果 batch size 是 $256$，也就是说一共有 $256$ 个图片，经过数据增强，又得到了 $256$ 张图。对某一张 $x_1$ 来说，$hat(x)_1$ 就是它的正样本；剩下 $(256-1)*2$ 就是负样本
  - 这样负样本比 Inst Disc 少得多，但是可以只用一个 encoder 做端到端的训练
- 本文因为比较贫穷，没有 TPU，所以结果没那么炸裂，事实上它可以理解成  SimCLR  的前身

=== Representation Learning with Contrastive Predictive Coding(CPC)
- 时间：2018.7
- 一般机器学习分为*判别式*模型和*生成式*模型，前两篇论文的个体判别显然是属于判别式范畴的，而常见的预测型任务就属于生成式代理任务
- CPC 这篇论文比较厉害，是一个很通用的结构，可以处理音频、图片、文字以及用于强化学习，这里以音频为例
#fig("/public/assets/Reading/limu_paper/对比学习串讲/2024-10-04-12-22-05.png")
- 一个序列输入 $x$，用 $t$ 表示当前时刻，$t-i$ 表示过去，$t+i$ 表示未来。把过去输入全都扔给一个 encoder，返回一些特征，把这些特征喂给一个自回归的模型($g_"ar"$, auto regressive, e.g. RNN, LSTM)，得到上下文特征($c_t$, context representation)。如果上下文特征表示足够好，那它应该可以做出一些合理的未来预测
- 对比学习在哪里体现的呢？正样本其实就是未来输入通过 encoder 以后得到的特征输出（参考答案）；负样本的定义很广泛，比如任意选取输入通过 encoder 得到的特征，都应该跟预测结果不相似
- 这套思想是很朴实且普适的，把输入序列换成一个句子，用前面的单词来预测后面的单词的特征输出；把这个序列换成一个图片从左上到右下的 patch，用上半部分的图片特征去预测后半部分的图片特征。总之非常灵活

=== Contrastive Multiview Coding(CMC)
- 时间：2019.6
- CMC 的摘要写的非常好：
  - 人观察这个世界是通过很多个传感器（眼睛、耳朵给大脑提供信号），每一个视角都是带有噪声的且可能不完整的，但最重要的那些信息其实在所有的视角中间共享（基础的物理定律、几何形状、语音信息）
  - 基于此提出：学一个非常强大的特征，具有视角的不变性（不管看哪个视角，到底是看到了一只狗，还是听到了狗叫声，都能判断出这是个狗）
  - CMC 工作的目的就是去增大视角之间的互信息，如果能学到一种特征能够抓住所有视角下的关键的因素，那这个特征就很好了，至少解决分类问题不在话下
#fig("/public/assets/Reading/limu_paper/对比学习串讲/2024-10-04-14-48-20.png")
- 具体方法：采用 NYU RGBD 这个数据集，对同一个图片有四种视角 —— 正常视角、深度图、表面法向、物体分割。同一图片的视角互为正样本，与其它图片的视角为负样本
- CMC 这篇论文是第一个或者比较早的用多视角去做对比学习的工作，证明了对比学习的灵活性，某种程度上启发了后来 CLIP 多模态的思想。CMC 的原班人马后来又做了一篇关于蒸馏的对比学习工作，teacher 和 student 的结果构成正样本对，属于是大开脑洞
- 另外就是一个局限性，多个视角如果是多模态的，那就可能需要多个 encoder，加大计算复杂度。但话又说回来，一些论文显示 Transformer 具备同时处理多模态信息的能力

== CV 双雄
- 双雄主要指的是 MoCo 和 SimCLR

=== Momentum Contrast for Unsupervised Visual Representation Learning
- 时间：2019.11
- MoCo-v1 见之前的文章（#link("https://crd2333.github.io/note/Reading/%E8%B7%9F%E6%9D%8E%E6%B2%90%E5%AD%A6AI%EF%BC%88%E8%AE%BA%E6%96%87%EF%BC%89/MoCo")[链接]），不再赘述

=== A Simple Framework for Contrastive Learning of Visual Representations
- 时间：2020.2
- SimCLR 概念上容易理解，方法上也容易解释，因此很多博客在介绍对比学习的时候都用 SimCLR 当例子，只不过 batch size 太大，一般人不好上手
- 方法
  #grid(
    columns: (65%, 35%),
    [
      - 如果有一个 minibatch 的图片，记为 $x$，做不同的数据增强得 $x_i$ 和 $x_j$，同一个图片延伸得到的两个图片就是正样本，不同图片得到就是负样本
      - 正负样本通过同一个 encoder $f(dot)$ 编码，如果具体化为一个 Res-50，得到的特征表示 $h$ 就是 $2048$ 维
      - 然后经过一个 projector MLP 层 $g(dot)$ 降维到 $128$ 维
        - 这个 MLP 层在降维的同时转化语义到对比学习特征空间，效果出奇得好（在 ImageNet 上提了 $10$ 个点），在有监督里很难观测的现象
        - 这个 projector 只在训练的时候用，做下游任务的时候不用
      - 损失函数采用的是 normalized temperature-scaled 的 cross entropy loss。进行 L2 归一化，温度 $tau$ 则跟 infoNCE loss 一样
    ],
    fig("/public/assets/Reading/limu_paper/对比学习串讲/2024-10-05-00-22-26.png")
  )
- 其实是非常简单直接的一个思路，主要不同点就四个：更多的数据增强、MLP 层、更大的 batch size、更久的训练时间

=== Improved Baselines with Momentum Contrastive Learning
- 时间：2020.3
- MoCo-v2 在 MoCo-v1 的基础上把 SimCLR 的即插即用的方法拿过来，加了 projection head 和更多的数据增强
- 又刷了一波榜，然后称赞了一下自己的工作不用太多卡也能跑起来

=== Big Self-Supervised Models are Strong Semi-Supervised Learners
- 时间：2020.6
- 其实 SimCLR-v2 只是这篇论文一个很小的部分，就是一个模型上的改进，而主要在讲如何去做半监督学习
- 这篇文章分了三个部分
  + 第一部分就是 SimCLR，怎样自监督或者说自监督的对比学习去训练一个大的模型出来
  + 第二部分是说，有了这么好的一个模型后，只需要一小部分有标签的数据就可以做有监督的微调，得到一个 teacher 模型，然后就可以用这个 teacher 模型去生成伪标签，在更多无标签数据上去做自监督学习
  + 第三部分没讲，跟对比学习关系不大
- 具体从 SimCLR-v1 到 SimCLR-v2 的改进
  - 使用了更大的模型
  - 更深的 projection head，两层就够了
  - 引入了动量编码器，提升不算特别多（因为 batch-size 已经很大了）

=== 其它
- 不细展开
- CPC 的延伸工作
  - CPC-v2 也是融合了很多的技巧，用了更大的模型、更大的图像块、更多的数据增强，把 batch norm 换成了 layer norm，做了更多方向上的预测任务，一系列操作下来，把 CPC-v1 在 ImageNet 上 $40$ 多的准确率一下拔到 $70$ 多
- CMC 的延伸工作
  - informing 其实是 CMC 作者做的一个分析型的延伸性工作，它论文本身的名字叫 What Makes for Good Views for Contrastive Learning（我们到底选什么样的视角才能对对比学习最好？）
  - 它主要是提出了一个 InfoMin 的原则，就是最小化互信息 minimi mutual information。乍一听觉得可能有点奇怪，之前大家做的都是两个视角之间的互信息达到最大，为什么作者这里就想让它达到最小呢？作者想表达的其实是适量，因为互信息过大可能也是一种浪费且可能泛化性不好
  - 按照 InfoMin 的原则选择合适的数据增强，使用合适的对比学习视角，作者发现对于很多的方法都有提升，它们最后在 ImageNet 上也有 $73$，也是相当不错的

=== 总结
- 其实到了第二阶段很多细节都趋于统一了，比如说
  + 目标函数都是用 infoNCE 或者类似的目标函数去算
  + 模型最后也都归一到用一个 encoder 后面加一个 projection head
  + 都采用了更强的数据增强
  + 都想用这个动量编码器
  + 都尝试着训练的更久
  + 最后在 ImageNet 上的准确度也逐渐逼近于有监督的 baseline

== 不用负样本
=== Unsupervised Learning of Visual Features by Contrasting Cluster Assignment
- 时间：2020.6
- SwAV: #strong[Sw]ap, #strong[A]ssignment, #strong[V]iews
- Views 是什么意思呢？其实跟之前的 CMC 差不多。给定同样一张图片生成不同的 views，希望可以用一个视角得到的特征去预测另外一个视角得到的特征
- 具体做法上，是把对比学习和之前的聚类方法合在了一起
  - 当然这么想也不是偶然，因为聚类方法也是一种无监督的特征表示学习方式，跟对比学习的目标和做法都比较接近；另外，这篇文章的一作之前一直也是做聚类的
  #fig("/public/assets/Reading/limu_paper/对比学习串讲/2024-10-05-10-45-12.png", width: 90%)
  - 左图就是之前的对比学习方法，例如 MoCo 取了 $6$ 万个负样本（还只是部分近似），每个图片都要跟大量负样本比。SwAV 就想，能不能借助一些先验信息去跟更简洁的东西比，也就是跟聚类中心比（语义含义更明确）
  - 右图的 $C in RR^(K times D)$ 就是聚类中心，$K$ 为聚类数目，$D$ 为特征维度。如果 $x_1, x_2$ 是正样本的话，那 $z_1$ 和 $z_2$ 的特征就应该很相似，跟聚类中心算相似度应该很高，二者互为 ground truth 进行预测
  - 另外一个性能提升点来自于一个叫 multi crop 的 trick，也被后来很多工作所借鉴
    - 之前的工作是在 $256^2$ 的图片里 crop 出 $224^2$ 的图片，这么大的 crop 重叠区域也很多所以应该代表一个正样本。这样做明显抓住的是整个场景的特征，如果想学习局部物体的特征，最好能多做一些小的 crop
    - 但出于计算复杂度考虑，采样二者折中的办法，比如 $2 * 160^2$ 的大 crop，再加上 $4 * 96^2$ 的小 crop，争取同时学习全局和局部的特征
- SwAV 的结果非常好，它不仅比我们之前讲过的方法效果好，其实比之后要讲的 BYOL、SimSiam 这些都好，算是卷积神经网络里用 Res-50 分刷的最高的一篇工作，达到了 $75.3%$

=== Bootstrap Your Own Latent, A New Approach to Self-Supervised Learning
- 时间：2020.6
- 标题
  - Bootstrap：在一定基础上改造
  - Latent / hidden / feature / embedding：都是指特征，不同叫法
- BYOL 的特点在于自己跟自己学，不用负样本，类似于左脚踩右脚上天
  - 不用负样本新奇在何处？因为它相当于一个约束，否则如果没有负样本，模型只要对所有正样本的特征都输出零，即可让 loss 为零，这显然是一个 shortcut，也叫模型坍塌(model / learning collapse)
- 模型前向过程
  #fig("/public/assets/Reading/limu_paper/对比学习串讲/2024-10-05-14-17-16.png")
  - 输入是一个 minibatch 的图片 $x$；经过两次数据增强得到 $v$ 和 $v'$；通过 encoder 得到特征，两个 encoder 使用同样的架构但参数不同，上侧的 $f_theta$ 参数正常更新，下侧的 $f_xi$ 为动量编码器（动量更新）；随后分别通过 projection head $g_theta$ 和 $g_xi$得到 $z$ 和 $z'$，同样是上面的参数正常更新，下面的参数动量更新
  - BYOL 在上侧加了一个层 MLP 得到一个新的特征，让这个新的特征和下侧特征尽可能一致，把一个匹配问题变成了一个预测问题
    - 和 SwAV 有点像，但后者借助了聚类中心去帮助做预测任务
  - 目标函数：MSE(mean square error) loss，跟之前的方法都不一样
- BYOL 摈弃了负样本的成功训练非常令人震惊，作者自己给出的解释比较中规中矩，转战一篇复现 BYOL 的#link("https://imbue.com/research/2020-08-24-understanding-self-supervised-contrastive-learning/")[博客]。这篇博客复现了一下发现失败了，于是检查了细节，发现与 BatchNorm 有关
  - SimCLR 里面的 projection head 用了两层 BN，MoCo-v2 里面没有用 BN，而 BYOL 里面用了 BN
  - 博客借鉴了写得非常漂亮的 MoCo-v2 代码，MLP 中少了 BN，模型就坍塌了。于是做了实验，验证 BN 的影响
  #tbl(
    columns: 6,
    [Name], [Projection MLP Norm], [Prediction MLP Norm], [Loss Function], [Contrastive], [Performances],
    [Contrastive Loss], [None], [None], [Cross Entropy], [Explicit], [44.1],
    [BYOL], [Batch Norm], [Batch Norm], [L2], [Implicit], [57.7],
    [Projection BN Only], [Batch Norm], [None], [L2], [Implicit], [55.3],
    [Prediction BN Only], [None], [Batch Norm], [L2], [Implicit], [48],
    [No Normalization], [None], [None], [L2], [None], [28.3],
    [Layer Norm], [Layer Norm], [Layer Norm], [L2], [None], [29.4],
    [Random], [—], [—], [—], [None], [28.8]
  )
  - BN 是什么？就是把一个 batch 里所有样本的特征拿来算均值和方差，从而做归一化。这样在算某个样本 loss 的时候，其实也看到了其他样本的特征，有一定信息泄露。像 MoCo 中就做了一个 shuffle BN 以防止信息泄露。
  - 于是博客作者认为，因为 BN 中有信息泄露，所以可以把 batch 里的其他样本想成隐式的负样本。换句话说，BYOL 其实并不仅是正样本在自己和自己学，它的实际对比任务是：当前正样本的图片，和 BN 产生的平均图片的差别（这和 SwAV 的不用负样本而是聚类中心去对比是相似的）
- 这时候 BYOL 作者就急了（因为这样他们的工作就没有那么开创了），于是做了一系列实验，把 SimCLR 也拉下水
  #fig("/public/assets/Reading/limu_paper/对比学习串讲/2024-10-05-14-47-46.png")
  - 大部分结果显示，BN 确实比较关键，没有 BN 的 BYOL 确实就不学了，但 SimCLR 还在学
  - 但有一组实验显示，即使 Projector 有 BN，BYOL 还是训练失败了，这就不能说明 BN 关键了（因为如果 BN 能提供隐式负样本的话，这里就不应该失败）
  - 更进一步，当 encoder 和 Projector 都没有 BN 的时候，SimCLR 也失败了（SimCLR 是有显式负样本的，没有 Projector 理应不会坍缩而只是降点）
  - 于是 BYOL 作者和博客作者达成一致：BN 跟它原来的设计初衷一样，主要的作用是帮助模型稳定训练，提高模型训练的稳健性，让模型不会坍塌。更进一步，BYOL 在回应论文的 3.3 中给出解释：如果一开始就能让模型初始化的比较好(+WS)，那么后面的训练即使离开了 BN 也没问题(+GN)
    - Weight Standardization 和 Group Norm 分别是一种模型初始化方式和一种归一化的方式

=== Exploring Simple Siamese Representation Learning
- 时间：2020.11
- KaiMing 团队出手，SimSiam 对对比学习进行分析，化繁为简
  + 不用负样本，基本上和 BYOL 很相似
  + 不需要大的 batchsize
  + 不需要动量编码器
  - 不仅不会模型坍塌，而且效果还很好
#algo(
  // stroke: none,
  title: [*Algorithm 1:* 伪代码]
)[
  - \# f: backbone + projection mlp
  - \# h: prediction mlp
  #no-number
  + for x in loader: #comment[load a minibatch x with n samples]
    + x1, x2 = aug(x), aug(x) #comment[random augmentation]
    + z1, z2 = f(x1), f(x2) #comment[projections, n-by-d]
    + p1, p2 = h(z1), h(z2) #comment[predictions, n-by-d]
    #no-number
    + L = D(p1, z2)/2 + D(p2, z1)/2 #comment[loss]
    #no-number
    + L.backward() #comment[back-propagate]
    + update(f, h) #comment[SGD update]
    #no-number
  + def D(p, z): #comment[negative cosine similarity]
    + z = z.detach() #comment[stop gradient]
    #no-number
    + p = normalize(p, dim=1) #comment[l2-normalize]
    + z = normalize(z, dim=1) #comment[l2-normalize]
    + return -(p*z).sum(dim=1).mean() #comment[MSE loss]
]
- 前向过程：得到两个视角之后先过孪生 encoder 得到特征，然后通过 predictor 去进行预测。注意是一个对称型的任务，右下角图上只画了一边
- 结论：之所以 SimSiam 可以训练，不会模型坍塌，主要就是因为有 stop gradient 这个操作
  - 所以可以把 SimSiam 认为是一个 EM 算法，这一个训练过程或者说这一套模型参数其实就被人为的劈成了两份，相当于在解决两个子问题，模型的更新也是在交替进行的
  - 可以理解成一个 Kmeans 的聚类问题，Kmeans 就是分两步走的，每次先把所有点分配给一些聚类中心，再去更新聚类中心。从这个角度说，SimSiam 和 SwAV 就有异曲同工之妙。如图归纳总结了所有孪生网络的做法
  #fig("/public/assets/Reading/limu_paper/对比学习串讲/2024-10-05-15-14-38.png")
- 前面基本没看实验结果，现在在 SimSiam 这个总结性工作上看一下
  #fig("/public/assets/Reading/limu_paper/对比学习串讲/2024-10-05-15-23-27.png")
  - 只有 MoCo-v2 和 SimSiam 能用 $256$ 的 batchsize，其他的工作都要更大；SimCLR 和 MoCo-v2 都要用负样本，BYOL 完全没用，SwAV 用的聚类中心
  - $100$ epoch 的时候 SimSiam 学的最好，但是随着训练推进涨幅就小了，后面是 BYOL 更强。说明动量编码器很好用，很好提点。但是本文主要是把这些 trick 都拿掉，证明没有这些 trick 也能训练
  - 针对下游任务的 transfer 来说，MoCo-v2 和 SimSiam 是表现最好的。如果尝试一些对比学习的工作，用 MoCo-v2 作为基线模型比较好，因为训练快、稳而且下游任务迁移好

- 这个阶段还有一篇论文叫 Barlow Twins（时间：2021.2，已经是 ViT 的时代了），方法差不多但是把目标函数换掉了（感觉跟 CLIP 很像的目标函数？），不细细展开

== Transformer
=== An Empirical Study of Training Self-Supervised Vision Transformers
- 时间：2021.4
- MoCo-v3 的论文，但大部分篇幅在讲自监督的 ViT 怎么做，另外 MoCo-v3 只是一种架构，卷积神经网络也可以用，ViT 也可以用。文章贡献在于做了一个很直接、很小的改动，让自监督的 ViT 训练变得更稳定了
- MoCo-v3 其实相当于 MoCo-v2 和 SimSiam 的合体，是一个很自然的延伸工作
  - 整体框架：query 编码器(backbone + projection + prediction , i.e. BYOL/SimSiam)和 key 编码器(momentum)
  - 对称型目标函数：既算 $q_2$ 到 $k_1$，也算 $q_1$ 到 $k_2$
  - 把 backbone 的 ResNet 换成 ViT，试验了不同 batchsize 的结果，发现问题
    #grid(
      columns: (50%, 50%),
      [
        + 当 batchsize 比较小的时候，曲线比较平滑，效果也还行
        + 当 batchsize 变大之后，准确度会突然掉下来又恢复，但是不如其它方法高了
        + 按道理大 batchsize 应该会有更好的结果，如果能解决这个问题，就能用更大的 batchsize，训练更大的 ViT
      ],
      fig("/public/assets/Reading/limu_paper/对比学习串讲/2024-10-05-15-48-57.png")
    )
- 针对这个普遍出现的问题，提出一个普适的小 trick
  - 如何想到的？观察训练的时候每一层梯度回传的情况。作者发现每次 loss 有大幅的震动时，梯度也会有一个波峰，发生在第一层也就是做 patch projection 时
    - 即 ViT 论文中的第一步，属于 tokenization 阶段，把一个图片打成 patch 的做法就是一个可训练的全连接层
    - 如果这个可训练的全连接层每次梯度都不正常，那还不如不训练。所以作者就尝试把这个 MLP 随机初始化然后冻住，问题就解决了
  - 这个 trick 具有普适性，不仅对 MoCo-v3 有用，对 BYOL 也有用（用 BYOL 的框架，把残差网络换成 ViT）；因为 Transformer 又简单扩展性又好，不大改它就只能改开始的 tokenization 阶段和结尾的目标函数

=== Emerging Properties in Self-Supervised Vision Transformers
- 时间：2021.4
- DINO 的论文，也是一个自监督的 ViT，但是主要卖点在于 ViT 在自监督训练的情况下出现的有趣特性
  - 名字来源于 Self-#strong[DI]stillation with #strong[NO] labels
  - 一个完全不用标签信息训练出来的 ViT，如果把自注意力图进行可视化，能非常准确的抓住每个物体的轮廓，效果甚至能媲美直接对物体做分割的有监督工作
- 具体做法
  - 延续了 BYOL 和 MoCo-v3 的框架，只不过换了个名字，用蒸馏的叫法成为 student, teacher
  - self-distillation：和 BYOL 一样自己和自己学，用 student 去预测 teacher
  - 加了个 centering 的操作，其实就是半步 BN，减掉 batch 的均值，避免模型坍塌
  - 从方法和模型角度上讲，和第三阶段一模一样，主要是融合了 Transformer

== 总结
在这之后，对比学习应该就是 CLIP 的天下了，可以看 CLIP 及其相关工作（#link("https://crd2333.github.io/note/Reading/%E8%B7%9F%E6%9D%8E%E6%B2%90%E5%AD%A6AI%EF%BC%88%E8%AE%BA%E6%96%87%EF%BC%89/CLIP")[链接]）。而随着 MAE 的火爆，对比学习的热潮逐渐冷却了一些，转而向掩码学习而去。再然后就不知道了，可能是多模态大模型？

最后再自己画一张图总结一下 CV 领域对比学习的发展
#fig("/public/assets/Reading/limu_paper/对比学习串讲/2024-10-05-16-30-12.png")
