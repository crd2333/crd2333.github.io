// ---
// order: 32
// ---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "d2l_paper",
  lang: "zh",
)

= Hierarchical Text-Conditional Image Generation with CLIP Latents
- 时间：2022.4

== 标题 & 摘要 & 引言
- 技术路线：DALLE $->$ CogView $->$ NVWA $->$ GLIDE(OpenAI) $->$ ERNIE-ViLG $->$ DALLE2 $->$ CogView2 $->$ CogVideo $->$ Imagen(Google)
- DALLE 沿用了 OpenAI 擅长的基于 GPT 的技术路线(GPT+VQ-VAE)。在此之前，OpenAI 已于 2020 年 6 月发布了 Image-GPT，在图像生成大模型上小试牛刀。但是 DALEE2 采用了不同的技术方案：扩散模型。其效果比 DALLE 提升很多。
- 标题：使用 CLIP 特征，基于文本信息层次化地生成图像。其实 DALLE2 就是 CLIP + GLIDE，后者就是基于 difussion 的图像生成模型
- 摘要
  - 用一种 two-stage 的方法，先 prior 显式地生成 image embedding，再用 decoder 生成 image，这种显式方式可以显著增强 diversity 而不会影响写实程度和文本图像匹配程度；而且用 CLIP 得到的 embedding space 允许 DALLE2 通过文本来修改图像，而且是 zero-shot 的
  #diagram(
    node((-4.5,0), [Text]),
    edge([CLIP encoder]),
    node((-1.5,0), [Text embedding]),
    edge([prior]),
    node((1.5,0), [Image embedding]),
    edge([decoder]),
    node((4.5,0), [Image]),
  )
- 引言
  - 首先说最近的 CV 领域进展主要是在 captioned images 上训练 scaling models，比如 CLIP。
    - CLIP 可以看之前的论文阅读笔记
  - 然后是说扩散模型成为 CV 领域图像和视频生成最好的工具
    - difussion 是从一个分布里去采样，它的多样性非常好，但是保真度比不过 GAN。但后来各种 technique 比如 guidance 不断地去优化它，逐渐就成为 SOTA
  - 接着就是用一个图片九宫格卖一卖结果，又多样又逼真巴拉巴拉
  - 最后简单介绍一下模型。其实它就是 CLIP 和 GLIDE 的融合，prior 模型通过把 CLIP text encoder 的结果作为输入，CLIP image encoder 的结果作为 ground truth 进行训练，这样显式地得到图像的特征，然后再送入 decoder 生成图像
- 论文的主体方法部分只有两页，默认读者有一定的了解，细节透露的也不多（CloseAI 一贯作风）。所以下面先去了解一下图像生成领域以前的方法和 difussion 的做法等
- 其实在论文发布的时候，GPT 已经在文本生成领域取得巨大成功，但是图像生成任务依然没有很好地解决，文本生成和图像生成有何不同？
- 之前的图像生成模型都是基于 GAN 的，但是 DALLE2 采用了扩散模型，这两者有何不同？
  + 相对而言，文本生成是“一对一”的任务，而图像生成是“一对多”的任务。如机器翻译，有比较确定性的正确答案；而图像生成，一个文本描述可以对应很多图像，图像生成时机器需要大量“脑补”（一文对多图）
    - 更本质地说，一般的机器学习任务，一个输入有一个确定性的标签(label)；图像生成任务不一样，对一个输入，其输出是一个分布
    - 因此 Image-GPT 这种直接拿 GPT 做图像生成效果相对不好。因为每个 pixel 单独生成，无法表达分布的约束。画一幅图，前一个 pixel 可能往左跑，后一个 pixel 可能往右跑，单独看每个都没有问题，但是放在一起就不协调（其实感觉用 patch 思想能一定程度解决这个问题）
  + “一图胜千言”，图像的信息量远远大于文本，同一张图片可以有不同的文本描述、包含多个视觉概念，生成任务需要把它们有机地融合在一起（一图对多文）
  + 再者，文本生成任务的基本概念单元 —— token，是有限的、离散的、可枚举的；而图片任务不一样，它是无限的、连续的、不可穷举的。
    - 图像的像素表征有很多冗余，图像概念更像是在一个连续、渐变空间。例如，同一张图片，可以稍微做一点变换，生成一个大体相似，但有细微差别的图片。
  - 凡此种种，可以通过扩散模型比较好地解决
    - 扩散模型在文本之外引入额外的输入：随机噪声分布。使得输入变成了一个分布，输出也是一个分布。有了分布就有了约束，使得输出的视觉概念满足概率约束
    - 扩散模型的输出不是一步到位，而是多步到位。中间过程生成了大体相似却又有所差异的图片

== 图像生成技术的演进
=== GAN
- GAN 的核心思想是“左右手互搏”，有两个网络，一个生成器(Generator) $G$，一个判别器(Discrimitor) $D$。它刚提出时，被认为是深度学习领域当时最具创意的思想
- 生成器的输入是随机噪声，输出是图像 $x'$。判别器的输入是 $x'$ 和真实图像 $x$，输出是二分类，表示 $x'$ 是否是真实图片。生成器的目标是以假乱真，糊弄判别器。而判别器的目标是练就一双火眼金睛，识别伪造的图片。训练过程中 $G$ 和 $D$ 不断提升，最后 $G$ 能生成非常逼真的图片
- GAN 的目标函数就是为了以假乱真，所以 GAN 生成的图片保真度非常高，即便人眼也很难区分真假，使用 GAN 的 DeepFake 曾经十分火爆。
- 经过多年的优化，GAN 现在很好用，但是它还有一些缺点
  + 训练不稳定。因为它要训练两个网络，不太好平衡
  + GAN 生成过程的随机性来自初始的随机噪声，导致生成的图片缺乏多样性和创造性
  + GAN 不是一个概率模型。它的生成都是隐式的、通过一个网络完成的。我们没法知道它具体做了什么，遵循什么分布。GAN 在数学上不如后期的 VAE,diffusion 模型优美
- 接下来是 AE 大家族

=== AE & DAE
#fig("/public/assets/Reading/limu_paper/DALLE2/2024-10-09-09-28-49.png")
- AE
  - 原始图片 $x$，经过 encoder $E$ 得到中间向量 $z$，再经过 decoder $D$，输出图片 $x'$。$z$ 的维度通常比原始图片小很多，所以又被称为 bottleneck
  - 训练目标：$x'$ 尽量逼近 $x$。即重构原始图片
- DAE
  - DAE 与 AE 只有一个差别：输入的原始图片 $x$ 先加噪变成 $x_c$，再接入后续流程。训练目标仍是使输出 $x'$ 逼近原始图片 $x$
  - 事实证明，加噪声很有用。它使得模型更稳健，鲁棒性更强，不容易过拟合
  - 究其原因，可能在于，图片信息冗余很大。即使原始图片被污染了，模型仍然能够抓住它的本质，把它重构出来。这一思想与扩散模型以及何恺明的 MAE 有异曲同工之妙
  - 无论是 AE, DAE 还是 MAE，都是为了学习中间的 bottleneck 特征。然后再拿 bottleneck 特征做分类等任务。它并不是为了做生成式任务。原因是它学到的是固定的特征向量，而不是一个概率分布，不能用来做采样。于是，顺着这条思路衍生出来 VAE

=== VAE & VQ-VAE
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

=== DALLE
#fig("/public/assets/Reading/limu_paper/DALLE2/2024-10-09-11-45-44.png")
- DALLE 的模型十分简洁。输入文本通过编码(BPE)得到文本向量(256)，图像通过事先训练好的 VQVAE 编码得到图片向量($32 * 32 = 1024$)。二者 concat 到一起得到一个序列(1280 token)。有了输入序列接下来就是很常规的操作，接入 GPT，并通过 mask 等方式训练
- 推理的时候，输入文本，得到文本序列，输入 GPT，用自回归的方式生成图像 token 序列，得到图片
- DALLE 自回归输出得到多张图片，将图片的 CLIP embedding 与输入文本的 CLIP embedding 做对比，找到最相似的图片作为最终输出

=== Diffusion
#fig("/public/assets/Reading/limu_paper/DALLE2/2024-10-09-11-57-36.png", width: 70%)
- 部分参考 #link("https://mp.weixin.qq.com/s?__biz=MzkwODI1OTE1Nw==&mid=2247484415&idx=1&sn=a8c642342c579997367060b54fec218a&chksm=c0cdf9c5f7ba70d371485819600cd76835ae6f734793b85b09808099e5b2da51f432991725cb&token=1945802926&lang=zh_CN#rd")[AI论文精读-10：深入理解扩散模型和DALLE2]
- 扩散的概念
  - 来自物理学中的扩散过程。将一滴墨汁滴到一瓶清水中，它会逐渐扩散开来，最后墨汁和清水浑然一体，达到“各向同性的正态分布”
  - 对一张原始图片，逐步加噪声，它最终会变成面目全非的白噪声。这个过程比作上述扩散过程。称作前向扩散，forward diffusion
  - 生成图片可以看作，输入高斯白噪声，然后一步一步地对它去噪，最后生成清晰的图片。这一过程称作反向扩散，reverse diffusion，是前向扩散的逆过程
  - 但从深度学习的角度来看，加噪声是为了构造自监督学习的 label。它和 BERT 及 GPT 通过 mask 或者预测下一个单词等方式构造 label 有异曲同工之妙。有了稳健的自监督 label，我们才能构造模型消费取之不尽、用之不竭的图片、文本等数据集，才能实现“大力出奇迹”
  - 图像生成及推理过程，就是逐步去噪。模型推理时不是一步到位，而是步步为营 $N$ 次完成
    - 输入是白噪声（或者 prior 网络得到的分布，例如 DALLE2）以及步数 $t$，模型推理预测上一个时间步的图片。重复这一过程 $N$ 次，最终得到输出图片。而这个图片跟前向过程的输入图片已经有很大不同了
  - 对于反向过程中的预测网络，选用了非常常规的 U-Net
    - U-Net 最早是 2015 年提出，它是一种 CNN 网络。输入图片 $x$ 经过 encode 逐步下采样，压缩到一个中间结果，然后经过 decoder 逐步上采样恢复到和输入同样维度的 $x'$
    - 为了恢复得更好，encoder 和 decoder 间有一些 skip connection。U-Net 输入和输出维度一致，刚好非常适合 diffusion 的场景
  - 几个疑问
    + 为何每一步的噪声预测网络参数可以共享？
    + 为何不同图片的噪声预测网络参数可以共享？
    + 噪声预测网络本质上学习并且存储的是什么？
      - GPT 中不同序列能共享相同的网络参数是假设输入的文本数据集中同一个 token 不管在哪个句子出现，它遵循相同的生成概率。模型学习并存储（所有）token 以及 token 组合（句子）的生成概率。那 Diffusion Model 呢？

==== 扩散模型的演进
- DDPM
  - 扩散模型早在 2015 年就提出来了，但是它真正产生好的效果走入人们的视野是 2020 年 DDPM 论文之后。DDPM 由 Berkeley 的三位大佬提出，算是扩散模型在图像生成领域的开山之作。
  - 它的贡献主要有两个：
    + 之前人们在扩散过程中想直接实现 $X_t$ 到 $X_(t-1)$，即图像到图像的转换。DDPM 认为直接预测图像比较困难，它转而预测噪声，类似 ResNet 的思想。模型推理预测（前一步添加的）噪声，从输入中减去预测噪声得到一个稍微清晰一点的图片
    + 如果要预测正态分布（噪声），只需要学习它的均值和方差。DDPM 发现甚至连方差都不用学习（设置成一个常数），只学习均值就能取得很好的效果，再次降低模型优化的难度
  - 比较 VAE 与 DDPM，有以下差别：
    + DDPM 这种扩散模型其实和 VAE 有点像，看成是 encoder-decoder 的架构
    + DDPM encoder 是一步步走过来固定的过程，而 VAE encoder 是学习的
    + 扩散过程每一步中间结果的维度都和输入一样，而 VAE 的中间结果 bottleneck 维度比输入小
    + 扩散模型有 time step, time embedding 的概念。每一步的 U-Net 模型共享参数
  - 伪代码
  #fig("/public/assets/Reading/limu_paper/DALLE2/2024-10-15-19-11-18.png", width: 80%)
  - 两个注意点
    + 训练时并没有迭代 $T$ 步，即没有扩散 $T$ 步。从数学上可以证明，前向过程中，$X_T$ 可以直接从 $X_0$ 叠加高斯噪声一步得到，无需 $T$ 步迭代。
    + 推理时，每一步去噪之后，又叠加了一个高斯噪声扰动项 $bz$。这个小小扰动是为了增加 noise，增加不确定性，实验证明它非常有效（正如在文本生成时只选取概率最大的 token 输出效果不好，需要采样增加随机性和多样性）
- improved DDPM
  - 把 DDPM 的常数方差也学了
  - 把产生噪声的 schedule 从线性改成余弦（可以类比学习率的线性 $->$ 余弦）
- Diffusion beats GAN
  - OpenAI 祭出传统艺能，把模型做得又大又宽
  - 用新的归一化方式 adaptive group normalization
  - 引入 classify guidance 引导图像生成，不仅让图像更逼真，也加速了反向采样速度
- classify guidance
  - 额外训练一个 classifier（在加噪图片上），把反向过程的每一步输入传给它，结果去做交叉熵损失函数然后反传得到梯度。
  - 这个梯度暗含了图片是否包含物体或物体是否真实的信息，能够帮助模型训练。它告诉 U-Net  网络，去噪得到的图像不仅仅是意思到了就行，而是真的要包含这样一个逼真的物体
  - 某种程度上是牺牲一点多样性（但依旧比 GAN 好），换取逼真效果
  - 这个 guidance 的方法比较灵活，大家马上就想到使用 CLIP，不光可以用梯度去引导，甚至可以将文本联系起来进行控制。而分开来，也分别可以用 image 去做特征和图像风格层面的引导，用 LLM 去做引导。所有的这些 guidance，都可以被视为是一个条件变量
  - 更进一步，又有人提出 classifer free guidance，在没有另一个模型作为分类器的情况下自己指导自己。训练时要求两个输出 $f_th (x_t,t,y)$ 和 $f_th (x_t,t,emptyset)$，相减得到差距，然后在推理时就大概能知道有条件的结果在哪个方向。这个方法进一步提高了训练开销，但确实是好用的方法
- GLIDE
  - 在之前工作的基础上引入 classifier free guidance，只用 3.5B 就直逼之前 12B 的 DALLE 模型

== DALEE2
- 现在回到 DALEE2
#fig("/public/assets/Reading/limu_paper/DALLE2/2024-10-15-19-14-49.png", width: 70%)
- 虚线上方是 CLIP 模型，下面是 Text2Image 文生图模型。CLIP 模型参数冻结，而文生图模型包含 prior 和 decoder 两个部分
  - 输入文本 $y$ 通过 CLIP text encoder 模型得到 text embedding $bz_t$
  - Prior 模型根据 $bz_t$ 生成 image embedding $bz_i$，记作 $P(bz_i|y)$，Decoder 再根据 $bz_i$ 生成图片 $x$。
  - 文生图的过程像是 CLIP 的逆过程，所以在原论文中 DALLE2 被称为 unCLIP。另外，上面这样变化的合理性有如下保证
  $ P(x|y) = P(x, bz_i|y) = P(x|bz_i, y)P(bz_i|y) $
- Decoder
  - Decoder 继承自 GLIDE 模型。它同时采用了 CLIP guidance 和 classifier free guidance，随机生效
  - 为了生成高清晰度的图片，文章采用了级联的方式，训练了两个上采样模型。一个模型负责从 $64 * 64$ 到 $256 * 256$，另一个模型负责从 $256 * 256$ 到 $1024 * 1024$
  - 另外由于扩散模型使用 U-Net 而不是 Transformer，所以可以不用担心序列长度是否一致的问题，是直接可以去生成更清晰的图片的
- Prior
  - Prior 从输入文本生成一个符合 CLIP 多模态空间的图片向量。文章探索了 AR 和 diffusion 两种方式（两种方式都使用了 classifer free guidance），前者比较贵而不予采用，这里主要介绍 diffusion 方式
  - 输入：encoded text, CLIP text embedding, timestep embedding, noised CLIP image embedding, 占位符 embedding(cls token) 用于做输出
  - label：unnoised CLIP image embedding
  - 模型结构：decoder-only Transformer
  - 从 DDPM 开始大家发现预测 Diffusion 预测残差比较好，但这里最终目标不是图片而是 CLIP image embedding $bz_i$，所以没有用残差
- 其实，模型结构部分文章介绍很少。各种技术细节如果不看源代码很难解释清楚。在此只能简要介绍。另外，图像生成有很多技巧，有些有用有些没用。例如 AR 方式到底好不好用，到底预测噪声好还是预测原始图片好，不同的文章结论不完全一样。其实，这些奇技淫巧不是最重要的，最重要的是规模(scale)，只要能把规模做上去，模型结构上的差异没有那么重要。

== 结果 & 讨论
- 文生图、图生图、图之间内插、文本图像内插
- 局限性
  - DALLE2 不能很好地把物体和它的属性结合起来。例如，输入 prompt "a red cube on top of a blue cube"，DALLE2 不能识别 "on top of" 的语义
    - 其原因可能在于 CLIP 模型只考虑了文本和图片的相似性，而没法学习 "on top of" 这种属性信息
  - 另一个例子，输入 prompt "a sign that says deep learning"，生成的图片确实像一个标语牌，但是上面的文字五花八门，基本都是错误的
    - 其原因可能是文本编码采用了 BPE，是编码词根词缀，不是编码整个单词
    - 后面的讨论提到，这个问题反映了 DALEE2 有一套自己的“方言”，跟人类语言映射错位。DALLE2 发明的这些黑话使得监管更加困难
  - 其它，例如公平性、伦理性、安全性等生成模型老生常谈的问题不再赘述
- 脑洞：自动数据增强，无限套娃
  - 给 GPT-3 输入一段 prompt，用它生成一段文本，再将文本扔给 DALLE2 生成图片，得到无穷无尽的图像文本对，接下来可以用它们训练 CLIP 和 DALLE2。怀疑大公司早就在做了
- 该领域后续发展飞快，google 马上提出 imagen，然后又有开源的 stable diffusion 等……
