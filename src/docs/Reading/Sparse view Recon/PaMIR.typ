---
order: 3
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Sparse view Reconstruction -- Human",
  lang: "zh",
)

= PaMIR: Parametric Model-Conditioned Implicit Representation for Image-based Human Reconstruction
- 时间：2020.7
- 参考了 #link("https://www.slagworld.com/index.php/archives/63/")[这篇解读] 和 #link("https://blog.csdn.net/weixin_42145554/article/details/120050376")[这篇]
#fig("/public/assets/Reading/Human/2024-11-05-22-54-33.png", width: 70%)
- PaMIR 用的还是 PIFu 的方法去预测体素化的 occupancy，只是加了几何信息的先验即 SMPL 信息（又因为这已经包括了深度信息，所以直接把 PIFu 原本的 $Z(X)$ 删了），随后将 SMPL 转换为体素，并通过 3D encoder 提取 Voxel-aligned Feature $bF_V$
  $
  F(C(p)): RR^3 |-> [0,1] \
  C(p) = (S(bF_I, pi(p)), S(bF_V, p))^T
  $
  - $S$ 表示双线性插值，$bF_I$ 是 2D encoder 得到的图片特征，$pi(p)$ 跟 PIFu 一个意思（所要求的内外参应该也是？以及 mask 信息去背景应该也需要吧？），$bF_V$ 是 SMPL 体素特征，$p$ 是 3D 点
  - 两边特征提出来，concate 一下，随后直接怼到隐函数中进行重建
- SMPL 哪来？用当时的 SOTA 模型 GCMR 即 #link("https://github.com/nkolot/GraphCMR")[GraphCMR]，以后出新的 SOTA 可以替换
  - GCMR 其实是直接出了一个 body mesh 了，直接把这个 mesh 体素化不就行了？不知道为什么后面还要转成 $beta_"init",th_"init"$，PaMIR 体素化的是这个 GCMR 的 mesh，还是把它转回原始 SMPL 的参数化表达再用 SMPL 模型参数得到的 mesh 来体素化，我就不清楚了
- 由于预测出来的 SMPL 跟 ground truth SMPL 之间有差距（尤其是深度，因为图像在深度信息上天生有模糊性），作者提出了深度模糊的重建损失函数
  - 具体而言就是加一个对人体深度偏移的补偿（因为训练的时候 ground truth SMPL 是知道的，所以可以算出来）
  $ Delta z_i = sum_(j in cN(i)) w_(j->i)/w_i (Z(vj-vj^*)) $
    - 其中 $cN(i)$ 是 $p_i$ 的 $4$ 最近邻集合（在 posed mesh 中），根据 $p_i$ 与它们的距离算了个混合权重并归一化
  - 之所以这样做，是因为我们其实不在乎回归出的人体模型中心的绝对坐标到底在哪，只要几何曲面重建得好就行
  - 这里也就对应 ICON 作者说把 ground truth SMPL 灌给 PaMIR（但依旧不能泛化到未见姿态）的那句话
- 对于 RGB 预测，跟 PIFu 应该也差不多，只是多预测了个混合值 $al$，将该点对应图片中观察到的颜色和预测出的颜色做了混合
- PaMIR 也可以自然地拓展到多视角图片的预测，但比 PIFu 好的一点在于它不需要 calibration or synchronization，因为它能通过 SMPL 建立 correspondence across different views
- body reference optimization
  - 在 inference 时，网络权重固定，作者把最终 SMPL 的顶点送入 implicit function 预测计算跟 $0.5$ 的插值，把 SMPL 参数 $beta, th$ 再优化一下（因为 GCMR 预测跟真值还是有差距），鼓励最终预测和 SMPL 的预测对齐，同时用正则项惩罚 $beta, th$ 与 GCMR init 预测的差异
    $
    cL_B = 1/n_S sum_(j=1)^n_S q(F(c(v_j))-0.5) \
    q(x) = cases(abs(x) ~~~~ &x >= 0, 1/5 abs(x) &x < 0)
    $
    - 这里的这个 loss，意思是对外部的点（占用小）施加更小的惩罚，通过这种方式，虽然 SMPL 学的是 naked body，但对 loose clothing 也有一定的鲁棒性
  - 训练的时候为什么不能这样做呢？个人理解：
    - 首先，optimized-based 方法是指过拟合到某一个场景，而 learning-based 方法是学到某种通用的模式，之后还能泛化到其它场景。比如说（原始）NeRF 那种，本身就是一个场景一个网络，那用 optimized-based 当然没问题。对 PaMIR，推理的时候再调优一下没啥问题，训练的时候就甭想了；
    - 其次，因为那个时候网络都还没训好，没法这样调优
  - 得益于此，作者声称 PaMIR 对 SMPL 预测不那么敏感，在 SMPL 不准的情况下也能做后续优化（算是获得更准确的 SMPL 的 trick 吧）
- train 阶段：输入数据是一组（去除了背景的）RGB 图片以及对应的 meshes（包括对应的 texture 和顶点的 UV map）。作者首先在自己的 training set 上 fine-tune GCMR，然后训练 single-view network；之后在其上 fine-tune 出 multi-view network
- inference 阶段：只需要（去除了背景的）RGB 图片即可输出 SMPL 的参数和 reconstructed surface with texture。不过为了最好的性能，都跑了一遍 body reference optimization
