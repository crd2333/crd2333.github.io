---
order: 7
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Sparse view Reconstruction -- Human",
  lang: "zh",
)

#let SQ = math.text("SQ")
#let IF = math.text("IF")
#let PQ = math.text("PQ")
#let SDF = math.text("SDF")
#let Prior = math.text("Prior")
#let DR = $cal(D R)$

= GTA: Global-correlated 3D-decoupling Transformer for Clothed Avatar Reconstruction
- 先来看 SIFU 的前置工作（名字取得很好x），时间是 2023.9
- 杨易老师实验室的学长的工作

== Insights
- 以往工作的缺陷
  + *对 2D 图像特征的过度依赖*。仅仅依赖于 CNN-based 的 2D 特征提取缺乏全局相关性，不过大多数方法会去尝试融合 SMPL 的 3D 特征，但在处理宽松衣物和具有挑战性的姿势时，表现参差不齐，暴露出整合程度上的不足（比较典型比如 PIFu, PaMIR 这些，PIFuHD, ICON, ECON 用的 normal depth 虽然意义比较明确，但也可以看作是 2D 图像特征）。另外，像 ECON 那样一定程度上 optimization-based 的方法可能变得复杂且易于出错
  + *查询方法的不一致性*。目前的查询特征策略各有优劣。pixel-align 的方法 (e.g. PIFu, PIFuHD) 直接将查询点投影到特征图上，缺乏对人体先验的考虑（global 信息不够）。而 prior-guided strategy (point-level, e.g. SHERF) 虽然在 SMPL 顶点上整合特征，却导致了原始图像中细节信息的丢失
    - 个人感觉，对比 SHERF 采用了 hierarchical 的策略提取，GTA 可以理解为把 SHERF 的 global-level 和 point-level 合称为 Prior-enhanced Query，把 pixel-aligned 称为 Spatial Query
- 从前面分析来看，单纯 2D 特征图远远不够，需要“全局相关的 3D 特征表示”。但是，传统三维表示通常需要大量存储空间且处理效率低下。那，基于最近 Representation 的发展，很自然地就有两条路 —— 基于 NeRF 以及它的改版；基于 3DGS
- 而这篇文章就是以 NeRF 往 explicit 方向的改进工作 EG3D 的三平面模型为基础，进一步提出通过 learnable embeddings 和 cross-attention mechanisms 来有效地模拟复杂的跨平面关系（分为 global-correlated ViT encoder 和 3D-decoupling decoder）；然后，基于这种特征抽取方法，进一步提出要巧妙利用 spatial localization 和 SMPL prior
  - 也就是说，先 image encoder 提取出正平面信息，然后用 learnable embeddings 连学带猜得到三个正交平面的信息（先初步地解耦出 3D 空间信息），然后进一步融合 SMPL 把信息填充到整个空间（跟 ECON 那种一步步来，先攻克重难点再解决剩余问题的思路有异曲同工之妙）
  - 而且用 Transformer 来做全局特征提取感觉挺妙的，Attention 相对 Convolution 天生就有提取相关性的能力
  - 疑问：但是感觉这里加入信息不够多啊？没有直接在这里加入 SMPL 先验，单单从 2D image 不见得能很好得学出三个平面的特征吧？

== 具体方法
#fig("/public/assets/Reading/Human/2024-11-18-22-02-31.png")
- *Global-correlated 3D-decoupling Transformer*:
  - 把 image $I$ 的平面记作 xy-plane，从 2D 提取 3D 信息想想就难，需要额外指导信息。之前看的方法都是加先验 (SMPL, normal depth)，而这里的想法是，可以让模型学到脑子里 (embeddings)，用 cross-attention 来提取，自己指导自己。具体分为几个模块：
  - *Global-correlated Encoder*，很标准的 ViT，把图像拆成不重合的 $n times n$ patches，送入网络得到 latent $bh$
  - *3D-decoupling Decoder*，xy-plane 直接 self-attention 就好了，而与其正交的 xz-plane, yz-plane 用 cross-attention（embedding $bz$ 做 query，$bh$ 做 key and value），这样产生三个 feature map
    $
    "CrossAttn"(bz,bh) = "Softmax"(frac(W^Q "SelfAttn"(bz)(W^K bh)^T,sqrt(t))) (W^V bh) \
    F_xy in RR^(H times W times C), F_yz in RR^(H times W times C), F_xz in RR^(H times W times C)
    $
  - *Principle-plane Refinement*，xy-plane 的质量是最关键的，这里对 xy-plane 的特征图做加强（提高分辨率），把原始图像降采样然后和刚才提取的特征 concate，送入 Hourglass 网络，然后再超采样，得到
    $
    F_xy^"refine" = "SuperRes"("Hourglass"("DownConv"(I) plus.circle F_xy)) in RR^(2H times 2W times 2C)
    $
  - *Tri-plane Division*，在 channel 维度把每个特征图都分开，用于后续特征融合，一个用来做 spatial query（相当于 pixel-aligned），一个用来做 prior-enhanced query（相当于做 point-level）
- *Hybrid Prior Fusion Strategy*:
  - *Spatial Query* (pixel-aligned)，把空间中 3D 点投影到三平面，通过加和与 concate 合成（为什么不都 concate 呢？可能实验效果？）
    $ F^SQ (bx) = F_xy^SQ (bx) plus.circle (F_yz^SQ (bx) + F_xz^SQ (bx)) $
  - *Prior-enhanced Query* (point-level)，把 SMPL body mesh 的顶点投影到三平面上并像上面一样融合，把它存储在每个顶点里面。然后对于每个 3D query point，找到它在空间中最近的三角面片，利用重心坐标插值得到特征
    $ R^PQ (bx) = u F^PQ (bv_0) + v F^PQ (bv_1) + w F^PQ (bv_2) $
  - *Hybrid Prior Fusion Strategy*，接下来就是把特征 concate 起来送入 MLP 了，然后可能因为继承 ICON, ECON 的代码，又加了个相对 SMPL body mesh 的 SDF $SDF_Prior (bx)$ 和 pixel-aligned normal feature $F_cN (bx)$ 模块进去。最终预测 occupancy 得到 human surface
  - 最终重建出来的表面可以表示成
    - 也就是任给一个 3D 点，预测它的 occupancy 和 color，令 occupancy $o=0.5$
    $ cS_IF = {bx in RR^3 | IF(F^SQ (bx), F^PQ (bx), SDF_Prior (bx), F_cN (bx)) = (o, bc)} $
  - 如果需要 mesh 的话，从 occupancy 到 mesh 用经典的 Marching Cube 就可以
- 最后就是说各种指标上都超越了之前的 SOTA (ECON)。以及 GTA 可以应用于动画（用估计的 SMPL 参数去提取 tri-plane 特征）、虚拟试穿（替换 parts of SMPL body 的 feature）

= SIFU: Side-view Conditioned Implicit Function for Real-world Usable Clothed Human Reconstruction
- 时间：2023.12
- 参考 #link("https://mp.weixin.qq.com/s/ZZ5Fu4pjiRRMP5qI8IZyDA")[几何纹理重建新SOTA！浙大提出SIFU：单图即可重建高质量3D人体模型]

== Abstract & Introduction
- Abstract
  - 单张图片重建 3D 人体模型很重要但很难，尤其是在复杂姿势和宽松衣物，以及预测遮挡区域的纹理的情况下，最重要的原因就是 2D 到 3D 特征转换时和纹理预测时不充分的先验指导
  - 所以 SIFU 提出了 Side-view Decoupling Transformer 和 3D Consistent Texture Refinement pipeline
    - SIFU 用 cross-attention 机制，使用 SMPL-X 的法向图作为查询，在 2D 到 3D 特征转换时有效地解耦了侧视图特征。这种方法不仅提高了 3D 模型的精度，还提高了鲁棒性（尤其是当 SMPL-X 估计不完美时）
    - 而 texture refinement 利用了 text-to-image 扩散模型的先验，为遮挡视图生成逼真且一致的纹理
  - 大量实验证明，SIFU 在 geometry 和 texture 方面都超越了 SOTA，鲁棒性强，而且可以扩展到 3D 打印和场景搭建等实际应用
- SIFU 认为，之前的单张图片重建 3D human 的方法的 limitation 在于
  - *Insufficient Prior Guidance in Translating 2D Features to 3D*
    #fig("/public/assets/Reading/Human/2024-11-19-17-41-12.png",width:50%)
    - 从 2D 图像特征到 3D 物体重建通常包括三个主要步骤：(1) 提取 2D 图像特征；(2) 将 2D 特征转换为 3D；(3) 3D 特征用于重建
    - 当前方法通常在第一步和最后一步中添加几何先验 (e.g. SMPL-X)，专注于比如说 normal map prediction, SMPL-guided SDF, volume features 的技术。但是第二步探索的还不够多，只用了一些基础的比如，把 2D feature 投影到 3D points 或者反过来把 3D point 投影到 2D feature 上 (e.g. PIFu, PIFu, PaMIR)，亦或者用固定的 learnable embeddings 生成 3D features (e.g. GTA)
  - *Lack of Texture Prior*
    - 当前方法在 unseen 区域的纹理预测还是不够准（特别是受限于训练数据，难以 scale up 让模型学会足够强的脑补能力），所以考虑加入更多的 texture 先验
  - 因此 SIFU 就提出了两种 refined strategies：
    + 使用 cross-attention mechanism 融合 SMPL-X prior
    + 使用预训练扩散模型的强大生成能力来提高纹理预测，也就是引入了 texture prior
- 总之，SIFU 的贡献大体在于
  + 提出了 Side-view Conditioned Implicit Function，巧妙地将 2D 图像特征转换为 3D 特征，在此过程中引入了 SMPL-X 的先验指导
    - 用了 SMPL 先验的工作有很多，但 SIFU 是第一个把 side-view 3D feature 从 input image 中解耦出来的，显著推进了 clothed human reconstruction 领域
  + 提出了 3D Consistent Texture Refinement pipeline，在 clothed human meshes 上生成逼真的、一致的 3D 纹理
  + 在 geometry 和 Texture 重建方面均取得 SOTA，为 3D 打印和场景搭建等实际应用提供了可能性

== Method
#fig("/public/assets/Reading/Human/2024-11-19-20-09-09.png")
- 模型运行可分为两个阶段
  + 第一阶段借助侧隐式函数重建人体的几何(mesh)与粗糙的纹理(coarse texture)
  + 第二阶段则借助预训练的扩散模型对纹理进行精细化

=== Side-view Conditioned Implicit Function
- 这个第一阶段感觉就是 GTA 改了一下，也是一个能够 Decoupling 的 Transformer 和一个 Hybrid Prior Fusion Strategy，去掉了 tri-plane 的表示，改成用 side-view 四个视图来表示
- *Side-view Decoupling Transformer*
  - 首先是跟 GTA 一样还是先用 ViT 提取全局特征
  - 然后用 cross-attention 解耦出 3D 特征，这里就稍微有点不同了
    - GTA 是用 learnable embeddings 作为 query，把 yz-plane 和 xz-plane 的特征学出来，而 SIFU 是用 SMPL-X（来自 PIXIE）渲染出的三个侧面法向图作为 query，从而解耦出三个侧面的特征
      - 这个 side-view 的解耦就对应了 insight 里面所说的 2D feature to 3D feature 转换中的 prior 引入
      - 同时也解答了我在 GTA 那里，觉得 Global-correlated 3D-decoupling Transformer 部分没有用 SMPL 先验的问题
    - 具体做法还是很像，正面自己做 self-attention，三个侧面 (left, right, back) 做 cross-attention
- *Hybrid Prior Fusion Strategy*
  - 这里跟 GTA 几乎差不多，首先把四个视图的信息融合起来 (pixel-aligned)
    $ F^S (bx) = F^S_f plus.circle "avg"(F^S_l (bx),F^S_l (bx),F^S_b (bx),F^S_r (bx)) $
  - 加上 SMPL 的信息 (point-level)
    $ F^P (bx) = u F^S (bv_0) + v F^S (bv_0) + w F^S (bv_0) $
  - 连带着相对 SMPL body mesh 的 SDF $SDF(bx)$ 和 pixel-aligned normal feature $F^cN (bx)$，送入 MLP，预测 occupancy 和 color
    $ (o,bc) = MLP(F^S (bx), F^P (bx), SDF(bx), F^cN (bx)) $
  - 最后再用 Marching Cube 就得到具有粗糙 texture 的 mesh

=== 3D Consistent Texture Refinement
- 到这里为止，跟 GTA 的差异不算太大，我感觉效果应该不会好太多
  - 还是老生常谈的问题，此时的纹理会显得比较粗糙，尤其是看不见的区域会很光滑
  - 于是，就考虑用 pre-trained diffusion model 中包含的知识，用文生图来生成更好的纹理。而且顺带的好处是，可以用文本指导来进行 texture 的替换（换衣）
  - 不过需要注意的问题是生成结果需要满足 3D Consistency，而不是说每个视角各管各的就好了
  #q[修正：但从实验结果上来看，此时的 SIFU 已经比 GTA 强了很多，反而是 texture refinement 部分的改进从定量的数值上看改进不大（除了 LPIPS 改进略多一点），难以理解……作者解释说，可能是 geometry 和 color 的预测比较好，但感觉说了跟没说一样]
- *Pipeline*
  - 首先输入是 input image 和重建出的 coarse mesh $M$，用 image-to-text models (e.g. GPT-4v) 生成文本描述，加上 "the back side of" 的修饰记作 $P$，用于之后扩散模型；然后用这篇论文 #link("https://arxiv.org/abs/2309.16653")[DreamGaussian: Generative Gaussian Splatting for Efficient 3D Content Creation] 的方法，把 mesh 转化成 uv texture map $T$
  - 使用可微渲染器 differentiable renderer $DR$ (visualize unseen areas) 把 $bk={k^1, k^2, dots, k^n}$ 个相机视角下的 mesh 图片渲染成图像 $bI={I^1,I^2,dots,I^n}$
    $ bI=DR(T,M,bk) $
  - 用一个预训练并且冻住了的 text-to-image diffusion model $bold(ep)_bold(th)$，基于条件 $P$ 把 $bI$ refine 成 $bJ={J^1,J^2,dots,J^n}$
    - 为了保持 3D 一致性，用了一个 consistent editing 技术 $cH$
    - 在 $P$ 的指导下，$bold(ep)_bold(th)$ 给 $bJ$ 生成了跟 input image 相吻合的纹理，弥补了背部不可见区域纹理的不足
    $ bJ=cH(bold(ep)_bold(th),P,bI) $
  - 这样，我们就可以用 $bJ$ 与 $bI$ 和 $bJ$ 与 input image 之间的差异，来优化纹理图 $T$
  - 这个表示 appearance 的纹理图和表示 geometry 的 mesh 一起，就正正好好是图形渲染管线所需要的输入了
- *Consistent Editing*
  - 使用来自 #link("https://arxiv.org/abs/2307.10373")[TokenFlow: Consistent Diffusion Features for Consistent Video Editing] 的方法，强制保持所有渲染视图在 diffusion features 中的一致性
  - 对 input image 进行 #link("https://arxiv.org/abs/2010.02502")[DDIM] 逆变换，提取所有层的 diffusion tokens
  - 选择一组 key-views ${J^i}_(i in κ)$ 进行 joint editing，确保结果特征中的外观相统一，然后这些特征通过最近邻方法传播到所有 views，以保持它们之间的一致性
  - （还不太熟悉 Diffusion Model，不是非常清楚这里在干什么

== Experiments & Conclusion
- 实验部分
  - 首先是说各种指标和各种数据集上的重建精度都超越了之前的模型 (PIFu, PIFuHD, ARCH, PaMIR, ICON, ECON, D-IF, GTA)，达到新的 SOTA
  - 然后是说对 HPS 预测出的 SMPL-X 不准的情况，SIFU 具有一定的鲁棒性（特征提取和先验融合做得比较好？），具有实用价值
- 消融实验
  - Different Backbone Analysis: 对比了不用 cross-attention，用 learnable embeddings，用 CNN 三种情况，证明特征提取和转化那里的设计是有效的
  - Different Feature Plane Analysis
    - 这里也解答了我之前的疑问：GTA 是用三个正交平面，这里的话是前后左右四个视图，我当时在想为什么不做得绝一点，把人体头顶和脚底板（上下视图）也给它学了，做成一整个包围盒呢？
    - 这里做实验发现 left, right side-view 相对比较有效，考虑到增加视角对效果和计算量的影响，最终选择了四个视角的 balance
  - Query Strategy Efficacy: 对比 PIFu, PIFuHD 那样只有 pixel-aligned 的方法，hybrid 方法表现更好
  - Different Texture Refinement: 比较用其它方法做 refinement 和不做的效果，证明 SIFU 的方法在质量和一致性上都更有优势
- 应用
  - Texture Editing: 很自然的，不用 image-to-text 的文本，而是另外指定，就可以实现 texture editing
  - Scene Building and 3D Printing: 重建效果和鲁棒性好到一定程度就可以拿来做场景搭建和 3D 打印了
- Limitations
  + 常见问题，HPS 估计不准会影响重建精度（即使有一定鲁棒性）
  + 常见问题，对宽松衣物（衣服和身体明显分开）的效果不好
  + 从图像到文本再 Diffusion Model 的过程，可能会丢失一些细节，影响纹理的质量（为此已经用了 GPT-4v 来尽量生成准确详细的描述了，但可能还是有点割裂，或许可以考虑更直接的方法）
- Future Work，除了克服以上局限性以外
  + 最近一些研究证明了扩散模型在学习丰富的 3D prior 方面的潜力，有可能使用 Diffusion Model 同时进行 geometry 和 texture 的预测。一个重要的挑战在于有效地将基于图像的 visual prompt 与扩散过程相结合，同时也减少 finetuning 所需的时间
  + 此外，对人体的不同部分（头发、脸部和手部）采用不同的技术，可能会产生更好的结果
- Broader Impact，可能的负面社会影响云云

== 论文十问
+ 论文试图解决什么问题？
  - 以往的 3D human reconstruction 方法在特征转换和纹理预测时，不充分的先验指导
+ 这是否是一个新的问题？
  - 3D human reconstruction from single image 是一个很经典的问题，之前的 PIFu, PIFuHD, ARCH, PaMIR, ICON, ECON, D-IF, GTA 等很多
+ 这篇文章要验证一个什么科学假设？
  - 通过引入 SMPL-X 的先验指导，可以在 2D 到 3D 特征转换时有效地解耦出 side-view 的 3D 特征，提高 3D human reconstruction 的精度和鲁棒性
  - 通过引入预训练的扩散模型，可以提高纹理预测的质量和一致性
+ 有哪些相关研究？如何归类？谁是这一课题在领域内值得关注的研究员？
  - 研究员之前写过，这里不写了。研究归类之后另外总结一下
+ 论文中提到的解决方案之关键是什么？
  - 通过 cross-attention 机制，使用 SMPL-X 的法向图作为查询，在 2D 到 3D 特征转换时有效地解耦了侧视图特征
  - 使用预训练扩散模型的强大生成能力来提高纹理预测
+ 论文中的实验是如何设计的？
  - 跟之前模型的对比和消融实验
+ 用于定量评估的数据集是什么？代码有没有开源？
  - THuman2.0, CAPE，代码开源在 #link("https://github.com/River-Zhang/SIFU")[github/River-Zhang/SIFU]
+ 论文中的实验及结果有没有很好地支持需要验证的科学假设？
  - 有，模型超越了之前的 SOTA，对 HPS 预测不准的情况具有一定的鲁棒性
+ 这篇论文到底有什么贡献？
  - 提出了 Side-view Conditioned Implicit Function，巧妙地将 2D 图像特征转换为 3D 特征，并在此过程中引入了 SMPL-X 的先验指导
  - 提出了 3D Consistent Texture Refinement pipeline，在 clothed human meshes 上生成逼真的、一致的 3D 纹理
+ 下一步呢？有什么工作可以继续深入？
  - 克服局限性，同时尝试将 geometry 和 texture 的预测结合起来，减少 finetuning 所需的时间
