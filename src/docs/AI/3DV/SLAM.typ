#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "SLAM",
  lang: "zh",
)

= SLAM 中的 CV
== SfM
- 参考 #link("https://blog.csdn.net/shyjhyp11/article/details/104108926")
=== 增量式的 SfM(Incremental Structure-from-Motion)
- 步骤
  - 先从一对图像开始，计算*对极几何约束*(epipolar geometry)，*本质矩阵*(Essential Matrix)；
  - 然后，可以从 Essential Matrix 中 decompose 两个相机的 pose（旋转矩阵 R 及位移 t），然后就可以使用 triangulation，三角化算出一些三维点（误差累计的来源）；
  - 所以可以通过两张图，计算出包含两个相机和一些三维点的初始三维重建，接着再使用 Resection 方法，加第三个相机（第三张图片），即使用三维点（已计算点）和两维点（新加点）的 对应关系（correspondence），计算出第三个相机的姿态。逐步增加相机，逐步找到三维点，及对应的图像点。
- 问题：误差会不断累计。
  - 比如加第三张图像时，用的是 3D-2D 对应点的对应关系，来做 Resection 或者做 PnP。我们之前讲到，在做 Resection 时，假设 3D 点坐标是绝对精确的、没有误差的，误差全部来自于 2D 点坐标（特征点检测出来的像素坐标值），但增量式 SfM 在添加相机时，使用的三维点坐标，是前面计算出来的。所以三维点的误差，会导致我们新加进来的第三张图的相机的pose（R 和 t）的误差，进一步会导致我第四张图有些误差。
  - 这样，使用第三张和第四张图对应相机三角化出来的三维点，也会有误差，逐步被放大
- 怎么办呢？目前没有什么办法，非线性优化呗，即 minimize 重投影误差(reprojection error)，所以，通常在做了几次添加相机（图像）后，就需要做一把 Bundle Adjustment。这时候就相对安全了，这时候就可以继续添加相机了。这时就会有一个判断准则，比如添加了20张图像（或者判断 triangulate 出来的相机姿态需要优化了），就需要做 Bundle Adjustment 了。
  - 就这样一直添加图像，直到所有的图像全部添加完以后，还要再最后做一次整体的 Bundle Adjustment。因为 BA 是在优化所有的相机，所有的三维点。整套这样的流程就叫做 Incremental Structure-from-Motion。

=== 全局式的SfM(Global Structure-from-Motion)
- 步骤
  - 先给定一对图像对(pair)，同样要计算 Essential Matrix，然后同样的 decompose 出来相机的相对运动（Relative Motion，包含：相对旋转矩阵 R 和相对平移矩阵 t）；使用同样的方法，算出所有的图像对的 E 和 Motion，比如有 n 张图，就有 $C_n^2$ 个图像对。
  - 然后根据这些所有的图像对，算出的 Relative Motion，解一个优化问题（称之为：Register all cameras），把所有相机的朝向(Rotation)和中心点坐标(center)一次性的求出来。
  - 最后当然离不开 Bundle Adjustment，因为这才是最后要解的 reprojection error 的 minimize。前面初始化的效果越好，后面 Bundle Adjustment 的效果就越好。一般情况下，使用 Global Structure-from-Motion，最后收敛的也就越快。
- 通过 Essential Matrices 和 Decomposition，算出来相对的旋转 R 、相对的平移 t，怎样把他们放到世界坐标系中，如何把他们 register 到一起，这个就是这一步要解决的问题。这步一般可以分成两步 Rotation Averaging 和 Translation Averaging
  - Rotation Averaging（求解所有相机朝向）
  - Translation Averaging（求解所有相机中心点）

== IMU 融合视觉里程计
- 参考 #link("https://blog.csdn.net/weixin_43569276/article/details/104783347")[SLAM基础 —— 视觉与IMU融合（VIO基础理论）]
- #link("https://blog.csdn.net/qq_35453190/article/details/114452939")[基于优化的IMU与视觉信息融合]



= SLAM 视觉 14 讲
== Chapter 1: 初识 SLAM



== Chapter 2: 三维空间刚体运动



== Chapter 3: 李群与李代数



== Chapter 4: 相机与图像



== Chapter 5: 非线性优化



== Chapter 6: 视觉里程计
- 详细可参考 #link("https://blog.csdn.net/lixujie666/article/details/82262513")[视觉SLAM中的对极约束、三角测量、PnP、ICP问题]
- 对极几何(2D-2D)
  - 输入：相机内参和配对点
  - 输出：通过计算基础矩阵 F 和本质矩阵 E，恢复并输出相机的位姿(R, t)
  - 局限性：尺度不确定性、不适用纯旋转问题

- 有了相机的位姿，接下来就是恢复3D点，即通过两帧图像中对应的匹配点的像素坐标$x_1,x_1'$和相机的位姿$R,t$，计算得到其对应的在三维世界中的坐标$X$；

- 三角测量(2D-2D)
  - 输入：相机参数，包括内参（例如焦距、光心位置等）和外参（旋转和平移）；特征点匹配，在两个或者多个视图中，匹配的二维图像点
  - 输出：三维点的坐标，在相机坐标系下或某个预定的世界坐标系下的三维点的位置
  - 这里要和 PnP 做一下区分，PnP 也是两帧图像，但是其中一帧的 3D 点$X_1, X_2, X_3$已知，则通过这些 3D 点以及对应的另一帧的 2D 坐标($x_1,x_2,x_3$)，来估计两帧的运动$R, t$
  - 当然，也需要和对极几何做一个区分，对极几何是仅仅通过两张图像的匹配点像素坐标$(x_1,x_1'), dots, (x_8,x_8')$，就可以计算出两帧图像的相对运动$R, t$
  - 然后讲一个第十三章提到的思路上的东西：对一个三维点，可以用世界坐标或相机坐标下的$(x,y,z)$来描述，三个量存在明显的相关性（反映在协方差矩阵中表现为非对角元素不为零）；但我们也可以用某一帧下$(u,v,d)$来表示，图像内 2D 坐标 $u,v$ 与深度 $d$ 有近似独立的性质，甚至我们亦能认为 $u, v$ 也是独立的 —— 从而它的协方差矩阵近似为对角阵，更为简洁

#note()[
  - 因此在 ORBSLAM 中这三种方法的顺序是：
    1. 由两张图像的匹配点，利用*对极几何*计算出 $H$ 或者 $F$ 矩阵，并从这两个矩阵中恢复出 $R, t$
    2. 有了 $R, t$ 就可以利用相机的位姿和两帧对应的像素坐标用*三角测量*计算出其对应的 3D 点坐标。至此，相机的位姿和对应的地图点就都有了，接下来正常跟踪即可；
    3. 跟踪丢失后，就需要回到原来机器人曾经经过的位置找匹配帧，找到的匹配帧是有其3D地图点和位姿的，用这些3D点和当前帧自己的像素坐标， *PnP计算*出当前帧相较于匹配帧的运动 $R, t$
]

- PnP(3D-2D)
  - 输入: 1. 三维点坐标：在世界或某一特定坐标系中的一组三维点坐标。 2. 二维点坐标：这些三维点在图像上的投影点坐标。 3. 相机内参：焦距，本征矩阵等。
  - 输出: 1. 相机姿态：解决 PnP 问题的主要输出是相机的旋转矩阵和平移向量，这两者共同描述了相机的姿态。
  - 线性解法和 Bundle Adjustment 解法

- ICP(3D-3D)
  - 输入： 1. 源点云：我们想要移动或旋转的点云。 2. 目标点云：我们希望源点云能和这个点云对齐的点云。
  - 输出： 1. 旋转矩阵和平移向量：这两者描述了如何将源点云最优地对齐到目标点云。
  - 线性解法和 Bundle Adjustment 解法

- 配对点
  - 特征点法
  - 光流法
    - 光流，看看这篇文章：#link("https://www.cnblogs.com/jiading/articles/13403997.html")[计算机视觉 -- 光流法 (optical flow) 简介]
  - 直接法

== Chapter 7: 后端优化
- 以上对极几何、三角测量、PnP、ICP 等，只是作为初始化的手段，在上述所有信息已知后，通常都会通过一种全局优化方法进一步优化重建结果和相机位置，使得重投影误差最小
- Bundle Adjustment
  - 输入主要有两部分： 1. 观测值：这些是从图像中获取的特征点匹配，通常表示为一系列的二维点（在图像平面上的坐标）； 2. 初始估计：这是使用其他方法（如直接线性变换，DLT）得到的三维点和相机参数的初始估计（包括相机位姿，即外参，和焦距，径向畸变参数等内参）
  - Bundle Adjustment的输出： 1. 优化的三维点坐标：经过优化后的三维场景点的坐标值； 2. 优化的相机参数：包括优化后的相机位置、姿态以及其他内参（如焦距、畸变系数等）。
- 公式推导上，某一个点云在某一帧图像上的实际观测位置和重投影位置之间的误差（一般是均方误差），用两个 $sum$ 求和，就得到了目标函数。
  - 将相机位姿$bx_c$和空间点$bx_p$变量都放在一起，形成$bx=[bx_c, bx_p]$，然后雅可比矩阵也形成这样的格式 $bJ = [bF, bE]$。
  - 接下来无论是 G-N 或 L-M 法，都需要求解一个增量线性方程 $bH Delta bx = bg$，其中 $H = J^T J$ 或 $J^T J + la bold(I)$，其中 $H$ 矩阵为镐形矩阵，可以通过 Schur 消元进行分布计算，从而简化计算。
  $ mat(bB,bE;bE^T,C) mat(Delta bx_c; Delta bx_p)=mat(v;w) -> mat(bB-bE bC^(-1)bE^T,0;bE^T,bC)mat(De bx_c; De bx_p)=mat(v-bE bC^(-1)w; w) $

== Chapter 8: 回环检测



== Chapter 9: 建图
- SLAM 称为同时定位与建图，事实上前面已经涉及很多建图内容，这里单列一章进行更详细的阐述，因为根据人们对建图的需求不同，建图模块也有很大不同。
- 稠密地图与稀疏地图
  - 稠密地图的重点在于需要知道每一个像素点（或大部分像素点）的距离，大致有三种方案：单目相机移动并进行三角测量；利用双目或多目相机的视差；使用 RGB-D 相机直接获得像素距离。书里详细阐述了单目稠密重建
  - 由于不能把每个像素都当作特征点计算描述子来进行匹配，单目稠密重建中使用*极线搜索*和*块匹配技术*来进行匹配，然后用*深度滤波器技术*（将深度建模为极线上块的概率分布）使深度估计收敛
    - 如果用高斯分布建模：frame $i$ 里某块对应三维点重投影到 frame $j$，对这个块进行微小扰动得到的深度估计误差作为不确定度 $sigma$
    - 几个问题和改进
      + 环境纹理的限制、像素梯度与极线的角度
      + 逆深度：假设逆深度服从高斯分布，用卡尔曼滤波器进行逆深度估计
      + 考虑图像间的旋转，在块匹配之前做预处理
      + 并行化
  - 然后提一嘴 RGB-D 相机

#quote(caption: "网上看到的一段话，不是很理解什么意思")[
  #tab BA和图优化，是把位姿和空间点放在一块，进行优化。特征点非常多，机器人轨迹越走越长，特征点增长的也很快。因此位姿图优化的意义在于：在优化几次以后把特征点固定住不再优化，只当做位姿估计的约束，之后主要优化位姿。

  也就是说，不要红色的路标点了，只要位姿。位姿里的三角形是位姿，蓝色的线是两个位姿之间的变换。

  【关于这点，有一个理解非常重要：三角形的位姿，是通过和世界坐标系的比较而得到的，其实世界坐标系在大部分情况下也就是一开机的时候的相机坐标系，把第一帧检测到的特征点的相机坐标，当成是世界坐标，以此为参照，逐步直接递推下去。而上图蓝色的线，是根据中途的两张图，单独拿它俩出来估计一个相对的位姿变换。

  换言之：在前端的匹配中，基本都是世界坐标系的点有了，然后根据图像坐标系下的点，估计世界坐标系与图像坐标系下的变换关系作为位姿，（这里的世界坐标系下的坐标实际是根据第一帧一路递推下来的，可能错误会一路累积）我们假设算出来两个，分别是T1和T2。而蓝色的线，作为两个位姿之间的相对变换，也就是T1和T2之间的变换。但它并不是直接根据T1的逆乘以T2这种数学方式算出来的（不然还优化什么？肯定相等啊）而是通过T1和T2所在的图像进行匹配，比如单独算一个2D-2D之间的位姿变换或者光流法等，这样根据图像算出的位姿很有可能是和T1与T2用数学方式计算得到的位姿是有差异的（因为没有涉及到第一帧图像，就是单纯这两张图像的像素坐标）。这个理论一定要明白，不然纯粹是瞎学】BA和图优化，是把位姿和空间点放在一块，进行优化。特征点非常多，机器人轨迹越走越长，特征点增长的也很快。因此位姿图优化的意义在于：在优化几次以后把特征点固定住不再优化，只当做位姿估计的约束，之后主要优化位姿。
]

== Chapter 10: 传感器融合

== References
- #link("https://blog.csdn.net/qq_25458977?type=blog")[CSDN 博客]
- #link("https://github.com/Michael-Jetson/SLAM_Notes")[github 上找到的笔记]