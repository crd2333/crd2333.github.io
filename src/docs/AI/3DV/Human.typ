---
order: 2
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Reconstruction",
  lang: "zh",
)

#info(caption: [参考])[
  + #link("https://zhuanlan.zhihu.com/p/442488645")[人体三维重建（一）—— 绪论]
  + #link("https://zhuanlan.zhihu.com/p/442959552")[人体三维重建（二）—— AR/VR应用]
  + #link("https://zhuanlan.zhihu.com/p/443409212")[人体三维重建（三）—— 参数化人体方法简述]
  + #link("https://zhuanlan.zhihu.com/p/443860216")[人体三维重建（四）—— 非参数化人体方法简述]
  + #link("https://zhuanlan.zhihu.com/p/691329488")[Human-NeRF 详细理解：从 LBS 到 Human-NeRF]
]

= 人体重建
- 在对三维重建有一些基本的了解之后，下面我们专注与人体重建这一个子领域，梳理一下从传统方法到现代方法的脉络
- 狭义的人体数字化主要包含对某一特定人物进行几何重建与纹理估计。这一问题的复杂性主要在两方面
  + *几何的复杂性*。人体的几何受相当多的因素的影响，包括性别，体态，种族和姿态等。特别是姿态的变化，产生了人体复杂的大尺度非刚性形变，使得广泛应用于人脸的形状混合(BlendShape)和主成分分析(PCA)等线性变形方法难以直接应用于人体的变形。另外，由于人体会穿戴各种材质的服装和各式各样的物体，它们本身的表达以及与人体之间复杂的交互，极大地增加了人物的形状复杂度，对重建算法的精度和变化拓扑的表达能力提出了极高要求
  + *纹理颜色的复杂性*。另一方面，人体的肤色以及衣物五花八门的颜色和材质属性，使得精准地提取人物的纹理信息也变得相当困难
  - 实际上也就是 3D 表示的两个老生常谈的难点 —— geometry 和 appearance
- 三维人体重建的应用：AR / VR 应用、虚拟主播、动画电影游戏、服装辅助与试衣

== 动画技术
- 在正式进入人体三维重建的领域之前，我们可以先看看工业界是如何表示人体并做动画的。*主要*是基于骨骼动画(Skeletal Animation) + 蒙皮(skinning)来实现（可以看 #link("https://www.bilibili.com/video/BV1jr4y1t7WR?share_source=copy_web&vd_source=19e6fd31c6b081ac5b8486c112eafa1f")[08.游戏引擎的动画技术基础(上) | GAMES104-现代游戏引擎：从入门到实践]）
- 模型是由大量顶点(Vertex)组成的，或者每三个一组称为网格(Mesh)，一般来自 blender 或 Maya 这种专门的建模软件。我们知道图形渲染管线是基于 mesh，密集 mesh 构成 geometry，再往 mesh 上面进行纹理映射，为模型添加 appearance
- 但如果想移动任何网格，显然直接移动那么多网格的顶点到指定位置是不实际的，需要添加骨骼(Skeleton)，有时也叫骨架(Armature)，就像现实世界一样人体由一根根骨头(Bone)组成骨骼
  - 如何产生骨架？可以用正向动力学(Forward Kinematics)、反向动力学(Inverse Kinematics)
  - 有了骨骼控制起来就方便多了，但我们还想让角色摆姿势更加方便，于是人们定义骨骼之间的父子节点关系、巧妙设计并组合一些约束（也跟人体很像不是吗），这叫做绑定(Rigging)。并且添加一些控制器，这样很多需要多个骨骼协同工作的动作就可以通过一个控制器来实现
  - By the way，其实说是骨骼，实际上指的是关节，关节之间的 bone 一般是比较刚性的
  - 这一整套技术实际上不仅应用于人体，而是做 3D 动画的通用方法，应用于各种武器、衣着等（这里就不科学了，外骨骼 bushi）
- 我们希望骨骼和 mesh（或者说大量顶点）以某种方式结合起来，这就是蒙皮(Skinning)。一根骨头可以控制很多顶点，同时我们希望一个顶点也可以被多根骨头控制（即混合蒙皮，blend skinning）
  - 那么蒙皮到底是怎么实现顶点的变换呢？具体而言：
    - 任何骨骼模型都会有：一个初始位姿(rest pose)下的 mesh 上所有顶点位置 $v_1, v_2, ..., v_n in RR^3$，每个骨骼(joint)的变换矩阵 $M_1, M_2, ..., M_k in RR^(3 times 4)$（一般是在局部坐标系下，需要乘上父节点的变换矩阵才能得到世界坐标系下的变换矩阵）
    - 在骨骼运动后，新顶点的位置由如下公式给出
    $ overline(v)_i = sum_(j=1)^k w_(i,j) T_j^m (T_j^r)^(-1) v_i $
    - 其中，任意新顶点 $overline(v)_i$ 表示为受到所有骨骼（业界一般会限制在 $4$ 个以下）的影响，通过权重 $w_(i,1), w_(i,2), ..., w_(i,k) in RR$ 来混合。$T_j^r$ 表示第 $j$ 个骨骼在 rest pose 下从局部坐标系到世界坐标系的变换矩阵，$v_i$ 左乘它的逆也就是变换得到这个顶点相对骨骼 $j$ 的位置；$T_j^m$ 表示第 $j$ 个骨骼在 moved pose 下从局部坐标系到世界坐标系的变换矩阵，左乘它得到 move 后世界坐标系下第 $j$ 块骨骼贡献的 $v_i$ 新位置；我们考虑所有 $j$，将它们加权组合就得到上式
  - 这时就需要分配这些骨头对该顶点的权重，这是通过各种蒙皮算法实现的。其中最著名的一个就是线性混合蒙皮，而线性混合蒙皮(LBS)是指权重是线性的，使用最广泛但在关节处可能产生不真实的变形
  - 所谓蒙皮，在 Blender 这种建模软件上其实就是一个快捷键的事，一般来说 Blender 的自动权重已经比较准确了，但也可以手动分配，也就是所谓的刷权重(Weight Painting)
- 所以整个动画设计的 Pipeline 大致是(from GAMES104)
  + Mesh：四个 Stage: Blockout, Highpoly, Lowpoly, Texture，把高精度的 mesh 转化为低精度，为肘关节添加额外的细节
  + Skeleton binding：在工具的帮助下创建一个跟 mesh 匹配的 skeleton，绑定上跟 game play 相关的 joint
  + skinning：在工具的帮助下通过权重绘制，将骨骼和 mesh 结合起来
  + Animation creation：做关键帧，之后插值出中间动画
  #fig("/public/assets/AI/human/2024-11-02-19-54-23.png", width: 50%)
- 这里额外拓展一下做动画的其它方法（从 GAMES104 看来的）。实际上业界做动画的几种方式里面，骨骼动画是最基础最广泛的一种，但绝不是唯一（主要是想讲一下 blend shape 方法，因为后面会提到）
  - 对于动作比较小又追求高精度的地方（典型的比如人体面部表情），骨骼动画就不那么适用了，这时候就需要 *Morph 动画*，每个关键帧都存储了 Mesh 所有顶点对应时刻的位置
    - 这样精度是上去了，但内存占用也变得不可接受。很自然地我们会想，能不能只存储从中性形状 Mesh 到目标形状 Mesh 的 offset，用插值来确定这个形变的强弱，并且用少量这种基础形状的组合(blend)来产生动画呢？
    - 这其实就是 *Blend Shape*（Morgh 动画的一种）。特定地，在面部表情动画里，基础形状就是根据面部动作编码系统(FACS)定义的一系列 key poses，通过这些类似基函数的东西组合出各种面部表情
    - Blend Shape 往往与骨骼动画结合使用。比如面部表情动画中，嘴巴张开这种相对较大的动作还是用骨骼实现，而嘴角弧度等精细控制又 key poses 组合得到
  - 从驱动的角度来看，除了 *skeletion driven* 之外，还有 *cage driven* 的方法，即在 mesh 外围生成一个低精度的 mesh 包围盒，用这个低精度的变化来控制高精度的 mesh
  - 对于面部表情动画，还有一个很生草的办法是直接把一系列纹理映射到 head shape 上，对卡通动画比较适用（比如笔者最喜欢的游戏《塞尔达传说：旷野之息》，还有《动物森友会》也是这么做的）
- 个人认为，所谓骨骼、蒙皮这些概念，就是工业界探索得出的一条既能高精度表示（大量 vertices），又能高效控制（使用蒙皮约束大大减小解空间）的办法，基于图形渲染管线，兼顾美工设计需求（抽象掉了具体的很多细节），更专注于切实可用。我们之后会看到，学界的很多方法其实不是这样

== 三维重建
- 而 CV CG 学界为了重建相对精确的人体，一般有三种思路
  - 基于 RGB-D 数据的方法。随着一些扫描设备的兴起，RGB-D 数据的获取相对变得容易。这些方法基于融合的思想，通过将每帧深度信息融合到基准空间，在视频的扫描过程中，实时地逐步恢复出完整的人物形状。然而，追踪的精度是此类方法的一个痛点。通过引入人体信息的先验知识，针对人体实现更加快速稳定的跟踪，是此类方法继续改进的目标。然而，尽管深度信息的获取变容易了，但真正广泛而实用的还是单目数据
  + *参数化*人体形状来正则化解空间。参数化人体模型基于人类归纳的统计分布，将人体变形分解为几组低维的参数化表示（如形状、姿态）。通过对人体形变空间的低维流形嵌入，大大缩小了合理的解空间，用来对抗单目数据的歧义性。此类方法往往通过优化、回归等手段，建立图像与人体低维参数空间的映射，来实现人体重建。然而，人类裸体形状还比较符合低维假设，但各式衣物的形状归属于极其高维的空问，难以参数化为低维表示。这就使得参数化人体的方法难以推广到穿衣人体之上。目前常见的参数化人体模型如 SCAPE、SMPL、SMPL-X 等
  + 利用神经网络做隐式神经表示，包括 voxel, SDF 等，相对于参数化方法称为*非参数化*（但不是神经网络非参数的意思！）。此类方法的一大局限是训练模型依赖于数据集，存在泛化能力不足，过拟合等问题。另外，由于高精度的穿衣人体几何数据的获取本就十分困难，稀缺数据是此类方法落地的一大阻碍。此外可以利用视频数据增加更多的正则化。利用人类运动在时间上的连续性和语义性的先验可以帮助重建算法对抗单目的歧义性，多帧之间的对应关系也可以设计一些正则化来帮助优化和网络的拟合。比如隐式神经表示和 NeRF 的崛起

- [ ] 上面的一般思路是抄来的，我决定还是先自己多看几篇论文再去总结这件事
  - Explicit 的方法
    - SMPL —— mesh-based statistical model (parametric, template)
  - Implicit 的方法


== 术语 & 前置知识
- avatar：数字人，属于一种虚拟资产，我们希望它能有自己的形象、能动、能说话、能表情、能交互等等。在人体三维重建领域，一般关注重建后的(clothed)人体能摆出各种姿势，能动画化
- LBS：线性混合蒙皮，如前面所介绍的
- SMPL
  - 提到三维重建中的人体重建话题，SMPL 是绕不开的一个模型。如果要做分类的话，它属于 explicit 方法中的 mesh-based model，因此很自然地与图形渲染引擎兼容
  - SMPL 影响力非常大，已经成为人体重建任务广泛应用的一个基础先验(prior)或模板(template)，它主要是针对裸体人体的 shape（高矮胖瘦）和 pose（动作姿势）进行参数化(parametric)建模，因此可以给人体重建任务最关键 geometry and appearance 中的前者提供先验。因为 shape 参数是通过 PCA 降维出的对人体表示影响最大的几个维度，因此 SMPL 也被称为基于 statistical 的模型
    - 后续的工作中对它有各种各样的叫法，mesh-based, explicit, prior, template, parametric, statistical... 实际上很多都是指 SMPL 及其衍生模型
- Canonical Space 规范空间：人体的姿态处于 Zero pose（或称 Rest pose, T pose，即一个“大”字形）；
  - #link("https://www.zhihu.com/question/556578310")，有一个问答是就是归一化的三维空间（类似于 {camera} coordinate to NDC 的那种），我觉得答错了，说的应该不是一回事。在人体重建的领域里，canonical space 往往指 a consistent, pose-independent representation that enables smooth animation across diverse poses
  - #q[由于隐式场 MLP 的输入为点的坐标，如果直接输入相机坐标系下坐标的话对于同一个点（比如鼻尖的点），该点在不同帧下由于人头姿态 ${R,t}$ 的影响在相机坐标系下坐标是不一样的，但是同一个点输入 MLP 坐标应该是一样才合理，所以要根据 $R,t$ 将点由相机坐标系转到基准坐标系（即把每帧姿态消除）。这里可以类比世界坐标（即基准坐标）和相机坐标的转换，只是换成了假设人头不动，相机在动，然后人头姿态就等价于相机的外参]
- Pose Space 姿态空间
  - 与 Canonical Space 相对，人体处在某种姿态下
  - 通过 Pose Space 与 Canonical Space 之间的转换，实现广义的“归一化”，从而方便后续的处理，容易改变人体的姿态（从一个规整的姿势去变换而不是从五花八门的姿势去变换）
  - 一般都是用 SMPL-based 方法，从 HPS 得到 $beta, th$，通过 SMPL 的蒙皮权重(skinning weights)可以从 canonical space 下的 rest pose template $T$ 转化到 pose space；至于逆过来怎么搞？

  - 与观测空间不同的是，姿态空间的人体姿态是客观存在的（Ground Truth），而观测空间观测到人体处于的姿态是一种“观测值”，通常地这两种空间的人体姿态是一样的（除非我们在研究微观物理）；
- target/Observation Space 观测空间：相机观测到的，人体处于某种随机姿态；