#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "colmap 的使用",
  lang: "zh",
)

= Colmap
#note(caption: "几个写的比较好的连接")[
  + #link("https://blog.csdn.net/m0_74310646/article/details/137889450")[colmap tutorial 的阅读笔记]
  + #link("https://www.cnblogs.com/li-minghao/p/11865794.html")[COLMAP已知相机内外参数重建稀疏/稠密模型]
]

== Introduction
- COLMAP 是一种通用的运动恢复结构(SfM)和多视图立体(MVS) pipeline，具有图形和命令行界面
  - 首先 SfM 重建稀疏 3D 特征点，主要用于定位
  - 随后 MVS 估计深度和稠密重建。稠密重建又称三维重建，是对整个图像或图像中绝大部分像素进行重建
- 首先需要知道 colmap 这种传统方法重建的 pipeline
  - 数据采集 $-->$ 稀疏重建 $-->$ 深度图估计 $-->$ 稠密重建
  - 稀疏重建包含：
    #diagram(
      node((-1,0),[*Detect* 2D features\ in images]),
      edge((-1,0),(0,0)),
      node((0,0),[*Match* 2D features\ between images]),
      edge((0,0),(1,0)),
      node((1,0),[Generate 2D *tracks* from \ matches #sym.slash.big Estimate \ camera *poses*]),
      edge((1,0),(1,1)),
      node((1,1),[*Triangulate* 3D points from 2D tracks]),
      edge((1,1),(-0.5,1)),
      node((-0.5,1),[SfM model refinement using *Bundle Adjustment*]),
    )
    - 联系 CV 导论课的知识
      + Detect 2D features: 用 SIFT 等方法检测(detect)并描述(descript)图像中的特征点
      + Match 2D features: 用描述子匹配特征点对，涉及 ratio test, mutual nearest neighbour 等，或者使用深度学习方法
      + Estimate camera poses: 用对极几何 Epipolar Geometry 从 2D 特征点配对中估计相机外参（轨迹）
        - 对极几何假设内参已知，这个内参怎么来的呢？一般是先根据相机模型初始化一个值（或者你自己导入一个值），然后后续进行优化(Bundle Adjustment)#strike[，虽然我做实验的时候好像没优化不知道为什么]
      + Triangulate 3D points 三角测量：，从 2D 特征点对和相机外参估计 3D 特征点坐标
      + Bundle Adjustment: 通过重投影误差最小化来优化相机外参和特征点坐标
  - 深度图估计包含：去畸变、立体匹配
    - 联系 CV 导论课的知识
      + Undistortion: 重新校正图片，上课没讲
      + Stereo Matching: 图像矫正、视差计算、深度估计
    - 深度估计一般有两种，基于 photometric 和 geometric 的方法
      + Photometric 光度，即像素的颜色和亮度。在 COLMAP 中，photometric depth map 是通过光度一致性方法生成的。我们 CV 课上讲深度估计部分采用的方法就是如此，讲了 3 种 Popular matching scores 计算方法 —— SSD, SAD, ZNCC
      + Geometric 几何，主要涉及图像中的几何信息即物体的形状、边缘和结构。在 COLMAP 中，geometric depth map 是通过几何一致性方法生成的，我们 CV 课上讲深度估计部分似乎没有说这种方法，但是在讲比如 SfM 时有大量对特征点方法的运用
  - 稠密重建包含：立体融合、网格化
    - 联系 CV 导论课的知识
      + Stereo Fusion: 将多个视图的深度图融合在一起，去除噪声和错误匹配，生成稠密的三维点云
      + Surface Reconstruction: 如用 Poisson Reconstruction 把深度图转化到点云再转化到 voxel 表示的 occupancy 中
      + Meshing: 网格化，如 marching cubes
- Project 文件夹必须包含 "images" 文件夹，其中包含所有图像，像这样：
  #tree-list(root: [./])[
    - images
      - image1.jpg
      - image2.jpg
      - ...
      -  imageN.jpg
  ]

== Usage
- 然后像下面这样进行命令行使用：
  ```bash
  # 设置数据集路径
  $ DATASET_PATH=/path/to/dataset

  # 提取特征
  $ colmap feature_extractor \
    --database_path $DATASET_PATH/database.db \
    --image_path $DATASET_PATH/images \
    # --ImageReader.single_camera 1

  # 匹配特征
  $ colmap exhaustive_matcher \
    --database_path $DATASET_PATH/database.db \
    # --SiftMatching.guided_matching 1

   # 创建稀疏重建文件夹
  $ mkdir $DATASET_PATH/sparse

  # 重建稀疏模型
  $ colmap mapper \
      --database_path $DATASET_PATH/database.db \
      --image_path $DATASET_PATH/images \
      --output_path $DATASET_PATH/sparse \
      # --Mapper.min_num_matches 5

  # 创建稠密重建文件夹
  $ mkdir $DATASET_PATH/dense

  # 去畸变
  $ colmap image_undistorter \
      --image_path $DATASET_PATH/images \
      --input_path $DATASET_PATH/sparse/0 \
      --output_path $DATASET_PATH/dense/0 \
      --output_type COLMAP \
      --max_image_size 2000

  # 立体匹配，这一步需要 GPU
  $ colmap patch_match_stereo \
      --workspace_path $DATASET_PATH/dense/0 \
      --workspace_format COLMAP \
      --PatchMatchStereo.geom_consistency true

  # 立体融合，得到稠密点云
  $ colmap stereo_fusion \
      --workspace_path $DATASET_PATH/dense/0 \
      --workspace_format COLMAP \
      --input_type geometric \
      --output_path $DATASET_PATH/dense/0/fused.ply

  # 泊松重建并三角化
  $ colmap poisson_mesher \
      --input_path $DATASET_PATH/dense/0/fused.ply \
      --output_path $DATASET_PATH/dense/0/meshed-poisson.ply \
      # --PoissonMeshing.depth 10 \
      # --PoissonMeshing.trim 3

  # 或者使用德劳内重建并三角化
  $ colmap delaunay_mesher \
      --input_path $DATASET_PATH/dense/0 \
      --output_path $DATASET_PATH/dense/0/meshed-delaunay.ply
  ```
- 每一条命令都可以加 `-h` 参数来查看*支持修改的参数*以及*默认值*
  + feature_extractor: 比较重要的就是 `--ImageReader.single_camera`
    - `--ImageReader.single_camera`: 指定所有图像使用相同的相机模型和内参
  + exhaustive_matcher: 比较重要的就是 `--SiftMatching.guided_matching`
    - `--SiftMatching.guided_matching`: 使用几何信息（例如相机位姿）来引导特征匹配过程，从而提高匹配的准确性和鲁棒性，可以在某些情况（特别是当图像之间的视角变化较大时）下显著提高匹配的质量
  + mapper: 比较重要的就是 `--Mapper.min_num_matches`
    - `--Mapper.min_num_matches`: 每对图像之间的最小匹配数，如果匹配数低于此值，则不会生成连接
  + poisson_mesher: 比较重要的就是 `--PoissonMeshing.depth` 和 `--PoissonMeshing.trim`
    - `--PoissonMeshing.depth`: 控制 Poisson 表面重建的深度。较高的深度值会生成更细致的网格，但也会增加计算时间和内存消耗
    - `--PoissonMeshing.trim`: 控制网格的修剪程度。较高的修剪值会移除更多的外部噪声和孤立点，但也可能移除一些有用的点

== Visualization
- colmap gui 可以可视化
  + 图像及其特征点：在 Database Management 里，然后 `show image`
  + 稀疏重建结果：`import model`，然后选择 `sparse/0` 文件夹（有 `project.ini` 的那个）
  + `.ply` 文件: `import model from`，然后选择 `fuse.ply` 或 `meshed-poisson.ply` 或 `meshed-delaunay.ply`
- 但如果要可视化深度图，或者对稀疏重建点云做修改（比如标记出来自哪张图的特征点），可能就需要自己写 python 代码了。colmap 提供了一些脚本，里面包含大量工具函数可供使用。我修改 `main()` 函数如下
  - 可视化深度图
  ```py
  def main():
      geometric_depth_map_path = "./project/dense/0/stereo/depth_maps/00001.jpg.geometric.bin"
      photometric_depth_map_path = "./project/dense/0/stereo/depth_maps/00001.jpg.photometric.bin"
      geometric_depth_map = read_array(geometric_depth_map_path)
      photometric_depth_map = read_array(photometric_depth_map_path)

      min_depth_percentile = 5
      max_depth_percentile = 95

      geometric_min_depth, geometric_max_depth = np.percentile(
          geometric_depth_map, [min_depth_percentile, max_depth_percentile]
      )
      photometric_min_depth, photometric_max_depth = np.percentile(
          photometric_depth_map, [min_depth_percentile, max_depth_percentile]
      )
      geometric_depth_map[geometric_depth_map < geometric_min_depth] = geometric_min_depth
      geometric_depth_map[geometric_depth_map > geometric_max_depth] = geometric_max_depth
      photometric_depth_map[photometric_depth_map < photometric_min_depth] = photometric_min_depth
      photometric_depth_map[photometric_depth_map > photometric_max_depth] = photometric_max_depth

      import pylab as plt
      plt.subplot(1, 2, 1) # geometric
      plt.imshow(geometric_depth_map)
      plt.title("geometric depth map")
      plt.subplot(1, 2, 2) # photometric
      plt.imshow(photometric_depth_map)
      plt.title("photometric depth map")
      plt.show()
  ```
  - 可视化稀疏重建点云（修改来自 `00001.jpg` 的点的颜色）
  ```py
  def main():
      input_model = "./project/sparse/0"
      input_format = ".bin"

      cameras, images, points3D = read_model(path=input_model, ext=input_format)
      print("num_cameras:", len(cameras))
      print("num_images:", len(images))
      print("num_points3D:", len(points3D))

      # 可视化三维稀疏模型点云，将和 00001.jpg 关联的关键点换成特别的颜色
      image_id = 1
      image = images[image_id]
      point3D_ids = image.point3D_ids # 读取 00001.jpg 的点及其索引
      points = np.array([point3D.xyz for point3D in points3D.values()]) # 读取所有 3D 点
      colors = np.array([point3D.rgb for point3D in points3D.values()]) # 读取所有 3D 点的颜色

      # 修改 00001.jpg 的点的颜色
      valid_indices = (point3D_ids > 0) & (point3D_ids <= len(points3D))
      point3D_ids = point3D_ids[valid_indices]
      colors[point3D_ids-1] = [255, 0, 0]

      # 可视化
      pcd = o3d.geometry.PointCloud()
      pcd.points = o3d.utility.Vector3dVector(points)
      pcd.colors = o3d.utility.Vector3dVector(colors / 255)
      o3d.visualization.draw_geometries([pcd])
  ```

= 其它工具 (to be con'T)