---
order: 6
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "d2l_paper",
  lang: "zh",
)

= Generative Adversarial Nets
== 摘要 & 引言 & 相关工作
- 摘要
  - 两种写法
    - 创新工作（本文）：讲清楚自己是谁？
    - 拓展工作：和别人的区别、创新
  - 提出了一种 framework（掂量这个词的份量），即Generator 和 Discriminator
    - $G$ 的目标是使 $D$ 犯错，而非常见的直接拟合数据分布
    - $D$ 的目标是分辨输入来自 $G$ 还是真实数据
    - 类似于 minimax two-player game，最终希望找到函数空间中的一个解，使 $G$ 逼近真实数据而 $D$ 无法分辨
    - 使用 MLP --> error backpropagation 训练，无需 Markov chains or unrolled approximate inference networks 近似推理过程的展开
- 引言
  - 深度学习不等于深度神经网络，我可以不用 DNN 去近似似然函数，可以有别的方法得到计算上更好的模型
  - 对 $G$ 和 $D$  做了造假者和警察的比喻
  - $G$ 的输入是随机噪音（通常为高斯），映射到任意分布。两个模型都是 MLP 所以可以通过反向传递来优化
- 相关工作
  - 版本为 NIPS final version，不同于 arxiv 早期版本其实基本没写相关工作，可能是因为作者的确是完全自己想毫无参考的，但事实上还是有一定类似工作的
  - 学习数据分布，一种想法是直接假定了数据分布是什么然后去学它的参数，另一种想法是直接学习一个模型去近似这个分布（坏处是，即使学会了也不知道究竟是什么分布），后者逐渐成为主流
  - 相关工作 VAEs
  - 相关工作 NCE (noise-contrastive estimation)
  - 相关工作 PM (predictability minimization)，GAN 几乎是它的逆向，也是一段趣事
  - 易混淆的概念 adversarial examples，用于测试算法的稳定性

== 方法
- adversarial modeling framework 在 $G$ 和 $D$ 都是 MLP 最简单直白
  - 我们设数据为 $bx$，其分布为 $p_"data" (x)$，并定义一个噪声变量，其分布为 $p_z (bz)$
  - $G$ 学习 $bx$ 上的分布 $p_g=G(bz; th_g)$，$G$ 为由 $th_g$ 参数化的 MLP 函数，使 $p_g$ 逼近 $p_"data"$
  - 定义 $D(bx; th_d)$，$D$ 为由 $th_d$ 参数化的 MLP 函数，输出标量表示输入是真实数据的概率（$1$ 为真实）
  - 定义损失函数和优化目标
  $ min_G max_D V(D,G) = EE_(bx wave p_"data" (bx)) [log D(x)] + EE_(bz wave p_z (bz)) [log (1 - D(G(bz)))] $
- 举一个游戏的例子
  - 显示器里一张 4K 分辨率 ($800w$ pixels) 的图片。每一个像素是一个随机向量，由游戏程序 $p_"data"$ 所控制。$bx$ 是一个 $800w$ 维度的多维随机变量
  - $G$ 的学习目标：生成和游戏里一样的图片。思考游戏生成图片的方式？$4K$ 图片由 $100$ 个变量控制
    + 反汇编游戏代码，找到代码生成原理 —— 困难
    + 放弃底层原理，直接构造一个约 $100$ 维的向量（这就是这里的 $bz$，a prior on input），用 MLP 强行拟合最后图片的样子
      - 好处是计算简单，坏处是不真正了解代码。看到一个图片，很难找到对应的 $bz$；只能反向操作，随机给一个 $bz$，生成一个像样的图片
  - $D$ 的学习目标，判断一个图片是不是游戏里生成的
  - $D$ 最大化 $V(D,G)$。对完美的 $D$ 而言，前一项判正，后一项判负，即 $D(bx) = 1, ~~ D(G(bz)) = 0$，上式 $V(D,G) = 0$，达到最大
  - $G$ 最小化 $V(D,G)$。对完美的 $G$ 而言，$D(G(bz)) = 1$，上式 $V(D,G) = -infty$，达到最小
- 伪代码
#algo(title: [*Algorithm 1*: 伪代码])[
+ *for* number of training iterations *do*
  + *for* $k$ steps *do*
    + Sample minibatch of m noise samples ${bz^((1)), . . . , bz^((m))}$ from noise prior pg(z).
    + Sample minibatch of m examples ${bx^((1)), . . . , bx^((m))}$ from data generating distribution $p_"data" (x)$.
    + Update the discriminator by ascending its stochastic gradient:
    - $ nabla_(th_d) 1 / m sum_(i=1)^m [log D(bx^((i))) + log (1 - D(G(bz^((i)))))] $
  + *end for*
  + Sample minibatch of m noise samples ${bz^((1)), . . . , bz^((m))}$ from noise prior $p_g(bz)$.
  + Update the generator by descending its stochastic gradient:
  - $ nabla_(th_d) 1 / m sum_(i=1)^m log (1 - D(G(bz^((i))))) $
+ *end for*
+ The gradient-based updates can use any standard gradient-based learning rule. We used momentum in our experiments.
]
- GAN 的收敛特别不稳定，因为要确保 $G$ 和 $D$ 实力相当，这也是后续很多工作的改进方向
- 另外一个小问题是说，一开始判别器 $D$ 容易训练得特别强大，导致 $log (1 - D(G(bz))) == 0$，$G$ 梯度消失无法学习，可以把 $G$ 的优化目标暂时改成 $max_G log D(G(bz))$
- 理论证明
  + 当 $G$ 固定，$D$ 的最优解就是 $D(x) = frac(p_"data" (bx), p_"data" (bx) + p_g (bx))$
  + $G$ 达到全局最优当且仅当 $p_g = p_"data"$（使用 KL 散度证明）
  + 如果 $G$ 和 $D$ 有足够的容量，并且算法中每一次迭代都让 $D$ 达到当前最优（但其实不一定有，只迭优化了 $k$ 步），那么 $G$ 确保能够收敛到最优（使用泛函分析证明）

== 实验 & 评价
- 实验结果相对来说不是那么好，但也因此给后人留了很多机会
- 优劣
  - 作者 claim 优点是没有看训练数据，因此能够生成比较锐利的边缘（？），但后来大家发现不是这样子
  - 缺点是训练困难，不好收敛
- 未来工作
  + conditional GAN
  + 学习到的近似 inference 其实可以用任意模型去蒸馏
  + 通过训练一组共享参数的条件模型，可以对所有条件进行近似建模
  + 半监督学习
  + 效率优化
- 李沐的评价
  + 无监督学习，无需标注数据。标签和数据来自真实采样 + 生成器拟合
  + 借助 $D$ 用有监督的损失函数来训练无监督，相对高效。同时也是自监督学习的灵感来源，i.e. BERT
