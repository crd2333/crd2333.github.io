---
order: 8
draft: true
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Sparse view Reconstruction -- Human",
  lang: "zh",
)

#let SDF = math.text("SDF")
#let RGB = math.text("RGB")

= Template-Free Single-View 3D Human Digitalization with Diffusion-Guided LRM
- 时间：2024.1

== Abstract
- 从单个图像重建 3D 人体已经得到了广泛的研究。然而，现有的方法往往无法捕捉到精细的 geometry and appearance details，用貌似真实的细节来想象遮挡部分会产生幻觉，并且难以泛化到 unseen 和 in-the-wild 数据
- 作者提出了 diffusion-guided 前向模型 Human-LRM，从单个图像预测人体的 implicit field。Human-LRM 结合了 SOTA 重建模型 LRM 和生成模型 Stable Diffusion，可以在没有任何模板先验(e.g. SMPL)的情况下捕捉人体，并有效地生成真实细节去丰富遮挡部分
- 作者的方法首先使用 single-view LRM 模型结合 enhanced geometry decoder 来获得 triplane NeRF 表示。然后从 triplane NeRF 渲染出的新视图提供 geometry 和 color 先验，让 diffusion model 为遮挡部分生成真实细节。生成的多视图使得重建具有高质量的 geometry 和 appearance，成了新 SOTA

== Introduction
- 从 single image 重建 3D 人体是 CV 领域的重要研究方向，有着广泛的应用(AR/VR、asset creation、relighting, .etc)和海量各有优劣的方法
  - Parametric reconstruction methods，或者说 human mesh recovery(HMR)，通过回归 SMPL 的 pose 和 shape 参数来重建人体，但不包括衣物细节
  - implicit volume reconstruction methods 利用 pixel-aligned 特征捕捉衣物细节，但不能泛化到各种姿态
  - 最近的 hybrid 方法（这里的 hybrid 是 parametric 和不包括 NeRF 的 implicit 方法的混合，不是指 explicit 和 implicit 的混合）使用预测的 SMPL mesh 作为条件来指导 full clothed 重建。然而这些 SMPL-conditioned 方法面临不可避免的局限性：SMPL 预测误差会累计，导致重建出的网格与输入图像之间不对齐（尤其是当姿态复杂的时候），而且这些错误通常是无法通过后续优化(e.g. ICON, ECON)完全修复的。此外，这些工作通常不学习 appearance，即使学习了 joint of geometry and appearances，appearances 预测会很 blurry（尤其在遮挡部分）
  - 同时，之前有大量基于 NeRF 的工作（我们知道 NeRF 同时学习了 geometry 和 appearance），但基本上是 overfit 单个场景而无法泛化。最近有 feed-forward NeRF prediction models(e.g. Large Reconstruction Model, LRM)提供了从任意单个图像输入泛化到 3D 重建的能力，但直接应用到人体上效果不佳(even with fine-tuning)，尤其是遮挡部分会 collapse 并且 blurry
- 这篇文章就基于此提出了一个 human 特化的 LRM，它的 insight 在于：diffusion models 可以为遮挡部分生成高质量的 novel view hallucinations，而 3D reconstruction 可以提供强大的 geometry 和 color 先验来确保 diffusion model 的 multi-view 一致性
- 作者的方法分为三个阶段：
  + 使用 enhanced LRM 来预测 single view NeRF，捕捉人体的 coarse geometry and color，但缺乏细节
  + 使用 novel-view guided reconstruction 来提高人体的整体质量。具体来说，利用 diffusion model 的生成能力来幻化生成人体的高分辨率新视角，把第一阶段包含 geometry and appearance 信息的输出作为条件，来确保前向扩散时的 multi-view consistency
  + 最后，新视图生成用来指导更高质量的 geometry 和 appearance 预测。由于作者的方法不需要 human template，可以很容易地通过加入多视角人体数据集来 scale up。此外，与现有的 deterministic 方式预测 appearance 不同，Human-LRM 利用了 diffusion model 的生成能力来实现更高质量的重建
- 作者总结的贡献：
  + 提出了 Human-LRM，一个 feed-forward model，可以从单个图像重建出高质量人体 geometry 和 appearance。Human-LRM 在一个可扩展的包含多视角 RGB 图像和 3D 扫描的数据集上训练，泛化能力很强
  + 提出了 conditional diffusion model，用来生成高分辨率的、饱含细节的新视角图像，有效地指导了最终重建。从 single-view LRM 得到的渲染图像作为空间条件，提供 geometry 和 appearance 先验；额外的 reference networks 有助于保持人物的标识
  + 在广泛的数据集上与过往方法进行对比实验，证明 Human-LRM 全面优于过往方法

== Related Work
- *Parametric reconstruction*。许多 3D 人体重建工作基于 mesh-based 的参数化人体模型(e.g. SMPL)，也可以称作 Human Mesh Recovery(HMR)。这些方法通过神经网络从输入图像预测 SMPL 的 shape 和 pose 参数，从而构建目标人体 mesh。这种 SMPL-conditioned 方法大大降低了网络输出的复杂度，也可以适应弱监督训练比如用 2D 姿态估计通过可微分的 mesh 光栅化来训练。由于 SMPL 建模的是 minimally-clothed 的、具有固定 topology 的平滑 mesh 的人体，因此难以重建详细的 geometry 和 texture，但它捕捉了 base body shape 并描绘了其 pose structure，所以预测出的 SMPL mesh 可以作为 fully clothed reconstruction 的代理（提供 guidance, prior）。HMR 的前景激励了后续的工作来预测 3D offsets 或在 base body mesh 上构建另一层 geometry 来适应 clothed human shapes（但这种 "body+offset" 策略还是缺乏灵活性，难以表示各种各样服装类型）
- *Implicit reconstruction*。Implicit-functions 提供了一种 topology-agnostic 的人体建模表示。PiFU 定义了一个 Pixel-Aligned Implicit Function，对预定义 grid 中的采样来的每个 3D 点，用 FCN 抽取 pixel-aligned 图像特征，用相机内外参算投影位置，预测 3D occupancy 和颜色值。在此基础上，PIFuHD 开发了一个高分辨率模块来预测几何和纹理细节，并用额外的前后法向量作为输入。这些模型对简单的输入（e.g. 干净背景下的站立人体）重建效果不错，但它们无法很好地泛化到野外场景，且通常在 challenging poses and lightings 下产生 broken and messy 的形状，这是由于其有限的模型容量和缺乏整体表示。
- *Hybrid reconstruction*。一些新兴方法把 parametric 方法和 implicit reconstruction methods 结合在一起来改进泛化性。ICON 以给定图像和估计的 SMPL mesh 为起点，从局部查询的特征中回归出形状以泛化到 unseen poses，基于此有工作用 GAN-based generative component 进一步拓展。ICON 原班人马又推出 #link("http://crd2333.github.io/note/Reading/Sparse%20view%20Reconstruction/ICON%20&%20ECON")[ECON]，利用 variational normal integration 和形状补全来保留松散衣物的细节。D-IF 通过自适应的不确定性分布函数额外建模了占用的不确定性。GTA 使用 hybrid prior fusion 策略(3D spatial and SMPL prior-enhanced features)。SIFU 进一步使用 side-view conditioned features 增强 3D 特征。所有这些方法都利用了 SMPL 先验，尽管确实增强了对 large poses 的泛化性，但也受到 SMPL 预测准确性的限制（估计出的 SMPL 参数的错误会对后续 mesh 重建阶段有连锁效应）
- *Human NeRFs*（这篇论文应该是把 NeRF 从 Implicit Representation 里单独摘出来了）。NeRF 仅从 2D 观察中学习对象的 3D 表示，标志着 3D 重建的一个重要里程碑。一些工作专注于重建 human NeRF，但通常集中在 fine-tuning 单个视频或图像这种设置上，计算时间长（几十分钟到几小时）且无法泛化。相比之下，这篇文章的重点在于用 feed-forward 范式（几秒钟内）出图。最近一些工作也采用 feed-forward 范式来实现泛化性，利用 SMPL 作为几何先验，并从 sparse observations 中聚合特征（换句话说，需要多视图）。有一项更相关的工作(#link("http://crd2333.github.io/note/Reading/Sparse%20view%20Reconstruction/SHERF")[SHERF])进一步考虑了只用单个图像，但依赖于 ground truth SMPL body meshes，限制了模型表示能力
  - 而这篇文章的方法是完全 template-free 的，使得 NeRF-based 人体重建更适用和实用
- *Diffusion-based novel view synthesis*。最近很多工作利用了扩散模型来进行新视图合成，但在 geometry 和 colors 上保持 multi-view consistency 仍是一个挑战。为此 Zero123++ 利用 reference attention 来保留输入图像来的全局信息。SSDNeRF, Viewset Diffusion 和 SyncDreamer 建模了多视图图像的联合概率分布。GNVS 和 ReconFusion 利用预测出的 3D latent or renderings 作为扩散模型的条件。这篇文章使用 NeRF 预测渲染出的 geometry 和 appearance、从输入图像来的全局信息、triplane features 来确保多视图一致性。与只做了新视图合成的工作(GNVS, Zero-1-to-3, Zero123++)相比，这篇文章还重建了 geometry；与 ReconFusion 不同，这篇文章的方法采用 feed-forward 范式

== Method
#fig("/public/assets/Reading/Human/2024-11-24-19-22-40.png")
- Human-LRM 主要分成 $3$ 个阶段
  + Stage I: 在 LRM 的基础上搭建，由两个模块构成 —— transformer-based triplane decoder 和 triplane NeRF
  + Stage II: 用特定的 diffusion model，从 triplane NeRF 渲染出的粗糙图像，在一些 condition 下生成高精度的、密集的、新视角下的人体
  + Stage III: 用上一个阶段产生的具有高质量 geometry 和 texture 的密集视图重建人体

=== Single-view Triplane Decoder
- 这里看起来跟 GTA 挺像的，不过作者说是基于 LRM 搭建的，有时间去看一下后者
- 对输入图像 $I_1 in RR^(H times W times 3)$，先训练一个 ViT encoder $bold(ep)$，把图像编码成 patch-wise feature tokens ${bh_i in RR^768}_(i=1)^n$ #h(1fr)
  $ {bh_i}_(i=1)^n = bold(ep) (I_1) $
- 基于这些 tokens 和 camera features $bc$，训练一个 decoder $cD$ 得到三平面表示
  $ bT_(X Y),bT_(Y Z),bT_(X Z) = cD({bh_i}_(i=1)^n,bc) $

=== Triplane NeRF
- 相比传统 NeRF 预测 density + color，这里预测 SDF + color（类似 NeuS），如图里两个 SDF MLP 和 RGB MLP #h(1fr)
  $
  (bh_p,SDF) = MLP_SDF (bT_(X Y),bT_(Y Z),bT_(X Z)) \
  RGB = MLP_RGB (bT_(X Y),bT_(Y Z),bT_(X Z), bh_p, hat(n)_p)
  $
- 然后体渲染的公式也因此略微变化
  $ I(br) = sumiM al_i Pi_(i>j) (1-al_j) RGB_i, ~~~ al_i = 1 - e^(-si_i de_i) $
  - 其中 $si_i$ 是从 SDF 转化来的 density（使用 VolSDF 的技术），$de_i$ 是 ray 上样本点之间的距离
- 这样就渲染出一张新图片了，到这里为止是 Human-LRM 的第一阶段，如果只看 geometry 不管 texture 的话，到这里已经和 TGA, SIFU 打平甚至更好了

=== Diffusion-Based Novel View Generations


=== Novel-View Guided Feed-Forward Reconstruction


