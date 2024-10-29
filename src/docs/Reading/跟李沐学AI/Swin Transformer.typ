// ---
// order: 14
// ---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "d2l_paper",
  lang: "zh",
)

= Swin Transformer: Hierarchical Vision Transformer using Shifted Windows
- 时间：2021.5
- Swin Transformer 为 ICCV21 最佳论文，是 ViT 之后，第二个证明 Transformer 在 CV 领域强大表现的工作
- 此外，作者团队发布了一系列基于 swin transformer 的工作，比如自监督版本的 MoBY、视频领域的 video-swin-transformer、应用 swin 思想的 MLP 版本 Swin MLP 以及半监督目标检测 Soft Teacher、基于掩码自监督学习的 SimMIM 等，基本把视觉领域所有的任务都刷了个遍。范围广、效果好、影响力大，成了视觉领域绕不开的 baseline

== 标题 & 摘要 & 引言
- 标题：用了 Shifted Windows 的 Hierarchical 的 ViT
  - 就是想让 ViT 像 CNN 一样，也能够分成几个 block，做层级式的特征提取，从而让提出来的特征有多尺度的概念
- 论文提出 Swin Transformer 可以作为 CV 领域通用的骨干网络。之所以这么说，是因为 ViT 只做了分类任务，把下游任务（e.g., 检测、分割）留给后人探索。Swin Transformer 证明使用 Transformer 没毛病，绝对能在方方面面上取代 CNN
- 直接把 Transformer 从 NLP 应用到 Vision 的挑战：
  - *尺度*：同一个语义的物体在图片中具有不同的尺度，这是 NLP 中没有的情况
  - *Resolution*：如果以图片像素作为基本单位，序列的长度会剧烈膨胀，以往工作往往将处理后的特征图来当做 Transformer 的输入，或者把图片打成 patch
- 基于此提出 Shifted Windows
  - 自注意力在窗口内计算，序列长度大大降低，计算复杂度随着图像大小线性增长（而不是平方增长），为作者之后在更大分辨率上预训练模型并提出 Swin-V2 铺平了道路；
  - 层级式结构非常灵活，可以提供各个尺度的特征信息；同时 shifting 操作让相邻两个窗口之间有了交互，上下层之间就可以有 cross-window connection，变相地达到了全局建模的能力
- 引言里的 fig 1 对 Swin Transformer 和 ViT 做了对比
  - ViT 使用 $16 * 16$ 的 patch size，始终是 $16 times$ 的下采样率。它可以通过全局的自注意力操作达到全局建模能力，但是它对多尺寸特征的把握就会弱一些
  - 插播：我们知道，对于视觉任务，尤其是下游任务（e.g., 检测和分割）来说，多尺寸特征至关重要的
    - 对目标检测而言，运用最广的一个方法就是 FPN(feature pyramid network)：使用分层式的 CNN，每一个卷积层的感受野(receptive field)不同，能抓住物体不同尺寸的特征；
    - 对物体分割而言，最常见的一个网络是 U-Net，U-Net 使用 encoder-bottleneck-decoder 的架构，为了处理多尺度物体的问题，使用 skip connection 的方法，让高频率的图像细节能恢复出来。分割里常用的网络结构还有 PspNet、DeepLab，这些工作里也有相应的处理多尺寸的方法，比如说使用空洞卷积、psp 和 aspp 层等
    - 但是在 ViT 里，处理的特征自始至终都是单一尺寸（$16$ 倍下采样后的特征），而且是 low resolution，就不适合处理这种密集预测型的任务。另外一点是它的自注意力在最大的窗口上进行，计算复杂度随图像尺寸平方增长
  #fig("/public/assets/Reading/limu_paper/Swin Transformer/2024-10-27-18-58-35.png", width: 50%)
- Swin Transformer 的效果是非常好的，在视觉领域大杀四方，作者对此展望了 CV 和 NLP 大一统的未来
  - 但其实在 unified network 这一点上，ViT 还是做的更好的，因为它真的可以什么模态特征都不考虑，直接拼接起来送入共享参数的模型里（相比之下 Swin Transformer 更多还是利用了视觉这边的先验信息）
  - 另外 Swin Transformer 比较大的创新点就是 shifted window，它未来需要证明这对 NLP 也是有效的，才能真正把大一统的故事讲得圆满

== 具体架构
- 为了减少序列长度，Swin Transformer 在窗口内算自注意力，每个窗口内包含的 patch 数量不变的（每个窗口的计算量不变），当图像大小（面积）增长 $x$ 倍，窗口数量也增长 $x$ 倍，从而计算复杂度随图像尺寸线性增长（如果把图像边长作为 $x$ 的话，就是从原来的 $x^4 -> x^2$）
  - 这个感觉跟 transformer 的 global attention 性质就相违背，有点部分牺牲全局建模能力换取计算效率的感觉
  - 但由于利用了 CNN 里 locality 的 inductive bias，即使是在一个局部小范围的窗口算自注意力也够用，全局计算自注意力对于视觉任务来说有点浪费资源，所以也不算特别大的牺牲。更何况后续还用 shift 操作增加了窗口之间的交互，部分弥补了这一点
- 另外一个挑战是如何生成多尺寸的特征
  - CNN 生成多尺寸特征主要是靠 Pooling 操作，增大每一个卷积核的感受野，从而每次池化过后的特征能抓住物体的不同尺寸
  - 类似的，Swin Transformer 也提出来一个操作叫 *patch merging*，把相邻的小 patch 合成一个大 patch，这样合并出来的大 patch 就能看到之前四个小 patch 看到的内容，增大了感受野，能捕捉多尺寸特征
  - Swin Transformer 是个通用的骨干网络，对密集预测型任务友好，有了这些多尺寸的特征图以后，后续可以接各种 U-Net, FPN 等架构
- Shifted Windows
  - 如图 (b) 所示，论文里一个窗口默认为 $7 * 7$ 个 patch，这里只是图例
  - shift 操作就是往右下角的方向整体移了两个 patch，在新的特征图里把它再次分成四方格
  - 如果按照原来的方式，窗口之间永不重叠，就真的变成了孤立自注意力，达不到使用 Transformer 的初衷。现在加上 shift 操作，一个 patch 就可以跟新的窗口里别的 patch 进行交互，而新的窗口里所有 patch 其实来自于上一层别的窗口里的 patch
  - 这也就是作者说的 cross-window connection。配合之后提出的 patch merging，合并到 Transformer 最后几层的时候，每一个 patch 本身的感受野就已经很大，再加上 shifted Windows 操作，所谓窗口内的局部注意力其实也就变相等于全局的自注意力
- 模型总览图画的十分清晰：
  - *stage 1*：首先上来 Patch Parition + Linear Embedding 其实就相当于 ViT 里的 Patch Projection，在代码里也是通过一次卷积就完成了，输出为 $H * W * C$，其中论文里 $C=96$
  - 紧接着是 swin transformer block。使用*基于窗口的自注意力计算*，内部操作暂时当做黑盒，依据 transformer 的特性输入输出的 shape 保持一致
  - *stage 2*：提出 Patch Merging 的操作以达到 pooling 的效果，它很像 Pixel Shuffle 的上采样的一个反过程。输入输出也跟 CNN 类似，size 减半，channel 翻倍。具体过程如图（数字为序号）。merging 后再接一个 swin transformer block
  #fig("/public/assets/Reading/limu_paper/Swin Transformer/2024-10-28-10-45-37.png",width: 70%)
  - *stage 3* 和 *stage 4* 继续重复 stage 2 的操作，最后输出的特征图就是多尺寸的特征图，可以接各种下游任务的网络结构
    - 为了跟 CNN 保持一致，Swin Transformer 并没有像 ViT 一样使用 cls token，而是（比如对分类任务），采用 global average polling 把特征拉成 $1 * 1 * C$
  #fig("/public/assets/Reading/limu_paper/Swin Transformer/2024-10-27-16-55-10.png")
- Swin Transformer Block 细致介绍
  - *基于窗口的自注意力计算(W-MSA)*
    - 拿第一层的输入来举例。我们知道 ViT 用 $16 * 16$ 的 patch size，序列长度就只有 $196$；而这里，用 $4 * 4$ patch，同样大小的特征图就被划分为 $56 * 56 * 96$，序列长度 $56 * 56 = 3136$ 太长了
    - 所以*小窗口*概念，每次少算一点但算很多次。自注意力以 $7 * 7 = 49$ 为序列长度计算，但算了 $56/7 * 56/7=64$ 次。我们把各个数字抽象为 $H,W,C,M$，通用的复杂度公式为
    #grid(
      columns: (50%,40%),
      align: center,
      grid.cell(align: center+horizon)[
        $
        Omega("MSA") = 4 h w C^2 + 2 (h w)^2 C\
        Omega("W-MSA") = 4 h w C^2 + 2 M^2 h w C
        $
      ],
      grid.cell(align: center+horizon)[
        #fig("/public/assets/Reading/limu_paper/Swin Transformer/2024-10-28-11-16-59.png")
      ],
    )
  - *移动注意力窗口(SW-MSA)*: cyclic shift + mask
    #fig("/public/assets/Reading/limu_paper/Swin Transformer/2024-10-28-11-30-21.png")
    - 之前图例里画的移动窗口方式，会导致窗口数量增加以及每个窗口大小不一（一个简单的解决方式是 padding，但增加计算复杂度）
    - 于是很自然的解决办法是循环移位(cyclic shift)，把小块拼起来不就好了
    - 但另外一个问题就浮现了。对于图片边界的窗口，它们里面的一些元素是从很远的地方搬过来的，它们之间按道理来说不应该去做自注意力。对此使用*掩码*操作，巧妙地设计几种掩码方式
    - 掩码计算完，最后要把小块循环移位搬回去。通过这种方式，实现不增加计算复杂度的情况下，在一次前向过程完成了交互
    #fig("/public/assets/Reading/limu_paper/Swin Transformer/2024-10-28-12-01-46.png")
  - 于是整体的 Swin Transformer Block 就是 Layernorm + W-MSA，再接着 Layernorm + MLP；随后 Layernorm + SW-MSA，再接着 Layernorm + MLP。两个 block 加起来构成一个基本计算单元
- 作者后面还讲了没有用绝对位置编码，而是用相对位置编码，其实是为了提高性能的技术细节，跟文章整体的故事已经关系不大，就不介绍了

== 实验 & 评价
- 四种变体：Swin Tiny, Swin Small, Swin Base, Swin Large。主要不一样的就是两个超参数
  + 一个是向量维度的大小 $C$
  + 另一个是每个 stage 里到底有多少个 transform block（跟残差网络非常像，ResNet 也是分成了四个 stage，每个 stage 有不同数量的残差块）
- 首先是分类上的实验
  - 一共用了两种预训练方式：第一种是在正规的 ImageNet-1K 上，第二种是在更大的 ImageNet-22K 上做预训练
  - 不论是用哪种去做预训练，最后都是在 ImageNet-1K 的测试集上测试的
  - 对比了一些方法总之就是效果比较好
- 其次是目标检测的结果，在 COCO 数据集上训练测试
- 语义分割用 ADE20K 数据集
- 消融实验
  - 探究移动窗口以及相对位置编码的影响
  - 对分类任务而言影响不算特别显著，不过在 ImageNet 上提升一个点也算可观了；对下游任务也就是目标检测和语义分割影响更大
  - 这很合理，因为密集型预测任务对位置信息更敏感，而且更需要上下文关系
- 评价
  - 除了作者团队自己在过去半年中刷了的任务，比如说最开始讲的自监督的 Swin Transformer，还有 Video Swin Transformer 以及 Swin MLP，Swin Transformer 还被别的研究者用到了不同的领域
  - 在视觉领域大杀四方，以后每个任务都逃不了跟 Swin 比一比，而且因为 Swin 这么火，所以很多开源包里都有 Swin 的实现
  - 它的影响力远不止于此，论文里对 CNN，对 Transformer，还有对 MLP 这几种架构深入的理解和分析可以给更多研究者带来思考，从而不仅可以在视觉领域里，在多模态领域中，也能激发出更好的工作




