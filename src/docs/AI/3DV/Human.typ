---
order: 2
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Reconstruction",
  lang: "zh",
)

= 人体重建
== Introduction
- 在对三维重建有一些基本的了解之后，下面我们专注于人体重建这一个子领域，梳理一下从传统方法到现代方法的脉络
- 人体重建具有一般三维重建所不具备的复杂性，主要体现在：
  + *几何的复杂性*。人体的几何受相当多的因素的影响，包括性别，体态，种族和姿态等。特别是姿态的变化，产生了人体复杂的大尺度非刚性形变，比如关节的高自由度旋转，使得广泛应用于人脸的形状混合 (Blend Shape) 和主成分分析 (PCA) 等线性变形方法难以直接应用于人体的变形。人的脸部、头发这种精细部位的几何很难表示。另外，由于人体会穿戴各种材质的服装和各式各样的物体，它们本身的表达以及与人体之间复杂的交互，极大地增加了人物的形状复杂度，对重建算法的精度和变化拓扑的表达能力提出了极高要求
  + *纹理颜色的复杂性*。另一方面，人体的肤色以及衣物五花八门的颜色、材质属性和跟随人体运动产生的褶皱，这些信息的精准提取和恢复相当困难
  + *精度要求高*。一般三维重建任务比如建筑、物体，如果稍微有一些小瑕疵，可能不会影响太多整体的效果。但是对于人体，比如面部表情、头发、手指等细节，稍有不慎就会显得很不真实，甚至产生恐怖谷效应
  + *训练数据的稀缺性*。人体的数据集 (ground truth) 相对于一般物体的数据集来说，要稀缺得多。这就使得很多方法难以直接应用于人体重建任务
  - 实际上也就是 3D 表示的两个老生常谈的难点 —— geometry 和 appearance，加上各种实际应用的难点
- 三维人体重建的应用：数字人、AR / VR 应用、虚拟主播、动画电影游戏、服装辅助与试衣

== 术语 & 前置知识
- avatar：数字人，属于一种虚拟资产，我们希望它能有自己的形象、能动、能说话、能表情、能交互等等。在人体三维重建领域，一般关注重建后的 (clothed) 人体能摆出各种姿势，能动画化
- LBS：线性混合蒙皮，详细见 @animation 或 #link("http://crd2333.github.io/note/Reading/Sparse%20view%20Reconstruction/SMPL")[SMPL 笔记]
- SMPL，详细见 #link("http://crd2333.github.io/note/Reading/Sparse%20view%20Reconstruction/SMPL")[SMPL 笔记]
  - 提到三维重建中的人体重建话题，SMPL 是绕不开的一个模型。如果要做分类的话，它属于 explicit 方法中的 mesh-based model，因此很自然地与图形渲染管线兼容
  - SMPL 影响力非常大，已经成为人体重建任务广泛应用的一个基础先验 (prior) 或模板 (template)，它主要是针对裸体人体的 shape（高矮胖瘦）和 pose（动作姿势）进行*参数化 (parametric)* 建模（不是神经网络那个参数化的意思！），因此可以给人体重建任务最关键的 geometry and appearance 中的前者提供先验。因为 shape 参数是通过 PCA 降维出的对人体表示影响最大的几个维度，因此 SMPL 也被称为基于 *statistical* 的模型
    - 后续的工作中对它有各种各样的叫法，mesh-based, explicit, prior, template, parametric, statistical... 实际上很多都是指 SMPL 及其衍生模型
  - 跟 LBS 的关系：SMPL 用到了 LBS，LBS 是 SMPL 的一部分
- Canonical Space 规范空间：人体的姿态处于 Zero pose（或称 Rest pose, T pose，即一个“大”字形）
  - #link("https://www.zhihu.com/question/556578310")，有一个问答是就是归一化的三维空间（类似于 {camera} coordinate to NDC 的那种），我觉得答错了，说的应该不是一回事。在人体重建的领域里，canonical space 往往指 a consistent, pose-independent representation that enables smooth animation across diverse poses
  - 一个跟相机内外参的类比
    #q[由于隐式场 MLP 的输入为点的坐标，如果直接输入相机坐标系下坐标的话对于同一个点（比如鼻尖的点），该点在不同帧下由于人头姿态 ${R,t}$ 的影响在相机坐标系下坐标是不一样的，但是同一个点输入 MLP 坐标应该是一样才合理，所以要根据 $R,t$ 将点由相机坐标系转到基准坐标系（即把每帧姿态消除）。这里可以类比世界坐标（即基准坐标）和相机坐标的转换，只是换成了假设人头不动，相机在动，然后人头姿态就等价于相机的外参]
- Pose Space 姿态空间：与 Canonical Space 相对，人体处在某种姿态下
  - 通过 Pose Space 与 Canonical Space 之间的转换，实现广义的“归一化”，从而方便后续的处理，容易改变人体的姿态（从一个规整的姿势去变换而不是从五花八门的姿势去变换）
  - 一般都是用 SMPL-based 方法，从 HPS 得到 $beta, th$，通过 SMPL 的蒙皮权重 (skinning weights) 可以从 canonical space 下的 rest pose template $T$ 转化到 pose space；反过来的话用一个逆过程就好
- Target / Observation Space 观测空间：相机观测到的，人体处于某种随机姿态
  - 跟 Pose Space 的含义差不太多，只不过一个是直接观测到的，一个是变换得到的，类似 predicted value 和 ground truth 的关系，希望它们能够尽可能接近（有的文章可能会区分它们）

== 动画技术 <animation>
- 在正式进入人体三维重建的领域之前，我们可以先看看工业界是如何表示人体并做动画的。*主要*是基于骨骼动画 (Skeletal Animation) + 蒙皮 (skinning) 来实现（可以看 #link("https://www.bilibili.com/video/BV1jr4y1t7WR?share_source=copy_web&vd_source=19e6fd31c6b081ac5b8486c112eafa1f")[08.游戏引擎的动画技术基础(上) | GAMES104-现代游戏引擎：从入门到实践]）
- 模型是由大量顶点 (Vertex) 组成的，或者每三个一组称为网格 (Mesh)，一般来自 blender 或 Maya 这种专门的建模软件。我们知道图形渲染管线是基于 mesh，密集 mesh 构成 geometry，再往 mesh 上面进行纹理映射，为模型添加 appearance
- 但如果想移动任何网格，显然直接移动那么多网格的顶点到指定位置是不实际的，需要添加骨骼 (Skeleton)，有时也叫骨架 (Armature)，就像现实世界一样人体由一根根骨头 (Bone) 组成骨骼
  - 如何产生骨架？可以用正向动力学 (Forward Kinematics)、反向动力学 (Inverse Kinematics)
  - 有了骨骼控制起来就方便多了，但我们还想让角色摆姿势更加方便，于是人们定义骨骼之间的父子节点关系、巧妙设计并组合一些约束（也跟人体很像不是吗），这叫做绑定 (Rigging)。并且添加一些控制器，这样很多需要多个骨骼协同工作的动作就可以通过一个控制器来实现
  - By the way，其实说是骨骼，实际上指的是关节，关节之间的 bone 一般是比较刚性的
  - 这一整套技术实际上不仅应用于人体，而是做 3D 动画的通用方法，应用于各种武器、衣着等（这里就不科学了，外骨骼 bushi）
- 我们希望骨骼和 mesh（或者说大量顶点）以某种方式结合起来，这就是蒙皮 (Skinning)。一根骨头可以控制很多顶点，同时我们希望一个顶点也可以被多根骨头控制（即混合蒙皮，blend skinning）
  - 那么蒙皮到底是怎么实现顶点的变换呢？具体而言：
    - 任何骨骼模型都会有：一个初始位姿 (rest pose) 下的 mesh 上所有顶点位置 $v_1, v_2, ..., v_n in RR^3$，每个骨骼 (joint) 的变换矩阵 $M_1, M_2, ..., M_k in RR^(3 times 4)$（一般是在局部坐标系下，需要乘上父节点的变换矩阵才能得到世界坐标系下的变换矩阵）
    - 在骨骼运动后，新顶点的位置由如下公式给出
    $ overline(v)_i = sum_(j=1)^k w_(i,j) T_j^m (T_j^r)^(-1) v_i $
    - 其中，任意新顶点 $overline(v)_i$ 表示为受到所有骨骼（业界一般会限制在 $4$ 个以下）的影响，通过权重 $w_(i,1), w_(i,2), ..., w_(i,k) in RR$ 来混合。$T_j^r$ 表示第 $j$ 个骨骼在 rest pose 下从局部坐标系到世界坐标系的变换矩阵，$v_i$ 左乘它的逆也就是变换得到这个顶点相对骨骼 $j$ 的位置；$T_j^m$ 表示第 $j$ 个骨骼在 moved pose 下从局部坐标系到世界坐标系的变换矩阵，左乘它得到 move 后世界坐标系下第 $j$ 块骨骼贡献的 $v_i$ 新位置；我们考虑所有骨骼 $j$ 的影响，将它们加权组合就得到上式
  - 这时就需要分配这些骨头对该顶点的权重，这是通过各种蒙皮算法实现的。其中最著名的一个就是线性混合蒙皮，而线性混合蒙皮 (LBS) 是指权重是线性的，使用最广泛，但在关节处可能产生不真实的变形
  - 所谓蒙皮，在 Blender 这种建模软件上其实就是一个快捷键的事，一般来说 Blender 的自动权重已经比较准确了，但也可以手动分配，也就是所谓的刷权重 (Weight Painting)
- 所以整个动画设计的 Pipeline 大致是 (from GAMES104)：
  + Mesh：四个 Stage: Blockout, Highpoly, Lowpoly, Texture，把高精度的 mesh 转化为低精度，为肘关节添加额外的细节
  + Skeleton binding：在工具的帮助下创建一个跟 mesh 匹配的 skeleton，绑定上跟 game play 相关的 joint
  + skinning：在工具的帮助下通过权重绘制，将骨骼和 mesh 结合起来
  + Animation creation：做关键帧，之后插值出中间动画
  #fig("/public/assets/AI/Human/2024-11-02-19-54-23.png", width: 50%)
- 这里额外拓展一下做动画的其它方法（从 GAMES104 看来的）。实际上业界做动画的几种方式里面，骨骼动画是最基础最广泛的一种，但绝不是唯一（主要是想讲一下 blend shape 方法，因为后面会提到）
  + 对于动作比较小又追求高精度的地方（典型的比如人体面部表情），骨骼动画就不那么适用了，这时候就需要 *Morph 动画*，每个关键帧都存储了 Mesh 所有顶点对应时刻的位置
    - 这样精度是上去了，但内存占用也变得不可接受。很自然地我们会想，能不能只存储从中性形状 Mesh 到目标形状 Mesh 的 offset，用插值来确定这个形变的强弱，并且用少量这种基础形状的组合 (blend) 来产生动画呢？
    - 这其实就是 *Blend Shape*（Morgh 动画的一种）。特定地，在面部表情动画里，基础形状就是根据面部动作编码系统 (FACS) 定义的一系列 key poses，通过这些类似基函数的东西组合出各种面部表情
    - Blend Shape 往往与骨骼动画结合使用。比如面部表情动画中，嘴巴张开这种相对较大的动作还是用骨骼实现，而嘴角弧度等精细控制由 key poses 组合得到
  + 从驱动的角度来看，除了 *skeletion driven* 之外，还有 *cage driven* 的方法，即在 mesh 外围生成一个低精度的 mesh 包围盒，用这个低精度的变化来控制高精度的 mesh
  + 对于面部表情动画，还有一个很生草的办法是直接把一系列纹理映射到 head shape 上，对卡通动画比较适用（比如我最喜欢的游戏《塞尔达传说：旷野之息》，还有《动物森友会》也是这么做的）
- 个人认为，所谓骨骼、蒙皮这些概念，就是工业界探索得出的一条既能高精度表示（大量 vertices），又能高效控制（使用蒙皮约束大大减小解空间）的办法，基于图形渲染管线，兼顾美工设计需求（抽象掉了具体的很多细节），更专注于切实可用

== 三维人体重建
- 而 CV, CG 学界为了重建相对精确的人体，宽泛的意义上一般有这几种 setting
  + *基于扫描数据和 RGB-D 数据的方法*
    - 随着一些扫描设备的兴起，RGB-D 数据的获取相对变得容易。这些方法基于融合的思想，通过将每帧深度信息融合到基准空间，在视频的扫描过程中，实时地逐步恢复出完整的人物形状
    - 追踪的精度是此类方法的一个痛点。通过引入人体信息的先验知识，针对人体实现更加快速稳定的跟踪，是此类方法继续改进的目标
    - 然而，尽管深度信息的获取变容易了，但真正广泛而实用的还是单目数据，因此近年来学界会更关注下面两类 setting
  + *基于多视角图片或单目视频的方法*
    - 通过多视角带位姿视图，弥补单张图片信息的不足，从而提高重建的精度，这类方法往往需要多个相机。多个相机比扫描或 RGB-D 数据还是简单一些的，但局限性还是比较大
    - 或者通过虽然单目但是多帧的视频来获取尽量多视角的信息，setting 变得更低，视频数据的获取容易得多。另外，视频中蕴含的时间上的连续性和语义性的先验可以帮助重建算法对抗单目的歧义性
    - 在这个 setting 下，NeRF 和 3DGS 等表示方法已经可以大展身手
  + *基于单张图片重建的方法*
    - 相比起前两种方法，单目数据的获取成本最低，做成了之后应用范围也是最广的。但可能最困难，所以这类工作相对不算特别多
      - 注意，single image 数据本身非常多，但对应的 ground truth 数据是很稀少的
    - 但它也是最具挑战性的，因为单目数据的信息量有限，很难直接从单张图片中恢复出人体的三维形状
      - 一般需要通过大量数据训练来使得模型看过足够多数据，具有 generalization 能力
      - 或者引入一些先验知识，比如用 SMPL 引入 geometry prior，或者用图片生成模型 (e.g. Diffusion Model) 引入 appearance (texture) prior
    - 如果要更难一点，那就不仅仅希望能从 single image 恢复高质量 geometry + texture，还希望重建的人体是 animatable 的

=== From Single Image
- 很自然地，人体重建作为三维重建的子问题、子领域，3D Representation and Reconstruction 下的各种 Implicit and Explicit 方法都可以使用，无非是效果好坏的区别，如果从这种角度来分类的话：
  - *Implicit* 方面，用得最多的是 SDF, Occupacy, (generalizable) NeRF
    - *SDF* 一般不用作最终的表面表征，而是过程中的中间表示（从哪来？SMPL），携带 geometry prior 的信息，作为神经网络的部分输入
    - *Occupacy* 用得非常广泛，大量工作把它和 color（为了得到 texture）作为神经网络的预测目标，原因可能是因为能够通过 Marching Cube 方法转化成 mesh
    - *NeRF* 要求多视角输入，这里指可泛化的能从单张图片重建人体的 NeRF，从 Optimization-based 变成 Learning-based，可以想见这对数据量的要求会比较高，以及对信息提取、先验融合的要求也会比较高
  - *Explicit* 方面，用得最多的是 Voxel, Point Cloud, Mesh, 3DGS
    - *Voxel* 和 *Point Cloud* 同样一般作为中间表示（毕竟你不能指望一堆小立方体或者稀疏点能够很好地表示人体）
    - [ ] *3DGS*，待补充（其在人体重建领域的优势亟待探索）
    - *Mesh* 是人体重建这个领域用的最多的表示，大多数工作即使是用隐式表示，到最后都要把人体转化成 mesh
      - 我觉得原因可能在于，首先人体重建跟 animatable 这个属性绑得比较紧，而 mesh 这种表示方法、以及附带的蒙皮、骨骼动画等技术跟图形渲染管线非常契合
      - 另外也可能是受到 SMPL (mesh-based) 模型的影响。而且 SMPL 已经脱胎于普通的 mesh 表示，成为人体重建领域的基础 geometry prior，基于统计分布把人体变形分解为几组低维的参数化表示，大大缩小了合理的解空间，用来对抗单目数据的歧义性（反过来，如果不依赖与 SMPL，就要直接预测出那么多 vertices 的位置，而且还要满足正确拓扑关系，这是非常困难的）
- 不过如前所述，人体重建有几何、纹理颜色、高精度要求、训练数据稀缺等的复杂性
  - 这就导致这一领域的方法往往比较复杂，需要引入各种先验知识，包含很多 handcrafted 特征和模块（还没到能用大量数据进行 end-to-end 训练的地步），各种方法的混合使用非常普遍（比一般三维重建 topic 更加 hybrid），仍没有一个较好的范式来一统江湖。鉴于该领域的方法五花八门，个人觉得再用 Implicit 和 Explicit 来区分感觉不那么现实了
  - 单视图重建人体这一任务信息很少，对未见部分、遮挡部分力有未逮。一般需要通过大量数据训练来使得模型看过足够多数据，具有 generalization 能力，基本不太能采取 “过拟合到某一视频的人体” 这种做法了（当然，为了最终效果而做一些 optimization-based refinement 还是很常见的）
  - 此外，SMPL 人体模型的引入对结构先验非常有帮助，提高了泛化性，在下面的方法中使用得很普遍。但它的参数预测不准会导致后续有误差累计，也会使得模型对 loose clothes 的支持不佳，属于是一种 trade-off。此外，SMPL 定义的蒙皮权重可以用来驱动人体运动
  - 这一任务实际上已经不止是重建而更多是一个生成问题，于是生成模型那边的进展也能很自然地应用过来，比如 Diffusion Model，对结果的 appearance 尤其有帮助。最浅显的应用自然是生成出多视角图片，进而转化为多视角人体重建任务，但这算是比较粗暴的做法，应该追求更深度的融合
- 下面梳理一遍从 PIFu, PIFuHD, PaMIR 到 ICON, ECON, SHERF 再到 GTA, SIFU 这些工作的发展脉络
  - PIFu 没有引入任何 geometry prior，它单纯使用 image encoder 得到的 2D feature，对 3D 空间的任意点进行投影得到对应 feature，连带着深度送入 MLP 去预测 occupancy + color；PIFuHD 跟 PIFu 差不多，也没有引入 geometry prior，但它在 (a) 多了个从 input image 猜 normal map 的过程（打开了后续*法向图*路线的潘多拉魔盒x），从而进行 coarse-to-fine 的重建
  - PaMIR 开始引入 SMPL prior，先用跟 PIFu 差不多的方法提取 2D feature，用 input image 估计出 SMPL body mesh，然后用 3D global encoder 提取 volume feature，把投影得到的 2D feature 和 volume feature 一起送入 MLP
  - ICON 也是引入了 SMPL prior，在 SMPL 的帮助下预测 normal map，normal map 和 SMPL 进行迭代优化，最后把 SMPL-guided SDF, SMPL body normal 和 normal map 送入 MLP
  - ECON 针对 ICON 中出现的 “几何比法向好” 的问题，将重心转向用法向图重建 2.5D 人体，再利用 SMPL 模型补全成真正的 3D mesh。ICON, ECON 的手工特征较多，整体是想往 explicit 并摈弃 data-driven 的方向走
  - SHERF 将 generalizable NeRF 引入人体领域，定义了三种 Global Feature, Point-Level Feature, Pixel-Aligned Feature 并将之融合，随后利用 NeRF 的方法重建 canonical space 下的 mesh
  - [ ] TeCH
  - GTA 用 ViT 提取图像信息，并用 learnable embeddings 以及 transformer 更好地解耦、利用了 tri-plane 的空间信息表示，然后进一步融合 SMPL 重建 occupancy field
  - SIFU 用 ViT 提取图像信息，用 SMPL 渲染出的法向图做 query 解耦出 $4$ 个侧面的特征，再融合起来重建 occupancy field。并且进一步利用 3D-Consistent Diffusion Model 和 UV map 进行 Texture Refinement
  - Human-LRM 首先用 single-view LRM 模型 encode 再 decode 出 triplane，再用从中渲染出的新视图作为 condition 和 reference 用 Diffusion Model 生成多视图，最后再用相对更成熟的 multi-view reconstruction model 来重建人体
  - HumanSplat
  - [ ] GeneMan


#note(caption: "Reading List")[
  + #link("https://dl.acm.org/doi/10.1145/3596711.3596800")[SMPL: A Skinned Multi-Person Linear Model] (2015.10)
  + #link("https://arxiv.org/abs/1712.06584")[HMR：End-to-end Recovery of Human Shape and Pose] (2017.12)
  + #link("https://arxiv.org/abs/1905.03244")[Convolutional Mesh Regression for Single-Image Human Shape Reconstruction] (2019.5)
  + #link("https://arxiv.org/abs/1905.05172")[PIFu: Pixel-Aligned Implicit Function for High-Resolution Clothed Human Digitization] (2019.5)
  + #link("https://arxiv.org/abs/2004.00452")[PIFuHD: Multi-Level Pixel-Aligned Implicit Function for High-Resolution 3D Human Digitization] (2020.4)
  + #link("https://arxiv.org/abs/2007.03858")[PaMIR: Parametric Model-Conditioned Implicit Representation for Image-based Human Reconstruction] (2020.7)
  + #link("https://arxiv.org/abs/2104.03313")[SCANimate: Weakly Supervised Learning of Skinned Clothed Avatar Networks] (2021.4)
  + #link("https://arxiv.org/abs/2108.07845")[ARCH++: Animation-Ready Clothed Human Reconstruction Revisited] (2021.8)
  + #link("https://arxiv.org/abs/2112.09127")[ICON: Implicit Clothed humans Obtained from Normals] (2021.12)
  + #link("https://arxiv.org/abs/2201.04127")[HumanNeRF: Free-viewpoint Rendering of Moving People from Monocular Video] (2022.1)
  + #link("https://arxiv.org/abs/2212.07422")[ECON: Explicit Clothed humans Optimized via Normal integration] (2022.12)
  + #link("https://arxiv.org/abs/2303.12791")[SHERF: Generalizable Human NeRF from a Single Image] (2023.3)
  + #link("https://arxiv.org/abs/2309.13524")[GTA: Global-correlated 3D-decoupling Transformer for Clothed Avatar Reconstruction] (2023.9)
  + #link("https://arxiv.org/abs/2312.06704")[SIFU: Side-view Conditioned Implicit Function for Real-world Usable Clothed Human Reconstruction] (2023.12)
]