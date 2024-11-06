#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "计算机视觉导论",
  lang: "zh",
)

#info()[
  - 部分参考 #link("https://lhxcs.github.io/note/AI/cv/icv/")[lhxcs 的计算机视觉笔记]
]

= Introduction
== What's Computer Vision
- Computer vision tasks
- 3D reconstruction 3D 重建
  3D reconstruction 3D重建, localization 定位, SLAM 即时定位重建, ……
- Image undestanding 图像理解
  Image recognition 图像识别, object detection 物体识别, image segmentation 图像分割, action recognition 动作识别, deep learning 深度学习, ……
- Image synthesis 图像合成
  Colorization 着色, super-resolution 超采样, debluring 去模糊, HDR 合成, panorama stitching 全景拼接, free-viewpoint rendering 自由视角渲染, GANs 生成对抗网络, ……
- 我们人类看到的是图像，而计算机看到的是像素值
  - computers can be better at computing
  - humans are better at understanding
  - 但具体为什么，还有待对人类智能的研究
  - 人类视觉常常被误导

== What's Computer Vision used for
- 计算机视觉的各种应用，略

== Course Overview
- Basics (Lec.2 - Lec.4)
- Reconstruction (Lec.5 - Lec.8)
- Understanding (Lec.9 - Lec.11)
- Synthesis (Lec.12 - Lec.13)

== Review of Linear Algebra
- 向量的各种运算
- 矩阵的各种运算
  - 仿射变换
  - 齐次坐标
  - 行列式(marix determinant)：几何意义为行向量或列向量张成的有向面积（体积）
  - 特征值和特征向量
  - 矩阵的特征分解
  - 矩阵的奇异值分解

= Image Formation
- 针孔相机模型
  - 假如直接在物体面前放一个底片，由于像平面上的一个点接收到物体上各个方向的光线，因此无法成像
  - 使用小孔成像使得一一对应关系成立
  - 但是当孔太小时，会产生光的衍射现象；并且孔太小也会导致通光量不足

== 透镜成像
- 放大率
$m=(h_i)/(h_o)=i/o$，当 $o$ 较大时，$i$ 近似等于 $f$，可以说焦距也决定了图像放大率（拍照调焦的原理）

- Field of View(FOV)
取决于焦距与底片(sensor)的大小。从成像质量来看，底片越大越好（每个像素收到的光更多，信噪比更好），因此现在的工业目标就是在缩小底片的同时维持好的信噪比

- 光圈(Aperture)与光圈数(F-number)
通过放大/缩小光圈来控制图像的亮度。$N=f/D$，$f$ 是焦距，$D$ 是光圈直径，光圈数越大，光圈越小，进光量越少。

- Lens Defocus & Blur Circle
当 $f$ 和 $i$ 固定时，理论上只有一个面(深度)在成像平面上是清楚的，所以我们需要对焦（略微调整底片位置或透镜位置，i.e. 调整 $i$）。
弥散圆(Blur circle diameter):$b=D/i' |i'-i|$
#fig("/public/assets/Courses/CV/2024-09-19-11-22-07.png")

- 景深(Depth of Field)
虽然有了弥散圆与 defocus 的概念，但是我们可能会疑惑生活中的照片并非仅有一个深度才是清晰的，这是因为图像并非连续的，而是由一个个方格（像素）构成的，当弥散圆落在一个像素内时，它表现出来也是清晰的，这就引入了景深的概念
#fig("/public/assets/Courses/CV/2024-09-19-11-25-42.png")
$
c = (f^2 (o-o_1))/(N o_1(o-f)) = (f^2 (o_2-o))/(N o_2(o-f))\
"Depth of Field" o_2 - o_1 = (2o f^2 c N (o-f))/(f^4 - c^2 N^2 (o-f)^2)
$

- 综合利用以上概念，可以得到背景虚化、人物清晰的照片
  + Large aperture，增大进光量
  + Long focal length，把上式分子分母同除以 $f(o-f)$，可以得到 $f arrow.tr ~~=>~~ "depth of filed" arrow.br$
  + Near foreground & Far Background，使人物落入景深而背景不在景深内

== Geometric image formation
- 透视投影
#fig("/public/assets/Courses/CV/2024-09-20-17-00-54.png", width: 70%)
- 引入齐次坐标，将投影表示为线性变换
$
mat(f,0,0,0;0,f,0,0;0,0,1,0) vec(x,y,z,1) = vec(f x,f y,z) #sym.tilde.equiv vec(f x/z, f y/z, 1)
$
#fig("/public/assets/Courses/CV/2024-09-19-11-41-05.png", width: 70%)
- 在透视投影中，直线仍然是直的，但长度和角度丢失了。深度信息部分丢失，虽然近大远小，但同一个图像对应无穷多三维形状
- Vanishing points & Vanishing lines
  - 铁路汇聚的尽头就是消失点；两个消失点的连线就是消失线
  - 平面上的任何一组平行线都定义了一个消失点，所有这些消失点的结合就是消失线
  - 不同的平面唯一定义了不同的消失线
- 投影失真 Perspective distortion
  - Problem for architectural photography: converging verticals
  #fig("/public/assets/Courses/CV/2024-09-20-19-38-53.png")
  - Solution: 取景器(view camera)，镜头相对胶片可以移动
  - The distortion is not due to lens flaws.
- 径向失真 Radial distortion
  #fig("/public/assets/Courses/CV/2024-09-20-19-40-21.png", width: 60%)
  - 由现实镜头的非理想性引起，对于穿过透镜边缘的光线更为明显。
  - 分为桶形畸变(barrel distortion)和枕形畸变(pin cushion distortion)
- Orthographic projection 正交投影

== Photometric image formation
- 描述了 3D 世界物理性质与 2D 图像颜色之间的关系
- Image sensor
- Shutter
  - The pixel value is equal to the integral of the light intensity within the exposure time
- Color spaces: RGB, HSV
- Bayer filter
  - 对于彩色图像，需要采集多种基本的颜色，最简单的方法是用滤镜的方法
  - 如果要采集 RGB 三种颜色，则需要三种滤镜，价格昂贵。
  - 而 Bayre Filter 在一块滤镜上设置不同颜色，由于人眼对绿色比较敏感，因此绿色较多
- Model the light reflected by an object : Shading
  - 后面的内容是直接 copy from GAMES101，参见 #link("https://crd2333.github.io/note/Courses/%E8%AE%A1%E7%AE%97%E6%9C%BA%E5%9B%BE%E5%BD%A2%E5%AD%A6/index/")[计算机图形学笔记]


= Image Processing
== Image processing basics
#let blur = math.text("blur")
- 一些基本处理
  + Increase contrast
  + Invert
  + Blur
  + Sharpen
- Convolution
- Padding
- 几种 filter
  - Guassian blur & Sharpen
    - $f(i, j)= 1/(2 pi sigma^2) e^(- (i^2+j^2)/(2 sigma^2))$
    - $sigma$ 越大越模糊
    - Sharpen
      - Let $I$ be the original image
      - High frequencies in image $I=I-blur()$
      - Sharpened image $I'= I+(I-blur())$
  - Edge detection filter
  - Gradient detection filters
  - Bilateral filter
    - 保持边缘的同时去除噪声

== Image Sampling
- 采样时有可能发生失真（反走样/锯齿）现象
- 主要原因是 —— 采样的速度跟不上信号变化的速度（高频信号采样不足）

=== Fourier Transform
- 傅里叶变换本质上是把函数与不同频率的三角函数做内积，得到它在不同频率下的分量
- 即：用不同频率的正余弦函数加权表示原函数
  #fig("/public/assets/Courses/CV/2024-09-26-11-49-09.png", width: 70%)
- PPT 里展示了一些常见的信号的傅里叶变换

=== Signal & Frequency
- Convolution Theorem
  #fig("/public/assets/Courses/CV/2024-09-26-12-00-47.png")
  - Box filter = low-pass filter
  - Wider kernel = lower frequency
- Sampling
  - Sampling a signal = multiply the single by a Dirac comb function（狄拉克函数）
  - Sampling = Repeating Frequency Contents
- Nyquist-Shannon theorem
  - Consider a band-limited signal: has no frequencies above $f_0$
  - The signal can be perfectly reconstructed if sampled with a frequency larger than $2 f_0$
- anti-alisaing
- 其实基本也都是图形学的内容

== Image magnification & minification
- 图像放大时基本使用 Interpolation 或者上采样(AI)
  - Interpolation
    - Nearest neighbor
    - Bilinear
    - Bicubic
- How to change aspect ratio
  - 最简单的方法就是在长宽方面进行不同的缩放，但会导致形变
  - Challenge
    + Changing aspect ratio causes distortion
    + Cropping may remove important contents
  - Solution: Seam Carving for Content-Aware Image Resizing
    - Basic idea: remove unimportant pixels, and edges are important
    $ E(I) = |(diff I) / (diff x)| + |(diff I) / (diff y)| $
    - Find connected path of pixels from top to bottom of which the edge energy is minimal，可以认为就是寻找最短路算法（DP 算法）。然后把这条路的像素扔掉
    #fig("/public/assets/Courses/CV/2024-10-10-10-17-49.png", width: 70%)
    #mitex(`\mathbf{M}(i,j)=E(i,j)+\min\big(\mathbf{M}(i-1,j-1),\mathbf{M}(i-1,j),\mathbf{M}(i-1,j+1)\big)`)
    - seam carving 方法也可以应用于 enlarge image，原理类似

= Model Fitting and Optimization
== Optimization
- 优化的基本范式，与优化基本理论与方法没什么差别
- 一个有趣的 example: Image deblurring
  - 已知模糊图像 $Y$ 和卷积核 $F$，通过优化的方法得到去噪后的图像 $X$
  - 想法是找到清晰的图像 $X$，使得它做模糊处理后与已知的图像 $Y$ 差别尽可能小，于是得到目标函数：
  $ min_X norm(Y - F*X)_2^2 $

=== Model Fitting
- 一个经典的例子：Linear Mean Square Error (MSE)
- 如果假设数据噪声服从*高斯分布*，那么可以与*极大似然估计*联系起来 (Linear MSE = MLE with Gaussian noise assumption)
  $
  b_i = a_i^T + n, ~~~ n tilde.op  G(0, sigma^2) \
  P[(a_i, b_i)|x] = P[b_i - a_i^T x] #sym.prop exp(- (b_i - a_i^T x)^2 / (2 sigma^2)) \
  P[(a_1, b_1) (a_2, b_2) ... (a_n, b_n)|x] #sym.prop exp(- sum_i (b_i - a_i^T x)^2 / (2 sigma^2)) = exp(- norm(A x - b)_2^2 / (2 sigma^2))
  $

== Numerical methods
- 一些问题有 analytical solution，但是大多数问题需要 numerical solution
- Recap: Taylor expansion

=== 梯度下降法 Gradient Descent
==== Steepest descent method
- Advantage
  + Easy to implement
  + Perform well when far from the minimum
- Disadvantage
  + Converge slowly when near the minimum
  + Waste a lot of computation
- Why converge slowly?
  + Only use first-order derivative
  + Does not use curvature

==== Newton's method
- 考虑二阶导数
- Advantage: fast convergence near the minimum
- Disadvantage: Hessian requires a lot of computation

==== Gauss-Newton method
- 使用 Jacobian 矩阵 $J_R^T J_R$ 近似 Hessian 矩阵 $H_F$
- Advantage: faster than Newton's method
- Disadvantage: $J_R^T J_R$ 不正定，未必可逆

==== Levenberg-Marquardt method
$ Delta x = -(J_R^T J_R + lambda I)^(-1) J_R^T R(x_k) $
- Start quickly(远离目标点时使用最速梯度下降)
- Converge quickly(接近目标点时近似高斯牛顿法，保证收敛速度快)
- $J_R^T J_R + lambda I$ 正定，保证高斯牛顿法成立

=== Robust estimation
- Outliers: 使得最小二乘法受很大影响，它会过度放大偏离较大的误差
- Huber loss function
  $ L_"huber" (e) =cases( 1/2 e^2\, |e| =< delta, delta dot |e| - 1/2 delta^2\, |e| > delta) $
  - 在误差较小时，与 MSE 一样，但是在误差较大时，它的影响会减小（减小 outliers 的影响）
- RANSAC: Random Sample Concensus
  - The most powerful method to handle outliers
  - 主要思想：首先我们知道拟合一条直线只需要两个点，因此首先随机找两个点拟合一条直线，然后检查有多少点符合该直线（点到直线的距离小于一定的阈值，就 count++），一直重复该过程，选择 count 最高的直线。

=== Regularization
- L1-norm, L2-norm

= Image Matching and Motion Estimation
== Image Matching
- Main Components of Feature matching
  - Detection: identify the interest points
  - Description: extract vector feature descriptor surrounding each interest point
  - Matching: determine correspondence between descriptors in two views

=== Detection
- 特征点需要满足独特性（至少要在局部唯一）
  - 使用一个小的像素窗口去探测像素的变化（用梯度分布来衡量）
  - 可以用 PCA 算梯度分布的主方向（特征值）
    + flat: $l1, l2$ are small
    + edge: $l1 >> l2$ or $l1 << l2$
    + corner: $l1, l2$ are large, $l1 wave l2$
  - 为了方便计算，引入 Harris operator
- Harris operator
  $ f = frac(l1 l2, l1 + l2) = "determinant"(H)/"tr"(H) $
  - pipeline:
    + Compute derivatives at each pixel
    + Computer matrix $H$ in a Gaussian window around each pixel
    + Compute corner response $f$
    + Threshold $f$（阈值过滤）
    + Find local maxima of response function
  - 除了独特性之外，我们还希望特征点在图像变换（如光学变换和几何变换）中保持不变
    - Corner response is invariant w.r.t image translation and rotation, but not scaling
    #fig("/public/assets/Courses/CV/2024-10-17-10-56-43.png", width: 60%)
    - 一个解决办法是使用不同尺度的 window，但一般我们固定住窗口大小，而去改变图像的大小，形成一个图像金字塔(image pyramid)，二者效果上是等价的（可以想象成是在三维的体素上去找极值）
- Blob detector
  - 除了角点很重要以外，我们也关注斑点
  - 由于斑点的局部性质（在一个小区域内，且一般是闭合的），在像素上具有比较大的二阶导
  - 所以我们的步骤是计算图像的拉普拉斯，然后找到局部最大与最小值
  $ na^2 = frac(diff^2, diff x^2) + frac(diff^2, diff y^2) $
  - 由于 Laplacian 对噪声比较敏感（实际上求导对噪声都很敏感，更何况二阶导），我们通常使用 Laplacian of Gaussian(LoG) filter 进行处理，即首先对图片作高斯模糊，再计算拉普拉斯算子。由卷积的交换律
  $ na^2 (f * g) = f * na^2 g $
  - 同样有 scale 的问题，由高斯分布的方差 $si$ 控制，同样可以用不同尺度来解决，不过这里我们放缩的是 LoG 的 $si$
  - 但我们调 OpenCV 的时候会发现它用的一半是 DoG，它的思想是用两个相邻 $si$ 的 Guassian 近似 Laplacian（因为我们构建图像金字塔的时候本来就要去做前者）
  $ na^2 G_si approx G_si_1 - G_si_2 $

=== Description
- 现在我们已经知道哪些点比较独特，接下来我们要描述这些点（才能匹配），如何做？
  - 首先很容易想到的就是将特征点以及其周围区域像素值 concat 成一个特征向量，但这对位移、旋转非常敏感(i.e.,not invariant)
  - 这里我们介绍 SIFT 描述子（事实上它不仅包含 Description，还包含前面的 Detection）
- SIFT(Scale Invariant Feature Transform)
  - SIFT 使用 patch 的梯度方向分布作为描述子。方向位于 $[0, 2 pi]$ 之间，因此 SIFT 构建一个直方图，来统计在每个区间（例如十等分）有多少个像素。等分个数即为描述子的维度
  #fig("/public/assets/Courses/CV/2024-10-17-11-35-18.png")
  - SIFT are robust to small translations / affine deformations
  - 而对于旋转，会导致直方图循环平移。但这个情况很好处理：选中最大的分量放在第一个进行平移对齐，称作直方图的归一化（朝向归一化）
  - 对于 scaling，很显然地，SIFT 描述子本身是 not invariant to scaling 的，但其实 SIFT 不仅包括 Description，也包括 Detection，经过 DoG 处理后已经确定了 scale 的大小（最佳的 $si$），所以此时不用考虑 scale 的影响
  - Properties of SIFT: Extraodinarily robust matching technique
    + Can handle changes in viewpoint
    + Can handle significant changes in illumination
    + Fast and efficient-can run in real time
  #algo(title: [*Algorithm 1:* SIFT algorithm])[
    + Run DoG detector: find maxima in location/scale space
    + Find dominate orientation
    + For each $(x, y, "orientation")$, create descriptor
  ]

=== Matching
- 有了描述子之后，我们要做的就是将描述相似的特征点匹配起来
  - 简单的思路就是计算两个描述子向量之间的距离，并与最小的匹配，但会造成有歧义的分配
  #fig("/public/assets/Courses/CV/2024-10-17-11-49-36.png", width: 70%)
  - 两种传统解决办法
    + Ratio test: $norm(f1 - f2)/norm(f1-f2')$，容易得知，ambigous matches 会使得这个值比较大
    + Mutual nearest neighbour: 如果 $f1$ 到 $f2$ 匹配正确的话，对 $f2$ 寻找最佳匹配也应该是 $f1$.
- Deep learning for feature matching
  - 表现比传统方法好得多
  - Example: SuperPoint

== Motion Estimation
- Motion estimation problems
  - Feature-tracking
    - 给出两帧画面，估计特征点的运动方向
  - Optical flow
    - Recover image motion at each pixel
    - Output: dense displacement field (optical flow)
  - 二者的主要区别在于 feature tracking 仅限于某些特征点；而 optical flow 估计的是整张图片。但二者使用的方法是一样的：Lucas-Kanade method
- LK 算法的三个主要假设和能推出的方程:
  + *brightness constancy*: same point looks the same in every frame
    $ I(x,y,t) = I(x+u,y+v,t+1) $
  + *small motion*: points do not move very far
    $ 0 approx I(x+u,y+v,t+1) - I(x,y,t) approx I_x u + I_y v + I_t, " i.e. " na I dot [u,v]^T = -I_t $
  + *spatial coherence*: points move like their neighbours。如果使用 $5 times 5$ 的窗口，可以得到 $25$ 个方程
    $ mat(I_x (p_1), I_y (p_1); dots.v, dots.v; I_x (p_25), I_y (p_25)) dot vec(u,v) = - vec(I_t (p_1), dots.v, I_t (p_25)) => A d = b $
- 这时我们就可以使用最小二乘法来求解 $u,v$，它的解 given by $(A^T A) d = A^T b$，即
  $ mat(Si I_x I_x, Si I_x I_y; I_x I_y, I_y I_y) vec(u,v) = - vec(Si I_x I_t, Si I_y I_t) $
  - 当 $A^T A$ 可逆且两个特征值不能太小的时候，该方程有解，这个条件和之前介绍的 Harris corner detector 的条件是一样的
  - 或者说，纹理很丰富，变化很大的角点才有解。反过来，Low Texture Region 和 Edge Region 时会出现问题
- 再另外，当不符合上述三个假设时，LK 算法*也*会出现问题
  - *Brightness constancy* is not satisfied
  - The motion is *not small*
  - A point does *not* move *like its neighbors*
- 对于不满足 small motion 的情况（比如说特征点实际上移动了八个像素），我们有方法可以解决 —— *降采样*！
  - 一个直观的想法就是将图片缩小到原来的八分之一，在缩小后的图片中就满足 small motion 了，处理之后再放大回去。缺点就是在缩小图片的过程中会丢失信息，这样图像移动距离的精度就无法保证
  - 一个想法就是使用*像素金字塔*(*Coarse-to-fine*)。其中金字塔一是时间为 $t$ 时的图像,金字塔二是时间为 $t + 1$ 时的图像。在金字塔上逐层估计,并逐步细化。例如先估计运动距离小于一个像素的最上层图像，根据此估计在金字塔一中的第二层恢复出运动（做一个补偿），再与金字塔二进行比较，此时特征点移动的距离经过较为准确的估计后也小于一个像素，以此类推
  #fig("/public/assets/Courses/CV/2024-10-24-10-11-11.png", width: 80%)

#hline()
Anyway，这些都是相对 old-fashion 的东西，现在效果最好害得看 Deep learning for optical flow

#info(caption: "Takeaways")[
  - Feature matching
    - Detector: Harris corner detector, LoG, DoG
    - Descriptor: SIFT …
    - Matching: ratio test
    - Invariance
  - Motion estimation
    - Feature tracking
    - Optical flow
    - Lucas-Kanade
      - Three assumptions
  - Both feature matching and motion estimation are called correspondence problems
]

= Image stitching
- 图像拼接，比如全景图、VR 等
- 核心问题是，给定两张图片，怎么把它们做一定的几何变换(warping)，然后把它们拼接在一起(stitching)

== Image warping
- 与 lec3 介绍的 image filtering 相比较，filtering 改变的是图像的像素值(intensity)，而 warping 改变的是图像的形状(shape)

== Parametric global warping
- 参数化全局变形，即图像的每一个坐标都遵循同一个变换函数 #h(1fr)
  $ p' = T(p) $
  - 比如 translation, rotation, aspect
  - 这个 $T$ 可以用 matrix 来描述
  - 使用非齐次坐标系的矩阵，都可以叫做*线性变换*，但前面说了不能描述平移(translation)，为此引入其次坐标
  - 仿射变换：Affine map = linear map + translation，并且矩阵最后一行是 $[0, 0, 1]$
  - 如果不是，那就称为 perspective transformation 投影变换，或者叫单应变换(Homography)

== Projective Transformation(Homography)
- Homography #h(1fr)
  $ vec(x'_i, y'_i, 1) approx mat(h_00, h_01, h_02; h_10, h_11, h_12; h_20, h_21, h_22) vec(x_i,yi,1) $
  - $9$ 个系数但自由度为 $8$，因为在其次坐标系里，对整个矩阵乘以一个非零常数不会改变结果
- 在什么情况下两张图片的 transformation 是 homography？
  - Camera rotated with its center unmoved  #h(1fr)
    #fig("/public/assets/Courses/CV/2024-10-24-10-46-00.png", width: 50%)
  - Camera center moved and the scene is a plane
    - 比如，投影仪的结果，在教室左边和右边的人看来还是一样的
- Summary of 2D transformations
  #fig("/public/assets/Courses/CV/2024-10-24-10-54-37.png", width: 70%)

== Implementing image warping
- 或许我们会想，实现 warping 不是很容易吗，只要把当前图片的坐标值根据变化函数映射到另一个坐标上就行了
- 但是考虑一个问题：当前的像素坐标映射后不一定是整数（可以理解为像素值是存放在格点上的，映射后的像素位置不一定在格点上）
- 所以这里我们采取逆变换，即对于每一个需要找的像素点，去找变换前的坐标，同样，大多数时候不会是整数，这时候可以用周围的像素进行插值得到结果

== Image stitching
=== compute transformation
- 现在我们的问题就是给定两张图片, 如何计算出变换矩阵？可以采用如下的方法(DLT)
- 这一块大多是矩阵和公式，懒得打了，看 PPT 吧
- 核心思路就是利用两张图的特征点，列方程组，求解优化问题
- 对于 outliers
  - Recap the idea of RANSAC:
    - All the inliers will agree with each other on the translation vector;
    - The outliers will disagree with each other (RANSAC only ha guarantees if there are $< 50%$ outliers)
  #q[All good matches are alike; every bad match is bad in its own way. ——Tolstoy via Alyosha Efros]

#info(caption: "Summary for image stitching")[
  - Input images
  - Feature matching
  - Compute transformation matrix with RANSAC
  - Fix image 1 and warp image 2.
]

=== Panoramas
- 对于全景，我们处理的是多张图片的拼接
  - 最朴素的方法就是取最中间的图片作为参考，其它所有的图片与中间那张对齐
  - 一个问题是，如果投影到屏幕上，会使得边缘图像的形变很明显 #h(1fr)
  #fig("/public/assets/Courses/CV/2024-10-24-11-31-02.png", width: 70%)
- Cylindrical panoramas
  #fig("/public/assets/Courses/CV/2024-10-24-11-36-52.png", width: 80%)
  - How to compute the transformation on cylinder?
    - A rotation of the camera is a translation of the cylinder! 相机的旋转在柱面上是平移
- Assembling the panorama
  - 在柱形投影的基础上还是会出现问题，就是误差的积累，导致漂移
  #fig("/public/assets/Courses/CV/2024-10-24-11-39-23.png", width: 70%)
  - 我们希望整体误差的和为 $0$，一个解决办法就是将最后一张图和第一张图之间也进行个约束
  #fig("/public/assets/Courses/CV/2024-10-24-11-44-52.png", width: 70%)
- 不过，最终得到的全景图还是会有一些问题，比如直线变弧形、无法应对运动场景等

= Structure from Motion
- Recover *camera poses* and *3D structure* of a scene
- SfM's extension: SLAM
  - 二者的区别在于，SLAM 更注重实时性，而且可以有额外的传感器输入
- 需要解决的几个关键问题
  - 相机是如何将三维坐标点映射到图像平面上的？(camera model)
  - 如何计算相机在世界坐标系下的位置和方向?(camera calibration and pose estimation)
  - 如何从图像中重建出不知道的三维结构？(structure from motion)
#q[这一章节可以部分参考我的 #link("https://crd2333.github.io/note/AI/SLAM/index/")[SLAM 笔记]，以及 SLAM 视觉十四讲]

== Camera Model
#fig("/public/assets/Courses/CV/2024-10-24-11-59-15.png", width: 70%)
- 这整个过程可以总结为三个步骤：
  + 坐标系变换:将世界坐标系的点变换到相机坐标系
  + 透视投影：将相机坐标系的点投影到像平面上
  + 成像平面转化为像素平面：完成透视投影后我们得到的坐标单位是长度单位（毫米、米等），但是计算机上表示坐标是以像素为基本单元的，这就需要我们进行一个转化
- 而这一系列过程可以定义为两个矩阵（两次变换）:
  + 外参矩阵(Extrinsic Matrix): 坐标系变换
  + 内参矩阵(Intrinsic Matrix): 透视投影与转化为像素平面
- 内参外参与总的投影矩阵
  #fig("/public/assets/Courses/CV/2024-10-31-10-20-39.png", width: 70%)
  - 投影矩阵里还分为透视矩阵、仿射矩阵、弱透视矩阵等，可以参考 #link("https://blog.csdn.net/LoseInVain/article/details/102883243")[这篇文章]，讲得很清晰

#note(caption: [CV 内外参矩阵和 CG MVP 矩阵的联系 #h(2em) #text(fill: gray.darken(30%))[纯属个人理解]])[
  - 如果读者对 CG 有所了解的话，就对应于 MVP 里的视图变换 View 和投影变换 Projection，以及视口变换 Viewport
  #fig("/public/assets/Courses/CV/2024-10-31-10-49-32.png", width: 50%)
  - 我们可以把这个过程归纳一下，一共有 $4$ 个坐标系
    + *{world}* 世界坐标系。可以任意指定 $x_w$ 轴 和 $y_w$ 轴，表示物体或者场景在真实世界中的位置
    + *{camera}* 相机坐标系。相机在 {world} 坐标系里有 position, lookat, up，共 $6$ 个自由度。一般我们会把 {world} $->$ {camera} 的过程定义为：position 转到原点，$-z$ 轴作为 lookat，$y$ 轴作为 up
    + *{image}* 图像坐标系，在图形学里我们也叫做 *NDC*(Normalized Device System) 坐标系，即归一化为一个 $[-1,1]^3$ 的正方体
    + *{pixel}* 像素坐标系，也叫屏幕坐标系，图像的左上角为原点 $O_"pix"$, $u, v$ 轴和图像两边重合
  - 从 CG 的视角：Model 矩阵是在 {world} 内的变换；View 矩阵是从 {world} 到 {camera}；Projection 矩阵是从 {camera} 到 {image}；最后 Viewport 矩阵是从 {image} 到 {pixel}
  - 从 CV 的视角，外参矩阵是从 {world} 到 {camera}；内参矩阵是从 {camera} 直接到 {pixel}，但我们又把内外参矩阵的乘积也就是整个过程又称作*投影矩阵*
  - 所谓*投影*，在 CG 中从 {camera} 到 NDC，已经非常接近 image 了（$z$ 只是用于可见性的深度），因此这一步叫做*投影*；而在 CV 中，*投影*取 {world} 直接投射到图像平面之意
    - 命名上的差异，或许可一窥社区趣味与风向。CG 更关注渲染的真实性，在 NDC 坐标系内还要细化光照、着色、光栅化与光追之类，定义得更细节；CV 更关注计算机对视觉的理解，或者说从 3D 到 2D 的匹配与对应，投影概念定义得更宽泛
]

#let b0 = math.bold("0")
#let bp = math.bold("p")
== Camera Calibration
- 有了内外参矩阵的定义后，我们自然想通过像素坐标和实际空间坐标来得到这两个矩阵
  - 个人理解，所谓*标定*更倾向于准确求得内参，毕竟外参也就是位姿时刻会变化，而内参是相机出厂时就固定、且一般商家会明确给出的
- 我们需要同时知道若干像素点的 2D 位置和 3D 世界坐标，所以我们希望有一个东西（标定板）能够使我们方便测量这两种坐标，比如黑白棋盘，它的坐标位置是很方便计算的，可以人为定义世界坐标系（尽可能方便计算）。具体步骤如下：
+ Capture an image of an object with known geometry (e.g. a calibration board)
+ 寻找 3D 场景点和图像特征点的对应关系
+ 每个配对 $i$ 可以得到方程 $[u^((i)),v^((i)),1]^T equiv P [x_w^((i)),y_w^((i)),z_w^((i)),1]^T$，每个都包含两个线性方程
+ Solve $P$
  - 利用之前求解单应矩阵的方法，把 $N$ 个方程转化成 $A bp = b0$ 的形式(Rearranging the terms)，随后
    $ min_bp norm(A bp) ~~~~~ "such that" norm(bp) = 1 $
  - 也就是求解最小二乘法，具体过程不需要掌握，但要知道解就是 $A^T A$ 的*最小特征值*对应的*特征向量*，即可以对 $A$ 应用奇异值分解
+ 最后，把它重组回 $P$，然后分解成内参 $K$ 和外参矩阵，我们把它记为
  $ P_(3*4) = K_(3*3) mat(R_(3*3),bt_(3*1); b0,1) $
  - 通常来说，将一个矩阵分解为两个特定矩阵是做不到的，但是我们的 $K$ 是一个*上三角矩阵*，且外参矩阵中的 $3 times 3$ 旋转子矩阵 $R$ 是*正交*的，因此我们可以通过 QR 分解实现对 $K$ 和 $R$ 的求解，而剩下的 $bt$ 就很好求了

== Visual Localization Problem
- 下面我们来看视觉定位。视觉定位的任务：内参已知，场景已知，通过照片计算出相机位姿（外参）
- 视觉定位总体有两个步骤
  + 第一步(Find 3D-2D correspondences)，找到 3D 场景下的特征点与 2D 图像中的特征点与它们的匹配。本质上是图像的特征匹配，不再赘述
  + 第二步(Solve camera pose)，利用 3D-2D 求解相机位姿（外参）
    - This is called Perspective-n-Point (PnP) problem 多点透视成像问题
- 对于 PnP 问题，有 $6$ 个未知的参数，$3$ 个旋转（$3 times 3$ 但只有 $3$ 个自由度），$3$ 个平移，因此也叫做 6DoF pose estimation 问题
  - 由于一个点对对应两个方程，因此我们至少需要 $3$ 个点对来求解 PnP 问题
- Direct Linear Transform (DLT) solution
  - 最简单的方法，应用之前原始相机标定问题的方法，直接求解投影矩阵，然后再分解为 $K_(3*3) mat(R_(3*3),bt_(3*1); b0,1)$
  - 但这是不合算的，因为我们现在相机内参是已知的，一方面这样求解忽略了已知信息而不高效，另一方面分解出来会有误差
- P3P
  - P3P 就是使用几何上的方法，用最少的点对来求解相机位姿
  - P3P 问题解到最后会有 $4$ 个可能解，因此往往会用 $4$ 个点来保证答案的唯一性（其实也可以把 $4$ 个）
- PnP
  - 其实 3D-2D correspondences 远不止 $3$ 个 $4$ 个，我们可以直接转化为一个优化问题，即最小化*重投影误差(reprojection error)*
  - 给定相机的外参，把三维点投影到图像上，如果外参是对的，则投影点和特征点的距离（误差）应该最小
  $ min_(R,t) sum_i norm(p_i - K(R P_i + t)) $
  - 使用 P3P 问题的解来初始化，并用高斯牛顿法进行优化
    - 当然，这里涉及到选哪三个点，因为 3D-2D 匹配有可能是有问题的，需要找到合理的三个点。怎么做？RANSAC
    - 具体而言，对每组三个点计算 P3P 问题，不优化直接做重投影误差，使用 RANSAC 找出最好的一组，拿来做优化问题的初始值

== Structrue from motion
- 下面再回到 SfM。回顾一下 SfM 的任务：内参已知，场景未知，从多视角图片恢复相机位姿（外参），并重建场景（三维点坐标）
- 一般通过如下步骤
  + Find a few reliable corresponding points
  + Find relative camera position $t$ and orientation $R$
    - 我们可以假定第一张图的相机为相机坐标系的原点，后续计算每一帧相对于上一帧的位姿
  + Find 3D position of scene points

=== Epipolar Geometry 对极几何
- 描述同一个 3D 点，在不同视角的两张图片特征点之间的对应集合关系(2D-2D)
#fig("/public/assets/Courses/CV/2024-10-31-11-09-07.png", width: 70%)
- 在正式开始之前先描述一些术语
  - 基线：两个相机中心的连线，$O_l O_r$
  - 对极点 Epipole：两个相机中心连线与像平面的交点，如图中的 $e_l, e_r$。可以理解为在一个相机视角下另一个相机在该相机平面的投影点
  - 对极平面 Epipolar Plane: 由实际点 $P$ 和两个相机中心形成的平面。对于某个场景中的点，其对极面是唯一的
  - 对极线：对极面与成像平面的交线。
- 对极几何的公式特别多，这里不仔细讲，总体而言的推导思路是
  + 把极平面法向量表示为 $n = t times x_l$，有 $x_l dot n = x_l dot t times x_l = 0$，又有 $x_l = R x_r+t$
  + 转化为 $[x_l, y_l, z_l] E [x_r,y_r,z_r]^T$，当我们算出本质矩阵(Essential Matrix) $E$ 后可以分解 $E=T_times R$ 得到 $R, t$
  + 但我们并不知道场景点相对相机坐标系的三维坐标，只知道像素平面上的二维坐标，要把 $bx_l, bx_r$ 通过内参矩阵转化为像素坐标 $[u_l,v_l,1] (K_l^(-1))^T E K_r^(-1) [u_r,v_r,1]^T = [u_l,v_l,1] F [u_r,v_r,1]^T$，表示成基础矩阵(Fundamental Matrix) $F$ 的形式。由于基础矩阵也是homogenous的，因此在求解时可以加上约束 $norm(f)=1$
  + 也就是求解基本矩阵 $F$，通过已知的相机内参求解出 $E$，再使用 SVD 就得到 $R, t$
- 总体 Pipeline
  + For each correspondence $i$, write out epipolar constraint
  + Rearrange terms to form a linear system
  + Find least squares solution for fundamental matrix $F$
  + Compute essential matrix $E$ from known left and right intrinsic camera matrices and fundamental matrix $F$
  + Extract $R$ and $bt$ from $E$

=== Triangulation 三角测量
- 有了对应的二维特征点，相机参数以及两个相机坐标系的相对位置关系，下一步就是计算出场景点的实际三维坐标
- 左右两个相机的投影矩阵分别可以得到一个 3D-2D 的对应关系
  $
  bu_l = K_l mat(R, bt; b0, 1) bx_r, ~~~~~~ bu_r = K_r bx_r
  $
  - 假如数据都是准确的，那么 $O_l X_l, O_r X_r$ 应该相交于场景点 $X$，但是多数情况下会有误差，不过我们有四个方程三个未知数，可以通过最小二乘得到最优解。用之前同样的方法，rearrange the terms，得到
  $
  A_(4 times 3) bx_r = b_(4 times 1)
  $
  - the least squares solution:
  $ bx_r = (A^T A)^(-1) A^T b $
- 另一种选择是，通过优化重投影误差进行求解
  $ "cost"(P) = norm(bu_l-hat(bu_l))^2 + norm(bu_r-hat(bu_r))^2 $
  - 没有展开

=== Multi-frame Structure from Motion
- 之前我们一直在讲两个图像（两个相机）之间的匹配和测量，现在我们考虑多帧情况下怎么做
- Sequential SFM（或者说增量式的 SfM）步骤：
  + 从其中两张开始，使用前述方法重建
  + 不断取出新的图像，根据已知条件计算相机位姿，新的相机可能看到更多的三维点，并优化现有的点
  + 使用 Bundle Adjustment 进行优化（消除累积误差）
- Bundle Adjustment
  - 在所有相机坐标系下优化所有点的重投影误差 #h(1fr)
  #fig("/public/assets/Courses/CV/2024-10-31-12-03-48.png", width: 70%)
- 其实也有 Global SfM，这里没讲

#v(1em)

- 最后还讲了一个三维重建工具 COLMAP
  - contains SfM, MVS pipeline, with a graphical and command line interface

= Depth estimation and 3D reconstruction



