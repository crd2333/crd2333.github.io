---
order: 9
draft: true
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Human Reconstruction",
  lang: "zh",
)

#let tri = math.text("tri")
#let pose = math.text("pose")
#let LBS = math.text("LBS")

= Expressive Whole-Body 3D Gaussian Avatar
- 时间：2024.7
- #link("https://github.com/mks0601/ExAvatar_RELEASE")[Github 连接]
- #link("https://arxiv.org/abs/2407.21686")[论文 arxiv 连接]

== 摘要、引言和相关工作
- *Abstract*
  - 面部表情和手部动作对人体表示很重要，但是目前从 casually captured video 建模 3D human avatar 的方法都忽略了这两点
  - 于是作者提出了 ExAvatar，从 short monocular video 学习出 whole-body 3D human avatar，具体方法是把参数化模型 SMPL-X 和 3DGS 结合起来
  - 主要困难点在于：1）视频中面部表情和姿势的多样性有限，让全新表情动画和姿势变得 non-trivial；2）没有 3D 观察（比如 3D 扫描和 RGBD 图像）会导致人体部位的不确定性，在全新动作下不可见部位产生 artifacts
  - 为了解决它们，作者提出了 mesh 和 3D Gaussians 的混合表示方案，把每个 3D Gaussian 看作是 SMPL-X mesh 的一个顶点。这样就可以用 SMPL-X 的面部表情参数驱动 ExAvatar 的面部表情，另外由于遵循三角形的 topology 获得了额外的连接信息，可以用来正则化从而减少 artifacts
- *Introduction*
  - 除了身体的运动，面部表情和手部动作也很重要巴拉巴拉。已经有一些方法去建模这种 whole body geometry，其中 SMPL-X 是应用最广的
  - 为了超越那种仅穿着基本服装的参数化模型，personalized 3D human avatars 最近被广泛研究，它结合了 geometry 和特定人物的 appearance 并且要求可动画化、可渲染新姿势。然而，目前的从任意视频建模的方法都忽略了面部表情和手部动作。而最近虽然有一个可以建模这两者的方法(X-Avatar)，但 setting 比较高（需要 3D 扫码或 RGBD 图像），因此不是很实用
  - 于是作者提出了 ExAvatar，困难、解决方式同摘要。这里多了一句是说，现存的 volumetric avatars 没有用到这种 connectivity 信息（少了这种 geometry 先验的利用）
  - 使用这种 hybrid 方法之后，即使在训练帧中没有见过（缺少多样性），也可以凭借 SMPL-X 和 FLAME 的编码来驱动任何表情，另一个好处就是减少 artifacts (e.g. floating 3D Gaussians)
  - 总的来说，作者的贡献有三点
    + 提出了 ExAvatar，一个可以从短单目视频学习出富有表现力的 whole-body 3D human avatar 的方法
    + 提出了 mesh 和 3D Gaussians 的混合表示方案
    + 提出了 connectivity 信息的使用
- *Related Works*
  - *3D human avatars*。Human avatar 这个领域还算比较火的，发展到现在积累有不少方法
    - #link("https://arxiv.org/abs/1803.04758")[Video Based Reconstruction of 3D People Models] 使用 per-vertex offsets 的 SMPL 扩展；#link("https://arxiv.org/abs/2105.10441")[Driving-Signal Aware Full-Body Avatars] 使用 conditional VAE 达成逼真的结果；#link("https://arxiv.org/abs/2207.09774")[Drivable Volumetric Avatars using Texel-Aligned Features] 提出使用 texel-aligned 特征，即一种局部表征；NeRF 兴起之后，许多 volumetric and implicit representation-based 方法开始涌现，这里就不一一列举（跟我之前看的单视图重建应该是差不多的思路，手工特征很多）
    - 与这些方法相比，最近的工作更关注抛弃 3D 观察数据（扫描、RGBD、多视图），而只用简短的单目视频。#link("https://arxiv.org/abs/2203.12575")[NeuMan] 搞了一个数据集和一个从 in-the-wild 环境的视频重建人体的方法；#link("https://arxiv.org/abs/2302.11566")[Vid2Avatar] 提出一个自监督的解耦了 scene 和 human 的系统；#link("https://arxiv.org/abs/2212.10550")[InstantAvatar] 顾名思义就是注重系统的实时性
    - 而基于最近提出的 3DGS，又有不少新方法。比如 HUGS 和 GaussianAvatar（后面我自己展开说说）
    - 除此之外，还有 #link("https://arxiv.org/abs/2405.07933")[Authentic hand avatar] 使用 universal hand model(UHM) 专注于手的动画；后续 #link("https://arxiv.org/abs/2401.05334")[URHand] 扩展到可照明的情境
    - 跟之前的这些工作相比，本文的不同就在于 whole-body
  - *Whole-body 3D human modeling and perception*。虽然重建人体已经是一个比较 challenge 的事情，但更进一步把 face, body, hands 一起建模就更难了
    - 可以想见这在 geometry 方面的要求非常高，不然人体会变得歪七八扭、表情出现恐怖谷、手部交叉扭曲等等。已经有不少 parametric 方法，把人体表示成 pose, facial, shape code (parameters)，其中 SMPL-X 是使用最广泛的（因为它最完整）。然后基于此，又有不少 3D whole-body pose estimation 的工作。我们可以利用 SMPL-X 之类参数化模型的先验来得到人体 geometry 约束
    - 在 avatars 里面也有一些做了 whole-body 的工作。这里着重说了 X-Avatar 的不足，一是需要结合了 SMPL-X registrations 的 3D 观察数据，因此不适用于 in-the-wild 环境；二是它还需要 3D 观察的视频数据包含 diverse facial expressions，这是因为他们对 FLAME/SMPL-X 的表情空间利用得不好，需要把 mesh-based 表示使用可学习模块转化到 implicit representation 上。另外还有一个也是基于 3DGS 的 whole-body 的工作 #link("https://arxiv.org/abs/2402.16607v1")[GEA]，但是脸部表情不能动
  - *（自添加）跟先前 3DGS-based 方法的比较*
    - 以 CV 社区的卷度，3DGS 从 2023.8 提出到本文 2024.7，肯定已经有 3DGS-based 的方法了，比如 #link("https://arxiv.org/abs/2312.02134")[GaussianAvatar]（#link("https://blog.csdn.net/soaring_casia/article/details/139952332")[参考解读]） 和 #link("https://arxiv.org/abs/2311.17910")[HUGS]（#link("https://blog.csdn.net/qq_40731332/article/details/138764116")[参考解读]）
    - 而且 SMPL-X 先验的使用在人体领域已经是一件很普遍的事情，我粗看了一下，它们都是一个顶点一个高斯球的驱动方法（说明这个 idea 还是比较好想的x）
    - 个人觉得从 high level 的角度它们以及这篇做的都差不太多，都是 SMPL mesh + 3D Gaussians 的混合表示并用 LBS 驱动。具体的高斯球特征表征，GaussianAvatar 是用的一个平面 UV map（怎么感觉看着就效果一般x），HUGS 用的跟本文差不多的 triplane 表征。我觉得本文做得比他们好的地方就是着重突出了 whole-body 的属性以及大量细节的处理（比如 offsets 的提出、FLAME 局部替代 SMPL-X、identity-dependent 和 pose-dependent 的解耦、connectivity 的正则化等等），最终效果上实现超越
    - 但从后文方法部分的分析也可以看到，本文对 3DGS 的利用还处于一个较初级的阶段。从我个人#strike[的品味]来说，我可能会更希望探索 3DGS 更高级的特性在人体重建能否有用武之地（不过好难。。。）

== 方法 <method>
=== Accurate co-registration of SMPL-X <preprocess>
#tldr[加入 joints $De bJ$ 和 face vertices $De bV_"face"$ 两个 offsets，更进一步把 SMPL-X 跟 FLAME 和 2D keypoints 对齐]
- 所谓 short monocular video，假定是在 in-the-wild(one person in natural background)环境下拍摄的 30s 的 frames
- 在训练 ExAvatar 之前，需要做前处理也就是用 SMPL-X regressor 粗估计每一帧的 SMPL-X 参数，即
  $ "poses" th in RR^(55 times 3), ~~ "shape" beta in RR^100, ~~ "facial code" psi in RR^50, "translation" t in RR^3 $
  - 其中 shape 参数对所有帧是共享的，而另外二者是 per-frame 的
  - 然后额外解释一下，pose 跟之前一样是关节点的位置，hand 归入 shape 里面，（facial code 独立出来，是 FLAME 的 face identity code），translation 是全局平移即整个人体的位置
- whole-body avatar 跟一般 avatar 所不同的独特挑战在于，它需要准确地同时优化 face, body, hands
  - 但事实是，由于 SMPL-X 终究还是不够 expressive，在 body registration accuracy 比较差的情况下会对 face 和 hands 造成负面影响（我理解这里的意思应该是，当人体重建地一团糟的时候，脸部和手部可能压根都没有方向、没法优化）
  - 为了解决这个问题，作者为引入了两个 optimizable offsets。它们初始化为零，在所有帧之间共享，并且与 pose, shape, face 独立，依赖于 identity(ID) 也就是每个人，因此，它们在执行 LBS 之前被直接加到 SMPL-X 的 T-pose 模板上
    $ De bJ "for joints", ~~ "and" De bV_"face" "for face" $
    - $De bJ$ 被加到关节点上，这对 fit hands perfectly 非常重要，因为 SMPL-X 的 shape 参数对手部骨架表现力有限，具体怎么做呢？
      - *SMPLX registration*. 从 Hybrid-X 输出的 SMPL-X 参数，进一步优化对齐到 2D keypoints（来自 mmpose 这个 off-the-shelf 工具的估计），并且同时也会对齐到 FLAME 参数（$De bJ$ 跟 $De bV_"face"$ 其实是一起优化的），见下面
    - $De bV_"face"$ 被加到 SMPL-X T-pose mesh 脸部区域的顶点上。具体怎么做呢？
      - *FLAME registration*. 首先 FLAME 是一个 3D face-only model 的参数化表示，用一个叫做 DECA 的方法回归它（得到 FLAME 参数，也就是 face shape parameter, facial expression code, and jaw pose）。然后进一步优化这些参数对齐到 2D poses（2D keypoints，也是来自 mmpose），最小化这个损失
        $ L_"FLAME" = L_"kpt" + 0.1 L_"init" $
        - 从而 DECA 回归出的 FLAME 参数跟图像进行了 pixel-aligned 对齐，并且正则化保证不会偏离太远
        - 之后 SMPL-X 的 facial expression space 直接替换为 FLAME 的，其可行性来自于它们共享同一个 facial expression space
      - *SMPLX registration*. 从 Hybrid-X 输出的 SMPL-X 参数，对齐到 2D keypoints 并且融合脸部的 FLAME 参数表示。T-pose 的关节点加上 $De bJ$，脸部区域 vertices 加上 $De bV_"face"$，优化它们最小化这个损失
        $ L_"SMPLX" = L_"kpt" + 0.1 L_"init" + L_"face" + L_"reg" $
        - 再具体就不写了，太太太细节了（
      - 这里之所以要这种两阶段优化的策略，主要有两个考虑：一是 FLAME 这种 face-only model 的 space 比 SMPL-X 这种 whole-body model 更具有表现力；二是 face-only model 并不受 body registration 的影响
    - 从结果上来看，论文的 Fig 2 和 Fig 3 指出二者的效果很显著（虽然我没看出来x），而且那个两阶段的方案之前方法从来没提过

=== Architecture
#tldr[预处理得到 canonical mesh $oV$，triplane 和 3DGS 表征 identity-dependent 特征，每帧的 pose 和 facial expr 驱动 pose-dependent deformations]
#fig("/public/assets/Reading/Human/2024-12-06-23-32-07.png",width: 70%)
- *Canonical mesh* $oV in RR^(N times 3)$
  - 本文在 canonical space 下建模人体，拥有 $N = 167K$ 个 vertices 和 $335K$ triangle faces。那这玩意儿哪来呢？
  - 首先 SMPL-X 本身就预定义了一个 template mesh 和关节点位置，然后用前面预处理估计出的 SMPL-X 的 shape parameters 去变形调节体型；
  - 接着再加上本文提出的 joint offsets 和 face offsets，细节上再优化了一些；
  - 最后作者还嫌精度不够（至于为什么，之后会理解的），用 PyTorch3d 的 subdivision function（曲面细分）以consistent 的方式进行上采样，最终得到这个 $oV$
    - PyTorch3d 是 facebook（现在应该叫 meta 了x）开源的一个面向 3DV 的工具箱，里面有很多针对 mesh 常用的操作，比如这里的曲面细分
- *Per-vertex Gaussian assets regression*
  - 本文使用经典的 triplane 特征表示（NeRF 延伸工作 EG3D 提出） —— $bT in RR^(3 times C times H times W)$
    - 其中 $C=32,H=128,W=128$ 代表 channel dimension, height, width of the triplanes，三平面初始化为零
  - 然后，准备一个 大-pose 下的 positional encoding mesh $oP in RR^(N times 3)$，并且没有 shape parameters，用同样的 subdivision function 上采样到 $oV$ 的分辨率（或者按论文的话叫 the same mesh topology）
    - 疑问：这个 $oP$ 不就是 SMPL-X 自带的 template mesh 吗？为什么叫 prepare？
    - 为什么不用之前微调过的 canonical mesh $oV$ 来做 feature extraction？这是因为它的 shape parameters $beta$ 和 joint offset $De bJ$ 会继续在训练过程中优化。vertex 位置的变化会导致提取出的特征不稳定
      - *注：*这里个人感觉会导致两边略 mis-aligned，或许是一个可以优化的点。怎么避免这个震荡问题或许可以限制每次更新的步长，让每次位置更新得很小；或者用强化学习的思路做进行平稳
  - 接下来就是常规的把 $oP$ 每个顶点（正交）投影到三平面并双线性插值得到 per-vertex feature
    - 三平面的表示很有用，因为它自然地强化了邻近 vertex 之间的 similarity
    - 然后还有一个实践上的优化(practical trick)，由于面部在整个身体的占比很小，对应到 triplane 的 physical size 就不大，因此为脸部的 geometry 和 appearance 额外创建了一个 triplane 表示
  - 采样出的特征被 concatenated，标记为 $bF in RR^(N times 96)$（$96 = 3C$，$N$ 个顶点但脸部来自另外的 triplane），然后送入两个 MLP，分别回归出用于 3DGS 的：
    + 3D offset $De bV_tri in RR^(N times 3)$, scale $bS_tri in RR^(N times 1)$
    + RGB values $bC_tri in RR^(N times 3)$
    - MLP 对所有顶点共享参数（想想也知道不可能单独x）
    - 受 GaussianAvatar 的启发，为了更好的新视图的泛化性，把所有高斯限制为各向同性，具体来说
      - 回忆 Gaussians 的属性，3D position（均值 $mu$）、用 scale 和四元数 $q$ 来表达的协方差矩阵 $Si$、不透明度 $al$、用球谐函数表示的颜色 $bc$
      - 这里把位置表示成对每个 vertex 的 offset，不透明度设置为 $1$（这两个比较好理解，毕竟现在是跟 mesh 混合的方法，mesh 也是不透明的），并且把 scale 自由度限制到 $1$（这下是真高斯*球*而非*椭球*了），用单位矩阵删去了旋转（既然变成了纯粹的球，那旋转就没有任何卵用）
      - 这是因为单目视频缺少多视角的监督，对于一个视频帧而言，神经网络更容易将高斯球过拟合到当前视角，而当高斯球各项同性时会减小过拟合的影响
    - 特征表示了什么？
      - 从前面 feature extraction 是用 fixed $oP$ 也能知道，triplane 表征的是在所有帧中共享的 identity(ID) 特征，因此是 pose-independent 的。进一步提取出来的 Gaussians 当然也是，然后它们随每一帧的 pose 变化用 LBS 牵引
      - 注：这里说的另外一点是 triplane 特征跟 environment 也是相关的（比如说光照），这我就觉得有点扯了。既然这么说，那就表明他们视频的 in-the-wild 程度还不够，而且人物动作变化应该不大，这样才有可能一整个视频的光照都没怎么变（不然的话随便走动一下光照条件肯定会有变化的）
    - 从上面的分析，pose 的特征并没有在 triplane 中体现出来，但从 SMPL 我们知道 pose 也是会影响人体形状的。因此这里我们需要额外建模 pose-dependent deformations
  - 额外引入两个 MLP
    + 第一个 MLP 接受特征矩阵 $bF$ 和 3D pose $th$（但不包含 root pose），输出 3D vertex offsets $De V_pose in RR^(N times 3)$ 以及 scale offset $De S_pose in RR^(N times 1)$
    + 第二个 MLP 接受同样的 $bF$ 和 $th$，再加上 mesh 每个 vertex 的 normal vector，输出 RGB offsets $De C_pose in RR^(N times 3)$
      - 额外的 normal vector 可以提供 view-dependent shading information，且在解耦 geometry 和 appearance 方面很有帮助（这句不是很理解）
      - per-vertex normal vector 的获取得益于 hybrid 表示，通过把每个顶点参与的面的法向进行加权平均得到
  - 后一节会说，最后把这些 offset $De bV$ 加到每个 vertex 本身的位置上得到高斯球的位置，预测出的 scale $bS$ 和 scale offsets 为高斯球的大小，预测出的 RGB values $bC$ 和 RGB offsets 为高斯球的颜色，不透明度设置为 $1$。这样就得到了 $N$ 个高斯球 (per-vertex)
- 相比起直接预测 pose-dependent Gaussians，本文方法采用 hybrid 方法，基于本就有的 vertex 加上预测出的 offsets，个人理解其好处在于：
  - 从 mesh vertex 基于 offsets 生成 Gaussians 的位置，本身就已经有一个 geometry 先验，且易于驱动
  - 从 triplane 抽特征得到 pose-independent 的 Gaussians 的属性，这样就已经有了合理的表现力。随后 pose-dependent 需要承担的责任就变小，且被解耦出来，能更多地专注于 pose-dependent deformations
  - 这种设计在从短视频中生成 3D avatar 的时候尤为重要，因为视频内 pose diversity 有限，泛化到新 pose 很困难。本文的这种框架能够提高 Gaussians 对 novel pose 的泛化性

=== Animation and rendering
#tldr[高斯球加上偏移量，用 LBS 驱动 per-vertex Gaussians，然后渲染出来，另外还可以做风格迁移]
- *Animation*
  - SMPL-X 的 shape parameters 已经在 $oV$ 用上了，然后我们需要用 facial expression code $psi$ 和 3D poses $th$ 来驱动高斯球
  - offsets 处理
    - 首先我们用 MLP 预测出的手部和脸部的 pose-dependent 的 vertex offset $De V_pose$ 直接替代掉 SMPL-X 的 vertices offsets（SMPL 本身所建模的 pose 引起的 shape 变化）
      - 这是因为手部和脸部通常是裸露的，因此我们可以直接使用 SMPL-X 的 vertex offsets（没懂什么意思？）
    - 然后把来自 facial code $psi$ 的 vertex offsets $De V_"expr"$ 加到 SMPL-X 的脸部 vertices 上
      - 通过直接使用 SMPL-X 的 facial expression offsets，我们不需要学习一个新的 facial expression space，这种直接利用基于 mesh 和 3D Gaussians 的 hybrid 表示
    - 如下式子描述了 canonical space 下的 vertex deformations
      $ oV_tri = oV + De V_tri + De V_"expr" $
      $ oV_pose = oV + De V_tri + De V_pose + De V_"expr" $
      - 其中 $De V_tri$ 和 $De V_pose$ 分别是 triplane 和 pose-dependent 的 vertex offsets（pose 引起的 canonical space 形体变化），$De V_"expr"$ 是 SMPL-X 的 facial expression offsets
      - 从而所有这些偏移量（包括一开始 registration 阶段加入到 $oV$ 里的，以及这里优化预测的）都会参与 LBS 的牵引
  - 然后，对 body vertices，我们取自 downsampled $oV$ 的最近 vertices 的 skinning weight；而对 hand 和 face vertices，使用原始的 skinning weight。这是因为，对于 body vertices，由于 cloth geometry 的影响，它们的语义含义可能会发生变化
  - 最终的 animated geometry $V_tri$ and $V_pose$ 用下面的方程表示
    $ V_tri = LBS(oV_tri, th, W_tri), ~~ V_pose = LBS(oV_pose, th, W_pose) $
    - $V_pose$ 很好理解就是经过 LBS 变换的带位姿的高斯球；而 $V_tri$ 一直保留（即 pose-independent 的部分），这是因为后面要一直用不带位姿信息的高斯球来做渲染并做 loss，从而反向优化 triplane 部分
    - 可能会难以理解 $V_tri$ 后续是怎么跟 captured image 对齐的，实际上如果细看过 SMPL 的话就知道，pose 引起的 shape 变化并不明显，因此 $V_pose$ 相比 $V_tri$ 差得并不算多，经过 LBS 驱动后大体上还是类似的
- *Rendering*
  - 渲染就是 3DGS 那 rendering pipeline，不多赘述
    $
    I_tri = f(V_tri, exp(S_tri), C_tri, K, E) \
    I_pose = f(V_pose, exp(S_tri + De S_pose), C_tri + De C_pose, K, E)
    $
    - 其中 $f$ 代表 3DGS 的渲染方程（但就像上面说的一样略有调整 —— 各向同性 + 不透明），$K, E$ 是相机的内外参矩阵
- *Pose and Garment Transfer*
  - 然后补充一下，论文里所没有提到的是，现在 Github 上 ExAvatar 的最新版本，已经支持类似姿势和服装迁移的效果
  - 怎么实现呢？注意到 co-registration of SMPL-X 跟 Per-vertex Gaussian assets regression 本身就是两个独立的模块。我们完全可以 preprocess 一个视频去 Fit SMPL-X，作为 geometry 指导（动作）；然后另一个视频去 fit Gaussians，作为 geometry 调整和 texture 指导
  - 这样就能实现 github 上那个视频迁移的效果（作者把自己的形体迁移到另一个街舞舞者的动作上，或者也可以说把动作迁移到自己的形体上，差不多）

=== Loss functions <loss>
#tldr[以 image 为粒度做 loss，额外加上 face loss 增强脸部约束，以及 connectivity-based 正则化]
- *整个优化过程的目标*：triplane $bT$、用于回归 Gaussians 的 MLP、每一帧的 3D pose $th$ 和 facial code $psi$ 以及 3D translation $t$、shape parameters $beta$、joint offset $De bJ$
- *同时渲染背景*
  - 除了优化人体之外，也会通过现成的 mask-RCNN 这种分割工具标出 human mask，借此同时优化 background 3DGS
  - 可能是因为 3DGS 的代码来自原论文，所以渲染背景部分比较自然就加上了？
  - 同时建模 background 的好处在于，（遵循 #link("https://arxiv.org/abs/2302.11566")[Vid2Avatar]），它能产生更好的 foreground mask，因为 off-the-shelf 的分割工具会有误差，尤其是手的部分（*疑问：*不用现成工具而用 gaussian splatting 的话，这个 mask 具体如何区分来自前景还是背景？）
  - 这样，前面渲染出来的 $I_tri$ 加上用作背景的高斯球渲染的结果，记作 $I_tri^*$，$I_pose$ 加上背景记作 $I_pose^*$
- 然后优化以下 loss
  - *Image loss*
    - 跟原始 3DGS 一样，渲染出的 $I_tri^*, I_pose^*$ 跟 captured image 之间的 L1 loss, 1-SSIM 做图像粒度的对齐
    - 但额外加上了 LIPIPS loss，对 sharper textures 更有帮助
    - 为了节省 image loss 计算量，把图像裁剪到 human region（*疑问：*那 background 还怎么优化？）
  - *Face loss*
    - face 跟其它区域不一样的地方在于，它需要 geometry 和 texture 之间比较强的一致性。比如 Fig 6 里面，嘴唇 geometry 通常有红色的纹理，如果其它 face geometry 需要唇部纹理，在 novel 表情或下巴姿势下可能不会正确变化，导致显著的 artifacts
    - 简单地最小化上述 image loss 并不能保证这种脸部一致性，这里采取的做法是用另一个渲染器得到的 face image 和 captured image 之间的 L1 loss
      - 这个渲染器是 standard differentiable mesh renderer
      - mesh vertex 哪来？脸部高斯球的位置作为优化变量，它被调整来减小 loss
      - texture 哪来？@preprocess 处优化来的 FLAME 模型同时输出了一个 unwrapped UV texture，这个 texture 被固定
    - 总之这里相当于是说，重利用了先前步骤的结果，为脸部区域加入额外约束
- *Regularizers*
  - 由于训练集中 pose diversity 有限，可能存在一些人体部位不可见，会导致 occlusion ambiguity 并最终导致 novel pose and face 下的 artifacts
  - 为了更好地利用 SMPL-X 的 facial expression offsets，我们需要让 face geometry 跟 SMPL-X 的 face geometry 一致
  - 受之前一些工作的启发，为了解决这一问题，本文使用 connectivity-based regularizers(Laplacian regularizer)，效果如 Fig 7，这个感觉效果很明显
  - 最小化这二者之间的差距
    + canonical space 下 deformed 高斯球的 Laplacian，即 $oV_tri, oV_pose$
    + 最开始的 canonical mesh $oV$ 的 Laplacian
    - 可以看到这跟 $oV_tri = oV + De V_tri + De V_"expr", ~~ oV_pose = oV + De V_tri + De V_pose + De V_"expr"$ 是恰恰相反的，这就是正则化，它限制了这个 offset 是局部小范围的而不能到处乱飘
    - 拉普拉斯是什么意思？是指*拉普拉斯微分算子*，用来描述一个图的局部性质，即论文 introduction 部分说的 connectivity 信息（但不知道为什么这里反而没展开讲）
  - 这种 connectivitybased regularizer 比广泛使用的 L2 regularizer(e.g. GaussianAvatar)更有效，因为能利用 mesh 的 topology 信息。而本文的 hybrid 表示使这种正则项的引入非常自然且容易
  - 除了正则化 3D Gaussian 的位置，还会计算它们的 scales 和 RGBs，具体需要看 supplementary material

== 实验
- *Datasets*
  - NeuMan 提供了 in-the-wild 的short monocular video，每个视频包含单个人在大约 $15$ 秒内四处走动的画面。使用跟先前的工作(GaussianAvatar)一样的视频，遵循官方实现的训练测试集划分，这些视频展示了大部分人体区域，包含最少的模糊图像
  - X-Humans 提供了实验室内采集的包含 3D scans 和 RGBD 数据的 multiple subjects videos。跟 NeuMan 相比，它提供了更多样的 facial expressions 和 hand poses。这个数据集只跟 X-Avatar 做了比较，它使用了额外的 depth maps，而本文不使用
- *Comparison to SOTA methods*
  - Table 1, Table 2 在 NeuMan 的测试集上进行，跟多种方法对比。二者分别是有没有考虑 backgrounds 时的指标计算
    - 我们知道 ExAvatar 是个基于优化而非学习的方法，那这个训练测试是什么意思呢？对 NeuMan，就是对同一个视频，用训练真来训练 @loss 说的那些参数；然后在测试集上，冻结那些参数（除了 SMPL-X 参数要优化，因为至少需要它的 pose parameters $th$ 才能动起来，另外俩 $beta, psi$ 有没有冻结不知道）
  - Fig 8 可视化展示了 NeuMan 上 novel views and poses 下渲染结果的对比。一方面可以明显看到衣服上的印花变得 sharper and clearer，另一方面可以看到由于本文建模了 whole-body，在脸部和手部有更强的 controllibility，纹理也更尖锐，不像之前工作一样只能嵌入模糊的纹理
  - Table 3 和 Fig 9 在 X-Humans 上进行，跟 X-Avatar 对比，在缺失 3D 观察的情况下甚至结果更好
    - 这里的测试跟 X-Avatar 一样，对测试帧直接用了给定标值且没有进一步优化它
- *Ablation studies*
  - 测了两个方法 —— face loss(Fig 6 and Table 5) 和 Laplacian regularizer(Fig 7 and Table 4)
  - 结论是都有效果提升，不赘述
- 然后讨论几个 failure cases
  + 如果 off-the-shelf regressor 估计的 SMPL-X facial expression code $psi$ 不准确，会导致 artifacts。研究更高级的 facial model 和更高精度的 regressor 应该恁更解决这个问题
  + 比如输入视频的人一直在微笑，那么需要迁移到的人如果皱眉的话，并不能正确变换
    - 我个人觉得这好像不是特别严重的问题？因为你如果把这个微笑看作是动作的话，那么就像 demo 一样，既然是迁移，这个皱眉被改成微笑是可以理解的；这里作者的意思应该是把皱眉和微笑理解成 appearance，希望皱眉能像其它 texture 比如皮肤、衣服之类的一样被迁移
    - 此时可以说，微笑的 facial appearance 已经被嵌入到我们的 avatar 了。更进一步深究这个事情的话，个人觉得有点像是 out-of-distribution(OOD) 问题
      - 相比起 body mesh 具有整个 body 的 template mesh，在其上进行 LBS；facial expression code 的 canonical space 只是 template mesh 的一小部分，其“分辨率”跟脸部要求的高精度表示是严重不吻合的
      - *个人理解：*而且我认为这里作者所没说的是，他加的 $De bV_"face"$ 其实加剧了这种情况
        - 我们做一个类比，facial expression code 把脸部表情在 canonical 的基础上进行变换，可以理解成围绕空间的原点进行旋转（只不过空间的“维度”比较低）
        - 那么加一个 identity-specific 的 offset 可以说是导致了原点的偏移。也就是上面脸部表情空间分布完全趋向于微笑的情况，而不是一个标准化的空间
    - 从短单目视频 Canonicalize 出 facial appearance 是很困难的事情，尤其是在本文这种 whole-body 的 setting 下，脸部只占视频的很少一部分 pixels，这就导致 2D key points 的生成变得 noisy，进而导致 SMPL-X/FLAME 的 co-registration 阶段有一定的 misalignment。这种误差会进一步累计/传播到后面的 ExAvatar learning stage，导致上述 failure case
    - 作者认为，使用生成式方法得到 canonical facial appearances 的先验或许能解决这个问题

== 结论
- *Summary*
  - 提出了 ExAvatar，一个 expressive 的 whole-body 3D human avatar 方法，能从短单目视频建模，它能完全适应 SMPL-X 的 facial expression space 并且显著减少了 novel pose 和 face 下的 artifacts
  - 使用了 hybrid 的方法，作者声称这解决了 —— 1) 视频中 facial expressions and poses 的 limited diversity; 2) 3D 观察的缺失
  - 但我个人觉得最重要的还是因为 SMPL-X 提供了一个强有力的 geometry prior，它自然而然地提供了 animatable 的能力，而且比较能无视 input diversity（参数化表示本身就提炼出了人体的很多特征和动作，见得够多了）
- *如果要一句话概括方法*的话，就是
  - 在 SMPL-X 每个顶点上绑一个高斯球，允许一定的局部小范围偏移，从 triplane 预测高斯球们的（部分）特征
  - 这是 high level 的想法，至于具体的参数哪来，怎么提取特征和怎么融合，就都属于 technical details 了，回看 @method 部分
  - 再然后就是 3DGS 的#strike[体]渲染（都不叫 volumetric 了感觉）之类；而且也不涉及 3DGS 的分裂合并，只是简单的一一配对（所以才需要上采样，但这个就感觉比较机械过程了，没能根据结果融入优化过程里面）
    - 因此个人感觉这里对 3DGS 的应用还不是特别深入，有待进一步探索
- *Limitations*
  - 一是说，对于视频里几乎不出现的区域（比如张开的嘴巴和手掌心），模型只能幻视出一个看似合理的猜测
  - 二是说，就跟之前的 avatars 方法一样，难以建模 dynamic cloths，比如宽松的衣物、以及它们的材质信息比如速度加速度
- *Future works*
  - 既然视频里没有信息，那就只能从预训练生成式（大）模型拿先验信息咯，比如 DreamFusion（一个利用 2D Difussion Model 实现 text-to-3D 的工作）的分数蒸馏采样(score distillation sampling, SDS)，就可以用来生成图像并用于监督
    - 其实生成模型仅使用 DensePose 或 2D 姿态做驱动，也已经甚至能从单张图像生成 3D avatar 了，但问题在于这个更多是基于生成而不是重建。前者有其合理性和一定的逼真性，但总归不太真实，至少目前完全不如基于重建的方法真实（最大的问题就是幻觉）
  - 另外，给 ExAvatar 加上 relightability 也是一个有前途的方向（目前的光照是完全耦合在建模出的 texture 里的，也就是 Gaussians 的 RGBs）

#hline()
- *Supplementary Material*
  + Details of co-registration of SMPL-X
  + Architecture of MLPs
  + Regularizers
  + Running time comparison
  + Geometry comparison
  + Comparison to generative AIs
  + Implementation details
  + Failure cases
  - 着重看了看 1, 6, 7，融合在了上述笔记中，其它部分感觉比较浅显就没太细看
