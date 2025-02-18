---
order: 2
draft: true
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Diffusion Model",
  lang: "zh",
)

- 参考
  + #link("https://kexue.fm/tag/%E6%89%A9%E6%95%A3/4/")[生成扩散模型漫谈（苏剑林）]
  + #link("https://www.bilibili.com/list/watchlater?oid=1053831517&bvid=BV19H4y1G73r")[【较真系列】讲人话-Diffusion Model全解(原理+代码+公式)]、#link("https://www.bilibili.com/list/watchlater?oid=113497413322062&bvid=BV1wkU6Y7EiT")[【串讲系列】讲人话-Stable Diffusion全解（原理+代码+公式）之SDXL]
  + #link("https://zhuanlan.zhihu.com/p/11228697012")[零推导理解 Diffusion 和 Flow Matching]

= 生成模型
- 生成模型是 “涌现” or “幻觉”，常见的 text-conditioned 生成模型是 “言出法随”。下面讨论不带条件的（最基本的）生成模型
- 定义：一个能随机生成*与训练数据一致*的样例的模型
- 问题：如何对训练数据建模？如何采样？
- 思路：从一个简单分布（对其采样是容易的）变换到观测数据分布（这个变换是可以拟合的）
  - encoder: 从观测数据分布映射到简单分布，记作 $q(z|x)$
  - decoder: 从简单分布映射到观测数据分布，记作 $p_th (x)$
  - 训练时需要 encoder 和 decoder，推断时只需要 decoder
- 这个简单分布采用*高斯分布*
  - Why? 回忆*高斯混合模型*，一个复杂分布可以用多个高斯分布来表示
    $ P_th (x) = sumiK P(z_i) P_th (x|z_i) $
  - 为了避免设置 $K$ 作为超参，把 $z$ 表示为连续的高斯分布（即*高斯个高斯分布*）
    $ P_th (x) = int P(z) P_th (x|z) dif z $
- 如何求 $th$，使用极大似然估计

= DDPM
- *前向扩散过程 (forward diffusion process)* $P(z|x), P(x_T|x_0)$
  $
  x_t = sqrt(1 - beta_t) x_(t - 1) + sqrt(beta_t) ep_(t - 1) \
  x_t = sqrt(overline(al)_t) x_t + sqrt(1 - overline(al)_t) ep
  $
  $
  q(x_t|x_(t - 1)) wave NN (x_t; sqrt(1 - beta_t) x_(t - 1), beta_t bI) \
  q(x_t|x_0) wave NN (x_t; sqrt(overline(al)_t) x_t, (1 - overline(al)_t) bI)
  $
  - 重参数化采样：从 $x_0$ 逐步推向 $x_T$，已知的 $x_(t-1)$ 作为固定偏置，结果就是一个均值比较奇怪的高斯分布（沾上一点高斯就变成了高斯），并且我们可以通过系数来操控每一步以及最后的高斯的均值与方差
    - 两个独立高斯分布的和依然是高斯分布，且均值为二者均值的和、方差为二者方差的和
- *反向生成过程 (reverse diffusion process)* $P(x|z), P(x_0|x_T)$
  - 训练时已知 $x_0$，反向生成过程也是一个确定性的过程
  $  $
- *优化目标* —— 极大似然估计，最终拆成三项
  - $L_T$ 表示最终加出来的噪声尽可能为高斯分布，通过超参数的设置保证
  - $L_0$ 表示 $x_0$ 与 $x_1$ 尽可能接近，也是由超参设置保证
  - 最核心的就是 $L_t$，它要求我们模型的预测结果跟已知 $x_0$ 的去噪真值结果尽可能一致
    - 这里推导过程比较复杂，最后就真正变成了一个 noise predictor
- 训练与推理（几张图）
  - 推理时需要注意，模型预测的噪声实际上不是真的随机变量，可以看作确定的值（只是均值中的一部分），需要加一个 $ep$ 使每一步结果都是高斯分布
- 总结
  - 前向扩散
  $  $
  - 反向生成
  $  $
  + DDPM 是一类……
  - Diffusion 为什么*爆火*，除了其本身效率的原因外，还有
    - SD 跟*微调 (LoRA)* 的适配度较好
    - 开源社区的支持，尤其是 *ControlNet*

== 更深入的理解
- 从 VAE 的角度看 DDPM
  - 前向扩散过程即为 encoder，反向去噪过程即为 decoder
  - 通过多步微调的方式变相增强了模型复杂度
    - VAE 只过一次前向，模型复杂度为 $O(N)$，而 DDPM 通过参数共享达到 $O(T N)$
    - 这既是优点也是缺点，模型复杂度高了时间复杂度也随之上升；但逐步的方式允许它慢慢达到更好的效果（而且每一步只预测噪声而非图片，利用了高斯分布适合神经网络预测这一特性）
  - 自回归式的 VAE 彰显出 auto-regressive 的优势
- VLB
- ELBO

== DDIM
- 试图解决 DDPM 推理慢的问题，在采样过程不再限制扩散过程必须是一个马尔可夫链，用小采样步数加速生成过程
- 近两年论文其实用的并不多

= Stable Diffusion
- Stable Diffusion 是什么？基于扩散模型的*文生图*模型
  - 时间线
    - ……


== LDM
- LDM (latent diffusion mofel) 与 DDPM 的关系
  + LDM = VAE + DDPM
  + ……
- classifier guidance
  - 给定 $y$ 的条件下，$p(x_(t-1)|x_t)$ 的分布是多少？根据一通推导得出
  $  $
  - 即 classifier guidance 相当于 unconditioned + 分类对抗梯度。也就是说，在原本 DDPM 的基础上，加入 $y$ 相对 $x_t$ 的梯度信息，驱使它往我们希望的方向走（均值漂移）
  - 在以上基于数学的推导基础上，由实验发现加入超参 $ga$ 可以更好地调节生成效果
  - 训练采用两阶段，输入 $x_t$ 其实由 DDPM 的超参可以得到，据此预测不同类别的概率即可
    - classifier guidance 的另一个好处就在于，因为 DDPM 一般比较大训练很慢，这个时候我们只需要调整相对小的分类器，就能让其有分类指导的能力
  - 推理时，只需要每一步算分类器相对 $x_t$ 的梯度，加到高斯分布的均值里即可
- classifier free
  - 为什么？首先一方面 classifer 的引入让 pipeline 变得复杂，大家学术上互相卷起来；另一方面就是这个分类器的输入是带噪声的 $x_t$ ，其效果可以想见不会太好
  - classifer free 是以另一种玄学方式求解上述梯度。试想，同一个模型给它两个输入，一个带 $y$ 一个不带，那么减一下就成为我们想要的那个梯度
  $  $
  - 实现上，把 $y$ 做成一个 embedding，跟 $t$ 一起加入网络即可
- text guidance
  - 跟 classifer free 一样，不管你是什么，反正就是个条件，做成输入融进网络即可（大道至简）
    - [ ] 其实还是有一些数学原理在的
  - 不过 text 的融合方式跟 class 有所不同（因为信息表现形式不同：长文本序列和单个类别），所以前面 class 通过跟 time 想加，而 text 通过在网络中加入 cross-attention
  - 网络结构上，把 text 用 CLIP 拿到 embedding 后，把原本 resblock 内的 self-attention 变成 cross-attention 即可（$K$ 和 $V$ 为 text）


== SDXL
- 相比 SD 1.5
  + ……
- SDXL-Refiner
  - 是一个*独立的图生图的去噪模型*
  - 增加了美学得分的 condition
  - 总之它的作用是优化 base 的结果，使一些细节变得更好
- 总结
  - ……

== SD 的发展与插件
- 输入模态与方式的革新，主要分为三种方式
  + 基于训练，直接重训新模态的网络，比较少见
  + 基于微调，比如 ControlNet
  + 非训练也非微调 (tuning-free)，如 InstantID
- ControlNet
  - 一种高效微调text-to-image diffusion models的方法，可以*让diffusion model学习空间条件注入信息*
  - ControlNet 冻结 stable diffusion 的参数，复用它的 encoding layers 来训练，其中复用的 encoding layers 的参数为零初始化("zero convolutions" , zero-initialized convolution layers)，确保没有有害的噪声影响微调
  - 属于比较工程性的工作