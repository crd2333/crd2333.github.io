---
order: 3
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
#let tsi = $tilde(si)$
#let sit = $si_t$
#let tsit = $tsi_t$
#let tsith = $tsi_th$
#let oalt = $oal_t$
#let ept = $ep_t$
#let epth = $ep_th$

- 可以参考
  + #link("https://kexue.fm/tag/%E6%89%A9%E6%95%A3/4/")[生成扩散模型漫谈（苏剑林）]
  + #link("https://www.bilibili.com/list/watchlater?oid=1053831517&bvid=BV19H4y1G73r")[【较真系列】讲人话-Diffusion Model全解(原理+代码+公式)]、#link("https://www.bilibili.com/list/watchlater?oid=113497413322062&bvid=BV1wkU6Y7EiT")[【串讲系列】讲人话-Stable Diffusion全解（原理+代码+公式）之SDXL]
  + #link("https://zhuanlan.zhihu.com/p/11228697012")[零推导理解 Diffusion 和 Flow Matching]
  + #link("https://zhuanlan.zhihu.com/p/638240916")[理解扩散模型：一个统一的视角 Understanding Diffusion Models: A Unified perspective 全译文]（也就是宋飏博士那篇博客）
    - 又看到一篇它的 #link("https://zhuanlan.zhihu.com/p/558937247")[阅读笔记]
  + #link("https://zhuanlan.zhihu.com/p/12591930520")[一文贯通 Diffusion 原理：DDPM、DDIM 和 Flow Matching]
  + #link("https://www.bilibili.com/video/BV1Ax4y1v7CY/")[【公式推导】还在头疼 Diffusion 模型公式吗？Diffusion 理论公式喂饭式超详细逐步推导来了！]

= 生成模型
- 生成模型是 “涌现” or “幻觉”，常见的 text-conditioned 生成模型是 “言出法随”。下面讨论不带条件的（最基本的）生成模型
- 定义：一个能随机生成*与训练数据一致*的样例的模型
- 问题：如何对训练数据建模？如何采样？
- 思路：从一个简单分布（对其采样是容易的）变换到观测数据分布（这个变换是可以拟合的）
  - encoder: 从观测数据分布映射到简单分布，记作 $q(bz|bx)$
  - decoder: 从简单分布映射到观测数据分布，记作 $pth(bx)$
  - 训练时需要 encoder 和 decoder，推断时只需要 decoder
  #fig("/public/assets/Reading/Generation/2025-02-28-22-25-42.png", width: 25%)
- 这个简单分布采用*高斯分布*
  - Why? 回忆*高斯混合模型*，一个复杂分布可以用多个高斯分布来表示
    $ pth(bx) = sumiK p(bz_i) pth(bx|bz_i) $
  - 为了避免设置 $K$ 作为超参，把 $bz$ 表示为连续的高斯分布（即*高斯个高斯分布*）
    $ pth(bx) = int p(bz) pth(bx|bz) dif bz $
- 如何求 $th$？
  - 使用极大似然估计
    $ th^* = argmax_th pth(bx) $
  - 最小化负对数似然 $LL=-log(pth(x0))$
    $
    log(pth(x0)) &= log(pth(x0)) int q(bz|bx) dif bz ~~~~~~ "借一个值为一的积分" \
    &= int log(frac(pth(bx,bz), pth(bz|bx))) q(bz|bx) dif bz ~~~~~~ "贝叶斯公式" \
    &= int log(frac(pth(bx,bz), q(bz|bx)) \* frac(q(bz|bx), pth(bz|bx))) q(bz|bx) dif bz \
    &= int log(frac(pth(bx,bz), q(bz|bx))) q(bz|bx) dif bz + KL(q(bz|bx)||pth(bz|bx)) ~~~~~~ KL(p|q) = int p log p/q \
    &>= int log(frac(pth(bx,bz), q(bz|bx))) q(bz|bx) dif bz = EE_q(bz|bx) [log(frac(pth(bx,bz), q(bz|bx)))]
    $
    - 此即为*证据下界 Evidence Lower Bound (ELBO)*，有时也称为 *Variational Lower Bound (VLB)*
    - 极大似然估计 = 最大 lower bound = 最小化负对数似然
    #q[注：从第一条式子到最后一条实际上可以直接由 Jensen 不等式得到，但这里的推导显示出 Evidence 和 Evidence Lower Bound 之间显式的关系 —— 差一个 KL 散度项（而且该项的形式很有意思）]
  #question[
    注：上面的推导过程看起来很有道理，但为什么最大化 ELBO 就可最大化似然呢？会不会有一种可能 ELBO 增大的同时 KL 减小，于是似然并没有增大？

    宋飏博士的博客对这个变分推断的过程进行了解释，他的推导如下：
    $ log p(bx) = EE_(q_th (bz|bx))[log frac(p(bx,bz), q_th (bz|bx))] + D_KL (q_th (bz|bx)||p(bz|bx)) $
    我们的目的是最小化 KL 散度，即让预测的变分后验分布 $q_th (bz|bx)$ 尽可能逼近真实后验分布 $p(bz|bx)$，但我们无法访问 ground truth $p(bz|bx)$。然而，evidence 相对 $th$ 是个常数，所以我们可以通过最大化 ELBO 来最小化 KL 散度。此外，训练完成后 ELBO 也可用于估计似然（因为它逼近  $log p(bx)$）。

    宋飏博士的这个解释感觉自然很多，但这里并不是最大化似然而是最小化 KL。然而，无论是各大博客还是原论文都有极大似然的表述，感觉有点奇怪？
  ]

= DDPM
- 原论文 #link("https://arxiv.org/abs/2006.11239")[denoising Diffusion probabilistic Models]
- 时间：2020.6.19

== 前向扩散与反向生成
- *前向扩散过程 (forward diffusion process)* $p(bz|bx), p(bx_T|x0)$
  - 核心加噪过程
    $
    xt = sqrt(1 - beta_t) xtm + sqrt(beta_t) ep_(t-1) \
    xt = sqrt(oalt) x0 + sqrt(1 - oalt) ept
    $
    #q[
      注：$al_t = 1 - be_t, ~~ oalt = pi_(i=1)^t al_i$ \
      注：这个 $ept$ 和 $ep_(t-1)$ 不是同种 $ep$，一个是逐步的，一个是单步的（重参数化采样表示出来的），理论上来说应该标识一下，但为美观起见就不标了，后续我们统一采用后者
    ]
  - 其概率描述
    $
    q(xt|xtm) = cN (xt; sqrt(1 - beta_t) xtm, beta_t bI) \
    q(xt|x0) = cN (xt; sqrt(oalt) xt, (1 - oalt) bI)
    $
  - 重参数化采样：从 $x0$ 逐步推向 $bx_T$，已知的 $xtm$ 作为固定偏置，结果就是一个均值比较奇怪的高斯分布（沾上一点高斯就变成了高斯），并且我们可以通过系数来操控每一步以及最后的高斯的均值与方差
    - 两个独立高斯分布的和依然是高斯分布，且均值为二者均值的和、方差为二者方差的和
  - 超参设置，$T=1000$，$be_t$ 从 $be_1=10^(-4)$ 到 $be_T=0.02$ 线性变化，大致上可以表示为
    $ al_t = 1 - frac(0.02 t, T) $
    - 为什么要设置这么大的 $T$ 和这么一个单调递减的 $al_t$？两个问题的答案其实是一致的
      - 这跟具体的数据背景有关。在重构的时候我们简单起见用欧氏距离作为损失函数，这其实并不是图片真实程度的好的度量。VAE 用欧氏距离来重构时往往会得到模糊的结果，除非是输入输出的两张图片非常接近才能得到比较清晰的结果。为此，较大的 $T$ 让我们每一步的变化尽可能小
      - 当 $t$ 比较小时，$xt$ 还比较接近真实图片，要缩小 $xtm$ 与 $xt$ 的差距（即较大的 $al_t$），以便更适用欧氏距离；当 $t$ 比较大时，$xt$ 已经比较接近纯噪声，用欧式距离无妨，可以稍微增大 $xtm$ 与 $xt$ 的差距（即较小的 $al_t$）。另外我们最终接近纯高斯噪声要求 $oalt approx 0$，这也要求 $al_t$ 不能一直很大

- *反向生成过程 (reverse diffusion process)* $p(bx|bz), p(x0|bx_T)$
  - 训练时已知 $x0$，反向生成过程也是一个确定性的过程
    - 根据贝叶斯公式
      $ p(xtm|xt) = frac(p(xt|xtm) p(xtm), p(xt)) $
    - $p(xtm), p(xt)$ 未知，但是在给定 $x0$ 情况下，$p(xt|x0), p(xtm|x0)$ 已知（加噪的过程），于是给上式都加上 $x0$ 有
      $ p(xtm|xt,x0) = frac(p(xt|xtm,x0) p(xtm|x0), p(xt|x0)) $
    - 其中 $p(xt|xtm,x0) = p(xt|xtm)$，$p(xt|x0), p(xt|x0)$ 均已知，带入整理系数得到
      $ p(xtm|xt,x0) = cN (xt; 1/sqrt(al_t) (xt - frac(1-al_t,sqrt(1-oalt)) #pin(1)ept), ~~~~~~ frac(1-oal_(t-1), 1-oalt) be_t bI) eq.delta cN (xtm; tmu(xt,x0), tsit^2 bI) $
      #pinit-point-from(1, pin-dy: -5pt, offset-dx: 80pt, offset-dy: -25pt, body-dx: 2pt, body-dy: -4pt, fill: rgb(0, 180, 255))[#bluet[危险的量]]
    - 反向生成过程中的其它值要么是超参，要么是一步步生成的结果，唯独 $ept$ 是前向过程中的，需要*预测*出来
      $ ept = epth (xt, t) $
      - 或者也可以说 $x0$ 是未知值（因为 $ept$ 与 $x0$ 通过加噪过程相关联，知道一个就知道了另一个，预测噪声与预测原图殊途同归）
      - 本质上其实是说：我们只想通过 $xt$（和 $t$）来预测 $xtm$，而不能依赖 $x0$（最终想要生成的结果）
      - 于是一个“异想天开”的想法是：如果能通过 $xt$ 和 $t$ 预测 $x0$，不就能消去 $p(xtm|xt, x0)$ 中的 $x0$，使得它只依赖于 $xt$ 和 $t$ 了吗？
        $
        pth (xtm|xt) &eq.delta cN (xtm; muth(xt,t), Sith(xt,t)) \
        &approx p(xtm|xt, x0 = hat(mu)_th (xt,t)) = cN (xtm; tmu(xt, hat(mu)_th (xt,t)), tsit bI)
        $
      #q[用 $xt, t$ 预估 $x0$，要是能估准的话，就直接一步到位了，用不着逐步采样了。因此可以相见，这个预估不会太准，至少开始的相当多步内都不准。*它仅仅起到了一个前瞻性的预估作用*。就是很多数值算法中的“预估-修正”思想，即我们用一个粗糙的解往前推很多步，然后利用这个粗糙的结果将最终结果推进一小步，以此来逐步获得更为精细的解 —— 苏剑林]
- *综合前向扩散与反向生成的过程如下*
  #fig("/public/assets/Reading/Generation/2025-02-28-19-47-29.png", width: 80%)
  #q[注：图里为了对称都画成了逐步进行，实际上前向扩散是一步到位的]

== 优化目标
- *生成过程*
  - 如前面所述，从一个简单高斯分布采样反转得到观测图像的一般步骤为
    $ pth(bx) = int p(bz) pth(bx|bz) dif bz $
  - 而对于 DDPM 这样逐步的过程，$x1 wave bx_T$ 都属于隐变量 $bz$，得到 DDPM 的采样生成过程
    $
    pth(x0) = int pth(x0T) dif x1T
    $
    - 其中每个 $pth(xtm|xt)$ 都为高斯分布，用同一个网络预测其均值和方差（参数共享）
      $ pth(xtm|xt) = cN (xtm; muth (xt,t), Sith (xt,t)) $
    #quote(caption: [记号])[$
      p(x0T) &= p(x0|x1) p(x1|x2) dots.c p(xtm|xt) p(xt) = p(xT) PitT p(xtm|xt) \
      q(x1T|x0) &= q(bx_T|x_(T-1)) q(x_(T-1)|x_(T-2))  dots.c q(x1|x0) = PitT q(xt|xtm) \
    $]
- *变分下界逐步推导*
  - 如前所述，原始 VAE 和 Diffusion 的 ELBO 分别为
    $
    log(pth(x0)) >= int log(frac(pth(bx,bz), q(bz|bx))) q(bz|bx) dif bz = EE_(q(bz|bx)) [log(frac(pth(bx,bz), q(bz|bx)))] \
    log(pth(x0)) >= int log(frac(pth(x0T), q(x1T|x0))) q(x1T|x0) dif x1T = EE_(q(x1T|x0)) [log(frac(pth(x0T), q(x1T|x0)))] \
    $
  - 于是我们有以下逐步推导，最终拆分为三项
    $
    cL_"VLB" &= EE_(q(x1T|x0)) [log(frac(q(x1T|x0), pth(x0T)))] \
    &= EE_q [log frac(PitT q(xt|xtm), pth(xT) PitT pth(xtm|xt))] \
    &= EE_q [-log p(xT) + sum_(t=1)^T log frac(q(xt|xtm),pth (xtm|xt))] #pin(2) \
    &= EE_q [-log p(xT) + sum_(t=2)^T log frac(q(xt|xtm),pth (xtm|xt)) + log frac(q(x1|x0),pth (x0|x1))] \
    &= EE_q [-log p(xT) + sum_(t=2)^T log (frac(q(xtm|xt,x0),pth (xtm|xt)) frac(q(xt|x0),q(xtm|x0))) + log frac(q(x1|x0),pth (x0|x1))] \
    &= EE_q [-log p(xT) + sum_(t=2)^T log frac(q(xtm|xt,x0),pth (xtm|xt)) + sum_(t=2)^T log frac(q(xt|x0),q(xtm|x0)) + log frac(q(x1|x0),pth (x0|x1))] \
    &= EE_q [-log p(xT) + sum_(t=2)^T log frac(q(xtm|xt,x0),pth (xtm|xt)) + log frac(q(xT|x0),q(x1|x0)) + log frac(q(x1|x0),pth (x0|x1))] \
    &= EE_(q(x1T|x0)) [log frac(q(xT|x0),p(xT)) + sum_(t=2)^T log frac(q(xtm|xt,x0),pth (xtm|xt)) - log pth(x0|x1)] \
    &= EE_(q(xT|x0)) [log frac(q(xT|x0),p(xT))] + sum_(t=2)^T EE_(q(xt,xtm|x0)) [log frac(q(xtm|xt,x0),pth (xtm|xt))] - EE_(q(x1|x0)) [log pth(x0|x1)] #pin(3) \
    &= underbrace(D_KL (q(xT|x0)||p(xT)), cL_T) + sum_(t=2)^T underbrace(EE_(q(xt|x0)) [D_KL (q(xtm|xt,x0)||pth (xtm|xt))], cL_(t-1)) - underbrace(EE_(q(x1|x0)) [log pth(x0|x1)], cL_0)
    $
    #pinit-point-from(2, pin-dy: -5pt, offset-dx: 30pt, offset-dy: -25pt, body-dx: 2pt, body-dy: -4pt, fill: rgb(0, 180, 255))[#bluet[这个式子也很优美，是原论文 $cL$ 的另一个表述]]
    #pinit-point-from(3, pin-dx: -50pt, pin-dy: -10pt, offset-dx: -85pt, offset-dy: -30pt, body-dx: 10pt, body-dy: -15pt, fill: rgb(0, 180, 255))[#bluet[对于函数的期望，若给出的分布有自变量\ 以外的变量，它们并不会影响函数的期望]]
    #q[注：无关变量不影响函数期望，例如 $
      EE_(q(x1T|x0))[f(xj)] &= int_(x1T) [PitT q(xt|x0)] f(xj) dif x1T \
      &= [pi_(t=1, t!=j)^T int_xt q(xt|x0) dif xt] dot int_xj q(xj|x0) f(xj) dif xj \
      &= [pi_(t=1, t!=j)^T 1] dot int_xj q(xj|x0) f(xj) dif xj \
      &= int_xj q(xj|x0) f(xj) dif xj = EE_(q(xj|x0))[f(xj)]
    $]
  - 这三项分别有自己的含义
    + $cL_T$ prior matching term: 表示最终加出来的噪声尽可能为高斯分布（先验），它没有可训练的参数，并且根据我们的假设等于零
    + $cL_0$ reconstruction term: 可以使用蒙特卡洛估计进行近似和优化（？）。论文中则是牵扯到 Data scaling 之类，没太看懂。一些资料认为这一项也是由超参所决定，可以不去管它
    + $cL_(t-1)$ denoising matching term: 最核心，它要求我们模型的预测结果跟已知 $x0$ 时的去噪真值结果尽可能一致
    - 另外可以注意到，当 $T=1$，上式完全等于传统 VAE 的 ELBO 方程
  - 现在我们来仔细 judge 这 $cL_(t-1)$ 项，导出优化目标
    - 我们已知：
      $
      q(xtm|xt,x0) &= cN (xtm; tmu(xt,x0), tsit^2 bI) \
      &= cN (xtm; 1/sqrt(al_t) (xt - frac(1-al_t,sqrt(1-oalt)) #bluet[$ept$]), #redt[$frac(1-oal_(t-1), 1-oalt) be_t bI$]) \
      pth(xtm|xt) &= cN (xtm; muth (xt,t), Sith (xt,t)) \
      &= cN (xtm; 1/sqrt(al_t) (xt - frac(1-al_t,sqrt(1-oalt)) #bluet[$epth (xt,t)$]), #redt[$Sith(xt,t)$])
      $
    - 且两个高斯分布的 KL 散度有计算公式（推导见 #link("https://zhuanlan.zhihu.com/p/387938179")[两个多元正态分布的 KL 散度、巴氏距离和 W 距离]）
      $ KL(p(bx)||q(bx)) = 1/2 [(mu_p-mu_q)^T Si_q^(-1) (mu_p-mu_q) - log det(Si_q^(-1) Si_p) + tr(Si_q^(-1) Si_p) - d] $
    - 于是我们得到（为简洁起见，高斯参数的自变量省略）
      $
      D_KL (q(xtm|xt,x0)||pth (xtm|xt)) = 1/2 [(tmu-muth)^T Si_th^(-1) (tmu-muth) - log frac((tsit^2)^d, det Si_th) + tsit^2 tr(Si_th^(-1)) - d]
      $
      - 这个式子看起来很丑陋？但如果我们限定 $Sith(xt,t)=tsith^2 bI$（对角矩阵且各项同性），就变成
        $
        D_KL (q(xtm|xt,x0)||pth (xtm|xt)) &= 1/(2 tsith^2) norm(tmu-muth)_2^2 + 1/2 [d frac(tsit^2, tsith^2) - d - d log frac(tsit^2,tsith^2)] \
        &= frac((1 - al_t)^2, 2 tsit^2 al_t (1 - oalt)) norm(epth (xt,t)-ep_t)_2^2 + 1/2 [d frac(tsit^2, tsith^2) - d - d log frac(tsit^2,tsith^2)]
        $
      - 更进一步，DDPM 令方差为跟 $th$ 无关的常数（实验证明具体是 $tsit^2 = frac(1-oal_(t-1), 1-oalt) be_t$ 或 $tsith^2 = be_t$ 效果差别不大），于是上式右边成为跟梯度无关的常数（甚至可以是零）。问题归结为
        $ cL_(t-1) = EE_(q(xt|x0)) [frac((1 - al_t)^2, 2 tsit^2 al_t (1 - oalt)) norm(epth (xt,t)-ep_t)_2^2] $
        $
        th &= argmin_th EE_(t wave U{2,T}) [EE_(q(xt|x0)) [frac((1 - al_t)^2, 2 tsit^2 al_t (1 - oalt)) norm(epth (xt,t)-ep_t)_2^2]] \
        &= argmin_th EE_(t wave U{2,T}) {EE_(x0, ep) [frac((1 - al_t)^2, 2 tsit^2 al_t (1 - oalt)) norm(epth (sqrt(oalt) x0 + sqrt(1 - oalt) ep,t)-ep_t)_2^2]}
        $
      - 顺带一提，这里的*两种方差选择*，刚好分别是假设数据集 $p(x0)$ 服从*狄拉克函数*（单个样本）和*标准正态分布*时推导出来的结果，属于两个极端。具体推导，可以参考 #link("https://kexue.fm/archives/9164#%E9%81%97%E7%95%99%E9%97%AE%E9%A2%98")[生成扩散模型漫谈（三）：DDPM = 贝叶斯 + 去噪 By 苏剑林]
      - 如果不固定的话，也预测 $Sith$，这是后续一些不差钱的工作的做法
    - 这里推导过程比较复杂，最后就真正变成了一个 noise predictor
- *最终的损失函数*
  - 如上推导了 Standard Variational Bound，但 DDPM 最终采用的却是如下的损失函数
    $ L_"simple" = EE_(t wave U{1,T}, x0, ep) [norm(epth (sqrt(oalt) x0 + sqrt(1 - oalt) ep,t)-ep_t)_2^2] $
  - 可以看到这就是相对标准变分下界的 unweighted 版本（只考虑了 $L_0, L_(t-1)$），这可以看作是对标准版本的 reweighting，对较小的 $t$ 赋予更小的权重，让模型更关注较大的 $t$ 时更困难的去噪任务。实验表明这样做效果更好

== 训练与推理
- *训练*
  - 训练时不必枚举每个 $t$，因为已经推导出每一时刻的加噪的封闭形式，可以直接均匀随机采样（也方便并行）
  #fig("/public/assets/Reading/Generation/2025-02-28-19-54-16.png", width: 80%)
- *推理*
  - 推理时沿着马尔科夫过程反向模拟每一步（逐步进行）
  - 需要注意，模型预测的噪声实际上不是真的随机变量，可以看作是确定的值（只是均值中的一部分）而不是分布，需要加一个 $ep$ 使每一步结果都是高斯分布
  #fig("/public/assets/Reading/Generation/2025-02-28-19-55-00.png", width: 80%)
- *模型结构*
  - 使用常见的 UNet 结构
  - time embedding 为标准的位置编码方式 (sinusoidal embedding)，加到 UNet 的每个 block 的输入上
  #fig("/public/assets/Reading/Generation/2025-02-28-19-58-22.png", width: 80%)

== 总结
- 前向扩散
  $
  xt = sqrt(1 - beta_t) xtm + sqrt(beta_t) ep_(t-1) \
  xt = sqrt(oalt) x0 + sqrt(1 - oalt) ept \
  q(xt|xtm) = cN (xt; sqrt(1 - beta_t) xtm, beta_t bI) \
  q(xt|x0) = cN (xt; sqrt(oalt) xt, (1 - oalt) bI) \
  al_t = 1 - beta_t, ~~ oalt = inline(Pi_(i=1)^t) al_i
  $
- 反向生成
  $
  q(xtm|xt,x0) &= cN (xtm; tmu(xt,x0), tsit^2 bI) = cN (xtm; 1/sqrt(al_t) (xt - frac(1-al_t,sqrt(1-oalt)) #bluet[$ept$]), #redt[$frac(1-oal_(t-1), 1-oalt) be_t bI$]) \
  pth(xtm|xt) &= cN (xtm; muth (xt,t), Sith (xt,t)) = cN (xtm; 1/sqrt(al_t) (xt - frac(1-al_t,sqrt(1-oalt)) #bluet[$epth (xt,t)$]), #redt[$Sith(xt,t)$])
  $
- 推导路线总结
  $ p(xt|xtm) -->^"推导" p(xt|x0) -->^"推导" p(xtm|xt,x0) -->^"近似" p(xtm|xt) $
- DDPM
  + 是一类生成模型，输入是标准高斯噪声，输出是图片
  + 相对 GAN 稳定易训练
  + 生成过程不是一步到位的，是需要迭代的【耗时】
  + 的输入和输出尺寸是一致的【耗资源耗时】
  - 针对*耗时*的问题：许多加速采样的方法应运而生，目的是降低迭代的次数
  - 针对*耗资源*的问题：LDM (latent diffusion model) 提出把 Diffusion Model 做到 VAE 的 encoder 输出上，降低每次迭代的计算量（而且本身数字图像的大多数像素都用来描述细节，在像素空间做 Diffusion 存在大量冗余）
- Diffusion 为什么*爆火*，除了其本身效率的原因外，还有
  - SD 跟*微调 (LoRA)* 的适配度较好
  - 开源社区的支持，尤其是 *ControlNet*

= 更深入的理解
== 数学原理背景
- VLB 和 ELBO
  - [ ] ……
- ODE 和 SDE
  - [ ] ……

== VAE 和 DDPM
- 从 VAE 的角度看 DDPM
  - 前向扩散过程即为 encoder，反向去噪过程即为 decoder
  - 通过多步微调的方式变相增强了模型复杂度
    - VAE 只过一次前向，模型复杂度为 $O(N)$，而 DDPM 通过参数共享达到 $O(T N)$
    - 这既是优点也是缺点，模型复杂度高了时间复杂度也随之上升；但逐步的方式允许它慢慢达到更好的效果（而且每一步只预测噪声而非图片，利用了高斯分布适合神经网络预测这一特性）
  - 自回归式的 VAE 彰显出 auto-regressive 的优势
- [ ] 马尔可夫链……

== VDM 的三种等价形式
- 宋飏博士将这类扩散模型称为 Variational Diffusion Model (VDM)，并提出了三种等效的优化 VDM 目标
  + 学习神经网络预测原始图像 $x0$
  + 学习神经网络预测噪声 $ept$，这也是 DDPM 和上面我们推导的形式
  + 一定噪声水平下的图像得分函数$nabla_xt log p(xt)$
  #q[学艺不精的时候我以为是从 $xt$ 预测噪声和预测 $xtm$ 两种*并列*（类似 ResNet 的关系），现在才明白其实前者是*为了*后者（这三种方式都是*为了*从 $xt$ 预测 $xtm$）]
- 三种版本都来自对下式的不同推导
  $
  cL_(t-1) &= EE_(q(xt|x0)) [KL (q(xtm|xt,x0)||pth (xtm|xt))] \
  &= EE_(q(xt|x0)) [1/(2 tsith^2) norm(tmu-muth)_2^2 + 1/2 (d frac(tsit^2, tsith^2) - d - d log frac(tsit^2,tsith^2))] \
  &= 1/(2 tsith^2) EE_(q(xt|x0)) [norm(tmu-muth)_2^2] + C
  $
  + 用如下代换推出*原始图像 $x0$ 形式*
    $
    tmu^(#cnum(1))(xt,x0) = frac(sqrt(al_t) (1-oal_(t-1)) xt + sqrt(oal_(t-1)) (1-al_t) x0, 1-oalt) \
    muth^(#cnum(1))(xt,t) = frac(sqrt(al_t) (1-oal_(t-1)) xt + sqrt(oal_(t-1)) (1-al_t) x_th (xt,t), 1-oalt) \
    cL_(t-1) = 1/(2 tsith^2) frac(oal_(t-1) (1-al_t)^2, (1-oalt)^2) EE_(q(xt|x0)) [norm(x0 - x_th (xt,t))_2^2] + C
    $
  + 用如下代换推出*噪声 $ept$ 形式*
    $
    tmu^(#cnum(2))(xt,x0) = 1/sqrt(al_t) (xt - frac(1-al_t,sqrt(1-oalt)) ept) \
    muth^(#cnum(2))(xt,t) = 1/sqrt(al_t) (xt - frac(1-al_t,sqrt(1-oalt)) epth (xt,t)) \
    cL_(t-1) = 1/(2 tsith^2) frac((1 - al_t)^2, al_t (1 - oalt)) EE_(q(xt|x0)) [norm(epth (xt,t)-ep_t)_2^2] + C
    $
  + 用如下代换推出*得分函数 $nabla_xt log p(xt)$ 形式*
    $
    tmu^(#cnum(3))(xt,x0) = 1/sqrt(al_t) xt + frac(1-al_t,sqrt(al_t)) na_xt log p(xt) \
    muth^(#cnum(3))(xt,t) = 1/sqrt(al_t) xt + frac(1-al_t,sqrt(al_t)) s_th (xt,t) \
    cL_(t-1) = 1/(2 tsith^2) frac((1 - al_t)^2, al_t) EE_(q(xt|x0)) [norm(s_th (xt,t)-na_xt log p(xt))_2^2] + C
    $
- 第二种替换就是前面 DDPM 介绍过的做法，第一种则只需要注意到加噪时 $x0$ 与 $ept$ 的共通性即可，但第三种形式需要介绍一下
  - 对于满足高斯分布的变量 $bz wave cN (bz; bmu_bz, Si_bz)$，Tweedie 公式如下
    $ EE[bmu_bz|bz] = bz + Si_bz na_bz log p(bz) $
  - 由 $q(xt|x0) = cN (xt; sqrt(oalt) x0, (1 - oalt) bI)$ 我们知道已知 $x0$ 情况下 $xt$ 的后验均值，带入得到
    $ x0 = (xt + (1 - oalt) na_xt log p(xt)) / sqrt(oalt) $
  - 于是就可以将该式带入我们在第一种形式中用到的 $tmu^(#cnum(1))(xt,x0)$ 进而化简得到 $tmu^(#cnum(3))(xt,x0)$ 了，具体计算从略
  - 另外，我们能以 $x0$ 为桥梁将噪声 $ept$ 与得分函数 $nabla_xt log p(xt)$ 联系起来
    $
    x0 = (xt - sqrt(1 - oalt) ept) / sqrt(oalt) &= (xt + (1 - oalt) nabla_xt log p(xt)) / sqrt(oalt) \
    na_xt log p(xt) &= - frac(1, sqrt(1 - oalt)) ept
    $
    - 事实证明，这两个术语存在一个随时间变化而缩放的常数差！得分函数测量了在数据空间中如何移动以最大化对数概率。直观地说，由于源噪声被添加到自然图像中以污染它，因此向反方向移动会"去噪声"，并且将是提高后续对数概率的最佳更新。而我们的数学证明证实了这种直觉：学习模拟得分函数等价于模拟源噪声的相反数（差一个缩放因子）

== Score-based Generative Model
上一节中，我们通过 Tweedie 公式简单地推出可以通过优化神经网络 $s_th (xt,t)$ 来预测得分函数 $na_xt log p(xt)$ 可以用来学习变分扩散模型。但是其实我们并未对得分函数有很深的理解，也无法解释为什么模拟得分函数值得研究。甚至到目前为止，我们连为什么叫它得分函数都不知道。因此先来探索更一般的 Score-based Generative Model，甚至溯源回 Energe-based Generative Model。

=== Energy-based Models
论及生成模型，最直接也是之前最普遍使用的思路就是 likelihood-based models，直接建模目标数据的分布，然后在这个数据分布中采样就可以得到生成的新数据。基于这种想法，如果设待建模数据是一个连续型随机变量，那就可以通过建模该随机变量的概率密度函数来进行生成。

#q[直接设为连续型随机变量其实包含了对世界的连续性的假设]

但有时概率密度函数是难以捉摸的，就像 Diffusion Model 这里也是，我们并非直接建模概率密度函数，而是建模从高斯密度函数到它的转换。Energy-based Models (EBM) 是 Yann Lecun 提出的一种希望统括 ML/DL 的模型框架。它认为模型只需要建模一个能量函数 $F(x,y)$ 衡量 $x$ 和 $y$ 的相容性 (compatibility)，从能量函数出发再进一步处理就可以得到最终想要建模的概率密度函数。

能量函数（相容性度量）$F(x,y)$ 中 $x$ 是观测变量，$y$ 是待预测变量（举视频生成的例子，若 $x$ 是已有的视频帧，$y$ 就是待生成的视频帧），我们希望 $y$ 尽可能与 $x$ 相融，即能量函数 $F(x,y)$ 尽可能小。如果模型很好地学到了这个能量函数，在推断时就可以通过下式得到与所给数据最相容的预测 $y$。
$ y^* = argmin_y F(x,y) $

将 $x$ 学成函数后，给定 $y$ 输出一个相容性 $f_th (y)$，衡量了 $y$ 出现在 $x$ 的分布中的“概率”。我们也可以更直观地写出能量函数与概率密度的关系（这在实践中更常用）：
  $ pth (bx) = frac(e^(-f_th (bx)), bZ_th) $
其中，$bZ_th$ 就是一个归一化项，使得 $pth$ 满足概率密度函数的基本要求 $int pth (bx) dif bx = 1$。因此，这里说的 EBM 也被称为未归一化的概率模型 (unnormalized probabilistic model)。

=== Challenges of EBM & Introduction to Score-based Model
- 那么这样一个 EBM 该如何训练？可以仍然用似然模型的框架，通过最大化训练集的对数似然以训练 $pth(bx)$
  $ max_th log pth (PiiN bx_i) = max_th log PiiN pth(bx_i) = max_th sumiN log pth(bx_i) $
  - 但对于复杂的 $f_th (bx)$ 函数，归一化常数 $bZ_th$ 或许是难以计算的，有两种常见的妥协方式：
    + 限制网络结构，如自回归 CNN 中的因果卷积 (causal convolution) 和归一化流模型 (normalizing flow models) 中的可逆网络
    + 近似计算 $Z(th)$，如 VAE 中的变分推断和对比散度 (contrastive divergence) 中的马尔科夫链蒙特卡洛 (Markov Chain Monte Carlo, MCMC) 采样，往往需要较高的计算量代价
- 为了避免求取 $Z(th)$ 的麻烦，Score-based Model 在和基于似然的模型的同一层次上，将原本的建模 $p(bx)$ 转为去建模一个称为 score 的 $s(bx) = na_bx log pth(bx)$
  - 这是因为观察到上式两侧取对数再导数为
    $
    na_bx log pth(bx) &= na_bx log (1/bZ_th) + na_bx log e^(- f_th (bx))) \
    &= - na_bx f_th (bx) \
    &approx s_th (bx)
    $
  - 可以看到它可以自由地表示为神经网络，而不涉及任何归一化常数
- 得分函数代表什么意义？
  - 对于每个 $bx$，取其对数似然相对于 $bx$ 的梯度，本质上描述了移动到哪个方向可以进一步增加似然。因此，从直觉上说，得分函数在数据 $bx$ 所在的整个空间上定义了一个朝向着模式（mode，指混合分布中的一个单独分布）的向量场
  - 然后，通过学习真实数据分布的得分函数，我们可以通过在同一空间中的任意点开始，跟随得分函数迭代到达某个模式来生成样本。这个采样过程被称为 *Langevin 动力学*（朗之万动力学），并且在数学上被描述为:
    $ bx_(i+1) <- bx_i + c na log p(bx_i) + sqrt(2c) ep, ~~~~ i = 0, 1, dots.c, K $
  - 其中 $bx_0$ 是从先验分布（如均匀分布）随机抽样得到的，而 $ep wave cN(bold(0), bI)$ 是额外的噪声项，以确保生成的样本不总是塌陷到一个模式上，而是在其周围游走，以获得更多多样性。而且能避免由于学习出的确定性的得分函数导致的确定性轨迹。当采样从处于多个模式之间的位置初始化时，这种随机性尤其有用
- 得分函数应该怎么学呢？
  - 可以通过最小化 Fisher 散度与真值得分函数来优化：
    $ EE_(p(bx)) [norm(s_th (bx) - na log p(bx))_2^2] $
  - 但真实得分函数我们不一定能得到（比如模拟自然图像分布这样复杂的分布而言）。幸运的是，已经有一些称为*得分匹配* (score matching) 的替代技术，可以在不知道真实得分函数的情况下最小化 Fisher 散度，并可以用随机梯度下降进行优化
#fig("/public/assets/Reading/Generation/2025-03-06-21-25-19.png", width:70%)
- 这种通过得分函数来学习表示分布、通过马尔科夫链蒙特卡洛技术 (e.g. Langevin 动力学) 生成样本的方法，被称为 *Score-based Generative Modeling*，它有三个主要问题：
  + 当 $bx$ 处于高维空间中的低维流形上时，得分函数未定义
    - 从数学上看，不在低维流形上的所有点的概率都为零，其对数是未定义的
    - 这在尝试学习自然图像的生成模型时特别不方便，因为自然图像被认为位于整个环境空间的低维流形上
  + 通过一般的得分匹配方法训练的估计得分函数在低密度区域中将不准确
    - 因为我们要最小化的目标是对 $p(bx)$ 的期望，并且明确地在其样本上训练，模型在少见或未见样本上无法获得准确的学习信号
    - 这个问题很大，因为我们的采样策略是从高维空间中的随机位置开始根据学习的得分函数移动，这个位置很可能是随机噪声。由于我们遵循的是嘈杂或不准确的得分估计，最终生成的样本也可能不够优化，或者需要更多迭代才能收敛到准确的输出
  + 即使使用真实的得分进行 Langevin 动力学采样，也可能无法混合
    - 假设真实数据分布是两个不相交分布的混合
      $ p(bx) = c1 p_1 (bx) + c2 p_2 (bx) $
    -  然后，在计算得分时，这些混合系数会丢失，因为对数运算将系数从分布中分离出来，并且梯度运算将其置零
- 事实证明，通过向数据*添加多层高斯噪声*可以同时解决这三个缺点！
  + 由于高斯噪声分布的支持是整个空间，扰动后的数据样本将不再限于低维流形
  + 添加大量的高斯噪声会增加每个模式在数据分布中的覆盖范围，在低密度区域添加更多训练信号
  + 通过添加方差递增的多层高斯噪声，可以得到对应于真实混合系数的中间分布
  - 形式上，我们可以选择一个噪声水平为 ${sit}^T_(t=1)$ 的正序列，并定义一个渐进扰动数据分布序列
    $ p_(sit) (bx_t) = int p(bx) cN (bx_t; bx, sit^2) dif bx $
  - 然后，使用得分匹配学习神经网络 $s_th (bx, t)$，以同时学习所有噪声水平的得分函数
    $ argmin_th sumtT la(t) EE_(p_sit(bx)) [norm(s_th (bx) - na_bx log p_sit (bx))_2^2] $
    - 其中，$la(t) > 0$ 为对噪声水平 $t$ 施加的权重
  - 注意到了吗？这与基于变分扩散模型训练推导出的*目标公式几乎完全相同*！
  - 此外，作者提出了一个通过退火 Langevin 动力学采样的生成过程
    + 其中样本是按顺序在每个 $t = T,T-1,dots.c,2,1$ 上运行 Langevin 动力学来生成的
    + 初始化是从某个固定先验（例如均匀分布）中选择的，并且每个后续的采样步骤都从前一个仿真的最终样本开始
    + 由于随着时间步长 $t$ 的减小噪声水平逐渐降低，我们逐渐减小步长大小，样本最终会收敛到真实模式
    - 这与变分扩散模型的马尔可夫 HVAE 解释中执行的*采样过程直接类似*（随机初始化的数据向量经过逐渐减小的噪声水平迭代地进行改进）
  - 基于此，我们在训练目标和采样过程上建立了 VDM 和 Score-based Generative Model 之间的明确联系
- 还有一个问题是如何自然地将扩散模型推广到无限数量的时间步骤
  - 在马尔可夫 HVAE 视图下，这可以解释为将层次数扩展到无穷大$T -> infty$
  - 从等价的基于得分的生成模型的观点来看能更清晰地表示这一点：在无限数量的噪声尺度下，图像随时间的连续变化可以被表示为一种随机过程，因此可以用随机微分方程 (SDE) 描述。采样是通过反向求解 SDE 进行的，这自然要求在每个连续值噪声水平处估计得分函数。SDE 的不同参数化基本上描述了随时间的不同扰动方案，使得对噪声过程的灵活建模成为可能
- 原文后续还有对 Classifier Guidance 和 Classifier-Free Guidance 的讨论，这里略去

=== 统一视角理解扩散模型的总结
- 文章脉络
  + 首先，将变分扩散模型推导为马尔可夫层级变分自动编码器的特例，其中三个关键假设使计算可行并实现了对 ELBO 的可扩展优化
  + 接下来，证明优化 VDM 归结为学习一个神经网络以预测三个潜在目标之一：从任意噪声源噪声化的图像中还原出原始源图像、从任意加噪的图像中还原出原始噪声源，或者是任意噪声水平下加噪图像的评分函数
  + 然后，深入探讨了学习评分函数的含义，并将其明确地与基于评分的生成建模的观点联系起来
  + 最后，介绍了如何使用扩散模型学习条件分布
- 扩散模型展示了生成模型不可思议的能力，并且支撑这些模型的数学方法非常优雅，但也有一些缺点
  + 对于我们人类来说，这不太可能是自然建模和生成数据的方式；我们不会将样本生成为随机噪声，然后迭代地去噪
  + 变分扩散模型无法产生可解释的潜变量。如果说一个 VAE 通过优化其编码器来学习一个结构化的潜空间，那么在变分扩散模型中，每个时间步的编码器已经被设定为线性高斯模型，不能进行灵活优化。因此，中间的潜变量仅仅是原始输入的嘈杂版本
  + 潜变量受限于与原始输入相同的维度，进一步阻碍了学习有意义、压缩的潜变量结构的努力
  + 采样是一个开销较大的过程，因为在两种形式下都必须运行多次去噪步骤
- 最后要注意，扩散模型的成功凸显了分层变分自编码器 HVAE 作为生成模型的能力
  - 我们已经证明，当推广到无限潜层次时，即使编码器是微不足道的、潜变量维度是固定的，并且假设马尔可夫转换，我们仍然能够学习到强大的数据模型
  - 这表明，在一般情况下，深层 HVAE 可能会取得进一步的性能提升，其中复杂的编码器和具有语义意义的潜空间可能会被学习出来
