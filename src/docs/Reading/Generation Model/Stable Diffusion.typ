---
order: 5
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Diffusion Model",
  lang: "zh",
)

#let xt = $bx_t$
#let xT = $bx_T$
#let x0 = $bx_0$
#let x1 = $bx_1$
#let xj = $bx_j$
#let oal = $overline(al)$
#let xtm = $bx_(t-1)$
#let xtp = $bx_(t+1)$
#let x0T = $bx_(0:T)$
#let x1T = $bx_(1:T)$
#let pth = $p_th$
#let pth = $p_th$
#let muth = $mu_th$
#let Sith = $Si_th$
#let tmu = $tilde(mu)$
#let tsi = $tilde(si)$
#let tsit = $tsi_t$
#let tsith = $tsi_th$

= Stable Diffusion
- Stable Diffusion 是什么？基于*扩散模型*的*文生图*模型
  - 时间线
    - 2021.12 早期由 Stability AI 资助，Comp Vis 与 Runway ML 联合研究，发布 paper LDM
    - 2022.08 Comp Vis 发布 SD1.1 #wave SD1.4
    - 2022.10 Runway ML 发布 SD1.5
    - 2022.11 Stability Al 发布 SD2.0
    - 至今 ~~~~ 此后发布便一直以 Stability AI 名义发布模型
    #fig("/public/assets/Reading/Generation/2025-03-01-20-34-06.png", width: 80%)

== LDM
- LDM (latent diffusion mofel) 与 DDPM 的关系
  + LDM = VAE + DDPM
  + LDM 在语义空间做 Diffusion
  + LDM 有更多模态的融入（类别、文本……）
- *classifier guidance*
  - 给定 $y$ 的条件下，$p(xtm|xt)$ 的分布是多少？
    $
    p(xtm|xt,y) &= frac(p(xt|xtm,y) p(xtm|y), p(xt|y)) \
    &= frac(p(xt|xtm) p(xtm|y), p(xt|y)) \
    &= frac(p(xt|xtm) p(xtm|y) p(y), p(xt|y) p(y)) \
    &= frac(p(xt|xtm) p(xtm) p(y|xtm), p(xt) p(y|xt)) \
    &= p(xtm|xt) frac(p(y|xtm), p(y|xt)) \
    &= p(xtm|xt) exp(log p(y|xtm) - log p(y|xt)) \
    &approx p(xtm|xt) exp((xtm-xt) na_xt log(p(y|xt))) ~~~~ log x "在" p(y|xt)"处泰勒展开"
    $
    - 将 DDPM 中 $p(xtm|xt) wave cN (xtm;muth(xt,t);tsi_t^2 bI)$ 带入并整理得到
    $ p(xtm|xt,y) = cN (xtm; muth(xt,t) + tsi_t^2 na_xt log(p(y|xt)), tsi_t^2 bI) $
    - 即 classifier guidance 相当于 unconditioned + 分类对抗梯度。也就是说，在原本 DDPM 的基础上，加入 $y$ 相对 $xt$ 的梯度信息，驱使它往我们希望的方向走（均值漂移）
  - 在以上基于数学的推导基础上，由实验发现加入超参 $ga$ 可以更好地调节生成效果
    $ p(xtm|xt,y) = cN (xtm; muth(xt,t) + ga tsi_t^2 na_xt log(p(y|xt)), tsi_t^2 bI) $
  - 训练采用两阶段，另外训练一个分类器 $p(y|xt)$
    - 输入是 $xt$，是加了噪声的图片，由 DDPM 的超参可以得到，据此预测不同类别的概率即可（因此并非任何图像分类器均可）
    - classifier guidance 的另一个好处就在于，因为 DDPM 一般比较大训练很慢，这个时候我们只需要调整相对小的分类器，就能让其有分类指导的能力
  - 推理时，只需要每一步算分类器相对 $xt$ 的梯度，加到高斯分布的均值里即可
- *classifier free*
  - 为什么要有这玩意儿？首先一方面 classifier 的引入让 pipeline 变得复杂，大家学术上互相卷起来；另一方面就是这个分类器的输入是带噪声的 $xt$ ，其效果可以想见不会太好
  - classifier free 是以另一种玄学方式求解上述梯度。试想，同一个模型给它两个输入，一个带 $y$ 一个不带，那么减一下就成为我们想要的那个梯度
  $
  p(xtm|xt) &wave cN (xtm; muth(xt,t), tsi_t^2 bI) \
  p(xtm|xt,y) &wave cN (xtm; muth(xt,t,y), tsi_t^2 bI)
  $
  $
  muth(xt,t,emptyset) &= 1/sqrt(al_t) (xt - frac(1-al_t,sqrt(1-oal_t)) ep_th (xt,t)) \
  muth(xt,t,y) &= 1/sqrt(al_t) (xt - frac(1-al_t,sqrt(1-oal_t)) ep_th (xt,t,y))
  $
  $
  xtm &= muth (xt,t,y) + tsi_t ep \
  &= muth (xt,t) + tsi_t^2 na_xt log(p(y|xt)) + tsi_t ep \
  => xtm &= muth (xt,t) + ga (muth (xt,t,y) - muth (xt,t)) + tsi_t ep
  $
  - 实现上，把 $y$ 做成一个 embedding，跟 $t$ 一起加入网络即可
  - classifier free 也是一种财大气粗的表现（因为整个网络要重训）
- *text guidance*
  - 跟 classifier free 一样，不管你是什么，反正就是个条件，做成输入融进网络即可（大道至简）
    - [ ] 其实还是有一些数学原理在的
  - 不过 text 的融合方式跟 class 有所不同（因为信息表现形式不同：长文本序列和单个类别），所以前面 class 通过跟 time 想加，而 text 通过在网络中加入 cross-attention
  - 网络结构上，把 text 用 CLIp 拿到 embedding 后，把原本 resblock 内的 self-attention 变成 cross-attention 即可（$K$ 和 $V$ 为 text）

== SDXL
- 相比 SD 1.5
  + 更大的模型结构
    + 删除 UNet 最后一次下采样 ($1\/8 -> 1\/4$)
    + 深层更多 Tranformer Block
    + 使用一大一小两个 clip text encoder（力大砖飞……），进而有更大的 context dim
    + 增加 pooled text embedding
  + 更多的条件控制且更多的图片
    + 利用原先没有使用的小图片，增加图片原始尺寸的 condition $(h_"ori", w_"ori")$
    + 增加 crop 参数的 condition $(c_"top", c_"left")$
    + 多分辨率（将不太分辨率图片放入不同 bucket，训练时保证 batch 来自同一 bucket），加入 bucket size 的 condition $c_"ar"=(h_"tgt",w_"tgt")$
    - 融入方式就是做 embedding 后 concat 起来，过一个 MLP 融合模态，跟 time 的 embedding 加到一起
  + 更强的 VAE
  + SDXL-base + SDXL-refiner
- SDXL-base 的训练范式
  - 三阶段训练，不同阶段的输入尺寸和模态不同
  - Stage 3 加了 $0.05$ 的偏移噪声
    - 为什么？因为我们前向加噪到最后，虽然已经很接近高斯噪声，但毕竟不是纯高斯分布；但反向生成的时候用的是纯高斯分布
    - 这会导致无法生成全黑或全白的图片。而更为严重的影响是，模型蒸馏的时候（SDXL turbo，让模型反向一步就能生成图片），这一点点的 gap 会带来巨大的影响
    - 这个偏移噪声就是其中一种解决方案，还有一些解决方案可以参考这篇论文 #link("https://arxiv.org/abs/2305.08891")[Common Diffusion Noise Schedules and Sample Steps are Flawed]
- SDXL-Refiner
  - 是一个独立的*图生图的去噪模型*
  - 增加了美学得分的 condition
  - 总之它的作用是优化 base 的结果，使一些细节变得更好
- 总结
  + SDXL 使用了更大的模型结构 ($0.8B -> 2.6B$)
  + SDXL 更高效地利用了以前被丢弃的数据
  + SDXL 使 condition 更模块化
  + SDXL 是重新训练的版本模型（诚意满满）
  + SDXL 尝试解决了一些实际问题，比如多分辨率，生成目标完整性等
  + SDXL 对分辨率敏感

== SD 的发展与插件
- 输入模态与方式的革新，主要分为三种方式
  + 基于训练，直接重训新模态的网络，比较少见
  + 基于微调，比如 ControlNet
  + 非训练也非微调 (tuning-free)，如 InstantID
- ControlNet
  - 后面介绍

= Fine-Tuning of Diffusion Models
- 参考 #link("https://www.bilibili.com/video/BV1Hk4y1p7nN")[【详解】LoRA, ControlNet等Stable Diffusion微调方法原理详解！]
- Textual Inversion —— 简易
  - 在 CLIP 的字典中新增一个伪词的 embedding，finetune 这个 embedding，其它参数都冻结
  - 训练量极小，只需一张图；但完全不改神经网络参数效果有限
- Dream Booth —— 完整
  - 找一个罕用词代表 subject，其 embedding 继承自原类型的词的 embedding
  - 调整了模型的所有可调参数，彻底让模型学会 subject
  - “灾难性遗忘” 问题，通过 loss 项防止 “学会新的忘记旧的”
  - 再 LoRA 出现前，训练 Dream Booth 是主流，但代价较大
- Custom Diffusion —— 精简
  - Custom Diffusion 基本建立在 DreamBooth 的基础上，通过消融实验证明了即使只训练交叉注意力层中的部分矩阵，也有非常好的 finetune 效果（不需要像 DreamBooth 那样全部参数调整）
  - 这种思路也引领了后续的一系列研究，但 DreamBooth 仍然是当时的范式
- LoRA —— 灵巧
  - LORA 的网络是一种 additional network，训练不改变基础模型的任何参数，只对附加网络内部参数进行调整。在生成图像时，附加网络输出与原网络输出融合，从而改变生成效果
  - 由于 LORA 是将矩阵压缩到低秩后训练，所以 LORA 网络的参数量很小，训练速度快
    - 实验发现，低维矩阵对高维矩阵的替代损失不大。所以即便训练的矩阵小，训练效果仍然很好，已经成为一种 customization image generation 范式
  - LORA 后来在结构上改进出不同的版本，例如 LoHa，LyCORIS 等
    - 典型修改方案 LyCORIS，这个以二次元人物命名的方法把 LORA 的思想应用在卷积层做改进，并且结合了一些其他算法进行了参数调整
  #fig("/public/assets/Reading/Generation/2025-03-05-22-18-57.png", width: 40%)
- ControlNet —— 彻底
  - 一种高效微调 text-to-image diffusion models 的方法，可以*让 diffusion model 学习空间条件注入信息*
  - ControlNet 冻结 stable diffusion 的参数，复用它的 encoding layers 来训练，其中复用的 encoding layers 的参数为零初始化 ("zero convolutions" , zero-initialized convolution layers)，确保没有有害的噪声影响微调
  - 属于比较工程性的工作
