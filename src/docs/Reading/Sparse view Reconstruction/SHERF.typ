---
order: 6
draft: true
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Sparse view Reconstruction -- Human",
  lang: "zh",
)

#let trans = math.text("trans")
#let attn = math.text("attn")
#let global = math.text("global")
#let point = math.text("point")
#let pixel = math.text("pixel")
#let LBS = math.text("LBS")

= SHERF: Generalizable Human NeRF from a Single Image
- 时间：2023.3

== 概要
- 现存的 Human NeRF 方法一般要求大量多视角图片，或是固定位置的单目视频，这跟真实场景相违背
- SHERF 是第一个 generalizable Human NeRF model，可以从单张图片重建可动画化的 3D 人体
- SHERF 在 canonical space 中提取编码人体表示，同时捕捉了 global appearance 和 local fine-grained textures。这是由 a bank of 3D-aware hierarchical features 实现的：
  + Global features 增强图片提取的信息并补充部分 2D 观察所缺失的信息
  + Point-level features 提供 strong clues of 3D 人体结构
  + Pixel-aligned features 保护 fine-grained details
  - 为了将它们高效合并，设计了 feature fusion transformer
- 在 THuman, RenderPeople, ZJU_MoCap, and HuMMan 数据集上进行了广泛实验，证明 SOTA 的实力，代码开源在 #link("https://github.com/skhu101/SHERF")[github/skhu101/SHERF]

== 引言
- 第一段宽泛引入
- 现存 Human NeRF 主要有两类
  + 第一类从单目或多视角视频中重建，但是 subject-specific 很耗时且不适应时代发展
  + 第二类探索泛化模型，可以用少许 multi-view 图片在一次前向中快速重建人体，但是需要在 well-defined camera angles 下。MonoNHR 解决了这个问题，但它重建的人体不能动，应用受限
- generalizable, single image, animatable 有两个挑战
  + missing information from partial observation。目前的 generalizable Human NeRF 太关注保护局部特征，在补足缺失信息上不足
  + single image but animatable。需要连贯的(coherent)人体结构的理解
- SHERF 如前所述提取并合并了 hierarchical features，可以在 visible 区域重建正确颜色，在 invisible 区域给出大概正确(plausible)的猜测。前者得益于 geometry and color details，后者得益于 global features。为了 animatablility，SHERF 在 canonical space 建模人体，用 SMPL prior 把 hierarchical features 转换到 canonical space 进行 encode
- 主要贡献
  + 第一个符合 generalizable, single image, animatable 三个属性的 Human NeRF
  + 提出 3D-aware hierarchical features，让 SHERF 能够恢复细节并补全缺失信息
  + 新视角和新姿态合成上的 SOTA 性能

== 相关工作
- *Human NeRF*。给定多视角图片或单目视频，Human NeRF 能够高质量合成新视角或姿态，激发了人体重建的工作。Neural Body 把稀疏卷积应用于辐射场，而其它方法使用 SMPL LBS weights or optimizing LBS weights with appearance 在 canonical space 中建模 human NeRF。但是他们需要密集观察和长时间优化，为此探索从 single image 用一次前向过程泛化的 generalizable 方案，同时提出 animatable 的追求
- *Monocular Human Reconstruction*。基于统计的 3D 人体模型通过估计 coarse human shapes and poses 来建模人体（或者叫 Parametric, template 的方法，都是一个意思，即利用 SMPL 来约束单目重建的 geometry）。通过估计 mesh deformation 来建模 clothed humans 的复杂形状。Implicit representations(e.g. SDF)，被用来提高 geometry 质量。为了充分利用 explicit and implicit representations，研究者探索了 hybrid 的方法来得到更好的重建质量和泛化性，比如我看过的 #link("http://crd2333.github.io/note/Reading/Sparse%20view%20Reconstruction/ICON%20%26%20ECON")[ICON & ECON]。相比之下，NeRF 的优势在于不需要 3D ground truth 进行训练；此外，作者在 canonical space 中重建人体，可以很容易地改变人体的姿态
- *Generalizable NeRF*。NeRF 需要密集的带位姿视图，但最近一些发展使得用很少甚至单个视图来训练 generalizable NeRF 成为可能。Cross-scene multi-view aggregators 可以通过学习如何 aggregate sparse views 来合成新视图；其它方法将观察 encode 到 latent space 中，然后 decode 到 NeRF。作者的工作则专注于将单视图 encode 到 canonical space 中的 generalizable Human NeRF

== Preliminary
- 在看 SHERF 之前，我们先来简单看一下它的前置技术（都看过了，这里不展开，仅列一下核心公式）
  + 一是 NeRF（#link("http://crd2333.github.io/note/Reading/Representations/NeRF")[我的 NeRF 笔记]） #h(1fr)
    $ hC(br) = int_(t_n)^(t_f) T(t) si (br(t)) bc(br(t),bd) dif t $
  + 二是 SMPL（#link("http://crd2333.github.io/note/Reading/Sparse%20view%20Reconstruction/SMPL")[我的 SMPL 笔记]） #h(1fr)
    $ bx^o = sumkK w_k bG(bth,bJ) bx^c $
- 不过这里我们可以看一看非 generalizable 的普通 Human NeRF 是怎么做的
  - 把 NeRF 用到人体重建的想法非常自然，所以归类于 Human NeRF 的方法也不少，SHERF 在 related works 里列了很多，不过比较有代表性和影响力的是 #link("https://arxiv.org/abs/2201.04127")[HumanNeRF: Free-viewpoint Rendering of Moving People from Monocular Video] (CVPR2022 oral)，见 #link("http://crd2333.github.io/note/Reading/Sparse%20view%20Reconstruction/HumanNeRF")[HumanNeRF 笔记]

== 方法
#fig("/public/assets/Reading/Human/2024-11-15-22-23-42.png",width:80%)
- 首先明确输入输出和总体思路
  - 输入单张图片 $bI^o$，假设相机参数 $bP^o$ 已知，人体区域的 mask 已知，并且相应的 SMPL 参数 ${th^o,be^o}$ 也已知
  - 输出人体在 target camera view $bP^t$ 和 SMPL 参数 ${th^t,be^t}$ 下的渲染结果
  - 为了渲染 target space 下的图片，我们发出射线并采样点 $bx^t$，通过逆 LBS 转换到 canonical space 下的 $bx^c$
    - 怎么转换呢？貌似 SHERF 并没有去学这里的参数，而是直接把 SMPL 参数和蒙皮权重拿来用了。之所以能这样，应该是因为后面提特征做得更高效、更优秀
    - 论文中说，它们使用 nearest SMPL vertex 的转换矩阵和逆转换矩阵
    - 或许可以在这里把 HumanNeRF 里的那整个 Pose Correction + Motion Field 都搬过来，用作 inference-only 的 refinement（因为是 Optimization-based），效果应该会更好？
  - 接着，用 hierarchical 的方式提取特征，先按下不表
  - 然后用一个 feature fusion transformer 从 bank of 3D-aware hierarchical features 去 query $bx^c$ 的总特征
    $ f_trans (bx^c) = attn(f_global (bx^c), f_point (bx^c), f_pixel (bx^c)) $
    - 先用 MLPs 把三个 level 的特征 project 到 32 channels，然后用一个三头自注意力层去整合它们
    - 为什么要用自注意力？因为特征融合其实并不是一个 trivial 的事情，比如直觉上，可见部分应该更依赖于 pixel-aligned features。self-Attention 机制有助于这件事情
  - 最后把 $bx^c$ 连带它的特征 $f_trans (bx^c)$ 丢到 NeRF decoder 里预测密度 $si$ 和颜色 $bc$，跟 HumanNeRF 一样，作为 $bx^t$ 的密度和颜色去渲染出图片来
    - NeRF decoder 来自另一个 generalizable Human NeRF 的工作 MPS-NeRF（NHP 和 MPS-NeRF 作为前 SOTA 成为 SHERF 衡量的 benchmark），但是它们都专注于提取 local feature 导致不能很好地补全缺失信息，这也正说明 hierarchical feature extraction 的重要性
- 下面我们一个个说明 Hierarchical Feature Extraction 是怎么做的
  + *Global Feature*: global structure 和 overall appearance 对单目人体重建这种 partial observation 任务很重要
    - 利用 2D Encoder(ResNet18 backbone) 把输入图片压缩成 compact latent code $f in RR^512$
    - 然后为了高效解码，采用 EG3D 的 tri-plane 式的体素分解策略（用 GAN 的 generator + discriminator 训练的）。用 Mapping Network 把 $f$ 映射到 512 维的 style vector，然后丢进 Style-Based Encoder 生成特征，再 reshape 到 tri-plane representation
    - 这样我们就能把变换到 canonical space 下的任何点 $bx^c$ 正交投影到三个平面上，提取 3D-aware global features $f_global (bx^c)$
  + *Point-Level Feature*: 利用 SMPL prior 搭建 global structure 和 local details 之间的桥梁
    - 利用 2D Encoder(ResNet18 backbone) 提取输入图片特征得到 feature map $f in RR^(64 times 256 times 256)$，为了保留更多 low-level 细节，对 RGB 值做 positional encoding，然后拼接到 $f$ 上得到 $f in RR^(96 times 256 times 256)$
    - 将 observation space 下的 SMPL vertices 投影到 feature map 上，只提取可见顶点(from the input view)的特征（make the point-level feature aware of occlusions），然后逆 LBS 转换到 canonical space
    - 体素化成 3D volume tensor，再用 $4$ layers of #link("https://github.com/traveller59/spconv")[sparse 3D convolutions] 处理，得到 canonical space 下的 96-dimensional point-level features，这样我们就可以从 encoded sparse 3D volume tensors 中提取 $f_point (bx^c)$
    - 相当于是说，把 2D feature 转存到 mesh 上的点里，再转化到 3D volume 上
  + *Pixel-Aligned Feature*: 前面 point-level 的信息由于 SMPL mesh resolution 和 voxel resolution 有限，可能会有信息丢失，所以我们进一步提取 pixel-aligned features
    - 使用 feature map $f in RR^(96 times 256 times 256)$ 同上
    - 将 canonical space 下的 $bx^c$ 转换到 observation space $bx^o$，然后投射 $(Pi)$ 到 input view 的 feature map$(W(I^o))$上，得到 pixel-aligned features $f_pixel (bx^c)$
      $ f_pixel (bx^c) = Pi (W(I^o); LBS (bx^c;th^o,be^o)) $
    - 如果是 multi-view input 的设置，不同的 pixel-aligned features 应该能指示出 3D 点与表面的远近，但在 SHERF 的 single image setting 下，得不到这种隐式信息。为了避免过拟合到无用的 pixel-aligned features，就根据 $bx^c$ 和最近 SMPL 顶点之间的距离为 pixel-aligned features 分配不同的权重
      - 这个就有点像 HumanNeRF 那个 volume 的思路了，只不过这里用的是写死的权重，但可以根据距离来调整；而 HumanNeRF 是直接学出一个好的权重
  - PS: 看了下代码，感觉写得好乱，根本没和论文里三层结构分开对应上。。。

== 实验 & 分析 & 结论
- 在 THuman, RenderPeople, ZJU_MoCap and HuMMan 这些数据集上做验证，把 MPS-NeRF 和 NHP 作为 benchmark 比较，定性和定量都表现出 SOTA 的实力
- 接下来分析几个更细的指标(or settings)
  - *Training Protocols*。以前的 generalizable Human NeRF 方法大多会在训练的时候仔细选择 camera views 并固定它们，而 SHERF 用 free view inputs 训练。不过这里也分别用 Front View Input / Free View Input 去都训练了一遍，结果显示前者效果明显更好，但 SHERF 一开始就采用的 free view inputs 更符合现实，并且在两种 setting 上 SHERF 都更好
  - *Different Viewing Angles as Inputs*。输入视图在 $[0 deg, 360 deg]$ 角度之间均匀采样 $12$ 个视角，渲染其它 $11$ 个角度的图像，结果显示 SHERF 在不同视角输入下都比之前的 SOTA 表现得更好，而且对于不同的输入视角也表现得很稳定
  - *Viewing Angle Difference Between Target and Observation*。考虑输入视角和目标视角之间的角度差异对新视角合成的影响，发现差异越小，模型越容易合成新视角；而且 SHERF 在所有输入设置下都由于 baseline
  - *Generalizability*。在 THuman 上训练的 SHERF, NHP, MPS-NeRF 在 ZJU_MoCap 上推理，SHERF 表现最好，甚至能和直接在 ZJU_MoCap 上训练的 NHP, MPS-NeRF 相当
  - *Runtime*。generalizable Human NeRF 只用一次前向过程就能完成重建，所以一般都比较快，但 SHERF 的速度也比 NHP, MPS-NeRF 快
- 总结一下，SHERF 是第一个可以从单张图片重建可动画化 3D 人体的 generalizable Human NeRF
  - 跟 HumanNeRF 比泛化（为什么可泛化呢？因为基于学习的方式学了通用的特征提取方式），跟其它 generalizable Human NeRF 方案比 animatable（为什么可动画化呢？因为在 canonical space 下建模）和效果（为什么效果好呢？因为 hierarchical feature），最终达到了 SOTA
  - 但这里是跟同类 generalizable Human NeRF 的方法比出的 SOTA，却没有跟 setting 类似甚至更低（不用准确 SMPL prior，也不用复杂相机参数）的 ECON 比较（时间上比 ECON 晚），看图感觉纹理细节不如 ECON（可能它这个 hierarchical feature 还是不如 ECON 那种手工特征和各种细节有效），而且 ECON 的 github stars 也比 SHERF 高得多
- 缺陷
  + 有些部位被遮挡时，目标渲染中仍然存在可见的 artifacts。需要更好的特征表示来解决这个问题
  + 如何补全单张图片输入中缺失的信息仍然是一个具有挑战性的问题。SHERF 基于重建视图这个任务，预测出的新视图相对来说具有确定性。一个潜在的研究方向是使用 conditional generative models 来多样地生成更高质量的新视图
  + #text(fill: gray.darken(20%))[而且闭口不谈 ECON 所挑战的 challenging poses 和 loose clothes，感觉是在回避问题？]
- 可能的负面社会影响云云

== 论文十问
+ 论文试图解决什么问题？
  - 从单视图(with SMPL and camera parameters)重建一个 animatable 3D 人体
+ 这是否是一个新的问题？
  - 不是，有基于 Implicit 特别是 NeRF 的，有基于 Explicit 而且效果很好的 ECON，这篇论文主要对比的是同 setting 的 generalizable Human NeRF
+ 这篇文章要验证一个什么科学假设？
  - hierarchical feature 对 generalizable Human NeRF 很有效
+ 有哪些相关研究？如何归类？谁是这一课题在领域内值得关注的研究员？
  - 基于 Implicit 的，比如 PIFu, PIFuHD, PaMIR, ICON 这些（它们都是同样 single image 的 setting），Implicit 中基于 NeRF 的又可以分为 Optimization-based 和可以 generalize 的两类；基于 Explicit 的比如 ECON
  - 比较值得关注的研究员
    + THU 的 Yebin Liu 和 Zerong Zheng (PaMIR)
    + MRL 的 Zeng Huang (ARCH), Tuny Tung(ARCH, ARCH++), Shunsuke Saito (PIFu, PIFuHD)
    + MPI 的 Gerard Pons-Moll, Justus Thies 以及 Yuliang Xiu (ICON, ECON)
    + ETH 的 Siyu Tang
+ 论文中提到的解决方案之关键是什么？
  - hierarchical feature extraction
  - 用 generalizable NeRF 做隐式函数
+ 论文中的实验是如何设计的？
  - 在 THuman, RenderPeople, ZJU_MoCap and HuMMan 上跟 MPS-NeRF 和 NHP 两个同样是 generalizable NeRF 的方法比较，分析了各种指标和设置
+ 用于定量评估的数据集是什么？代码有没有开源？
  - 数据集如上，代码开源在 #link("https://github.com/skhu101/SHERF")[github/skhu101/SHERF]
+ 论文中的实验及结果有没有很好地支持需要验证的科学假设？
  - 支持论文自己的假设应该是可以的，但我总觉得不跟 ECON 比划一下而只跟同样 generalizable NeRF 的方法比较，有点自适应 setting 的感觉
+ 这篇论文到底有什么贡献？
  - 提出 hierarchical feature，特征提取和融合得更好
  - 通过 canonical space 和 observation space 的转换实现 animatable
+ 下一步呢？有什么工作可以继续深入？
  - 如果还是用 NeRF 的渲染方法和隐式函数的话，想要提升效果，能做的似乎就只有更好地提特征了（更好地融入 prior）
  - 然后，NeRF 后续的那么多工作中的 techniques 都可以用上来，在速度、存储、泛化性等等各种方面进行提升
