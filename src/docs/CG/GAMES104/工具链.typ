---
order: 6
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GAMES104 笔记",
  lang: "zh",
)

- #link("https://games104.boomingtech.com/sc/course-list/")[GAMES104] 可以参考这些笔记
  + #link("https://www.zhihu.com/column/c_1571694550028025856")[知乎专栏]
  + #link("https://www.zhihu.com/people/ban-tang-96-14/posts")[知乎专栏二号]
  + #link("https://blog.csdn.net/yx314636922?type=blog")[CSDN 博客]（这个写得比较详细）
- 这门课更多是告诉你有这么些东西，但对具体的定义、设计不会展开讲（广但是浅，这也是游戏引擎方向的特点之一）
- 感想：做游戏引擎真的像是模拟上帝，上帝是一个数学家，用无敌的算力模拟一切。或许我们的世界也是个引擎？（笑
- [ ] TODO: 有时间把课程中的 QA（课后、课前）也整理一下

#let QA(..args) = note(caption: [QA], ..args)
#counter(heading).update(12)

= 引擎工具链基础
工具链在引擎中仿佛默默无闻，但其实是非常重要的组成部分。游戏引擎在宣传时总是强调其渲染、物理、AI 等等有多酷炫，但相关从业者看了也就大概知道怎么个实现了，更重要的反而是工具链的设计。一般商业引擎里的工具链代码量是超过引擎 Runtime 部分的。

#fig("/public/assets/CG/GAMES104/2025-04-04-21-53-38.png")

工具链是衔接不同岗位之间的桥梁（调和不同思维方式的人一起工作的平台），同时它也是各种 DCC (Digital Content Creation) 工具到游戏引擎的桥梁，它处在 ACP (Asset Conditioning Pipeline) 这一层。

== 复杂的工具
- *GUI 界面*
  - GUI 就是工具的操作界面，正在变得越来越复杂，它要求 fast iteraction, separation of design and implementation, reusability
  - 两大类实现方式
    + Immediate Mode
      - 例如 Unity UGUI
      - 每次绘制时由游戏逻辑直接发出绘图命令，需要不间断发出指令
      - 好处是直接、简单、快，坏处是扩展性差、把业务压力给到逻辑这边，压力大
    + Retain Mode
      - 例如 UE UMG, Qt GUI
      - 类似于 Graphics 的 Command Buffer，GUI 绘制逻辑时根据存储的命令自行绘制，如果不需要更新，就不用发出命令，且把游戏逻辑和工具的 GUI 逻辑分开了
      - 好处是扩展性强，性能高、可维护性高，但往深处做就要涉及到许多 Design Pattern 的概念
- *Design Pattern 设计模式*
  - 当一个工具有几十上百个功能时，如果不遵循某一设计模式的指导，往往会越来越混乱甚至动辄炸掉
  #grid2(
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-04-22-14-27.png", width: 70%),
    fig("/public/assets/CG/GAMES104/2025-04-04-22-14-36.png", width: 70%),
  )
    #fig("/public/assets/CG/GAMES104/2025-04-04-22-14-57.png", width: 70%)
  - MVC
    - Model 管理组织应用数据 $->$ View 任何表示信息的方式如图、表 $->$ Controller 接受输入并更新 Model 和 View
    - 数据流是单向的，原始数据不会被弄脏，一定程度上能够解耦二者
    - 最经典，变种也最多的设计模式
  - MVP
    - Presenter 从 Model 里取数据呈现给 View，又从 View 的用户交互里反馈给 Model
    - 把 Model 和 View 拆分得更彻底、干净，二者的功能和测试更独立，代价是 Presenter 会比较臃肿
  - MVVM
    - 与 MVP 相似但是用 ViewModel 来代替 Presenter，不是在代码里写死对 View 和 Model 的 query，而是利用 Binding 的机制区分得更好
    - MVVM 的 View 更多是一个 designer 而非传统的也是一个 developer，降低了对代码的依赖，更强调所见即所得，从而可以直接让 UX Designer 来做。一般是直接用 xml, json 等文件即可描述
    - 这也是现代最常用的模型，好处是独立开发、方便测试和复用，坏处是平台依赖性强、debug 困难、对简单 UI 需求太 overkill 以及必须得在现成框架上开发（当然这也不全是坏处，比如现在在 `.cs` 里写 GUI 比 `.cpp` 里方便太多）
  - 建议：游戏引擎工具链需要有非常强的工程可扩展性，最好不要自己造轮子，而应该选择最成熟的结构和方案
- *数据的加载和存储*
  - 序列化 (Serialization) 和反序列化 (Deserialization) 其实就是 save 和 load，将数据转化为二进制块方便存储。它不仅局限于存到硬盘，也广泛应用于网络传输、工具链传输中
  - 存储形式
    + Text File
      - 最简单的 txt 以及结构化的 xml, json, yaml 等。比如 Unity 用 subset of YAML，Cryengine 用 XML / Json
      - 好处是易读，容易 debug。引擎推荐优先支持此类，测试完成后转成 Binary File
    + Binary File
      - 二进制文件，例如 Unity 的 `*.asset` 和 Runtime、Unreal 的 `*.uasset`、FBX Binary 等
      - 好处是存储容量小，并且容易加密，安全性高，且省去了语义的 Parse 处理。比如 FBX Binary 比 FBX Text 占用小很多，总体加载速度能快 $10$ 倍。因此上线产品一般用这种形式
- *资产引用*
  - 游戏中很多东西会重复出现，为了节省内存需要资产引用，通过引用实例化 (Instance) 重复对象 (Prefab)
  - Object Instance Variance（Prefab 与 Prefab Variant）
    + 通过*复制*的方式构建变体：复制原先数据并修改，但是比较低效并且丧失关联性
    + 通过*数据继承 (Data Inheritance)* 的方式构建变体：继承原数据并 override

== Deserialization 资产加载
-* Parse 资产解析*
  - 加载资产是一个 Parse 的过程，并且所读到的某个属性可能还没被加载出来，需要构建一个 Key-Type-Value Pair Tree
    #fig("/public/assets/CG/GAMES104/2025-04-05-11-01-19.png", width: 50%)
  - 树状结构在 text 和 binary 文件里的形式
    + Text: store in asset（需要第三方库解析成一个 dictionary 再二次 Parse）
    + Binary: store in a table
  - Endianness 字节端序
    - 即大小端，不同游戏平台规则不同，做适配时需要注意
- *Asset Version Compatibility 资产版本兼容性*
  - 很多软件都只做到向下（向后）兼容，那怎么做到向上（向前）兼容？在元宇宙、分布式部署这类场景里非常需要
  - *By Version Hardcode*
    - 给资产添加版本号，对新版本新增的数据类型读取其 default value，对删除的数据类型不进行读取
    - Unreal 的做法，但其实不太好，随着时间的更迭代码越来越臃肿
  - *By Field UID*
    - 提出了 Protocol Buffer 的概念，给数据的每一个属性定义单调递增的 UID。存储时为每个 filed 根据 UID 生成固定大小的 key 并存储 data；读取时遇到 filed in schema but not in data 就用默认值，遇到 filed in data but not in schema 就跳过
    - Google 的做法，相对鲁棒

== Robust Tools 如何制作高鲁棒性的工具
游戏引擎工具链一旦崩溃，整个团队都得停摆，我们实际上得服务团队所有人，是最底层的打工仔（悲）。

- *Undo & Redo, Crash Recovery*
  - Undo & Redo 听起来简单，但（尤其是对游戏引擎）不同操作之间有很深的 correlation 且很多态；Crash 更是致命，设计得再好的工具也难免崩溃，一旦崩溃就几小时白干
- 这个问题在软件工程中其实是一个 well-studied problem，有一个成熟的 design pattern 来解决 —— *Command Pattern*
  - 记录用户所有操作（分解为多个 Command）并记录，定时保存到磁盘上
  - Command 的定义
    + UID 是唯一、累加的，用于记录执行顺序
    + Data 用于存储操作数据
    + `Invoke` 和 `Revoke` 方法用于执行和撤销操作
    + `Serialize` 和 `Deserialize` 方法用于序列化和反序列化，一般由所操作的数据实现
  - Command 的 $3$ 种主要操作：Add, Delete, Update

== Make Tool Chain 如何制作工具链
各个工具如果全部单独写的话，那将没有任何*可扩展性 (Scalability) 和可维护性 (Maintainability)*，因此需要找到这些工具通用的部分，把任何复杂结构用简单的 Building Block 构成，用一个标准的 Schema 去描述它们。

- *Schema*
  - 是一个 Description Structure，在不同工具之间规范化数据，自动生成标准化的用户界面
  - 需要有 Basic Elements (Atomic Types, Class Type, Container)，要有 Inheritance 的能力，要能支持 Data Reference
  - 两种定义方式
    + Standalone schema definition file
      - 直接用类似脚本的语言或结构化语言定义 schema，用一套方法反射成引擎代码，让引擎知道怎么读、写、编辑资产文件
      - 好处是好理解，把数据定义和工程实践相剥离；坏处是需要代码生成器，可能有版本问题，难以定义 function, API
    + Defined in code
      - UE 的做法，类似于 C++ 等高级语言的类，通过宏来描述数据、方法是 meta 的、可以反射的
      - 好处是可以包装 function 等，支持性好；坏处是对鲁棒性要求高
- 引擎数据的 $3$ 种 View
  - Runtime View: 在 CPU 和内存中，在乎读取速度和计算速度
  - Storage View: 在 SSD, HHD 中，在乎读写速度和存储空间
  - Tools View: 在 Human 尤其是非 Programmer 看来，需要更好理解的界面（比如弧度变为角度、颜色直观显示等）和多样的编辑模式 (Beginer Mode, Expert Mode)

== What You See is What You Get (WYSIWYG) 所见即所得
工具体系的核心精神：所见即所得，即工具是什么样运行时就是什么样（与运行环境配置一致），让设计师以最快的速度和最低的成本去尝试。

- *Stand-alone Tools*
  - 早期工具链独立于引擎，因为它的逻辑非常复杂，有很多 dirty and special 的代码，为了让引擎相对干净，把它独立出来
  - 好处是工具接入简单 (as a DCC tool plugin)，但是难以做到所见即所得。现在基本不用了
- *In Game Tools*
  - 直接在游戏引擎上做的工具，需要在 Runtime 层上架一层 Editor Scene，再实现 Editor GUI
  - 好处：完全 In-Game Editing，所见即所得，对生产效率提升帮助巨大
  - 坏处：开发成本高，需要引擎向上兼容编辑器需求；需要做复杂的 UI；容易导致工具链跟引擎同步崩溃
- *Play in Editor (PIE)*
  - 在编辑器里直接就能启动 (Play in editor world)；或者把编辑器中的数据拷贝一份启动游戏，类似于新开一个沙盒做分身 (Play in PIE world)
  - 前者比较简单，但 editor 跟 runtime 的数据难以分开（容易导致二者行为不一致出现 bug）
  - 后者是 UE / Unity 等商业引擎的做法，相当于多花一点内存更好地模拟游戏单独运行的环境，不过架构会更复杂

== Plugin 可拓展性
引擎太过复杂，做得再多也不能自大地认为完全覆盖了用户的需求，需要将引擎设计为一个平台让用户以插件 Plugin 的方式制作工具，比如 Unity 商店。

- 这要求引擎
  + 提供 PluginManager 来管理插件的加载和卸载
  + 提供 Interface 来为插件提供一系列抽象类，插件可以选择实例化不同的类来实现相应功能的开发
  + 提供对应的 API，暴露引擎的一系列函数，让插件可以自定义相关逻辑
  - 引擎自身功能也要尽可能 API 化、Module 化

= 引擎工具链高级概念与应用
== Architecture of World Editor 世界编辑器
世界编辑器（地图编辑器）是一个平台 Hub，把所有制作世界的逻辑集合起来，又对不同 user 呈现出不同 view。

- UE 的例子
  #fig("/public/assets/CG/GAMES104/2025-04-05-14-23-49.png", width: 80%)
- *Editor Viewport*
  - 设计师和游戏世界交互的窗口，下面跑了一个 Editor Mode 的 full game，额外提供很多为编辑而生的特殊功能
  - 因此会有部分 Editor Only 的代码，比如 Unity `.cs` 脚本里面写 `#if UNITY_EDITOR` 的宏，如果不小心开放很可能成为外挂入口
  - 需要引擎能支持多种 view，比如编辑的 view 和过场动画的 view 等
- Editable Object
  - Everything is an Editable Object，UE 里叫 Actor，Unity 里叫 Object (GameObject)
  - Object 的管理
    - 用 different views 显示所有 objects，比如 tree view
    - 分成各种 categories, groups, layers，还要支持 filger, search
  - Schema-Driven Object Property Editing
    - 选中一个 Object，通过 schema 反射出它拥有的属性，在一个 Panel 里生成界面提供给 designer 编辑
    - UE 中叫 Detail，Unity 中叫 Inspector，还有些叫 Property
- *Content Browser*
  - 在最初的时候，往往是一个有经验的 TA 规定所有 Assets 的存储结构，构成一个巨大的树状文件夹结构。但是一方面 TA 不可能预知未来游戏的复杂演化，另一方面这种组织方式不适合引用与改动
  - 因此需要一个 Content Browser 来组织所有的 Asset
    - 可以视作一个巨大的 "Ocean"，通过所需资产的名字、标签等检索
    - 根据不同项目来生成所需的 view，而不需要关心资产的位置（甚至不用在本地，可以是远程的数据库）
    - 当然仍旧会支持树状文件夹结构，但更多只是一个 view
- *Mouse Picking 鼠标选取*
  - 最基本的方法就是用 Raycast，相当于交给物理系统负责，但 query 性能较差
  - 也可以用 RTT (Render To Texture) 的方式，把 ObjectId 写在 FrameBuffer 上
    - 能够轻易地且快速地 query，支持 range queries
    - 如果跑的是 Editor Mode 且管线不支持 Visibility Buffer 等技术的话，就需要一个额外的 pass 来渲染。当然开发机一般配置较高问题不太大
    - 当然对透明物体（不写入 buffer）、微小粒子等还需要额外的 code 来处理，比如给 particle 挂载一个虚拟体代为选中
- *Object Transform Editing*
  - 更改平移、旋转、缩放，要支持快捷键、高亮等交互
  - 这方面逻辑简单，但想要打磨得比较好，并且达到成熟 DCC 工具的水平还是需要花不少功夫
- *Terrain*
  - Landform $->$ Height map, Appearance $->$ Texture map, Vegetation $->$ Tree instances & Decorator distribution map
  - Height Brush: smooth 是一个很大的难点，需要精心设计。此外艺术家有时有自定义笔刷的需求 (Scalability)
  - Instance Brush: 刷出来的 instance 是所见即所得的，且支持进一步的修改，但可能导致大量的数据冗余。这方面的问题可能需要 PCG 来解决
- *Environment*
  - 现代游戏越来越像电影，需要各种 Sky, Light, Roads, Rivers 的环境效果把氛围渲染好。这方面是通过各种各样的插件、工具协作完成，需要引擎为它们设计好空间
  - Rule System 环境规则
    - 比如路上不能有树，路应该适应地形……这些当然可以固定住让艺术家手调，但万恶的策划变来变去的需求会让工作量巨大
    - 更好的方法是程序化生成 (PCG)，先把原始的数据分层（road 的分布、tree 的分布、water 的分布……），定义一套规则系统来约束，让程序整合最后的结果
    - 更细节地，要求 deterministic（结果应该是确定性的）和 locality（局部调整不影响其它已经满意的区域），要求符合直觉（Deep Learning 可以掺一脚），要求对设计师友好（设计师可以方便、低门槛地自定义规则）

== Plugin Architecture
- *Double Dispatch*
  - 引擎设计时考虑的是 Mesh, Particle, Animation, Physical 等系统（横向），但 Plugin 可能还会考虑对某一类对象做功能（纵向）
  - 即，插件需要同时考虑引擎系统和对象两个维度，支持矩阵形数据访问。反过来有些 high level 的特殊功能最好不要内嵌在引擎系统里而是用 Plugin 的形式可供选用
    #fig("/public/assets/CG/GAMES104/2025-04-05-15-35-04.png", width: 60%)
- *Plugin 模型*
  + Covered: 新的插件能覆盖老的
  + Distributed: 不同插件各自执行，最后合并结果
  + Pipeline: 输入输出相连协作
  + Onion rings: 洋葱圈，插件之间相互依赖，读取另一个插件的处理后的结果作为输入，自己处理后的结果再传回去进一步修改
  - 四种模型都有广泛使用，引擎应当保持开放性。更宽泛意义上来说，软件工程师一边要考虑设计的严谨一致，又妥协于工程的复杂而允许不同 pattern 共存。应当秉持实用主义原则，以解决问题为优先
  #grid2(
    fig("/public/assets/CG/GAMES104/2025-04-05-15-41-04.png", width: 70%),
    fig("/public/assets/CG/GAMES104/2025-04-05-15-41-17.png", width: 50%),
    fig("/public/assets/CG/GAMES104/2025-04-05-15-41-25.png", width: 70%),
    fig("/public/assets/CG/GAMES104/2025-04-05-15-41-35.png", width: 70%)
  )
- *Version Control 版本控制*
  - 引擎更新版本、接口修改后可能会导致插件功能失效，因此在一开始设计接口时就考虑到这些问题
  - 不过这些问题对我们初学者而言就太过复杂了，没有 $10$ 年经验搞不定其中复杂度和丰富度。因此老师不认为程序员写了 $5 wave 10$ 年代码就应该做管理和架构（但事实是，$35$ 岁还没爬到这一层的就要 “毕业” 了，唉）

== Design Narrative Tools 设计叙事工具
现代游戏做的越来越像电影，Storytelling 就变得很重要（腹诽一句，感觉这个走向脱离了游戏的本质，很高兴老师的观点跟我一致）。

这方面 UE 里叫 Sequencer，Unity 里叫 Timeline，相当于电影导演的统筹安排，一个一个角色各自在不同的时间做不同的事，游戏中一些过场动画就是这样做的。很繁琐，但所有电影、游戏都是这样一点一点构建出来的。这个过程涉及到很多工具的实现，这里没有细讲。

Timeline 的过程中，工具是如何调整 Runtime 里各个对象某个 component 的 parameter 的？这就引出下面的话题 —— Reflection，可以说反射是 Timeline 的基石之一。

== Reflection and Gameplay
回忆一下，虽然我们有 schema，但它只是一个描述，我们需要的是绑定好的可以直接操作 (set, get) 的数据；另一方面，游戏中的 Gameplay 非常复杂多样，作为一个引擎不可能知道也不可能把它们写到引擎里面，并且也难以用数据配置做出所有的玩法（任何语言所能描述的东西都有上限）。

还有另一种可视化编程 (Visual Scripting System) 比如 UE 的蓝图 (Blueprint) 的需求，标志着低代码、低门槛编程的未来方向。我们不可能只是预设一系列节点，因此也向引擎提出了可扩展性的需求。

因此，引擎应该允许游戏团队基于现有的功能增加新的逻辑，然而逻辑增加需要接口、工具相应地更新，工作量非常大，那就需要反射 Reflection。

「反射允许程序在运行时检查、修改和操作其自身的结构和行为」，在如今高级语言基本都支持 (e.g. C\#, Java)。引擎实现功能后，工具可以通过知道有哪些开放类和接口可以访问，这时在蓝图中创建对象时，其接口参数全部可以展现。

早期用 C / C++ 编写的引擎为了实现类似反射的效果，用了很多 Tempalte 元编程的 hack，在反射这一概念提出后就成了无用功。那么现在 C++ 如何实现反射？C++ 代码在编译时会翻译成抽象语法树 (Abstract Syntax Tree, AST)，比如类就会被翻译成一个树状结构表，在这个表里就比较容易提取接口和参数。提取到相应数据内容后还需要自动生成操作代码 (Code Generation)，提出一个叫做 Code Rendering 的概念（多说一句，代码生成这个概念几乎没有缺点，不仅 bug 少，而且能更好地做到 code, data 的分离）。

== Collaborative Editing
协同编辑是引擎发展方向，只要 AGI 一天不到达，未来越来越复杂甚至倾向于开放世界的现代游戏就越来越需要多人协同编辑。但大量数据、不同版本如何协作？

- Conficts
  - 用 Git, SVN 等工具管理 Merge 冲突，但依旧要花许多时间
  - 如何尽可能避免冲突？Split Assets —— Layering / Dividing the World
  - Layering: 分层编辑，概念非常好，但很多时候层与层之间有相互依赖，不能分得很清楚
  - Dividing: 分块编辑，不仅更符合直觉，对 dynamically expand the world 支持也比较好；但有时候 asset 可能跨界，所以可能需要支持不规则划分
  - One File Per Actor (OFPA): UE5 新提出的概念，每个对象都创建一个文件，再也不会冲突。但问题也比较大，茫茫多的小文件不仅让版本控制系统提交变得很慢，也让分包时多一个迁移的步骤（学过 OS 都知道，操作系统最恨的就是小文件这种碎片内存）
- Coordinate Editing in One Scene
  - 不过，以上这种本地做完再提交、合并的方式只是协同编辑的初始形态，畅享真正的协同编辑：许多人同时在一个场景里编辑
  - 非常困难的问题在于时序上的控制、原子性操作、Undo/Redo、Operation Merge 等。这些问题结合起来更是复杂，比如操作 $A$ 和操作 $B$ 有时序依赖关系并最终合并出一个结果，但操作 $A$ 随后被 Undo 了，操作 $B$ 应该如何变化？最终结果应该怎么办？
  - 简单的处理办法：Instance lock, Asset lock。复杂的处理办法：Operation Transform (OT), Conflict-free Replicated Data Type (CRDT)。这里都没有详细展开
- Collaborative Editing Workflow
  - 所有的操作不要直接 apply 到最终结果，先发往 Collaborative Server 统一结算完再发回给大家并同步 Remote Storage
  - 付出的代价是一点点的延迟（但在局域网是可以接受的），好处是避免争议，因此被现代很多协同编辑系统所采用
  - 不过鲁棒性有限（Server 炸掉就全完了），因此这个系统还处在比较早期的阶段，是下一代游戏引擎的前沿方向之一