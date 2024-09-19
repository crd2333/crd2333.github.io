#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Python 笔记",
  lang: "zh",
)

= TonyCrane 的视频笔记
== 注释
- 单行注释用 `#`
- 严格上没有多行注释，但可以用三个"来代替

== 列表list
- 类似其他语言的数组，内部类型可以不统一
- 用`[]`表示，`lst=[1,2,3,"abc",True]`
- 用`[]`索引，从0开始；可以加负号，表示从后往前数
- 切片功能`lst[a:b:c]`
  - `lst[1:3]`，得到下标1到3-1的分割出来的列表
  - 之所以设计成减1，是为了直接得到b-a的长度，同时可以理解为半闭半开的区间，使用更方便
  - 前后都可以省略，表示取完；也可以都省略，相当于拷贝一份列表
  - 若有三个元素，则c表示选取步长
    - c也可以是负数，这时需要a>b才能获取到值
    - `lst[::-1]`表示将整个列表翻转
  - 列表切片修改
    - `lst[2:4]=[1]`表示列表下标的2~3的值被替换成了1（变短了）
- 自带栈的功能
  - `lst.append(x)`在列表末尾加入元素x
  - `lst.pop()`弹出列表末尾元素并返回
- 任意位置插入弹出
  - `lst.insert(1,x)`在索引1的位置插入x，后面依次后移
  - `lst.pop(1)`弹出索引1的位置的元素，后面依次前移
- 列表拼接
  - 直接相加（不改变原列表，得到新的列表）
  - `lst.extend([1,2,3])`把一个列表接到原列表末尾
    - 注意与append的区别
- 根据值删除元素
  - `lst.remove(value)`删除第一个值为value的元素
- 列表排序
  - `lst.sort()`对原列表操作，升序排序
  - `lst.sort(reverse=True)`降序
  - `sorted(lst)`得到一个排序后的新列表
- 列表反转
  - `lst.reverse()`
    - 当然也可以用切片功能
  - `list(reversed(lst))`
    - 直接`reversed(lst)`得到的是一个列表生成器（为的是提高效率）
- 列表统计
  - `len(lst)`
  - `sum(lst)`
    - 可以传入start参数指定加和的起始值和类型
  - `max(lst)`,`min(lst)`

== 元组tuple
- 可以看做元素不可变的列表，内部也可以包含不同类型的元素
  - 但不能保证元素完全不可变，所以要避免在元组内放入可变元素（如列表）
- 可以使用和列表一样的方法读取元素（用`[]`），但不可修改
- 用`()`表示，内部用`,`分隔
- python默认用,分隔的元素会转成元组输出
- 当只有一个元素时，应写成`(a,)`而不是`(a)`（后者是单个值加括号而已）
- 可以用`tuple(...)`来将可迭代对象（列表、字符串等）转为元组

== 集合set
- 用`{}`表示，自动去重
- 集合中不能包含如列表等不能hash化的元素
- 可以用`set(...)`来将可迭代对象（列表、字符串等）转为集合
- 集合修改
  - `s.add(x)`加入元素x
  - `s.remove(x)`删除元素x，如果没有会抛出异常
  - `s.discard(x)`删除元素x，如果没有则忽略
- 集合运算
  - `s1 & s2`交集,`s1 | s2`并集,`s1 - s2`差集,`s1 ^ s2`对称差集

== 字典
- 也是用`{}`括起来，存储键值对，用`,`分隔，如`d={key:value,}`
- `{}`是空字典而不是空集合
- 用`d[key]`访问对应的值，如果不存在这个键会抛出异常
  - 通过`d.get(key)`访问值时如果不存在key这个键会返回None
  - 通过`d.get(key,default)`访问值时如果不存在key这个键会返回default值，如`default="not found"`
- 添加键值对，直接`d[key_2]=value_2`
- 删除键值对，用`del d[key2]`
- 更新键值对，`d.update(d2)`用d2对应的值更新d对应的值

== 条件语句
- `if-elif-else`结构（不是else if）
- 注意缩进
- 类三目运算符写法`B if A else C`（没有`A?B:C`）

== for循环
- python中的for循环不是像c一样指定一个变量的变化方式，而是从列表/元组/迭代器等可迭代对象中遍历值，如：`for value in lst:`,`for value in range(...):`
- python中为了循环产生的变量不是那么严格的局部变量（结束后不删除），在循环外部，它保留最后一次循环值
- 可以使用`range`生成一串数字用于循环
  - `range(a,b)`生成从a到b-1的连续整数
  - `range(a,b,c)`以c为步长生成
  - `range`得到的不是列表，如果要用其生成列表可以用`list(range(...))`
- 循环遍历字典（三种方法）
  - 遍历键：`for key in d.keys():`
  - 遍历值：`for value in d.values():`
  - 遍历键值对：`for item in d.items():`或`for key,value in d.items():`（解包）
- 枚举enumerate
  - 枚举可迭代对象
  - 可以加参数`start=1`，从1开始数
```python
lst=[1,2,"a","c"]
for i,value in enumerate(lst): = 这里用到了解包
    print(f"{i}-->{value}")
```
- 打包zip
  - 将可迭代的对象作为参数，将对象中对应的元素打包成一个个元组

== 元素解包
- 赋值时等号左侧可以使用逗号分隔的多个值，这时会将右侧解包分别赋值给左侧的各个变量
- 右侧也可以是多个值（出现逗号成为元组）
  - 可以通过`a,b=b,a`实现元素交换
- 星号表达式
  - 可以用来在可迭代对象内部解包
  - 也可以用来标记一个变量包含多个值
```python
t=(1,2,3)
a,b,c=t = a=1,b=2,c=3
t=(1,2,(3,4))
a,b,(c,d)=t  = c=3,d=4
t=[1,2,-[3,4]] = t=[1,2,3,4]
a,-b=[1,2,3,4]
```

== 列表推导，生成元组、字典
- 一种很方便的生成列表的方式
  - 即在列表中包含循环，遂次记录
  - 可以有多重循环，即生成笛卡尔积集
  - 可以包含条件，即在条件成立时才记录值
  - 列表推导中的循环变量有局部作用域，和for循环不一样
- 类似的，有生成元组和字典
```python
lst=[]
for i in range(1,10)
    lst.append(i--2)
= 等价于
lst=[i--2 for i in range(1,10)]

lst1=[x-y for x in l1 for y in l2]
lst2=[... for ... in ... if ... ]

t=tuple(i--2 for i in range(1,10))
d={a:b for a in ... for b in ... }
```

== 函数
- 定义方式，形状
- 用`return`返回
  - 没有`return`运行到结尾或者只有`return`，返回`None`
  - return的值类型不要求一致
  - return可以返回多个值（利用元组）
- 函数参数
  - 括号中列出参数名，可以指定默认值
  - 使用`-`来接受任意多个参素
    - 接收进来的是一个元组
    - `-`参数后面不能跟非关键字参数
  - 使用`--`来接受任意多关键字参数
    - 接受进来的是一个字典
- 函数调用
  - 直接传参要将参数与定义对应上顺序
  - 通过关键字传参可以打乱顺序

== 变量引用
- python中的变量都是引用的
- 用=实际上是定义了一个别名
  - Lst1=1st2,则Lst1和Lst2会同时变化（要用[:]创建副本）
  - 数值类型有优化，所以不会这样
  - `==`检查值是否相等，`is`检查值是否相同（比较id）
- 函数参数传递只有“共享传参”一种形式（即传引用）
  - 可变变量（例如列表）在函数内部可以被改变
  - 避免向函数传递可变变量（列表可传入[:]创建的副本）

== 匿名函数与高阶函数
- 可以通过lambda表达式来定义匿名函数
  - 格式：`lambda 输入:输出表达式`
  - 可以有多个输入
  - 可以将匿名函数赋值给一个变量
- 接受函数作为参数的函数叫做高阶函数
  - 常见如`map`和`filter`
    - `map(A,B)`将函数A作用于可迭代对象B，输出`A(B)`
    - `filter(A,B)`,将函数A作用于可迭代对象B，当值为`True`时输出，否则过滤

== 用户输入
- 使用内置的`input`函数
- 函数参数为要显示的提示符，如`input("please input number>>> ")`
- 函数返回值为字符串
- 每次读到换行为止
- 读入数字类型`a,b=map(int,input().strip().split())`
- 读入奇数`list(filter(lambda a:a%2==1,map(int,input().strip().split())))`

== 类与类的继承(没懂)
- 类可以看成包含一些属性和方法的框架
- 根据类来创建对象→实例化
- 用class关键字来定义类
- 类中的函数→方法
  - 特殊方法`__init__`,在类实例化的时候会被自动调用
  - 其它一般的方法第一个参数都要为"self",调用的时候会自动传入
- 直接写在类中的是属性，也可以通过为`self.<name>`赋值的形式创建属性
- 用类似函数调用的形式实例化类，参数为`__init__`方法的参数
- 直接通过`.<method>.<attribute>`的形式调用方法/获取属性
```
class ClassName():
  a=1
  def __init__(self,arg1,arg2):
    self.arg1 = arg1
    self.arg2 = arg2
  def method(self):
    print(self.arg1,self.arg2,self.a)
obj.ClassName(2,3)
obj.method() =2 3 1
print(obj.a,obj.arg1) =1 2
```
- 在class定义的括号中加上另一个类名则表示继承自那个类定义一个子类
- 子类会继承父类的所有属性和方法
- 子类编写和父类名字一样的方法会重载
- 在重载的方法中调用父类的原方法使用super()
- 也可以为子类定义独有的方法
```
class ClassA():
  def init_(self,a):
    self.a = a
  def print(self):
    print(self.a)
class ClassB(CLassA):
  def__init__(self,a):
    super().__init__(a)
    self.a -=2
obj = ClassB(1)
obj.print() =2
```

== 私有？
- `python`中类并没有严格私有的属性
- 双下划线开头的属性会被隐藏，不能直接读取
- 使用双下划线开头的属性可以轻微保护属性，但并不代表其是私有的
- 但这种属性可以通过 `_类名__属性` 的方式读取到

== 一切皆对象？
- `python`中即使最简单的整数也是一个类（`object`）的实例
- 通过`dir(...)`查看一个对象的所有属性/方法
- 有很多双下划线开头、双下划线结尾的方法，成为魔术方法(dunder method)

== 魔术方法
- 很多函数、表达式其实是通过调用类的魔术方法来实现的，如：
  - `len(obj)`调用`obj.__len__()`
  - `obj[...]`调用`obj.__getitem__（...)`
  - `a in obj`调用`obj.__contains__（a)`
  - `booL(obj)`调用`obj.__bool__()`
  - 函数的调用本质上是调用`func.__cal__`
  - `a + b`调用`a.__add__(b)`
  - ......

== python进阶
- python中类还有更多更多更好玩的用法
- 静态方法、类方法……
- 多重继承、mro顺序……
- 接口协议、鸭子类型、抽象基类……
- 猴子补丁……
- 元类……
- 垃圾回收……
- ......

== 文件操作
- open函数，传入文件名、打开模式
- 打开模式（可以叠加）：`r`读（默认）、`w`写、`x`创建并写、`a`写在末尾、`b`字节模式、`t`文本模式（默认）
- 读取
  - 文本模式建议加上`encoding`,不然容易报错
  - `f,read()`读取全部内容（字节模式得到字节序列）
  - `f.readline()`读取一行
  - `f.readlines()`读取所有行，返回一个列表
- 写入
  - 文本模式同样建议加上`encoding`
  - `f.write(...)`直接写入，返回值为写入字符数
  - `f.writelines(...)`传入列表，元素间换行写入
- 通过这种形式操作文件记得用完后要`f.close()`

== with 块
- `with ... as ... :`开启一个上下文管理器
- 常用在文件open上
  - with块开始自动打开
  - with块结束自动结束
- with块结束后变量仍会留存
```
with open("file","r",encoding="utf-8") as f:
  s = f.read()

print(f.closed) =True
```

== 异常与处理
- 产生错误→抛出异常→程序结束
- raise关键字抛出异常
- try-except块捕获异常
  - 可以有多个except、不可以没有
  - except后接异常类（没有则捕获所有）
  - as字句存下异常
- finally语句，不管是否有异常都会运行
```
try:
  print(1 0)
except ZeroDivisionError as e:
  print("can't devide by zero")
  raise e
finally:
  print("finished")
```

== if 外的 else 语句
- else块不仅仅跟着if才能运行
- `for-else`和`while-else`
  - for正常结束运行else，while不满足condition退出运行else
  - break异常退出则不会运行
  - 不用这个功能的话，则需要用flag来标记之类的
- `try-else`
  - try块中没有异常出现才会运行
  - else块中异常不会被前面的except捕获
- 程序流跳到块外了不会运行(return等)

== 模块与导入
- 模块可以是一个单独的.py文件，也可以是一个文件夹
  - 文件夹相当于导入其下`__init____.py`文件
  - `__init____.py`里面导入`main.py`里的函数
- 模块中正常编写函数、类、语句
- 通过import语句导入模块
  - `import code`
  - `import code as cd`
  - `from code import ...`
  - `from code import -`
- 导入时相当于运行了一遍导入的代码

== “main函数”
- 防止导入时运行代码，只允许直接运行脚本时运行
- 通过判断`__name__`
  - 如果是直接运行，则其等于字符串`__main__`
  - 如果是被导入的，则其等于模块名

== python内部模块
- `python`内置了很多内部模块（标准库），如：
  - os、sys:系统操作
  - math:数学运算
  - re:正则表达式
  - datetime:日期与时间
  - subprocess:子进程管理
  - argparse:命令行参数解析
  - Logging:日志记录
  - hashlib:哈希计算
  - random:随机数
  - csv、json:数据格式解析
  - collections:更多类型
  - ……
- 详情见："docs.python.org/zh-cn/3/library"


== 文档字符串
- 模块开头的三引号字符串，或者函数、类定义下面的三引号字符串
- `help(...)`的时候可以显示
- `obj.__doc__`表示这串字符
- 编辑器用来提示
- 一些文档生成工具（sphinx等）从中获取文档


- 以上均为 xg 的 python 授课中摘录的内容

== 高阶函数
- 操作函数的函数叫做高阶函数。这一叫法跟 Python 可以将函数作为参数传递的特性有关，不仅如此，还能做到函数的嵌套定义
- python 中所谓函数的环境，在这里就分出两个含义
  1. 每个用户定义的函数都有一个关联环境：它的定义所在的环境。
  2. 当一个用户定义的函数调用时，它的局部帧扩展于函数所关联的环境。
- 词法作用域的两个关键优势
  1. 局部函数的名称并不影响定义所在函数外部的名称，因为局部函数的名称绑定到了定义处的当前局部环境中，而不是全局环境。
  2. 局部函数可以访问外层函数的环境。这是因为局部函数的函数体的求值环境扩展于定义处的求值环境。
  - 事实上，这感觉跟 C 语言中的生存期、作用域等概念真的很像。复杂之处在于，python 可以嵌套定义
- 这样定义的环境模型有一个好处就是可以将函数自己作为结果返回，例如：
    ```python
    def square(x):
        return x - x
    def successor(x):
        return x + 1
    def compose1(f, g):
        def h(x):
            return f(g(x))
        return h
    add_one_and_square = compose1(square, successor)
    add_one_and_square(12)
    = The result is 169.
    ```
- 上面的例子中，我们注意到，我们在 Global 环境中创建了 square 函数和 successor 函数，将 `x - x` 和 `x + 1` 这种表达式关联到一个名称上，这种实现方式不是那么优雅（我不知道会不会相对造成更大的开销）。Python 中提供匿名函数(lambda)机制来简化这一问题
  - 例如，上文的 `compose1` 可以写成
      ```py
      def compose1(f,g):
          return lambda x: f(g(x))
      ```
  - 将表达式重构为应为语句来理解 lambda 语句
    ```py
        lambda            x            :          f(g(x))
    "A function that    takes x    and returns     f(g(x))"
    ```
- 有关 frame 和高阶函数的这一块是真的很复杂，建议是把代码放到 python tutor 里可视化查看

= Python 笔记之自我探索
== Python Decorator（装饰器）
- 是以前没有见过的语法
- 可以参考这个视频 #link("https://www.bilibili.com/video/BV11s411V7Dt/?spm_id_from=333.337.search-card.all.click&vd_source=39c8439d36378fa7ed46eae9e393a316")[Python小技巧：装饰器(Decorator)\_bilibili]
- 有什么用呢？根据我目前的了解，它可以给函数附加功能。比如，一个计算函数，我们要让它同时输出运行的时间，正常的方法是在代码中加计算时间的片段，但这会导致附加代码和实际计算代码混在一起，比较难看。这就是装饰器发挥作用的地方了。在想要运行的计算函数前加个 `@<装饰器名>`，再额外写一个装饰器函数，这样，所有的计算函数就都可以享受到装饰器了
  - 说得高级一些，就是：--装饰器的作用就是为了解耦一些通用处理或者不必要功能的，尽可能让一个函数只负责一个任务，避免后续维护时散弹式修改代码--
```py
def xx1(<被装饰函数>)：
    def xx2(如果被装饰函数有参数那么输入)：
        xxxxxxxxxxxxxxx
        <被装饰函数>(如果被装饰函数有参数那么输入)
        xxxxxxxxxxxxxxx
        = 如果被装饰函数中含有return则需要返回被装饰函数,没有则不需要
        return xx2
```
- 用处例如，函数自动输出运行时间、函数自动追踪（效果如下）等等
    ```
    >>> traced_reverse(123)
    -> 123
    -> 12
    -> 1
    <- 1
    <- 21
    <- 321
    321
    ```
- 有一个问题是为什么要做的这么复杂，创建装饰器的语法，而不能直接 `new_func = decorator(old_func)`，这样方便理解得多。问题在于，这样就没法确保递归函数的效果，比如，如果被装饰函数是自引用的，装饰器的语法确保了调用的还是 `old_func` 它自己（只不过被装饰了），否则，会造成一次又一次的给调用函数加 `decorator`

