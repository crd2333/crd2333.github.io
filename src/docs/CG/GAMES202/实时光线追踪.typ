---
order: 5
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GAMES202 笔记",
  lang: "zh",
)

有点后悔没有早点开始看这门课，里面的很多概念当初我在网上四处扒资料才理解了一点点……

- GAMES202 也没有咋写详细笔记，可以参考这些笔记
  + #link("https://zhuanlan.zhihu.com/p/363333150")[知乎 | Games202 高质量实时渲染课堂笔记 by CarlHer]
  + #link("https://www.zhihu.com/column/c_1473816420539097088")[知乎 | GAMES202 高质量实时渲染-个人笔记 by 风烟流年]（这个可能整理得更好一些）
  + #link("https://blog.csdn.net/yx314636922/category_11601225.html")[CSDN | GAMES202 by 我要吐泡泡了哦]（这个也不错）

另外，这门课据闫令琪的说法，不会有 GAMES101 那样贯穿的主线，而是分几个 topic 来介绍。Global Illumination (GI) 部分加入 GAMES104 的内容。

#counter(heading).update(5)

= Lec12/13: Real-time Ray Tracing
光线追踪在当时已经不是什么新鲜的话题（现在更是普遍），尤其是 18 年英伟达的 RTX 架构出世，总之至少能做到每帧约 1 SPP (1 sample per pixel) 的计算量（也可能更多，但更多不太可能x）。这样的结果自然非常 noisy，因此 RTRT 的核心其实不是 RT 本身，而是*降噪*。

降噪既要保证实时，又要保证质量，那么选择面就变得非常窄，像切变滤波 (sheer filtering)、离线滤波 (offline filtering) 和深度学习都用不了（DL 存疑，当年不行，本质因为神经网络 inference 过慢，现在随着比如 TensorCore 可能有一点变化）。

噪声的根本原因是因为采样率不足，解决方法一般就两种，一是（暴力 / 取巧地）增加采样数，二是低通滤波，沿着这两个思路提出 *Temporal Accumulation* 和 *Spatial Filtering*。

- *Temporal Accumulation*
  - 通过时间上的均摊来变相增加采样率。自然的问题是，如何对每一帧的像素找到前一帧的对应像素？找到这个值后，做线性加权即可
    - 这里的对应关系寻找在 CG 中被称为 *motion vector*。CV 中有类似的概念叫 optical flow，但不同在于，前者的信息更多（整个渲染过程以及相机相对位姿均已知）
    - 并且随着延迟渲染的发展，G-Buffer 中可以存储 world space coordinates, normal, RGB, Object ID 等，可以拿到更多信息
  - Temporal 对时间上的复用效果非常好，但问题也很明显。老师总结了四点：
    + Switching Scenes (Burn-in Period)
    + Screen Space Issue
    + Disocclusion
    + Shading Failure (delay or lagging)
    - 总之就是，如果对应像素不在屏幕内，或对应元素不可信（被遮挡，或 shading 发生变化），就会无法复用，从而被去噪所掩盖的问题重新暴露出来
    - 解决方法自然是有的，一般分为 Clamping（将上一帧结果强制贴近到当前帧）和 Detection（记录 Object ID，如果变化则通过改变 $al$ 取消复用）两种，但或多或少会重新引入噪声
  - 即使有这么多问题，但 Temporal Accumulation 仍然是效果很好很常用的方法，其缺陷掩盖一下就不会太严重，而且工业界要求也没那么高#strike[（毕竟电子竞技不需要视力）]
- *Spatial Filtering*
  - 一种简单想法是直接用高斯滤波 (Gaussian filtering)，但是纹理边界这种高频信息也会被一起模糊
  - 双边滤波 (Bilateral filtering)
    - 高斯滤波的改进，核心思想是使用欧氏距离的高斯分布和像素的色值差异 (position dist & color dist) 共同决定滤波核的权值
    - 一定程度上合理，但用像素值差异实际上不能完全反映边界和噪声的区别
  - 联合双边滤波 (Cross / Joint bilateral filtering)
    - 利用 "free" feature of G-Buffer，它不涉及 multi-bounces，因此是 noise-free 的 (depth, normal, color, position, etc.)
    - 高斯函数不是距离衰减的唯一选择，例如 exponential (absolute), cosine (clamped) 都可以。以高斯函数为例，每种特征有一个自己的 $si$，不同的高斯调调参后乘在一起
  - 改进 large filtering kernel，一般有两种方法
    + Separate Passes: $N^2 -> N + N$（对高斯函数，数学上本身就是正交可拆分的；对于各种联合滤波，理论上不太能但实现上能）
    + Progressively Growing Sizes: 先用小的 kernel 滤波，然后用大的 kernel 做“空洞卷积”（实际上的卷积核大小没变）
      - 从 higher / deeper level 理解，growing sizes 实际上是逐步去除更低频的高频信息；skip samples 之所以安全是因为采样本质上等于频谱的搬移，当更高频信息被去除，搬移就是安全的
- *Outlier Removal (and temporal clamping)*
  - 有时滤波后的结果仍然是 noisy 的，甚至 blocky，大多数时候是因为 outliers，需要在滤波前检测并去除
  - Outliers 在 rendering 领域有个名字叫 fireflies（火萤、萤火虫）。在图形领域，从理论上来讲并不应该去除它们，反而说明这个方向上探索不够，应该增大采样率来把 variance 降下去；但从 RTRT 的角度我们等不起
  - 对每个像素，看 (e.g.) $7 times 7$ 的邻域，算均值和方差，把 $[mu - k si, mu + k si]$ 之外的值 clamp 到这个范围

= Lec14: A Glimpse of Industrial Solutions
- *Specific Filtering Solutions for RTRT*
  - Spatiotemporal Variance-Guided Filtering (SVGF)
    - 更细致分析三个指导 filtering 的因素
      + Depth: 在考虑深度时，利用深度的梯度将其点所在的切平面也考虑在内，对同一平面的点施加更小的惩罚
      + Normal: 法线的点乘衡量相似度，用类似 Blinn-Phong specular term 的指数来衰减（注意，使用法线、凹凸贴图*前*的结果来做）
      + Color: RGB 转换为 Luminance 作差衡量，但考虑 outlier 的影响，除以在 spacial, temporal, spacial $3$ 个层面的方差
    - SVGF 效果不错，但有时倾向于 over-blur，算是在过度模糊和噪声之间的 trade-off；另外 temporal 的老问题 —— 场景固定、光源移动时的拖影 也还在
  - Recurrent AutoEncoder (RAE)
    - 用神经网络降噪，且有 G-Buffer 的辅助，用最典型的 U-Net 结构。用 recurrent 引入时序信息，后续也有单图的做法
    - 纯 DL 大力出奇迹，没有涉及 motion vector 之类，也就没有对应的那些问题。但其问题在于神经网络速度慢，在那个时候大概要 $50ms$，基本没有实用价值
- *Temporal Anti-Aliasing (AA) / Super Sampling (SS)*
  - TAA 基本跟 RTRT 里面的方法一模一样，不同在于有个 jitter filtering 的概念，用一种固定 pattern 进行采样的抖动，比纯随机更好
  - DLSS
    + DLSS 1.0: 将低分辨率硬拉成高分辨率势必需要一些额外信息。DLSS 1.0 通过数据驱动的方法去硬猜，针对每个游戏或者场景单独训练出一个神经网络，学习一些常见的物体边缘，将分辨率拉高后模糊的边缘替换
    + DLSS 2.0: 引入 temporal 信息，即 TAA-like 方法。但不同在于，由于需要真正提升分辨率，因此对于 temporal failure 不再能用 clamping 方法处理（会导致小像素的值是根据周围点颜色猜测出来的，即高分辨率但模糊）。神经网络不是直接输出混合后的颜色，而是预测怎么将上一帧和当前帧的结果混合
- *Deferred Shading 延迟渲染*
  - 见 GAMES104
- *Tiled Shading & Clustered Shading*
  - 见 GAMES104
- *Level of Detail (LOD)*
  - 比如 Cascaded Shadow Map, Cascaded LPV
  - 再比如 Geometry LOD，预先产生一个细模，根据距离决定简化程度用于渲染
    - 会有 popping artifacts，解决办法是 leave it to TAA（本身就适宜处理这种时序上的变化）
    - 这就是 UE5 的 Nanite 系统的原理
  - 一些技术上的难题
    + 不同部位的 LOD，如何避免缝隙？(how to become waterproof)
    + 动态加载 LOD，如何利用 cache？（提一嘴，虚拟纹理）
    + 使用 geometry textures 表示 geomertry（没听懂，好像是 GAMES102 的内容）
    + 如何用 clipping, culling 等方法来加速？
- *Global Illumination Solutions*
  - 回忆经典的 SSR 的 fail case，没有任何的 GI 解决方法可以应对所有情况，除了直接上 RTRT。于是工业界很自然的思路是 hybrid solutions：先做一遍 SSR 得到一个近似的 GI，对于 SSR failure cases，使用 hardware / software ray tracing 来补充
  - Software Ray Tracing
    - \* 用 SDF 加速 ray tracing，对近处着色点用 high quality SDF，对远处用 low quality SDF
    - \* 如果场景中有强烈的方向光源或者点光源（e.g. 手电筒），通过 RSM 解决
    - 如果场景偏 diffuse，通过 DDGI (dynamic diffuse GI) 解决，这部分没讲，总之是 3D grid 中的 probes
  - Hardware Ray Tracing
    - \* RTRT 的 indirect illumination 没必要那么精确，没必要用原始的 geometry，使用 low-poly proxies 即可（用简化模型代替原始模型）
    - Probes (RTXGI)，RTRT 结合 probe 的思路，叫做 RTXGI
  - 以上带 \* 的方法结合起来就是 UE5 的 Lumen 系统
- 这门课没涉及到的（前面的区域，以后再来探索吧\~）
  + Texturing an SDF
  + Transparent material and order-independent transparency
  + Particle rendering
  + Post processing (depth of field,motion blur, etc.)
  + Random seed and blue noise
  + Foveated rendering
  + Probe based global illumination
  + ReSTIR, Neural Radiance Caching, etc.
  + Many-light theory and light cuts
  + Participating media, SSSSS (screenspace subsurface scattering)
  + Hair appearance
