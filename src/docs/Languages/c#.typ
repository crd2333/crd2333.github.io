#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "C Sharp 笔记",
  lang: "zh",
)

// #show "C\#" : "C#"

= C Sharp 笔记
C\# 语言是由 Microsoft 公司开发的 OOP 编程语言，属于 .NET 平台的一部分。顾名思义它跟 Cpp 有很多相似之处，在有 Cpp 基础的情况下，其实学起来算比较快。

*为什么要学* C\#？对于我而言主要是因为 Unity 使用 C\# 作为脚本语言，文件后缀名为 `.C\#`。不过老实说在 Unity 走下坡路而基于 Cpp 的 Unreal Engine 持续上升的情况下，我学习 Unity 和 C\# 的动力有点被打击到。但毕竟用到了，没办法，老老实实学咯。

*如何学习* C\#？我搜集了以下资源：
+ 快速翻阅（有 Cpp 基础不难）一遍 #link("https://www.runoob.com/csharp/csharp-tutorial.html")[菜鸟教程 - C\#]
+ 有什么不懂的或许可以去 #link("https://learn.microsoft.com/zh-cn/dotnet/csharp/tour-of-csharp/overview")[微软官方 C\# 教程] 看看？
+ 这位专门写 C\# 和 Unity 的大佬的博客 #link("https://aihailan.com/?s=C%23")[海澜的博客 (search tag: C\#)]

== 高级特性
很多基础语法在不同语言中是互通的，快速过一遍即可。或许更多需要看的是*菜鸟教程*里面提到的*高级特性*，比如：特性 (Attribute)、反射 (Reflection)、属性 (Property)、索引器 (Indexer)、委托 (Delegate) 与事件 (Event)、集合 (Collection)、泛型 (Generic)、匿名方法、不安全代码、多线程、语言测验。

=== 特性 (Attribute)
就是给类、方法、属性等加上一些标签 (`[]`)，赋予其一定的特性，使用非常频繁。

=== 反射 (Reflection)
应该是用于在运行时获取类型信息的，比方说获取一个没有源代码的程序集的信息。从这个角度看 “反射” 这个名字就很形象了。可以参考下面这些文章：
+ #link("https://www.cnblogs.com/wangshenhe/p/3256657.html")[【整理】C\# 反射 (Reflection) 详解] 对反射的概念和动机解释得比较清楚
+ #link("https://blog.csdn.net/weixin_45136016/article/details/139095147")[C\# 反射 (Reflection) 超详细解析] 看起来似乎很全

=== 属性 (Property)
则是跟字段相区别，给其封装 `set`, `get` 方法，使其更安全或达到某些特定目的。

=== 索引器 (Indexer)
没什么好说的，类似于重载了默认的下标访问方式而已，跟 Cpp 重载 `operator[]` 是类似的。

=== 委托和事件 (Delegate and Event)
比较难理解，菜鸟教程写得比较烂，可以按顺序看下面列出的文章：
+ #link("https://zhuanlan.zhihu.com/p/413733828")[C\# 中委托 (delegate) 与事件 (event) 的快速理解] 先看这篇文章有个大概理解
+ #link("https://blog.csdn.net/life_is_crazy/article/details/78206166")[C\# 委托 (delegate) 和事件 (event) 详解] 再看这篇文章由浅入深（写的非常好！）
+ 然后是这两篇讲得很复杂、很底层的 #link("https://www.cnblogs.com/wangqiang3311/p/11201647.html")[彻底搞清楚 C\# 中的委托和事件]、#link("https://www.cnblogs.com/sjqq/p/6917497.html")[C\# 事件与委托详解【精华 多看看】]（但感觉甚至不如上面那篇好）

在委托和事件之上，还有 Action 和 Func。以及 Unity 又再次重载封装了一层形成 UnityAction, UnityEvent。其区别和用法，有点晕了，用到的时候再看吧。可参考 #link("https://blog.csdn.net/boyZhenGui/article/details/120956981")[【Unity知识点】通俗解释 delegate,  event, Action, Func, UnityAction, UnityEvent] 和 #link("https://developer.unity.cn/projects/602603cbedbc2a0020405f83")[帮你理清 C\# 委托、事件、Action、Func]

=== 集合 (Collection)
就是 Cpp 里的容器，常用的有 `List`, `Dictionary`, `Queue`, `Stack`, `HashSet` 等等。也可以参考 #link("https://aihailan.com/archives/941")[C\# 数据集合解析]

=== 泛型 (Generic)
跟 Cpp 里的模板差不太多，体感上更简单一些。区别可以参考 #link("https://blog.csdn.net/ylq1045/article/details/125227550")[C++ 模板和 C\# 泛型之间的区别【示例语法说明】]

=== 匿名函数 (Anonymous Method)
C\# 里面的匿名函数是用 `delegate` 实现的（而 Cpp 中则是编译器生成匿名类的语法糖），由于匿名方法没有签名而只有方法体，所以无法使用 `方法名();` 去调用，只能交由委托变量去调用它。换言之，匿名方法将自己唯一拥有的方法主体交给委托，让委托代理执行。

但是 C\# 2.0 之后引入了 lambda 表达式，允许更简洁地定义匿名函数，比如 `var evenNums = numbers.Where(n => n % 2 == 0)`。具体的进化过程和常用方法可以参考 #link("https://www.cnblogs.com/ywtssydm/p/18131890")[C\# lambda 表达式和匿名方法]。

=== 不安全代码 (Unsafe)
之前一直疑惑 C\# 里面是不是没有指针，其实是有的，但因为 C\# 有自动垃圾回收机制，存下来的指针指不定什么时候就变成非法了，并不安全。因此可以用 `unsafe` 声明不安全代码块，然后用 `fixed` 修饰指针变量，并且编译的时候也需要加上 `/unsafe` 选项。

=== 多线程 (Thread)
这个好像没什么好说的，稍微知道一点语法就行了，反正各种语言里基本都是那套，换汤不换药，需要时再查。多线程可能可以参考海澜大佬的多线程系列 —— #link("https://aihailan.com/archives/869")[上]、#link("https://aihailan.com/archives/872")[中]、#link("https://aihailan.com/archives/874")[下]（自己还没看）。

== C\# 进阶
看海澜大佬的 #link("https://aihailan.com/archives/2427")[编写高质量C\#代码必备技巧（上）] 与 #link("https://aihailan.com/archives/2429")[编写高质量C\#代码必备技巧（下）]。看不懂啊 orz，暂时应该用不到这么高深。

== 总结
目前感觉 C\# 跟 Cpp 在基础方面还是很像的，只是在 Cpp 的引用、指针等这些概念上弱化了许多，然后加入了一些新的特性。具体有哪些不同，我现在也还是半吊子，不好总结。比如说：
+ C\# 有垃圾回收机制，随便 new，不用自己 delete
+ C\# 有字段 (fields)、属性 (property) 的概念区别
+ C\# 有花里胡哨的特性 (attribute)
+ 相比起 Cpp 比较像是面向过程 (Procedure Oriented Programming, POP) 里掺了一点 OOP，C\# 则是纯 OOP，所有除了顶级语句之外的代码都需要写在类里

