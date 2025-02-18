---
order: 8
draft: true
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Sparse view Reconstruction -- Human",
  lang: "zh",
)

#let intra = math.text("intra")
#let inter = math.text("inter")

= HumanSplat: Generalizable Single-Image Human Gaussian Splatting with Structure Priors
- 时间：2024.6.18
- 我的 reading list 里面最早的一篇把 3DGS 引入单视图人体重建的文章，说实话感觉做得已经挺不错了

== Abstract & Introduction & Related Work
- Abstract
  - 尽管最近高保真度人体重建技术发展迅猛，密集拍摄的图像、对每个个体进行优化的耗时过程，这些问题严重限制了更广阔的应用
  - 为了解决这些问题，本文提出了 HumanSplat，用可泛化方式从单张图像预测 3DGS 属性。更具体的说，它由以下部分组成
    + 2D 多视图扩散模型
    + 结合人体结构与语义先验 (SMPL) 的 latent reconstruction Transformer
    + 设计了一个包含人体语义信息的 hierarchical loss，以实现高保真纹理建模，并对估计出的多视图施加更强的约束
  - 基准数据集和野外图像上的全面实验表明 HumanSplat 在新视图合成方面成为新 SOTA
- Introduction
  - 首先就是说显式 (SMPL)、隐式那一套怎么怎么样。然后 3DGS 出现改善了效率和渲染质量的问题；最近一些工作 (e.g. TeCH) 专注于 score distillation sampling (SDS) 技术，试图以此把 2D diffusion priors 提升到 3D，但需要做逐个体的极其耗时的优化；一些 LRM 方法要么忽视了 human priors，要么需要多视角输入，限制了应用场景
  - HumanSplat 相当于把上面这些的思想都融入了进来，利用 SMPL 先验、fine-tuned 多视角扩散模型、可泛化 3DGS 框架，从单张图片预测出 3DGS 属性，而不是做逐个体的优化，赋予模型更有效率地泛化到不同情景的能力
    - 从 high level 的角度，实际上用 data-driven 的泛化思路做单视图人体重建是一个很自然的思路，因为你就只有单视图的一张图片也优化不出什么名堂来，那就只能靠把知识记在模型里面咯，以及从诸如 diffusion, SMPL 引入先验等。难点在于怎么把这些东西 “有机” 地结合起来，同时又利用 3DGS 提高效率（而我们知道 3DGS 这种显式表征其实不太好跟 data-driven 结合）
  - 关键的 insight 用一句话概括：用可泛化的、端到端的架构从 diffusion latent space 中预测 3DGS 属性，用 2D 生成模型作为 appearance 先验，用 SMPL 作为 structure 先验
  - 具体而言，作者总结他们的贡献在于
    + 提出了一个可泛化的 human Gaussian Splatting 网络框架，用于从单张图片中重建高保真度的 3DGS 人体（这是该 setting 下第一个提出利用生成式扩散模型做潜高斯重建的端到端框架的工作）
    + 使用一个统一的 Transformer 框架结合从生成模型来的 appearance 先验和从 SMPL 来的 structure 先验（利用投影策略和 projection-aware attention 在相邻窗口内搜索，减轻 SMPL 不准的限制，在鲁棒性和灵活性中取得平衡）
    + 引入（从 SMPL 来的）语义信息、层次监督和静心设计的损失函数来改善视觉敏感区域（如面部和手部）的精细细节
    + 进行广泛实验证明成为了新 SOTA
- Related works 略，跟我之前看的东西差不多

== Method
#fig("/public/assets/Reading/Human/2025-01-24-15-52-32.png", width:90%)
- 给定一张包含人体的图片（从图里看可能要 segment）$bI_0 in RR^(H times W times 3)$，目的是重建出 3DGS 表示，可以借此实现新视图合成，方法可以分为如下步骤
  + 使用 *SMPL* estimator 预测和引入 Geometry & Semantic Prior $cM$；使用 *CLIP* 生成 image embedding $bc$
  + 使用一个 fine-tuned 潜空间时空扩散模型 (*Novel View Synthesizer*) 生成 $N$ 个视角的 latent features ${bF_i in RR^(h times w times c)}_(i=1)^N$
  + 利用 *latent reconstruction Transformer*，融合 latent features 和 $cM$，生成 $N_p$ 个高斯属性 $bG := {(mu_i, q_i, s_i, c_i, si_i)|i=1,dots,N_p}$
  + 设计了 *hierarchical loss* 来训练网络，实现高保真纹理建模和多视图约束

=== Video Diffusion Model as Novel-view Synthesizer <diffusion>
- *Novel View Synthesizer* 利用预训练的视频扩散模型 #link("https://arxiv.org/abs/2403.12008")[SV3D] 作为 appearance 先验，生成新视图特征
  - condition 来自利用 CLIP image encoder 得到的 image embedding $bc$，以及利用预训练的 VAE $cal(E)$ 得到的 latent feature $bF_0$
  - 网络为 U-Net，来自 #link("https://arxiv.org/abs/2311.15127")[Stable Video Diffusion]（#link("https://blog.csdn.net/qq_45670134/article/details/134643046")[解读参考]）
    - ？到底是来自 SV3D 还是来自 SVD？还是说 SV3D 的架构类似于 SVD？
- 用 U-net $D_th$ 逐次去噪得到时间连续的 $N$ 个多视角 latent features ${bF_i}_(i=1)^N$，目标函数为
  $ EE_(ep wave p(ep)) la(ep) norm(D_th ({bF_i^ep}_(i=1)^N; {e_i,a_i}_(i=1)^N, bc, bF_0, ep) - {bF_i}_(i=1)^N) $
  - 其中 ${bF_i^ep}_(i=1)^N$ 是加噪后的多视角 latent features，${e_i,a_i}_(i=1)^N$ 是对应的高度和方位角（相对 $bI_0$ 的），$p(ep)$ 是噪声概率分布，$la(ep) in RR^+$ 是 lvel $ep$ 对应的噪声损失函数权重项
  - 由于 SV3D 并非针对人体，需要 fine-tune 以适应人体重建任务

=== Latent Reconstruction Transformer
- 分为两个部分：*latent embedding interaction* 和 *geometry-aware interaction*，从而无缝地融合特征，为恢复复杂人体细节做铺垫
- *Latent Embedding Interaction*
  - @diffusion 得到 latent features ${bF_i}_(i=1)^N$，根据以往工作，把它跟 Plücker embeddings 在 channel 维度拼接起来，形成 dense pose-conditioned feature map
  - 用 ViT 的方式把 feature map 拆成 patches，用一个线性层映射到 $d$ 维 latent tokens
  - 然后用 $N_intra$ 个标准 Transformer block 提取它们之间的空间信息，每个 blcok 由多头自注意力和前馈网络组成
    $ macron(bF)_i = [FFN(SelfAttention(bF_i))]_(times N_intra) $
#fig("/public/assets/Reading/Human/2025-01-24-15-52-58.png", width:90%)
- *Geometry-aware Interaction*
  - *Human Geometric Tokenizer*
    - $cM in RR^(6890 times 3)$ 还不是图片以及能更进一步处理的 token，我们把 $cM$ 投影到 input view 并利用双线性插值 (where?) 计算特征向量
      $ oPi_o (cM) = K(R_0 cM + t_0) $
      - 其中 $R_0, t_0$ 是输入视图的相机外参，$K$ 是相机内参
    - 把 $cM$ 和 $bF_0 [oPi_0 (cM)]$ 拼接起来
      - $bF_0 [oPi_0 (cM)]$ 代表在投影点查询 $bF_0$，猜测应该是把 geometry-only SMPL 的投影结果在输入视图中找到对应的 RGB 值，前面说的双线性插值应该是发生在这个时候
        - query 的想法跟 SIFU 有点像，不过 SIFU 是通过 Attention 机制，这里是显式地做（如果我没猜错的话）
      - 拼接应该是指 $(x,y,z)$ with $(R,G,B)$
    - 同样，用一个线性层映射到 $d$ 维 latent tokens，并用 $N_intra$ 个标准 Transformer block 提取集合信息 $oH in RR^(6890 times d)$
  - *Human Geometry-aware Attention*
    - 无论是 ICON & ECON 还是 GTA & SIFU，我们知道，利用 SMPL geometry 先验的工作都面临着 robustness 和 flexibility 的 trade-off，这里作者也提到了这个问题
      - 一方面，SMPL 缓解了人体建模的一些共性问题如 broken body parts and various artifacts；另一方面，又限制了衣物的复杂性（尤其是跟身体偏离较大的），在准确描绘多样服装的模型容量方面存在根本性缺陷
      - 对于这个问题至今没有很好的解决方案：ICON & ECON 基本就直接摆烂了；GTA & SIFU 利用更高效的 cross-attention 机制，也就是更高效地把 2D 图像特征与 3D geometry 特征融合，但说实在的 implicit 方法在这方面解决地并不直接、彻底
      - *我个人认为，3DGS 在这方面有一定优势*，它能显式建模出 “宽松衣服跟身体偏离较远” 这种差别
    - HumanSplat 在这方面是如何做的？如上图所示，它通过把 3D tokens 投影到 2D space，然后在相邻窗口内执行 local searches（即 masked cross-attention）。不仅有效地利用了先验，也减小了冗余（复杂度 $cal(O)(L_F times L_H) -> cal(O)(L_F times K_"win"^2)$）
      $ {tilde(F)_i}_(i=1)^N = [FFN(CrossAttention({macron(bF)_i}_(i=1)^N, oH))]_(times N_inter) $
      - 具体来说，latent features ${macron(F)_i}_(i=1)^N$ 作为 Queries，geometry prior tokens $oH$ 作为 Keys / Values，window 尺寸为 $K_"win" times K_"win"$
      - 这里和上面的图画得感觉不好，没太看出来 window 和空间上的关系（另外公式似乎写错了，从图上看 $i=0$ 原输入视图也包括在 cross-attention）。但总之，就是设计了一个 projection-aware inter-attention 模块，做了多头掩码交叉注意力来融合特征
      #fig("/public/assets/Reading/Human/2025-01-25-15-57-21.png", width: 50%)
    - 个人感觉并没有充分利用 3DGS 的特性，依旧停留于更好的特征融合上，跟 GTA & SIFU 没有本质区别。而且最终的 3DGS 表征是纯离散而非 ExAvatar 那样 mesh + 3DGS 融合的，约束来自于学习出的隐式特征而不是显式的（个人认为，在缺乏数据的情况下隐式的、数据驱动的约束不够强大）。*如何跟 3DGS 结合，是一个可以深入挖掘的方向*
      - 怎么样又能控制高斯密度，又能充分融合特征信息，预测每个高斯的属性？
      - 预测一个代表 body 还是 cloth 的 probability？更进一步细分成面部、手部等不同部位，给予不同的处理粒度？似乎可以跟下面的 semantic 信息结合
      - 比如，脸部用更小更精细更多的高斯（分裂阈值降低），衣服允许跟 vertices 更大的 offsets 从而显式控制宽松衣物？
      - 还得思考 animatable 的话，如何处理蒙皮权重

=== Semantics-guided Objectives
- 对每个输出 token $tilde(bF)_i$，使用 $1 times 1$ 卷积核 decode 出 pixel-aligned 高斯属性
  $ bG := {(mu_i, q_i, s_i, c_i, si_i)|i=1,dots,N_p} $
  - 我又来疑问了，$tilde(bF)_i$ 应该代表的是每个 patch 位置在不同视图下的 token，用 $1 times 1$ 卷积核应该是指在不同视角的维度上 concat？那么 patch 之间的信息交互是否忽略了？用 swin transformer 那种 patch merging 方法似乎可以改善？亦或者说其实 “信息交互” 在前面 cross-attention 阶段已经足够，这里不再需要了？
- 需要设计出一个理想的目标函数，保持三维重建渲染出的视图与 GT 视图之间的总体一致性；另外，人类总是很关注面部细节，对感知质量有很大影响，所以需要设计一个 *Hierarchical loss*
  - 以往的方法总是忽略了人体解剖学中蕴含的丰富语义信息，而这里比较天才的一点是我们可以利用 SMPL 本身就定义好的 SMPL segmentation
    - SMPL 中定义了 $24$ 个关节点 (e.g. "right hand", "left hand", "head")，然后通过蒙皮权重我们可以判定 vertices 分属于哪个区域，可以参考这篇博客 —— #link("https://www.stubbornhuang.com/3083/")[将 smpl、smplh、smplx 模型按不同身体部位以不同的颜色进行渲染]
  - 因此我们可以对不同身体区域施加不同的注意力权重，并从不同视角下渲染不同分辨率等级的图像，提供 hierarchical supervision，与常见的 reconstruction loss 相加形成最终的 loss function
    $ cL = cL_H + cL_"Rec" $
  - *hierarchical loss* 定义为 part-specific losses 的加权和
    $ cL_H = 1/n 1/m sumin sumjm la_i la_j (cL_MSE (bI_(i,j), hat(bI)_(i,j)) + la_p cL_p (bI_(i,j), hat(bI)_(i,j))) $
    - $i, j$ 分别代表分辨率等级和身体部位，$la_i, la_j$ 为其权重，$cL_p$ 表示 perceptual loss（另外，是不是少写了视角层面的求和？）
    - appendix 里具体的描述
      - 首先根据相机参数和 SMPL mesh，计算可见的三角面片，然后赋予对应的 semantic label。这个过程是 online 的而不需要 pre-computation
      - 该方法显著地促进了关键身体部位的精确定位，在监督层面提供了 3D consistency，避免了训练不稳定的问题
      - 主要关注 head and hands 而不包括 hair and clothing（毕竟 SMPL 里面没有），后者在后续图像级别的监督中优化；并非使用完全的分割成子部分分别重建然后合并的做法，而是基于 part segmentation 设计 loss function（soft 的意思？），因此对 segmentation 的准确性要求不高
  - *Reconstruction Loss* 则为常见的定义
    $ cL_"Rec" = sum_(i=1)^N_"render" cL_MSE (bI_i, hat(bI)_i) + la_m cL_MSE (bM, hat(bM)_i) + la_p cL_p (bI_i,hat(bI)_i) $

== Experiments & Conclusion
- 跟以往方法 PIFu, LGM, GTA, SIFU, Magic123, HuamnSGD, TeCH 比较
  - 比较尴尬的是，THuman 2.0 数据集上的 PSNR, SSIM 居然没打过 TeCH。可能是因此做了 Twindom dataset 上的实验，作者说这个数据集更加 challenging，在这个数据集下明显领先于 TeCH
  - 另外就是 inference time 的区别
    - 虽然单视图人体重建领域基本是基于学习而非 per-instance 优化，但一些方法仍会做一些相对耗时的优化 / 反馈，比如 SIFU 的 texture refinement，TeCH 没看过但好像是用 SDS optimization
    - 在这些方法里面 HumanSplat 是最快的（$9.3s$，而且有足足 $9s$ 都是 SV3D 占的），尤其是跟采用 optimization 的 TeCH 相比（需要 $4.5h$）快得多。并且由于 3DGS 的渲染效率高，在后续的新视图合成上更是快到完全达到实时级别（但是这里由于没做 animatable，这个优势其实没体现出来）
  - 定性实验，从作者节选出的图片来看，HumanSplat 确实在细节以及纹理上都产生了比较好的效果（但为啥不跟 SIFU 比而是跟 GTA 比？）。以及 TeCH 虽然在纹理上效果也不错，但其 SDS optimization 常产生 overly saturated multi-face outcomes
- 结论就不重复了，来看看作者提到的 limitation and future works
  + 老生常谈的多样化服装问题，未来的改进应该结合 2D 数据和新的训练策略来改善这一点
  + 尽管已经很快了，但计算速度可以进一步通过限制高斯数量以及把 compact 3DGS 和 texture representation（是指 CG 那边的纹理贴图、BRDF 吗？）结合来提高
  + 目前驱动重建出的人体需要后处理 (Open-AnimateAnyone)，未来工作可以通过引入 canonical space 来重建 animatable avatars，简化流程并提高效率
- 现在回过头来一看感觉创新不算很多？而且感觉对 3DGS 的利用并不深入

== 论文十问
+ 论文试图解决什么问题？
  - 单视图重建人体
+ 这是否是一个新的问题？
  - 并非
+ 这篇文章要验证一个什么科学假设？
  - 感觉没有一个很明确的科学假设
+ 有哪些相关研究？如何归类？谁是这一课题在领域内值得关注的研究员？
  - 略
+ 论文中提到的解决方案之关键是什么？
  - 用 2D 生成模型作为 appearance 先验，用 SMPL 作为 structure 先验，用可泛化的、端到端的架构预测 3DGS 属性
+ 论文中的实验是如何设计的？
  - 见上
+ 用于定量评估的数据集是什么？代码有没有开源？
  - THuman 2.0, Twindom dataset，代码开源在 #link("https://github.com/humansplat/humansplat")[github/humansplat]
+ 论文中的实验及结果有没有很好地支持需要验证的科学假设？
+ 这篇论文到底有什么贡献？
  - 至少是我看到的第一个把 3DGS 引入单视图人体重建的工作
+ 下一步呢？有什么工作可以继续深入？
  - 见上
