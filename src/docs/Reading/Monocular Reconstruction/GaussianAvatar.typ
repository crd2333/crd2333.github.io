---
order: 2
draft: true
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Monocular Reconstruction -- Human",
  lang: "zh",
)

#let splatting = math.text("splatting")

= GaussianAvatar: Towards Realistic Human Avatar Modeling from a Single Video via Animatable 3D Gaussians
- 时间：2023.12
- CVPR 2024
- 一篇 3DGS 出来后就即时跟进的文章，比较早期，我也就简单概括一下
- #link("https://blog.csdn.net/soaring_casia/article/details/139952332")[原作者翻译解读]

== 概要
- 本文提出了 GaussianAvatar，从单个视频中创建外观动态可变又逼真的 3D 数字人
  - 首先，通过引入可驱动的 3D 高斯，来显示表示处于不同位姿和服装下的人体。这种显式和可驱动的表示可以更有效、更一致地从 2D 观察中融合3D appearance
  - 本文设计的表示进一步增强了动态属性，支持跟位姿相关的外观建模（通过一个动态外观网络和一个可优化的特征张量来学习 motion-to-appearance 的映射）
  - 此外，通过利用 LBS 驱动这一过程的可微分性，能够在数字人建模过程中对运动（即 SMPL 参数）和外观进行联合优化，有助于解决单目设置下老生常谈的人体参数表示估计不准的问题
- GaussianAvatar 的有效性在公共数据集和自己收集的数据集上都得到验证，证明了它在外观质量和渲染效率方面的卓越性能

== 方法
#fig("/public/assets/Reading/Human/2025-01-22-21-48-27.png", width: 90%)
- 使用 GS + SMPL mesh 的混合表示，即 Gaussian-per-vertex（原文非如此表述，是 ExAvatar 的表述，我觉得它们俩类似）
  $ G(be, th, bD, bP) = splatting(W(bD, J(be), th, omega), bP) $
  - $G$ 表示最终渲染的图像，$splatting$ 表示 3DGS 的渲染过程
  - $W$ 代表标准的 LBS 过程，在 $w$ 的 LBS 权重下牵引高斯运动，注意这个权重被继承给每个顶点对应的高斯
    - 原文表述为继承给最近的高斯，这是否会导致若某个高斯周围比较空，有两个顶点都把它视为最近，得到两个蒙皮权重？可能得看代码是怎么实现的
  - $bD = T(be) + dif T$ 为矫正后高斯（顶点）在 canonical space 下的位置，$bP$ 为它们的属性（偏移量、颜色、缩放、方向、透明度）
- 于是现在问题就在于如何得到 3DGS 的属性 $P$ 和 offset $De hat(bx)$
  - 我们知道 3DGS 相比 NeRF，不太好直接结合网络去预测属性，一般通过（个人归纳）
    + 可学习 (per-subject) 的潜空间（张量）
    + 三平面或其它带空间信息的表示 + 投影
    + 局部小 MLP
    + ……
  - 这里采用前两种方法的结合，使用一个动态外观网络（动态意为 pose-dependent），包括一个姿态编码器 U-Net 和一个高斯参数解码器 MLP，学习动作信号与动态高斯参数的映射瓜系，是一个从 2D manifold 到 3D Gaussians 的映射
    $ f_phi: cS^2 in RR^3 -> RR^7 $
    - 这个 2D manifold 可以理解为人体不同位姿下的集合，它是通过 UV positional map 实现的，在 SMPL 的 posed body points 上采样并存储 $(x,y,z)$ 得到 $I in RR^(H times W times 3)$。实际上跟三平面表示 + 投影的思路差不多，这里可以理解为以 UV map 的形式做了特殊的 “投影” 到二维图像上，不过每个点带有空间坐标信息
    - 预测的参数是 $De hat(bx) in RR^3$, color $hat(bc) in RR^3$, scale $hat(s) in RR$。相比起原始的 3DGS，这里有几个变化
      + 不预测球谐函数（与视角方向有关）而是直接预测 RGB，因为对单目视频而言，相当于只有一个视角，直接用 RGB 任务上更简洁有效
      + 将高斯的各项异性变为各项同性，降低单目视频缺少多视角监督而造成过拟合的风险，从而旋转向量（四元数） $bq$ 直接固定为 $[1,0,0,0]$，scale 也变为半径（标量） —— 完全从一个椭球变为球
      + 把不透明度 $al$ 固定为 $1$，这是因为实验观察到网络错误地倾向于让边缘处高斯球 $al = 0$；另外我觉得还有个解释是，既然是跟 mesh 的混合表示，mesh 压根不 care 内部的东西，那也没必要搞体渲染这一套了
  - 另外引入了一个可优化的特征张量 $F in RR^(H times W times C)$，直接加到 pose feature 上
    - 值得注意的是，这整个网络架构跟 #link("https://github.com/qianlim/POP")[之前一篇论文] 是一样的，但作者说 repurpose 了这个网络，并解释了 motivation —— 学习 coarse global appearance，设计了相应的两阶段训练策略
    - 但实际上我感觉这跟原论文 pose-independent 的目的也差不太多，可以学一下这种论文写作方法（x
- 此外，对 SMPL regressor 的结果添加一个可优化的残差，从而对其结果进行联合优化
  $ hat(Th) = (th + De th, bt + De bt) $
- 训练策略
  - 首先第一阶段冻结 pose encoder，不加 pose-dependent 信息，优化其余 framework。这样我们就得到了更准确的 human motions $th, bt$ 以及 feature tensor $F$，说是后者提供了 coarse appearance（但跟 pose-independent 也没什么区别嘛）
  - 第二阶段用不同的 loss 去优化 pose encoder，对 pose feature 加一个惩罚来减轻过拟合 (strong bias of limited training poses)

== 总结
- 实验就不说了
- 通过结合 SMPL/SMPL-X 模型提出了可驱动 3DGS 人体，实现高效建模和实时驱动，外观动作联合优化有效解决初始姿态不准的问题，给予动捕新思路
- 然而 GaussianAvatar 还存在一些问题
  + 无法达到分钟级的建模速度，由于 CNN 的加入，GaussianAvatar 需要几个小时才能在动态外观比较丰富的数据上进行拟合
  + 还无法解决宽松衣物的建模，在裙子等衣物上表现较差（老生常谈的 artifacts）
