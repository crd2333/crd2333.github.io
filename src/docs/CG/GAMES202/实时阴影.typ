---
order: 1
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

#let occ = math.text("occ")
#let unocc = math.text("unocc")
#let into = $int_Om$
#let intop = $int_(Om^+)$

= Lec1: Introduction


= Lec2: Recap of CG Basics


= Lec3/4: Real-time Shadows

- *Shadow Map*
  - 最简单的 Shadow Map 算法，用 ray casting 算 visibility，不赘述，会因为像素宽度和视角与平面垂直发生 self-occlusion 问题
  - Second-depth shadow mapping
    - 使用最小深度和次小深度的中间值，但也意味着计算阴影的时间随之翻倍
    - RTR does not trust in Complexity! 实时渲染里面，一切都看最终跑起来的效果，即使复杂度低但常数项大、系数大的算法也不一定能用（不要小看翻倍的代价）
  - Cascade Shadow Map
    - 应对大世界挑战而生的多分辨率阴影贴图
  - *RTR 积分近似方程*
    $ into f(x) g(x) dif x = frac(into f(x) dif x, into dif x) dot into g(x) dif x $
    - 它是 Shadow Map 背后的数学基础，非常重要，后续也会继续用到
      $ L_o (p, om_o) approx frac(intop V(p, om_i) dif om_i, intop dif om_i) intop L_i (p, om_i) f_r (p, om_i, om_o) cos th_i dif om_i $
    - 要求是：要么 support $Om$ 比较小，要么 $g(x)$ 比较光滑（这里的光滑不是导数意义，而是说值变化小，即较平稳的意思）
- *PCSS (Percentage Closer Soft Shadows)*
  #grid(
    columns: (43%, 20%, 30%),
    column-gutter: 8pt,
    fig("/public/assets/CG/GAMES202/2025-04-18-23-46-11.png"),
    fig("/public/assets/CG/GAMES202/2025-04-18-23-37-12.png"),
    fig("/public/assets/CG/GAMES202/2025-04-18-23-37-33.png")
  )
  - PCSS 注意到阴影的软硬程度跟这个像素到被遮挡物的距离有关，于是以自适应的方式调整 PCF 的 window 大小，达成更好的阴影效果
  - 利用那张经典的相似三角形图，利用 blocker depth 显式建模了 window 大小。具体而言，就是在 PCF 步骤之前额外查一次 blocker depth
  - 但是查 blocker depth 本身也要有一个 window 做平均，这里有用 const size 的方法，也有用启发式的方法（离光源越近则一般 window 较大）
- *VSSM (Variance Soft Shadow Map)* (a.k.a. VSM)
  - PCF 的采样过程较慢，利用泊松样斑等方法提高采样效率是一种方法；而 VSSM 是将其视为概率分布，利用均值和方差对其加速
    - 其思想是，我并不需要确切知道窗口内的深度值，只需要知道窗口内深度的排名，也就是分布内的 CDF
    - 首先，如果将其视为高斯分布（只是为了方便理解），那么只用知道 window 内的深度分布的均值和方差就确定其分布的 PDF。均值 $E(X)$ 可以用硬件上的 mipmap 实现；方差可以由 $var(X)=E(X^2)-E^2 (X)$ 得到，也就是在存深度图的时候可以另开一个 channel 存深度平方值
    - 其次，利用切比雪夫不等式估计（视为约等式），哪怕不视为高斯分布也可以直接估计出 CDF 而无需先得到 PDF
  - VSSM 同时也对 blocker search 的过程进行加速，注意这一过程我们需要计算*遮挡物的平均深度* $z_occ$，而无需考虑非遮挡物的深度 $z_unocc$，而我们能观察到下式
    $ N_1 / N z_unocc + N_2 / N z_occ = z_avg $
    - $z_avg$ 用下面介绍的 range query 方法很容易得到，而 $N_1 / N = P(x > t)$，也可以用 Chebychev 得到！
    - 至于剩下的 $z_unocc$，没办法，估计它为 $z_unocc=t$，即跟 shading point 视为同一平面（这是不得已的假设，但是是有道理的，因为绝大多数情况下我们都是在平面上算阴影）
  - 但这里要对 PCSS 和 VSSM 做个比较，后者当然是更高效的算法，但 PCSS 目前反而压过了 VSSM。这是因为我们可以用 PCSS 的低采样噪声版本，即在格子里面取部分 samples；而目前在屏幕空间的降噪技术发展得非常好，我们可以容忍一些噪声
  - *具体实现: MIPMAP and Summed-Area Variance Shadow Maps*
    - 给一个 texture 和 window size，要快速查询出每一点在窗口内的均值 (range query)，这可以用 mipmap 和 summed area table (SAT) 来实现
    - Recall mipmap: 快速的、近似的、方形的 range query。但首先它是方形的（可以用各向异性过滤解决），其次它是近似的、不准的，为此这里介绍 SAT 方法
    - SAT 与算法与数据结构中的前缀和紧密关联，总之就是需要 $O(N)$ 的预计算
    - 问题，跟原本的 PCF 采样比快在哪里？因为每个像素都是并行的，过一次 window 感觉不是很慢呀
- *Moment Shadow Map (MSM)*
  - 在 VSSM 的基础上更进一步引入*矩*的概念（VSSM 可以认为是只用了一阶和二阶矩），从而达成更准的近似（四阶）
  - 具体计算说是非常复杂，没有进一步推导
- *SDF-based Shadow*
  - SDF + ray marching $->$ safe distance
  - SDF for shadow $->$ safe angle
  #fig("/public/assets/CG/GAMES202/2025-04-18-23-51-55.png", width: 80%)
  - SDF 的存储，一般用 hierarchy 的方法存一棵树，只在物体边界的叶子附近才存值。还有一些用深度学习压缩的方法（闫令琪评价：毫无意义！）
  - 至于怎么计算 SDF，一般都认为是其它领域研究的问题（比如 CV，233），CG 这边就当作是能直接拿到的东西
  - SDF 的优势是，在做阴影层面（不考虑生成存储的情况下）对硬阴影软阴影处理相同，比 shadow map 方法快，效果也很不错；另外对于移动物体它也可以处理；但问题在于不好处理物体形变，以及 SDF 生成的物体没法做贴图
