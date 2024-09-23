// ---
// order: 17
// ---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "d2l_paper",
  lang: "zh",
)

= CLIP: Contrastive Language-Image Pre-Training

== 标题 & 摘要 & 引言
- Learning *Transferable* Visual Models From Natural Language *Supervision*，利用自然语言监督的信号来训练一个可迁移的视觉文本多模态模型
- zero shot：能够在没有任何训练样本的情况下(no fine-tuning)进行迁移学习，即 transferable
  - 多模态特征适合 zero shot 迁移
- CV 领域使用有标注的数据仍有诸多限制，而 NLP领域已经常用无监督学习。CLIP 使用大规模的无监督信号（图像和文本的匹配，近乎无需标注）训练

- 输入是文字和图片的配对，各自通过一个encoder得到特征，然后做对比学习（只需要有正样本和负样本的定义即可，配对的样本是正样本，即*矩阵中对角线*是正样本）
#fig("/public/assets/Reading/limu_paper/CLIP/2024-09-21-17-35-21.png")

- 正常的 CLIP 是没有分类头的，因此要额外进行 prompt template，即将类别转成一个句子（例如 `This is a <class>`）然后抽取文本特征，图片抽取特征，然后计算相似度
- 在预测的时候，把图像进行编码，然后对预先定义的类别进行编码，计算相似度并取最大的类别作为预测结果

== 方法
- 数据集：WIT（WebImage Text）

- 论文的想法实际上并不新，但是之前的工作说法混淆、规模不够大、NLP模型不够好，当Transformer解决NLP大一统问题之后容易获得语义特征了
  - CLIP 是 ConVIRT 的简化版本，但是在数据和模型大小上大大提高了

- 之前的预训练工作在ImageNet1K上就需要数十个GPU/TPU年的训练时间，而OpenAI注重效率，所以选择对比学习。而其他OpenAI工作都基于GPT，仅有CLIP基于对比学习
  - 一开始采用类似VirTex，图像CNN文本Transformer，给定图片预测其对应文本。但是图片的描述有很多可能，所以预训练非常慢
  - 当把预测型任务换成对比型任务，判断图片与文本是否是配对就比较简单（生成式变判别式），效率提高4倍

- 作者没有使用非线性投影层（之前的对比学习中提升了近10个点）因为作者发现多模态中提升不大，只做了随机裁剪的数据增强

- 伪代码
  + 抽取特征
  + 中会点乘一个$W$，这个投影是为了将单模态信息转成多模态信息，然后归一化。
  + 算相似度。第四步算loss，正样本是对角线上，对称式的loss函数
#fig("/public/assets/Reading/limu_paper/CLIP/2024-09-22-13-01-48.png")

- 关于大模型训练，参考：#link("https://lilianweng.github.io/posts/2021-09-25-train-large")[How to Train Really Large Models on Many GPUs? | Lil'Log]

== 实验
- 之前的自监督无监督学习到一个特征之后，还需要对下游任务做有监督的微调
- prompt engineering and ensembling
  - 为什么要 prompt：比如 ImageNet 中有两个类 construction crane（起重机）和 crane（鹤），文本多义性可能导致问题；另外输入输出要尽可能保持一致，避免 distribution gap
  - 作者使用 prompt template，类似 `A phot of {label}`，还可以加一些例如 `A photo of {label}, a type of pet`
  - ensemble，用多种提示模板，CLIP 共使用了 $80$ 个模板
- 大规模迁移学习结果：
  - 这里 Linear Probe 表示将前面的模型 freeze 掉只从中抽特征，然后训练一个 FC 来做分类任务。普通物体 zero shot 任务比较好，但是比较难的任务（DTD 纹理分类，CLEVRCounts 物体计数）效果一般
  #fig("/public/assets/Reading/limu_paper/CLIP/2024-09-22-13-39-33.png")
  - Few Shot的结果：其中 BiT 为 Big Transfer，本身就是谷歌为了迁移学习设计的
  #fig("/public/assets/Reading/limu_paper/CLIP/2024-09-22-13-39-43.png")
  - 所有数据：略
- 和人类对比的实验，图一乐
- 去重实验，证明泛化性强

== 讨论 & 局限性
- 目前和基线模型水平相近，但和 SOTA 水平还有差距，同时扩大 CLIP 规模也很难实现 SOTA
- 在某些细分类任务或抽象概念效果很差，不知道什么是异常什么是安全
- 虽然 zero shot 在某些数据集还可以，但是如果推理和训练的数据差的太远，还是不行的，out-of-distribution（例如 MNIST，原因是 $4$ 亿数据集中都是自然图片，没有合成数字图片）
- CLIP 需要给一个类别来判断，不能做到图片加 caption 这种生成。之后可能会把对比式和生成式的目标函数合在一起
- CLIP 对数据利用效率不高；另外数据是从网上爬的，没有被清洗过，存在偏见和可能的不当使用
- CLIP 存在用 ImageNet test 训练的问题，$27$ 个数据集也用到了，最好有一个专门的用来 zero-shot 的数据集
- 复杂的任务或概念不能用语言描述，所以做下游任务泛化的时候能提供一些训练样本(Few-Shot)也是有必要的，但是 CLIP 的提出不是为了 Few-Shot，所以会有提供一些训练样本还不如 zero-shot 的情况，和人不太一样

== 总结
- 文本经过Encoder得到文本特征，图像经过Encoder得到图像特征，然后进行文本图像对的对比学习
- 做分类任务的时候：将类别通过prompt template通过文本编码器形成很多query，然后图像通过图像编码器得到一个图像特征，然后相当于依次问query，得到图像特征和文本特征之间的相似度


= CLIP 改进工作（串讲）
== 分割(Language-Driven Semantic Segmentation)
- 图像分割本质上和分类很像，只是把分类的粒度变成了像素级别。这就导致每当分类有了什么突破，分割领域马上就能有所跟进，CLIP 也不例外
- 模型总览图
  - 跟 CLIP 有点像但其实不是 zero-shot，本质上还是在传统的有监督训练中引入了文本那一支信息
  - 图像这边经过一个 encoder(DPT: ViT + Transformer)，得到 $tilde(H) times tilde(W) times C$ 的特征；文本那边经过 encoder 得到 $N times C$ 的特征。两边一乘就得到 $tilde(H) times tilde(W) times N$，也就是回到了传统有监督分割的领域
  #fig("/public/assets/temp/2024-09-23-12-04-50.png")






