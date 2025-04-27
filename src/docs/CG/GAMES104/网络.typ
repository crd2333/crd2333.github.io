---
order: 8
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
#counter(heading).update(17)

= 网络游戏的架构基础
- 网络游戏和单机游戏相比有很多难点，比如
  + Consistency: 如何在保证每个玩家的游戏状态是一致的、如何进行网络同步
  + Reliability: 如何处理延迟、丢包和重连
  + Security: 如何反作弊、反账号篡改
  + Diversity: 如何处理不同的设备和系统，以及这么多设备系统的热更新
  + Complexity: 极高的 Concurrency, Availability 要求极高的 Performance

== Network Protocols 网络协议
=== 传统网络协议
网络协议要解决的核心问题是实现两台计算机之间的数据通信。随着软件应用和硬件连接变得越来越复杂，直接进行通信非常困难，因此人们提出了中间层 Intermediate Layer 的概念来隔绝掉应用和软件，让开发者专注于程序本身而不是具体通信过程。

在现代计算机网络中人们设计了 OSI 分层模型来对通信过程进行封装和抽象。一般来说我们只用在最上层的 Application 混一混就行了，如果对这七层协议了解的话，可以对其中冗余的地方进行底层优化。

- *Socket*
  - 网络游戏开发一般不需要很底层的通信协议，大多数情况知道如何使用 socket 建立连接即可
  - socket 是一个简单的结构体，只需要知道对方的 IP 和 Port 就可以
  - Setup socket 时，需要考虑 domain 是 IPv4 还是 IPv6，type 是 TCP 还是 UDP，protocol 一般是 $0$
  #align(center)[`int socket (int domain, int type, int protocol)`]
- *Transmission Control Protocol 传输控制协议*
  - TCP 是最经典也是著名的网络协议，它连接牢靠，可以按顺序接收，还可以进行流量控制（网络差时可以降低发包效率）
  - Retransmission Mechanisms: TCP 的核心原理。这个机制要求 Receiver 接受到消息后向 Sender 发送 Acknowledgment (ACK) 确认消息已经收到，Sender 收到后就可以继续发下一个包，否则反复发送
  - Congestion Control: TCP 会根据 loss 的数量主动调整 Congestion Window (CWND)，避免网络拥堵。这有效地保证了服务器不被堵死，但也导致 high delay 和 delay jitter（带宽一上一下，并且前置消息收不到后续的也都被卡住）
- *User Datagram Protocol 用户数据报协议*
  - UDP 的发明者也是 TCP 发明者之一，本质是一个轻量级的端到端协议，其特点是
    + Connectionless，不需要握手（长时间连接）
    + 不管 Flow Control 和 Congerstion Control
    + 不保证顺序和可靠性
  - 因为简单，所以开销小，包头只有 $8$ 字节（TCP 有 $20$ 字节）
- 现代网络游戏需要根据游戏类型不同来使用合适的网络协议
  + 对实时性要求高的游戏会优先选择 UDP
  + 策略类、时间不敏感的游戏则会考虑使用 TCP
  + 大型 MMO 游戏会使用复合类型，比如登录、聊天、邮件用 TCP，战斗用 UPD
  + 说是这么说，但其实一般会根据具体需求魔改出 Reliable UDP，或者用第三方库

=== Reliable UDP
- TCP 复杂又笨重，UDP 轻量但不可靠，有没有办法结合二者优势呢？有的兄弟，有的。现代网络游戏往往会基于 UDP 定制网络协议，采用第三方协议或完全自定义
- 我们想要什么？Game Server 应该做到
  + 链接保活 (TCP)
  + 一定的逻辑顺序 (TCP)
  + 快速响应低延迟 (UDP)
  + 支持广播 (UDP)
- *一些概念*
  - Positive acknowledgment (ACK) & Negative ACK (NACK or NAK): 确认某一信息收到或没收到
  - Sequence Number (SEQ): 序列号，TCP 中的重要概念，标记主机发出的每个包
  - Timeouts: 超时时间，时间过长就不管它
- *Automatic Repeat Request 自动重传请求*
  - ARQ 是基于 ACK 的错误控制方法，所有通信算法都要实现 ARQ 功能，一个常见的方法是使用 *Sliding Window Protocol 滑动窗口协议*
  - 滑动窗口协议按 SEQ 的顺序发包，每次发送 `window_size` 个，等待 ACK，接受多少滑动多少。分几种策略
    + Stop-and-Wait ARQ: `window_size = 1`，每次只发一个包，等待 ACK 后再发下一个包，太笨了没人用
    + Go-Back-N ARQ: 没接收到 ACK 时，会回头把包含那个包的整个窗口都重发
    + Selective Repeat ARQ: 只重发没有收到 ACK 的包 (NARK)，效率高但实现复杂
- *Forward Error Correction (FEC)*
  - UDP 不保证可靠性，需要引擎自行考虑，我们在自定义网络协议时一般会结合 FEC 方法让丢包数据也能自动恢复，避免反复发送，一般属于空间换时间
  + XOR FEC 异或校验位: 使用异或运算恢复丢失的那一个包（如果多个包丢失则无效）
  + Reed-Solomon Codes: 利用 Vandemode 范德蒙矩阵及其逆矩阵来恢复丢失的数据，可以覆盖丢包率高的场景

== Clock Synchronization 时钟同步
就好像相对论，每个人接受到的时间都是局部的，需要进行同步。

- *Round Trip Time (RTT)*
  - 客户端向服务器端发送一个包后都需要等待网络通信延迟导致的一定时间才能收到回包，这个间隔的时间称为 RTT
  - 类似于 ping 的概念，区别在于 ping 更偏底层，而 RTT 一般是应用层自己写的
  - 跟 latency 的区别在于，latency 是发出端到接受端的单向时间，而 RTT 是双向的
- *Network Time Protocol (NTP)*
  - 时间同步其实是一个 well-studied 问题。一般会设定一个 Reference clock，要求极度精确（比如原子钟），使用无线电或光纤而不是网络来传输（因为网络延迟不稳定），然后通过 Time Server Stratums 的概念一层层同步
  - 游戏中一般不会有多层，Server 作为 Reference Clock，Client 通过网络与其同步即可，具体而言：
    + Client 在 $t_1^c$ 向 Server 发送消息，Server 在 $t_2^s$ 收到消息，随后又在 $t_3^s$ 发送回包，Client 在 $t_4^c$ 收到回包
    + NTP 假设网络上行下行延迟相（做了个平均）且没有波动，算出时间偏差为
      $ t_"offset" = frac((t_2^s - t_1^c) + (t_3^s - t_4^c), 2) $
    + Client 本地的时间通过 offset 来校正
      $ t_"corrected" = t^c + t_"offset" $
  - 实践中往往通过多次 NTP 得到一系列 RTT 值，把高于平均值 $50%$ 的部分丢弃（波动、不可靠），剩下的平均值的 $1.5$ 倍用作真实 RTT 的估计

== Remote Procedure Call (RPC) 远程过程调用
- 利用 socket 可以实现客户端、服务端通信，但完全基于 socket 的通信非常复杂，因为
  + 网络游戏中客户端、服务端要发送大量不同类型的消息和相应反馈，都要打包成对应网络协议，导致游戏逻辑无比复杂
  + 客户端和服务器有不同的硬件和操作系统，它们的语言、数据类型大小、大小端、数据对其要求可能都不一样
  - 因此现代网络游戏一般会使用 RPC 方式实现通信，在客户端可以像本地调用函数的方式来向服务器发送请求（复杂度解耦），使开发人员可以专注于游戏逻辑而不是具体网络协议实现
- *RPC*
  - Interface Definition Language 界面定义语言：跟之前在工具链讲过的 Schema 是共通的概念，例如 Google ProtoBuf 等
  - RPC stubs：在启动时，Stub Compiler 编译 IDL，Server / Client 端的程序员实现自己侧的逻辑并链接到自己侧的 stubs，明确双方有哪些 RPC 可以调用，如果调用的 RPC 不存在就返回报错但不会让程序 crash
  - Real RPC Package Journey: 真实游戏中的 RPC 在实际进行调用时还有很多的消息处理、压缩解压缩和加密工作

== Network Topology 网络拓扑
设计网络游戏时还需要考虑网络自身的架构。

- *Original Peer-to-Peer (P2P)*
  - 每个客户端之间直接建立通信，任何一个客户端的时间需要 broadcast 到所有其他客户端
  - 现在用的较少，一般用于双人点对点游戏，或者比较抠 or 穷没有服务端的游戏
- *P2P with Host Server*
  - 当 P2P 需要集中所有玩家的信息时，选择其中一个客户端作为主机，其它客户端通过连接主机实现联机
  - 主机的处理性能、网络质量很影响所有人的体验，现在很多需要房主开房、开服的游戏都是这个模式
- *Dedicated Server 专用服务器*
  - 现代的大型商业网络游戏必须使用专用服务器，从而能够同步所有玩家的状态
  - 为了满足不同网络条件的玩家的需求，运营商可能还需要自己建立网络线路（一般直接走光缆专线）

== Game Synchronization 游戏同步
即使我们已经做了时钟同步，但由于延迟客观存在，不同玩家视角下的对方可能有不同的行为表现，需要有游戏同步技术来保证玩家体验的一致性。目前常用的同步技术有 Snapshot 快照同步、 Lockstep 帧同步（锁步同步）和 State Synchronization 状态同步。

=== Snapshot Synchronization 快照同步
- *Snapshot Synchronization*
  - 客户端只负责发送输入到服务端，其它所有逻辑都在服务端处理。服务端把整个游戏的状态生成为一个快照，再发送给每个客户端给玩家反馈
- *Snapshot Interpolation*
  - 快照同步在 Performance, Bandwidth 方面均给服务器提出了非常巨大的挑战，导致 Jitter and Hitches
  - 实际游戏中一般会降低服务器上游戏运行的帧率，在客户端上通过插值的方式提高帧率 (Keep an interpolation buffer)
- *Delta Compression*
  - 每次生成快照的成本相对较高，为了压缩数据可以使用状态的变化量来对游戏状态进行表示
- *总结*
  - 优点：非常简单也易于实现
  - 缺点：基本浪费客户端算力，同时在服务器上产生过大的压力
  - 现代网络游戏基本不会使用

=== Lockstep Synchronization 帧同步
- Lockstep Origin and in Online Game
  - Lockstep 最初来源于军队的步伐同步，在 same time 做出 same action，拓宽到游戏上，类似于把世界变成回合制
  - 很明显，所有生成的事件都按照相同的唯一顺序交付是确保不同节点之间游戏状态一致性的充分条件
  - 在帧同步中，服务器更多地是完成数据的分发工作 (dipatch)，其宗旨为
    $ "Same Input" + "Same Execution Process" = "Same State" $
- *Lockstep Initialization*
  - 使用帧同步时首先需要初始化，将客户端上所有游戏数据与服务器同步，一般在游戏的 loading 阶段完成
- *Deterministic Lockstep*
  - 所有客户端在每一轮将玩家数据各自发送到服务器上，服务器接收到所有数据后再统一转发给客户端，然后由客户端执行游戏逻辑，整个过程公平而确定
  - 当然其缺陷也很明显，游戏进程取决于最慢的用户。当某一玩家滞后甚至掉线，所有玩家都得等待，并且这种延迟是不固定的。这种情况在早期联网游戏中很常见
- *Bucket Synchronization*
  - 对原始 Lockstep 进行一定改进，服务器只等待 bucket 长度的时间，如果超时没有收到就直接跳过，看下一个 bucket 能否收到
    - 弹幕：LOL 会给没有收到的玩家赋予默认操作走回泉水
    - 网络游戏设计中一般有两种策略：网络差者获利与网络好者获利，前者可能导致可以通过拔网线等方式争取更多的反应、决策时间（例如《马里奥制造》）。Bucket Synchronization 可以算是后者
  - Bucket Synchronization 本质是对玩家数据的一致性以及游戏体验进行的一种权衡
- *Deterministic Difficulties*
  - 帧同步的一大难点在于要保证不同客户端上游戏世界在相同输入下有完全一致的输出。否则，一整局游戏只有最开始的同步，在后续不断的演化下极易产生蝴蝶效应
  - 在物理引擎部分我们描述过这一概念的难点，在不同客户端上要保证
    + 浮点数一致性：使用 IEEE 754 标准表达，但不同平台上行为可能不同，一种方法是使用 Floating Point Numbers，但应用并不广泛
    + 随机数一致性：使用相同的种子和伪随机数生成算法
    + 各种容器和算法的一致性：挑选确定性的容器和算法
    + 数学运算函数一致性：查表法，把 $sin, cos$ 等的结果定死
    + 物理模拟一致性：很难
    + 代码逻辑执行顺序一致性
  - 完全确定性的保证几乎不可能，好消息是，只用把核心的业务逻辑如角色移动、伤害、血量等影响结算的游戏状态做成确定性的，如渲染等可以不确定
- *Tracing and Debugging*
  - 现代网络游戏的逻辑十分复杂，可能无法避免地出现一些 bug，引擎需要为上面的应用层提供追踪功能
  - 一般我们要求客户端定时记录游戏状态，例如使用 checksum 技术存储数据，又如把所有关键函数的 core, parameter 变成哈希值存下来，每隔一定时间上传本地 log。服务器自动比较 logs，定位哪一帧、哪一步运算出了 bug
- *Lag and Delay*
  - 帧同步并没有真正解决延迟和抖动问题。对抖动问题，可以通过在客户端上用 buffer 缓存若干帧来解决（类似视频网站缓存），当然缓存帧越大延迟越高
  - 另一方面可以把游戏逻辑帧和渲染帧分离（一般渲染帧数会更高），客户端通过对渲染帧插值的方式获得平滑效果
    - 逻辑、渲染的解耦使画面不会因为网络原因出现抖动，同时也可以结合之前说过的垂直同步 V-Sync 来避免撕裂现象，另外对后面的断线重连也有一定好处
  - 更进一步，甚至对动作都可以进行插值，以及评论区提到客户端可以对用户输入进行一定预测（类似后面状态同步的做法）
- *Reconnection Problem*
  - 帧同步时，客户端每隔若干帧会设置一个关键帧，更新游戏世界的快照，保证即使游戏崩溃了也可以从快照中恢复。服务器端也可以保存快照，当客户端断线过久时采用服务器端快照恢复
  - quick catch up: 为了从关键帧快照追赶队友的当前帧（追帧），暂停关闭渲染，全力执行游戏逻辑，每秒能追很多倍
  - Observing: 服务器端保存快照的另一个作用是实现观战和回放功能，它们的实现机制跟断线重连是一致的
- *Lockstep Cheating Issues*
  - 帧同步中，玩家可以通过发送虚假的状态来实现作弊行为，因此要有反作弊机制
  - 对于多人游戏，可以使用投票机制，所有玩家都会发送校验码 checksum，找出哪个玩家进行作弊
  - 对于双人游戏，单个玩家无法确定作弊，服务器端也必须保存校验码，如果服务器没法验证就无计可施（当然，双人情形作弊只有一个玩家收到损害，相对不严重，而且一般双人游戏用 P2P 实现即可）
  - 但帧同步的机制本来就是客户端上存储了所有的游戏信息，因此还是容易出现通过作弊破解 “战争迷雾” 而得到全局信息，而这是校验码无法避免的。现在的帧同步游戏会用很多方法、策略来规避这个问题
- *Lockstep Summary*
  - 优点
    + 占用带宽少，适合需要实时反馈的游戏
    + 解决 determinism 问题后开发效率高，类似单机游戏
    + 适合对打击操作敏感的游戏（状态同步）
    + 方便做观战、录像、回放
  - 缺点
    + 一致性很难保持
    + 全图挂难以解决
    + 断线重连机制设计得不好会导致需要很长时间恢复

=== State Synchronization 状态同步
状态同步是目前大型网游（比如 MMORPG）非常流行的同步技术。

- *State*
  - 帧同步的基本思想是每个客户端提交和服务端发放都只针对部分状态，即为了表示游戏世界所必要的量 (e.g. HP, MP)
  - 如果游戏世界太过复杂，可以设置 Area Of Interest (AOI) 来减少同步数据
- *Server Authorizes the Game World*
  - 状态同步跟快照同步、帧同步很大的不同在于，服务端在收到所有玩家数据后会运行游戏逻辑，模拟一整个游戏世界，然后把下一时刻的状态按需分发给用户（放作弊能力稍强一些），客户端接受状态并模拟本地的游戏世界
- *Authorized and Replicated Clients*
  - 状态同步中，服务器称为 authorized server，是整个游戏世界的绝对权威；玩家的本地客户端称为 authorized client，是玩家操作游戏角色的接口；在其他玩家视角下的同一角色则称为 replicated client，仅仅是 authorized client 的一个副本
- *State Synchronization Example*
  - 以一个射击游戏击中敌方的过程为例
  + 玩家 A (Authorized) 在本地按下开火键，将这一行为发送给 Server
  + Server 收到信息后，将玩家 A 的开火行为广播给所有玩家 A, B, C, D
  + 玩家 A 收到 Server 端确认后才开火；玩家 B, C, D 视野中的玩家 A (replicated) 也会开火（本地模拟），但并不负责击中效果的结算
  + 同一时刻 Server 端模拟玩家 A 的开火行为，结算并判定其击中玩家 B，发生扣血、爆炸等事件，并广播给所有玩家
  - 可以看到，状态同步非常大的一个好处在于它不要求各个 Client 的模拟是 deterministic 的，结算由 Server 来完成，整个游戏世界本质上是由统一的服务器驱动；另外，它可以只同步部分发生变化的状态以及各个玩家可见的状态，节省带宽
- *Dumb Client Problem*
  - 游戏角色的所有行为都要经过服务器确认才能执行，client 的操作总是会有一定滞后
  - 要缓解该问题可以在 client 端对玩家的行为进行预测。比如当角色需要移动时，首先在本地移动半步 (Client-side prediction)，等到服务器确认可以移动后再进行对齐 (reconciliation)
  - Client-side prediction: client 总是领先于 server half RTT 程度的动作，即时响应输入并维护一个 buffered command frame (Ring buffer)
  - Reconciliation: 来自 server 端的消息跟 buffer 中 half RTT 前的消息对比，如果不一致就以 server 为准，退回到该状态并 replay buffer 中的后续操作
  - 这个机制是典型的网络差者不利，他们的角色状态会不断地被服务器修正（例如 Apex 的闪回、吞子弹，网络差到一定地步连路都走不动）
- *Packet Loss*
  - 对于丢包的问题，状态同步方法可以在 server 端为每个 client 维护一个 tiny input buffer
  - 如果发生丢包（server 端一定时间内没有收到信息，表现为 run out of buffer），server 会 duplicate 最后一个输入
- *帧同步和状态同步两种主流同步技术的对比*
  #csvtbl(
    ```
    , Lockstep Synchronization, State Synchronization
    Deterministic Logic, 必要, 不必要
    Response, Poor, Better
    Network Traffic, 通常低, 通常高
    Development Efficiency, 开发容易，调试困难, 复杂得多
    Number of Players, 支持少量玩家, 支持大量玩家
    Cross Platform, 相对困难, 相对容易
    Reconnection, 相对困难, 相对容易
    Replay File Size, 小, 大
    Cheat, 相对容易, 相对困难
    ```
  )
  - 一般来说，帧同步比较适合网络较好、特定类型的游戏，状态同步比较适合网络不稳、游戏业务复杂、玩家数量多的大型游戏
  - 目前商业引擎做状态同步比较多（缺省行为），而帧同步则需要游戏团队做额外修改、加 hardcode

= 网络游戏的进阶架构
== Character Movement Replication 角色移动复制
角色 A 的行为到 server 端产生了一定延迟和抖动，到另一个角色 B 的视角下延迟和抖动更大。这个问题在前面部分实际上已经部分讨论，在 Lockstep 中我们针对抖动问题，说把游戏逻辑和渲染分开，对渲染帧进行插值来平滑动画效果；在 State Synchronization 中我们说可以对玩家的自己行为进行预测和修正。这一 part 就是单独把这个问题拉出来再讨论。

- *Interpolation*
  - 在两个已知点之间进行插值，得到中间的点，需要建立一个 buffer 存储用于插值的点。另外一个细节在于，Interpolation 要求对信息做进一步的 deferred render，避免要插值时下一个点还没到，换句话说需要额外增加人为延迟
  - 插值还有一个潜在问题是可能平滑掉高频信息（如果角色确实是走走停停的话），不过一般来说人眼倾向于连续动作，并不那么 care 这个问题
  - Interpolation 带来的延迟加上本身就有的延迟，在高速运动游戏中很有可能导致两方的本地逻辑判断不一致（PPT 中红车认为自己撞到了，灰车认为没有的例子），这就需要预测，引出 Extrapolation
- *Extrapolation*
  - 既然每个 client 都清楚自己接收到的 replica 数据存在延迟（且能做一定数值估计），那么就可以通过速度、加速度等信息预测其未来的状态
  - *Dead Reckoning* 航位推算：航空领域的一个专有名词，指的是通过出发位置、空速管测量的相对空气速度、空气的方向和速度来推算飞向原目标位置的应该用的方向和速度（对抗风的干扰）。对应到游戏引擎的概念，就是解决一个追赶问题 —— 我已知延迟存在的情况下如何追赶对方（不能直愣愣朝着对方走，而应该有一定预判），这里涉及到大名鼎鼎的算法 Projective Velocity Blending (PVB)
  - *Projective Velocity Blending (PVB)*
    #fig("/public/assets/CG/GAMES104/2025-04-08-23-19-26.png", width: 50%)
    - 假设当前 replica 位置在 $p_0$，在 blend 的时间点 $t_B$ 时，如果不做调整会在当前速度、加速度作用下沿#redt[红线]走到 $p_t|_(t=t_B)$；而 server 端发来的 $t_0$ 时刻准确位置在 $p'_0$，同时也接收到速度 $v'_0$、加速度 $a'_0$，准确位置应该沿#text(fill: green, [绿线])走到 $p'_t|_(t=t_B)$
    - PVB 的做法就是对速度进行一个线性插值，让真实坐标沿着#bluet[蓝线]转移
      $
      la = frac(t-t_0, t_B-t_0) \
      v_t = v_0 + la (v'_0 - v_0) \
      p_t = p_0 + v_t t + 1/2 a'_0 t^2 => p_d = p_t + la(p'_t - p_t)
      $
    - 并不是一个基于物理的解决方案，但好处在于，不会看到角色的位置瞬间变化，而是逐步追上目标点位置
    - PVB 还有很多变种和小 trick 解决边界情况，这里了解它的核心思想即可。当然实际上用 PVB 来解 Dead Reckoning 问题时，在插值过程中会不断发来新的包，因此永远是一个动态追赶的过程
  - *Collision Issues*
    - 当双方都在进行 Extrapolation 时，可能出现 collision weird 的情况，其原因是虽然我自己预测出已经撞到停下了，但对方 replica 根据上一 snapshot 进行 extrapolation 会继续前进，导致两辆车嵌入对方而不是一触即离
    - 再结合一些物理引擎会给嵌在一起的物体施加巨大的力，导致两辆车可能只是轻轻碰撞却飞得很远的问题
    - *Physics Simualtion Blending During Collision*
      - 这个问题非常复杂，一种解决思想是在客户端提前进行物理检测，如果发生碰撞就把控制位置同步的权利从 Dead Reckoning 转移到物理引擎上，过一段时间后再逐步转回去（相当于权利移交给预碰撞）
      - 但这又严重依赖于物理引擎的 determinism。有的算法会把预测到要相撞后的一段时间 (e.g. $100ms$) 内玩家输入关闭，把位置同步全部交给插值，让双方同步（没太懂为什么关闭输入就能同步。。。）
- *总结*
  - 单机游戏做得再酷炫，要真正在网络游戏中也实现甚至进一步与 GamePlay 相结合，是一个设计上十分挑战的问题
  - Interpolation 的应用场景
    + 玩家经常以很大的加速度移动（这里有一个反直觉的常识，controller 的加速度一般会比车辆的加速度大很多，因为是为了手感而反物理操控）
    + GamePlay 受 extrapolation 的 wrap 问题影响严重（因为外插是预测，有时候容易卡到不希望的状态）
    + 更具体的例如 FPS, MOBA 游戏等
  - Extrapolation 的应用场景
    + Player 以符合物理规律的方式移动（预测更准）
    + GamePlay 受网络延迟影响严重
    + 更具体的例如赛车游戏、载具游戏等
  - 结合 Interpolation 和 Extrapolation 的应用场景
    - 角色移动用内插，上了载具之后用外插
    - 当网络波动，没有足够数据接受到时用外插

== Hit Registration 命中判定
- 射击游戏里，在玩家的视角射中敌人爆头显得十分自然，但在真实情况里是一个非常复杂、漫长的过程：
  +  敌方进入视野；
  + 经过 half RTT 传到 server 并被 buffer 后再处理；
  + server 端经过 half RTT 传到 client，又要经过 buffer、插值；
  + client 端玩家反应过来开枪；
  + 开枪信号又要经过 half RTT 传到 server 进行结算
  - 需要尝试解决的问题：Where is the Enemy? Where Should I Shot?
  - 实际上 Hit Registration 这一问题没有 ground truth，最重要的是达成一个共识，一般有两种流派
    + Client-side Hit Detection
    + Server-side Hit Registration
- *Client-side Hit Detection*
  - 使用 replicated 角色位置检测客户端上的命中事件，将命中事件发送到 server 端，server 端进行简单验证 (verification)
    - server 端做的验证包括但不限于：
      + StartPoint 不能跟 shooter 差太远
      + HitPoint 跟 HitObject 也不能差太远
      + 从 StartPoint 到 HitPoint 的 RayCast 之间不应该有障碍
    - 但真实情况下，就算是相对简单的 Client-side Hit Detection，server verification 也会很 tricky and complicated
  - 非常适合于 PUBG 这种大地图 + 多人在线的游戏，以及 Battlefield 3 这种破坏和载具系统丰富的游戏
  - 其好处是：1. 非常高效，对 server 端压力较小，可以模拟 hitscan, projectile, projectile + gravity 等不同弹道类型；2. 非常符合玩家直觉、射击手感好
  - 其坏处是 server 端轻信 client 端结果，容易导致作弊 (e.g. fake hit event message, lag switches, infinite ammo...)
- *Server-side Hit Registration*
  - server 端验证最大的问题在于 client 不知道敌人的准确位置，如果严格遵守真实情况则永远打不中，为此需要引入延迟补偿 Lag Compensation 机制
  - *Lag Compensation*
    - 一句话理解就是状态回溯，server 端保存一系列快照，处理命中事件往回拨一段时间，在当时的快照进行验证
    - 由于运行的是同一个游戏，server 端、client 端 ticking 的周期和 interpolation 所用算法均已知，假设网络波动不明显，server 端对各个 client 往回拨的时间可以有相对准确的估计
    $ "RewindTime" = "Current Server Time" - "Packet Latency" - "Client View Interpolation Offset" $
  - Cover Problems
    - Running into Cover：虽然我已经躲进掩体，但 server 端以开枪人视角为准，我可能还是会暴毙 (Shooter's Advantage)
    - Coming out from Cover：我从掩体出来，对方眼中我还在掩体因此发现不了，而我能先手发现对方并开枪 (Peeker's Advantage)
    - 鉴于这种种问题，此类游戏往往采用局域网把延迟尽量降低，同时把 tick rate 尽量调高，以求对双方都公平
- *一些 hack*
  - Startup Frames to Ease Latency Feeling
    - 给各种动作加上几帧的前摇，让用户专注于动画而不是延迟，从而为网络同步争取宝贵的时间
  - Local Forecast VFX Impacts
    - 击中特效、声效 (instant feedback) 可以在 client 端提前播放，server 端确认后再进行对齐 (permanent effects)。这也是经典头上冒火星不掉血的由来

== MMOG Network Architecture 大型多人在线游戏网络架构
MMOG: Massively Multiplayer Online Game，大型多人在线游戏，或者一般叫 MMO。很多人一提到 MMO 就想到 MMORPG，实际上还有 MMOFPS 等。各种游戏类型做大、做联网之后都能叫 MMO。并且现在的 MMO 有不局限于某一类型，而是构建虚拟小世界（元宇宙雏形）的趋势。

- *Game Sub-Systems*
  - 从 GamePlay 的角度，可以把游戏分成这些子系统
    + User management
    + Matchmaking
    + Trading system
    + Social system
    + Data storage
    + ...
- *MMO Architecture*
  - 从架构角度，可以把游戏分成这些层
  #fig("/public/assets/CG/GAMES104/2025-04-11-14-13-30.png", width: 60%)
  + Players
  + Link Layer
    - MMO 的 server 非常复杂，需要保护起来，用户首先跟 Login Server 建立连接（链接、握手、账号验证）
    - Gateway: 把服务器的内外网隔绝开，类似于一个防火墙，进行加密、解密、压缩等
  + Business Layer
    - Lobby Server: 大厅可以认为是一种特殊的游戏模式，作为一个等待 MatchMaking 的缓冲池
    - Character Server: 角色服务器，存储玩家的角色信息、物品信息等
    - Trading System: 交易系统需要保证绝对的原子性与安全性
    - Social System: 社交系统，负责玩家之间的交互等，有时还专门把 chat, mail servers 分开
    - MatchMaking: 把拥有不同等级、实力、延迟等属性的玩家匹配在一起
  + Data Layer
    - 游戏数据复杂而多样，包括 player data（公会、地下城、仓库等）, monitoring data, mining data 等，需要持久安全地保存，并且高效地组织用于 retrieve and analysis
    - 数据库一般分为三种
      + Relational Data Storage: 关系型数据库，适合存储结构化数据，e.g. MySQL
      + Non-Relational Data Storage: 游戏中有一些不需要严格按照关系进行存储、查询的数据（关系型数据库存储负载较重），比如 Log Data, Game States, Quest Data……非关系数据库在这种情况下更轻量、更高效，e.g. MongoDB
      + In-Memory Data Storage: MMOG 几百个 server 产生大量的中间数据，如果读写磁盘就太慢，需要用内存数据库来管理
- *Distributed System*
  - 随着游戏人数的上涨，服务器的负载也越来越重，一般会采用分布式架构
    - 分布式系统是一种计算环境，其中各种组件分布在网络上的多台计算机上
    - 比如数据同时写到多个数据库中，读写的效率更高且安全性更高，还有冷热表、灾难备份等概念
  - *Challenges with Distributed systems*
    + Data access mutual exclusion: 不同 services 的访问不会互相冲突构成死锁
    + Idempotence: 访问同一数据多次（消息冗余发来）不会产生不同的结果
    + Failure and partial failure: 部分服务宕机不会影响其他服务的正常运行
    + Unreliable network: 对不可靠网络的容忍能力
    + Distributed bugs spread epidemically: 避免分布式 bug 在不同 server 之间传播、震荡甚至放大
    + Consistency and consensus: 各个业务产生的结果必须一致
    + Distributed transaction: 事务处理
- *Load Balancing*
  - 有了分布式系统就可以解决上面说的游戏人数上涨问题，负载均衡是分布式系统中最重要的一个问题
  - 我们首先来思考*负载均衡的困难性*，以用于玩家信息管理的 character server 为例
    + 玩家数量动态变化，新玩家注册、老玩家注销，没有办法划分某一段玩家 ID 由某一个 server 负责
    + 服务器数量动态变化，server 宕机、增加、减少等，没有办法按玩家 ID 的余数划分
  - 类似问题非常多，一个很经典的解决方法叫做*一致性哈希 Consistent Hashing*
    - 对 Player ID 和 Server IP / Port 分别设计 hash 函数，映射到 $[0, 2^32- 1]$ 的空间上（一个 $32bit$ integer 的空间），形成一个环形
    - 定义规则，比如逆时针规则：每个 Player ID 按逆时针寻找最近的 Server 负责。当某个 server 挂掉或是增加时，在圆环中插入，根据规则会有部分 Player ID 需要重新分配；Player ID 的增删也是同理
    - 从而我们把复杂问题简单化 —— 动态变化的问题转化为两个 hash 函数分布的均匀性问题；并且只要两个 hash 函数定下来，也不再需要任何 rpc query 来显式调整负载
    - *Virtual Server Nodes*: 对 hash 函数的优化，增加虚拟节点，虚拟节点再映射回真实节点，增加 hash 函数的均匀性
- *Servers Management*
  - 承接上面，分布式系统的巨量服务会不断宕机、增加、减少，如何管理这些 services 是一个很大的问题；另外，MMO 游戏中各种服务的依赖关系错综复杂也给管理带来了困难
  - 对这一概念，分布式系统里更专业的术语叫 *Service Discovery 服务发现*
    + 每个服务向 Service Discovery System 注册 (Register) 自己的信息 (e.g. Apache ZooKeeper, etcd)
      #align(center, [server type/server_name\@server_ip:port])
    + 随后当应用层 request 某个服务时，Gateway 对 Service Discovery System 进行 query，得到相应的服务并进行负载均衡处理
    + 当服务有什么变动，Service Discovery System 会 watch 到并通知 Gateway（观察者）
    #fig("/public/assets/CG/GAMES104/2025-04-11-21-42-26.png", width: 80%)

== Bandwidth Optimization 带宽优化
- *带宽为什么重要？*
  + 基于使用的计费，例如手机流量、云服务，与成本息息相关
  + 带宽大了延迟也大，容易出现拥塞
  + 网关为了平衡可能主动掐断 message overflow 的连接
- *计算带宽*
  - 影响因素
    + 玩家数量 player numbers: $n$
    + 更新频率 update frequency: $f$
    + 更新的游戏状态数量（包体大小）size of game state: $s$
  - 每秒传输数据
    + Server: $O(n dot s dot f)$
    + Client (downstream): $O(s dot f)$
    + Client (upstream): $O(f)$
  - 带宽优化就是分别优化这三项影响因素
- *Data Compression 数据压缩*
  - 浮点数表示的 position, rotation, speed 等，如果用 vector3，可以考虑是否能把 y 轴弃用；此外考虑是否能用低精度浮点表示，或者转化为定点数 $->$ 可以称得上是网络游戏数据压缩中最重要的算法，大大减小 size of game state $s$
  - 由于角色的移速限制，往往只会在一块小区域内活动，可以对地图进行分区从而降低浮点数精度
- *Object Relevance 对象相关性*
  - 只传输跟玩家相关的对象，大大减小 size of game state $s$
  - Static Zones: 对非开放世界，采用静态区域划分，只传输玩家所在区域内的对象
  - *Area of Interest (AOI)*
    - 感兴趣区域，超出这一范围就不可见、不可交互，也就不传输
    - Direct Range-Query: 直接暴力查询，遍历每个对象计算距离，确定是否在范围内。对每个玩家对象都计算一遍，复杂度为 $O(n^2)$
    - Spatial-Grid
      - 把空间划分成格子，玩家周围格子内的对象划入 AOI
      - 玩家的 AOI 可以被 cache 成 list，enter / leave 格子时更新
      - 好处是时间复杂度为 $O(1)$，坏处是额外的内存开销（空间换时间），且性能跟 Grid Size 强相关，另外无法处理 varying AOI 的情况
    - Orthogonal Linked-list
      - 类似碰撞检测时说的 sweep and prune（Sort and Sweep 做粗筛），把物体按 x, y 轴建立链表并分别遍历做 range query，取其交集；当然对象移动时需要做更新
      - 好处是内存友好、支持 varying AOI，坏处是插入对象的时间复杂度为 $O(n)$，且不适合对象频繁大距离移动的情况
    - Potentially Visible Set (PVS): 预计算可见性集，每次更新时只需要查表加入附近区域的对象即可，适合 e.g. 高速移动的赛车游戏
- *Varying Update Frequency by Player Position*
  - 一般而言只有离玩家近的对象才能进行交互，为此根据距离对更新频率做衰减
  - 减小 update frequency $f$

== Anti-Cheat 反作弊
- 作弊方式多种多样
  + 修改游戏代码：修改、读取内存数据，破解客户端等
  + 系统软件调用：重载 D3D Render Hook（底层的绘制 SDK，比如画三角形变成画线框），模拟鼠标和键盘操作等
  + 网络数据包拦截：发送假包、修改包数据等
- *Executable Packers & Obfuscating Memory*
  - 外挂可能获取玩家坐标在内存中的位置用于穿墙、获取玩家血量用于锁血等，甚至利用这些值的位置在内存中找出更大的数据结构的位置，比如玩家对象本身。这一问题在采用帧同步、客户端验证的游戏中尤甚
  - 可以给*客户端加壳 (Executable Packer)*，把它加密包起来，在游戏运行时实时解密使 exe 得以运行
  - 还有一种方法是*内存混淆 (Obfuscating Memory)*，把高度敏感的数据在内存中加密，在使用的瞬间进行解密
- *Verifying Local Files by Hashing*
  - 外挂可能替换游戏文件例如材质，从而使敌人变得更明显、使墙壁变透明等
  - 通过不停对游戏文件计算 hash 并上传服务器，验证文件完整性，避免文件被篡改
- *Packet Interception and Manipulation*
  - 作弊者可能会拦截、修改数据包，甚至伪造数据包发送给服务器。对此服务器一般难以检测，用额外的检测机制又提高了负载
  - 一般的方法是对网络包进行加密，最核心的有两种算法：
    + *Symmetric-key algorithm 对称加密算法*
      - 发送方和接收方使用同一个密钥进行加密和解密
      - 快速且效率，但密钥的分发和管理是一个问题
    + *Asymmetric encryption 非对称加密算法*
      - 客户端和服务端使用不同的密钥，客户端的公钥被破解了无伤大雅，没有私钥无法打开数据
      - 例如 SSL，安全但是慢，一般只用于加密重要数据且尽量少用
      - 具体应用时，在登录时用 Asymmetric encryption 建立私钥公钥对，只用这一次建立一个安全的网络连接；之后用其加密方法传递 Symmetric-key，用对称加密算法进行具体数据的传输；不断更新该 Symmetric-key 使其被破解也没关系（只影响这一次传输）
      #fig("/public/assets/CG/GAMES104/2025-04-11-23-35-18.png", width: 40%)
  - 现代网络游戏中对加密问题非常重视（基本是刚需），一般会做成引擎底层功能提供服务
- *System Software Invoke*
  - 外挂可能通过钩子勾到引擎里去，注入代码
  - 一些反作弊软件如 VAC, Easy Anti-Cheat（小蓝熊）等会扫描内存中游戏的签名，监控系统调用，检测是否有异常的调用；以及对一些可疑的应用程序、外挂做报警
- *AI Cheat*
  - 以上方法或多或少都有解决的办法，但 AI 作弊作为一种新兴的作弊方式，可能会对游戏造成很大的影响，目前还没有成熟的解决方案
  - AI Cheat 一般全平台通用、不需要修改游戏文件、独立于游戏运行。比如把 YOLO 用到枪战游戏，直接在屏幕空间进行目标检测，移动鼠标并开火，很难检测且门槛越来越低
- *Statistic-Bases System*
  - 基于大数据、深度学习识别出玩家行为的异常 pattern，跟 AI Cheat 属于道高一尺、魔高一丈的比拼关系，用 AI 打败 AI，还处在早期阶段
  - 还有一些游戏如 CSGO 会把超出统计数据的对局录像，交由人类审核 (overwatch)，判断是否作弊（不太可取）
- *Detecting Known Cheat Program*
  - 一般用作牟利的外挂总会有一些特征可供记录，通过对比已知的外挂程序，进行检测
  - 对商业型外挂效果较好

#q[反外挂是长期战、持久战。]

== Build a Scalable World
如何构建可扩展的游戏服务器 (Scalable Game Servers)？

#grid(
  columns: (65%, 35%),
  column-gutter: 4pt,
  [
    + *Zoning*
      - 把游戏世界划分成多个区域（对世界的横向空间划分），每个区域由一个 server 负责
      - 分布可能不均匀，可以采用四叉树划分等方式，进行动态的区域划分
      - 如何让玩家感受不到区域切换 (seamless) 是一个挑战
        - 给 Zone Border 设置宽度 ($>=$ max AOI radius)，在这个宽度内做特殊处理
          - 例如 Active Entity $A$ 处在 Zone $A$ 和 Zone $B$ 的 Border 中，归属于 Zone $A$ 管理。Zone $B$ 中也有一个 Entity $B$，虽然它的逻辑、行为归属于 Zone $B$，但在 Zone $A$ 中创建一个 ghost 显示给 Entity $A$
          - 从而在 Cross Border 时，分 #cnum(1)#cnum(2)#cnum(3)#cnum(4)#cnum(5) 不同的阶段
          #grid2(
            fig("/public/assets/CG/GAMES104/2025-04-12-10-23-44.png"),
            fig("/public/assets/CG/GAMES104/2025-04-12-10-38-09.png", width: 80%)
          )
        - 另外这里有个细节，为了防止反复跨越 Border Line 导致的高频更新，一般会设置一个阈值，只有当玩家移动超过一定距离后才会进行切换（因此图中 #cnum(3) 应该还未切换到 Zone $B$）
    + *Instancing*
      - 同时独立地运行多个游戏区域实例，类似于副本
      - 减少拥堵和竞争的同时也降低了沉浸感
    + *Replication*
      - 复制游戏到很多层，允许更高的用户密度，跟前面说的 load balancing 类似
      - 跟 Zoning 跨区时的处理类似，如果要让某个 layer 的玩家看到足够多的玩家，实际上很多都是 ghost
    + *Combination*
      - 综合结合以上方法，首先考虑动态划分 Zones，但不能分得太小，否则一方面容易造成频繁跨区，另一方面至少也得大于 max AOI radius
      - 如果一个 Zone 已经很小但依旧负载过重，就考虑 Replication，分发到多个 server
      - Instancing 则作为补充和 GamePlay 的需要
  ],
  [
    #fig("/public/assets/CG/GAMES104/2025-04-12-10-13-10.png")
    #fig("/public/assets/CG/GAMES104/2025-04-12-10-44-38.png")
  ]
)