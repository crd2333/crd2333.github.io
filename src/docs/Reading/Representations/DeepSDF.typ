---
order: 1
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Reading DeepSDF",
  lang: "zh",
)

#let SDF = math.text("SDF")
#let clamp = math.text("clamp")
#let Occupancy = math.text("Occupancy")
#let NeRF = math.text("NeRF")

= SDF(DeepSDF)
- DeepSDF: Learning Continuous Signed Distance Functions for Shape Representation
- 时间：2019.1
== 引言
- DeepCNN 是基于图像的支柱方法，当直接推广到第三个空间维度时，在空间和时间复杂度上的快速增长，以及表示的不匹配问题，使得 3D 数据处理或产生 3D 推理等任务的质量、灵活性和保真度不高
- 这项工作中提出了一种新的生成 3D 建模表示和方法，该方法高效、富有表现力且完全连续。该方法使用 SDF 的概念，但与将 SDF 离散为规则网格以进行评估和测量去噪的常见表面重建技术不同，我们改为学习一个生成模型来产生这样一个连续的场
- 尽管 SDF 在 CV, CG 领域被熟知，但这篇文章应该是第一个用神经网络来直接拟合的工作，主要贡献在于：
  + 具有连续隐式曲面的、shape-conditioned 的 3D 模型的建模方法
  + 基于概率 auto-decoder 的 3D 形状的学习方法，以及
  + 该方法在形状重建和补全方面的演示和应用
  - 我们的模型产生了具有复杂拓扑结构的高质量连续表面，并在定量比较中取得了 SOTA。一个例子，我们的模型仅使用 7.4 MB 的内存来表示椅子这一类别，这还不到单个未压缩的 $512^3$ 3D 位图的内存占用的一半(16.8 MB)（但感觉拿未压缩的原图来比也有点耍流氓）

== 相关工作
=== Representations for 3D Shape Learning
- 3D 物体形状的（显式）表示可以分成 $3$ 类：基于点云， mesh 和 voxel 的方法：
  + Point-based: 点云的表达更接近 raw data，不可否认PointNet 在提特征方面很合适（做分类分割检测的工作比较合适），但在物体形状的表达方面很受限，没有描述 topology，不适合生成完美的表面
  + Mesh-based：可以对 3D 物体建模，但是拓扑结构固定
  + Voxel-based：最直接的想法就是使用 dense occupancy grid，但是由于三次的复杂度所以代价高昂，即使有八叉树或者 voxel hash 的方法依旧精度不高
    - 所以体素的用法需要进一步的拓展，那就是 SDF(TSDF)了。比如 KinectFusion 作为经典工作，成功将 depth map 融合到了 3D model 中。后续工作都是在离散空间开展的，重建的话一般就是 TSDF 之后做 marching cubes，所以连续域的探索是很新颖的工作

=== Representation Learning Techniques
- 现代 Representation Learning 技术旨在自动学到描述数据的特征，主要有以下这些方法
  + Generative Adversial Networks(GAN): 生成器和判别器对抗学习学到 deep embeddings of target data
  + Auto-encoders: auto-encoder + decoder，比如 VAE（对比学习那一套里面的）因为 encoder 和 decoder 之间的 bottleneck 的约束，auto-encoder 有望学到原始输入的表示
  + Optimizing Latent Vectors: 或者说 decode-only，使用 self-reconstruction loss 训练

=== Shape Completion
- 经典的表面重建方法通过拟合 RBF 来近似隐式表面函数，或者通过将定向点云的重建问题转换为泊松问题，从而得到密集表面。这些方法仅对单个形状而不是数据集进行建模
- 最近的各种方法使用数据驱动的方法，大多采用 encoder-decoder 架构将 occupancy voxels、离散 SDF voxels、深度图、RGB 图像、点云 简化为 latent vector，然后根据学习到的先验预测完整的体积形状
- （其实都是比较 old-fashioned 的方法，真现代肯定 NeRF, 3DGS 了

== 方法
- key idea 是使用 Deep Neural Networks 直接从点样本中回归连续的 SDF。训练后的网络能够预测给定查询位置的 SDF 值，从中我们可以通过评估空间样本来提取零水平集曲面。可以直观地理解为二元分类器，决策边界是形状表面
- 最简单的想法当然就是为每个形状学习一个网络（没有包含任何 shape 的信息） $f_theta (x) approx SDF(x), ~~~ forall x in Omega$，训练时使用 L1 loss: $ cal(L)(f_theta (x),s) = |clamp(f_theta (x),s) - clamp(s,delta)| "，其中" clamp(x,delta)) := min(delta, max(-delta,x)) (delta = 0.1) $
#fig("/public/assets/Reading/Representations/DeepSDF/2024-10-11-15-19-08.png", width: 60%)
- 我们当然希望一个模型可以表示各种各样的形状，发现它们的共同属性并嵌入到低维潜在空间中。为此，我们引入了一个潜在向量 $z$
  - codebook 的思想，$z$ 代表对某个 general 形状的描述，每一种形状都有一个对应的 code，用某个 3D location $x$ 去 query 然后得到近似的 SDF 输出
  $ f_th (zi, x) approx SDF^i (x) $
#fig("/public/assets/Reading/Representations/DeepSDF/2024-10-11-15-18-45.png", width: 60%)
- 那么这个 $z$ 怎么来呢？
  - 不像 VAE 那样（类似上图左边 encoder + decoder） encoder 是针对单个 shape 的，在 VAE 得到这个 latent code 之后，test 的时候再 VAE 一次，再和 point 一起作为输入进行预测，着实有些累赘。所以考虑去掉 encoder 使用 decoder-only（另外，这个工作在 3D 学习社区首次引入 decoder-only）
  - 给定一个 $N$ shapes 的数据集，构建训练样本 $X_i = {(bx_j, s_j): s_j = SDF^i (bx_j)}$，每个 $i$ 对应一个 shape，每个 $j$ 对应一个点，于是给定 shape SDF samples $X_i$ 后的 shape code $zi$ 的后验概率为
  $ p_th (zi|X_i) = p(zi) p(X_i|zi) / p(X_i) =^? p(zi) product_((x_j,s_j) in X_i) p_th (s_j|zi;bx_j) $
  - 当前形状最好的 Latent Vector 应该是使得这个 SDF 值的判断最为正确的 Vector，所以文章的训练方法就是，先随机定义该形状的 Latent Vector（随便给个先验），通过训练反向传播得到更好的 Vector（通过后验不断优化）
  - 我们假定 $p(zi)$ 为特定均值方差的 multivariate-Gaussian，$p(zi) = 1/(2si sqrt(pi)) exp(- zi^2 / (si^2))$
  - 对于 $Pi$ 中的公式，我们用 deep feed-forward network 来拟合 $f_th (zi,bx_j)$，然后不失一般性(?)地表示为
  $ p_th (s_j|zi;bx_j) = exp(-cal(L)(f_th (zi, bx_j), s_j)) $
  - 于是，在训练时我们把编码向量 $bz$ 和样本位置 $bx_j$ 堆叠在一起，如上图 b 所示，作为神经网络的输入，同时在第 $4$ 层也进行输入（说是再插入到中间一次效果更好）。神经网络梯度反传优化 $th$，同时反传到输入优化 $bz$（更确切地说，把部分输入也当成了 nn.Parameters），这相当于是在做上面那个后验概率的最大化(MAP)
  $
  argmin_(th,{zi}_(i=1)^N) sum_(i=1)^N (sum_(j=1)^K cal(L) (f_th (zi,bx_j),s_j) + 1/si^2 norm(zi)^2)
  $
  #fig("/public/assets/Reading/Representations/DeepSDF/2024-10-11-20-13-28.png", width: 70%)
  - 然后在 inference 的时候，我们冻结网络 $th$，只优化 $bz$，继续做 MAP
  $ hat(bz) = argmin_bz sum_((bx_j,bs_j) in X) cal(L)(f_th (zi,bx_j),s_j) + 1/si^2 norm(zi)^2 $
- 我们可以发现模型在推理阶段仍然是会用到 ground truth 和损失，这是什么意思呢？
  - 我们知道 3D Reconstruction 是对于空间里的点进行更高精度的恢复，3D Completion 是对部分可观测点还原出整个形状，二者都可以采样出一定的 ground truth。那么在推理的时候我们可以只取一小部分点，利用这些点去进行训练，得到 Latent Vector，之后再对全部的点利用刚刚得到的 Latent Vector 进行重建。因为我们之前 decoder 是训练过的（类似于预训练），包含大量的先验知识。所以在这样的 decoder 下，反向传播训练出一个较好的 Latent Vector 是比较快的
  - 这与 auto-encoder（或者说 encoder-decoder）框架相比是一个巨大优势，因为 auto-encoder 的 encoder 期望测试输入与训练数据相似（有些过于依赖训练数据的意思），也就是说泛化性没那么强；但我感觉这样的方法也有缺点，因为 encoder-decoder 架构的 Latent Vector 只需要一次 forward 就得到了，而这里 auto-decoder 的方法就要反向传播重训练，应用上稍微复杂一点。也算是一种在 LocalOverfitting 和 Generalisable Learning 之间寻求平衡吧
  - （论文这里真的写得很怪且不清晰，其实我觉得把整个模型称作 hypernetwork，然后推理的时候产生真正的 network，这样描述不就清晰多了。可以参考 #link("https://zhuanlan.zhihu.com/p/102904841")[谈谈DeepSDF中AutoDecoder]，写得挺深入）

== 实验
- 先说一下数据的问题
  - 我们需要的数据是$(x, y, z, "sdf value")$，这样的数据集目前没有，但是像 ShapeNet 这样的数据集提供了物体的 3D shape mesh，对每个物体用一个 mesh 表达。
  - 把它 normalize 到单位球中(in practice fit to sphere radius of 1/1.03)，解决 scale 的问题，半径比 $1$ 稍小一点参考 TSDF 理解
  - 数据的预处理是个大头的工作，这里有两个难点
    + 必须知道 mesh 的每个三角形的朝向才能判断点在物体内部还是外部，决定 SDF 的 sign
    + 必须 aggressive 一些，在物体表面附近采点，球内随便产生的点没啥用，学不出来表面。
  - 作者的做法描述得很简单，在单位球上均匀假想 $100$ 个相机，每个得到一个 depth map，然后通过一些操作算出符号和距离
- 作者分了 $4$ 个章节来展示，不细看了，反正就是很厉害效果很好云云
  - Representing Known 3D Shapes
  - Representing Test 3D Shapes (auto-encoding)
  - Shape Completion
  - Latent Space Shape Interpolation
- #link("https://blog.csdn.net/qq_38677322/article/details/110957634")[一篇复现论文的博客]

== 结论和评价
- 作者自评
  - DeepSDF 在形状表示和完成任务中显著优于适用的 baseline，同时实现了表示复杂拓扑、封闭表面以及提供高质量形状法线的目标。DeepSDF 模型能够在不产生离散化错误的情况下表示更复杂的形状，并且所需的内存显著少于之前最先进的结果
  - 然而，尽管形状的 SDF 逐点前向采样是高效的，但在推断过程中需要对潜在向量进行显式优化，所需时间显著增加。我们希望通过用更高效的 Gauss-Newton 或类似方法替代 ADAM 优化来提高性能，这些方法利用了解析导数
  - DeepSDF 目前假设模型处于 canonical pose，因此野外完成需要对 SE(3) 变换空间进行显式优化，从而增加了推断时间
  - 最后，要在单一嵌入中表示包括动态和纹理在内的真实可能场景空间仍然是一个重大挑战，将继续探索这一问题
#q[deepSDF 之后涌现了大量的工作，达摩院的 Curriculum DeepSDF 以及 Berkeley 的 Extending DeepSDF 就是典型代表，还有 Facebook 的 Deep Local Shapes以 及 ETH 的 KAPLAN，这也一定程度能理解为什么 DeepSDF 被评为 CVPR2019 最有影响力的几篇工作之一了]

== 论文十问
+ 论文试图解决什么问题？
  - 3D 形状的表示和重建问题
+ 这是否是一个新的问题？
  - 不是新问题，但是 DeepSDF 是第一个用神经网络直接连续地拟合 SDF 的工作
+ 这篇文章要验证一个什么科学假设？
  - 通过神经网络直接拟合 SDF，可以更好地表示 3D 形状
+ 有哪些相关研究？如何归类？谁是这一课题在领域内值得关注的研究员？
  - 3D 形状的表示和重建问题，主要有 Point-based, Mesh-based, Voxel-based 的显式方法，学习的架构上有 GAN, encoder-decoder, decoder-only 等
+ 论文中提到的解决方案之关键是什么？
  - 使用神经网络直接拟合 SDF，通过 decoder-only 的方法学习潜在空间，通过 inference 时再训练的方法得到最优的潜在向量
+ 论文中的实验是如何设计的？
  - 通过 ShapeNet 数据集，对每个物体的 mesh 进行处理，得到 SDF 数据集，然后训练模型，展示效果
+ 用于定量评估的数据集是什么？代码有没有开源？
  - ShapeNet 数据集的处理后版本（需要自己处理）；代码开源在 #link("https://github.com/facebookresearch/DeepSDF")[github.com/facebookresearch/DeepSDF]
+ 论文中的实验及结果有没有很好地支持需要验证的科学假设？
  - 有的，实验效果还是不错的
+ 这篇论文到底有什么贡献？
  - 提出了一种新的 3D 形状表示方法，用神经网络直接连续地拟合 SDF 的工作，效果不错
+ 下一步呢？有什么工作可以继续深入？
  - 优化推理时间，解决动态和纹理的问题
