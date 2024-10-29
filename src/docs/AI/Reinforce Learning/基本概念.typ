---
order: 1
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "",
  lang: "zh",
)

- Reinforcement Learning
- 其他人的博客 or 笔记
  + #link("https://www.cnblogs.com/pinard/category/1254674.html")[刘建平Pinard的强化学习随笔]

#note(caption: "注：")[
  我觉得 rl 的本质是把无梯度的 feedback 转换为可训练的梯度。具体使用什么样的框架更好，并不影响 rl 理论的本质。这也就是为什么感觉现在做 rl 理论的都在叫苦，但 rl 应用却越来越多（比如大模型 ChatGPT-o1 等）
]

= 基本概念
== 动态规划
- 动态规划将复杂的多阶段决策问题分解为一系列简单的、离散的单阶段决策问题，采用顺序求解方法，通过求解一系列小问题达到求解整个问题的目的。
- 适合于用动态规划的方法求解的问题是具备无后效性（马尔科夫性）的决策过程。

== MDP建模
- 马尔可夫决策过程(Markov decision process，MDP)

== 策略评估与优化
- 强化学习由策略评估和策略改进组成
- 策略评估的目标是知道什么决策是好的，即估计 $V^pi (s_t)$
- 策略提升的目标是根据值函数选择好的行动
  - 基于价值函数 $V(s)$，$pi(s)=arg max_(a in A)sum_(s' in S)P(s'|s,a)V(s')$
  - 基于动作价值函数 $Q(s,a)$，$pi(s)=arg max_(a in A)Q(s,a)$

== 探索与利用
- 为什么？环境信息不完全；每一种决策的真实价值无法获取，只能获取其统计价值。
  - 更具体地，有些行为尚未被探索过，其价值未知；已被探索过的行为可能因为偶然概率原因被高估或者低估；
=== $epsilon-"greedy"$ 方法
- 大多数时间($1 - epsilon$)采用当前统计行为价值中最优的行为，其余时间随机选择一个行为($epsilon$)
  - 每个行为的价值为历史决策经验中该行为获得奖励的均值
  #mitex(`\hat{Q}_{t}(a)=\frac{1}{N_{t}(a)}\sum_{\tau=1}^{t}r_{\tau}\,\delta[a_{\tau}=a]`)其中 $delta$ 为二元指示函数，$N_t (a)$ 为 $t$ 步中行为 $a$ 被选择的次数，即 $display(N_t (a) = sum_(tau=1)^t delta[a_tau=a])$
  - $epsilon$ 可以被设定为超参，也可以随训练的进行逐步衰减
  - 优点：简单，易于理解
  - 缺点：虽然每个行为都有可能是最优行为，但是其成为最优的可能性是不同的，同理选择具备不同潜力的行为的策略也可以不完全随机
=== UCB 方法
- 通过奖励值的上置信界(Upper Confidence Bound)来衡量每一个动作附加其“潜力”后的价值。
  - 行为的真实价值低于附加潜力后的价值，即：$Q(a) =< hat(Q)_t (a) + hat(U)_t (a)$
  - 上界函数 $U_t (a)$ 跟 $N_t (a)$ 相关，因为大的行为访问次数使得对应的行为的价值更准确，因此得到较小的置信上界。
  - 首先介绍 Hoeffding 不等式：对于独立同分布的随机变量 $X_1, X_2, ..., X_n$，，$t$ 次采样得到的样本均值为 $macron(X)_t$，那么对于给定的 $u$：$ P(E(X) > macron(X)+u) <= e^(-2 t u^2) $
  - 替换得到我们的结论 #mitex(`\mathbb{P}[Q(a)>{\hat{Q}}_{t}(a)+U_{t}(a)]\leq e^{-2t U_{t}(a)^{2}}`)
  - 令上式右端为 $p$，反解得到 $U_t (a) = sqrt((-ln p)/(2 N_t (a)))$
  - 一种启发方法是及时降低 $p$ 的阈值，因此常设其为 $t$ 的负数次方，得到 $U_t (a) = sqrt((c ln t)/(N_t (a)))$
  - 当 $c=2$（$c$越大，越趋向探索），UCB1 算法选择这样的动作 #mitex(`a_{t}^{U C B1}=\arg\operatorname*{max}_{a\in A}\left(Q(a)+{\sqrt{{\frac{2\log t}{N_{t}(a)}}}}\right)`)

=== 熵正则
- 我们希望策略网络的输出的概率不要集中在一个动作上，至少要给其他的动作一些非零的概率，让这些动作能被探索到。可以用熵 (Entropy) 来衡量概率分布的不确定性