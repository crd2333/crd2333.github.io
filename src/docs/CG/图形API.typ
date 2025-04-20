#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "图形 API 笔记",
  lang: "zh",
)

= OpenGL
== 课上讲的 OpenGL（过时）
- OpenGL 是一个跨平台的图形 API，用于渲染 2D 和 3D 图形
- OpenGL Ecosystem
  - OpenGL, WebGL, OpenGL ES, OpenGL NG, Vulkan, DirectX ...
  - #link("https://blog.csdn.net/qq_23034515/article/details/108283747")[WebGL，OpenGL 和 OpenGL ES三者的关系]
- OpenGL 是做什么的？
  - 定义对象形状、材质属性和照明
    - 从简单的图元、点、线、多边形等构建复杂的形状。
  - 在 3D 空间中定位物体并解释合成相机
  - 将对象的数学表示转换为像素
    - 光栅化
  - 计算每个物体的颜色
    - 遮光
- Three Stages in OpenGL
  - Define Objects in World Space
  - Set Modeling and Viewing Transformations
  - Render the Scene
  - 跟我们学的顺序类似
- OpenGL Primitives
  - `GL_POINTS`, `GL_LINES`, `GL_LINE_STRIP`, `GL_LINE_LOOP`, `GL_TRIANGLES`, `GL_QUADS`, `GL_POLYGON`, `GL_TRIANGLE_STRIP`, `GL_TRIANGLE_FAN`, `GL_QUAD_STRIP`
  - 放到 `glBegin` 里决定如何解释，具体见 PPT
- OpenGL 的命令基本遵守一定语法
  - 所有命令以 `gl` 开头
  - 常量名基本是大写
  - 数据类型以 `GL` 开头
  - 大多数命令以两个字符结尾，用于确定预期参数的数据类型
- OpenGL 是 Event Driven Programming
  - 通过注册回调函数(callbacks)来处理事件
  - 事件包括键盘、鼠标、窗口大小变化等
  #fig("/public/assets/CG/API/2024-09-22-16-45-55.png", width: 50%)
- Double buffering
  - 隐藏绘制过程，避免闪烁
  - 有时也会用到 Triple buffering
- 后来看了看 OpenGL 的相关教程，感觉现在的实现和这里不太一样（可能过时了……）。还是以网络教程为准
- WebGL Tutorial / OpenGL ES

== 现代 OpenGL
- OpenGL 是一个相对老旧的图形 API，但了解它的底层原理对于理解现代图形 API 仍然非常有帮助
  - OpenGL 的 Windows 环境搭建可以参考 #link("https://github.com/yocover/start-learning-opengl/")[这个仓库]
  - OepnGL 的学习主要参考这个网址：#link("https://learnopengl-cn.github.io/")[learnopengl-cn]
- 这里首先需要搞明白各种规范、实现与它们的定位
  - OpenGL 只是一个标准 / 规范，具体的实现是由驱动开发商针对特定显卡实现的。这是因为图形学渲染管线跟硬件 (GPU) 高度相关，跟显卡架构、驱动版本等都有关系
    - 类似地，OpenGL ES, Vulkan, DirectX, Metal 等都是*标准*。Vulkan 可以看作是 OpenGL 的精神续作（不向下兼容的后继），而 DirectX, Metal 分别是 Microsoft 和 Apple 的专有标准
    - 怎么实现？一般显卡驱动安装后会有相应的 `.so`, `.a`, `.dll`, `.lib` 等文件，通过动态链接库的方式调用
  - OpenGL 本身无法创建窗口，窗口需要用到上下文
    - 一个形象的比喻是，一个画家在画图，OpenGL 就是这个画家（可以发出各种指令），而作画需要用到的画笔、画布等东西就是 Context，Context 的切换就像画家同时作多幅画，每一幅画有自己的画笔、画布。上下文是线程私有的，在线程中绘制时，需要为每一个线程指定一个Current Context的，多个线程不能指向同一个Context
    - GLFW 是一个针对 OpenGL 的 C 语言库，它提供了一些渲染物体所需的最低限度的接口。它允许用户创建 OpenGL 上下文，定义窗口参数以及处理用户输入。事实上它还支持 OpenGL ES, Vulkan
  - OpenGL扩展引入方式
    - 由于 OpenGL 驱动版本众多，它大多数函数的位置都无法在编译时确定下来，需要在运行时查询。所以任务就落在了开发者身上，开发者需要在运行时获取函数地址并将其保存在一个函数指针中供以后使用。取得地址的方法因平台而异，代码非常复杂，而且很繁琐，我们需要对每个可能使用的函数都要重复这个过程
    - 幸运的是，有些库能简化此过程，比如 glad, glew。其中 glad 是目前最新，也最流行的库。具体而言，它用来管理 OpenGL 的函数指针，所以在调用任何 OpenGL 的函数之前我们需要初始化 glad。glad 也可以使 OpenGL 基础渲染变得简单
- 具体的代码和流程这里就不写了，还是得多看代码多实践 (learnopengl-cn)

= Vulkan
== Vulkan 简介
- Vulkan 是 Khronos 组织在 2015 年底发布的新一代图形 API
- Vulkan vs. GL/GLES
  - 发展历程
    #fig("/public/assets/CG/API/2025-01-11-13-38-00.png")
  - 特性对比
    #grid(
      columns: 2,
      tbl(
        columns: 3,
        [功能特性], [Vulkan], [GL/GLES],
        [驱动渲染模式], [支持 CommandBuffer，\ 支持 Mulitple Submit], [立即渲染模式],
        [状态切换], [预处理，轻量级，\ 运行时切换 Handle 即可], [状态切换影响\ 全局状态机],
        [资源管理], [开发者定制], [驱动管理\ 暴露部分接口],
        [CPU/GPU\ 同步管理], [Fence, Barrier,\ Semerphore, Event], [驱动管理\ 开发者无法干预],
        [Renderpass], [显式地 Renderpass 切换，\ 多 subpass 支持], [驱动管理\ 完全黑盒],
        [Shader 支持], [支持 SPIR-V 开放标准], [Shader Compiler\ 由各个驱动实现，\ 没有统一标准],
        [Debug 支持], [由开源 Validation Layer\ 完成，动态加载], [包含在驱动中],
      ),
      [#fig("/public/assets/CG/API/2025-01-11-13-48-47.png", width: 90%)],
    )
  - 优缺点
    #grid(
      columns: (50%, 50%),
      [
        - Vulkan
          - 优点
            + 大幅减轻 CPU 负载
              - 几乎所有管线状态都预创建，运行期绑定即可；
              - 驱动状态绑定只需切换 Handler，几乎零消耗；
            + 显式的硬件控制
              - 通过 CommandQueue 进行显式提交
              - 多种同步管理：Fence、Barrier、Semaphore、Event
              - 显式的 Renderpass 切换
            + 原生的多线程支持
            + 完美契合 Tile-based 架构
            + 跨平台，支持 API 互转
            + 完整的官方支持
          - 缺点
            + 移动端驱动有待完善
            + 接口复杂，学习成本高
            + 各平台驱动差异较大
      ],
      [
        - GL/GLES
          - 优点
            + 接口简单易用
            + 运行状态灵活多变
            + 驱动完善，表现差异性较小
            + 学习资料多，学习成本低
            + 向下兼容
          - 缺点
            + 标准更新慢，现代渲染技术适应性较差
            + 扩展众多，接口繁杂
            + CPU 负载重，跑大型场景很吃力
      ]
    )
- Vulkan vs. Dx12, Metal
  #tbl(
    columns: 4,
    [功能特性], [Vulkan], [DX12], [Metal],
    [稀疏资源], [完整支持], [完整支持], [需要 Metal3，\ A13 以上的硬件],
    [Indirect Draw], [支持\ 1.2 开始支持 indrect], [完整支持], [不支持],
    [Renderpass], [多 subpass 支持], [未来准备支持], [多 subpass 支持],
    [Shader 资源绑定], [无需实时绑定], [无需实时绑定], [运行时执行 Set],
    [支持], [跨平台 API], [Win7 以上系统专有 API], [iOS8 以上、macOS 系统专有 API],
    [设计理念], [模块化，尽量暴露硬件操作], [完整支持 GPU Driven，Async Compute], [易用性，高性能，低开销]
  )

== Vulkan 基础技术
- 可以参考这一篇咕咕了、只有第一章的教程 #link("https://frightenedfoxcn.github.io/blog/e453db9c/")[大概可能不难上手的 Vulkan 教程（1） 计算管线]，介绍了一个基本的 Vulkan 程序的结构
- 中文文档 #link("https://docs.vulkan.net.cn/guide/latest/index.html")[Vulkan 指南]


== Vulkan 优化技术概述




== 未来展望






