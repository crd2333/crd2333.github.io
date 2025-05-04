---
order: 4
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GAMES202 笔记",
  lang: "zh",
)

有点后悔没有早点开始看这门课，里面的很多概念当初我在网上四处扒资料才理解了一点点……

- 其他可以参考的笔记
  + #link("https://zhuanlan.zhihu.com/p/363333150")[知乎 | Games202 高质量实时渲染课堂笔记 by CarlHer]
  + #link("https://www.zhihu.com/column/c_1473816420539097088")[知乎 | GAMES202 高质量实时渲染-个人笔记 by 风烟流年]（这个可能整理得更好一些）
  + #link("https://blog.csdn.net/yx314636922/category_11601225.html")[CSDN | GAMES202 by 我要吐泡泡了哦]（这个也不错）

另外，这门课据闫令琪的说法，不会有 GAMES101 那样贯穿的主线，而是分几个 topic 来介绍。Global Illumination (GI) 部分加入 GAMES104 的内容。

#let occ = math.text("occ")
#let unocc = math.text("unocc")
#let dst = math.text("dst")
#let src = math.text("src")
#let into = $int_Om$
#let intop = $int_(Om^+)$

= Lec10/11: Real-time Physically-Based Rendering
- 微表面模型 Microfacet
  $ f_r (om_o, om_i) = frac(F_r (om_o) G(om_o,om_i) D(w_h), 4 (n dot om_o) (n dot om_i)) $
  - Fresnel Term
    - 一般采用 Schlick approximation
  - Geometry (Shadowing-Masking) Term
    - 描述微表面的自遮挡现象，主要是 grazing angle 时做一定惩罚
    - 为了解决能量守恒问题 (no consideration for multiple bounce)，需要补偿项，一般用 Kulla-Conty Approximation，其推导略复杂。
      - 先考虑不带颜色（没有任何能量吸收），假设白炉测试，积分出来的 $1-E(mu_o)$ 不带入射角度。然后对一般情况利用光路可逆性再加一个归一化项 $c$ 使得两式相等，从而把入射方向纳入考虑，算出 $E_avg$
      - 进一步，对带颜色的，又引入 $F_avg$
      - 工业界常常使用 mocrofacet 和 diffuse 混合使用的方法，这是完全错误的，会导致能量不守恒！
  - Normal Distribution Term
    - 描述微表面的分布，一般用 Beckmann 或 GGX (Trowbridge-Reitz)，或者 GTR (Generalized Trowbridge-Reitz)
  - 此外还讲了一个基于 microfacet 的方法，叫做 LTC (Linearly Transformed Cosines)，没太听懂，但总之宗旨是：把变化 BRDF + 变化光源通过一个变换矩阵变成固定 BRDF + 变化光源（将标准空间中的反射波瓣线性映射到余弦空间），从而固定的 BRDF 为 cosine 的形式具有解析解
- Disney Principled BRDF
  - 没有细讲，介绍了其相关特点
- 以及介绍了 PBR 的对立面 NPR (Non-Physically Based Rendering)
  - 首先介绍了一堆卡通渲染的例子
  - outline，主要分为 shading, geometry, postprocessing 三种方法
  - color block，对正常渲染的结果进行阈值化，可以是渲染过程中做，也可以是后处理做
  - stroke surface，根据明暗给物体表面加上笔划，主要是用纹理贴图来做