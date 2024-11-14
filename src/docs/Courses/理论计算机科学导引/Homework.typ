#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "TCS HW",
  lang: "zh",
)

= HW 注意点
- HW1, Q1
  - (g) 注意 superset
- HW1 Q6, Q7, Q8 都用到了 $q_"dead"$ 的概念
  - 即 DFA 每个状态所有的 transition 都应该写出来（即使它 transit 到 $q_"dead"$）
  - 而 NFA 不用，如 HW2 Q3 题设
- HW2 Q2 总是少考虑情况
- HW2 Q4 常看常新
- HW2 Q5 (a) 形象来说就是把原本 state diagram 的边都*加粗*
- 比较 HW1 Q4 and HW2 Q1
  - Let $A$ be a regular language over $Sigma$. Consider the following language. $ overline(A) = {w in Sigma^*: w in.not A} $ Show that $A$ is regular.
    - Sol: exchanging the role of final and non-final states
  - Let $M$ be an arbitrary NFA. Let $M'$ be the NFA obtained from $M$ by exchanging the role of final and non-final states. Is it always true that $L(M) subset L(M') = emptyset$? Give a proof or a counter-example.
  - 有时间思考一下两个问题的本质

- HW7, Q1
  - 最后的解法采用 state diagram 的方式，对于这一点有一个定理（跟 pumping theorem 的证明相关）
  #theorem()[
    给定一个状态数为 $n$（$n$ 就是 pumping theorem 的 $p$）的 DFA $A$，$L(A)$ is infinite $<==>$ $A$ 接受一个长度 $n =< abs(w) < 2n$ 的字符串（$2n$ 的条件其实不需要，但加上也没事，Q1 借此限制搜索长度）
  ]