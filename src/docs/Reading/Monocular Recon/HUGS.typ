---
order: 2
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Monocular Reconstruction -- Human",
  lang: "zh",
)

= HUGS: Human Gaussian Splats
- 时间：2023.11
- 一篇 3DGS 出来后就即时跟进的文章，比较早期，我也就简单概括一下

== 概要
- 神经渲染的最新进展使训练和渲染时间都提高了几个数量级，质量上也有所提高，但它们多是为静态场景而设计，不能很好推广到环境中自由移动的人类
- 本文引入了 Human Gaussian Splats (HUGS)，使用 3DGS 将场景与可驱动的人类一起表示。该方法只需要一个短单目视频 (50 \~ 100 frames)，能在 30 分钟内自动学会将静态场景和完全可驱动的数字人分开
  - 利用 SMPL 人体模型来初始化人体高斯模型。为了捕捉 SMPL 没有建模的细节（例如布料、头发），允许 Gaussians 偏离人体模型
  - 将 3D 高斯模型用于驱动人类带来了新的挑战，包括在表达高斯模型时产生的伪影。本文提出联合优化 LBS 权重，以协调动画过程中单个高斯的运动
- 该方法能实现人体的新姿态合成和人类与场景的新视图合成，实现了最先进的渲染质量，渲染速度为 60 FPS，而训练速度比以前快 100 倍（这其实都得益于 3DGS）

== 方法
#fig("/public/assets/Reading/Human/2025-01-22-21-54-25.png", width: 90%)
- Preliminaries 略 (SMPL, 3DGS)
- SMPL regressor (#link("https://github.com/shubham-goel/4D-Humans")[Humans in 4D]) 为每帧预测 $th_(1 wave T)$ 和帧共享的 $be$，然后据此初始化高斯模型 (in canonical space)
- 用三平面表征来表示人体，对每个点 $mu_i$ 投影得到 $f_x^i, f_y^i, f_z^i$，concat 起来送入分别的 MLP 预测高斯属性
- 用 LBS 权重驱动，渲染得到 human-only 图像，也结合场景高斯一起渲染得到 scene + human 图像
- 优化上，允许人体高斯进行密度控制 (clone, split, and prune)，做以下 loss
  + 跟 ground-truth 的 human-only (by segmentation model) 图像做 human-only loss
  + 跟 ground-truth 的 scene + human 图像做 loss
  + 对学出来的 LBS 权重做正则化，具体做法是对每个高斯，检索其 $k=6$ 近邻做 distance-weighted 平均得到 $hat(W)$，计算 $||W - hat(W)||_F^2$

== 总结
- 实验不看了
- 缺陷和未来工作
  + HUGS 受限于 SMPL 和蒙皮权重，因此无法很好地建模 loose clothes（老生常谈），未来工作可以用非线性的 clothing deformation 来解决
  + HUGS 在 in-the-wild videos 上训练，没有 cover 人体模型的 pose-space（？
  + 虽然是逐个体优化而非学习的方式，但依旧有缺少数据的问题，使用生成方式（如 diffusion）加入 human-pose appearance 的先验能缓解
  + 本文没有建模环境光照，导致把人体摘出来放到新环境中显得不自然，未来工作可以光照表示方法做一个解耦来进行重光照之类
- 从不阉割掉密度控制功能的角度看，这篇最早的反而最符合直觉，但后续两篇 GaussianAvatar 和 ExAvatar 为什么要砍掉呢？

