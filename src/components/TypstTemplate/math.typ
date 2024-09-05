#import "@preview/quick-maths:0.1.0": shorthands
#import "@preview/mitex:0.2.4": *

// 以类似格式添加符号缩写
#let shorthand = shorthands.with(
  ($+-$, $plus.minus$),
  ($|-$, math.tack),
  ($=<$, $<=$),                // =< becomes '≤'
  ($<==$, math.arrow.l.double), // Replaces '≤'，似乎需要某一边有东西才能正常工作，原因未知
  ($~$, $med$),
)

// 以类似格式添加文本缩写
#let le = $<=$
#let ge = $>=$
#let infty = $infinity$
#let int = $integral$
#let wave = $tilde$ // alternative to ~
// $wave$, $prop$, $approx$
#let r1 = $rho_1$
#let r2 = $rho_2$
#let si = $sigma$
#let Si = $Sigma$
#let s1 = $sigma_1$
#let s2 = $sigma_2$
#let de = $delta$
#let De = $Delta$
#let d1 = $delta_1$
#let D1 = $Delta_1$
#let d2 = $delta_2$
#let D2 = $Delta_2$
#let al = $alpha$
#let a1 = $alpha_1$
#let a2 = $alpha_2$
#let an = $alpha_n$
#let aN = $alpha_N$
#let ta = $tau$
#let th = $theta$
#let t1 = $theta_1$
#let t2 = $theta_2$
#let tn = $theta_n$
#let tN = $theta_N$
#let ep = $epsilon$
#let ep1 = $epsilon_1$
#let ep2 = $epsilon_2$
#let ga = $gamma$
#let g1 = $gamma_1$
#let g2 = $gamma_2$
#let la = $lambda$
#let l1 = $lambda_1$
#let l2 = $lambda_2$
#let ln = $lambda_n$
#let lN = $lambda_N$
#let La = $Lambda$
#let L1 = $Lambda_1$
#let L2 = $Lambda_2$
#let Ln = $Lambda_n$
#let LN = $Lambda_N$
#let p1 = $pi_1$
#let p2 = $pi_2$
#let pn = $pi_n$
#let pN = $pi_N$
#let na = $nabla$
#let di = $dif$
#let pa = $diff$ // partial

// 文本运算符
#let argmax = math.op("argmax")

// 带圈数字，在 sym 里没找到，Unicode 字符中的又太小，故自己实现，希望没 bug
#let czero  = box(baseline: 15%, circle(radius: 5pt)[#align(center + horizon, "0")]) // circle zero
#let cone   = box(baseline: 15%, circle(radius: 5pt)[#align(center + horizon, "1")])  // circle one
#let ctwo   = box(baseline: 15%, circle(radius: 5pt)[#align(center + horizon, "2")])
#let cthree = box(baseline: 15%, circle(radius: 5pt)[#align(center + horizon, "3")])
#let cfour  = box(baseline: 15%, circle(radius: 5pt)[#align(center + horizon, "4")])
#let cfive  = box(baseline: 15%, circle(radius: 5pt)[#align(center + horizon, "5")])
#let csix   = box(baseline: 15%, circle(radius: 5pt)[#align(center + horizon, "6")])
#let cseven = box(baseline: 15%, circle(radius: 5pt)[#align(center + horizon, "7")])
#let ceight = box(baseline: 15%, circle(radius: 5pt)[#align(center + horizon, "8")])
#let cnine  = box(baseline: 15%, circle(radius: 5pt)[#align(center + horizon, "9")])
