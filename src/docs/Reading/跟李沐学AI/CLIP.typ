---
order: 17
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "d2l_paper",
  lang: "zh",
)

= Learning Transferable Visual Models From Natural Language Supervision
- 时间：2021.2

== 标题 & 摘要 & 引言
- Learning *Transferable* Visual Models From Natural Language *Supervision*，利用自然语言监督的信号来训练一个可迁移的视觉文本多模态模型
- zero shot：能够在没有任何训练样本的情况下(no fine-tuning)进行迁移学习，即 transferable
  - 多模态特征适合 zero shot 迁移
- 模型名字叫 CLIP: Contrastive Language-Image Pre-Training
- CV 领域使用有标注的数据仍有诸多限制，而 NLP 领域已经常用无监督学习。CLIP 使用大规模的无监督信号（图像和文本的匹配，近乎无需标注）训练
- 输入是文字和图片的配对，各自通过一个 encoder 得到特征，然后做对比学习（只需要有正样本和负样本的定义即可，配对的样本是正样本，即*矩阵中对角线*是正样本）
  #fig("/public/assets/Reading/limu_paper/CLIP/2024-09-21-17-35-21.png")
- 正常的 CLIP 是没有分类头的，因此要额外进行 prompt template，即将类别转成一个句子（例如 `This is a <class>`）然后抽取文本特征，图片抽取特征，然后计算相似度
- 在预测的时候，把图像进行编码，然后对预先定义的类别进行编码，计算相似度并取最大的类别作为预测结果

== 方法
- 数据集：WIT（WebImage Text）
- 论文的想法实际上并不新，但是之前的工作说法混淆、规模不够大、NLP 模型不够好，当 Transformer 解决 NLP 大一统问题之后容易获得语义特征了
  - CLIP 是 ConVIRT 的简化版本，但是在数据和模型大小上大大提高了
- 之前的预训练工作在 ImageNet1K 上就需要数十个 GPU/TPU 年的训练时间，而 OpenAI 注重效率，所以选择对比学习。而其他 OpenAI 工作都基于 GPT，仅有 CLIP 基于对比学习
  - 一开始采用类似 VirTex，图像 CNN 文本 Transformer，给定图片预测其对应文本。但是图片的描述有很多可能，所以预训练非常慢
  - 当把预测型任务换成对比型任务，判断图片与文本是否是配对就比较简单（生成式变判别式），效率提高 $4$ 倍
- 作者没有使用非线性投影层（之前的对比学习中提升了近 $10$ 个点）因为作者发现多模态中提升不大，只做了随机裁剪的数据增强
- 伪代码
  + 抽取特征
  + 点乘一个 $W$，这个投影是为了将单模态信息转成多模态信息，然后归一化
    - 在多模态里是非常常见的做法，fusion 学习一个 joint representation space（投影到同一个语义空间）
  + 算相似度
  + 算 loss，正样本是对角线上，对称式的 loss 函数
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
  - Few Shot 的结果：其中 BiT 为 Big Transfer，本身就是谷歌为了迁移学习设计的
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
- 文本经过 Encoder 得到文本特征，图像经过 Encoder 得到图像特征，然后进行文本图像对的对比学习
- 做分类任务的时候：将类别通过 prompt template 通过文本编码器形成很多 query，然后图像通过图像编码器得到一个图像特征，然后相当于依次问 query，得到图像特征和文本特征之间的相似度


= CLIP 改进工作（串讲）
== 分割
- 图像分割本质上和分类很像，只是把分类的粒度变成了像素级别。这就导致每当分类有了什么突破，分割领域马上就能有所跟进，CLIP 也不例外
- CLIP 出来以后，大家要么是用一下 CLIP 预训练的参数做一些简单的改动把它和下游任务结合起来(LSeg)；要么是利用 CLIP 目标函数(GroupViT)，或者它的其它特性

=== Language-Driven Semantic Segmentation(LSeg)
- 模型总览图
  - 跟 CLIP 有点像但其实不是 zero-shot，本质上还是在传统的有监督训练中引入了文本那一支信息。它终究不是无监督学习，目标函数也不是对比学习
  - 跟 CLIP 的区别主要是说，图像这边输入是一张图片，抽取的特征是一个 dense feature 而不是 CLIP 那种一张图一个向量
  - 图像这边经过一个 encoder(DPT: ViT + Transformer)，得到 $tilde(H) times tilde(W) times C$ 的特征；文本那边经过 encoder 得到 $N times C$ 的特征。两边一乘就得到 $tilde(H) times tilde(W) times N$，也就是回到了传统有监督分割的领域
    - text encoder 用的就是纯 CLIP 冻结参数，image encoder 可以也这样做但效果不如自己整一个（基于实验科学）
  - 然后最后还多了一个 spacial regularization block 来多学习一点（其实不是很重要，随便一个 MLP 就可以）
  #fig("/public/assets/Reading/limu_paper/CLIP/2024-09-23-12-04-50.png")
- 实验的话，把 PASCAL, COCO 等数据集均分，在其中一份上训练然后 zero-shot 到其它份。结果来看，比以往的 zero-shot 或 few-shot 都好不少，但比监督训练（ResNet，非 large model）还是差了不少

=== Semantic Segmentation Emerges from Text Supervision(GroupViT)
- 介绍
  - Grouping 是 CV 分割方面已有的一个技术，利用区域生长的思想（自下而上地从聚类中心开始发散）
  - GroupViT 在已有 ViT 的框架中加入 group blocks 和可学习的 group tokens
- 训练
  - 首先依旧是把图像分成 patch，然后把 patch embedding 送到 Transformer 里面，但是要加上 group tokens
    - group tokens 可以理解成之前的 cls token，但之前是想学到每个图片一个特征，现在是多个特征用来分割，把那些语义相似的点归结到这 $64$ 个 clusters 里面。
  - 经过一系列 Transformer Layers 互相学习之后，group tokens 学得差不多了。然后用 group blocks 把图像 patch embedding 给 assign 到 group tokens 里去（相当于合并为更大的 group，同时也是一种减小序列复杂度）
  - 用类似 attention 的机制算一个相似度，然后用 gumbel softmax 完成可导（argmax 不可导）的聚类分配，实现降维和合并
  - 这些新的 tokens 就看做之前的 patch embedding tokens，再加入一些 group tokens 来重复以上过程，得到 $8$ 个大的 group tokens
  - （为了跟 CLIP 对齐）这学到的 $8$ 大块特征做一个 avg pooling（相当于 $8$ 个类别物体特征融合来表征这一张图片）再 MLP 一下，然后这张图对应的文本那边跟 CLIP 一样 encoder 得到一个特征，然后后续就跟 CLIP 一样做 contrastive learning
  #fig("/public/assets/Reading/limu_paper/CLIP/2024-09-30-11-08-57.png")
- 推理
  - 然后是如何做 zero-shot 推理，图像经过左边的编码器得到 $8$ 个类别特征，右边各种 class 经过 prompt 和 text encoder 得到文本特征，算相似度
  - 另外，为了区分出背景类，需要设置一个阈值，低于这个值就认为是背景，这个值比较讲究，低了可能会导致错误分类，高了会导致全是背景类
  - 感觉这边训练和推理不是很一致？另外不是很懂分割领域里面最后 group 究竟是怎么还原回原图的
    - （？）group token 对应回图像靠的就是把 gumbel_softmax 再变成 argmax，这样就知道某个 group token 具体对应哪些像素了
  #fig("/public/assets/Reading/limu_paper/CLIP/2024-09-30-10-24-57.png")
- 结果
  - 可视化：stage 1 的分割比较小（眼睛、四肢），stage 2 的分割就大了一点（草地、狗）。
  - 数值上比较，比之前的自监督方法高了不少，但跟有监督方法还是差了不少（30 个点），不过这毕竟是首个将文本信号应用在自监督分割分割的第一个工作
- 目前的局限性
  + 更多是一个图像 encoder，没有很好地利用 dense prediction 的特性
    - Dilated Convolution, pyramid pooling, U-Net 等，获得更多的上下文信息和多尺度信息
  + 另一个就是分类阈值的问题难以界定，以及（实验证实）模型其实分割对了，但是分类错了（这个主要怪 CLIP 只能学到明确的物体信息，对模糊的代表很多很多类的背景学得不太好）
    - 改进思路，根据每个类各自设置阈值，阈值可学习，调整 zero-shot 推理过程，训练中加入背景概念的约束等

== 目标检测
=== Open-vocabulary Object Detection via Vision and Language Knowledge Distillation(ViLD)
- 时间：2021.4
- 目标检测一般要比分类分割复杂一些，但丝毫不影响这篇文章出来的速度（两个月做大规模实验+投稿，太卷了）
- 看到标题就知道是把 CLIP 当做 teacher 进行蒸馏的工作
- 这篇文章的引言非常好，上来就是一张图，展示模型能力的同时根据这张图问出论文想要解决的问题：open-vocabulary 的目标检测
  #fig("/public/assets/Reading/limu_paper/CLIP/2024-09-30-10-25-32.png")
- 模型总览图
  - 这篇论文有点把锚框的提出和分类解耦的意思，图里都只画了第二阶段，即 proposal 拿到之后再开始做
  #fig("/public/assets/Reading/limu_paper/CLIP/2024-09-30-10-28-06.png")
- 方法部分，分别为 vanilla detector 作为 baseline，然后 ViLD-text 和 ViLD-image，两支合在一起得到 ViLD，最后还有 ViLD-ensemble
  1. *baseline* 其实就是一个 maskRCNN，为两阶段分类器，第一阶段提出 N 个 region proposal，过一个 detection head 得到 region embedding，过 classifier 得到分类
  2. *ViLD-text*，和 CLIP 的思路差不多，都是图像文本分别抽特征算相似度。图像这边跟 baseline 相比，就只多了 projection layer 和 L2-norm，得到 region embedding；图像那边用冻结的 CLIP text-encoder 得到 embedding，concatenate 上可学习的背景类 embedding。两边特征做点乘得到相似度，与 ground truth 有监督地算 cross entropy loss。目前为止都是 classify base(CB)，对于不在基础类中的物体都塞给背景
  - 那如何拓展到 classify novel(CN) 呢？于是提出了 ViLD-image。主要思路是说，CLIP 那边的图像和文本 encoder 都做得很好，那我这边既然用了 text-encoder ，那图像 encoder 得到的 embedding 跟 CLIP 尽可能一致就好了，于是引出知识蒸馏
  3. *ViLD-image*，具体而言，就是把 region proposal 经过裁剪和变换 送入作为 teacher 的 CLIP-image，预测结果替换 ground truth 做一个 L1-loss。现在预测不再局限于 CB，而是 CB+CN
    - 另外有点怀疑这篇文章就是蒸馏了一下 CLIP，然后包装了个比较好的运用结果而已……
    - 为了让训练更快，避免 region proposal 反复前向 CLIP image-encoder 造成极大计算负担，image embedding 其实是预先 RPN 得到、裁剪变换并前向算完的，蒸馏的时候只需要从硬盘 load
  - *ViLD*，最后把 ViLD-text 和 ViLD-iamge 合并，相当于在训练的时候有两个目标函数（测试的时候右边 image 那一支是丢掉的）
- 最后 ViLD 模型的汇总图
  #fig("/public/assets/Reading/limu_paper/CLIP/2024-09-30-10-33-37.png")
- 实验结果
  - 在 LVIS 数据集上实验（一个基于 COCO 的长尾数据集），把其中的 $A P_c$, $A P_f$（$A P$ 是目标检测常用指标，为“准确率-召回率”曲线下方的面积） 作为 CB 来训练，把只见过一两次的记作 $A P_r$，看作 zero-shot 推理
  - 表格显示，用 ResNet-50 作为 backbone，Supervised + RFS(repeated factor sampling)作为 baseline 只有 $12.3%$，ViLD 可以达到 $16.1%$
    - 但其实这是可以理解的，因为 baseline 即使重采样了，它也没见过几次新类别，没怎么发挥 Supervised 效果，而 ViLD 仅比它好一点，略微有些取巧。从总的 $A P$ 来看，ViLD 比 baseline 还弱一点
    - 不过，换用更强的 backbone 以后，它的效果变得更强，仅比 2020 性能冠军弱一点，还是有实力的
  - 另外作为 zero-shot 的模型，肯定是可以直接用到其它数据集上的，于是就用到 PASAL, VOC 2007, COCO, Objects365 上，结果显示跟这些数据集上 Supervised 模型比还是有一定差距
- 评价
  - ViLD 是第一个在 LVIS 这么难的数据集上做 open-vocabulary 的目标检测的工作，还是有里程碑意义的
  - 它使用了 CLIP 的预训练参数，借鉴 CLIP 的一些思想，得到了不错的效果

=== Grounded Language Image Pre-training(GLIP)
#let Enc = math.text("Enc")
#let Img = math.text("Img")
#let cls = math.text("cls")
#let loc = math.text("loc")
#let Lf = math.cal("L")
- 时间：2021.12
- 对标分割领域的 Group-ViT，目标检测这边的 GLIP，名字上跟 CLIP 相比只是把 contrast 换成 grounded
- 研究动机
  - 跟分割一样，精心标注的数据很贵，希望用一个巨大的预训练模型处理 open-vocabulary case，所以希望像 CLIP 一样利用图像文本对
  - Vision Language 里有一类下游任务是给一段话把图像里对应物体圈出来，这种 phrase grounding 任务和 object detection 结合，同时如果再加入伪标签那一系列 self-training 的方法，就能大大扩大数据集了
- loss 处理
  - 目标检测这边的 loss 一般是 $Lf = Lf_cls + Lf_loc$，后者其实大家都差不多，主要根据模型和锚框生成方式决定；但是分类 loss 就不一样了，而且对于这里 object detection（label 是一个 one-hot 单词） 和 visual grounding（label 是一个句子）的处理是不一样的，我们需要把它统一到一个框架里
  - *object detection* 这边相对简单，$O in RR^(N times d), W in RR^(c times d), S_cls in RR^(N times c), T in {0, 1}^(N times c)$，分别为 region embedding, classifier weight, ground truth
    $ O = Enc_I (Img), S_cls = O W^T, Lf_cls = "loss"(S_cls;T) $
    - 图像先经过图像 encoder 得到目标/区域特征 $O$，然后经过一个分类头（也就是乘权重矩阵 $W$），得到输出类别的 logits，然后计算与真实类别的 cross entropy loss
  - *visual grounding* 这边相对复杂，$P in RR^(M times d), S_"ground" in RR^(N times M)$ 为 text embedding 和点乘得到的相似度
    $ O = Enc_I (Img), P = Enc_L ("Prompt"), S_"ground" = O P^T, Lf_cls = "loss"(S_"ground";T') $
    - 这里的操作其实类似于 ViLD 中的 ViLD-text 分支，图像和句子分别经过各自的 encoder 得到 feature embedding，然后计算匹配度。但现在得到的 region-word aligment scores $S_"ground"$ 跟 ground truth 不匹配，(sub)-word tokens 的数量 $M$ 总是比 text prompt 中的 phrases 数量 $c$ 要大
    - 作者列了 $4$ 个原因，在此从略。解决方法是，如果一个 phrase 是正匹配，那么所有 sub-words 都是正匹配，且额外添加的 tokens 对所有 image features 都是负匹配，这样把 $T$ 转化为 $T'in {0, 1}^(N times M)$（？）
  - 其实这两种方式都差不多，只需要小小改动 positive match 和 negative match 的方式就能联合起来。作者在小数据集上确认了方法的有效性，然后迁移到大数据集上
  - #wrap-content(
    [具体是怎么个迁移法呢？首先对于 object 数据集和 grounding 数据集是可以拿来直接用的，然后又想利用图像文本对(caption)数据，但这些数据没有 bounding box label，所以采用了伪标签的形式 —— 把前面训的小模型的推理结果拿来当 ground truth，这样大大增大了数据集量],
    fig("/public/assets/Reading/limu_paper/CLIP/2024-10-03-15-44-32.png"),
    columns: (50%, 50%)
  )
- 然后来看模型总览图
  #fig("/public/assets/Reading/limu_paper/CLIP/2024-10-01-00-02-18.png")
  - 首先两个模态经过 encoder 得到 embedding``
  - Deep Fusion：得到 embedding 后，理论上可以直接计算相似度了，但是直接算的话，图像文本的 joint embedding space 还没有学的很好（Lseg 通过 conv 继续学习）。多加一些层数融合一下，最后算相似度也更有针对性。具体就是用 cross attention 交互了一下
  - 然后就是用上面的方式算一下 $Lf_cls$，再用 L1-loss 另外算一下 $Lf_loc$，这样训练
- 结果
  - 同期的一些纯视觉工作(DyHead, SoftTeacher)没有 zero-shot 能力，但是经过微调后在 COCO 数据集上能够达到 $60$ 左右的 AP。GLIP-L 具有 zero-shot 的能力，能够达到将近 $50$ 的 AP，而且微调后也能达到 $60$ 多一点的 AP。整体来看效果还是不错的。
- 后续还推出了 GLIPv2，又多加了几个任务（Object Detection, Instance Segmentation, Vision Grounding, Visual Question Answering, Image Captioning 等全放一起，把 text encoder 变得更花哨），这某种程度上也算是一种多模态任务的趋势，能用更多的数据把模型训练得又大又好
  #fig("/public/assets/Reading/limu_paper/CLIP/2024-10-03-17-04-04.png")

== AIGC
=== CLIP Passo：Semantically-Aware Object Sketching
- 时间：2022.2
- 其实是一篇计算机图形学领域的文章（CG, CV 交叉）
- 研究动机：标题为保持语义信息的物体素描，CLIP + Picasso。把*图片变成简笔画*的形式，可生成*各种层次的主要轮廓*并且保留其*主要视觉特征*。不仅要把原来的物体变成非常简单的形象，也需要模型抓住原来物体最关键的一些特征
- 相关工作
  - 之前的研究都是取收集好的、抽象层次固定的数据集，属于一种 data driven 的方式。这种方式生成的素描画在风格和形式上受到限制，违背图像生成的初衷（不同层次），同时种类不能做到很丰富。
  - 相比之下，CLIP 由于图像语义配对的学习方式，对物体的语义信息抓取的特别好，而且又有出色的 zero-shot 能力，不受图像风格的限制，能把图像特征编码的非常好。
- 主体方法
  #fig("/public/assets/Reading/limu_paper/CLIP/2024-10-03-17-19-37.png")
  - 任务就是在白纸上随机生成 Bezier 曲线，然后通过不停的训练，这些曲线就组合成了简笔画
  - 具体来说，先*初始化参数*，然后通过 Rasterizer 将笔画映射到二维画布上
    - 这个 Rasterizer 怎么跟我熟知的不太一样。。。不是三维物体、相机、光源 $->$ 二维图像的嘛？
  - 文章的主要贡献有两点
    + 一是一开始如何选择更好的初始化(saliency)：用一个训练好的 ViT，把最后一个多头自注意力取加权平均做成 saliency MAP，在这些映射上去看哪些特征更显著，然后在显著的区域上去采点（在显著的区域上采点，就是已经知道了一个物体或者说物体边界去画贝兹曲线了）
    + 二是选择了一个更合适的目标函数（CLIP 作为 teacher 作蒸馏）和损失函数（Lg：模型前几层的输出，即 低层次的空间信息——动作或位置、结构 尽可能接近；Ls：简笔画和原始图像的特征应尽可能接近）
  - 为了更好的效果，会多生成几张分别算 loss，最后输出最小的那张
- 亮点
  + 训练很快，一张 V100 能在 6 分钟完成 2000 次迭代
  + 不受物体类别限制，可以为不常见的物体生成简笔画
  + 通过笔画数任意控制抽象程度
- 局限性
  + 图像有背景时，效果大打折扣；可以用别的模型抠掉背景做 2-step 的方式，但不够 end2end；未来可以考虑把这种 mask 设计到 loss function 里面
  + 简笔画是同时生成而非逐步序列，不像人；加入 auto regressive 的方式
  + 提前设定的笔画数一方面很灵活，但另一方面对不同图片不方便；考虑把这作为 learnalbe parameter

== 视频理解
=== CLIP4Clip: An Empirical Study of CLIP for end to end Video Clip Retrieval and Captioning
- 时间：2021.4
- 视频检索，video text retrieval，根据文本检索最相关的视频片段
- 标题玩了个双关，CLIP 模型用作 clip 视频片段
- CLIP 模型本身很适合做 Retrieval 任务，因为它就是做图像和文本之间相似性，根据相似性可以去做 ranking, atching, retrieve 等任务。而且由于双塔结构（图像文本编码器分开），得到的 image, text embedding 做一步点乘就可以计算相似度，因此非常容易扩展（比如并行、预提取之类的）
- 模型
  #fig("/public/assets/Reading/limu_paper/CLIP/2024-10-03-19-08-34.png")
  - 文本这边没什么区别，得到 text embedding，视频这边多了时间维度。$N$ 个视频帧每一帧打成 patch 作为编码器输入，得到 $N$ 个 CLS Token。每个文本特征对应 $N$ 个图像特征，该怎么算相似度呢？本文是一个 Empirical Study，就把以往的三种方法都尝试了一遍，选出来最好的
  + *Parameter-free type*，最简单的做法，直接对时间维度取 mean pooling。但是这种方法没有考虑时序的特性，也就是前后帧之间先后关系（e.g. 一个人坐下和站起）。即使如此，这种方式也是目前最被接受的方式
  + *Sequential Type*，时序信息 + Positional encoding，用 LSTM / Transformer Encoder 建模。属于 Late FUsion（文本和图像特征抽完之后融合）
  + *Tight Type*，属于 Early Fusion。用 Transformer Encoder 将文本和 $N$ 个图像帧直接融合，用 MLP 直接输出相似度特征。有点像是把文本特征作为 cls token，不仅融合了时序信息，还同时融合了图文信息
- 实验结果与 insight
  + CLIP 的预训练模型很能打，微调或 zero-shot 都比之前方法提高 $20$ 多个点
  + 如果训练数据量不那么大，Mean pooling 这种非学习方法效果反而是最好的。而 Tight Type 可能是由于下游任务数据量少过拟合的原因，效果较差
  + 图像转到视频，存在域偏差(domain gap)，如果视频这边找到足够多的数据集再去预训练，这样迁移的效果会更好
  + 视频 ViT 领域的 2D patch 和 3D patch。2D patch 在这里效果更好一些，但 3D 也很有前途
  + CLIP 用在 video text retrieval 领域，学习率这个参数非常敏感

=== Action CLIP：A New Paradigm for Video Action Recognition
- 时间：2021.9
- 动作识别，本质上是加了时序信息的分类任务，自然很容易应用 CLIP
- 传统的动作识别模型
  - 视频进一个 encoder(2D/3D)，与有标签的 ground thuth 计算 loss。
  - 受限于有监督学习，难以做大数据集的规模；
  - 并且不像图像分类那种“一一对应”关系，在视频动作识别中，比如"open the door"一个短语对应三个单词，另外，open 这个词可以描述很多动作。这时就有一个 trade off
    + 如果标记很多类，人工标注成本提高，softmax 效果也不好，常规的分类算法可能表现都很差
    + 如果只标注大类，就无法预测细粒度的小类
    - 最理想的方法就是摆脱标签的限制，从大量的视频数据中学一个好的特征，然后再去 zero-shot 或者 few-shot 迁移至下游任务。于是自然想到 CLIP
- 那这篇论文改进了什么呢？
  + 一是如何让 image encoder 能处理视频，也就是每一帧的特征如何与文本特征计算相似度，这与 CLIP4clip 非常类似
  + 二是动作识别领域的标签矩阵，当数据集相对小且 batch 比较大的时候，不是对角线的地方也可能是正样本（比如一个 batch 中可能有多个描述跑的动作）。这个问题将交叉熵损失换成 KL 散度（衡量两个分布的相似性）就可以解决
#grid(
  columns: (30%, 70%),
  column-gutter: 4pt,
  align: horizon,
  fig("/public/assets/Reading/limu_paper/CLIP/2024-10-03-19-46-03.png"),
  fig("/public/assets/Reading/limu_paper/CLIP/2024-10-03-19-46-39.png")
)
- 主体架构
  - 视频和文本变成 token 后经过各自的 encoder，得到各自的特征后计算相似度然后与 ground truth 计算损失（KL 散度）
  - 但是加了 Textual Prompt, Pre-network Prompt, In-network Prompt, Post-network Prompt 来加快迁移。其实除了文本的那个算是正统 prompt，其它三个都是为了写作连贯性而称作 prompt 罢了
  + Pre-network Prompt: Joint。输入层面加入了时序信息，即 Temporal Encoding
  + In-network Prompt: Shift。每个 ViT 模块间加入 shift 模块，在特征图上做各种移动，zero cost 地达到更强的特征建模能力
  + Post-network Prompt: Transf。就是 CLIP4clip 中的三种相似度计算，一模一样
  - 感觉有点搭积木（
- 实验结果（消融实验）
  + 多模态的框架(ActionCLIP)表现不错，相较于单模态(Unimodality)的框架可以提升 2-3 个点。也就是说用 Language guidance 的方式更合理
  + Pre-train 是否重要？毋庸置疑，不用预训练疯狂掉点，不过值得注意的是 Vision 这边对 pre-train 的依赖性明显比 Language 那边要强
  + Prompt 是否重要？文本不用 prompt 基本不掉点，但是视觉这边，如果不用 joint，会掉 $2.74$ 个点，如果不用 shift，会掉 $5.38$ 个点（都用 MeanP）。另外这里在 post-network 中平均池化的效果不是最好的了，原因应该是数据量相对大了
  + Fine-tune 和 zero-shot 的比较。以往模型的 zero-shot 能力为零，如果 zero-shot 的话，大家都在涨点，但 ActionCLIP 依旧碾压

== 其它
- 快速过一下其它文章
+ How Much Can CLIP Benefit Vision-and-Language Tasks?(CLIP-ViL)：第一个大规模把 CLIP 作为预训练模型应用到各种下游任务上的 Empirical Study，答案是效果不错，没什么创新
+ AudioCLIP:Extending CLIP to Image, Text and Audio\*
  #fig("/public/assets/Reading/limu_paper/CLIP/2024-10-03-20-20-07.png")
  - 音视频里面，语言、视频、音频基本是成对出现的，很容易模仿 CLIP 的方式加音频模块，单个模态两两算相似度矩阵最后 loss 加起来
+ PointCLIP: Point Cloud Understanding by CLIP
  - 把 2D 图像的 CLIP 应用到 3D 的点云，想法就是把点云做成深度图（深度放在颜色那一位）。因为 CLIP 啥都见过所以这个也能迁移，效果还不错
+ Can Language Understand Depth?
  - CLIP 在物体抓取很有实力，但对比学习在学概念方面不是很好，深度也有点概念的意思，因此验证一下
  - 想法跟上面那篇一样，然后把深度硬分类成 giant, close, far 等（回归任务变成分类任务），非常巧妙地运用了 CLIP

== 总结
- 对 CLIP 模型的使用基本是 $3$ 种
+ 使用 CLIP 来抽特征，原有框架不动，只是用更好的特征加强我模型的训练，改动最小的方式
+ 拿 CLIP 作为 teacher 来蒸馏，不论我是什么模态还是 2D/3D，都可以借助 CLIP 更快收敛
+ 不借助 CLIP 预训练参数，但借用它多模态对比学习的思想，定义自己的正负样本
- 总而言之，在大模型当道的当下，不可能对每一个任务都训练大模型，而是借助大模型并加上可学习的小模块，可能会是一个更有用而且*更做得动*的方向