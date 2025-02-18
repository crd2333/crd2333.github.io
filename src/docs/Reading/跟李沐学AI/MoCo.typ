---
order: 11
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "d2l_paper",
  lang: "zh",
)

= Momentum Contrast for Unsupervised Visual Representation Learning
- 时间：2019.11

== 题目 & 摘要
- MoCo 是 CVPR20 最佳论文提名，是 CV 领域对比学习里程碑的工作，以一己之力盘活了巨卷的 CV 领域
  - 如果把深度学习比作一块蛋糕，那么强化学习只能是蛋糕上的一颗樱桃，有监督学习是蛋糕上的糖霜，只有自监督学习才能算是整个蛋糕的主体
  - 什么是对比学习？对比学习是自监督的一种，可以看对比学习综述那篇文章（#link("https://crd2333.github.io/note/Reading/%E8%B7%9F%E6%9D%8E%E6%B2%90%E5%AD%A6AI/%E5%AF%B9%E6%AF%94%E5%AD%A6%E4%B9%A0%E4%B8%B2%E8%AE%B2/")[链接]），简单来讲就是让相似样本的特征空间尽量接近而不相似的尽量远离。对比学习的框架最大的好处就在于正负样本定义规则的灵活性
- 题目：动量对比学习的方法做无监督视觉特征学习
  - 本文的亮点在于，MoCo（第一个）在主流的 CV 任务 （分类、检测、分割）中填补甚至超越无监督与有监督方法之间的鸿沟，并且容易迁移到下游任务
- MoCo 定义了一个动态 dictionary look-up 任务，它包含
  + 一个队列：队列中的样本无需全部梯度回传，可以放很多负样本，让字典变得很大
  + 一个移动平均的编码器：让字典的特征尽可能的保持一致
  - MoCo 利用动量的特性，缓慢的更新一个编码器，从而让中间学习到的字典中的特征尽可能保持一致，一个又大又一致的字典有利于无监督对比学习的训练

== 引言
- 无监督在 CV 不成功的原因是什么？
  - 原始信号空间的不同
    - NLP 原始信号是离散的，词、词根、词缀，容易构建 tokenized dictionaries 做无监督学习，容易建模且建好的模型也好优化
    - CV 原始信号是连续的、高维的，不像单词具有浓缩好的、简洁的语义信息，不适合构建一个字典，难以建模
- CV 领域近期无监督对比学习的各种方法可以被统一归纳为“动态字典法”，anchor 当做 query，而各个正负样本作为字典的 key，视图把字典建模得比较好使得 query 和 相似的 key 具有相似的特征 value
  - 从这个角度来看，动态字典应当具有 large + consistency 的特点
    + large：从连续高维空间做更多的采样。字典 key 越多，表示的视觉信息越丰富，匹配时更容易找到具有区分性的本质特征。否则模型可能学到 shortcut 而不能泛化
    + consistent ：字典里的 key 应该由相同的 or 相似的编码器生成。否则 query 很有可能去找同一个 encoder 生成的 key，而不是寻找语义相似性（另一种形式的 shortcut solution）

== 相关工作
- 跟有监督相比，两个主要不同点是代理任务 pretext tasks 和损失目标函数 loss functions, objective functions
  - 损失函数
    + 判别式，比如分类
    + 生成式，比如重建整张图
    + 对比学习，目标是相似样本特征相近，并不固定，跟 encoder 输出相关
    + 对抗学习，衡量两个概率分布之间的差异
  - 代理任务
    + denoising auto-encoders 重建整张图
    + context auto-encoders 重建某个 patch
    + cross-channel auto-encoders (colorization) 给图片上色当自监督信号
    + pseudo-labels 图片生成伪标签
      + exemplar image，比如同一张图片做不同的数据增广后都属于同一个类
      + patch ordering 九宫格方法：打乱了以后预测 patch 的顺序或随机选一个 patch 预测方位
      + 利用视频的顺序做 tracking
      + 做聚类的方法 clustering features
  - 不同的代理任务可以和不同形式的对比学习目标函数配对使用，思考 MoCo, CPC, CMC 分别是怎么样的配对
- 另外，作者把相关工作归纳为动态字典法之后，总结说它们或多或少都受限于字典*大小*和*一致性*问题，如图
  - 比如，同期的 SimCLR 就是第一种，正负样本对来自同一个 batch，因为 google 比较有钱才训练得起来；之前的 CPC, CMC 应该也都是这种，后来的 CLIP 应该也是
    #q[PS：其实 MoCo 的 queue 结构也没有吹得那么好，单从效果不计成本地来看还是 large batchsize 比较厉害(money is all you need)，后来 MoCo-v3 也换回去了。而且 KaiMing 团队后来自己的 SimSiam 也摈弃了动量编码器。不过，它的影响依旧是深远的]
  - Inst Disc 是第二种，用 memory bank 的方式 off-line 地做字典，大小可以很大但一致性欠缺
  - 其实 memory bank 加上 momentum 就是 MoCo 的雏形了，不过 MoCo 的扩展性更好（memory bank 需要存整个数据集，而 MoCo 只需要从中随机抽取）
#fig("/public/assets/Reading/limu_paper/MoCo/2024-10-04-23-00-36.png")

== 框架和方法
#fig("/public/assets/Reading/limu_paper/MoCo/2024-10-04-22-03-47.png", width: 50%)
- queue：剥离显卡内存对字典大小的限制，让字典大小（或者说 queue 的大小）和 batch size 分开，每次从中取出前 minibatch 个元素扔掉，从数据集中随机抽取 minibatch 个元素计算并入队。队列（字典）始终是整个数据集的子集，且大小为固定的超参数
- momentum encoder：有点强化学习目标网络的思想，减缓每次更新的剧烈程度，使得模型变得平稳一致，尽可能使字典(queue)里的 key 由跟 query 类似的 encoder 生成 $ theta_k <- m theta_k + (1-m)theta_q $
- MoCo 的代理任务 pretext task 是什么？事实上，MoCo 是一种建立模型的方法，可以和很灵活地与多种代理任务使用，这里以 instance discrimination 为例
- 损失函数为 infoNCE(info noise contrastive estimation)，负样本从整个数据集中选取部分进行估计，把一个超级多的 $N$ 分类问题变成 data sample 和 noise samples 共 $1 + K$ 个类别来解决 softmax 不工作的问题，同时降低了计算复杂度 $ cal(L)_q = - log exp(q dot k_+ \/ tau)/(sum_(i=0)^K exp(q dot k_i \/ tau))  $
  - 具体代码中，由于正样本就是类别 $0$ ，直接把 ground truth 设为全零然后做 cross entropy loss 就行了，很巧妙

#algo(
  // stroke: none,
  title: [*Algorithm 1:* 伪代码]
)[
  - \# f_q, f_k: encoder networks for query and key
  - \# queue: dictionary as a queue of K keys (CxK)
  - \# m: momentum
  - \# t: temperature
  #no-number
  + f_k.params = f_q.params #comment[initialize]
  + for x in loader: #comment[load a minibatch x with N samples]
    + x_q = aug(x) #comment[a randomly augmented version]
    + x_k = aug(x) #comment[another randomly augmented version]
    + q = f_q.forward(x_q) #comment[queries: NxC]
    + k = f_k.forward(x_k) #comment[keys: NxC]
    + k = k.detach() #comment[no gradient to keys]
    #no-number
    + \# positive logits: Nx1
    + l_pos = bmm(q.view(N,1,C), k.view(N,C,1))
    + \# negative logits: NxK
    + l_neg = mm(q.view(N,C), queue.view(C,K))
    #no-number
    + \# logits: Nx(1+K)
    + logits = cat([l_pos, l_neg], dim=1)
    + \# contrastive loss, Eqn.(1)
    + labels = zeros(N) #comment[positives are the 0-th]
    + loss = CrossEntropyLoss(logits/t, labels)
    #no-number
    + \# SGD update: query network
    + loss.backward()
    + update(f_q.params)
    #no-number
    + \# momentum update: key network
    + f_k.params = m*f_k.params+(1-m)\*f_q.params
    #no-number
    + \# update dictionary
    + enqueue(queue, k) #comment[enqueue the current minibatch]
    + dequeue(queue) #comment[dequeue the earliest minibatch]
]
- 最后还讲了一个避免 BN 信息泄露的小 trick，不是很懂为什么会信息泄露？

== 结果和讨论
- 主要分成了两大部分进行了结果的展示
  + Linear Classification Protocol：将训练好的模型 freeze，然后学最后一层线性层
    - 对两个主要贡献做了消融实验
    - 一个比较有意思的现象是 lr 设为了 $30$，也启示我们对比学习和有监督学习的目标函数分布可能大不相同
    - 在 $7$ 个检测 or 分割的任务超越 ImageNet 有监督训练的结果，甚至有时大幅度超越
  + 迁移学习的效果
    - 对 BN 和训练时长做了限制以得到公平的比较，感觉有点狂傲（用你的超参数打败你）
- 另外，如果把训练数据集换成 instagram，用更多数据、更大模型，性能会提升但性价比变低了
  - 可能是因为大规模数据集没有完全被利用，可以尝试开发其它的代理任务 pretext task，比如 masked auto-encoding（也就是两年后的 MAE，震撼）
- 总之就是效果碾压，就不细记了

== 总结


