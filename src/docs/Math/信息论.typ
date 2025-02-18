#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "信息论",
  lang: "zh",
)

#let KL = math.text("KL")
#let JS = math.text("JS")

= 信息论
- 在学习《统计学习方法》和《机器学习》（周志华）时，经常遇到信息论的一些概念
  - 1948 年，香农将热力学的熵，引入到信息论，因此它又被称为香农熵 (Shannon entropy)
  - 这里简单对一些公式进行归纳，不做过多解释
  - 另外可以参考 #link("https://www.cnblogs.com/jins-note/p/12596827.html")[信息熵、交叉熵、KL散度、JS散度、Wasserstein距离
]
- #link("https://zh.wikipedia.org/wiki/%E7%86%B5_%28%E4%BF%A1%E6%81%AF%E8%AE%BA%29")[*熵 (entropy)*]
  $
  H(X) = - sum_(x in X) p(x) log_b p(x) \
  H(X) = - int p(x) log_b p(x) dif x
  $
  - 熵是对不确定性的度量（或者说多样性 diversity 的度量），熵越大，不确定性越大，正确估计其值的可能性就越小（需要越大的信息量用以确定其值）
  - 单位取决于定义时对数的底。当 $b = 2$，熵的单位是 bit（通常来讲我们只用管这个，后面默认 $b = 2$）
  - 具有非负性、对称性（重排概率不变）、极值性
  - 加权形式：加权熵(weighted entropy)
    $
    H_w (X) = - sum_(x in X) w(x) p(x) log p(x) \
    H_w (X) = - int w(x) p(x) log p(x) dif x
    $
    - 就比普通熵多了一个权重 $w(x)$，用以刻画不同信息的重要性
- #link("https://zh.wikipedia.org/wiki/%E8%81%94%E5%90%88%E7%86%B5")[*联合熵 (joint entropy)*]
  $
  H(X, Y) = - sum_(x in X) sum_(y in Y) p(x, y) log p(x, y) \
  H(X, Y) = - int p(x, y) log p(x, y) dif x dif y
  $
  - 描述一对随机变量平均所需要的信息量
- #link("https://zh.wikipedia.org/wiki/%E6%9D%A1%E4%BB%B6%E7%86%B5")[*条件熵 (conditional entropy)*]
  $
  H(Y|X) = H(X, Y) - H(X) \
  H(Y|X) = - sum_(x in X) p(x) H(Y|X=x) = - sum_(x in X) sum_(y in Y) p(x, y) log p(y|x) \
  H(Y|X) = - int p(x, y) log p(y|x) dif x dif y
  $
  - 在已知随机变量 $X$ 的条件下，随机变量 $Y$ 的不确定性
  - 具有非负性、链式法则与条件减性
- #link("https://zh.wikipedia.org/wiki/%E7%9B%B8%E5%AF%B9%E7%86%B5")[*相对熵 (relative entropy)*]
  - 或者叫 *KL 散度 (Kullback-Leibler divergence)*
  $
  KL(p||q) = sum_(x in X) p(x) log p(x) / q(x) \
  KL(p||q) = int p(x) log p(x) / q(x) dif x
  $
  - 两个概率分布 $p$ 和 $q$ 之间的差异
  - 具有不对称性，非负性
  - *KL 散度在 AI 中极其常用*
    - 跟传统距离度量的区别在于，它衡量两个概率分布之间的差异，而不是两个确定的点之间的差异
    - 因此在比如 GAN, Diffusion 等生成模型中，KL 散度是一个重要的优化目标
  - *JS 散度 (Jensen-Shannon divergence)*
    $
    JS(p||q) = frac(1, 2) KL(p mid(||) (p+q)/2) + frac(1, 2) KL(q mid(||) (p+q)/2)
    $
    - 解决了 KL 散度非对称的问题，取值范围在 $[0, 1]$
  - *Wasserstein 距离*
    $ W(p, q) = inf_(ga in oPi(p, q)) int int ||x - y|| dif ga(x, y) $
    - $oPi(p, q)$ 是 $p$ 和 $q$ 之间所有可能的联合分布的集合，对每个可能的联合分布 $ga$，采样得到 $x, y$，对 $x, y$ 的距离求期望，所有 $ga$ 的期望值下界就是 Wasserstein 距离
    - Wessertein 距离相比 KL 散度和 JS 散度的优势在于：即使两个分布的支撑集没有重叠或者重叠非常少，仍然能反映两个分布的远近；而 JS 散度在此情况下是常量，KL 散度可能无意义
    - Wasserstein 被应用于 GAN，缓解了训练不稳定的问题
- #link("https://zh.wikipedia.org/wiki/%E4%BA%A4%E5%8F%89%E7%86%B5")[*交叉熵 (cross entropy)*]
  $
  H(p, q) = KL(p||q) + H(p) \
  H(p, q) = - sum_(x in X) p(x) log q(x) \
  H(p, q) = - int p(x) log q(x) dif x
  $
  - 两个概率分布 $p$ 和 $q$ 之间的差异，通常是衡量预测分布和真实分布之间的差异，预测越准确，交叉熵越小
  - 具有不对称性，非负性
- #link("https://zh.wikipedia.org/wiki/%E4%BA%92%E4%BF%A1%E6%81%AF")[*互信息 (mutual Information)*]
  $
  I(X; Y) = H(X) + H(Y) - H(X, Y) = H(X) - H(X|Y) = H(Y) - H(Y|X) = KL(p(x, y)||p(x)p(y)) \
  I(X; Y) = sum_(y in Y) sum_(x in X) p(x, y) log frac(p(x, y), p(x) p(y)) \
  I(X; Y) = int p(x, y) log frac(p(x, y), p(x) p(y)) dif x dif y
  $
  - 可以把互信息看成由于知道 $Y$ 值而造成的 $X$ 的不确定性的减小，反之亦然（即 $Y$ 的值透露了多少关于 $X$ 的信息量），例如，如果 $X$ 和 $Y$ 相互独立，则 $I(X; Y) = 0$
  - 具有对称性、非负性、极值性