---
order: 5
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "3DGS",
  lang: "zh",
)

= 3DGS
- 原论文：3D Gaussian Splatting for Real-Time Radiance Field Rendering (time: 2023.8)
- 原论文方法部分讲得不直观，结合综述 A Survey on 3D Gaussian Splatting (time: 2024.1)，一起理解 3DGS

== 前言
- 初看 3DGS 感觉有点像是 Plenoxels
  - 二者都是完全不涉及神经网络的方法（当然你也可以说二者的前向和优化过程可以看作是某种特殊的“网络”）
  - 所不同的是，Plenoxels 用来固化特征的体素网格依旧还是模拟 NeRF 的那个神经隐式场，只是把 RGB 的表达换成了球谐函数（3DGS 的这个想法应该也是从这里来的），并且仍旧是 Ray-Marching 逐像素采点进行 Volume Rendering 那一套 (backward mapping)
  - 而 3DGS 则完全脱胎于 NeRF，不仅摈弃了神经网络，创新出一种新的显式表示 —— 3D 高斯球，并且用 splatting (forward mapping) 代替了体渲染方法，实现了高速渲染

== 摘要 & 引言 & 相关工作
- 先回顾一下过去的方法
  - 隐式辐射场，一般使用神经网络来学习连续的体积表示，好处是构建了一个可微且紧凑的复杂场景，坏处是如 SDF 表征能力不够强，NeRF 需要对光线进行采样（随机采样成本很高并且可能导致噪声）和体渲染。一般公式如下
  $ L_"implicit"(x,y,z,th,phi) = "NeuralNetwork"(x,y,z,th,phi) $
  - 显式辐射场，直接表示光在离散空间结构中的分布，比如体素网格、点云或本文的高斯球。好处是更快的查值和渲染，坏处是更大的内存使用和受到分辨率的限制（不连续）。一般公式如下
  $ L_"explicit"(x,y,z,th,phi) = "DataStructure"[(x,y,z)] dot f(th,phi) $
  - 而 3DGS 通过高斯椭球作为表示形式，单个 3D 高斯可以作为小型可微空间进行优化，不同高斯则能够像三角形一样并行光栅化渲染，可以看成是在可微和离散之间做了一个微妙平衡。3DGS 充分利用了显示辐射场的优势，同时结合了类似神经网络优化的方法，辅以工程上的高效实现（并行、CUDA），从而达到高质量渲染的同时具有更快的训练和实时性能。其公式表示如下
  $ L_"3DGS"(x,y,z,th,phi) = sum_i G(x,y,z,mu_i,Si_i) dot c_i (th,phi) $
  - 虽然 3DGS 是显式表示，但吸收了神经网络参数优化的思想（和现代算力的加持），可以看作是把整个场景都视为一个神经网络，从而把参数调到最优。我觉得这是挺有意思的一点，站在现代回顾传统方法（用高斯球表示场景并渲染在 EWA splatting, 2001 里早已出现），依旧能给技术带来巨大进步
- 总的来说，文章的贡献有以下三点
  + 引入各向异性 3D 高斯作为高质量、非结构化的辐射场表示
  + 3D 高斯属性的优化方法，如何进行交错优化、密度控制，以实现对场景的准确表示
  + 名为 splatting 的可微分渲染方法，可在 GPU 上快速运行以实现高质量的新视图合成

== 方法
- 整个流程的 pipeline 如下，我将其拆分为三个部分来理解
  #fig("/public/assets/Reading/Representations/3DGS/2024-10-20-20-18-10.png")

=== 高斯球的创建和表示
- 首先从 SfM 产生的稀疏点云初始化（直接调用 COLMAP 库）或随机初始化（可以但不建议，效果会变差），随后为每个点赋予高斯属性值
- 一个 3D 高斯属性（都是可学习的，并通过反向传播进行优化）包括
  + 中心位置 $(x,y,z)$，表示成 3D 高斯的均值 $μ$
  + 3D 高斯的协方差矩阵 $Si$。协方差矩阵需要保持半正定性，但在梯度下降优化中难以保证，因此使用*沿坐标轴的放缩* $(bs)$ 加上*用四元数表达的旋转* $(bq)$ 进行表示：$Si = R S S^T R^T$，一共 $7$ 个参数
  + 不透明度 $al$
  + 颜色 $bc$，由球谐函数表示。球谐函数类似于傅里叶变换的基函数，比如使用 $4$ 阶，就需要 $16$ 个参数，对 RGB 分别而言就有 $48$ 个系数，它们描绘了这个高斯球在不用方向 $(th,phi)$ 看过去的颜色

=== splatting 和渲染
- 我们先想象高斯球的属性都已经优化得很好，接下来给定位姿用 splatting 方法渲染图像
- 所谓 splatting 中文翻译做泼溅，可以想象成是抛雪球
  - 实际上就是把 3D 高斯椭球投射到 2D 平面上，记录它们的深度（用于排序前后）以及溅起雪的范围（对图像的贡献，显然中心最多，符合直觉）。然后，如果不考虑后续的优化，我们就是逐个像素地遍历所有雪球计算颜色贡献，最后得到像素值
  - 这里如果我们与 NeRF 做一个比较，就会发现二者几乎是一个逆过程
    - NeRF 从像素出发找采样点，用体渲染的方式积分得到像素值，如果要保证渲染质量、隐式几何连续性、细节还原度，往往需要大量采样需求
    - 而 3DGS 从高斯球出发投射到 2D 平面，这个过程可以说是 3DGS 的关键创新点之一。3D 高斯的轴向积分等同 2D 高斯，从数学层面摆脱了采样量的限制，计算量由高斯数量决定；这些高斯又可以使用自定义的光栅化管线快速地并行渲染；而且避免了与空白空间渲染相关的计算开销
  - 下面一个个解释其中的技术细节
- 视锥剔除
  - 给定指定的相机位姿，可以想象有些高斯球是看不到的，可以自然地把它们从后续计算中剔除
- 投影
  - 我们希望 3D 高斯球在变换后依然保持 2D 高斯分布（不然光栅完和高斯没关系岂不是努力白费），这需要仿射性质
  - 在图形学经典的 MVP 变换中，我们用到 View 和 Perspective Project（正交投影没体现出近大远小的变化来，直接 pass）
    - view 变换 $W$ 涉及旋转和平移，都是仿射变换 (affine) 所以没什么问题；但 project 变换则不仿射了，这意味着不可能使用单一的线性变换矩阵来转换所有点的坐标（因为每个点在光线空间的坐标是一个以其在相机空间坐标为自变量的非线性函数，所以不存在一个通用的变换矩阵）
    - 于是论文用 $J$(Jacobian) 对 project 进行仿射近似：$ Si'=J W Si W^T J^T $
    - 随后我们很粗暴地将第三行第三列去掉作为 2D 高斯的协方差矩阵，不需要额外计算
    - 至于 2D 高斯的均值即中心点坐标，通过除以第三维坐标 $u_2$ 来获得，即中心点坐标为 $ mu' = (u_0/u_2, u_1/u_2, 1) $
  - 另外，每个高斯球的不透明度需要调整
    $ al'_i = al_i times exp(- 1/2 (bx'-mu'_i)^T Si'_i^(-1) (bx' - mu'_i)) $
    - 即 3D 高斯的不透明度乘以概率密度分布，其中 $bx'$ 和 $mu'_i$ 是投影空间中的坐标。这也很符合直觉，椭球厚一点的位置当然要不透明一点
  - 通过投影，我们把世界坐标系下的 3D 高斯球投射到投影空间($[-1,1]^3$)，得到 $mu', Si', al'$
- 渲染
  - 如果不考虑后续的优化，我们对每个像素逐个渲染。给定像素的位置 $bx$，可以通过视口变换 $W$ 计算出它与所有重叠高斯的距离，即这些高斯的深度，形成一个排序的高斯列表$cN$
  - 使用 $al"-composition"$ 计算这个像素的最终颜色，其中 $c_i$ 是利用球谐函数系数和方向算出来的颜色
  $ C = sum_(i in cN) c_i al'_i Pi_(j=1)^(i-1) (1 - al'_j) $
#fig("/public/assets/Reading/Representations/3DGS/2024-10-20-23-49-55.png")
- tile 优化
  - 在处理图像时，为了减少对每个像素进行排序的成本，论文将图片分成了砖块 (tile)，每个砖块包括 $16 times 16$ 个像素
  - 接下来，会进一步识别出哪些砖块与特定的高斯投影相交（$99%$ 以上）。一个覆盖多个砖块的高斯投影被复制并分配唯一的标识符，即与之相交的 Tile 的 ID
  - 每个 tile 内独立进行上述排序、渲染的计算。这一过程非常适合并行计算，在 CUDA 编程中，令 tile 对应 block，像素对应 thread。并且每个 tile 的像素可以访问共享内存，共享统一的读取序列，从而提高渲染的并行执行效率

=== 参数优化和密度控制
- 通过上面的渲染过程，我们可以得到一个图像，将其与真实图像比较计算 loss，然后通过反向传播优化参数
  - 损失函数是常见的 L1 loss 和 D-SSIM loss 的组合，后者度量两幅图像的相似度（在图像级别）
  $ cL = (1-la)cL_1 + la cL_"D-SSIM" $
- 3DGS 可以直接通过反向传播优化参数，这也是为什么整个流程可以看作是一个特殊的神经网络，但要注意两点
  + 协方差矩阵的优化需要保证其半正定性，我们前面讲过通过 $Si = R S S^T R^T$ 来保证，优化那 $7$ 个参数
  + 获得不透明度 $al$ 的计算图十分复杂，即 $ bold(q), bs arrow.r.bar Si arrow.r.bar Si' arrow.r.bar al$，因此这里不通过自动微分，而是直接推导了梯度计算公式
- 密度控制
  - *点密集化*：自适应地增加高斯的密度，以更好地捕捉场景的细节，重点关注缺失几何特征或高斯过于分散的区域，二者都在视图空间中具有较大位置梯度。其包括在未充分重建的区域克隆小高斯，创建高斯的复制体并朝着位置梯度移动；或在过度重建的区域分裂大高斯，用两个较小的高斯替换一个大高斯，按照特定因子减小它们的尺度
  - *点的剪枝*：移除冗余或影响较小的高斯（某种程度上算是一种正则化）过程，在保证精度的情况下节约计算资源。一般消除 $al < ep$ 和体积过大的高斯。此外，输入相机附近的高斯球在一定迭代次数后 $al$ 被设置为接近 $0$ 的值，避免不合理的密度膨胀
- 总的优化流程如下图
  #fig("/public/assets/Reading/Representations/3DGS/2024-10-21-00-03-46.png")

== 评价
- 优点
  + 高品质、逼真的场景
  + 快速、实时的渲染和极快的训练速度
- 缺点
  + 同以前方法类似的 artifacts（一个原因是渲染时过于简单的剔除，另一个则是过于简单的按密度排序的可见性算法）
  + 显存使用率和磁盘占用较高
  + 虽然是显式表示方法，但它自定义的渲染管线跟现有渲染管线（基本是基于三角形）不兼容

== 3DGS 当前的几个发展方向
- *Data-efficient 3DGS*，在数据不那么充分的地方可能出现 artifacts。主要有两种策略：
  1. *基于 Regularization 的方法*引入额外的约束，如深度信息，来增强细节和全局一致性。例如
    + DNGaussian 引入了深度正则化方法来解决稀疏输入视图中几何退化的挑战
    + FSGS 设计了一种用于初始化的 Gaussian Unpooling 过程，而且也引入了深度正则化
    + MVSPlat 提出了 cost volume representation，以提供几何线索
  - 然而，在视图数量有限甚至只有一个视图时，正则化技术的功效往往会减弱，这导致
  2. *基于 generalizability 的方法*，尤其关注学习先验知识。一个典型的实现是使用深度神经网络生成 3D 高斯，随后直接用于渲染而无需优化。这种范式通常需要多个视图来训练，但可以只用一张图像重建 3D 场景。例如
    + PixelSplat 提出从密集概率分布中采样高斯。它结合了 multi-view epipolar transformer 和重参数化技巧来避免陷入局部最优并保持梯度流
    + Splatter Image 通过学习的方法进行单目 3D 物体重建，利用 2D image-to-image 网络，将输入图像映射到每个像素的 3D 高斯。这种范式主要关注对象的重建，其泛化性有待改进
- *Memory-efficient 3DGS*，对于 NeRF 来说只需要存储学习到的 MLP 参数，而 3DGS 需要存储整个显示表示，对大尺度场景尤为严重。主要有两种策略：
  + *减少 3D 高斯的数量*，即剪枝。例如
    + #link("https://dl.acm.org/doi/abs/10.1145/3651282")[Paptantonakis] 等人提出了一种 resolution-aware 的剪枝方法，将高斯数量减少了一半
    + #link("https://openaccess.thecvf.com/content/CVPR2024/html/Lee_Compact_3D_Gaussian_Representation_for_Radiance_Field_CVPR_2024_paper.html")[Lee] 等人引入了一种可学习的 volume-based masking strategy，在不影响性能的情况下有效减少了高斯数量
  + *压缩 3D 高斯属性的内存使用量*。例如
    + #link("https://openaccess.thecvf.com/content/CVPR2024/html/Niedermayr_Compressed_3D_Gaussian_Splatting_for_Accelerated_Novel_View_Synthesis_CVPR_2024_paper.html")[Niedermayr] 将颜色和高斯参数压缩为 compact codebooks，使用 sensitivity-aware vector clustering 来进行 quantization-aware training and fine-tuning
    + HAC 使用高斯分布预测每个量化属性的概率，并且设计了一个自适应量化模块
  - 尽管目前的方法实现了几十到几十倍的存储压缩比（训练后），但在训练阶段减少显存使用仍有相当大的研究空间
- *Photorealistic 3DGS*，3DGS 当前的渲染管线较简单且有几个缺点。例如，简单的可见性算法可能会导致高斯的 depth/blending 顺序发生剧烈变化。渲染图像的真实性有待进一步优化，包括 aliasing, reflections, artifacts 等方面，几个关键点如下：
  + *不同的分辨率*。由于离散采样范式（将每个像素视为单点而不是区域），在处理不同分辨率的图像时，3DGS 容易受到 aliasing 的影响，比如低分辨率的图像（采样频率跟不上场景表示的高频细节），为此
    + #link("https://arxiv.org/abs/2311.17089")[Yan] 等人引入了多尺度 3DGS，场景使用不同大小的高斯表示，配套一个 multi-scale splatting algorithm —— 高分辨率图像使用更多的小高斯渲染，低分辨率图像使用更少的大高斯渲染
    + Analytic-Splattting 采用像素区域内高斯积分的解析近似，利用 conditioned logistic function 作为一维高斯信号中 CDF 的解析近似来更好地捕获像素的强度响应
  + *反射*。实现反射材料的逼真渲染是三维场景重建中一个困难而长期存在的问题
    + GaussiansShader 通过将简化的着色函数与 3D 高斯函数集成，增强了具有反射表面的场景的神经渲染
  + *几何形状*，3DGS 的一个局限性是忽略了底层场景的几何形状和结构（尤其是在复杂的场景和不同的视图、照明条件下），这引发了几何感知重建的研究。例如
    + GeoGaussian 专注于保留墙壁和家具等非纹理区域的几何形状（这些区域往往会随着时间的推移而退化）
- *Improved Optimization Algorithms*，优化算法对 3DGS 的重要性无需多言。一个问题是，各向异性的高斯虽然有利于表示复杂几何图形，但可能会产生 visual artifacts（例如那些大型 3D 高斯，尤其是在跟视角格外相关的区域，视觉元素突然出现或消失，打破沉浸感）。三个主要改进方向是
  + *引入额外的正则化*。3DGS 经常面临过度重建的挑战，稀疏的、大型的 3D 高斯在高方差区域表示不佳而导致 blur and artifacts，结合额外的正则化并改进 3DGS 的优化过程可能能够加速收敛、平滑噪声并提高渲染质量。例如
    + 基于频率的正则化。FreGS 引入了一种渐进频率正则化方法，通过利用傅里叶空间中的低通和高通滤波器提取的低频到高频分量来执行从粗到细的高斯密集化
    + 基于几何感知重建的正则化。例如 Scaffold-GS 引入了体素网格（网格的中心是 anchor point），由 anchor point 的特征向量 decode 出局部 3D 高斯的属性(offset,  opacity, color, scale, quaternion)，这些高斯根据 viewer 的透视和距离动态调整属性
  + *改进优化过程*。3DGS 使用 SfM 生成初始化高斯，不可避免地受到无纹理表面密集初始化的挑战（尤其是在大规模场景中），并且使用的分割和克隆策略相对简单
    + GaussianPro 利用场景的现有重建几何形状的先验和补丁匹配技术来生成具有准确位置和方向的新高斯，应用渐进传播策略来指导 3D 高斯密集化
  + *优化中的松弛约束*。还是 SfM 的问题，依赖外部工具/算法可能引入错误，并限制系统可能的潜力
    + #link("https://arxiv.org/abs/2312.07504")[Yang] 等人提出了COLMAP-Free 3D GS，它逐帧处理输入的连续视频并逐步增加 3D 高斯集，从而摆脱对 COLMAP 的依赖
    - 尽管 impressive，但现有方法主要集中在优化高斯以从头开始准确地重建场景，而忽略了一种具有挑战性但有前途的范式 —— 通过已建立的“元表示”以少量镜头的方式重建场景
- *3D Gaussian with More Properties*，3D Gaussion 的属性都是为了新视图合成而设计的，但结合 linguistic, semantic/instance, spatial/temporal 等属性，可能能让 3DGS 胜任更多任务，比如
  + *语言嵌入式场景表示*，将自然语言与三维场景联系起来，支持用户通过语言与三维世界进行交互和查询。例如
    + 由于当前语言嵌入场景表示的计算和内存需求较高，#link("https://arxiv.org/abs/2311.18482")[Shi] 等人提出了一种量化方案，通过简化的语言嵌入（而不是原始的高维嵌入）来增强 3D 高斯，并且还减轻了语义歧义，通过在不确定性值的指导下平滑不同视图的语义特征来增强开放词汇查询的精度
    + LangSplat，使用 SAM 基于输入的多视角图像集生成层次化语义 (Hierarchical Semantics)，把这些分割的掩码图输入 CLIP，将图像和文本特征对齐并输出 language embeddings，压缩到低维空间（降低内存成本），最后让三维语言高斯模型基于低维 embeddings 反复执行有监督的渲染迭代训练，得到包含语义信息的高斯场景表示
  + *场景理解和编辑*
    + Feature-3DGS 将 3DGS 与从 2D 基础模型 (e.g. SAM, CLIP-LSeg) 蒸馏来的特征场相结合。通过学习低维特征场并应用轻量的卷积解码器进行上采样，Feature-3DGS 在实现高质量特征场蒸馏的同时实现了更快的训练和渲染速度，支持视图语义分割和语言引导编辑等应用
  + *时空建模*，例如
    + #link("https://arxiv.org/abs/2310.10642")[Yang] 等人将时空概念化为一个统一的实体（即利用 4DGS 作为动态场景的整体表示，而不是对每个单独的帧应用 3DGS），并使用 4D 高斯的集合来近似动态场景的时空体积。所提出的 4D 高斯表示和相应的渲染管线能对空间和时间的任意旋转进行建模，并允许端到端训练
- *3DGS with Structured Information*，除了使用额外属性来增强 3D 高斯，适应下游任务的另一个 promising 的途径是引入为特定应用定制的结构化信息(e.g. spatial MLPs and grid)。一些特定结构化信息加持下 3DGS 的用途例如
  + *面部表情建模*。考虑到在稀疏视图条件下创建高保真 3D 头部化身的挑战，Gaussian Head Avatar 引入了 controllable 3D Gaussians 和 MLP-based deformation field。具体来说，它通过基于隐式 SDF 和 Deep Marching Tetrahedra 的几何引导初始化策略，然后用 dynamic generator $Phi$ 将 neutral Gaussians 形变，生成目标表情
  + *时空建模*。Deformable-3DGS 提出用 deformable 3D 高斯重建动态场景，在规范空间中学习，辅以对时空动态进行建模的变形场(i.e., spatial-MLP)。该方法还加入了退火平滑训练机制，不增加计算成本的同时增强时序上的平滑
  + *风格迁移*。为了跨视图保持 cohesive stylized appearance 的同时不损害渲染速度，GS-in-style 使用预训练的 3D 高斯和 multi-resolution hash grid 和 small MLP 来实时地生成风格化视图
  - 简而言之，对于那些跟 3D 高斯 sparsity and disorder 属性不兼容的任务，整合结构化信息可以作为它们的补充

== 3DGS 的应用领域和任务
- Simultaneous Localization and Mapping (SLAM)
- Dynamic Scene Reconstruction
- AI-Generated Content (AIGC)
- Autonomous Driving
- Endoscopic Scene Reconstruction
- Large-scale Scene Reconstruction

== 3DGS 的未来研究方向
- 尽管 3DGS 的后续工作令人印象深刻，相关领域已经或可能被 3DGS 革命，但人们普遍认为 3DGS 仍有很大的改进空间
- *Physics- and Semantics-aware Scene Representation*，作为一种全新的显式场景表示，3D 高斯的潜力不仅仅在于新视角合成。设计能够感知物理和语义的 3DGS 系统，它将有可能在场景重建和理解方面同时进步，彻底改变一系列领域和下游应用。例如
  + 结合先验知识（比如物体的一般形状）可以减少对大量训练视图的需求，同时改善几何/曲面重建
  + 生成场景真实性的进一步改善，包括几何、纹理和照明保真度方面的挑战
  + 增强真实感和交互性，如动态建模、场景编辑和生成等
  - 简而言之，追求这种先进、多功能的场景表示为跨领域的创造和应用开辟了新的可能性
- *Learning Physical Priors from Large-scale Data*，跟大模型那一块结合，利用大规模数据集学习物理先验
  - 目标是对现实世界数据中的固有物理特性和动力学进行建模，将其转化为 actionable insights，随后应用于机器人和视觉效果等各个领域
  - 如果能够建立一个用于提取这些物理先验的学习框架，就可以用预训练模型应用到下游任务，以少量数据快速适应新的对象和环境
  - 此外，学习物理先验的意义不仅在于提高场景的准确和真实性，还在于交互性和动态性，这在 AR/VR 环境中尤其有价值
  - 然而，从广泛的 2D, 3D 数据集中提取基于物理先验的现有工作仍然很少（比较显著的成果有：用于弹性物体建模的 Spring-Mass 3D Gaussians，和结合了 Multi-View Stereo 的 MVSGaussian）。对 real2sim 和 sim2real 的进一步探索可能推动这一领域的进步
- *3DGS for Robotics*，即 3DGS + 具身智能
  - 为了实现人形智能机器人，越来越需要它们以更直观和动态的方式 navigate and manipulate 环境
  - 目前的具身智能实现严重依赖于通过语义信息理解环境（识别对象及其属性），这种方法往往忽视了事物如何随时间移动和交互
    - 据我所知目前大多是在用 VLM (Visual Language Model, VLA(Visual Language Action Model) 来做，而不是对整个场景进行理解。另外，目前的数据集中于 high-level reasoning，但缺少 low level control。或者说以综述中的例子，机器人知道这是什么（方块）、要做什么（堆叠方块），但它不知道具体应该怎么做（机械臂移动多少）、这些东西会怎么变（方块如何被动作影响，如何随时间变化），这之间有一个 gap
  - 这种时候，3DGS 由于其显式表示的性质，除了在环境的语义和结构上的分析之外，还提供了场景如何随时间演变和对象如何交互的动态全面理解
  - 尽管现在已经有一些基于 GS 的世界模型 (#link("https://arxiv.org/abs/2406.10788v1")[Physically Embodied Gaussian Splatting], #link("https://arxiv.org/abs/2403.08321v2")[ManiGaussian]) 以及基于 GS 的强化学习 (#link("https://arxiv.org/abs/2406.02370v2")[query-based Semantic Gaussian Field ...], #link("https://arxiv.org/abs/2404.07950v3")[RL with Generalizable GS])，但它们仅仅只是证明了可能性，该领域的进一步研究将增强机器人执行那些需要理解物理空间和其中时间变化的任务的能力
- *Modeling Internal Structures of Objects with 3DGS*
  - 尽管 3DGS 能够渲染出逼真的 2D 图像，但也正因为 splatting 的渲染方法主要着眼于这一点，导致对象的内部结构是不那么关注的；另外一点是，由于密度控制过程，3D 高斯倾向于集中在表面，而不是内部
  - 因此，对对象的内部结构进行建模，将物体描绘成体积的任务 (e.g. CT: computed tomography) 仍然是一个挑战。然而，3DGS 的无序性使得体积建模特别困难
  - #link("https://arxiv.org/abs/2312.15676")[Li] 等人使用具有密度控制的 3D 高斯分布作为体积表示的基础，不涉及 splatting 过程。X-Gaussian 涉及用于快速训练和推理的 splatting 过程，但不能生成体积表示。使用 3DGS 来模拟物体的内部结构仍然没有标准答案，值得进一步探索
- *3DGS for Simulation in Autonomous Driving*
  - 为自动驾驶收集真实世界数据集非常昂贵又困难，但对训练有效的图像感知系统至关重要，模拟成为一种经济高效、环境多样的替代方案
  - 然而，开发一个能够生成逼真和多样化合成数据的模拟器并不容易，这包括实现高水平的真实感、适应各种控制方法以及精确模拟一系列照明条件
  - 尽管早期使用 3DGS 重建城市/街道场景的努力令人鼓舞，但它们只是冰山一角。仍有许多关键方面有待探索，例如
    + 集成 user-defined object models
    + 建模物理感知的场景变化（e.g. 车轮的旋转）
    + 增强可控性和真实性（e.g. 不同的照明条件）
- *Empowering 3DGS with More Possibilities*，尽管 3DGS 具有巨大的潜力，但在很大程度上仍未得到开发
  - 一个有前景的探索途径是用额外的属性（例如前面提到的语言和时空属性）增强 3D 高斯分布，或者引入针对特定应用定制的结构化信息（例如前面提及的 spatial MLPs and grid）
  - 此外，最近的研究已经开始揭示 3DGS 在几个领域的能力，例如点云对齐(point cloud registration)、图像表示和压缩、流体合成。这些发现为跨学科学者进一步探索 3DGS 提供了重要机会

== 论文十问
+ 论文试图解决什么问题
  - 同 NeRF，通过稀疏视图集进行 3D 场景的表示，以及新视图的合成，但更注重实时性
+ 这是否是一个新的问题？
  - 不是，传统的不管是显式还是隐式的方法都有很多，近期则基本转向基于 NeRF 的方法和其改版，在 3DGS 提出后则基本是 3DGS 的天下了
  - 事实上从 NeRF 逐渐转回到显式表示的方法如 PlenOctrees, Plenoxels, InstantNGP 早有预兆，这也反映出一种趋势：对实时性的追求
  - 但其实哪怕是用椭球表示场景、用 slatting 渲染的这种方法也早就已经有了（EWA splatting，2001 年的文章），所以 3DGS 可以看作是朝花夕拾的产物
+ 这篇文章要验证一个什么科学假设？
  - 3D 高斯球可以作为高质量、非结构化的辐射场表示，可以通过优化方法和渲染方法实现对场景的准确表示，可以打破 NeRF 的速度限制
+ 有哪些相关研究？如何归类？谁是这一课题在领域内值得关注的研究员？
  - 传统的显式表示方法，如体素网格、点云、三角面片等
  - 传统的隐式表示方法，如 SDF, Occupancy，以及近期的隐式表示方法 NeRF 及其改版，如 Plenoxels, InstantNGP
+ 论文中提到的解决方案之关键是什么？
  - 3D 高斯球的表示，splatting 渲染，以及自适应的参数优化和密度控制
+ 论文中的实验是如何设计的？
  - 原论文：在 13 real scenes taken from previously published datasets and 1 synthetic Blender dataset 上做实验，着重和 Mip-NeRF 360（渲染质量上的 SOTA）以及 Plenoxels, InstantNGP（两个 fast NeRF 方法）进行对比
  - 综述：对 3DGS 的方法进行了详细的解释和评价，在多种任务上对比了 3DGS 和其他方法的优势
    + Localization: have a clear advantage over
    + Static Scenes: generally outperform
    + Dynamic Scenes: outperform existing SOTAs by a clear margin
    + Driving Scenes: significantly surpass
    + Human Avatar: consistent performance improvements
    + Surgical Scenes: several significant improvements
+ 用于定量评估的数据集是什么？代码有没有开源？
  - 原论文：Evaluation carried out on 3 real datasets: Mip-NeRF360(7 scenes), Tanks&Templates(2 scenes), Deep Blending(2 scenes) and 1 synthetic dataset: Blender。代码开源在 #link("https://repo-sam.inria.fr/fungraph/3d-gaussian-splatting/")[repo-sam.inria.fr/fungraph/3d-gaussian-splatting]
  - 综述：多种任务上的多个数据集 (Replica, D-NeRF, nuScences, ZJU-MoCap)，代码开源在 #link("https://github.com/guikunchen/3DGS_NOTES")[github.com/guikunchen/3DGS_NOTES]
+ 论文中的实验及结果有没有很好地支持需要验证的科学假设？
  - Performance proved, Ablation convincing
+ 这篇论文到底有什么贡献？
  - 从效果上看，第一个实现了 real-time rendering speed (>=30fps) 同时保持了 SOTA 的新视角合成质量
  - 从方法上看，证明了用 3D 高斯球表示和 splatting 渲染方法的可行性，并提出了行之有效的优化方法和高质量工程实现
+ 下一步呢？有什么工作可以继续深入？
  - 原文中提出的
    + 速度优化并未穷，还能更进一步
    + 存储高效的 3DGS 解决方案
    + 渲染质量上的进一步改善（解决 artifacts 现象），这包括优化与正则化、更好的可见性算法等
    + 探索更多方向上的应用
  - 综述中提出的: Data-efficient 3DGS，Memory-efficient 3DGS，Photorealistic 3DGS，Improved Optimization Algorithms，3DGS with More Properties，3DGS with Structured Information
