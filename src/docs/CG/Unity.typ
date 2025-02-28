#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Unity",
  lang: "zh",
)

#align(center, text(size: 14pt)[#emoji.face.nerd 我们团结引擎真是太有实力辣 #emoji.face.heat])

= Unity
基本了解 C\# 语法（#link("https://crd2333.github.io/note/Languages/C#")[我的笔记]）后，就可以开始学习 Unity 的基本概念了。这里我主要参考以下资料：
+ 先看 #link("https://zhuanlan.zhihu.com/p/453098296?utm_id=0")[Unity C\#基础笔记]、#link("https://zhuanlan.zhihu.com/p/621543577")[Unity快速上手【熟悉 Unity 编辑器，C\# 脚本控制组件一些属性之类的】]
+ 一个从英文翻译来的完整的系列教程 #link("https://zhuanlan.zhihu.com/p/346208723")[Unity 基础教程系列（新） —— Unity 引擎入门和 C\# 编程入门]
+ 有时间的话可以过一遍 #link("https://learn.unity.com/project/john-lemon-s-haunted-jaunt-3d-beginner-1?uv=2020.3")[Unity 官方的项目教程]

== Unity 基础
=== 组件
- Unity 是*面向组件*的游戏引擎，组件即功能。需要给游戏对象添加什么功能就给它添加什么组件，游戏对象的不同来自于组件的不同
- 每一个组件都是一个脚本，要么是内置的，要么是继承自 `MonoBehaviour` 的自定义脚本。不过反过来，脚本不一定是组件，比如一些工具类脚本，又比如扩展编辑器脚本
- 组件的生命周期函数
  - 生命周期函数就是该脚本对象依附的 GameObject 从出生到消亡整个生命周期中，会通过反射自动调用的一些特殊函数，其访问修饰符一般为 private 和 protected（因为不需要我们手动调用）。下面罗列了一些常用的生命周期函数，实际上还有更多包括物理模拟、动画、渲染方面的，详见 #link("https://docs.unity.cn/cn/2019.4/Manual/ExecutionOrder.html")[Unity 官方的文档和图]
  #grid(
    columns: 2,
    [
      + Awake：在脚本实例化后立即调用，用于初始化变量或游戏状态（所以继承自 `MonoBehaviour` 的类都不推荐写构造函数，因为反而破坏了 Unity 设计规范。另外，继承 `MonoBehavior` 的脚本不能 new 只能挂载）。此函数在所有对象被初始化后调用，因此可以安全地与其他对象交互
      + OnEnable：当对象变为可用或激活状态时调用。此函数在创建 `MonoBehaviour` 实例时（例如加载关卡或实例化具有脚本组件的游戏对象时）会执行
      + Start：在第一次帧更新之前调用，仅当脚本实例启用后才会调用。适合进行延迟初始化
      + Update：每帧调用一次，是用于帧更新的主要函数。大部分游戏逻辑代码在此函数中执行
      + FixedUpdate：以固定时间间隔调用，常用于物理相关的计算
      + LateUpdate：在每帧的Update函数调用之后调用，常用于调整脚本执行顺序，例如相机跟随
      + OnDisable：当对象变为不可用或非激活状态时调用，用于清理代码
      + OnDestroy：在对象销毁时调用，用于释放资源
      - 多个对象的生命周期函数
        - 例如，如果有多个脚本 `test1.cs`, `test2.cs`, `test3.cs` 用作组件，它们的执行顺序如何？
        - 参考 #link("https://blog.csdn.net/qiaoquan3/article/details/56301112")[Unity 多个物体间的脚本执行顺序]
        - 大致意思是说，后挂载的脚本先执行而先挂载的后执行；每个周期执行完所有对象的 `Update` 之后再执行 `LateUpdate`（单线程）；部分函数成对出现，如 `Awake` 紧跟 `OnEnable`，`OnDisable` 紧跟 `OnDestroy`
    ],
    fig("/public/assets/CG/2025-02-22-18-38-31.png")
  )

- 一些核心组件
  + Transform 类：每个 GameObject 都包含的默认组件，功能包括平移、旋转、缩放，Hierarchy 中的父 / 子关系其实是由 Transform 决定的
  + Rigid Body 类：用于模拟物理效果，比如重力、碰撞、运动等。其跟 Collider 的关系是，Collider 用于检测碰撞，Rigid Body 用于模拟物理效果

=== 材质
- 参考 #link("https://blog.csdn.net/shulianghan/article/details/127753025")[【Unity3D】材质 Material] 与 #link("https://blog.csdn.net/qq_42672770/article/details/108068718")[Unity 基础二：Material 材质、Texture 纹理（贴图）和 Shader 着色器] 获取一个基本的概念
- 我们可以首先明确 material 在一个 GameObject 的定位
  #grid(
    columns: (50%, 50%),
    column-gutter: 4pt,
    [
      - 一般来说，一个 3D GameObject 都会包含 Mesh Filter 和 Mesh Renderer 组件。前者保存 Mesh，定义了 Geometry；后者定义了 Appearance，它包括 Materials, Lighting, Probes 等
        - 可以看到，这么一个层级结构跟我们自己用 OpenGL 写小引擎这种图一乐的结构有很多不同（大引擎就是规范啊
      - 而 material 实质上就是 shader 的实例，在 Inspector 上修改 material 的相关属性实质上是在更改 shader 的设置
        - material 中的 maps 包括反照率 (Albedo)、金属质地 (Metallic)、法向 (Normal)、高度 (Height)、遮挡 (Occlusion) 等，它们都可以设置纹理（贴图）
      #fig("/public/assets/CG/2025-02-22-20-43-10.png")
    ],
    fig("/public/assets/CG/2025-02-22-20-48-32.png")
  )
  - material 在代码里有 materials 与 sharedMaterials 之分，详见 #link("https://www.jianshu.com/p/b600f9f26f49")[[Unity] Renderer的materials与sharedMaterials]

=== 杂项
- 脚本序列化
  - 在脚本里写的 public 变量可以显示在 GameObject 的 Inspector 里，这叫做序列化
    - 为了显示方便，用 `m_` 前缀表示的成员 (member) 变量会显示成不带前缀的变量名，且自动分词
  - 默认只有继承自 `MonoBehaviour` 的类才能序列化，普通类需要添加 `System.Serializable` 属性。也可以有其它属性更具体地定义，序列化和反序列化的行为也可以重写
- 运行的单位是场景 (scene)，最基础的游戏单位叫做游戏体 (GameObject)
- 预制体 Prefab
  - 参考 #link("https://blog.csdn.net/weixin_74850661/article/details/132731639")[Unity 之预制体 (Prefab) 的解释以及用法]

== Unity 进阶

=== GUI
Unity 的 GUI 方面，早期有 IMGUI，是 Unity 自带的古老 UI 系统；NGUI 是第三方 UI 插件之一，Unity 早期功能不流行时比较流行；UGUI 是 Unity 4.6 之后推出的新 UI 系统，也是目前 Unity 的主流 UI 系统。

UGUI 具体可以参考 #link("https://blog.csdn.net/qq_37701948/article/details/106682377")[超详细的 Unity UGUI 教学] 这篇文章，不过这些设计可能跟美术关系更大，暂时不深究了。

- 对于我而言，我主要需要知道的就两点
  + UI 最基本的是*画布 Canvas*，相当于屏幕
    - 其他 UI 控件如 Text, Image, Button 等都放在画布上面作为 Canvas 的子控件
    - Canvas 组件的渲染模式一般默认是*屏幕空间-覆盖*，即覆盖在摄像机画面之上，永远在最上层。Canvas 的缩放模式一般是*按屏幕分辨率缩放*，但要注意其下的子控件也需要做适配
  + 利用事件系统 EventSystem 做交互

上面这些 GUI 是专注于游戏运行时，具体到*编辑器*的话题，相比原生 EditorWindow，有个叫做 Odin 的插件，用起来会更方便且强大，具体可以参考 #link("https://aihailan.com/archives/466")[海澜大佬的系列文章]。目前我写编辑器主要是依靠 Odin。

=== 存储
Unity 中许多数据需要*序列化*成字符串，进而才能显示在 Inspector 或其它编辑器窗口上。更进一步，我们可能需要将这些数据*持久化*成文件，保存到磁盘上，比如存成 `xml`, `json`, `excel`, `assets` 等文件。

其中前三种很好理解，而 `assets` 是 Unity 专有的资源文件，与 `ScriptableObject` 有关，具体可以参考这篇文章 #link("https://blog.csdn.net/qq_46044366/article/details/124310241")[Unity 进阶：ScriptableObject 使用指南]。

长话短说，`ScriptableObject` 是 Unity 提供的一个*数据配置存储基类*，可以作为用来保存大量数据的*数据容器*。它类似于 `MonoBehaviour`，继承自 `UnityEngine.Object`（因为不同于 `MonoBehaviour`，继承自它的脚本无法挂载到游戏物体上）。`ScriptableObject` 类的实例会被保存成 `.asset` 文件，存放在 `Assets` 文件夹下，其实例唯一存在。

- `ScriptableObject` 的主要作用大体上可以分成三点：
  + *编辑模式下的数据持久化*
    - 编辑模式下修改了 `ScriptableObject` 派生类对象的数据，将会被持久化保存；但是在发布运行后，即使在游戏中修改了数据，也不会受到影响
    - `ScriptableObject` 适合在编辑模式下调试数据与制作编辑器功能，但不适合存储在游戏打包发布后的运行期间会改变的数据
  + *数据配置*
    - `ScriptableObject` 非常适合用来做配置文件。因为配置文件一般在游戏发布前就定好了规则，且在游戏运行时只读
    - 相对于传统 `xml`、`json` 等配置文件，`ScriptableObject` 可以直接在 Unity 内部 Inspector 面板中配置，更加方便
  + *数据复用*
    - 比如一个 prefab 下挂载某个脚本，脚本上有一些相同只读数据。如果直接 prefab 实例化，每个实例都会有一份数据
    - 如果将这些数据放到 `ScriptableObject` 派生类中，脚本上只存对其的引用，这些数据就被所有实例共享

- *怎么创建和使用* `ScriptableObject`？
  - 上面的文章介绍了两种*创建办法*
    + 一是用 `CreateAssetMenu` 把 `ScriptableObject` 派生类做成跟预制体、材质球等一样的能在面板中手动创建的资源
    + 二是用 `Assets/Editor` 文件夹下的编辑器脚本中调用 `AssetDatabase` 等 API 来创建
  - *使用方法*也是两种
    + 一是直接得到其 public class 然后存成引用
    + 二是调用 `AssetDatabase`  等 API 来加载。

- 让 `ScriptableObject` 非持久化或真正意义上持久化
  - 利用 `ScriptableObject` 类中的静态方法 `CreateInstance<>()`，让其在运行时创建一个只存储在内存中的实例，而不是引用真实的 `.asset` 文件。这样实现了编辑模式和打包发布后均为非持久化
  - 配合 `json`, `xml`, 二进制等方式来实现 `ScriptableObject` 真正意义上的数据持久化。但多少有点画蛇添足，不如直接抛开 `ScriptableObject`，自定义数据结构类，用数据持久化方法交互

=== UnityEvent
参考 #link("https://blog.csdn.net/qq_46044366/article/details/122806863")[Unity 事件番外篇：UnityEvent]

以及 #link("https://blog.csdn.net/qq_46044366/article/details/122722948")[Unity 事件管理中心]

=== Singleton
参考 #link("https://blog.csdn.net/qq_46044366/article/details/122768530")[Unity 单例基类（运用单例模式）]

=== 渲染管线
- 要想了解 Unity 着色器编程，需要对其整个的渲染管线有一定了解，参考
  + #link("https://zhuanlan.zhihu.com/p/353687806")[Unity URP/SRP 渲染管线浅入深出【匠】]
  + #link("https://blog.csdn.net/xubufanzhou/article/details/131223847")[Unity 学习笔记（七）渲染管线]（官方文档的翻译。。。先不看了）
  + #link("https://zhuanlan.zhihu.com/p/378828898")[【Unity】SRP 简单入门]

- 首先我们要知道 Unity 各个渲染管线的关系
  #tree-list(
    root: [渲染管线],
    [
      - 内置渲染管线 Built-in Render Pipeline
      - 可编程渲染管线 Scriptable Render Pipeline (SRP)
        - 通用渲染管线 Universal Render Pipeline (URP) $<--$ 轻量级渲染管线 Lightweight Render Pipeline (LWRP)
        - 高清度渲染管线 High Definition Render Pipeline (HDRP)
    ]
  )
  - 不过这里要廓清一个概念，以上这些渲染管线都是 Unity 封装抽象的结果，最终映射到底层图形 API 所对应的经典*图形渲染管线*
    - 比如 DirectX 11, OpenGL, Vulkan, Metal 等，假如读者有过脱离商业引擎自己手搓小引擎的经历，应该知道这里在说什么
    - 而*图形渲染管线*也是 *“可编程的”*，包括顶点着色器、几何着色器、片段着色器。这里的 “可编程” 跟 SRP 的 “可编程” 是不同层级的概念，后者建立于 Unity 的规定之上
  - *SRP* 是什么？为什么要有它？这是因为 Unity 一开始的内置渲染管线在一个管线里支持所有平台，代码浮肿、定制性差、性能不佳。为此，SRP 将渲染管线拆成底层的渲染 API 和上层的 C\# 脚本，既提高可扩展性和易用性，也提高了性能
  - *URP* 前身为 LWRP，它是 SRP 的一种实现，为了提高移动端性能而推出，现在已经成为 Unity 的主流且通用的渲染管线。既然它仍是 SRP，就可以以它为模板继续进行自定义
  - *HDRP* 也是 SRP 的一种实现，为了提高画质而推出，更多针对高端设备和主机
- SRP Batcher
  - SRP Batcher 是 SRP 的一个特性，用于减少 CPU 到 GPU 之间的数据传输，提高性能
  - 具体除了看上面第一篇文章外，还可以参考这篇 #link("https://zhuanlan.zhihu.com/p/165574008")[Unity SRP Batcher的工作原理]


=== Shader
- Unity Shader 部分的资料，我主要参考了
  + #link("https://zhuanlan.zhihu.com/p/29239896")[基于 Unity 引擎的游戏开发进阶之着色器 (Shader) 入门 & 图形特效]
  + #link("https://www.zhihu.com/column/unityTA")[Unity 技术美术] 专栏中的《零基础入门 Unity Shader》系列（可能比较浅，但对入门理解概念很有帮助，尤其前面几章写得很好！）
  + #link("https://blog.csdn.net/lengyoumo/article/details/98497353")[Unity Shader Lab (cg hlsl glsl) 着色器入门教程 以及 vstudio 支持 unity shader 语法]（感觉写成了文档而非教程，可以用来查阅）
  + #link("https://docs.unity.cn/cn/2018.4/Manual/SL-Reference.html")[Unity 官方着色器文档]（挺机翻的，不过毕竟还是权威）
  + 啃《Unity Shader 入门精要》这本书，Z-lib 上有 epub 版。能找到一些 #link("https://zhuanlan.zhihu.com/p/569862136")[读书笔记]、#link("https://www.bilibili.com/video/BV1sh41147zb/")[视频笔记]，但还是自己啃吧

Unity 的着色器使用自定义 ShaderLab 声明性语言，充当一个容器，在其中嵌入具体的着色器代码，比如 HLSL（基于 Direct3D）、GLSL（基于 OpenGL）、Cg（Nvidia 与微软合作开发的跨平台着色器语言）。一般来说，建议使用 Cg / HLSL 来编写，这不仅是因为二者本质共通且 Cg 基于 C 语言比较好掌握，更是因为它们有更好的跨平台性（当然用 GLSL 也不是不行）。

#q[
  可能会好奇它们与图形 API 的关系是什么？简单来说，渲染管线定义了整体流程，而图形 API 提供硬件抽象层，它们负责组织、调度和管理这些着色器，从而实现实现具体渲染逻辑。DirectX 使用 HLSL，Vulkan 使用 SPIR-V 但支持将 GLSL, HLSL 等编译为 SPIR-V，OpenGL 使用 GLSL，Metal 使用它们自己的 MSL。而 Unity 作为一个成熟的商业游戏引擎，位于所有这些之上，将它们组织、调度、抽象的同时也开放给开发者修改的接口
]

- ShaderLab 着色器基本结构
  ```
  Shader "Custom/MyShader"{
      Properties{
          // Properties 是着色器的属性，可能是纹理，颜色或者其他参数
      }
      SubShader{
          // SubShader 中包含了一个具体的着色器
      }
      SubShader{
          // 后一个 SubShader 是前一个 SubShader 的简单版
          // 当显卡不支持前一个 SubShader 时，会尝试后一个 Shader
      }
      FallBack "Diffuse"       // 显卡不支持前面所有 SubShader 时的选择
      CustomEditor "ShaderGUI" // 自定义编辑器
  }
  ```
- Unity 着色器类型包括
  + 固定功能管线着色器 Fixed Function Shaders
    - 用于不支持高级着色器特性的旧硬件
    - 完全使用 ShaderLab 语言编写（直接调用固定功能管线的内置功能，无需手写自定义渲染逻辑）
    - 基本已经被淘汰，不推荐使用
  + 表面着色器 Surface Shader
    - ShaderLab 特有的让开发者以相对简便方式实现复杂功能，关键代码使用 Cg / HLSL 语言编写，嵌入到 SubShader 代码块
    - Surface Shader 最终被 Unity 转换为顶点和片段着色器，即它可看作后者的又一层封装
    - Unity 自己的可视化 Shader Graph 工具生成的都是顶点和片段着色器，由此可见在今后的可编程渲染管线中，Unity 自己也逐步抛弃了 Surface Shader
      - 顺带一提，这个工具大大降低了 Shader 编写的门槛，但作为 Unityer 最好还是具有基本的 ShaderLab 编写能力
  + *顶点和片段着色器 Vertex and Fragment Shader*
    - 功能强大，但复杂难写，基于 GLSL, HLSL, CG 三种着色器语言，ShaderLab 均支持
    - 如上所述，顶点和片段着色器是 Unity 着色器的核心，之后会更多记录这方面的内容
- 具体的内容庞杂繁多，还是自己啃书吧，记不下来。。。

=== 底层
- 总所周知，Unity 的底层是 C++，但脚本是用 C\#，这一节将探讨 Unity 的底层设计。参考：
  + #link("https://zhuanlan.zhihu.com/p/400470713")[【Unity笔记】ShaderLab 与其底层原理浅谈]
  + #link("https://zhuanlan.zhihu.com/p/378781638")[【Unity】SRP 底层渲染流程及原理]
  + #link("https://zhuanlan.zhihu.com/p/362941227")[Unity 的内存管理与性能优化]
  + #link("https://zhuanlan.zhihu.com/p/381859536")[【笔记】Unity 内存分配和回收的底层原理]

