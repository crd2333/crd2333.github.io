#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "信息论",
  lang: "zh",
)

#let DL = math.op("DL")
= 信息论
- 在学习《统计学习方法》和《机器学习》（周志华）时，经常遇到信息论的一些概念
  - 1948 年，香农将热力学的熵，引入到信息论，因此它又被称为香农熵(Shannon entropy)
  - 这里简单对一些公式进行归纳，不做过多解释
- #link("https://zh.wikipedia.org/wiki/%E7%86%B5_%28%E4%BF%A1%E6%81%AF%E8%AE%BA%29")[熵]
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
- #link("https://zh.wikipedia.org/wiki/%E8%81%94%E5%90%88%E7%86%B5")[联合熵]\(joint entropy)
  $
  H(X, Y) = - sum_(x in X) sum_(y in Y) p(x, y) log p(x, y) \
  H(X, Y) = - int p(x, y) log p(x, y) dif x dif y
  $
  - 描述一对随机变量平均所需要的信息量
- #link("https://zh.wikipedia.org/wiki/%E6%9D%A1%E4%BB%B6%E7%86%B5")[条件熵]\(conditional entropy)
  $
  H(Y|X) = H(X, Y) - H(X) \
  H(Y|X) = - sum_(x in X) p(x) H(Y|X=x) = - sum_(x in X) sum_(y in Y) p(x, y) log p(y|x) \
  H(Y|X) = - int p(x, y) log p(y|x) dif x dif y
  $
  - 在已知随机变量 $X$ 的条件下，随机变量 $Y$ 的不确定性
  - 具有非负性、链式法则与条件减性
- #link("https://zh.wikipedia.org/wiki/%E7%9B%B8%E5%AF%B9%E7%86%B5")[相对熵]\(relative entropy)
  - 或者叫 KL 散度(Kullback-Leibler divergence)
  $
  DL(p||q) = sum_(x in X) p(x) log p(x) / q(x) \
  DL(p||q) = int p(x) log p(x) / q(x) dif x
  $
  - 两个概率分布 $p$ 和 $q$ 之间的差异
  - 具有不对称性，非负性
- #link("https://zh.wikipedia.org/wiki/%E4%BA%A4%E5%8F%89%E7%86%B5")[交叉熵]\(cross entropy)
  $
  H(p, q) = DL(p||q) + H(p) \
  H(p, q) = - sum_(x in X) p(x) log q(x) \
  H(p, q) = - int p(x) log q(x) dif x
  $
  - 两个概率分布 $p$ 和 $q$ 之间的差异，通常是衡量预测分布和真实分布之间的差异，预测越准确，交叉熵越小
  - 具有不对称性，非负性
- #link("https://zh.wikipedia.org/wiki/%E4%BA%92%E4%BF%A1%E6%81%AF")[互信息]\(mutual Information)
  $
  I(X; Y) = H(X) + H(Y) - H(X, Y) = H(X) - H(X|Y) = H(Y) - H(Y|X) = DL(p(x, y)||p(x)p(y)) \
  I(X; Y) = sum_(y in Y) sum_(x in X) p(x, y) log frac(p(x, y), p(x) p(y)) \
  I(X; Y) = int p(x, y) log frac(p(x, y), p(x) p(y)) dif x dif y
  $
  - 可以把互信息看成由于知道 $Y$ 值而造成的 $X$ 的不确定性的减小，反之亦然（即 $Y$ 的值透露了多少关于 $X$ 的信息量），例如，如果 $X$ 和 $Y$ 相互独立，则 $I(X; Y) = 0$
  - 具有对称性、非负性、极值性