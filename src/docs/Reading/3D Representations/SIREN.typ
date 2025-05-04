---
order: 2
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Reading SIREN",
  lang: "zh",
)

#let SDF = math.text("SDF")
#let clamp = math.text("clamp")
#let Occupancy = math.text("Occupancy")
#let NeRF = math.text("NeRF")

= SIREN
- Implicit Neural Representations with Periodic Activation Functions
- 时间：2020.6
== 引言
- 感兴趣的是一类特殊函数：
  $
  F (x, Phi, nabla_x Phi, nabla^2_x Phi, ...) = 0, Phi : x arrow.r.bar Phi(x)
  $
  目标是学习一个神经网络，该神经网络对 $Phi$ 进行参数化，以将 $x$ 映射到某个感兴趣的量，同时满足上式约束（跨科学领域的各种问题都属于这种形式）
- 与替代方案（例如基于离散网格的表示）相比，连续参数化具有多种优势。
  + 具有更高的内存效率，从而它的建模不受限于网格分辨率，而是受限于底层网络架构。
  + 可微分意味着可以分析计算梯度和高阶导数，例如使用自动微分
  + 最后，通过良好的导数，隐式神经表示可以为解决反问题（例如微分方程）提供新的工具
- 因此隐式神经表征引起了人们的兴趣。大多数表示都建立在基于 ReLU 的 MLP 之上，这些架构缺乏表示底层精细细节的能力，并且通常不好表示目标信号的导数。
  - 部分原因是 ReLU 的分段线性导致二阶导数处处为零，高阶信息缺失。
  - 虽然替代激活函数（例如 tanh 或 softplus）能够表示高阶导数，但我们证明它们的导数通常表现不佳，也无法表示精细细节
- 为了解决这些限制，我们利用具有周期性激活函数的 MLP 来实现隐式神经表示。我们证明，这种方法不仅能够比 ReLU-MLP 或并行工作中提出的位置编码策略更好地表示信号中的细节，而且这些属性也独特地适用于导数，这对于许多应用来说至关重要
- 贡献总结
  + 提出周期性激活函数，可以稳健地拟合复杂信号，例如自然图像和 3D 形状及其导数
  + 用于训练这些表示并验证可以使用超网络学习这些表示的分布的初始化方案。（利用 hypernetwork 的网络初始化方案）
  + 应用演示：图像、视频和音频表示；3D 形状重建；求解旨在估计信号的一阶微分方程仅用其梯度进行监督；并求解二阶微分方程
  - 这里面比较核心的其实应该是第二点，因为第一点相信很多人都想过，只是因为效果不好导致没人用，现在作者提出好的初始化方案使得这个方法变得可行

== Formulation
- 把上面说的那个函数表示为可行集问题 ${C_m (a(x), Phi(x), nabla Phi(x), nabla^2 Phi(x), ...)}_(m=1)^M$，满足 $M$ 个约束，每个都把 $Phi$ 关联到 $a(x)$（？）
  $ "find" Phi(x) "subject to" C_m (a(x), Phi(x), nabla Phi(x), nabla^2 Phi(x), ...) = 0, ~~~~ forall x in Omega_m, m = 1, ..., M $
#note[
  paper 中的 notation 对初学者来说可能有些不适，因为长期以来使用神经网络处理图像数据时，input 大多情况下是图像本身(e.g. matrices with RGB channels)；但是这篇 paper 中，我们用神经网络所学是 $Phi$，这里面的 input 是 pixel coordinate（即 $x=(i, j)$），而 $Phi(x)$ 代表着不同 pixel value。$Phi(x)$ 表示对给定的像素位置输入，学出来网络认为这里的值是什么。而 $a(x)$ 表示这个像素位置的 ground truth，所以说每个约束都把 $Phi$ 关联到 $a(x)$，意思是约束神经网络往 $a$ 的方向学。这一点需要格外注意
]
- 损失函数就是在所有约束上的偏差
  $ L = int_Omega sum_(m=1)^M bold(1)_(Omega_m) (x) dot norm(C_m (a(x), Phi(x), nabla Phi(x), nabla^2 Phi(x), ...)) dif x $
- 损失函数通过采样 $Omega$ 来强制执行（意思是说通过数据集采样模拟真实模型？），数据集 $D = {(x_i, a(x_i))}$ 是一组坐标 $x_i in Omega$ 以及约束中出现的量 $a(x_i)$ 的样本的元组
  $ tilde(L) = sum_(i in D) sum_(m=1)^M norm(C_m (a(x), Phi(x), nabla Phi(x), nabla^2 Phi(x), ...)) $
- 总之就是定义了一套数学语言来描述这么个事情：为了找到比较好的 $Phi(x)$ 值，设计了一个 loss 损失函数，通过最小化这个损失函数，模型可以捕捉输入数据的周期性结构，学习到这个图片的隐式神经表示

=== 隐式神经表示的周期性激活函数
- 文章提出的核心 idea，即用 $sin$ 函数来做激活函数
  $ Phi(x) = W_n (phi_(n-1) circle phi_(n-2) circle ... circle phi_0) (x) + b_n, ~~~~ x_i arrow.r.bar phi_i (x_i) = sin(W_i x_i + b_i) $
  - 神经网络设为 $n$ 层 layer ，每层线性层计算操作为 $W_i * x_i + b_i$ ，并添加 $sin$ 操作，注意每个 $sin$ 是带缩放的（这一点好像论文里都没怎么提到，直到后面第一层初始化那里才说，令人费解）
  - 第 $0$ 到 $n-1$ 层，线性操作 + 激活 （最后层不加激活，避免值域错误）
- 有趣的是，SIREN 的任何导数本身就是 SIREN，因为正弦的导数是余弦，即相移正弦。因此，SIREN 的导数继承了 SIREN 的属性，使我们能够用“复杂”信号来监督 SIREN 的任何导数。
  - 在实验中发现，当使用涉及 $Phi$ 导数的约束 $C_m$ 来监督 SIREN 时，函数 $Phi$ 仍然表现良好，这对于解决许多问题（包括边值问题 BVPs）至关重要
  - 意思是说
    + 即便我们用的是一张图片的 pixel value（零阶）进行的训练，训练之后的 SIREN 也可以“顺便”很好地重构出一阶、二阶导函数的信息
    + 反过来，我们也可以用图像的导数图来训练网络，而不是直接用图像本身。而这样的网络依旧可以还原出原图
    - 换句话说，SIREN 利用 sin 函数的导数不变性，真正做到了把低阶信息和高阶信息一起学到了，这就让这种隐式神经表示非常强大

=== 激活、频率的分布和有原则的初始化方案
#quote()[
  原文的基本思路是：我们希望初始化的方式可以保证无论我们身处于神经网络的哪一层 layer，其 output 的分布都是差不多的，这样的话我们在做 back-propagation 的时候，gradients 就不太可能会 vanish 或者 explode。那么要如何去找这样的初始化方式呢？首先假设我们的 weights 是来自 uniform distribution 的（但是其区间待定），这样在穿过下一个 $sin(dot)$ 之后分布就变成了 $arcsin$ 的。于是，在下一层的时候就是一堆 $arcsin$ distributed 的随机变量的 weighted sum，使用中心极限定理可以推出当 neuron 个数很多的时候，这个 linear combination 是趋近于正态分布的，它的方差也是可计算的。最后我们可以通过这个方差来反推出最一开始那个待定区间的 uniform distribution 是什么。（然后再用那种递归的 argument 就可以说明，每一层我们都这么搞的话，每一层的 output distribution 就都差不多是 invariant 的了。这也是 supplement material 里的那张图想证明的事）
]
- 这里加上 supplement 一大堆证明看不太懂，总而言之就是（这里论文好像有笔误？）
  $ w_i tilde cal(U)(-sqrt(c/n), sqrt(c/n)) $
  - 然后建议 $c = 6$，使得每个正弦激活函数的 output distribution 都是正态分布，标准差为 $1$。由于只有少数权重的大小大于 $pi$，因此整个正弦网络的频率增长缓慢
  - 至于第一层（？
  - 最后，建议对正弦网络的第一层 sin 缩放权重初始化为 $w_0 = 30$，以便正弦函数 $sin(w_0 dot W x + b)$ 跨越 $[-1, 1]$ 上的多个周期，实验证明很有效

== 实验
- SIREN 这个网络究竟能干什么呢？比如说以 Image experiments 为例
  - 模型的输入维度就是 $2 (x, y)$，输出维度就是 $3 ("RGB")$，中间 layer 宽度为超参
  - 训练集是一张特定图片，对它的长宽随机采样（比例较小，相当于掩码学习）一些像素点坐标作为输入，然后从图片中取出对应像素值作为 ground truth，这样构成整个训练集，训练网络
  - 测试时，把整张图片的所有像素点坐标输入到网络中，得到的输出就是重建的图片，换句话说，就是从被掩码的图像中重建，预测了没看过的像素
- 另外一点则是（前面讲过）SIREN 的训练结合了高阶信息
- SIREN 可以运用于 图像、视频和音频表示，3D 形状重建；求解微分方程等

== 评价
- 实验效果确实还是不错的看起来
- 看了眼知乎上的评价
  + 这篇文章的重点是将周期激活应用在 Implicit Neural Representations 上，INR 是以坐标为输入，像素为输出的一种坐标拟合场景任务，训练过程相当于让网络去记住固定的空间位置代表的是什么像素，当图像中的周期性比较强的时侯，传统的 Relu, tanh 自然不能很好拟合。而 sin 通过对坐标特征进行周期激活后，能很好还原周期信息
  + 有人指出在 out-of-sample 上的数据表现很不好；但是冥冥之中觉得论文也许有些更深刻的启示性（跟 Fourier Analysis 的联系？）
  + 有人说 insight 很足，实验组织也不错，但是试了一下比 ReLU + Positional Encoding 的效果差，认为能够找出那几个实验支持是核心
  + 有人说：如果数据分布都是在 $-pi/2$ 到 $pi/2$ 之间，sin 激活函数跟 sigmoid 没什么区别，特别是用上 BN 的技术，这是完全可以做到的。但是论文里没有用 BN，而是提出了一个适配 sin 的权重初始化技术。普适性不强，也根本没办法迁移到其它工作里去。
  + 用 sin 激活和用深一点的 deep relu 表达能力差别不大。关键在于正常的 deep relu 没有加显示的正则它是捕捉不到周期信息的（尽管它的拟合能力理论上能做到这点）。这篇论文用 sin 让网络显式的去做这一点。但是，单单用 sin 还是不够，为了能出效果才需要一个依据 lazy training 的特性、和深度无关的初始化，在这组初始化附近就能完成训练。总结就是这个 sin 策略还是太敏感了。用起来可能不是那么方便

== 论文十问
+ 论文试图解决什么问题？
  - 表征复杂自然信号及其衍生物（图像、波场、视频、声音及其导数），可解决特定方程
+ 这是否是一个新的问题？
  - 不算新吧，已有 ReLU-based MLP 的方法（或者别的激活函数），只是 sin 的好的运用应该还是第一次，好像还被 Hinton 点赞了
  - 之前有过一篇 #link("https://openreview.net/forum?id=Sks3zF9eg")[Taming the waves: sine as activation function in deep neural networks]，是一篇有一定引用但最终被 ICLR2017 拒绝了的文章，同行评审里面有谈到用这种周期函数作为激活函数的应用任务范围有点太有限了，这篇文章将其拓展到稍微更多的应用场景，但感觉其实还是略局限
+ 这篇文章要验证一个什么科学假设？
  - 证明这种正弦网络非常适合表示复杂的自然信号（隐式神经表示）
+ 有哪些相关研究？如何归类？谁是这一课题在领域内值得关注的研究员？
  - 本文提到的相关研究：
    + Implicit Neural Representations：全连接网络可实现隐式神经表示，可通过符号距离函数、占用函数等训练获得。在外观编码、时间感知拓展和部分级语义分割也有相关变体
    + Periodic Nonlinearities（非线性周期）：通过单层隐藏网络模拟傅里叶变换，探索了用于简单分类任务的周期性激活神经网络和循环网络。已有余弦激活函数进行图像表示的方法，但是探索导数或本文工作的其他应用。本文探索了具有周期激活函数的 MLP，探索用于隐式神经表示及其衍生物的应用，并提出了原则性初始化和泛化方案
    + Neural DE Solvers（微分方程求解器）：神经网络求解微分方程已有长久的研究，早期简单的神经网络模型由 MLP 或 radial basis function(RBF) networks 组成，具有很少的隐藏层和 tanh or sigmoid 激活函数。本文表明，常用的基于平滑、非周期激活函数的常用 MLP 即使在密集监督下也不能准确模拟高频信息和高阶导数。神经 ODE 与该主题相关，但本质上非常不同
+ 论文中提到的解决方案之关键是什么？
  - $sin$ 的使用我感觉应该不是特别开创，但之前的工作不一定有效，关键应该就是 $sin$ 的权重如何初始化，论文对此进行了数学上的证明和实验上的验证，得到了一个不错的结果
+ 论文中的实验是如何设计的？
  - 做了一系列实验证明它的 claim
    + Solving the Poisson Equation
    + Representing Shapes with Signed Distance Functions，在三维结构重建问题下对比了 ReLU 和 SIREN，可明显的看到 SIREN 相较于 ReLU 重构出更多的结构细节，对物体表面恢复更光滑（图 4）
    + Solving the Helmholtz and Wave Equations，求解了以绿点为中心，均匀传播的亥姆霍兹方程（图 5），其中只有 SIREN 函数能够很好匹配原始结果，而其他激活函数(RBF, tanh, ReLU)均求解失败
    + Learning a Space of Implicit Functions
+ 用于定量评估的数据集是什么？代码有没有开源？
  - 数据集 CelebA；代码开源在 #link("https://github.com/vsitzmann/siren")[github.com/vsitzmann/siren], #link("https://github.com/lucidrains/siren-pytorch")[github.com/lucidrains/siren-pytorch]
+ 论文中的实验及结果有没有很好地支持需要验证的科学假设？
  - 公式总感觉有点 typo 或者和代码不太相符，但是在各个实验结果上看起来还是不错的，应该算能支持科学假设
+ 这篇论文到底有什么贡献？
  - 提出 sin 激活函数并提供一种行之有效的初始化方法，另外提供了各种应用演示
+ 下一步呢？有什么工作可以继续深入？
  - 好像没法真正嵌入到别的 MLP 工作里去，应用比较受限？可能还得探索。
  - 跟 Fourier Analysis 的联系？数学上的分析
