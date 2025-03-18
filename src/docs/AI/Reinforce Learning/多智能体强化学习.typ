---
order: 4
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "AI 笔记之强化学习",
  lang: "zh",
)

#let ba = $bold(a)$
#let bw = $bold(w)$

= MARL
- 从这一讲开始引入多智能体。之前的单智能体并不意味着场上只有一个智能体（比如围棋双方都是智能体，但认为是单智能体，也有多智能体的实现），它更多强调只有单个智能体受己方控制；而多智能体则是多个智能体相互作用，我们简单分为三类
  + 多智能体合作：最大化全队分享奖励；多智能体协调问题
  + 多智能体竞争：完全利己主义，最大化提高个人回报；零和博弈；Minimax均衡
  + 混合合作博弈：部分利己主义，平衡团队回报与个人回报；总和博弈；纳什均衡
- 博弈论简介：略
- 多智能体信用分配
- 模型：假设每个智能体都可以获取全局状态(MA-MDP)
  - 智能体：$i in I = {1,2, dots , N}$
  - 状态：$s in S$
  - 行为：$a_i in A$，联合行为：$ba =< a_1, dots, a_N >∈ A^N$
  - 状态转移函数：$P(s'|s, ba)$
  - 奖励：$r(s, ba)$
  - 折扣因子：$gamma$
  - 智能体$i$的策略$pi_i (s): S -> A$
  - 目标：搜索一个联合策略$bold(pi) = <pi_1, dots , pi>$来最大化期望累积回报$R =sum_(t=0)^infty gamma^t r_t$
  - 状态行为价值函数：$Q^pi (s, ba) = EE[R|s_0 = s, ba_0 = ba, bold(pi)]$
  - 最优策略 $pi^*(s) = argmax_ba Q^*(s, ba)$
- 模型：每个智能体只能看到全局状态的投影(Dec-POMDP)
  - 观测：$o_i in Omega$
  - 观测函数：$o_i in Omega wave O(s, i)$
  - 智能体 $i$ 的分布式策略：$pi_i (tau_i): T -> A$
    - 行为-观测历史：$tau_i in T = (Omega times A)^*$
  - 集中训练分布式执行（CTDE）：
    - 训练过程中智能体可以获取全局状态
    - 测试过程中智能体智能看到局部观测
- MARL(Multi-Agents RL) 挑战
  - 可扩展性：维度诅咒
  - 多智能体信用分配：每个智能体对整体博弈的贡献
  - 样本利用率：需要大量的交互数据
  - 受限的观测：受限传感器等，无法获取全局信息
  - 探索：指数级别的联合策略空间
- MARL 范例
  #fig("/public/assets/AI/AI_RL/img-2024-07-09-10-17-41.png",width:60%)
  - 可扩展的集中训练与分布式执行过程
  - 满足IGM原则：智能体个体最优决策即全局最优联合决策
    - 与纳什均衡矛盾？（个体最优并非全局最优）好像确实是这样的

== MARL with Factored Value Functions
- 值分解算法（线性）
  - 方法一(VDN)
  #fig("/public/assets/AI/AI_RL/img-2024-07-09-10-28-30.png",width:60%)
  - 方法二(DOP)
  #fig("/public/assets/AI/AI_RL/img-2024-07-09-10-29-09.png",width:60%)
- 线性值分解局限性
  - 有限的表征能力
  - 没有全局收敛保证

#let Qtot = $Q_"tot"$
- QMIX
  - QMIX 的思想其实与 VDN 类似，也是去中心化思想（假设个体最优即为全局最优，即 IGM 假设），不过每个智能体对群体的贡献是加权的，权重由超网络生成（即生成网络的网络）
  - 为了保证 IGM，需要限定网络参数非负，使 #Qtot 对任意 $Q_i$ 都是单调递增的。这有点像是人为转化了问题，限制了解法的可能性，但是确实能够保证 IGM，而且它 work
  - 不难看出，当 $pa Qtot \/ pa Q_i = 1$ 时，QMIX 退化为 VDN
  - QMIX 的模型由两大部分组成（三个网络组成），一个是 agent network，输出单智能体的 $Q_i$ 的函数，mixing network 则是以 $Q_i~(i=1 wave n)$ 作为输入，输出为联合 #Qtot。为了保证单调性，mixing network 的网络参数 $bw, bold(b)$ 通过 hypernetworks 网络计算得出，并且 hypernetworks 输出的网络权重都必须大于0，对偏置没有要求
  - 在训练上，QMIX 就是一个 MA 版本的 DQN，因此也是用 target agent network 和 target mixing network 算 $y_j$，计算它与用当前 agent network 和 mixing network 得到的 $Q_i$ 的 MSE，然后用梯度下降更新当前网络参数，隔一段时间将当前网络(eval)参数复制到 target 网络参数
  #fig("/public/assets/AI/AI_RL/img-2024-07-09-10-44-22.png",width:60%)
- QPLEX
  - 相当于 MA 版本的 DQN $->$ Dueling DQN，把 $Q$ 值改为 Advantage
  #fig("/public/assets/AI/AI_RL/img-2024-07-09-10-49-41.png",width:60%)

== 其它 MARL 方法
- 动态共享学习目标 $->$ ROMA
  - 多智能体强化学习需要更大的样本量，所以参数共享作为减少样本量的方法，对于多智能体强化学习非常重要
  - 但是用这种方法，智能体倾向于学习到均质行为策略，而实际上，不同的智能体在环境交互中往往需要异质性策略
  - 因此动态目标学习可以使智能体根据其目标最大化个体差异
  - ROMA
    - 相似角色的智能体分享相似的学习目标和分享相似的行为策略。
      - 相似角色 $<=>$ 相似子任务 $<=>$ 相似行为策略
    - 角色可以作为短期博弈轨迹的编码并嵌入到输入。
    - 智能体以对应的角色作为条件进行策略学习。
    - 智能体在不同的场景下动态更换其角色。
- 价值分解局限性 $->$ NDQ(Nearly Decomposable Q-Value Learning)
  - 不确定性：价值分解可以导致合作失调；在分布式执行的过程中也会导致行为浪费
  - 因此可以引入智能体之间的交流
  - NDQ：允许智能体间交流，但是需要最小化交流信道；智能体学习什么时候、向谁、交流什么内容
- W-QMIX
- Boosting Multi-agent Reinforcement Learning via Contextual Prompting（助教的私货）
- 上下文预测模型
- 啥也听不懂。。。

= MARL with Actor Critic
- Value-based的算法的核心是要估准每个状态-行为价值函数$Q_i (tau, a)$，再根据最大值 $Q_i (tau, a)$ 选择最优的行为。即 $Q_i (tau, a)$ 的准确性可以影响策略的优劣与收敛。大多数提升算法在解决连续空间、过高估计等问题。
- Policy-based方法建立输入和输出之间的可微参数模型，然后通过梯度优化搜索合适的参数，其输出为动作的分布而不是状态动作价值。多数提升算法在于解决MC采样带来的大方差问题以及奖励裁剪问题。
- AC-based方法中Actor前身是Policy Gradient，可以轻松地在连续空间内选择合适动作。但是Actor根据每个episode的累积奖励更新，所以效率比较慢。用一个value-based的算法作为Critic就可以使用TD方法实现单步更新，这其实可以看做是拿偏差换方差。
#info(caption: "介绍的四个算法")[
  + MADDPG
  + COMA
  + LICA
  + MAPPO
]

#let bx = $bold(x)$
== MADDPG
- 首先回顾 DDPG
  #fig("/public/assets/AI/AI_RL/img-2024-07-11-09-45-21.png",width:70%)
- 传统算法在多智能体环境中有以下几个困境
  + 环境的变化由所有智能体共同影响，对于单个智能体，环境是不稳定的，这违反了 Q-learning 所需的马尔可夫假设；
  + 由于环境的不稳定，策略不同时，状态转移矩阵也不同，因此不能直接将过去经验 $(s, a_i, r_i, s')$ 进行回放；
  + 策略梯度方法中大方差的问题加剧。基于这样的局限性，使用集中训练分布式执行的方式(CTDE)；以及假设 IGM 原则（假设较强，但没有别的好方法，而且它 work）
- 而使用 MADDPG
  + 学习到的策略可以分布式执行，即智能体根据自己的观察结果来决策；
  + 不需要假定环境动态系统是可微的，也不需要假设智能体之间的通讯方式有任何特性结构，即世界模型和通信模型都不要求是可微的；
  + 因为每个智能体最大化各自的累积奖励，MADDPG 不仅可以应用于具有明确通信渠道的合作博弈，还可以应用于竞争博弈。
- MADDPG 是一个多智能体的基于 AC 算法的架构，为此先介绍 MAAC 架构
  - 随机离散 Multi-Agent 的 AC 思路：
    - $N$ 个智能体，策略参数分别为：$bold(th) = {th1, dots, thN}$，策略：$bold(pi) = {pi1, dots, pi_n}$
    - 针对智能体 $i$ 的策略梯度公式：#mitex(`\nabla_{\theta_{i}}J(\theta_{i})=\mathbb{E}_{s\sim p}\pi_{,a\sim\pi_{\theta}}[\nabla_{\theta_{i}}l o g\pi_{i}(a_{i}|o_{i})Q_{i}^{\pi}(\bold{x},a_{1},\ldots a_{N})]`)
    - 其中 $Q_i^pi (bx, a_1, dots, a_N)$ 是一个集中的动作价值函数，它将所有智能体的动作 $a1, dots, aN$，以及一些状态信息 $bx$ 作为输入，输出每个智能体的动作价值；
    - $bx$中包含所有智能体的观测信息 $bx=(o_1, dots, o_N)$，以及其他额外信息如通信信息等；
    - 由于 $Q_i^pi$ 都是独立学习到，因此每个智能体可以有任何的奖励结构，包括合作或竞争以及混合奖励。
- MADDPG 算法思路基于以下原理：
  - 每个智能体都只输出一个确定性动作，而不是基于概率分布 $pi$ 采样的随机变量。则：
  #mitex(`P(s^{\prime}|a_{1},\ldots a_{N},\pi_{1},\ldots\pi_{N})=P(s^{\prime}|a_{1},\ldots a_{N})=P(s^{\prime}|a_{1},\ldots a_{N},\pi_{1}^{\prime},\ldots\pi_{N}^{\prime}),\qquad\pi_{i}^{\prime}\ne\pi_{i}`)
  - 即不论策略是否相同，只要其产生的动作 $a_i$ 相同，那么其状态转移可以视为不变。
  - 如果已知各个智能体的动作，即便生成的策略不同，环境依旧是稳定的。
  - 可以直接将 DDPG 的目标损失拓展到多智能体版本。
- 算法流程如下：
  #fig("/public/assets/AI/AI_RL/img-2024-07-12-11-31-06.png",width:60%)

== COMA
- 系统的联合动作空间 (joint action space) 将会随智能体数量指数性地扩大。因此，直接从这么大的联合动作空间中学习出一个比较好用的联合策略会非常困难。
- 考虑一种分布式策略，让每个智能体根据自己的观测，输出各自的动作，使得该分布式策略对全局性能来说是最优的。尤其在当每个智能体的观测是局部观测并且互相之间的通信受到限制时，这种分布式策略更是必须要考虑的。
- 假设 CTDE，智能体执行动作的时候策略是分布式的，但是在学习的过程中，我们还是假设能够获取更多的全局信息。
- CTDE 存在多智能体信用分配，COMA 提出了一种方法用于学习非中心式的、部分可观测的多智能体协同的控制策略。
- COMA 可以认为是 MA 版本的 A2C，使用*反事实基线*实现 Advantage

#fig("/public/assets/AI/AI_RL/img-2024-07-11-10-11-13.png",width:60%)

== LICA
- LICA-Critic
- 自适应熵正则化
- 听不懂思密达

== MAPPO
- 论文名《The Surprising Effectiveness of PPO in Cooperative Multi-Agent Games》
  - 也就是说 PPO 在合作多智能体中的效果出乎意料的好，本质上就是 PPO 的多智能体版本
- MAPPO：价值函数的输入
  - CL：所有本地观测的串联(concatenation of local observations, CL)形成的全局状态。
  - EP：采用了一个包含环境状态概况信息的环境提供的全局状态(Environment-Provided global state, EP)
  - AS（EP+特定 agent 的观测）：特定智能体的全局状态(Agent-Specific Global State, AS)，它通过连接 EP 状态和 $o_i$ 为智能体 $i$ 创建全局状态。这为价值函数提供了对环境状态的更全面描述。（会冗余重复）
  - FP：为了评估这种增加的维度对性能的影响，MAPPO通过移除 AS 状态中重复的特征，创建了一个特征剪枝的特定智能体全局状态(Featured-Pruned Agent-Specific Global State, FP)
- MAPPO：训练数据利用
  - PPO 的一个重点特性是使用重要性采样(importance sampling)进行非策略(off-policy)校正，这允许重复使用样本数据。也就是将收集的大量样本分成小批次，并进行多个 epochs 的训练。
  - 在单智能体连续控制领域，常见做法是将大量样本分成大约 32 或 64个小批次，并进行数十个训练周期。然而，在多智能体领域，我们发现当样本被过度重用时，MAPPO 的性能会降低（也就是不能重复使用次数太多）。
  - 这可能是由于多智能体强化学习中的非平稳性(non-stationarity)：减少每次更新的训练周期数可以限制智能体策略的变化，这可能有助于提高策略和价值学习的稳定性。
- MAPPO-Clip
  - PPO 的另一个核心特征是利用剪切的重要性比例(clipped importance ratio)和价值损失(value loss)，以防止策略和价值函数在迭代过程中发生剧烈变化。剪切的强度由超参数$ep$控制：较大的$ep$值允许对策略和价值函数进行更大的更新。
  - 与训练周期数类似，假设策略和价值的剪切可以限制由于智能体策略在训练中的变化而引起的非平稳性。对于较小的$epsilon$，智能体的策略在每次更新中的变化可能会更小，因此可以在可能牺牲学习速度的情况下，提高整体学习的稳定性。