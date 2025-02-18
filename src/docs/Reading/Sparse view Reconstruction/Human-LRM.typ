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
- 作者提出了 diffusion-guided 前向模型 Human-LRM，从单个图像预测人体的 implicit field。Human-LRM 结合了 SOTA 重建模型 LRM 和生成模型 Stable Diffusion，可以在没有任何模板先验 (e.g. SMPL) 的情况下捕捉人体，并有效地生成真实细节去丰富遮挡部分
- 作者的方法首先使用 single-view LRM 模型结合 enhanced geometry decoder 来获得 triplane NeRF 表示。然后从 triplane NeRF 渲染出的新视图提供 geometry 和 color 先验，让 diffusion model 为遮挡部分生成真实细节。生成的多视图使得重建具有高质量的 geometry 和 appearance，成了新 SOTA

== Introduction
- 从 single image 重建 3D 人体是 CV 领域的重要研究方向，有着广泛的应用 (AR/VR、asset creation、relighting .etc) 和海量各有优劣的方法
  - Parametric reconstruction methods，或者说 human mesh recovery (HMR)，通过回归 SMPL 的 pose 和 shape 参数来重建人体，但不包括衣物细节
  - implicit volume reconstruction methods 利用 pixel-aligned 特征捕捉衣物细节，但不能泛化到各种姿态
  - 最近的 hybrid 方法（这里的 hybrid 特指 explicit 中的 parametric 方法和 implicit 方法的混合）使用预测的 SMPL mesh 作为条件来指导 full clothed 重建。然而这些 SMPL-conditioned 方法面临不可避免的局限性：SMPL 预测误差会累计，导致重建出的网格与输入图像之间不对齐（尤其是当姿态复杂的时候），而且这些错误通常是无法通过后续优化 (e.g. ICON, ECON) 完全修复的。此外，这些工作通常不学习 appearance，即使学习了也会很 blurry（尤其在遮挡部分）
  - 同时，之前有大量基于 NeRF 的工作（我们知道 NeRF 同时学习了 geometry 和 appearance），但基本上是 overfit 单个场景而无法泛化。最近有 feed-forward NeRF prediction models (e.g. Large Reconstruction Model, LRM) 提供了从任意单个图像输入泛化到 3D 重建的能力，但直接应用到人体上效果不佳 (even with fine-tuning)，尤其是遮挡部分会 collapse 并且 blurry
- 这篇文章就基于此提出了一个 human 特化的 LRM，它的 insight 在于：diffusion models 可以为遮挡部分生成高质量的 novel view hallucinations，而 3D reconstruction 可以提供强大的 geometry 和 color 先验来确保 diffusion model 的 multi-view 一致性
- 作者的方法分为三个阶段：
  + 使用 enhanced LRM 来预测 single view NeRF，捕捉人体的 coarse geometry and color，但缺乏细节
  + 使用 novel-view guided reconstruction 来提高人体的整体质量。具体来说，利用 diffusion model 的生成能力来幻化生成高分辨率的人体新视图，把第一阶段包含 geometry and appearance 信息的输出作为条件，来确保前向扩散时的 multi-view consistency
  + 最后，新视图生成用来指导更高质量的 geometry 和 appearance 预测
  - 由于作者的方法不需要 human template，可以很容易地通过加入多视角人体数据集来 scale up，从而提高泛化性能
    - 这句话不太理解，template-based 跟不能利用多视角数据有什么关系？
  - 此外，与现有的 deterministic 方式预测 appearance 不同，Human-LRM 利用了 diffusion model 的生成能力来实现更高质量的重建
- 作者总结的贡献：
  + 提出了 Human-LRM，一个 feed-forward model，可以从单个图像重建出高质量人体 geometry 和 appearance。Human-LRM 在一个可扩展的包含多视角 RGB 图像和 3D 扫描的数据集上训练，泛化能力很强
  + 提出了 conditional diffusion model，用来生成高分辨率的、饱含细节的新视角图像，有效地指导了最终重建。从 single-view LRM 得到的渲染图像作为空间条件，提供 geometry 和 appearance 先验；额外的 reference networks 有助于保持人物的标识
  + 在广泛的数据集上与过往方法进行对比实验，证明 Human-LRM 全面优于过往方法

== Related Work
- *Parametric reconstruction*
  - 许多 3D 人体重建工作基于 mesh-based 的参数化人体模型 (e.g. SMPL)，也可以称作 Human Mesh Recovery (HMR)。这些方法通过神经网络从输入图像预测 SMPL 的 shape 和 pose 参数，从而构建目标人体 mesh
  - SMPL-conditioned 方法大大降低了网络输出的复杂度，也可以适应弱监督训练，比如用 2D 姿态估计通过可微分的 mesh 光栅化来训练
  - 由于 SMPL 建模的是 minimally-clothed 的、具有固定 topology 的平滑 mesh 的人体，因此难以重建详细的 geometry 和 texture，但它捕捉了 base body shape 并描绘了其 pose structure，所以预测出的 SMPL mesh 可以作为 fully clothed reconstruction 的代理（提供 guidance, prior）
  - HMR 的前景激励了后续的工作来预测 3D offsets 或在 base body mesh 上构建另一层 geometry 来适应 clothed human shapes（但这种 "body+offset" 策略还是缺乏灵活性，难以表示各种各样服装类型）
- *Implicit reconstruction*
  - Implicit-functions 提供了一种 topology-agnostic 的人体建模表示
    - PiFU 定义了一个 Pixel-Aligned Implicit Function，对预定义 grid 中的采样来的每个 3D 点，用 FCN 抽取 pixel-aligned 图像特征，用相机内外参算投影位置，预测 3D occupancy 和颜色值
    - 在此基础上，PIFuHD 开发了一个高分辨率模块来预测几何和纹理细节，并用额外的前后法向量作为输入
  - 这些模型对简单的输入（e.g. 干净背景下的站立人体）重建效果不错，但它们无法很好地泛化到野外场景，且通常在 challenging poses and lightings 下产生 broken and messy 的形状，这是由于其有限的模型容量和缺乏整体表示
- *Hybrid reconstruction*
  - 一些新兴方法把 parametric 方法和 implicit reconstruction methods 结合在一起来改进泛化性
    - ICON 以给定图像和估计的 SMPL mesh 为起点，从局部查询的特征中回归出形状以泛化到 unseen poses，基于此有工作用 GAN-based generative component 进一步拓展
    - ICON 原班人马又推出 #link("http://crd2333.github.io/note/Reading/Sparse%20view%20Reconstruction/ICON%20&%20ECON")[ECON]，利用 variational normal integration 和形状补全来保留松散衣物的细节
    - D-IF 通过自适应的不确定性分布函数额外建模了 occupancy 的不确定性
    - GTA 使用 hybrid prior fusion 策略(3D spatial and SMPL prior-enhanced features)
    - SIFU 进一步使用 side-view conditioned features 增强 3D 特征
  - 所有这些方法都利用了 SMPL 先验，尽管确实增强了对 large poses 的泛化性，但也受到 SMPL 预测准确性的限制（估计出的 SMPL 参数的错误会对后续 mesh 重建阶段有连锁效应）
- *Human NeRFs*（这篇论文把 NeRF 从 Implicit Representation 里单独摘出来了）
  - NeRF 仅从 2D 观察中学习对象的 3D 表示，标志着 3D 重建的一个重要里程碑。一些工作专注于重建 human NeRF，但通常集中在 fine-tuning 单个视频或图像这种设置上，计算时间长（几十分钟到几小时）且无法泛化
    - 相比之下，这篇文章的重点在于用 feed-forward 范式（几秒钟内）出图
  - 最近一些工作也采用 NeRF + feed-forward 范式来实现泛化性，利用 SMPL 作为几何先验，并从 sparse observations 中聚合特征（换句话说，需要多视图）
    - 有一项更相关的工作 (#link("http://crd2333.github.io/note/Reading/Sparse%20view%20Reconstruction/SHERF")[SHERF]) 进一步考虑了只用单个图像，但依赖于 ground truth SMPL body meshes，限制了模型表示能力
  - 而本文方法是完全 template-free 的，使得 NeRF-based 人体重建更适用和实用
- *Diffusion-based novel view synthesis*
  - 最近很多工作利用了扩散模型来进行新视图合成，但在 geometry 和 colors 上保持 multi-view consistency 仍是一个挑战
    - 为此 Zero123++ 利用 reference attention 来保留输入图像来的全局信息
    - SSDNeRF, Viewset Diffusion 和 SyncDreamer 建模了多视图图像的联合概率分布
    - GNVS 和 ReconFusion 利用预测出的 3D latent or renderings 作为扩散模型的条件
  - 本文使用 NeRF 预测渲染出的 geometry 和 appearance、从输入图像来的全局信息、triplane features 来确保多视图一致性
    - 与只做了新视图合成的工作 (GNVS, Zero-1-to-3, Zero123++) 相比，这篇文章还重建了 geometry；
    - 与 ReconFusion 不同，本文采用 feed-forward 范式

== Method
#fig("/public/assets/Reading/Human/2024-11-24-19-22-40.png")
#note(caption: "TL;DR")[
  - Human-LRM 主要分成 $3$ 个阶段
    + 一阶段：在 LRM 的基础上搭建，由两个模块构成 —— transformer-based triplane decoder 和 triplane NeRF
    + 二阶段：用特定的 diffusion model，从 triplane NeRF 渲染出的粗糙图像，在一些 condition 下生成高保真度的、密集的、新视角下的人体
    + 三阶段：用上一个阶段产生的具有高质量 geometry 和 texture 的密集视图重建人体
]

=== Single-view Triplane Decoder
- 这里看起来跟 GTA 挺像的，不过作者说是基于 LRM 搭建的，有时间去看一下后者
- 对输入图像 $I_1 in RR^(H times W times 3)$，先训练一个 ViT encoder $bold(ep)$，把图像编码成 patch-wise feature tokens ${bh_i in RR^768}_(i=1)^n$
  $ {bh_i}_(i=1)^n = bold(ep) (I_1) $
- 基于这些 tokens 和 camera features $bc$，训练一个 decoder $cD$ 得到三平面表示
  $ bT_(X Y),bT_(Y Z),bT_(X Z) = cD({bh_i}_(i=1)^n,bc) $

=== Triplane NeRF
- 相比传统 NeRF 预测 density + color，这里预测 SDF + color（类似 NeuS），如图里两个 MLP
  - SDF MLP 输入 point features，输出 SDF 和 atent vectors $bh_p$，并且基于有限差分法 (finite differences) 计算 normals $hat(n)_p$
    $ (bh_p,SDF) = MLP_SDF (bT_(X Y),bT_(Y Z),bT_(X Z)) $
  - RGB MLP 输入 point features, latent vectors $bh_p$ 以及 normals $hat(n)_p$，输出 RGB 值
    $ RGB = MLP_RGB (bT_(X Y),bT_(Y Z),bT_(X Z), bh_p, hat(n)_p) $
- 然后体渲染的公式也因此略微变化
  $ I(br) = sumiM al_i Pi_(i>j) (1-al_j) RGB_i, ~~~ al_i = 1 - e^(-si_i de_i) $
  - 其中 $si_i$ 是从 SDF 转化来的 density（使用 VolSDF 的技术），$de_i$ 是 ray 上样本点之间的距离
  - 基于类似的方法也可以渲染出 normal maps（把积分的对象从预测出的 RGB 换成 normal）和 depth maps（怎么来的没说）
- 训练方法则是挑几个 side views，渲染 image $hat(bx) in RR^(h times w times 3)$, depth maps $hat(bd) in RR^(h times w)$, normal maps $hat(bn) in RR^(h times w)$，最小化以下 loss
  + MSE and LPIPS between $hat(bx), bx$
  + MSE between $hat(bn), bn$; DSI (#link("https://github.com/isl-org/ZoeDepth")[scale invariant depth loss]) between $hat(bd), bd$
    - 真值可以来自 3D scans 的 ground truth 渲染，也可以是 off-the-shelf 工具的预测
  + Eikonal loss 做正则化（来自 #link("https://github.com/amosgropp/IGR")[IGR]）
- 这样就渲染出一张新图片了，到这里为止是 Human-LRM 的第一阶段，如果只看 geometry 不管 texture 的话，到这里已经和 TGA, SIFU 打平甚至更好了（得益于 large scale training）

=== Diffusion-Based Novel View Generations
- Stage I 的结果已经不错了，但在 unseen 区域尤其是背部区域，外观会显得很 blurry。在 Stage II，我们试图利用 Diffusion model，产生高保真度、有现实感的新视图，以指导后续在遮挡区域的重建
- 首先通过 triplane NeRF 渲染出的新视图以及中间结果 (RGB, Depth, Weights) 作为 diffusion model 去噪模型的 condition
  - RGB 和 depth map 为模型提供了新视图的 geometry 和 appearance 先验
  - 而 weights sum（体渲染公式里的那个权重和）作为渲染内容确定性的代理，即为了让 diffusion model 学会幻化出 less certain parts 的细节（希望它更关注的部分）
  - 通过 condition 加入信息就是 diffusion model 那一套方法，论文没有赘述
- 其次作者觉得只通过 condition 加入信息还不够，没能保持 the identity of the person，额外通过 #link("https://github.com/Mikubill/sd-webui-controlnet/discussions/1236")[reference network]
  - 参考 #link("https://zhuanlan.zhihu.com/p/629629227")[一张图替代 LoRa：ControlNet 发布重大更新 Reference Only]、#link("https://robot9.me/referencenet-review/")[ReferenceNet 简介及相关算法整理]，似乎是 ControlNet 相关工作
  - 这样，通过修改 U-Net 的自注意力层，把 key 和 value 都 concat 上 refernce 的对应值，让 denoiser 意识到人物的全局信息
- 于是扩散模型的目标函数为最小化 $cL_Diffusion$
  $
    r_"coarse" = (hat(bx)_v, hat(bd)_v, hat(bw)_v) \
    cL_Diffusion = EE_(t wave [1, T]) norm(v - hat(v)_th (x_v^"noised"; r_"coarse", bx_"input", bT, t))^2
  $
  - 其中 $hat(v)_th$ 是具有参数 $th$ 的 U-Net，执行 $v-"prediction"$，$x_v^"noised"$ 是加噪后的 ground truth view，$bx_"input"$ 是输入图像，$bT$ 是 triplane

=== Novel-View Guided Feed-Forward Reconstruction
- 一旦我们得到了人体在新视图下的生成结果，就可以用相对更成熟、更有效的 multi-view reconstruction model 来重建人体
- 这部分作者直接 "refer readers to #link("https://yiconghong.me/LRM/")[LRM]" 了，本人对这个方向不是很了解，这里就不做展开
  - 作者简单提了一下，通过模块化把 camera conditioning 吸收到 ViT encoder；multi-view 里的 triplane decoder 表征跟本文 single-view 是一样的，只是不包含 camera conditioning（移到 ViT encoder 里了）

== Experiments and Results
- 训练集
  - GTA 和 SIFU 只在 THuman 2.0 差不多 $500$ 个 human scans
  - 而 human-LRM 在此基础上加入了 $926$ 个 Alloy++ 的扫描数据；还有他们内部闭源 (internal) 的数据，跟 RenderPeople（要钱，很贵）质量或者说多边形面数相当；以及来自 HuMMan v1.0 的约 $8,000$ 张 posed multi-view captures
  - 明显数据量上更大了，也符合 LRM 中的 large 特点
- 验证集
  - $20$ humans from THuman 2.0, $20$ humans from Alloy++，每个都在均匀分布的 $3$ 个视角下渲染
  - 此外创建 X-Human 数据集作为 out-of-domain 验证集（每个模型都没有在训练时见过其中的图片）
- 这里着重看一下它的*比较*
  - *Geometry Comparisons*
    - *比较对象为*现存的 single-view 人体重建方法（历代 SOTA），包括 PIFu, PIFu-HD, Pamir, ICON, ECON, D-IF, GTA, SIFU
    - *评测指标*为 Chamfer distance, Point-to-Surface (P2S), Normal Consistency (NC)
    - 对于需要 SMPL 预测的方法，统一使用 PIXIE 的结果。其中 PIFu, PIFu-HD 是不用的，GTA 在第二阶段才引入 SMPL，可以把 SMPL-related feature 重新拿掉训练一个 SMPL-free 版本来提供更有说服力的比较。为了公平的比较且避开 RenderPeople 商业数据集的版权问题，除了 GTA, SIFU 放出的 pre-trained 模型本身就是在 THuman 2.0 上训练，其它方法都进行重新训练（包括他们自己的 Human-LRM）
    - *结果显示*：SMPL-free 的方法哪怕早期如 PIFu 都优于 SMPL-based 方法，SMPL-free GTA 也全面由于 SMPL-based GTA，而其中又以 Human-LRM 的指标最优
    - *评价*：这里就是想说明 SMPL 参数的误差影响非常大，而既然 PIFu 这么老的方法都能上桌，那说明这里 SMPL-free 全面占优的比较其实没什么意义。*但既然拿掉了 SMPL，人体姿态的泛化性势必收到影响*，文章理应对此进行更多讨论，然而却只用两张图片和一句 our method demonstrates exceptional generalizability to challenging cases 带过。与之相比，SIFU 给出了详尽的实验结果；而且细看这两张图，渲染视角和姿势有所不同，*怀疑这里有点问题*（当然，也不排除单纯只是论文写得有瑕疵）
    #fig("/public/assets/Reading/Human/2025-01-24-14-38-10.png", width: 80%)
    #fig("/public/assets/Reading/Human/2025-01-24-14-37-58.png", width: 80%)
  - *Appearance Comparisons*
    - *比较对象*
      - 前面那些方法（重新称为 volumetric methods），包括 PIFu, PIFu-HD, GTA, and SIFU；
        - PIFu-HD 的 color inference module 没有开源
      - 以及 generalizable Human NeRF 方法，包括 NHP, MPS-NeRF, SHERF
        - 这些方法假设 GT SMPL，但在 in-the-wild 环境上显然扯淡，我看 SHERF 的时候也感觉明显就是把 NeRF 生搬硬套到 human 上的论文
        - 因此本文这里用预测出的 SMPL 代替 GT 来进行比较，感觉无可厚非。另外就是，给了 GT 的情况下 Human-LRM 打不过 SHERF，这样也算是一个写作上的技巧吧
    - *评测指标*为 SSIM, PSNR, LPIPS
    - *结果显示*
      - 跟 volumetric methods 相比，定量实验显示出结果好一些，且上面那张三行的图定性地证明外观尤其是遮挡部分表现要好得多（确实好很多，之前看 SIFU 的时候以为做得不错了，这么看来也是选择性展示的结果，单视图重建领域还有很多发展空间）
      - 跟 SHERF 相比，定量实验显示出结果要好非常多。这个 gap 可能来自于 SHERF 严重依赖于跟 SMPL 像素层面对齐的 feature，把 GT 砍成 predicted 就效果大打折扣
  - 附录里面还比较了 Depth and Normal Estimation Methods，这里就不看了
- 此外还有一些消融实验，不看了

We introduced a novel approach for reconstructing human NeRFs from a single image. What sets our approach apart from previous implicit volumetric human reconstruction methods is its remarkable scalability, making it adaptable for training on large and diverse multi-view RGB datasets. Additionally, we proposed a coarse-to-fine reconstruction strategy guided by dense novel generations from a diffusion model. The dense novel views serve a strong geometry and texture guide that effectively enhances the overall quality of the final reconstruction.
- 结论
  - 基于可泛化 NeRF 提出了一种从单幅图像重建人类的新方法，与以前的 implicit volumetric 人体重建方法的不同之处在于 scalability，使其适用于在大型和多样化的多视图 RGB 数据集上进行训练。此外，还提出了一种由扩散模型指导的 coarse-to-fine 重建策略，密集的新视图提供了强大的几何和纹理指导，有效地提高了最终重建的整体质量
  - 不足之处在于脸部和手部的细节还不太好，未来工作可能可以考虑利用比 triplane 更强的表征，或使用额外的 refinement 技巧

== 论文十问
+ 论文试图解决什么问题？
  - 单视图人体重建问题，最关键问题还是效果不好，因为单视图没什么信息，所以要想办法从要么模型本身、要么 SMPL 先验、要么 diffusion model 等地方着手改进质量（template-free 虽然作为标题，但却没有详细叙述其动机，总的来说并不是迫切需要解决的问题）
+ 这是否是一个新的问题？
  - 并非新问题，前面有不少工作
+ 这篇文章要验证一个什么科学假设？
  - 感觉没有一个中心的 idea，主要还是第一数据集扩大，第二用一种比较直接的 coarse-to-fine 方式尝试引入 diffusion model（还是那句话，从论文中看不出 template-free 的优势）
+ 有哪些相关研究？如何归类？谁是这一课题在领域内值得关注的研究员？
  - 略
+ 论文中提到的解决方案之关键是什么？
  - 数据集扩大，尝试引入 diffusion model
+ 论文中的实验是如何设计的？
  - 见上
+ 用于定量评估的数据集是什么？代码有没有开源？
  - 见上。代码的话，project page 似乎挂了，github 上没找着。#strike[斯坦福的博士诶，不至于吧]
+ 论文中的实验及结果有没有很好地支持需要验证的科学假设？
  - 见上
+ 这篇论文到底有什么贡献？
  - 数据集扩大感觉算不上贡献，尝试引入 diffusion model 倒是令人耳目一新
+ 下一步呢？有什么工作可以继续深入？
  - 作者提到了脸部和手部细节不够好，可以考虑用更强的表征或者额外的 refinement 技巧
