#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "paper_reading",
  lang: "zh",
)

#note[记录本人阅读过的论文（精读 or 略读），写的不好还请见谅 `>_<|||`]

- 3D Representations（各种三维表征）
  + DeepSDF: 第一个用神经网络来直接拟合 SDF 的工作
  + Siren: 探索周期性激活函数用于隐式神经表示
  + NeRF: 用于新视角合成的神经辐射场，三维表征领域划时代工作
  + NeRF 的改进工作，如 Mip-NeRF, Plenoxels, PlenOctrees, Instant-NGP, MobileNeRF, NeuS 等
  + 3DGS: 用于三维重建的高斯椭球显式表示，又一划时代工作
- CV
  + Segment Anything: 通用分割模型，几乎在分割领域 “杀死比赛”
  + …… 更多的 CV 论文放在划分更细的 topic 里
- Generation Model
  + VAE: 变分自编码器，生成领域的开山之作，其思想贯穿在后续的扩散模型中
  + GAN: 生成对抗网络，通过 “左脚踩右脚上天” 的方式另辟生成之蹊径
  + DDPM: 扩散模型的奠基之作，真正把扩散模型带火并超越 GAN 系列
  + DDPM 的改进工作，如 DDIM, IDDPM 等
  + Stable Diffusion: 基于扩散模型的文生图模型
- HMR (Human Motion Recovery)
  + GVHMR: 预测 world-grounded SMPL 参数
- Monocular (Human) Reconstruction（通过单目视频重建人体）
  + HumanNeRF: 把 NeRF 应用到人体重建，过拟合到某个视频的人体上
  + HUGS & GaussianAvatar: 把 3DGS 应用到人体重建，通过 gaussian-per-vertex 结合 Gaussian & Mesh
  + ExAvatar: 同样是 gaussian-per-vertex 但做得更完整、更细节
- Sparse View (Human) Reconstruction（通过单张图重建人体）
  + SMPL: 人体重建领域绕不开的话题，通过参数化表示大大减小 mesh 的复杂度，并广泛应用于后续工作（甚至成为预测目标）
  + PIFu & PIFuHD: PIFu 是第一个用隐式神经表示 (occupancy field) 做人体重建的工作，PIFuHD 是其改进
  + PaMIR: 在 PIFu 基础上引入 SMPL prior
  + ICON & ECON: 综合 SMPL 和 normal map 优化，分别以隐式 (occupancy field) 和显式 (normal integration) 方式进行重建
  + SHERF: 将 generalizable NeRF 引入人体领域，实现单视图人体重建
  + GTA & SIFU: 用 ViT 提取图像信息，结合 cross-attention 解耦各个侧面特征，更好地重建出 occupancy field，辅以一定 refinement
  + Human-LRM: 将 Large Reconstruction Model 特化到人体领域，结合扩散模型生成多视图，最后采用成熟的多视角人体重建
  + HumanSplat: 把 3DGS 引入单视图人体重建，同样结合扩散模型生成多视图，用 transformer 融合后 MLP 预测高斯属性
- 跟李沐学 AI 之论文精读
  + 如何读论文: #link("https://www.bilibili.com/video/BV1H44y1t75x")[如何读论文【论文精读·1】]
  + Transformer (Attention is All You Need): #link("https://www.bilibili.com/video/BV1pu411o7BE")[Transformer 论文逐段精读【论文精读】]
  + GAN: #link("https://www.bilibili.com/video/BV1rb4y187vD")[GAN论文逐段精读【论文精读】]
  + ViT: #link("https://www.bilibili.com/video/BV15P4y137jb")[ViT 论文逐段精读【论文精读】]
  + MAE: #link("https://www.bilibili.com/video/BV1sq4y1q77t")[MAE 论文逐段精读【论文精读】]
  + MoCo: #link("https://www.bilibili.com/video/BV1C3411s7t9")[MoCo 论文逐段精读【论文精读】]
  + 对比学习串讲: #link("https://www.bilibili.com/video/BV19S4y1M7hm")[对比学习论文综述【论文精读】]
  + Swin Transformer: #link("https://www.bilibili.com/video/BV13L4y1475U")[Swin Transformer论文精读【论文精读】]
  + CLIP: #link("https://www.bilibili.com/video/BV1SL4y1s7LQ")[CLIP 论文逐段精读【论文精读】]
  + DALLE2: #link("https://www.bilibili.com/video/BV17r4y1u77B")[DALL·E 2（内含扩散模型介绍）【论文精读】]
