---
order: 4
draft: true
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
#let muth = $mu_th$
#let Sith = $Si_th$
#let tmu = $tilde(mu)$
#let tbe = $tilde(be)$
#let tsi = $tilde(si)$
#let tsit = $tsi_t$
#let tsith = $tsi_th$
#let VLB = math.text("VLB")
#let oalt = $overline(al)_t$
#let oalT = $overline(al)_T$
#let oaltm = $overline(al)_(t-1)$
#let sit = $si_t$
#let kat = $kappa_t$
#let lat = $lambda_t$
#let alt = $alpha_t$
#let epth = $ep_th$

= DDIM
- 原论文 #link("https://arxiv.org/abs/2010.02502")[Denoising Diffusion Implicit Models]
- 时间：2020.10.6
- 参考
  + #link("https://zhuanlan.zhihu.com/p/627616358")[一文读懂 DDIM 凭什么可以加速 DDPM 的采样效率]
  + #link("https://kexue.fm/archives/9181/comment-page-5#%E5%BE%85%E5%AE%9A%E7%B3%BB%E6%95%B0")[生成扩散模型漫谈（四）：DDIM = 高观点 DDPM By 苏剑林]

== Key Insights
- 先回顾 DDPM 的推导路线
  $ #box(stroke: red, inset: 6pt, baseline: 6pt)[$p(xt|xtm) -->^"推导"$] p(xt|x0) -->^"推导" p(xtm|xt,x0) -->^"近似" p(xtm|xt) $
- 然而实质上我们只用到
  $
  &"损失函数只依赖于" ~~~~ p(xt|x0) \
  &"采样过程只依赖于" ~~~~ p(xtm|xt)
  $
- 能否只依赖边缘分布 $p(xt|x0)$ 进行推导得到 $p(xtm|xt,x0)$？
  - 从贝叶斯定理的角度，似乎无法做到
    $ p(xtm|xt,x0) = frac(p(xt|xtm) p(xtm|x0), p(xt|x0)) $
  - 但既然它是个边际分布，就可以列出新的方程，用原论文中的*数学归纳法*也好，用*待定系数法*求也罢，推出 $p(xtm|xt,x0)$
    $ int p(xtm|xt,x0) p(xt|x0) dif xt = p(xtm|x0) $
    - 具体推导过程，可以看 #link("https://kexue.fm/archives/9181/comment-page-5#%E5%BE%85%E5%AE%9A%E7%B3%BB%E6%95%B0")[DDIM = 高观点 DDPM By 苏剑林]
  - 摈弃 $p(xt|xtm)$ 有什么用？实质上是抛开了马尔可夫链的假设，构造了实向量 $bsi in RR^T_(>=0)$ 索引的推断分布族 $cal(Q)$ 下的分布
    $
    q_bsi (xtm|xt,x0) &= cN (xtm; sqrt(oaltm) x0 + sqrt(1 - oaltm - sit^2) dot frac(xt - sqrt(oalt) x0, sqrt(1 - oalt)), sit^2 bI) \
    xtm &= sqrt(oaltm) x0 + sqrt(1 - oaltm - sit^2) dot frac(xt - sqrt(oalt) x0, sqrt(1 - oalt)) + sit ep \
    $

    - 人话讲就是我们手动构造了一个分布，且这一分布有 $T$ 个自由参数 $si_1, si_2, dots.c, si_T$，这些参数控制了条件分布 $q_bsi (xtm|xt,x0)$ 的方差，从而影响了逆过程的随机性
    #q[用苏剑林的比喻，就是我们知道楼会被拆成什么样 $p(xt|x0)$、$p(xtm|x0)$，但是不知道每一步怎么拆 $p(xt|xtm)$，然后推导出在知道楼长什么样前提下每一步怎么建（以 $bsi$ 为指导）$q_bsi (xtm|xt,x0)$，希望能够从中学会每一步怎么建 $p(xtm|xt)$，甚至更进一步能够跳步（见后面 @speedup）]
- 后面的步骤就和 DDPM 几乎一致了
  - 记 $f_th (xt,t)$ 表示对 $x0$ 的预测，从 $q_bsi (xtm|xt,x0)$ 预测替换 $x0$ 得到 $p_(bsi, th) (xtm|xt)$
    $
    p_(bsi, th) (xtm|xt) = cases(
      cN (x0; f_th (xt,t), si_t^2 bI) ~~~~ &"if" t = 1,
      q_bsi (xtm|xt, f_th (xt,t)) &"otherwise"
    )
    $
    $
    p_(bsi, th) (xtm|xt) &= cN (xtm; sqrt(oaltm) dot frac(xt - sqrt(1 - oalt) epth (xt), sqrt(oalt)) + sqrt(1 - oaltm - sit^2) dot epth (xt), sit^2 bI) \
    xtm &= sqrt(oaltm) dot underbrace(frac(xt - sqrt(1 - oalt) epth (xt), sqrt(oalt)), "对" x0 "的预测") + underbrace(sqrt(1 - oaltm - sit^2) dot epth (xt), "指向" xt "的方向") + underbrace(sit ep, "随机噪声")
    $
  - 带入 VLB 各项得到优化目标（$equiv$ 符号表示略去跟 $epth$ 无关的常数）
    $
    cL_(t-1) &equiv EE_(x0 wave q(x0), ep wave cN(0,1)) [1/(2 sit^2) norm(tmu(xt,xt) - mu_"prev"i (xt,t))_2^2] \
    &= EE_(x0 wave q(x0), ep wave cN(0,1)) [frac((sqrt(oaltm) - frac(sqrt(1 - oaltm - sit^2) sqrt(oalt), sqrt(1 - oalt)))^2, 2 sit^2) norm(x0 - f_th (t,t))_2^2] \
    &= EE_(x0 wave q(x0), ep wave cN(0,1)) [frac((sqrt(oaltm) - frac(sqrt(1 - oaltm - sit^2) sqrt(oalt), sqrt(1 - oalt)))^2 (1 - oalt), 2 sit^2 oalt) norm(ep - epth (xt,t))_2^2] \
    cL_0 &equiv EE_(x0 wave q(x0), ep wave cN(0,1)) [- log p_th (x0|x1)] \
    &= EE_(x0 wave q(x0), ep wave cN(0,1)) [- d log frac(1, sqrt(2 pi si_1^2)) + frac(1, 2 si_1^2) norm(x0 - f_th (x1,1))_2^2] \
    &equiv EE_(x0 wave q(x0), ep wave cN(0,1)) [frac(1, 2 si_1^2) norm(x0 - f_th (x1,1))_2^2] \
    &= EE_(x0 wave q(x0), ep wave cN(0,1)) [frac(1 - oalt, 2 si_1^2 oalt) norm(ep - epth (x1,1))_2^2]
    $
    #q[好像没法像原论文那样整合到一个 $cJ_bsi$ 里去。但原论文这里的推导感觉很奇怪，反正我推不出来，感觉是为了凑到一个形式改了系数？但网上没看到有人说，是我犯傻了吗？]
    - 回忆 DDPM 的损失函数
      $ cL_(t-1)^"DDPM" = EE_(q(xt|x0)) [frac((1 - alt)^2, 2 tsit^2 alt (1 - oal_t)) norm(epth (xt,t)-ep_t)_2^2] $
    - 但总之，通过控制系数里面的 $si_t$，我们可以推出 DDIM 与 DDPM 在某个 $bsi$ 设置下的共同性。@variance 将验证这一点
      $
      "令" ga_t := frac((sqrt(oaltm) - frac(sqrt(1 - oaltm - sit^2) sqrt(oalt), sqrt(1-oalt)))^2 (1-oalt), 2 sit^2 oalt) = frac((1 - alt)^2, 2 tsit^2 alt (1 - oal_t)) \
      cL_(t-1)^(ga_t) = cL_(t-1)^"DDPM" + C \
      $

== 方差选取 <variance>
- 前面说到，这个方差其实是可以随便控制的，我们来看两种特殊的例子
  $
  si_t = sqrt(frac(1 - oaltm, 1 - oalt) be_t) &= sqrt(frac(1 - oaltm, 1 - oalt) dot (1 - alt)) ~~~~ #cnum(1)\
  si_t &= 0 #h(9.7em) #cnum(2)
  $
- 第一个例子
  - DDPM 采取方差 $tsit = sqrt(frac(1 - oaltm, 1 - oalt) be_t)$ 版本（也就是 DDIM 用跟 DDPM 同方差，能推出二者的一致性），那么目标就是
    $ ga_t = frac(1-alt, 2 alt (1 - oaltm)) $
  - 我们将 DDIM 上述方差带入式子，首先来看较难化简的 $sqrt(1 - oaltm - sit^2)$
    $
    sqrt(1 - oaltm - sit^2) &= frac(sqrt(1 - oalt), sqrt(1 - oalt)) sqrt(1 - oaltm - frac(1 - oaltm, 1 - oalt) (1 - alt)) \
    &= frac(sqrt((1 - oalt) (1 - oaltm) (1 - frac(1 - alt, 1 - oalt))), sqrt(1 - oalt)) \
    &= frac(sqrt((1 - oaltm) (1 - oalt - (1 - alt))), sqrt(1 - oalt)) \
    &= (1 - oaltm) frac(sqrt(alt), sqrt(1 - oalt))
    $
  - 于是
    $
    ga_t &= frac((sqrt(oaltm) - (1 - oaltm) frac(sqrt(alt oalt), 1 - oalt))^2 (1 - oalt), 2 oalt frac(1 - oaltm, 1 - oalt) (1 - alt)) \
    &= frac((sqrt(oaltm) (1 - oalt) - (1 - oaltm) sqrt(alt oalt))^2, 2 oalt (1 - oaltm) (1 - alt)) \
    &= frac(oaltm ((1 - oalt) - alt (1 - oaltm))^2, 2 oalt (1 - oaltm) (1 - alt)) \
    &= frac((1 - alt)^2, 2 alt (1 - oaltm) (1 - alt)) \
    &= frac(1 - alt, 2 alt (1 - oaltm))
    $
  - 以上我们从损失函数出发，推导出在这种方差设置下 DDIM 与 DDPM 的一致性（实际上，因为方差是已知相等的，直接用均值相等来推导会更快）
  - 论文作者实际上对 $si_t = eta sqrt(frac(1 - oaltm, 1 - oalt) be_t), ~~~~ eta in [0,1]$ 做了对比实验
- 第二个例子
  - 方差为零，则 $xt$ 到 $xtm$ 是一个确定性变换，从 $xT = bz$ 出发得到 $x0$ 是不带随机性的
    $ xtm = sqrt(oaltm) dot frac(xt - sqrt(1 - oalt) epth (xt), sqrt(oalt)) + sqrt(1 - oaltm - sit^2) dot epth (xt) $
  - 这才是论文 DDIM 的 Implicit 含义，变成一个 deterministic 的隐式分布。因此 DDIM 其实并不是一个模型，只是一个特殊的采样方式
  - 我们可以认为此时的 $x_T$ 就是一个 high-level 的图像编码向量，里面可能蕴涵了大量的信息特征，也许可以用于其他下游任务
  - 最后，作者论述了当 $eta=0$ 时，上式可以写成常微分方程的形式，因此可以理解为模型是在用欧拉法近似从 $x_0$ 到 $x_T$ 的编码函数
  - 此外，这种确定性变换已经跟 GAN 几乎一致了，与 GAN 类似，我们可以对噪声向量进行插值，然后观察对应的生成效果
    - 但 DDPM 或 DDIM 对噪声分布都比较敏感，所以我们不能用线性插值而要用球面插值。因为如果 $bz_1, bz_2 wave cN(bold(0),bI)$，叠加的 $la bz_1 + (1-la) bz_2$ 一般就不服从 $cN(bold(0),bI)$，要改为
      $ bz = bz_1 cos (la pi) / 2 + bz_2 sin (la pi) / 2, ~~~~ la in [0,1] $

== 加速采样 <speedup>
- DDIM 的推导不依赖马尔可夫性质，抛开马尔可夫性质可以改写成
  $
  q_(bsi, th) (x_"prev"|x_"next") &= cN (x_"prev"; sqrt(oal_"prev") dot frac(x_"next" - sqrt(1-oal_"next") epth (x_"next"), sqrt(oal_"next")) + sqrt(1 - oal_"prev" - si_"next"^2) dot epth (x_"next"), si_"next"^2 bI) \
  x_"prev" &= sqrt(oal_"prev") dot frac(x_"next" - sqrt(1-oal_"next") epth (x_"next"), sqrt(oal_"next")) + sqrt(1 - oal_"prev" - si_"next"^2) dot epth (x_"next") + si_"next" ep
  $
  - 于是就可以从时间序列 ${0,...,T}$ 中随机取一个长度为 $l$ 的升序子序列，通过上式迭代采样 $l$ 次最终得到我们想要的 $x_0$
- 复用 DDPM
  - 注意到 DDPM 的训练结果实质上包含了它的任意子序列参数的训练结果，并且 DDIM 训练过程中 $bsi$ 的设置不影响边界分布 $x_T=sqrt(oalT) x0 + sqrt(1 - oalT) ep$
  - 因此二者的训练实际上是共通的！训练好的 DDPM 可以直接拿来通过 DDIM 的采样方法进行采样，不需要再去训练一次
  - 为什么干脆不直接训练一个 $l$ 步的扩散模型，而是要先训练 $T > l$ 步然后去做子序列采样？按苏剑林的说法，一方面从 $l$ 步生成来说，训练更多步数的模型也许能增强泛化能力；另一方面，通过子序列进行加速只是其中一种加速手段，训练更充分的 $T$ 步允许我们尝试更多的其他加速手段，但并不会显著增加训练成本

== 总结
- DDIM 是 DDPM 的高观点回顾，完全摈弃了单步加噪 $q(xt|xtm)$ 的方式，从而不再限制扩散过程必须是一个马尔可夫链。从这个角度利用边缘分布 $q(xt|x0)$ 推导出比 DDPM 更一般的式子，并顺便解决 DDPM 推理慢的问题，用小采样步数加速生成过程
- 近两年论文其实用的并不多

= IDDPM
- 原论文 #link("https://arxiv.org/abs/2102.09672")[Improved Denoising Diffusion Probabilistic Models]
- 时间：2021.2.18

== Motivation & Insights
- 虽然 DDPM 在生成任务上取得了不错的效果，但如果使用一些 metric 对 DDPM 进行评价，就会发现其虽然在 FID 和 IS 指标上效果不错，但在负对数似然 (Negative Log-likelihood，NLL) 上表现不够好
  - 根据 VQ-VAE2 文章中的观点，NLL 体现的是模型捕捉数据整体分布的能力，迫使生成模型拟合数据分布的所有模式。有工作表明即使在 NLL 指标上仅有微小的提升，就会在生成效果和特征表征能力上有很大的提升
- Improved DDPM 主要是针对 DDPM 的训练过程进行改进，主要从两个方面：
  + 固定方差改为可学习方差；
  + 改进加噪过程，使用余弦形式的 Scheduler，而不是线性 Scheduler

== 可学习的方差
- 首先我们知道 DDPM 中采用跟 $t$ 有关的固定方差，可以是 $tbe_t = frac(1-oal_(t-1), 1-oal_t) be_t$ 或者 $be_t$，效果区别不大
  - 这两种方差的设置刚好是假设数据集分布为狄拉克函数和标准正态分布的两种极端情况
  - 这里首先分析了为什么会出现这种情况：因为随着 $t$ 的增大，$frac(tbe_t, be_t)$ 趋近于 $1$，在大部分采样时刻二者近似相等；并且总步数越大，这个差异越不明显。如下左图
  #fig("/public/assets/Reading/Generation/2025-03-02-10-44-45.png", width: 80%)
  - 这么看来方差的设置不太重要？尤其是在采样步数增大以后，基本完全取决于均值 $muth(xt,t)$ 而非方差 $Sith(xt,t)$，至少两种固定方差对最终结果影响不大
  - 但我们换一种视角，从对 NLL 的数值贡献上来看，如上右图，最初的几步扩散对 VLB 的影响是最大的。换句话说，对 NLL 的增大而言，$Sith(xt,t)$ 依然有一定作用。于是作者做了如下设置
    $ Sith(xt,t) = exp(v log be_t + (1-v) log tbe_t) bI $
    - 其中 $v$ 是可学习参数，也就是在对数层面进行 $be_t, tbe_t$ 的插值
    - 之所以用插值的形式，是因为如前所述 $be_t, tbe_t$ 的差异（变化范围）非常小，从数值精度上就不适合神经网络学习；同时，插值的形式也符合对两个极端的认识
    - 这里我们没有对 $v$ 的范围进行限制，所以理论上模型可以学习到任意范围的方差值，但在实验中并未观察到模型学习到超出插值范围的方差的情况
  - DDPM 的损失函数 $L_"simple"$ 与 $Sith(xt,t)$ 无关，所以肯定要做修改，这部分留到后面介绍

== 余弦调度器
- DDPM 使用线性的 $be_t$ 超参规划，对于高分辨率图像效果还行，但对低分辨率的图像表现不佳
  - 为什么？因为 DDPM 前向加噪时，$be_t$ 是从一个较小值逐渐增大，如果最开始的时候加入很大的噪声，会严重破坏图像信息，不利于图像的学习。对于低分辨率图像尤其严重，因为包含的信息本身就不多，加噪太快使得细节丢失太快
  - 回忆原本的超参设置，$T=1000$，$be_t$ 从 $be_1=10^(-4)$ 到 $be_T=0.02$ 线性变化，大致上可以表示为
    $ alt = 1 - be_t = 1 - frac(0.02 t, T), ~~~~ oal_t = Pi_(i=1)^t al_i $
- 现在我们设置如下
  $ oal_t = frac(f(t),f(0)), ~~~~ f(t) = cos(frac(t\/T+s, 1+s) dot pi/2)^2 $
  - 除此之外设计这个 schedule 的时候作者也有一些比较细节的考虑，比如选取一个比较小的偏移量 $s=8 times 10^(-3)$，防止 $be_t$ 在 $t=0$ 附近过小，并且将 $be_t$ 裁剪到 $0.999$ 来防止 $t=T$ 附近出现奇异点
    - $s$ 的数值来自希望使 $sqrt(be_0)$ 略小于像素区间大小 $1\/127.5$
  - 这个 schedule 在 $t=0$ 和 $t=T$ 附近都变化比较小，而在中间有一个接近于线性的下降过程，同时可以发现 cosine schedule 使图片能够在中间地带还能保持一个比较好的图片细节，最终 FID 指标也有所上升
  #fig("/public/assets/Reading/Generation/2025-03-02-13-48-12.png", width:80%)

== 训练过程
- 最终训练使用的损失是两项损失的加权
  $ cL_"hybrid" = cL_"simple" + la cL_VLB $
  - $cL_"simple"$ 是 DDPM 简化 (reweight) 后的损失函数，$cL_VLB$ 是推导中用的标准变分下界
  - 前者与 $Sith(xt,t)$ 无关，后者用 $la=1 times 10^(-3)$ 权重避免喧宾夺主，且对 $cL_VLB$ 中的均值项 $muth(xt,t)$ 进行 stop-gradient（只影响方差）
- 随后作者发现直接的 $cL_VLB$ 很难优化 $-->$ *resample*
  - 作者分析认为这是因为不同时间步的 VLB 损失大小不一（也就是上边那个损失曲线），导致 $cL_VLB$ 的梯度比较 noisy
  - 回忆 DDPM 的 $cL_"simple"$，虽然方差和均值的设置不一样，但损失贡献不一致的问题是一样的，对此 DDPM 采用 reweight 解决，同时也时损失函数更加简单
  - 作者这里采用了不同的方法，称为*重要性采样*
    $ cL_VLB = EE_(t wave p_t) [L_t / p_t], ~~~~ "where" p prop sqrt(EE[L_t^2]) "and" sum p_t = 1 $
    - 根据 $t$ 在之前采出的 loss 值的平方 $L_t^2$（会随着每次采样计算出的 loss 值而动态更新）确定采样分布
    - 具体方法是先对每个 $t$ 都采样 $10$ 次，选用平均值作为 $L_t$，然后作为权重进行重要性采样，每次采样后都用计算出的 loss 去更新对应平均值

= Analytic-DPM & Extended-Analytic-DPM
- 其实 IDDPM 的做法算比较简单的，后续还有一些对方差的改进，比如
  + #link("https://arxiv.org/abs/2201.06503")[Analytic-DPM: an Analytic Estimate of the Optimal Reverse Variance in Diffusion Probabilistic Models] (2022.1.17)
  + #link("https://arxiv.org/abs/2206.07309")[Estimating the Optimal Covariance with Imperfect Mean in Diffusion Probabilistic Models] (2022.6.15)
  - 还是看苏剑林的博客吧 #link("https://kexue.fm/archives/9245")[生成扩散模型漫谈（七）：最优扩散方差估计（上）]、 #link("https://kexue.fm/archives/9246")[生成扩散模型漫谈（八）：最优扩散方差估计（下）]
