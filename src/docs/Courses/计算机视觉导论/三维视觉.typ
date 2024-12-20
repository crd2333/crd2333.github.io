---
order: 2
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "计算机视觉导论",
  lang: "zh",
)

#info()[
  - 部分参考 #link("https://lhxcs.github.io/note/AI/cv/icv/")[lhxcs 的计算机视觉笔记]
]

#counter(heading).update(4)

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
    + flat: $la1, la2$ are small
    + edge: $la1 >> la2$ or $la1 << la2$
    + corner: $la1, la2$ are large, $la1 wave la2$
  - 为了方便计算，引入 Harris operator
- Harris operator
  $ f = frac(la1 la2, la1 + la2) = "determinant"(H)/"tr"(H) $
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
  #fig("/public/assets/Courses/CV/2024-10-24-10-11-11.png", width: 60%)

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
  - 如何从图像中重建出未知的三维结构？(structure from motion)
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

== Structrue from motion (SfM)
- 下面再回到 SfM。回顾一下 SfM 的任务：内参已知，场景未知，从多视角图片恢复相机位姿（外参），并重建场景（三维点坐标）
- 一般通过如下步骤
  + Find a few reliable corresponding points
  + Find relative camera position $t$ and orientation $R$
    - 我们可以假定第一张图的相机为相机坐标系的原点，后续计算每一帧相对于上一帧的位姿
  + Find 3D position of scene points

=== Epipolar Geometry 对极几何
- 描述同一个 3D 点，在不同视角的两张图片特征点之间的对应集合关系(2D-2D)（也就是上面步骤中的第二步）
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
- 有了对应的二维特征点，相机参数以及两个相机坐标系的相对位置关系，下一步就是计算出场景点的实际三维坐标（也就是上面步骤中的第三步）
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
- 上一节我们讨论的 SfM 重建的是稀疏的点云，这节我们讨论稠密重建（对每个像素点进行重建），而需要的一个重要概念就是深度的估计

== Depth estimation
- 深度估计即对于给定的图像，估计每一个像素在实际场景中的深度
- 这里的深度有时候指空间点到相机中心或者像平面的距离，也有时候表示沿光线的距离。而深度图就是将深度信息可视化
- Depth sensing 一般有两种方式
  - Active depth sensing
    - LiDAR(e.g. Velodyne) —— 昂贵、相对视觉方案更高的精度和分辨率、360°可见性
    - Structured light (e.g. Kinect 1)
    - Active stereo (e.g. Intel RealSense)
  - Passive depth sensing
    - Stereo，即立体视觉（双目视觉），本节课重点讲
    - Monocular，一般用深度学习方式去估计

=== Stereo matching
- 一个物点将投影到我们图像中的某个点，对应于世界上的一条光线。两只眼睛的光线在同一个点相交（回忆上节课的 Epipolar geometry），这就是双目视觉的原理
- 但与上节课的光流不同，这里立体视觉任务实际上是更简单的
  - 首先，我们常常假设两个相机的内参相同，并且相对位置不变（即从 left view 到 right view 的外参已知）
  - 其次由 epipolar line 的约束，已知 $X_L$，不管它的 3D 点深度如何，它在右图上的投影点 $X_R$ 一定在红线上，这极大简化了我们搜索的区域
  #fig("/public/assets/Courses/CV/2024-11-07-10-26-19.png", width: 50%)
- Simplest Case: Parallel images
  - 像平面平行而且平行与 baseline，相机中心的高度一致，相机焦距一致
  - 这样子我们只需要搜索另一张图中同一高度的水平线即可，更加缩小了搜索的空间，提高效率
  - 并且有一个很简单的视差(disparity)公式
  #grid2(
    fig("/public/assets/Courses/CV/2024-11-07-10-28-41.png", width: 60%),
    fig("/public/assets/Courses/CV/2024-11-07-10-32-36.png", width: 60%),
  )
- Complex Case: Stereo image rectification
  - 那么对于并不平行的像平面，很直观的想法，就是通过几何变换使得它们平行，这被称作*立体影像矫正*
  #grid2(
    fig("/public/assets/Courses/CV/2024-11-07-10-29-16.png", width: 60%),
    fig("/public/assets/Courses/CV/2024-11-07-10-33-43.png", width: 90%)
  )

=== Stereo matching algorithms
- 我们已经将问题简化，不再需要特征点之类的方法。很直观的想法就是对这张图的当前点，在另一张图的对极线上取一个小窗口滑动，寻找最相似的小区域
- 一般有 $3$ 种 Popular matching scores 的计算方法，其中前二者假设亮度一致，第三个通过归一化考虑了亮度变化
  #fig("/public/assets/Courses/CV/2024-11-07-10-42-56.png", width: 60%)
- 另外一个影响因素是窗口的大小
  - 窗口太小可以增加细节，但是会增加噪声；窗口太大虽然噪声小了，但是我们提取不到细节，后续重建的效果就不好
  - 可以看到即使是最佳的 window size，得到的深度图与实际还是有一定差距，因为噪声很多（当然，Better methods exist，e.g. Graph cuts-based）
  #grid2(
    fig("/public/assets/Courses/CV/2024-11-07-10-45-52.png"),
    fig("/public/assets/Courses/CV/2024-11-07-10-46-03.png")
  )
- 我们可以将立体匹配转化为一个优化问题，把像素点周围的视差约束考虑进来，最小化一个能量函数
  $ E(d) = E_d (d) + la E_s (d) $
  - 匹配本身的损失：目的是在另一张图中找到最佳匹配(match cost) #h(1fr)
  $ E_d (d) = sum_((x,y) in I) C(x,y,d(x,y)) ~~~ "e.g. SSD, SAD, ZNCC" $
  - 光滑性的损失：相邻的两个像素，视察应该尽可能接近(smoothness cost) #h(1fr)
    $ E_s (d) = sum_((p,q) in ep) V(d_p, d_q) ~~~ ep ": set of neighboring pixels" $
    - $V$ 的选取一般也有两种方法，后者对边缘处更好（不过度惩罚）
    #fig("/public/assets/Courses/CV/2024-11-07-10-56-42.png", width: 40%)

=== Stereo reconstruction pipeline
- 至此我们可以得到立体重建(双目重建)的基本步骤：
  + Calibrate cameras
  + Rectify images
  + Compute disparity
  + Estimate depth
- 基线(baseline)的选择
  - 如果基线过小，则点的深度误差会比较大
  - 如果基线过大，则一方面重合的区域比较小，另一方面两张图片的内容差别比较大，匹配越难
  - 不过，这个 baseline 取决于两个相机相对外参，有时候也不是说想改就能改，比如人的眼睛（
  #fig("/public/assets/Courses/CV/2024-11-07-11-02-26.png", width: 50%)
- Possible Cause of Error
  + Camera calibration errors
  + Poor image resolution
  + Occlusions
  + Violations of brightness constancy 违反亮度一致性（比如非漫反射物体）
  + Textureless regions 纹理缺失区域
- Active stereo with structured light
  - 立体匹配在纹理缺失区域歧义性太强，压根无法进行深度估计
  - 此时我们可以用*结构光*（一般是用红外光，避免对重建出的颜色产生影响），给无纹理的区域打上光斑，属于主动方式的深度估计 (active stereo)
  - 这个时候我们甚至不需要两个相机了（projector 和 camera 之间的变换对打光是有影响的）
  #fig("/public/assets/Courses/CV/2024-11-07-11-11-08.png", width: 80%)
- Summary
  - Passive stereo，适用性比较广
  - Active stereo，一般来说精度最高
  - Lidar (ToF)，一般比较稳定，对无人机等有一定的应用

=== Multi-view Stereo(MVS)
- 和 SfM 一样，我们现在要将两个视角的深度估计拓展到多个视角
- 它的优势是
  + Can match windows using more than 1 neighbor, giving a *stronger constraint*
  + If you have lots of potential neighbors, can *choose the best subset of neighbors* to match per reference image
  + Can reconstruct a depth map for each reference frame, and the merge into a *complete 3D model*
- *basic idea*
  - 如果按照前述方法，将 $n$ 张图片两两依次匹配并依次计算重投影误差，那么效率极低
  - 因此在这里我们选择的方法是找一个 reference view，假设实际物体点的深度，在 neighbor views 中计算重投影误差（最简单的就是算窗口的 SSD），误差累计得到一个 error-depth 曲线
  #fig("/public/assets/Courses/CV/2024-11-07-11-20-53.png", width: 60%)
  - 对 reference view 的每个像素都做如上操作，我们得到的误差是个三维体素，长宽对应图像，高对应计算深度值个数，称作 *cost volumn*（三维体素的集合）
- *Plane-Sweep*
  - 对每个像素都做上述操作是比较耗时的，有没有办法一次算出 cost volumn 的一个面呢？
  - 先假设参考图像的所有像素深度都是同一个值（对应三维空间中的一个面），将这个面投影到其它的图像中（该投影是个单应性变换），据此计算重投影误差
  #fig("/public/assets/Courses/CV/2024-11-07-11-26-24.png", width: 70%)
  - cost volumn 记下了每个像素每一个深度对应的误差，最后我们提取每个像素表现最好的深度值，得到深度图
- *PatchMatch*
  - 不过 Plane-Sweep 计算 cost volumn 还是开销大了点，有一种更加高效的立体匹配算法（穷举 $-->$ 随机预测）
  #fig("/public/assets/Courses/CV/2024-11-07-11-32-45.png", width: 60%)
  + Initialization: 随机初始化，赋予图像中的每个像素一个随机的深度值，大部分是错的，但总有可能会蒙对部分像素，在上图中我们假设红色是对的
  + Propagation: 其次我们假设相邻的像素是相似的，即在两张图像上的视差相似。对于每一个图像块，将与其相邻的图像块计算误差，如果误差变小，则更新
  + Search: 虽然相邻的像素相似但是不完全一致，所以我们要在小范围内进行微调
  - 反复执行步骤 2, 3 直到收敛，可以把 PatchMatch 类比为图像匹配中的梯度下降

== 3D reconstruction
- 现在我们的目标是从深度图得到实际物体的三角网格
#note(caption: "3D reconsturction Pipeline")[
  + Compute depth map per image
  + Fuse the depth maps into a 3D surface
  + Texture mapping
]

=== 3D representations
- 这里可以参考我 #link("http://crd2333.github.io/note/AI/3DV/Representations")[另外的笔记]

=== 3D surface reconsturction
- 现在我们想要知道如何从深度图得到三角网格，基本的步骤如下：
  - 深度图 $-->$ 体素表示的 occupancy: Poisson reconsturction
  - Occupancy volume $-->$ mesh: Marching cubes

==== Poisson Reconstruction
- 泊松重建是从深度图到三维体素的一个过程
  + 首先将深度图转化为点云
    - 这时候我们得到了一堆点，其实这些点已经近似构成了一个三维表面，只是比较 noisy
  + 第二步，我们要计算这堆分布在表面附近的三维点各个局部的法向（可以利用 PCA，对应小特征值的特征向量即为局部表面法向）
  + 第三步，我们根据得到的法向构建 $0-1$ 的体素，即用体素拟合点云，使得 $0-1$ 交界的地方就是点云所在之处。我们可以定义一个优化问题：优化变量就是每个体素的值，为 $0$ 或 $1$
    - Represent surface by indicator (occupancy) function
    $
    cX_M (p) = cases(1 ~~~ "if" p in M, 0 ~~~ "otherwise")
    $
    - 对于目标函数，我们可以这样思考：对于体素的边界，物体内部值为 $1$，外部值为 $0$，则该处的梯度就沿着表面的法向。而我们又已知法向，因此可以优化梯度与法向之间的 Loss
#fig("/public/assets/Courses/CV/2024-11-07-12-21-08.png", width:70%)

#note(caption: "Poisson Reconstruction")[
  + Represent the oriented points by a vector field $V$
  + Find the function $X$（体素场） whose gradient best approximates $V$（梯度向量场） by minimizing: $norm(na_X-V)^2$
  + Solved by Poisson equation
]

==== Marching Cubes
- 现在我们需要从体素表示中提取表面三维网格
- 这个做法其实很直观，就是寻找体素中有 $0$ 和 $1$ 转化的地方，提取中点，生成三角面片。下图很直观地展示二维和三维的情况
#fig("/public/assets/Courses/CV/2024-11-07-12-13-38.png", width: 60%)
#fig("/public/assets/Courses/CV/2024-11-07-12-09-18.png", width: 60%)
- [ ] 这里比较粗略，复习的时候可能会补充一下（

#v(1em)

- 最后，得到 mesh 后做 texture mapping 即可

== Neural Scene Representations
- 最后讲了一些 Implicit Neural Representations，我就不记了
