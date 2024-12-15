#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "NeRF 改进工作",
  lang: "zh",
)

#let batch_size = math.text("batch_size")
#let bnu = math.bold($nu$)

#info()[
  - 参考
    + #link("https://github.com/awesome-NeRF/awesome-NeRF")[github.com/awesome-NeRF/]
    + #link("https://zhuanlan.zhihu.com/p/614008188")[NeRF 系列工作个人总结]
    + #link("https://zhuanlan.zhihu.com/p/618913937")[NeRF Baking 系列工作个人总结]
    + #link("https://zhuanlan.zhihu.com/p/586939873")[新视角图像生成：讨论基于NeRF的泛化方法]
    + #link("https://zhuanlan.zhihu.com/p/567653339")[神经体绘制：NeRF及其以外方法]
    + #link("https://mp.weixin.qq.com/s?__biz=MzU2OTgxNDgxNQ==&mid=2247488880&idx=1&sn=c1eedd7a2f9ec49a4d5d9d786fb76330")[【NeRF大总结】基于NeRF的三维视觉年度进展报告--清华大学刘烨斌]
]

= NeRF 进一步的论文（略读）
- 时间按 Arxiv 提交时间排序
- Generalization
  + GRAF: Generative Radiance Fields for 3D-Aware Image Synthesis(2020.7)
  + GIRAFFE: Representing Scenes as Compositional Generative Neural Feature Fields(2020.11)
- Multiscale
  + NeRF++: Analyzing and Improving Neural Radiance Fields(2020.10)
  + Mip-NeRF: A Multiscale Representation for Anti-Aliasing Neural Radiance Fields(2021.3)
  + Mip-NeRF 360: Unbounded Anti-Aliased Neural Radiance Fields(2021.11)
- Faster Training & Inference
  + NSVF: Neural Sparse Voxel Fields(2020.7)
  + AutoInt: Automatic Integration for Fast Neural Volume Rendering(2020.10)
  + FastNeRF: High-Fidelity Neural Rendering at 200FPS(2021.3)
  + PlenOctrees for Real-time Rendering of Neural Radiance Fields(2021.3)
  + KiloNeRF: Speeding up Neural Radiance Fields with Thousands of Tiny MLPs(2021.3)
  + Direct Voxel Grid Optimization: Super-fast Convergence for Radiance Fields Reconstruction(2021.11)
  + Plenoxels: Radiance Fields without Neural Networks(2021.11)
  + InstantNGP: Instant Neural Graphics Primitives with a Multiresolution Hash Encoding(2022.1)
  + TensoRF: Tensorial Radiance Fields(2022.3)
  + MobileNeRF: Exploiting the Polygon Rasterization Pipeline for Efficient Neural Field Rendering on Mobile Architectures(2022.7)
- Representation Enhancement
  + VolSDF: Volume rendering of neural implicit surfaces(2021.6)
  + NeuS: Learning neural implicit surfaces by volume rendering for multi-view reconstruction(2021.6)

== Generalization
- 参考
  + #link("https://zhuanlan.zhihu.com/p/388136772")[NeRF 与 GAN 碰撞出的火花 —— 从 CVPR 2021 最佳论文：GIRAFFE 读起（一）]
  + #link("https://zhuanlan.zhihu.com/p/384521486")[从NeRF -> GRAF -> GIRAFFE，2021 CVPR Best Paper 诞生记]
#grid(
  columns: (70%, 30%),
  fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-16-14-46-37.png"),
  [
    #fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-16-15-11-14.png")
    #fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-16-15-11-31.png")
  ]
)
- 方法总览如上
- GRAF 分成 Generator 和 Discriminator 两个部分
  - Generator 部分将相机矩阵 $bK$（固定），相机 pose $bxi$ ，采样模板 $bnu$ 和形状/外观编码 $bz_s in RR^m \/ bz_a in RR^n$ 作为输入预测一个图像 $bI$ 的一个 patch $P'$
    - 其中每个 Ray 由 $bK$, $bxi$, $bnu=((u,v), s)$ 三个输入决定，$nu$ 表示采样点的 2D 位置和步幅。每个 Ray 上采样点的方法同 NeRF
    - Conditional Radiance Field 是 Generator 唯一可学习的部分
  - Discriminator 对预测合成的 patch $P'$ 和用 $bnu$ 从真实图片采样得到真实 patch $P$ 进行判断
  - 训练阶段，GRAF 使用稀疏的 $K * K$ 个像素点 2D 采样模板进行优化，损失函数如下；测试阶段，预测出目标图片的每个像素的颜色值
  $ V(th, phi) = EE_(bz_s wave p_s, bz_a wave p_a, bxi wave p_bxi, bnu wave p_bnu) [f(D_phi (G_th (bz_s, bz_a, bxi, bnu)))] + EE_(bI wave p_cal(D), bnu wave p_bnu) [f(- D_phi (Ga (bI, bnu))) - la norm(na D_phi (Ga(bI, bnu)))] $
  - $bxi$, $bnu$, $bI$, $bz_s \/ bz_a$ 全都是根据分布随机采样来的
- 说是有泛化性，但其实还是比较有限，只能对同一类物体（比如都是对汽车、椅子）进行建模，在这个基础上形状、颜色略微不同。这个泛化性一方面是 GAN 本身自带一点点，另一方面则是因为引入了 shape/appearance code
- pose 的采样十分让人迷惑，如何保证 Generator 对一个离谱的 pose 依然能生成合理的图片？
  - 原因可能是使用了 GAN，这样尽管 Discriminator 的判别不如 NeRF 的像素级别监督来的有效直接，但迫使 Generator 学会对不同 pose 生成逼真图像。反之，像素对齐很容易让错误的 pose 和 image 对应起来
  - 但还是觉得好奇怪啊。。。

#hline()
- 虽然 GRAF 已经在 3D 的图像生成方面实现了高分辨率的可控图像生成，但 GRAF 仅限于单物体的场景，而且在更复杂的真实世界图像生成方面的表现不尽人意
- GIRAFFE 提出将场景表示为合成的 neural feature fields，能够从背景中分离出一个或多个物体以及单个物体的形状和外观
#fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-16-15-55-39.png", width: 70%)
#grid(
  columns: (70%, 30%),
  fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-16-15-44-22.png"),
  fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-16-15-46-07.png")
)
- 方法总览如上
- 总体而言跟 GRAF 很类似
  - Generator 选取图片 $I$，将相机位姿 $bxi$ 和 $N$ 个形状/外观编码 $bz_s^i, bz_a^i$ 以及仿射变换 $bT_i$ 作为输入
    + 经过 Ray casting 和 Point Sampling 得到以 $j$ 索引的光线，以 $i$ 索引的光线上采样点，这样的所有点云
    + 将其复制 $N$ 份，分别用仿射变换得到 $N$ 个想要表达的物体，送入神经网络得到 每个物体 每条射线 $j$ 每个采样点 $i$ 的隐式表征
    + 使用 Scene Compositions 操作将其在物体层面上整合
    + 接着送入体渲染公式得到 2D 特征图
    + 最后通过一个 2D Neural Rendering 转化成 RGB Image
  - Discriminator 则是对输入图片和预测图片进行判断，没什么好说的
  - 图中橙色矩形为可学习部分，蓝色为不可学习部分
  - 仿射变换 $bT = {bs, bt, bold(R)}$
    - 允许我们将不同物体从场景中分解出来，可以对单个物体的姿态、形状和外观进行控制。具体来说，表示放置物体的算子为
    $ k(bx) = bold(R) dot mat(s_1,,;,s_2,;,,s_3) dot bx + t $
    - 即 Generative Neural Feature Fields 可以表示为
    $ (si, bf) = h_th (ga(k^(-1) (bx)), ga(k^(-1) (bd)), bz_s, bz_a) $
  - Scene Compositions
    - 场景中有 $N-1$ 个 objects，和 $1$ 个 background（其仿射变换始终固定），这 $N$ 个实体的点云的隐式表征 $(si_(i j), bf_(i j))$ 因为仿射变换和 shape/appearance code 而产生不同。这自然产生了一个问题，如何将它们组合到一起？文章给出了一个简单的算子 $C$ ，即将 density 求平均，feature 加权平均，且保证了 backpropagation 的过程中梯度可以传播到每个实体：
    $ C(bx, bd) = (si, frac(1, sum_(i=1)^N si_i) sum_(i=1)^N si_i bf_i) $
  - 2D Neural Rendering $pi^"neural"_th$，看起来比较复杂，但目的很简单
  - 训练阶段，在原始图片集合上进行，测试阶段，可以同时控制相机位姿、目标位姿和目标的形状和外观来产生 2D 图片。并且，GIRAFFE 可以合成超出训练图片中以外的物体
- 回顾一下从 NeRF 到 GRAF 再到 GIRAFFE 的场景表达公式（隐式表达）
  - NeRF:
  $ f_th : (ga(bx),ga(bd)) arrow.r.bar (si, bc) ~~~~~ RR^(L_x) times RR^(L_d) -> RR^+ times RR^3 $
  - GRAF:
  $ g_th : (ga(bx),ga(bd), bz_s, bz_a) arrow.r.bar (si, bc) ~~~~~ RR^(L_x) times RR^(L_d) times RR^m times RR^n -> RR^+ times RR^3 $
  - GRAFEE:
  $ h_th : (ga(bx),ga(bd), bz_s, bz_a) arrow.r.bar (si, bf) ~~~~~ RR^(L_x) times RR^(L_d) times RR^m times RR^n -> RR^+ times RR^(M_f) $

#hline()
== Multiscale
- 动机
  - NeRF 需要沿着光线方向采样，无法处理无边界的场景
  - NeRF 用 MLP 提取（压缩）了场景的辐射场信息，可以想见这个场景不能太大，否则 MLP 难以学习
- 解决方法
  - 一种想法就是类似 MegaNeRF 这样 #h(1fr)
    #fig("/public/assets/Reading/Representations/Improved_NeRF/2024-12-12-11-37-46.png",width:40%)
    - 将大场景划分为一组区域，每个场景用一个 MLP network 表示
  - 另一种想法，我们希望在采样时用非线性变换考虑尺度信息
  - 最后，用 3DGS 这种可以像点云一样无限扩展的显式表示方法，就不会有 NeRF 的这个问题

=== NeRF++
- 具体来说，这篇文章首先讨论了几何-辐射模糊性(shape-radiance ambiguity)这一现象，并且分析了 NeRF 对于避免该现象的成功之处
  - 在缺少正则化处理的情况下，本应该出现结果退化(degenerate solution)的情况，即不同的 shape 在训练时都可以得到良好的表现，但是在测试时效果会明显退化。但是 NeRF 却避免了这种情况的发生
  - 究其原因，作者提出两点（参考 #link("https://zhuanlan.zhihu.com/p/458166170")[NeRF++ 论文部分解读：为何 NeRF 如此强大？]）：
    + 当预测的 geometry 与真实场景相差甚远时，其 surface light field 会变得十分复杂。而正确 geometry 下对应的 surface light field 一般较为 smooth(e.g. Lambertian case)，网络表征高频 surface light field 的局限性迫使其学习到正确的 geometry
    + NeRF 特殊的 MLP 网络结构不对称地处理着位置信息 $bx$ 和方向信息 $bd$，后者的傅里叶特征（位置编码函数中的 $L_bd$）仅由较低频分量组成，且网络输入位置靠后。即对于一个固定的 $bx$，辐射场 $c(bx, bd)$ 对 $bd$ 表示性有限
- 接下来，NeRF++ 引入一种全空间非线性参数化模型，解决无界 3D 场景下 NeRF 建模问题
  - 问题：对于 360 度 captures，NeRF 假设整个场景可以打包到一个有界的体积中。但对于大规模场景来说，要么我们将场景的一小部分装进体积中，并对其进行详细采样，但完全无法捕捉背景元素；或者我们将整个场景放入体积中，由于有限的采样分辨率，到处都缺少细节
  - 想法是，把光线 $br = bo + t bd $ 用半径为 $t'$ 的球分成两部分，用不同的 NeRF（不同的 MLP）去计算
  $
  C(br) = underbrace(int_(t=0)^t' si(bo + t bd) dot bc(bo + t bd, bd) dot e^(- int_(s=0)^t si(bo + s bd) dif s) dif t, (i)) \
  + underbrace(e^(- int_(s=0)^t' si(bo + t bd) dif s), (i i)) dot underbrace(int_(t=t')^infty si(bo + t bd) dot bc(bo + t bd, bd) dot e^(- int_(s=t')^t si(bo + s bd) dif s) dif t, (i i i))
  $
  - (i)项和(ii)项在欧式空间中计算，(iii)在反球面空间中计算 —— 一个处在外球体的 3D 点 $(x,y,z), r=sqrt(x^2+y^2+z^2)$ 可以重参数化为 $(x', y', z', 1/r)$，这个四元组中的所有数都是有界的，提高了数值稳定性（但是变换回原本空间采样频率不还是不够吗？没懂）

=== Mip-NeRF
- 参考 #link("https://blog.csdn.net/weixin_44292547/article/details/126315515")[NeRF神经辐射场学习笔记（四）——Mip NeRF论文创新点解读]，#link("https://blog.csdn.net/i_head_no_back/article/details/129419735")[NeRF必读：Mip-NeRF总结与公式推导]
- Mip-NeRF 的 mip 跟 CG 里 mipmap 的那个 mip 是同一个东西，意思是“放置很多东西的小空间”，旨在解决 NeRF 原始方法由于远景近景的分辨率不同而出现模糊和锯齿的现象。主要创新点分为三个方面
  + Mip-NeRF 的渲染过程是基于抗锯齿的圆锥体(anti-aliased conical frustums)，即 Cone Tracing
    - 当观察方向产生远近或者方向变化时，NeRF 基于 ray 的采样方式对此种变化不敏感，采样频率跟不上变化频率。而基于圆锥体采样的方式显示地建模了每个采样圆锥台的体积变化，从而解决了这种模糊性
    - 对于任意一个像素点，从相机中心 $bo$ 沿着像素中心的方向 $bd$ 投射出一个圆锥体，设在图像平面 $bo + bd$ 处的圆锥面的半径为 $dot(r)$，位于 $[t_0, t_1]$ 圆锥台之间的位置 $bx$ 的集合可以表示为（即径向和轴向分别表征）
    $ F(bx,bo,bd,dot(r),t_0,t_1) = 1{(t_0 < frac(bd^T (bx-bo), norm(d)^2) < t_1) and (frac(bd^T (bx-bo), norm(d)^2 norm(bx-bo)) > frac(1, sqrt(1+(dot(r)\/norm(d))^2)))} $
    - 针对基于圆锥体采样方式，原始的位置编码表达式的积分没有封闭形式的解，不能有效地计算，故采用了多元高斯函数来近似圆锥台。因为每个圆锥台截面是圆形的，而且圆锥台轴线对称，所以给定 $bo, bd$，高斯模型完全由 $3$ 个值来表示：$mu_t$​（沿射线的平均距离）、$si_t$（沿射线方向的方差）、$si_r$（沿射线垂直方向的方差），最终的多元高斯模型为
    $
    mu_t = t_mu + frac(2 t_mu t_de^2, 3 t_mu^2 + t_de^2), si_t^2 = frac(t_mu^2, 3) - frac(4 t_de^4 (12 t_mu^2 - t_de^2), 15(3 t_mu^2 + t_de^2)^2), si_r^2 = dot(r)^2 (frac(t_mu^2, 4) + frac(5 t_de^2, 12) - frac(4 t_de^4, 15(3 t_mu^2 + t_de^2))) $
    其中 $t_mu = t_0 + t_1, t_de = (t_1 - t_0)/2$，我们将其转到世界坐标系中：
    $
    mu = bo + mu_t bd, Si = si_t^2 (bd^T bd) + si_r^2 (bI - frac(bd bd^T, norm(bd)^2))
    $
  + Mip-NeRF 提出了新的位置编码的方法 —— IPE(Integrated Positional Encoding)
    - 首先将位置编码改写为矩阵形式(Fourier feature)
    $ P = mat(1,0,0,2,0,0,,2^(L-1),0,0,;0,1,0,0,2,0,...,0,2^(L-1),0,;0,0,1,0,0,2,,0,0,2^(L-1))^T ga(bx) = vec(sin(bP bx), cos(bP bx)) $
    - IPE 为高斯分布的 positional encoding 的期望值
    $ ga(mu, Si) = EE_(bx wave cal(N)(bP mu, bP Si bP^T)) [ga(bx)] = vec(sin(bP mu) compose exp(- 1/2 "diag"(bP Si bP^T)), cos(bP mu) exp(- 1/2 "diag"(bP Si bP^T))) $
    - 有点难以理解，就把它依旧当成是一条射线，在其上 $t_n wave t_f$ 之间采样许多个高斯椭球就行了，后续渲染依旧是以射线为单位
    - IPE 的优点
      + 平滑地 encode 一个 volume 的大小和形状，考虑了采样点的频率（为越远的点应当提供越少信息量，但 PE 编码违背了这一原则，导致走样），降低了带有锯齿 PE 特征的影响
      + IPE 的高频维度收缩能够使其摆脱超参数 L 的限制
  + Mip-NeRF 使用 a single multiscale MLP
    - NeRF 使用层次抽样 —— fine 和 coarse。这在 NeRF 中是必要的，因为它的 PE 特性意味着它的 MLP 只能学习单一规模的场景模型
    - 但是 Mip-NeRF 服从高斯分布的位置编码可以自动在采样频率较低时（IPE 特征间隔较宽时）弱化高频特征，从而缓解 aliasing 现象。这种采样设计本身决定了其适用于多尺度情况，因此两个 MLP 可以合并为一个
- 缺点
  + IPE 的计算较之 PE 更耗时，但单个 MLP 弥补了这一点
  + Mip-NeRF 相比 NeRF 能够更有效且准确地构建 Multi-View 与目标物体的关系，但这也意味着相机 Pose 的偏差会更容易使 Mip-NeRF 产生混淆，出现更严重的失真。
  + 同理，当拍摄过程中存在 motion blur、曝光等噪声时，Mip-NeRF 也会很容易受到影响（只有当图片成像质量高且相机姿态准确时，Mip-NeRF 才能实现非常棒的效果）

=== Mip-NeRF 360
- 在 Mip-NeRF 的基础上提出三个创新点
  + 非线性场景参数化(non-linear scene parameterization)
    - 提出一种类似卡尔曼滤波的方式将超出一定距离的无界区域的高斯模型变换到非欧式空间中
    #fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-17-11-23-01.png", width: 80%)
    $ "contract"(bx) = cases(bx &norm(bx)=<1, (2-1/norm(bx)) (bx/norm(bx)) ~~~ &norm(bx) > 1) $
    - 该函数将坐标映射到半径为 $2$（橙色）的球上，其中半径为 $1$（蓝色）内的点不受影响。并且其设计使得从场景原点的相机投射的光线在橙色区域具有等距间隔
  + 在线蒸馏(online distillation)
    - 使用一个小的 proposal MLP 和一个大的 NeRF MLP。前者只预测权重 $bw$（体渲染公式的那玩意儿），并用许多采样点反复重采样；后者真正预测隐式表征，只过一遍
    - 感觉就是把原始 NeRF 的 Hierarchical Volume Sampling 分得更开更细化
  + 基于失真的正则项(novel distortion-based regularizer)
    - 传统的 NeRF 经训练后表现出两种模糊现象
      + floaters：体积密集空间中的小而不相连的区域渲染后的结果像模糊的云一样（光线的 $w$ 分布是多峰的）
      + background collapse：远处的表面被错误地建模为靠近相机的密集内容的半透明云（光线的 $w$ 分布没有显著的峰）
    - 提出正则项：regularization 的作用就是拔高单峰，压制多峰（即对于光线上每个点的归一化权重，让显著的更加显著，一群不显著的就都压低）
  - 最后的损失函数考虑了 NeRF 的 $cL_"recon"$，蒸馏的损失函数 $cL_"prop"$，以及正则项 $cL_"dist"$

#hline()
== Fast Train & Inference
=== AutoInt
- 提出一种自动积分框架，可以学习定积分的求解，能在精度只掉一点的情况下比原始 NeRF 快 $10$ 倍
#fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-17-20-32-04.png", width:60%)
- 正常来说我们学习网络参数 $Phi_th$ 去拟合 $f(dot)$，根据微积分基本定理有
$ Phi_th (bx) = int frac(pa Phi_th, pa x_i) (bx) dif x_i = int Psi_th^i (bx) dif x_i $
- 那么如果我们先构建积分网络(integral network)，据此构建梯度网络(grad network)，以“对每个输入的梯度值”作为学习对象，但要求其与被拟合函数对齐，那么最终积分网络的输出直接就是定积分的结果
$ int_ba^bb f(bx) dif x_i = Phi_th (bb) - Phi_th (ba) $
- 具体到 NeRF 里面就是把这个玩意儿用到体渲染公式上去，积分网络直接去预测最后的颜色值

=== NSVF
- NSVF 试图从采样的角度出发解决 NeRF 渲染慢的问题
  - 体渲染需要考虑光线上的许多样本点，对于刚体而言绝大部分非表面样本点没有意义
  - 因此 NSVF 维护了一个*稀疏网格*用来指导光线上的样本点采样，从而跳过不必要的样本点
  #fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-18-14-35-20.png", width: 80%)
- 实际上 NeRF 的运算量大的原因，一方面是不必要的样本点，另一方面则是所有样本点都要过一个大的 MLP
  - 前者被 NSVF 解决了，但后者没有，这也是后来 FastNeRF, Plenoxels, DVGO 的改进处
  - 但 NSVF 提出的一些技术后续依然得到广泛应用
    + *Early Termination*，即并不遍历完光线上所有的样本点，当 transparency $T$ 衰减到一定地步时就停止遍历
    + *Empty Space Skipping*，对于 AABB(axis-aligned bounding box) 网络，可以用另一个更高分辨率的 AABB 网络来指示哪些区域是空的，从而跳过这些区域
    + 网格表示和网格自剪枝(*self-pruning*)，在后续基于网格表示的工作中得到广泛的应用

=== FastNeRF
- 核心方法是受图形学启发的因子分解，允许
  + 简洁地存储空间中每个位置的 deep radiance map
  + 高效地用 ray 的方向查询 map 来估计渲染图像的像素值
- 比原始 NeRF 快 $3000$ 倍，比其他的快一个数量级（CVPR2021 之前）
#fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-17-20-55-09.png", width: 80%)
- 问题：NeRF 一个像素的每个采样点都要调用一次神经网络
  - 为了实时效果利用了 caching，用内存换时间。对空间中 $(x,y,z)$ 每一维均匀采样 $k$ 个值，$(th, phi)$ 每一维采样 $l$ 个值
  - 并且把位置和方向分开存储，复杂度 $O(k^3 l^2) -> O(k^3 (1 + 3 D) + l^2 D)$，解决内存爆炸问题
  - 上面那个 MLP  $F_"pos"$ 只和位置有关，输出 $D$ 个 $(u_i,v_i,w_i)$ 向量，下面的 MLP $F_"dir"$ 只和方向有关，输出上面 $D$ 个向量的权重，最终两个做点乘算 $R G B$ 和 $si$，输入从 $5$ 维变成 $3 + 2$ 维。为了加速也用了跳点和早停策略
- 初看的时候很难理解
  - 在换了 pose 之后，在浮点数世界里采样新的点进行渲染，怎么可能利用得起来之前 cache 的计算结果？
  - 其实深度学习一般用的精度都不高，论文里说是 float16，小数点后也就 $4$ 个有效位。比如方向中的 $th$ in $[0, 2 pi]$，顶天了几万个不同值。并且论文在 Implementation 中提到对于整个 NeRF 场景过大的情况还会把整个包围盒降采样
  - 换句话说，实际上整个场景中的点和方向没那么稀疏，是可以做到稠密地离散化的。可以理解为也是体素化了，把 inference 变成是 offline 的，不再需要过网络而是直接查值。查询时会进行 nearest neighbour interpolation for $F_"pos"$ and trilinear sampling for $F_"dir"$，把输入值规整到 cache 的 key 上去

#note()[
  #tab 这种体素化的方法在同期和后期的许多工作中得到广泛应用。这种方法的思想，在图形学中被称作“烘焙”(bake, baking) —— 将颜色、法线、光照等需要大量计算的东西预先计算好，以某种形式存储起来，之后直接加载

  套到 NeRF 里，就是把原本需要经过大 MLP 的结果提前算好然后固定到体素网格、八叉树、哈希表等，接下来介绍的许多工作都是沿着这个思路展开
]

=== PlenOctrees
#fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-18-15-28-32.png")
- 三个创新点
  - 修改 NeRF 的 radiance field 部分使之基于*球谐函数*实现（MLP 预测对应球谐函数的系数），称之为 NeRF-SH。一方面可能更符合物理，另一方面学习任务变为预测系数，相对简单且更快
  - 提出 sparsity prior，起到的作用类似于 weight decay，其中 $la$ 是超参，$K$ 是空间中采样点的数量
  $ L_"sparsity" = 1/K sum_(i=1)^K |1 - exp(- la si_k)| $
  - 将训练好的 NeRF-SH 网络提取成体素网格，然后压缩到基于八叉树的结构中（对辐射场进行预计算，避免渲染时进行网络推理，即空间换时间，随后用 Octree 节省存储空间）
    + Evalution：把包围盒均匀划分成网格，然后预测这些网格点的 $si$。这个网格能够 auto scale 到适应场景的大小（通过调整包围盒大小使所有网格点的 $si$ 都大于一个阈值 $ta_a$）
    + Filtering：对每个网格点，计算它在所有训练视图渲染的 $w$ 最大值，然后利用阈值 $tau_w$ 过滤掉未被占用的点（它在任何一个视角下都是内部点）。以剩下的每个点为体素中心，作为叶节点来构建体素网格的八叉树（每个叶节点要么是体素要么是空节点）
    + Sampling：对于固定下来的叶节点体素，内部随机采 256 个点预测其 $si$ 和球谐函数系数更新该体素的值（反走样）
    - 并且可以进行微调(tree structure fixed, finetune values to optimize)
- 优缺点
  + 这样构建一个八叉树大概要用 $15$ min，但是后续就不用再过网络而是直接查八叉树的值，推理速度快得多
  + 渲染结果上看跟原始 NeRF 其实差不太多甚至好一点
  + 但它最大的缺点在于空间占用太大，一个物体就需要接近 2G 的存储（尽管已经使用八叉树来减少了）

=== KiloNeRF
#fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-18-19-21-42.png", width: 70%)
- Idea 非常直观，把空间体素化，每个体素用不同 tiny MLP
- 使用三阶段策略：
  + 训练一个原生 NeRF
  + 将原生 NeRF 的 MLP 预测结果逐点蒸馏到 tiny MLP 中
  + fine-tune tiny MLP。为了加速也用了跳点和早停策略
- 评价
  - Idea 直观，主要是代码实现有挑战性，作者用 CUDA 实现了一个 GEMM 使得不同样本点通过 tiny MLP 并行计算
  - 显著降低运算量并加渲染约数千倍
  - 相比于其他方法，其灵活性相对较差，不太好转换也不好部署

=== Plenoxels
#fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-19-11-59-05.png", width: 90%)
- 跟 PlenOctrees 是同一个作者
  - 作者发现 Baking 的主要作用反而不是 Raidance 部分的固定，而是 Geometry 部分的固定（PlenOctree 的 fine-tune 不改变八叉树结构）
  - 而且我个人觉得这种训练完再 baking 的思路不那么端到端。那么能不能在训练的过程中就以 Baking 的表征进行训练呢？Plenoxels 就是这样的尝试
  - 八叉树并不是一个适合进行形状优化的表征，所以 baking 表征又回到了稀疏体素网格上
- Plenoxel 是完全的 explicit 方法，没有用到任何 MLP
  - 为场景构建体素网格。遵守 Coarse to Fine 的原则，后续训练到一定阶段时，对网格进行上采样（一分八，分辨率从 $256^3 -> 512^3$ ，插值出的网格参数用三线性插值得到）；同时会对网格根据 $w$ 或者 $si$ 进行剪枝，仅关注非空网格
  - 只用网格顶点来存参数（沿用 PlenOctree 中用到的 $si$ 和球谐函数系数）。要渲染一条光线，只需要在光线上采点并根据样本点的位置进行三线性插值（比较 PlenOctree 是查询八叉树得到样本点所在网格的值）从而得到样本点的参数，最后在进行体渲染积分即可
  - 直接用顶点参数进行学习，但有个问题是相邻网格之间的参数是独立的（不像神经网络那样连续），导致失真
    - 想象一下，我某部分网格参数调整得比较好来满足训练视角的渲染，而一些网格随便糊弄一下。很自然的，可以想到添加相邻顶点之间的正则化项
    - 对此 Plenoxel 提出了相应的 smooth prior，通过计算 TV loss 来使相邻网格的值变得平滑
  $ cL_"TV" = frac(1, |cV|) sum_(bv in cV, d in cD) sqrt(De_x^2(bv, d) + De_y^2(bv, d) + De_z^2(bv, d)) $
  - Plenoxel 也处理了 Unbound Scene 的情况，方法和 NeRF++ 较为相似，用 sparse grid 处理内部情况；用多层球壳(Multi-Sphere Images)处理外部情况，不同层之间可以进行插值（外部的球壳不再是 view-dependent 的了，而是类似贴图）
- 评价：在实际使用中 Plenoxel 可能并不是很好用。一方面，完全 explicit 方法不是那么即插即用，不好融合到别的方法；另一方面，explicit 设计很容易陷入局部最优解（网格顶点间的特征相对孤立），产生撕裂效果的失真（论文里用的是合成的数据，噪声比较少，但在真实场景下就不是这样了）。与之相比，大家还是更倾向于 Hybrid 方案，用离散的特征存储结合小型 MLP 的方式，实现存储、速度、效果的权衡

=== DVGO
#fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-19-19-42-38.png")
- DVGO 应该是第一篇 hybrid NeRF 的工作，只是时运不济，被 InstantNGP 盖过了风头
- DVGO 的主要贡献
  + 用网格存取特征取代了 Encoding（和 Instant-NGP 的 hash encoding 是一个性质的，具体分析见下文）
  + 三线性插值后过一个 SoftPlus，网格顶点的值可以学的更广，增强了网格拟合高频信号的能力
  + 分了两个阶段训练
    - 先 Coarse geometry searching 学出大概的 coarse density grid $V^(("density")(si))$ 和 coarse color grid $V^(("rgb")(c))$，一方面用来加大采样密度，另一方面做跳点加速（剪枝无效空间）
    - 然后进行上采样 + 微调，对颜色的预测引入一个 MLP，结合了网格学习的特征和神经网络学习(hybrid)
  - 一句话概括：通过体素网格低密度初始化、插值后激活等训练策略直接优化体素表达的 NeRF 密度场与颜色特征场，实现分钟级别的训练收敛

=== InstantNGP
#fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-19-13-31-01.png")
- Instant NGP 同样使用了体素网络，这并不是创新。但是它用哈希表这一数据结构来加速查找，并使用多分辨率混合来得到以往 Coarse-to-Fine 的效果。更重要的是，它这一整套方法的 CUDA 配套代码工程价值极高，这才有了它极快的速度（但其实几秒出图也只是能粗看的状态，更多是个噱头，实际优化到论文中的指标还是需要几分钟的时间，但已经比原始方法快非常非常多），奠定了它的巨大名气，直接盖过了 Plenoxel 和 DVGO 的风头
- 我们可以比较一下到此为止 encoding 的演变
  + NeRF 和 Mip-NeRF 分别使用了 PE 和 IPE，它们没有可供学习的参数，只是引入了高频信息和尺度信息
  + 稠密参数编码：一些使用 grid 的方法引入了 Baking 的思想，通过查询和插值大大加快了渲染速度；并且参数可学习提高了表达能力。坏处是，稠密参数编码的空间占用是立方级别（只有 $approx 2.5%$ 的区域是有效的表面），并且有时展现出过于平滑的学习，总的来说太浪费资源
  + 稀疏参数编码：于是一些方法提出 Coarse-to-Fine 的训练（但可能由于定期更新稀疏数据结构而使训练复杂度增加），一些方法提出 Octree 和 sparse grid，但其剪枝或多或少要求表面信息而影响方法适用性
  - 而 Instant NGP 采用 hash table，本质上来说也是一种可学习的参数编码，跟 grid 没太大区别，只是查询得更快。但通过引入这一数据结构，我们可以很方便地使用 $T$ 来控制参数数量，同时多个哈希表实现 muitiscale 也更自然。另外，hash table 相比 tree structure 更加 cache 友好
  - 引用一个解读
    #q[
      回到我一开始对 NeRF 的 Position Encoding 的解读，我认为 Positional Encoding 是对欧式空间的三个轴分别引入了一组正交基函数，MLP 则用来预测这些个基函数的系数。我觉得这一套观点可以套进 Instant-NGP 或者下面会说到的 DVGO 这些个 Hybrid 方法中，*它们网格存储的值可以视作是某种基函数在该点的离散采样*。高分辨率等同于高采样率，这也就意味着高分辨率的网格可以存取高频基函数的离散点采样结果，相对的低分辨率的网格则存取低频基函数的离散点采样结果。只是相比于给定的一组正交基函数，这些个网格对应的基基本不会是正交的，但确实可以学习可以优化的，这就意味着 MLP 的学习负担被更进一步地降低，整个收敛过程也会更快。*Multi-Resolution 最重要的一点在于引入了合适的归纳偏置 (inductive bias) 来使得不同分辨率的网格能够捕获到相应频率的信息*
    ]
- 下面看一下 InstantNGP 的具体做法
  - 整体流程和 NeRF 依旧类似，但是位置信息采用 hash table 编码（方向信息依旧是 PE），预测密度特征的 MLP 变小。两个 MLP 和 hash table 都会在训练过程中优化
  + 按照多种分辨率将空间划分成网格（图示为二维情况，方便理解），每个网格顶点都有其量化的坐标
  + 构建并初始化 $M$ 个大小均为 $T$ 的 hash table，每个表代表一种分辨率，其中每个顶点保存的特征编码维度为 $F$。构建 hash function，从而建立每个网格顶点坐标到 hash table 的索引
  + 对于输入的点 $bx$，在每个分辨率下找到他最近的 $8$ 网格顶点，利用 hash function 取出对应的值；利用三线性插值得到该点的特征编码，将每个分辨率下的特征 concate 起来，随后送入 MLP
- Multi-resolution
  - 我们通过超参 $T$ 去控制 hash table 的大小，为了达到良好的效果，这个值往往设置得比最大分辨率网格要小很多，但比最小分辨率要大(e.g. $16^3 < 64^3 < 512^3$)，显然高分辨率下会发生 hash collision
  - 我们知道网格中绝大部分区域（非表面）是无效的，如果是无效区域的网格顶点和物体表面附近的网格顶点发生了冲突，通过梯度反传，hash table 中的值自然会更加关注物体表面区域的密度值。换句话说，通过 MLP 的注意力自适应地实现了剪枝（或者说，*体素压缩*）

=== TensoRF
#fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-19-22-32-47.png",width:90%)
- 使用张量分解技术，将 4D 张量分解成多个低秩的张量分量，以小见大。论文中使用了 CP 分解和 VM 分解，当然也可以尝试使用其他的张量分解方式
- 本质上是把体素网格分解为低维平面网格表达，空间占用从立方级降为平方级
- 不细看了，类似思路的还有：EG3D(Efficient Geometry-aware 3D Generative Adversarial Networks, CVPR 2022), MeRF(Memory-Efficient Radiance Fields for Real-time View Synthesis in Unbounded Scenes, SIGGRAPH 2023) 等

=== MobileNeRF
- 假如我们设计了这样一种 NeRF
  + 每条射线上的采样点位置和个数（且远少于原始 NeRF）是已知的
  + 每个采样点的位置特征向量是预先存储好的(grid, bake)，仅执行 NeRF MLP 最后那一小部分（称作 Decoder）的推理
  + 对于当前待渲染画面的每个像素，上述的计算是通过图形渲染 pipeline 在 GPU 上并行的
  - 那么这种新 NeRF，相比原始 NeRF，显然会大幅降低计算量。MobileNeRF 就是这样的设计，以至于可以在移动设备上实时运行
- 为了实现上述过程，作者将训练分为三个阶段：
  + 初始化一个 grid mesh，基于可微渲染思想，学习场景的几何结构，以及透明度 $al$ 连续的 Radius Field
  #fig("/public/assets/Reading/Representations/Improved_NeRF/2024-10-20-00-36-16.png")
    - 初始化一个三维 grid mesh（先生成 voxel grid，每个 grid 中设置一个点，作为顶点 vertice，每相邻的 4 个连接组成 mesh face，整个 mesh 被称为 grid mesh），初始化三个 MLP，分别预测透明度 $al$、空间特征向量 $f_k$（即 NeRF Encoder）、颜色 $c$（即 NeRF Decoder）
    - 根据相机位姿以及像素坐标，计算射线，射线与 grid mesh 的交点作为采样点（不是原始 NeRF 的随机采样了），颜色加权融合计算 loss
    - MobileNeRF 采用了可微渲染的思想，把 vertice 位置作为可训练参数，用 loss 推动顶点位置变化，同时用正则化限制每个顶点的“活动范围”在格子内
    - 借鉴 InstantNGP，创建了另一个 $P times P times P times 1$ 的 grid mesh，用于排除无关区域，加速训练
    - 引入 sparsity loss 和 smooth loss
  + 将 $al$ 二值化
    - 因为在渲染引擎里，处理半透明的 mesh，比完全透明或安全不透明的要更耗时，因此需要将透明度进行二值化，同时继续训练参数
    - 为了让训练更稳定，在第二阶段训练过程中，既渲染合成透明度二值化时的最终图像 $hat(C)(r)$，又渲染合成透明度连续时的图像 $C(r)$，二者 loss 相加回传
    - 最后当 loss 快收敛时，冻结其它参数，只 finetune $cal(F), cal(H)$
  + 对 grid mesh 进行剪枝操作，保存为 OBJ，以及烘培特征向量为纹理图像 Texture，保存 Decoder 的网络权重
    - 将训练图像完全无法“看到”的 face 删除（$95%$ 以上的 grid 都被删除），然后保存为 OBJ
    - 给每个 face（四边形）分配一个分辨率为 $K times K$ 的纹理区域(texture patch)，因为 face 的顶点坐标已知，容易计算 texture patch 上每个像素对应的空间坐标，获得相应的特征值。这样就完成了 bake 特征纹理的工作（即 Encoder 的输出）
  - 后面的部分就比较简单了，主要创新点在于这里的各种优化和想到把 Decoder 塞到 shader 里面从而利用传统图形学 pipeline 的已有技术
- 优点：
  + 第一次实现了移动设备上的实时神经渲染
  + 通过引入 OBJ, texture 以及 neural shader，使得很多传统图形优化技术，可以直接使用。例如对大型场景的 LOD，九宫格加载等
- 缺点：
  + 仅通过一个采样点来代表整条光线路径，当需要表现出半透明或者高光等复杂光学现象时，需要较高的模型精度以及准确的材质模型，mobileNeRF 并不擅长解决后两者
  + 通过固定分辨率的网格学习表达整个空间，会导致两个问题：细节分辨率不够；大块平坦区域的 mesh 过于碎片化，顶点数过多
  + 为了降低最终的 obj 顶点数量，在第三个阶段删除了对于训练图像完全不可见的 face。这要求采集训练图像时覆盖几乎所有渲染阶段需要的相机角度，否则会在渲染画面中出现大量的空洞。另外，这种删除策略也会损失模型的“泛化能力”，表现是在相邻相机角度切换时，出现“画面突变”
  + 推理快但训练慢，$8$ 卡 A100，训练 $24$ 小时左右

=== IBRNet & MVSNeRF
  - 利用 MVS 的方法降低训练迭代次数
  - *IBRNet* 将图像特征输入神经网络直接预测每个空间点的颜色和密度
    #fig("/public/assets/Reading/Representations/Improved_NeRF/2024-12-12-11-18-38.png",width:80%)
    - IBRNet: Learning Multi-View Image-Based Rendering
    - $"RGB"$: 采样点投影到各输入视角，然后用神经网络预测最后的 RGB 值（其实可以直接拿像素值颜色的平均，但神经网络往往能学出更好的结果）
    - $al$: 采样点投影到各输入视角，比较它们像素值的方差，如果比较小，就认为这里确实有个点，$al$ 给大

#hline()
== Representation Enhancement
- 动机
  - NeRF 的重建几何质量较低，尤其是在表面容易产生粗糙凹凸面
  - 另外，它在弱纹理区域难以重建（老大难问题了）
- *几何重建质量低*
  - 动机
    + 基于 Surface Rendering 的方法仅关注其与表面的交点部分，而基于 Volume Rendering 的方法的样本是光线上的很多采样点，所以后者能够更合理和全面地对隐式场进行监督
      - 换句话说，基于 Volume Rendering 能够使这个变形更“深入”，因为它能够在当前表面的远处也产生监督，而 Surface Rendering 与之相比则容易陷入到当前表面附近的局部最优解
    + 但 NeRF 这种隐式表示也有其困难，因为我们最终的目的一般还是渲染刚体，从中提取高质量的表面是困难的，因为在表示中没有足够的表面约束（NeRF 本质上还是基于“体”的表达，在“面”上没有足够的约束，实际上跟上一点的）
    + 隐式曲面场具有表示几何的优越性，但难以通过 NeRF 光线步进的方法渲染训练；若使用朴素方法将隐式曲面函数转换为密度函数，光线积分所估计的表面位置会略近于真实表面
  - 比如，VolSDF(Volume rendering of neural implicit surfaces, NeurIPS 2021), NeuS(Learning neural implicit surfaces by volume rendering for multi-view reconstruction, NeurIPS 2021) 用 SDF 指导采样点的生成，数学公式推导比较多，不细看了
  #fig("/public/assets/Reading/Representations/Improved_NeRF/2024-12-12-11-25-24.png",width:80%)
- *弱纹理区域的重建*
  - MonoSDF: 使用 Monocular depth and normal 作为约束
  #fig("/public/assets/Reading/Representations/Improved_NeRF/2024-12-12-11-27-31.png",width:80%)

#hline()
== Lighting
- 动机
  - 互联网图片存在光照不一致的情况
  - 更进一步，同一个场景随时间不同纹理图案的变化（比如涂鸦、墙纸）等，也可以视为某种程度的“光照”
- *NeRF in the Wild: Neural Radiance Fields for Unconstrained Photo Collections*
  - 非常暴力，在 NeRF 输入中加入可学习的外观编码，以建模外观变化
  - 在此基础上可以改变光照 #h(1fr)
  #fig("/public/assets/Reading/Representations/Improved_NeRF/2024-12-12-11-28-46.png",width:40%)

#hline()
== Video
- 原始的 NeRF 从静态场景进行学习，无法建模动态场景
- 动态街景建模
  - Street Gaussians for Modeling Dynamic Urban Scenes
  - 对场景进行解耦表示，对每个运动物体重建一个 NeRF（其实是说辐射场，用 3DGS 建模）
  - 对每个物体单独重建的另一个好处是，编辑变得很方便，比如换个车、改轨迹等
- 任意动态场景建模
  - 动态场景中的物体移动导致无法进行多视图匹配
  - *Deformable NeRF*
  #grid2(
    columns: (60%, 40%),
    fig("/public/assets/Reading/Representations/Improved_NeRF/2024-12-12-11-31-18.png"),
    fig("/public/assets/Reading/Representations/Improved_NeRF/2024-12-12-11-32-03.png")
  )
    - 将动态场景建模为一个 canonical NeRF 和一个 deformation field
    - 当然，这样建模出来的运动不能太大，不然 deformation 优化不出来
- 动态人体建模
  - Neural Body
  - 4K4D

