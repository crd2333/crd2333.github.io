---
order: 3
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "计算机视觉导论",
  lang: "zh",
)

#info()[
  - 部分参考 #link("https://lhxcs.github.io/note/AI/cv/icv/")[lhxcs 的计算机视觉笔记]
]

#counter(heading).update(8)

= Deep Learning
- 都比较基础，就不记了

= Recognition
== Semantic segmentation
- 语义分割就是识别图像中存在的内容以及位置，即对每个像素进行分类

=== Networks
- Sliding window
  - Very inefficient
  - Limited receptive fields
- FCN(Fully Convolutional Networks)
  - 传统的 FCN 是使用不缩减大小的卷积核，得到原图大小的输出
  - Pooling and Unpooling: 如果不加入池化层，则效率太低，但是由于普通的池化会缩小图片的尺寸，为了得到和原图等大的语义分割图，我们需要向上采样/反卷积
- U-Net
  - 在 Pooling,Unpooling 的过程中难免丢失信息，为此加入 skip connection，这就是 U-Net
  - 有点像 Res-Net 那个思路
- CRF(Conditional random field)
  - U-Net 输出之后，我们会再加一步条件随机场优化能量函数
  $ E(x)= sumi th_i (x_i) + sum_(i,j) th_(i,j) (x_i,x_j) $
  #fig("/public/assets/courses/cv/2024-11-21-10-20-09.png",width:60%)

=== Evaluation metric
- 评估语义分割结果，我们使用 per-pixel 的 Intersection-over-union(IoU)

== Object detection
- 输入一张 RGB 图像，输出一个标识物体的 bounding box 集合
- 最大的困难就是我们不知道图像中有几个物体，要输出几个 bounding box

- 最朴素的想法依然是 Sliding Window
  - 同样的问题，$800 times 600$ image 有大约 58M boxes，根本不可能一一计算
  - 提出 Region Proposal，找到一个大概率包含所有物体的 small set of boxes
    - Often based on heuristics
    - Relatively fast to run

=== Two-Stage Model
- First stage: run once per image
  - Backbone network
  - RPN
- Second stage:run once per image
  - Crop features: Rol pool/align
  - Predict object class
  - Predict bbox offset

==== R-CNN 系列
- 步骤：
  + 首先用启发式方法找出 region proposals(e.g. over-segmentation)
  + 然后每个 resize 到固定大小
  + 送入 CNN 进行分类，输出它们的 class 和 bounding box
- 评价指标依然是 IoU
- Non-Max Suppression
  - 有时候同一个物体，网络会输出两个 Bounding box，这时候我们需要选取概率最大的
- 依然有个问题，就是速度太慢（虽然能算了），主要是因为 region proposal 太多了而后面又剔除了很多（太多重复计算）
- Fast R-CNN
  - 用 backbone CNN 一次性处理整张图，得到 feature map，然后再用 region proposal，对每个 region proposal 只用过后续的小 CNN
  - 但是效率还是不够高，因为 region proposal 仍然很多
- Faster R-CNN
  - 用 Fast R-CNN 的方式处理，但用一个小网络 RPN(Region Proposal Network) 来生成 region proposal
  - RPN: 输入 $K$ 个 anchor boxes，输出 $K$ 个 scores (Anchor is an object?) 和 $4K$ 个 bounding box (How to adjust the anchor to fit the object?)

=== Single-stage Model
- YOLO(You Only Look Once)
- Two-stage v.s. single-stage
  - Two-stage is generally more accurate
  - Single-stage is faster
  - 但总得来说一般还是会选 YOLO

== Instance segmentation
- 执行对象检测，然后预测每个对象的分割掩码
- Faster R-CNN + Mask Prediction. 对于目标检测的每个框中的物体，判断每个像素是属于前景还是背景
- Mask R-CNN
- Deep Snake
- Panoptic segmentation 全景分割
  - 语义分割和实例分割的结合
  - Label all pixels in the image (both things and stuff)
  - For “thing” categories also separate into instances

== Human pose estimation
- with depth sensors
  - Microsfot Kinect
- Single Human
  - 直接预测关节点
  - 用热力图(heatmap)表示关节点
- Multiple humans
  - Top-down:
    - 先检测人(bounding box)，然后对每个人进行关键点检测
    - e.g. Mask R-CNN
    - 速度上不太好，其次两个人如果靠得很近，可能会检测成一个人
  - Bottom-up:
    - 先把所有关键点检测出来，然后再组合成人
    - e.g. OpenPose
- Top-down v.s. bottom-up?
  - Top-down is generally more accurate（没有太多重叠的情况下）
  - Bottom-up is faster

== Other tasks
- Video classification
  - Swimming, Running, Jumping, Eating, Standing ...
  - 在图像上加一个时间维度，使用 3D CNN（但速度很慢）
- Temporal action localization
  - 类似图像物体分类 $->$ 物体检测，视频从分类任务更进一步到定位任务
  - 一般是把视频分成很多小段，然后对每一段进行分类
- Spatial-temporal detection
  - 再难一点，要识别出视频中哪些时间、哪些空间在干什么
- Multi-object tracking
  - 从一系列帧中追踪物体
  - 一般是先检测，然后再追踪
- 如何找 SOTA？#link("https://paperswithcode.com/sota")[Papers with code]

= 3D Deep Learning
== 3D reconstruction
=== Feature matching
- Recap: SfM, colmap
- directly predict pose from image
  - 为了预测 Camera Pose，一开始比较粗暴的想法是直接预测，但是精度不高且泛化性一直起不来
    - 就在今年(2024)，随着数据增多，慢慢也开始有一些这样的工作，不过精度相对还是不够
- 因此主流的方法还是遵循之前的 Reconstruction Pipeline，一个个用 Deep Learning 替换，这里我们介绍 Feature Matching 的替代方案
- Recap: feature matching pipeline
- Why deep learning
  - handcrafted features: Geometry only, no semantics, cannot handle poor texture
  - 并且 Not robust to: viewpoint change, illumination change, motion blur
- SuperPoint #h(1fr)
  #fig("/public/assets/courses/cv/2024-11-21-11-44-42.png",width:70%)
- CNN-based detectors
  - 怎么训练？监督哪来？一般是用合成数据，生成 heatmap #h(1fr)
    #fig("/public/assets/courses/cv/2024-11-21-11-51-06.png",width:50%)
  - 数据增强，确保对仿射变换鲁棒性
    $ min_f 1/n sumin norm(f(g(I)) - g(f(I)))^2 $
- CNN-based descriptors
  - loss 一般是用度量学习(metric learning)，用 Contrastive loss
  - 这个训练数据就更难找了，一般是用三维重建的数据，一个 3D 点在两张图像上的描述符应该是相似的
    - 这里有个问题，就是三维重建的结果应该是准确的，但既然都准确了我们为什么还要训练网络呢？
    - 实际上是说，比如用 MVS 方法，我们可以把输入图像做得非常密，难度非常低，这样就算 MVS 很垃圾也能准确重建。然后用稀疏数据训练网络，这样网络就能泛化到困难的情况

=== Object Pose Estimation
- 估计物体相对 camera frame 的 3D location and orientation
- application: robot grasping, autonomous driving, augmented reality
- Feature-matching-based methods
  + First, reconstruct object SfM model by input multi-view images
  + Then obtain 2D-3D correspondeces by lifting 2D-2D matches to 3D
  + Finally, object pose of query image can be solved by PnP
- Direct Pose Regression Methods
- Keypoint detection methods
  - Using a CNN to detect pre-defined keypoints
  - Need to render a large amount of images for training

=== Human Pose Estimation
- 之前说的是 2D Human Pose Estimation，从 2D 图片定位 human joints(keypoints - elbows, wrists, etc)
- 现在是从 image 预测出 3D $(x,y,z)$ coordinate for each joint
- Marker-based MoCap system
  - 其实就是 MVS，但是需要特殊设备来得到标记物
- Markerless MoCap
  - 难度更高，但也能做（也是用多视角）
- Monocular 3D Human Pose Estimation
  - 单独估计每个关节的 3D 位置
  - 或者用参数化模型 SMPL

=== Dense Reconstruction
==== Multi-view Reconstruction
- Recap: 传统 pipeline
  + 对每个图像估计深度 (multi-view stereo)
  + Fuse the depth maps into a 3D surface (e.g. Poisson reconstruction)
  + Texture mapping
- Recap: multi-view stereo
  - 计算每一点相对于参考图像的深度值的误差
- 用深度学习改进 MVS
  - MVSNet: predict cost volume from CNN features
- 换一种思路，从 Learning-Based 直接转成 Optimization-based
  - 通过比较渲染出的图像跟 input 图像，来改进 mesh 的质量
  - 难点在于：
    + 基于 mesh 的 render process 并不可微（现在有一些近似 mesh differentiable renderer 方法，但可能比较慢）；
    +  mesh 不是一个适合优化的 representation
  - 但近年来 representation 方面的工作（比如 Implicit Neural Representations 或者 Explicit 的 voxel, 3DGS）使得基于优化的方法变得可行
- 这里介绍了一些 Implicit 的 representation，如参数曲面、SDF、NeRF、NeuS
  - NeRF 基于 volume rendering 使得渲染变得可微
  - 但 NeRF 重建的表面往往比较粗糙，为此改进为 NeuS（网络输出 color 和 SDF 而不是原始 NeRF 的 color 和 density，但体渲染时把 SDF 转为 density）

==== Single-view(Monocular) Reconstruction
- 从单张图像推断 3D representation (e.g. Depth, Mesh, Point Cloud, Volume)
- Monoculer depth estimation
  - 使用网络去 guess 每个像素的深度
  - Scale ambiguity: 单视图天然具有尺度不确定性，进而导致深度歧义性
  - Loss function: *scale-invariant* depth error
    - Standard L2 error
      $ D_"L2" (y,y^*) = 1/n sumin (log y_i - log y_i^*)^2 $
    - Scale-invariant error: 每一张图像都有一个对应的 $al$ 调整深度
      $
      D_"SI" (y,y^*) = 1/n sumin (log y_i - log y_i^* + al (y,y^*))^2 \
      al (y,y^*) = 1/n sumjn (log y_i - log y_i^* + al)^2
      $
  - 训练数据怎么得到：一般要么是合成的数据（假但是数据准）、要么是真实数据但是用 MVS 估计出深度（真但是数据不一定准）
- Monoculer shape estimation
  - 从单张图片输出 mesh, point cloud, volume 等，近年来更多是输出 NeRF 或 3DGS
  - 训练数据也是一般用的 MVS 数据
    - 从单张图片输出 3D representation 后，再渲染成 2D image，跟 MVS 数据做 loss
    - 可以想象这也需要 differentiable renderer，所以 NeRF 和 3DGS 所用的可微渲染方法就很有用

== Deep learning for 3D understanding
=== 3D Classification
- 输入 3D shape（如 Multi-view images, Volume, Point Cloud, Mesh, RGBD or Depth images, Implicit Shape），输出 Class
- Deep learning on *Multi-view images*
  - 给定 input 3D shape，生成多个 2D views（或者如果输入本身是 multi-view images 就省了这步）
  - *Multi-view CNNs*
    + 每个图像用 2D CNNs 抽特征
    + 经过 view-pooling 合并，再过一个 2D CNN 得到 final predictions
- Deep learning on *volumetric data*
  - volumetric data: Voxel + occupancy
  - *3D ConvNets*: 使用 3D 卷积核处理体素数据 #h(1fr)
    #fig("/public/assets/courses/cv/2024-11-28-11-29-47.png",width:50%)
    - Challenge: High space/time complexity of high resolution voxels: $O(N^3)$
  - *Sparse ConvNets*: 使用 3D shapes 的稀疏性
    - Store the sparse surface signals (Octree)
    - Constrain the computation near the surface
    - 稀疏卷积: compute inner product only at the active sites (nonzero entries)
- Deep learning on *point clouds*
  - Point cloud
    - The most common 3D sensor data
    - 表示为 matrix of $N times D$ (2D array representation)，$D$ 一般为 $3$
  - Challenge:
    + Point cloud 是未栅格化数据，因此无法应用卷积操作
    + point 的集合是 order-less 的，我们需要输出跟 $N!$ permutations 无关
    + 输出应该跟 rigid transformation of points 无关
  - *PointNet*: A point cloud processing architecture for multiple tasks(classification, detection, segmentation, registration, etc)
    - 以 Classification and Segmentation Architecture 为例
      #fig("/public/assets/courses/cv/2024-11-28-11-38-10.png")
    - Challenge 1: 不能用卷积，那就用 MLP（隐患：No *local context* for each point）
    - Challenge 2: 对 MLP 输出的特征，使用 max pooling 消除 order 信息
    #grid2(
      fig("/public/assets/courses/cv/2024-11-28-11-42-19.png",width:60%),
      fig("/public/assets/courses/cv/2024-11-28-11-44-00.png",width:60%)
    )
    - Challenge 3: 使用另一个网络 T-Net 来估计 transformation
  - *PointNet++*: Hierarchical structure for point cloud processing
    - 解决 MLP 无法捕捉 local context 的问题 (*global* feature learning —— *Either one* point or *all* points)
    - 类似卷积的局部性，引入 local pooling，分为 $3$ 部分 #h(1fr)
      + Sampling: Sample anchor points by Farthest Point Sampling (FPS)
      + Grouping: Find neighbourhood of anchor points
      + Apply PointNet in each neighborhood to mimic convolution
      #fig("/public/assets/courses/cv/2024-11-28-11-50-31.png",width:50%)
- Deep learning on *meshes*
  - 基本上是渲染成图片，用 Multi-view 的方式处理
- Deep learning on *RGBD images or Depth images*
  - 难度上相对简单一些，因为有深度信息，可以转化为点云表达，进而用点云方法处理
  - 难点在于要知道相机的参数（如果没有提供的话）：基于 RGBD 或 Depth 运行 SfM、点云对齐方法(ICP)
  - 最大的优势在于实时性，毕竟数据足够强

=== 3D Semantic Segmentation
- Input: sensor data of a 3D scene (RGB/depth/point cloud...)
- Output: Label each point in point cloud with category label
- Possible solutions
  - directly segmenting the point cloud (like PointNet++)
  - fuse 2D segmentation results in 3D（因为 2D 已经做得很好，直接对 3D 做不一定有对 2D 做再融合效果来得好）

=== 3D Object Detection
- Bounding Box
  - 回忆 2D Object Detection 中: $(x,y,w,h)$
  - 3D bouding box: $(x,y,z,w,h,l,r,p,y)$ #h(1fr)
    - $x,y,z$ 就是中心，然后还多了欧拉角 roll, pitch, yaw 的描述
  #fig("/public/assets/courses/cv/2024-11-28-11-57-04.png",width:40%)
  - Simplified bbox: no roll & pitch
  - 可以看到比 2D 难得多
- The first attempt: classify sliding windows
  - 2D 的 sliding windows 方法直接迁移到 3D
  - 缺点：3D CNNs are very costly in both memory and time（候选框太多了）
- PointRCNN: RCNN for point cloud
  - 但是 3D 目标检测比 2D 好的一个点在于，它几乎不会重叠（可能会挨着，但是分离的）
  - 基本思想是，把前景和背景分开，前景的 points 用聚类的方式生成好多 proposal，然后再用 PointNet++ 之类做细粒度的预测
  #fig("/public/assets/courses/cv/2024-11-28-12-00-30.png",width:80%)
- Frustum PointNets: Using 2D detectors to generate 3D proposals
  - 很多时候数据不止点云，还连带着 2D 图像（比如无人驾驶，除了重建出的点云之外，相机拍摄的原始 RGB 图像就可以拿来利用）
  - 然后利用 2D 的 proposal 生成方式，在 3D 里就对应一个视锥，这样也生成了一种 proposal 来减少候选框
  #fig("/public/assets/courses/cv/2024-11-28-12-00-00.png",width:50%)

=== 3D Instance Segmentation
- Input: 3D point cloud
- Output: instance labels of 3D points
- Top-down approach
  + Run 3D Object detection
  + Run segmentation in each 3D bbox
- Bottom-up approach: 应用聚类方法
  - Group (cluster) points into different objects

=== Datasets
- Datasets for 3D Objects
  - 计算机辅助设计(CAD)按理来说应该提供大量 3D 数据，但高质量的往往不会公开
  - Large-scale Synthetic Objects: ShapeNet
    - 想要对标 2D 的 ImageNet，但是
      + 首先质量很低，物体也比较简单
      + 其次缺少 texture，没有 BRDF 的描述
  - Fine-grained Part: PartNet (ShapeNetPart2019)
- Datasets for Indoor 3D Scenes
  - 家装公司应该会有很多，但也不怎么公开
  - Large-scale Synthetic Scenes: SceneNet
    - 3D meshes 5M Photorealistic Images
- Datasets for Outdoor 3D Scenes
  - KITTI: LiDAR data, labeled by 3D bboxes
  - Semantic KITTI: LiDAR data, labeled per point
  - Waymo Open Dataset: LiDAR data, labeled by 3D b.boxes


