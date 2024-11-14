---
order: 2
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "AI 笔记之强化学习",
  lang: "zh",
)


= 价值学习
== 价值估计
=== 蒙特卡洛方法
在现实问题中，通常不能假设对环境有完全了解，即无法明确地给出*状态转移和奖励函数*（例如，围棋的状态空间约为 $10^768$ 的大小）。因此需要一种*直接从经验数据*中学习价值和策略，无需构建马尔可夫决策过程模型的方法。

蒙特卡洛方法在强化学习中的基本思想是通过多次采样来估计状态或动作的值函数，随后利用*值函数*进行策略改进

- 目标：从策略 $pi$ 采样的历史经验中估计 $V^pi$
- 累计奖励(return)是总折扣奖励 $G_t = R_(t+1) + gamma R_(t+2) + dots + gamma^(T-1)R_T$
- 值函数(value function)是期望累计奖励 $V^pi(s) = E[R(s_0)+gamma R(s_1) +dots |s_0=s,pi] = E[G_t|S_0 = s,pi] approx 1/N sum_(i=1)^N G_t^i$

#note(caption: "总结")[
  + 直接从经验回合进行学习，不需要模拟/搜索
  + 模型无关(model-free)，无需环境信息
  + 核心思想简单直白：value = mean return
  + 使用完整回合进行更新（缺陷）：只能应用于有限长度的马尔可夫决策过程，即所有的回合都应有终止状态
]

=== 时序差分方法
$ G_t = R_(t+1) + gamma R_(t+2) + dots + gamma^(T-1)R_T = R_(t+1) + gamma G_(t+1)\
V(s_t) = V(s_t) + alpha [G_t - V(s_t)] = V(s_t) + alpha [R_(t+1) + gamma V(s_(t+1)) - V(s_t)]
$
- 时序差分方法（Temporal Difference methods，简称 TD）能够直接使用经验回合学习，同样也是模型无关的
- 与蒙特卡洛方法不同，时序差分方法结合了自举(bootstrapping)，能从不完整的回合中学习
- 时序差分通过更新当前预测值，使之接近估计出来的累计奖励，而非真实累计奖励

#note(caption: "时序差分 v.s. 蒙特卡洛")[
  - 时序差分方法能够在每一步之后进行在线学习，蒙特卡洛方法必须等待回合终止，直到累计奖励已知
  - 时序差分方法能够从不完整的序列中学习，蒙特卡洛方法只能从完整序列中学习
  - 时序差分方法能够应用于无限长度的马尔可夫决策过程，蒙特卡洛方法只适用于有限长度
  #set grid.cell(align: center+horizon)
  #grid(columns: (1fr, 1fr),row-gutter: 8pt,
    [时序差分方法],[蒙特卡洛方法],
    [$ V(s_t) <- V(s_t) +\ alpha(R_(t+1)+gamma V(s_(t+1))-V(s_t)) $],[$ V(s_t)<-V(s_t)+alpha(G_t - V(s_t)) $],
    [- 低方差，有偏差
      - 更高效
      - 最终收敛到 $V^pi$
      - 对初始值更敏感
    ],
    [- 高方差，无偏差
      - 良好收敛性
      - 对初始值不敏感
      - 易于理解和使用
    ],
  )
]

=== 资格迹方法
- 为了实现方差与偏差的平衡，一种可行的方案是将蒙特卡洛方法与时序差分方法融合，实现*多步时序差分*，介于时序差分方法和蒙特卡洛方法（等效于无限步时序差分）之间。在此基础上提出*资格迹方法*，而 TD-$lambda$ 是一种比较常见的资格迹方法
- $n$ 步时序差分学习
$
"定义 " n " 步累计奖励" ~~~ G_t^n = R_(t+1) + gamma R(t+2) + dots + gamma^(n-1) R_(t+n) + gamma^n V(s_(t+n))\
V(s_t) <- V(s_t) + alpha(G_t^n - V(s_t))
$
- 资格迹方法(TD-$lambda$方法)通常使用一个超参数$lambda in [0, 1]$控制值估计蒙特卡罗还是时序差分
  - TD-$lambda$方法 把 $n$ 从 $1$ 到 $infty$ 做加权和，从而在 $n$ 步时序差分方法上更进一步
  - 当$lambda = 1$等价于蒙特卡罗方法，当$lambda = 0$等价于时序差分方法
$
"定义 " n " 步累计奖励" ~~~ G_t^n = R_(t+1) + gamma R(t+2) + dots + gamma^(n-1) R_(t+n) + gamma^n V(s_(t+n))\
G_t^lambda = (1-lambda)sum_(n=1)^infty lambda^(n-1)G_t^n
$
- TD-$lambda$ 的两种视角
#grid2(
  fig("/public/assets/AI/AI_RL/img-2024-07-10-14-21-56.png"),
  fig("/public/assets/AI/AI_RL/img-2024-07-10-14-22-17.png")
)

== SARSA & Q-learning
- SARSA是一种针对表格环境中的*时序差分*方法，其得名于表格中的内容（状态-动作-奖励-状态-动作）
- SARSA的策略评估为更新状态-动作值函数$ Q(s_t,a_t)<-Q(s_t,a_t)+alpha(R_(t+1)+gamma Q(s_(t+1),a_(t+1))-Q(s_t,a_t)) $
- SARSA的策略改进为 $epsilon-"greedy"$
- 在线策略时序差分控制(on-policy TD control)使用当前策略进行动作采样，即SARSA算法中的两个动作“A”都是由当前策略选择的

- Q-learning学习状态动作值函数 $Q(s, a) in RR$，是一种离线策略(off-policy)方法
$
Q(s_t, a_t)=sum_(t=0)^T gamma^t R(s_t,a_t), ~~~ a_t wave mu(s_t)
$
- 为什么使用离线策略学习
  - 平衡探索（exploration）和利用（exploitation）
  - 通过观察人类或其他智能体学习策略
  - 重用旧策略所产生的经验
  - 遵循一个策略时学习多个策略
- 具体实现
  - 使用行为策略$mu(dot|s_t)$选择动作$a_t$
  - 使用当前策略$pi(dot|s_(t+1))$选择后续动作$a'_(t+1)$，计算目标 $Q'(s_t, a_t) = R_t + gamma Q(s_(t+1),a'_(t+1))$

#hline()
- 总结：SARSA 中新的 $Q(s,a)$ 通过当前策略得到，而 Q-Learning 通过 $max_a Q(s,a)$ 选取，除此之外代码上非常类似

== DQN
=== 经典 DQN
- 回顾表格式 Q-Learning
#mitex(`Q(s,a)\leftarrow Q(s,a)+\alpha(r+\gamma ~ max\limits_{a^{\prime}\in A} Q(s^{\prime},a^{\prime})-Q(s,a))`)
- 如果我们将表格式的$Q(s, a)$的取值用神经网络代替，且该网络以“状态+行为作为输入，该状态行为价值作为输出”（或者，“状态作为输入，该状态的所有行为空间作为输出然后取最大值”），那么 Q-learning 算法就可以直接扩展为 DQN 学习
  - 状态价值网络：$Q_omega (s,a)$
  - 时序差分目标：$r + gamma display(max_a') Q_omega (s',a')$
  - 给定一组状态转移数据：${(s_i,a_i,r_i,s'_i)}$，DQN 的损失函数构造为均方误差形式：#mitex(`\omega^{*}=\operatorname{argmin}\limits_{\omega}\frac{1}{2N}\sum_{i=1}^{N}\left[Q_{\omega}(s_{i},a_{i})-\left(r_{i}+\gamma\operatorname*{max}_{a^{\prime}} Q_{\omega}(s_{i}^{\prime},a^{\prime})\right)\right]^{2}`)
- 训练时，有两种方法：*fitted Q 值迭代*和*在线 Q 值迭代算法*
  - 两种方法都有一些问题
    + 神经网络训练需要独立同分布数据，但是状态转移数据强相关；
    + 更新神经网络参数并不是梯度下降，$y_i$的计算也更新梯度（target 和神经网络双向奔赴）；
    + Q 值的更新不稳定
  - 第一个通过并行 Q-learning（同步或异步）解决，但更好的策略是*经验回放缓存*
  - 第二第三个通过*目标网络*解决
- 最后得到经典 DQN 网络
#fig("/public/assets/AI/AI_RL/img-2024-07-04-16-11-51.png")

=== Double DQN
- 经典 DQN 的问题：过高估计 Q 值（原因，噪声导致最大值的期望大于期望的最大值）
- 引出 Double DQN，使用两个网络减少随机噪声的影响，恰巧，我们就有*目标网络*($omega^-$)和*当前策略网络*($omega$)这两个网络，分别用于计算TD目标值、选择行为
  #fig("/public/assets/AI/AI_RL/img-2024-07-04-16-20-27.png")
- 其算法流程
#algo(title: [*Algorithm:* DDQN])[
  - 算法输入：迭代轮数$T$，状态特征维度$n$，动作集$A$,步长$alpha$，衰减因子$gamma$，探索率$epsilon$，当前网络$Q$，目标网络$Q'$，批量梯度下降的样本数$m$,目标网络参数更新频率$C$
  - 算法输出：$Q$网络参数
  + 随机初始化所有的状态和动作对应的价值$Q$，随机初始化当前网络$Q$的参数，目标网络$Q'$的参数$w'=w$。清空经验回放集合$D$
  + for $i$ from $1$ to $T$, do:
    + a) 初始化$S$为当前状态序列的第一个状态，拿到其特征向量$phi(S)$
    + b) 在$Q$网络中使用$phi(S)$作为输入，得到$Q$网络的有动作对应的$Q$值输出。用$epsilon-"greedy"$法在输出中选择对应的动作$a$
    + c) 在状态$S$执行当前动作$a$，得到新状态$S'$对应的特征向量$phi(S')$和奖励$R$,是否终止状态`is_end`
    + d) 将${phi(S), a, R, phi(S'), "is_end"}$这个五元组存入经验回放集合$D$
    + e) 令 $S = S'$
    + f) 从经验回放集合$D$中采样$m$个样本${phi(S_j), a_j,R_j,phi(S'_j),"is_end"_j},j = 1,2,dots,m$，计算当前目标$Q$值$y_j$ $ y_j = cases(R_j\, &"is_end"_j = "True", R_j + gamma Q'(phi(S'_j)\, arg max_a' Q(phi(S'_j)\,a\, w)\, w')\, & "is_end"_j = "False") $
    + g) 使用均方差损失函数$1/m sum_(j=1)^m (y_j-Q(phi(S_j),a_j,w))^2$，通过神经网络的梯度反向传播来更新$Q$网络的所有参数$w$
    + h) 如果 `i % C == 1`，则更新目标网络参数$w' <- w$
    + i) 如果 $S'$ 是终止状态，则当前轮迭代完毕，转到2，否则转到3
    - 注意，上述的 f 步和 g 步的 $Q$ 值计算也都需要通过 $Q$ 网络计算得到。另外，实际应用中，为了算法较好的收敛，探索率 $epsilon$ 需要随着迭代的进行而变小。
]

=== Dueling DQN
  - 将原来的$Q$网络拆分成两个部分：$V$网络和$A$网络
    + $V$网络：以状态为输入、以实数为输出的表示状态价值的网络；
    + $A$网络：优势网络，它用于度量在某个状态$s$下选取某个具体动作$a$的合理性，
  - 它直接给出动作$a$的性能与所有可能的动作的性能的均值的差值。如果该差值(优势)大于$0$，说明动作$a$优于平均，是个合理的选择；如果差值(优势)小于$0$，说明动作$a$次于平均，不是好的选择；
  - 一般来说：$Q(s,a) = V(s) + A(s, a)$
  - 这两个网络可以设计成完全独立，也可以共用一大部分，最后用全连接层区分。如下左图，假设状态输入为图像，用 CNN 做前置处理，然后分别全连接得到 $V$ 和 $A$
  #grid2(
    fig("/public/assets/AI/AI_RL/img-2024-07-04-16-31-52.png"),
    fig("/public/assets/AI/AI_RL/img-2024-07-04-16-34-33.png")
  )
  - 为什么要这样拆呢？分辨当前的价值是由状态价值提供还是行为价值提供，进而有针对性的更新，增加样本利用率。如上右图中，当前方有车时，不同$a$应有不同的优势价值$A_theta (s,a)$；而$V(s)$则更关注远方的目标
  #fig("/public/assets/AI/AI_RL/img-2024-07-04-16-47-05.png")
  - 最后这个实际使用时的替代没什么理论依据，纯粹是实证效果好

=== 优先经验回放池PER
- 一般来说，具有较大TD误差的样本应该给予更高的优先级，有两种方法
  + 采样第$t$个样本的概率$p$正比于TD误差$delta$: $p_t prop |delta_t| + epsilon$，其中$epsilon$是一个小正数，防止采样概率为$0$。
  + 采样第$t$个样本的概率$p_t$反比于TD误差在全体样本中的排位$"rank"(t)$: $p_t prop 1/"rank"(t)$
  - 第二种方法相对于第一种针对异常数据更鲁棒，过大或过小的异常点不影响其排位。
- 除了更改每个样本的采样概率之外，还需要相应调整样本的学习率，具有高优先级的样本使用较低的学习率
  - 引入参数$beta in [0,1]$来调整各个样本的学习率$alpha$：$alpha_t <- alpha dot (n p_t)^(-beta)$，其中 $n$ 为样本数目。当均匀采样时 $p_i$ 均为 $1/n$，所有样本的学习率均为原始的 $alpha$，回到普通情况。

#hline()
- 其它优化方法
  + 在蒙特卡洛方法和时序差分中平衡
  + 噪声网络
  + 分布式 Q 学习
  + Rainbow