---
order: 3
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "NeRF",
  lang: "zh",
)

#let batch_size = math.text("batch_size")

= NeRF
- NeRF: Representing Scenes as Neural Radiance Fields for View Synthesis
- 时间：2020.1
- 参考 #link("https://zhuanlan.zhihu.com/p/512538748")[知乎：NeRF 及其发展]

== 引言
- 将静态场景表示为：一个连续的 5D 到 4D 的函数，输入为空间中每个点 $(x, y, z)$ 和每个方向 $(th, phi)$，输出是这个方向所发射的辐射，以及该点的 density（作用类似于不透明度，控制穿过光线的累积辐射量）
  - 说是 5D 是因为 $x, y, z, th, phi$ 的总自由度是 5，但是代码里为了表示方便，把方向编码成 3D 向量 $(x',y',z')$
  - 文章通过 MLP 来表示这个映射，从 $(x,y,z), (x',y',z')$ 回归到 $(R,G,B,si)$
- 为了渲染从特定角度的神经辐射场，我们：
  + 前处理：将相机光线穿过场景以生成一组采样的 3D 点
  + 模型训练和推理：使用这些点及其对应的 2D 观察方向作为神经网络的输入，以生成一组颜色和密度的输出
  + 后处理：使用经典的体渲染技术将这些颜色和密度累积到 2D 图像中
  - 实际上模型本身很简单，难点在于前处理和后处理的推导、理解
- 文章发现，对复杂场景的神经辐射场表示，基本的最优化过程无法收敛到足够高分辨率的表示（或者说，高频信息丢失），并且在每个相机光线的采样数量上效率低下。文章分别通过将输入的 5D 坐标做位置编码转换，以及提出一种分层采样方法（两个模型）来解决问题。
- 文章的方法继承了 volumetric representations 的优势：都能表示复杂的现实世界几何形状和外观，并且非常适合使用投影图像进行基于梯度的最优化。但更重要的是，文章的方法在以高分辨率建模复杂场景时克服了高昂的存储成本。总的来说文章主要贡献有：
  + 把一种复杂的场景表示为 5D 神经辐射场的方法，并参数化为 MLP 网络
  + 基于经典体渲染技术的可微渲染过程，从标准 RGB 图像中优化这些表示。包括分层采样策略
  + 一种位置编码方法，使神经辐射场能够表示高频场景内容
  - 文章证明了 NeRF 成了 SOTA，并且本文是首个能够在 natrual settings 下从 RGB 图像渲染高分辨率且逼真的全新视图的神经场景表示

== Related Work
=== Neural 3D shape representations
- 近年的工作通过优化将 $(x, y, z)$ 坐标映射到 SDF 或 occupancy fields 的深度网络，研究了连续 3D 形状的隐式表示。然而，这些模型需要有 3D 几何形状的 ground truth 作为真值
- 后来的一些工作制定了只需要使用 2D 图像就可以优化神经隐式形状表示的可微渲染函数。
  + Niemeyer 等人将物体表面表示为 3D occupancy fields，并使用数值方法找到每条射线的表面交点，然后使用隐式微分计算精确导数。每个光线交点位置都作为神经 3D texture field 的输入，这个 field 预测该点的漫反射颜色
  + Sitzmann 等人使用一种更加不直接的神经 3D 表示，在每个连续的 3D 坐标处简单地输出一个特征向量和 RGB 颜色，并提出一个由循环神经网络组成的可微渲染函数，该网络沿着每条射线行进以确定表面的位置
  - 虽然这些方法有表示复杂和高分辨率形状的潜力，但是目前仍然只能表达简单的几何形状。

=== View synthesis and image-based rendering
- 给定密集的采样视角，新视角可以通过 light field sample interpolation 技术得到。但如果是对于更稀疏的采样，就需要从观察到的图像中预测传统的几何和外观表示
- 一种流行的方法使用基于 mesh 的场景表示，具有漫反射或与视图相关的外观
  - Differentiable rasterizers 或 path tracers 可以使用梯度下降直接优化网格表示以重现一组输入图像
  - 然而，基于图像重投影的基于梯度的 mesh 优化通常很困难，可能是因为局部最小值或缺失的景观部分条件太差了。此外，该策略需要在优化之前提供模板网格作为初始化，这通常不适用于无约束的现实世界场景
- 另一类方法使用 volumetric representations，能表示复杂的形状和材料，非常适合基于梯度的优化，并且比基于 mesh 的方法产生的视觉干扰更少
  - 早期的体素方法使用观测到的图像来直接给体素网格上色
  - 近期，一些方法使用多个场景的大型数据集来训练深度网络，从一组输入图像中预测采样的体素表示，然后使用 alpha-compositing 或沿光线学习的合成 来在测试时渲染新的视图。其他工作针对每个特定场景优化 CNN 和采样体素网格的组合，使得 CNN 可以补偿来自低分辨率体积网格的离散化 artifacts，或者允许预测的体素网格根据输入时间而变化。虽然这些体积技术在新视图合成方面取得不错的结果，但它们扩展到更高分辨率图像的能力受到了限制，因为离散采样导致时间和空间复杂度高，而渲染更高分辨率的图像需要对 3D 空间进行更精细的采样
  - 本文提出的方法通过在 MLP 的参数中编码连续 volume 来规避这个问题，这不仅产生比先前体积方法更高质量的渲染，而且只需要更小的存储成本
- 注：某种程度上，NeRF 建模了视觉成像机理，更接近视觉世界本质
#fig("/public/assets/Reading/Representations/NeRF/2024-10-13-17-11-43.png", width: 70%)

== Method
- 这里原文分了好多章 Neural Radiance Field Scene Representation, Volume Rendering with Radiance Fields, Optimizing a Neural Radiance Field (Positional encoding & Hierarchical volume sampling)，这里将其整合到一起进行理解
- 整个任务的输入和输出
  - 输入：给定静止场景下的若干张图片
  - 输出：生成新的视角下的图片
  - 模型本质是使用神经网络 (MLP) 来隐式地存储 3D 信息
  - 不具有泛化能力，一个模型只能存储一个 3D 信息
- 模型的输入和输出
  - 模型输入是粒子的空间位置以及从哪个角度去看它（相机位姿），表示为 5D 向量，$(x, y, z, theta, phi)$，代码里是 6D 向量，$(x, y, z, x', y', z')$
  - 模型输出是从这个角度去看它得到的颜色和密度，表示为 4D 向量，$(R, G, B, sigma)$
  - 模型是 8 层的 MLP，但有两个
- 整个任务的输入输出和模型的输入输出并不一致，NeRF 的理解难点不在模型本身而在于前后处理，整个流程的 Pipeline 如下：
  - 前处理：
    - 将图片中的每个像素，通过相机模型找到对应的射线，共 $#batch_size$ 条射线
    - 在每条射线上进行采样，得到 $64$(N_samples) 个粒子
    - 对 $#batch_size * 64$ 个粒子进行位置编码
    - 位置坐标为 63D 和方向向量为 27D
  - 模型 1：
    - $8$ 层 MLP
    - 输入为 $(#batch_size, 64, 63)$ 和 $(#batch_size, 64, 27)$
    - 输出为 $(#batch_size, 64, 4)$
  - 后处理1：
    - 将模型 1 输出通过体渲染，转换为像素
    - 对射线进行二次采样，每条射线上总共采样 $192$ 个粒子
  - 模型2：
    - $8$ 层 MLP
    - 输入为 $(#batch_size, 192, 63)$ 和 $(#batch_size, 192, 27)$
    - 输出为 $(#batch_size, 192, 4)$
  - 后处理2：
    - 将模型 2 输出通过体渲染，转换为像素
  #fig("/public/assets/Reading/Representations/NeRF/2024-10-12-21-27-35.png",width:80%)
- 下面一个个描述其中的关键步骤
  - 输入图片如何得到这些粒子？
    - 训练时，一张图片（或者多个图片）采样 $#batch_size = 1024$ 个像素
    - 从图片和图片对应的相机位姿计算射线，$1024$ 个像素对应 $1024$ 条射线
      - $bold(r)(t) = bo + t bd$，从相机位姿得知 $bo$ 和 $bd$
    - 从射线上采样粒子
      - $t=2 wave 6$ 之间均匀采样（或者如果已知射线上的 CDF，就重要性采样），得到 $"N_samples" = 64$ 个粒子
    - 共 $1024*64$ 个粒子，以 batch 形式输入模型
      - 每个粒子有自己的空间位置 $bx = (x, y, z)$ 和方向 $bd = (x', y', z')$
  - 6D 向量如何进行位置编码？
    $ ga(p) = (sin(2^0 pi p ), cos(2^0 pi p), dots, sin(2^(L-1) pi p), cos(2^(L-1) pi p), p) $
    - 位置编码虽然不可学习，但显著提高了模型表示高频信息的能力
    - 模型函数 $F_th$ 现在变为 $F_th compose ga$
    - $L = 10 $ for $ga(bx)$, $3 * (2 * 10) + 3 = 63"D"$；and $L = 4$ for $ga(bd)$, $3 * (2 * 4) + 3 = 27"D"$
      - 其实 $L$ 的两个数值是超参，体现了作者认为位置比方向更重要
  - 模型具体架构？
    - 图里是 $60, 24$，但代码里是 $63, 27$
    - 63D 向量分两次进行输入，倒数第二层输出密度 $si$，同时输入 27D 向量，最后一层输出颜色 $R G B$
      - 这里方向输入得很晚，也体现了作者认为位置比方向更重要；另外密度都输出了方向才输入进来，这也是“方向与密度无关，只与颜色有关”的先验
    - 模型训练的 ground truth 是图片像素的颜色，因此需要将模型输出通过体渲染公式转换为像素颜色才能算 loss
    #fig("/public/assets/Reading/Representations/NeRF/2024-10-12-21-56-56.png", width: 70%)
  - 体渲染如何进行（同时也是模型输出如何得到图片的回答）？
    - 一个观察（先验）：一个点的密度越高，射线通过它之后变得越弱，*密度和透光度呈反比*；同时这个点的颜色反应在像素上的*权重越大*。这就是下面 $T(t)$ 在描述的事情 —— 采样点权重由其*密度*和*与光心距离*共同决定
    - 连续体渲染公式（确切地说应该是体渲染中的 Ray-Tracing 方法）
      - 其中 $c $ 表示颜色， $si$ 表示密度， $r$ 表示 camera ray，$t$ 和 $d$ 分别表示 camera ray 上的距离、方向
    $ C(br) = int_(t_n)^(tj) T(t) si(br(t)) c(br(t), bd) dif t, "where" T(t) = exp(- int_(t_n)^t si(br(s)) dif s) $
    - 实际计算需要将其离散化（掌握其推导：将射线划分为小区间，$delta_i=t_i - t_(i-1)$ 为区间长度，区间内 $si, c$ 为常数）
    $ hat(C)(br) = sum_(i=1)^N T_i (1 - exp(-si_i delta_i)) c_i, "where" T_i = exp(- sum_(j=1)^(i-1) si_j delta_j) $
    - 如果是在推理，通过这个公式从 $c_i, si_i$ 得到像素颜色，从而得到图片
    - 如果是在训练，得到像素颜色后与 ground truth 计算 loss，并且该式对于 $c_i, si_i$ 是可导的，可以梯度反传
  - 什么是 hierarchical volume sampling？
    - 根据粗模型 1 输出的密度，进行重要性采样，用更有效的输入训练细模型 2
    - 把上面的离散体渲染公式重写一下
    $ hat(C)(br) = sum_(i=1)^(N_c) w_i c_i, "where" w_i = T_i (1 - exp(-si_i delta_i)) $
    - 将这些权重归一化为 $hat(w)_i = w_i / sum_(j=1)^N w_j$，沿射线生成分段常数概率密度函数(PDF)，进而得到 CDF(Cumulative Distribution Function)
    - 使用逆变换得到 $"CDF"^(-1)$，该分布即为我们想要的重要性分布，采样 $128$ 个粒子，总共 $192$ 个，送入模型 2

== 实验和结论
- NeRF 不具有泛化能力，每个场景训练一次就用一次，在 DeepVoxels 数据集上做了 Synthetic renderings of objects 实验，并且做了 Real images of complex scenes 实验，效果都很好
- 与以往方法的比较
  + Neural Volumes (NV)
  + Scene Representation Networks (SRN)
  + Local Light Field Fusion (LLFF)
- 消融实验，主要考虑以下几个因素
  + Positional Encoding
  + View Dependence（指模型只输入粒子位置而不考虑方向）
  + Hierarchical
  + Image number
  + Frequencies
- 作者结论：
  - 我们证明，将场景表示为 5D 神经辐射场比之前的方法能产生更好的渲染效果，朝着基于真实世界图像的 graphics pipeline 迈出了进步
  - 尽管我们提出了一种分层采样策略，以提高渲染的样本效率，但仍有更多进展需要探索
  - 未来工作的另一个方向是可解释性：像体素网格这样的采样表示允许对渲染视图的预期质量和失败模式进行推理，但当我们使用深度神经网络的权重编码场景时，如何分析这些问题尚不清楚
- NeRF 的效果非常酷炫，同时也提供了一种 3D 场景建模的新形式（虽然后来被 3DGS 超了），它的主要问题包括
  + 速度慢
  + 只针对静态场景
  + 没有泛化性
  + 需要大量视角

== 论文十问
+ 论文试图解决什么问题？
  - 通过稀疏视图集进行 3D 场景的表示，以及新视图的合成
+ 这是否是一个新的问题？
  - 不是，之前已有基于 explicit representation(e.g. volume, mesh)的方法，另外也有基于 implicit representation(e.g. SDF, occupancy field)的方法。但效果算不上好
+ 这篇文章要验证一个什么科学假设？
  + 使用神经网络拟合隐式表达，能在节省储存成本的同时获得高质量的新视图
  + 5D 神经辐射场的隐式表达相比显式表达对噪声有更强的包容性和拟合性，能生成细节的几何表达
  + MLP 倾向于学习到一些低频的信号，傅里叶特征能使得模型学习到高频特征
+ 有哪些相关研究？如何归类？谁是这一课题在领域内值得关注的研究员？
  - 3D 场景表示的研究，可以分为 explicit 和 implicit 两类，NeRF 属于 implicit 类
+ 论文中提到的解决方案之关键是什么？
  + 使用 5D 神经辐射场的方法来实现复杂场景的隐式表示
  + 使用体渲染代替表面渲染完成场景任意光线颜色的渲染
  + 使用位置编码让模型学到高频信息，使用 hierarchical volume sampling 提高采样效率
+ 论文中的实验是如何设计的？
  - 在已有数据集和自己合成数据集上实验，对比了以往方法，做了消融实验
+ 用于定量评估的数据集是什么？代码有没有开源？
  - DeepVoxels 数据集，代码开源 #link("https://github.com/yenchenlin/nerf-pytorch")[github.com/yenchenlin/nerf-pytorch]
+ 论文中的实验及结果有没有很好地支持需要验证的科学假设？
  - 应该是能支持的
+ 这篇论文到底有什么贡献？
  + 提出了新的神经辐射场的隐式表示 $f_th (x,y,z,th,phi) arrow.r.bar (R,G,B,si) $，并用具体的模型成功拟合
  + RGB 的表示自然比 SDF 或 occupancy field 能渲染出更真实的场景
  + 密度 $si$ 结合体渲染，使模型表征不仅局限于刚体表面
  + 通过位置编码和 hierarchical volume sampling 提高了模型的性能
+ 下一步呢？有什么工作可以继续深入？
  - 速度优化，泛化性，动态场景，可解释性，视角需求数等
