---
order: 3
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "AI 笔记之强化学习",
  lang: "zh",
)

= 策略学习
== 策略梯度
- 前面讲的是基于价值（$V$或$Q$）的策略，而策略梯度是完全不同的一种方法
- 回顾
  - #fig("/public/assets/AI/AI_RL/img-2024-07-05-09-36-52.png")
  - #fig("/public/assets/AI/AI_RL/img-2024-07-05-09-38-37.png")
  - #fig("/public/assets/AI/AI_RL/img-2024-07-05-09-41-23.png")
    - 优点：具有更好的收敛性质；在高维度或连续的动作空间中更有效；能够学习出随机策略
    - 缺点：通常会收敛到局部最优而非全局最优；评估一个策略通常不够高效并具有较大的方差
- 回到现在，为什么要引入基于策略的强化学习方法？
  - 基于价值的强化学习方法：
    + 学习价值函数
    + 利用价值函数导出策略
    + 更高的样本训练效率
    + 通常仅适用于具有离散动作的环境
  - 基于策略的强化学习方法：
    + 不需要价值函数
    + 直接学习策略
    + 在高维或连续动作空间场景中更加高效
    + 适用任何动作类型的场景
    + 容易收敛到次优解
  - 基于演员-评论家的方法将二者优势结合

- 基于策略的强化学习方法方法直接搜索最优策略$pi^*$
- 通常做法是参数化策略 $pi_theta$，并利用无梯度或基于梯度的优化方法对参数进行更新
  - 无梯度优化（启发式优化方法，如有限差分方法、交叉熵方法、遗传算法等）可以有效覆盖低维参数空间，但基于梯度的训练仍然是首选，因为其具有更高的采样效率（这里没有详细展开）
  - 对比之前的表格型策略
    + 采取某个动作的概率的计算方式不同：状态 $s$ 上采取动作 $a$ 的概率，一个是直接查表，一个是计算 $pi_theta (a|s)$
    + 策略的更新方式不同：一个是直接修改表格对应条目，一个是更新参数 $theta$
    + 最优策略的定义不同
- 基本思想：
  - 利用目标函数定义策略优劣性：$J(theta) = J(pi_theta)$（目标函数如何设计?）
  - 对目标函数进行优化（优化方向如何计算），以寻找最优策略
- 优化方向
  - 目标函数不可微分时：使用无梯度算法进行最优参数搜索
  - 目标函数可微分时：利用基于梯度的优化方法寻找最优策略 $theta_(t+1) <- theta_t + alpha nabla_theta J(theta_t)$
- 目标函数
  #fig("/public/assets/AI/AI_RL/img-2024-07-05-09-59-33.png")
- 状态分布$d(s)$
  - 策略无关的状态分布
    - 在这类情况下，目标函数关于参数的梯度通常更好算
    -  一个简单的做法是取 $d(s)$ 为均匀分布，即每个状态都有相同的权重 $1\/|S|$
    - 另一种做法是把权重集中分配给一部分状态集合。例如，在一些任务中，一个回合只从状态 $s_0$ 开始，那么可以设置为：$d(s_0)=1,d(s!=s_0)=0$
  - 策略相关的状态分布
    - 在这种情况下，通常选用稳态状态分布
    - $d(s)$ 是稳态状态分布：若对一个状态转移 $s->a->s'$，满足：#mitex(`d(s^{\prime})=\sum_{s\in\mathcal{S}}\sum_{a\in\mathcal{A}}p(s^{\prime}|s,a)\cdot\pi_{\theta}(a|s)\cdot d(s)`)
- 如果采用最大化平均轨迹回报目标函数$ max_theta J(theta)=max_theta EE_(tau wave p_theta (tau)) [sum_t r(s_t,a_t)] $
  - $tau$ 为策略 $pi_theta$ 采样而来的轨迹 ${s_1,a_1,r_1,dots,s_T}$
  - 记 $G(tau)=sum_t r(s_t,a_t)$，平均轨迹回报目标的策略梯度为：
  $ nabla_theta J(theta)=nabla_theta int p_theta (tau)G(tau) dif tau &= EE_(tau wave p_theta (tau)) [nabla_theta log p_theta (tau)G(tau)]\ &=EE_(tau wave p_theta (tau)) [sum_(t=1)^T nabla_theta log pi_theta (a_t|s_t)G(tau)] $
  - 其中出现 $log$ 是因为乘一个除一个 $p_theta (tau)$，于是 $(nabla_theta p_theta (tau)) / (p_theta (tau))$ 变成 $nabla_theta log p_theta (tau)$
  - #fig("/public/assets/AI/AI_RL/img-2024-07-05-10-18-35.png")
- 另外两种目标函数和策略梯度
  #fig("/public/assets/AI/AI_RL/img-2024-07-05-10-19-19.png")
- 使用不同的策略梯度，以及不同的近似方法，我们可以得到各种各样的基于策略梯度的强化学习算法，如 REINFORCE、DDPG、PPO等

=== REINFORCE 算法
- 对于随机策略$pi_theta (a,s) = P(a|s, theta)$
  - 直觉上我们应该：降低带来低价值/奖励的动作出现的概率；提高带来高价值/奖励的动作出现的概率
- 上一章中我们推导出了策略梯度（最大化平均轨迹回报目标函数），在实践中，我们可以用蒙特卡洛方法进行估计 #mitex(`\nabla_{\theta}J(\theta)=\ \frac{1}{N}\sum_{n=1}^{N}\sum_{t=1}^{T^{n}}R(\tau^{n})\nabla_{\theta}l o g\,\pi_{\theta}(a_{t}^{n}|s_{t}^{n})`)据此，我们可以得到 REINFORCE 算法
#algo(caption: "REINFORCE 算法")[
```typ
利用策略$pi_theta (a|s)$采样$N$条轨迹${tau_i}$
计算梯度 $nabla_theta J(theta)=1/N sum_(n=1)^N (sum_(t=1)^(T^n) R(tau^n) nabla_theta log pi_theta (a_t^n|s_t^n))$
更新参数 $theta <- theta + alpha nabla_theta J(theta)$
```
]
#fig("/public/assets/AI/AI_RL/img-2024-07-05-15-16-33.png", width: 80%)
- 思考强化学习与分类问题对比
  + 都是输入状态，输出要采取的行为
  + 分类问题（监督学习）：假设有带标签的训练数据，随后利用极大似然法进行优化
  + 强化学习：没有标签，只能通过试错的方式与环境交互获取奖励，以替代监督信息进行训练
- 一个问题——*训练可能存在偏差*
  #fig("/public/assets/AI/AI_RL/img-2024-07-05-10-41-17.png")
  - 解决办法，添加 *baseline*：将奖励函数减去一个基线 $b$，使得 $R(tau)-b$ 有正有负
    - 如果 $R(tau)>b$ 就让采取对应动作的概率提升；如果 $R(tau)<b$ 就让采取对应动作的概率降低
  - 上述蒙特卡洛采样方法变为 #mitex(`\nabla_{\theta}J(\theta)=\ \frac{1}{N}\sum_{n=1}^{N}\sum_{t=1}^{T^{n}}(R(\tau^{n})-b)\nabla_{\theta}l o g\,\pi_{\theta}(a_{t}^{n}|s_{t}^{n})`)
  - 数学证明减去一个基线并不会影响原梯度的期望值
- 如何实现策略梯度？
  - 难以计算，在实际应用时，都会采用 Pytorch、Tensorflow 中的自动求导工具辅助求解
  - 将策略梯度的目标函数视为极大似然法的目标函数一个利用累积奖励进行加权的版本（？）
- 策略梯度算法在样本利用率以及稳定性上存在缺陷
  - 由于策略梯度算法为同策略算法，因此样本利用率较低
  - 较大的策略更新或不适宜的更新步长会导致训练的不稳定（在监督学习中，训练数据具有独立同分布的性质；而在强化学习中，不适宜的更新步长 $->$ 坏策略 $->$ 低质量的数据，于是可能难以从糟糕的策略中恢复，进而导致性能崩溃）
- 离策略梯度：根据重要性采样利用异策略样本
  - 听不懂
- 自然策略梯度
  - 听不懂

=== Actor-Critic 算法
- 为什么要引入 Actor-Critic？主要是因为 REINFORCE 效率不高
  - REINFORCE 算法中的的轨迹回报期望采用直接相加 $R(tau^n)=sum_(t'=t)^T r(s_t'^i,a_t'^i)$
  - 这样做方差较大，不易收敛。我们可以用动作价值估计 $hat(Q)^pi$ 来近似轨迹回报期望$EE_(pi_theta) sum_(t'=t)^T r(s_t'^i,a_t'^i)$，这就是评论家(critic)
  - 对应地，策略 $pi_theta$ 称为执行者(actor)
#algo(caption: "Actor-Critic 算法")[
```typ
使用当前策略 $pi_theta$ 在环境中进行采样
策略提升：$theta <- theta + alpha nabla_theta J(theta) approx 1/N sum_(i=1)^N (sum_(t=1)^T nabla_theta log pi_theta (a_t^i|s_t^i) hat(Q)^pi (s_t^i,a_t^i))$
拟合当前策略的动作值函数：$hat(Q)^pi (s_t'^i,a_t'^i) approx sum_(t'=t)^T r(s_t'^i,a_t'^i)$
```
]
#fig("/public/assets/AI/AI_RL/img-2024-07-05-15-17-48.png")
- Advantage Actor-Critc(A2C)算法
  - 思想：通过减去一个基线值来标准化评论家的打分
    - 降低较差动作概率，提高较优动作概率
    - 进一步降低方差
  - 优势函数：$A^pi (s,a)=Q^pi (s,a)-V^pi (s_t)$，改变critic，于是原本 AC 算法的策略梯度 #mitex(`\nabla_{\theta}J(\theta)\approx\frac{1}{N}\sum_{i=1}^{N}\left(\sum_{t=1}^{T}V_{\theta}\,l o g\,\pi_{\theta}(a_{t}^{i}|s_{t}^{i})\bar{Q}^{\pi}(s_{i}^{i},\alpha_{t}^{i})\right)`) 变为 #mitex(`\nabla_{\theta}J(\theta)\approx\frac{1}{N}\sum_{i=1}^{N}\left(\sum_{t=1}^{T}\nabla_{\theta}\,l o g\,\pi_{\theta}(a_{t}^{i}|s_{t}^{i})\bar{A}^{\pi}(s_{i}^{i},\alpha_{t}^{i})\right)`)
  - $Q$ 和 $V$需要用两个神经网络拟合吗？
    - 不需要 $hat(Q)^pi (s_t^i,a_t^i)= R(s_t^i,a_t^i) + gamma hat(V)^pi (s_(t+1)^i)$，只需用一个神经网络拟合$hat(V)^pi$
  - 状态值估计$hat(V)^pi$能否与策略 $pi_theta$ 共用网络？
    #fig("/public/assets/AI/AI_RL/img-2024-07-05-11-15-17.png")
    - 如果采用相同的网络去训练，这边的 loss function 没有讲（actor 的 loss，critic 的 loss，actor 的正则化项 entropy），可以参考代码或者看 #link("https://www.cnblogs.com/wangxiaocvpr/p/8110120.html")[这篇文章]
  - 批量更新（没听懂）
    - 问题：利用单个样本进行更新：更新方差较大，训练稳定性差
    - 解决方案：获得一个批次的数据后再进行更新，分为同步和异步两种方法
    #fig("/public/assets/AI/AI_RL/img-2024-07-05-11-22-12.png")
    - 批量更新再改进
    #fig("/public/assets/AI/AI_RL/img-2024-07-05-11-22-32.png")

- Asynchronous Advantage Actor-Critc(A3C)算法
  - 与A2C一样使用优势函数
  - 异步的Actor-Critic方法能够充分利用多核CPU资源采样环境的经验数据，利用GPU资源异步地更新网络，这有效提升了强化学习算法的训练效率

== TRPO & PPO
- TRPO（Trust Region Policy Optimization）是一种基于策略梯度的强化学习算法，其目标是最大化策略的期望回报
- 置信域(Trust Region)的概念就是在 $N(theta_"now")$ 的邻域内，$L(theta|theta_"now")$ 足够逼近优化目标 $J(theta)$
- 前面介绍的策略梯度方法（包括 REINFORCE 和 Actor-Critic）用蒙特卡洛近似梯度 $nabla_theta J(theta)$，得到随机梯度，然后做随机梯度上升更新 $theta$，使得目标函数 $J(theta)$ 增大；而这里是用不同的方法
- 目标函数等价形式写成#mitex(`J(\theta)~=~\mathbb{E}_{S}\left[\mathbb{E}_{A\cdots\pi(\cdot|S;\theta_{\mathrm{now}})}\left[\frac{\pi(A\mid S;\,\theta)}{\pi(A\mid S;\,\theta_{\mathrm{now}})}~\cdot\,{\cal Q}_{\pi}(S,A)\right]\right]`)
  - 其中 $Q_pi (S, A)$ 依旧无法求解，因此使用迭代中的上一步的 $pi=pi(a_t | s_t\; theta_"old")$
- TRPO 第二部置信域的选择
  - 认为设定的 $Delta$
  - 用 KL 散度衡量两个概率质量函数的距离
- TRPO 算法真正实现起来并不容易，主要难点在于第二步——最大化。
#hline()
- PPO 基于 TRPO 的思想，但是其算法实现更加简单
- PPO-惩罚
  - 直接将置信域约束 KL 散度作为损失函数的一部分，这样就不需要求解最大化问题
- PPO-截断
  - PPO 的另一种形式 PPO-截断（PPO-Clip）更加直接，它在目标函数中进行限制，以保证新的参数和旧的参数的差距不会太大

== 连续控制
- 考虑这样一个问题：我们需要控制一只机械手臂，完成某些任务，获取奖励。机械手臂有两个关节，分别可以在 $[0, 360] 与 [0, 180]$ 的范围内转动。这个问题的自由度是 $d = 2$，动作是二维向量，动作空间是连续集合 $cal(A) = [0, 360] times [0, 180]$。
- 此前我们学过的强化学习方法全部都是针对离散动作空间，不能直接解决上述续控制问题。如果用网格化方法，将连续动作空间离散化，会导致动作空间过大，训练效率低下。特别是自由度较高的问题，这种方法几乎不可行

== DPG
- 确定策略梯度(deterministic policy gradient)是一种 actor-critic 方法
- 确定策略网络
  - 在之前章节里，策略网络 $pi(a|s\; theta)$ 是一个概率质量函数，它输出的是概率值。本节的确定策略网络 $mu(s\; theta)$ 的输出是 $d$ 维的向量 $ba$，作为动作。两种策略网络一个是随机的，一个是确定性的
  - 个人认为不是很本质（？），感觉就是把在外的 argmax 放到神经网络里面去了
- 确定价值网络
  - 价值网络 $Q(s, ba\; bw)$ 也是一个神经网络，它的输入是状态 $s$ 和动作 $ba$，输出 $hat(q) = q(s, ba; bw)$ 是个实数
- 总而言之，个人认为这里相当于 actor-critic 的变种，并且真正把两个网络分了开来，两个网络分别训练，而不是共享前几层
- 训练过程
  - 做训练的时候，可以同时对价值网络和策略网络做训练。每次从经验回放数组中抽取一个四元组，记作 $(s_j, a_j, r_j, s_(j+1))$。把价值网络和策略网络当前参数分别记作 $w_"now"$ 和 $theta_"now"$
  -