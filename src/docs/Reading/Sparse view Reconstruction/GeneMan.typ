---
order: 10
draft: true
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Sparse view Reconstruction -- Human",
  lang: "zh",
)

= GeneMAN: Generalizable Single-Image 3D Human Reconstruction from Multi-Source Human Data
- 时间：2024.11.27

== 摘要
- 给定一张 in-the-wild 人类照片，重建一个高保真的 3D 人体模型，这仍是一个具有挑战性的任务
- 现有方法面临的困难包括
  + 不同图像中人体比例不同
  + 图像中有各种各样的个人物品（衣服、饰品等）
  + 人体姿势不明确，纹理不一致
  + 高质量的人体数据稀缺
- 为了解决这些问题，提出了一个通用的图像到 3D 人体重建框架 —— GeneMAN。基于一个包括 3D 扫描、多视角视频、单张照片和合成人体数据的高质量人体数据集。GeneMAN 包括三个关键模块
  + 不借助参数化模型 (SMPL)，GeneMAN 首先训练两个扩散模型：human-specific text-to-image 用于 2D 人体先验，view-conditioned 用于 3D 人体先验
  + 在 pretrained 人体先验模型的帮助下，GeneMAN 使用几何初始化和雕刻管线来恢复高质量的 3D 人体几何
  + 为了获得高保真的 3D 人体纹理，GeneMAN 使用 multi-space 纹理 refinement 管线，在潜在空间和像素空间中连续地优化纹理
- 大量实验结果表明，GeneMAN 在这个 setting 下成为 SOTA。值得注意的是，GeneMAN 在处理 in-the-wild 图像时表现出更好的泛化性，通常能够生成自然姿势的高质量 3D 人体模型，无论输入图像中的身体比例如何，都能够处理常见物品
- 又回到 NeRF 那一套了，先不看了
