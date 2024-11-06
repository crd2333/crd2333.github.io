---
order: 1
---

# CS61A

[toc]

## Lecture 2
* 表达式的计算
* `**` means `power`
* 函数可以被嵌套定义，也可以被作为参数传递 (我觉得这是目前看下来和 c 语言 最大的区别)

***
## Lecture 3
* 闭包，感觉就是作用域、本地变量、全局变量一样的概念
* `ture_part if condition else false_part` if 的新格式
  * c 中的`else if`记作`elif`
* `python`的`与或非`，直接就是`and` `or` `not`
* 按位`与或非`同 c,`&` `|` `~` `^`
* `and`和`or`返回的不是真值而是表达式
* python 通过缩进体现代码块的包含范围
* 注意 print('') 和 return ''的区别
* 负数也是 True，只有 0 为 False
* and 与 or，输出决定结果的那个值
  * 如`1 and 2`为 2,`1 or 2`为 1;`1 and 0`为 0,`0 or True`为 True
* true 必须写成 True,false 必须写成 False
* True 和 False 可以参与数值计算，分别为 1 和 0
* Python assert（断言）用于判断一个表达式，在表达式条件为 false 的时候触发异常
  * 好处在于，人为地设置了错误的原因，范围更 narrow。另外，它使得出现异常但没有停止的代码也显示出了错误，"crash is better than incorrect"
* `**`幂，`//`整除（往-$\infty$方向）
* 简易的函数定义方式（匿名函数）：
    ```python
    x = lambda a:a**3 #cube of a
    print(x(5))
    # which is equals to
    def cube(x):
        x=x**3
        print(x)
    ```
    * 我们可以将匿名函数封装在一个函数内，这样可以使用同样的代码来创建多个匿名函数。类似定义函数的函数，称之为高阶函数
    * 例如：`def myfunc(n): return lambda a : a * n`，可以创造不同的幂函数

***
## Lecture 4
* `int(str(player_score)[:2])`转字符串再取前两位转数字
* `python`中函数的传递参数与默认参数：如果传入了一个参数，则优先使用传入的，否则，使用默认参数
* `python`中函数的关键字参数：不一定按照创建函数时的顺序，可以按照参数名相匹配
* `python`中函数的可变对象与不可变对象
* `python`的函数传递使用比我想象的普遍得多 orz
* `python`的函数可以同时返回多个值
* `print`函数，使用时的逗号是分隔变量的，它不会真的被打印出来！

***
## Lecture 5: environment
- 这节主要是在看 python tutor 中理解 python 的 frame 机制
- curry 法函数：将多参数函数分离成一层层的接受单个参数的函数，如
    ```py
    def curry2(f):
        return lambda x:lambda y:f(x,y)
    from operator import add
    print(curry2(add)(30)(12))
    print(curry2(add)(30))   # Prints a function value
    ```
### Currying & Self Reference
- **Currying**, One important application of HOFs（高阶函数）is converting a function that takes multiple arguments into a chain of functions that each take a single argument.
- **Self Reference**,高阶函数的一种特殊形式，where a function eventually returns itself.
- 例如：（分别为一阶二阶）
    ```py
    def print_all(x):
        print(x)
        return print_all
    ```
    ```py
    def print_sums(n):
        print(n)
        def next_sum(k):
            return print_sums(n + k)
        return next_sum
    ```
- A Note on Recursion: This differs from recursion because typically each new call returns a new function rather than a function call.

### DISC 02:Currying & Self Reference.eg
- Chain Question: Q1 -->(currying) Q2 -->(self reference) Q7
- Q1: Keep Ints
Write a function that takes in a function cond and a number n and prints numbers from 1 to n where calling cond on that number returns True.
```py
def keep_ints(cond, n):
    """Print out all integers 1..i..n where cond(i) is true
    >>> def is_even(x):
    ...     # Even numbers have remainder 0 when divided by 2.
    ...     return x % 2 == 0
    >>> keep_ints(is_even, 5)
    2
    4
    """
    for i in range(1, n+1):
        if (cond(i)):
            print(i)
```
- Q2: (Tutorial) Make Keeper
Write a function similar to keep_ints like in Question 1 #, but now it takes in a number n and returns a function that has one parameter cond. The returned function prints out numbers from 1 to n where calling cond on that number returns True.
```py
def make_keeper(n):
    """Returns a function which takes one parameter cond and prints out all integers 1..i..n where calling cond(i) returns True.
        >>> def is_even(x):
        ...     # Even numbers have remainder 0 when divided by 2.
        ...     return x % 2 == 0
        >>> make_keeper(5)(is_even)
        2
        4
    """
    def cond(n):
        for i in range(1, n+1):
            if (cond(i)):
                print(i)
    return cond
```
- Q7: (Tutorial) Warm Up: Make Keeper Redux
These exercises are meant to help refresh your memory of topics covered in Lecture and/or lab this week before tackling more challenging problems.
In this question, we will explore the execution of a self-reference function, make_keeper_redux, based off Question 2, make_keeper. The function make_keeper_redux is similar to make_keeper, but now the returned function also returns another function with the same behavior. Feel free to paste and modify your code for make_keeper below.
(Hint: you only need to add one line to your make_keeper solution. What is currently missing from make_keeper_redux?)
```py
def make_keeper_redux(n):
    """Returns a function. This function takes one parameter <cond> and prints out
       all integers 1..i..n where calling cond(i) returns True. The returned
       function returns another function with the exact same behavior.
        >>> def multiple_of_4(x):
        ...     return x % 4 == 0
        >>> def ends_with_1(x):
        ...     return x % 10 == 1
        >>> k = make_keeper_redux(11)(multiple_of_4)
        4
        8
        >>> k = k(ends_with_1)
        1
        11
        >>> k
        <function do_keep>
    """
    def f(cond):
        for i in range(1, n+1):
            if (cond(i)):
                print(i)
        return f
    return f
```
- Q8: Print Delayed
Write a function print_delayed that delays printing its argument until the next function call. print_delayed takes in an argument x and returns a new function delay_print. When delay_print is called, it prints out x and returns another delay_print.
```py
def print_delayed(x):
    """Return a new function. This new function, when called, will print out x and return another function with the same behavior.
    >>> f = print_delayed(1)
    >>> f = f(2)
    1
    >>> f = f(3)
    2
    >>> f = f(4)(5)
    3
    4
    >>> f("hi") # a function is returned
    5
    <function delay_print>
    """
    def delay_print(y):
        print(x)
        return print_delayed(y)
    return delay_print
```
- Q9: (Tutorial) Print N
Write a function print_n that can take in an integer n and returns a repeatable print function that can print the next n parameters. After the nth parameter, it just prints "done".
```py
def print_n(n):
    """
    >>> f = print_n(2)
    >>> f = f("hi")
    hi
    >>> f = f("hello")
    hello
    >>> f = f("bye")
    done
    >>> g = print_n(1)
    >>> g("first")("second")("third")
    first
    done
    done
    <function inner_print>
    """
    def inner_print(x):
        if n <= 0:
            print("done")
        else:
            print(x)
        return print_n(n - 1)
    return inner_print
```

***
## Lecture 6、7: recurse
- iterative V.S. recursive
  - recursive is a little like induction
  - tail recursive:can be changed to iterative
- Linear Recursive V.S. Tree Recursive
  - 什么是 linear recursive，不是说只有 case 往一个方向变才叫 linear recursive，而是指这一层调用中只会进行一次递归，而不会进行多次。尽管方向变化，它依然是一条线
- 可以用 and、or 来消除程序中的 if

***
## Lecture 8、9: more on function & examples
- 异常处理
  - raise
  - try

***
## Lecture 10: container
- 从 container 的概念引入，试图自己实现数对以存储多个值。然后讲到 python 中原有的 sequence：tuple、list、string、list
  - tuple 中的元素不可变，list 中的元素可变
- 在 Python 中，局部变量是在函数被调用时创建的。当函数被调用时，Python 会为该函数创建一个新的“命名空间”。这个命名空间包含函数的参数和在函数内定义的局部变量。当程序执行到赋值语句时，相应的变量会被创建并赋予特定的值。但需要注意的是，变量在赋值语句之前访问是不允许的，因为它们在那个时候还未被绑定到相应的值上。
  - 例如在下面这个例子中，你可能以为报错的那条语句既然局部的 var 还未被创建，那他应该到 parent frame 去找 var 并打印 1 才对，但事实上，已经在本地找到了 var 这个变量了，只是还未绑定到相应的值上
    ```py
    def my_function1(var):
        def my_function2():
            print(var)  # 报错：UnboundLocalError: local variable 'var' referenced before assignment
            var = 2
        my_function2()
        return var

    my_function1(1)
    ```
  - 解决方法也是有的，可以用 `nonlocal var` 指定 var 是父幻境中的 var
  - 其实这一点在 C 语言中也是一样的，变量在进入函数的那一刻就创建了
- 字符串的 `'` 与 `"`，其区别是前者中允许后者的存在（跟中文的习惯反一反），二者均允许中间出现自己

### DISC 03:
- Recursion
  - A recursive function is a function that is defined in terms of itself. 这可能跟 Self Reference 听起来有点像，但是后者是高阶函数中返回自己，这里是函数调用返回自己，不要搞混了（后者是返回函数，而 recursion 是返回函数调用）
- Q3: Is Prime
Write a function is_prime that takes a single argument n and returns True if n is a prime number and False otherwise. Assume n > 1.（不难，大那是我没想到可以这样递归）
```py
def is_prime(n):
    """Returns True if n is a prime number and False otherwise.
    >>> is_prime(2)
    True
    >>> is_prime(16)
    False
    >>> is_prime(521)
    True
    """
    def is_factor(x):
        if x >= n:
            return True
        elif n % x == 0:
            return False
        return is_factor(x + 1)
    return is_factor(2)
```
- Q7: (Tutorial) Count K（青蛙跳台阶问题，不会做，只会经典的 1、2 层问题）
Consider a special version of the count_stair_ways problem, where instead of taking 1 or 2 steps, we are able to take up to and including k steps at a time. Write a function count_k that figures out the number of paths for this scenario. Assume n and k are positive.
```py
def count_k(n, k):
    """ Counts the number of paths up a flight of n stairs
    when taking up to and including k steps at a time.
    >>> count_k(3, 3) # 3, 2 + 1, 1 + 2, 1 + 1 + 1
    4
    >>> count_k(4, 4)
    8
    >>> count_k(10, 3)
    274
    >>> count_k(300, 1) # Only one step at a time
    1
    """
    """
    对递归情况的说明
    从数学的角度我是能理解了，但是组合的角度我还是理解不了，算了，已经花太久了
    一只青蛙一次可以跳上 1 级台阶，也可以跳上 2 级……它也可以跳上 n 级。求该青蛙跳上一个 n 级的台阶总共有多少种跳法。
        f(n) = f(n-1) + f(n-2) + f(n-3) + ... + f(n-(n-1)) + f(n-n)= f(0) + f(1) + f(2) + f(3) + ... + f(n-2) + f(n-1)
        f(n-1) = f((n-1)-1) + f((n-1)-2) + … + f((n-1)-(n-2)) + f((n-1)-(n-1)) = f(0) + f(1) + f(2) + f(3) + ... + f(n-2)
        so  f(n) = 2*f(n-1)
    一只青蛙一次可以跳上 1 级台阶，也可以跳上 2 级……它也可以跳上 m 级。求该青蛙跳上一个 n 级的台阶总共有多少种跳法。
        先列多项式：
        f(n) =  f(n-1) + f(n-2) + f(n-3) + ... + f(n-m)
        f(n-1) =   f(n-2) + f(n-3) + ... + f(n-m) + f(n-m-1)
        化简得：f(n) = 2f(n-1) - f(n-m-1)
    """
    if n == 0 or n == 1:
        return 1
    elif k == 1:
        return 1
    elif k >= n:
        return 2 * count_k(n - 1, n)
    else:
        return 2 * count_k(n - 1, k) - count_k(n - 1 - k, k)
```

***
## Lecture 11: Sequence(II) & Data Abstraction
- Zip 与 Sequence 的结合
    ```py
    beasts = ["aardvark","axolotl","gnu","hartebeest"]
    for n,animal in zip(range(1,5),beasts):
        print(n,animal)
    """
    1 aardvark
    2 axolotl
    3 gnu
    4 hartebeest
    """
    ```
  - zip 实际上是一个 generator
- list 的使用，非常灵活
    ```py
    >>> L = [1,2,3,4,5]
    >>> L[2] = 6
    >>> L
    [1,2,6,4,5]
    >>> L[1:3] = [9,8]
    >>> L
    [1,9,8,4,5]
    >>> L[2:4]=[] # Deleting elements
    >>> L
    [1,9,5]
    >>> L[1:1]=[2,3,4,5] # Inserting elements
    >>> L
    [1,2,3,4,5,9,5]
    >>> L[len(L):][10,11] # Appending
    >>> L
    [1,2,3,4,5,9,5,10,11]
    >>> L[0:0] = range(-3,0) # Prepending
    >>> L
    [-3,-2,-1,1,2,3.4,5,9,5,10,11]
    ```
- 注意，`len()` of list 返回的是一阶长度，也就是说矩阵返回的是行数
- list comprehension: 生成列表的方法
  - 语法：`[<expression> for <iter_val> in <iterable> if <cond_expr>]`，其中 if 可选（无 else）
  - 带 if-else 的语法：`[<expression_1> if <cond_expr> else <expresion_2> for <iter_val> in <iterable>]`
  - 注意二者的顺序
- ADT: abstract data type

***
## Lecture 12: Dictionaries, Matrices, and Trees
- 一些基本的字典、矩阵、树在 python 中的实现，前二者比较基本，tree 比较新对我来说

***
## Lecture 13: Creating Trees, Mutability（突变）, List Mutations
- operation 的 destructive 性与 non-destructive 性（破坏）
  - 判定标准在于有没有改变原本的被操作对象
- value 的 Immutability 性与 Mutability 性（可变）
  - 前者一经创建不可改变，后者可变
  - immutable 的东西内如果包含了 mutable 的东西，那这个 mutable 的东西是可以变的，对 immutable 的东西来说，它内部的东西并没有变
  - 可以用 `id()` 来查看在内存中的东西是否有改变
    - string `+=` 会改变 id
    - list 改变内容不改变 id，但是重新赋值（做了 bind）就会变
    - 一个数字 num 改变内容会改变 id，这点很反直觉，跟 c 语言中的指针不太一样
    - 但是，先 `a = [1, 2, 3]`，再 `b = a`，二者的 id 是相同的
    - 对数字，先 `a = 1`，再 `b = a`，有点奇怪，没说到底是怎么样的，也许是随机？说是 CS164 有教
  - Mutation in function calls
    - An function can change the value of any object in its scope（作用域）.
    - 对数字来讲，它只能改局部的
    - 对列表来讲，它能回到父框架改值（但不能 rebind）
- 我们很多函数、操作的实现，都是基于 destructive 性、mutable 性、抽象界限来决定的。比如，如果打破抽象界限我们知道某个东西的实现方式是 mutable 的，那我们再去实现新的操作就可以很方便的直接更改，做一个 destructive 的实现……
- list 是 non-destructive、mutable

***
## Lecture 14 List Mutations, Identity vs. Equality, Global Nonlocal
- 关于列表的“哲学”问题
    ```py
    a = [1, 2, 3]
    c = a
    a = a + [4, 5] # 如果在 python tutor 中可以看到，这里的操作是 non-destructive 的（不过 python tutor 的显示不太准确，如果少了 `c = a` 那一行，会显示成替换了，但实际不是）
    ```
    However...
    ```py
    a = [1, 2, 3]
    c = a
    a += [4, 5] # 这个操作却是 destructive 的，这说明 `+=` 不完全是 `=`、`+` 的语法糖，这很玄学
    ```
- list methods
  - 加法与 `.append(x)` 的区别，加法在 methods 中的实现是 `.extend(x)`，但是后者只能用于可迭代对象（从这个角度和上面那个例子来看，加法的操作性质和实现不那么“精确”）
    - 还有个更细节的问题，把 `b` append 或 extend 上去之后，如果改变 `b`，a 是否跟着变
    ```py
    a = [1, 2, 3]
    b = [4, 5]
    a = a + b   # [1, 2, 3, 4, 5]
    a.append(b)   # [1, 2, 3, 4, 5, [4, 5]],equal to a.extend(b)
    ```
  - `.pop()` 弹出（删除并返回）list 中的最后一个值，如果给它参数，则改为弹出指定索引位
  - `.remove(x)` 删除最先找到的匹配的值，否则返回 error
- Identity vs. Equality
  - 即 `a is b` 和 `a == b` 的区别。前者反映指向的内存，即是不是一个东西；后者反映指向的值，即是否相等
  - 后者包含了前者，前者更狭义
  - 一般来说，比较 type 的时候更常用 `is`，跟 None 作比较的时候更常用 `is`
  - 注意，有的时候分别创建两个相同的字符串或数字，python 会进行内存优化，导致这两个理应是不同东西的玩意儿变成了同一个 id。所以，对字符和字符串，一定要用 `==`

### DISC 05: Python Lists, Trees, Mutability
- Q2: (Tutorial) Max Product
Write a function that takes in a list and returns the maximum product that can be formed using nonconsecutive elements of the list. The input list will contain only numbers greater than or equal to 1.
```py
def max_product(s):
    """Return the maximum product that can be formed using non-consecutive
    elements of s.

    >>> max_product([10,3,1,9,2]) # 10 * 9
    90
    >>> max_product([5,10,5,10,5]) # 5 * 5 * 5
    125
    >>> max_product([])
    1
    """
    if len(s) == 0:
        return 1
    else:
        return max(s[0] * max_product(s[2:]), max_product(s[1:]))
```
- Q4: (Optional) Mystery Reverse Environment Diagram
Fill in the lines below so that the variables in the global frame are bound to the values below. Note that the image does not contain a full environment diagram. You may only use brackets, commas, colons, p and q in your answer.
![Alt text](./pictures/1.png)
```py
def mystery(p, q):
    p[1].extend(_______________________)
    ______________________.append(_______________[1:]_)

p = [2, 3]
q = [4, [p]]
mystery(____________________,____________________)

# --->
def mystery(p, q):
    p[1].extend(q)
    q.append(p[1:])

p = [2, 3]
q = [4, [p]]
mystery(q, p)
```
- 好难！
- Q6: (Warmup) Height
Write a function that returns the height of a tree. Recall that the height of a tree is the length of the longest path from the root to a leaf.
```py
def height(t):
    """Return the height of a tree.

    >>> t = tree(3, [tree(5, [tree(1)]), tree(2)])
    >>> height(t)
    2
    """
    if not children(t):   # if is_leaf
        return 1
    else:
        return max([height(children(c)) for c in children(t)]) + 1
```
- Q7 是 Q6 的简单变种，把 `1` 改为 `label(t)` 即可
- Q8: (Tutorial) Find Path
Write a function that takes in a tree and a value x and returns a list containing the nodes along the path required to get from the root of the tree to a node containing x.
If x is not present in the tree, return None. Assume that the entries of the tree are unique.
```py
def find_path(tree, x):
    """
    >>> t = tree(2, [tree(7, [tree(3), tree(6, [tree(5), tree(11)])] ), tree(15)])
    >>> find_path(t, 5)
    [2, 7, 6, 5]
    >>> find_path(t, 10)  # returns None
    """
    if _____________________________:
        return _____________________________
    _____________________________:
        path = ______________________:
        if _____________________________:
            return _____________________________

# --->
def find_path(tree, x):
    if label(tree) == x:
        return [label(tree)]
    for c in children(tree):
        path = find_path(c, x)
        if path:
            return [label(tree)] + path
```
- 有点难

***
## Lecture 15:iterators + generators
- `iter(<可迭代对象>)` 返回一个迭代器，可以对它一直 `next()` 到 stop
  - 由于 stop 这个异常会终止整个程序，所以我们通常把它放在 try、except 语句中，即
    ```py
    try:
        while True:
            choco = next(chocolaterator)
            print(choco)
    except StopIteration:
        print("No more left!")
    ```
  - 实际上，for loop 内部就在做这个事情
  - `iter` 和 `next` 实际上都是可迭代对象的方法
- 改变迭代器下面的可迭代对象是相当危险的，因为迭代器有可能追踪可迭代对象的某些属性，导致出现意料之外的变化
- functions that return iterators：
  1. `reversed(sequence)`
  2. `zip(*iterables)`
     - 一长一短的情况
     - 多个可迭代对象的情况
  3. `map(func, iterable)`
     - 效果跟 list comprehension 差不多
  4. `filter(func, iterable)`
     - 效果跟 list comprehension 加 if 差不多
- generators, def + yield
  - yield 会暂停并输出，在 `next()` 之后继续
  - 好处在于它只在需要时算下一项，适用于一些不需要把完整地东西算出来的情况
  - 对 for 循环的语法糖 `yield from`
  - 之前的很多 def 函数都可以改成 generator，比如：
    ```py
    def leaves(t):
        yield label(t)
        for c in branches(t):
            yield from leaves(c)
    ```

### hw:04
- 首先是一个关于递归的误区
    ```py
    def min_depth(t):
        """A simple function to return the distance between t's root and its closest leaf"""
        if is_leaf(t):
            return 0 # Base case---the distance between a node and itself is zero
        h = float('inf') # Python's version of infinity
        for b in branches(t):
            if is_leaf(b): return 1 # !!!
            h = min(h, 1 + min_depth(b))
        return h
    ```
    The line flagged with !!! is an "arms-length" recursion violation. Although our code works correctly when it is present, by performing this check we are doing work that should be done by the next level of recursion—we already have an if-statement that handles any inputs to min_depth that are leaves, so we should not include this line to eliminate redundancy in our code.
    ```py
    def min_depth(t):
        """A simple function to return the distance between t's root and its closest leaf"""
        if is_leaf(t):
            return 0
        h = float('inf')
        for b in branches(t):
            # Still works fine!
            h = min(h, 1 + min_depth(b))
        return h
    ```

***
## lecture16: Objects + Classes
- Objects 是数据和方法的集合
- 定义 Classes，然后将其实例化得到 Objects
- 一些惯例与语法，`__init__`、`self`、`_变量名`
- 每个方法都需要 `self` 作为第一个参数
- 可以任意创建新的实例变量
- 也可以创建类变量，使得他们在实例之间共享
- 先查实例变量，如果没有，就去查类变量
  - 实例变量与类变量的概念
- python 对属性的访问比 Java 随意得多，因此即使程序员加上 `_` 或 `__` 表示不希望被访问，实际上还是可以访问

### lab06:
- ~~数量与列表在本地变量中的不同表现~~ 不是这个原因，是 `append` 和 `=` 的机理不同，后者会做重绑定
    ```py
    def ba(by):
        def yo(da):
            by += 2   # return error
            return by
        return yo(2)
    ba(3)
    ```
    ```py
    def ba(by):
        def yo(da):
            by.append(da) # not return error
            return by
        return yo(5)
    ```

## lecture17: Inheritance（继承） + Composition
- 当多个类共享一些相似的属性时，我们不希望代码有太多重复，因此有 inheritance 这一特性，子类继承自父类，但可以决定是否自定义（或覆盖）一些属性、方法，被继承的那个类又被称为 superclass
- 子类中调用父类的方法，如果没有覆写，原本就存在；但看一个例子，如果需要加上一些条件再执行原来的方法，这时已经覆写了，如何调用父类方法呢？`super().<method>`
- 事实上，所有的 python3 class 都是隐式地从 `object` 这一个 class 中继承来的
- 多重继承，这是可以做到的，创建子类的时候括号里填多个父类就行了，但是会使得代码变得混乱，不建议这样做，尤其是两个父类有相同的属性的时候

### DISC06:
- Email 系统，蛮绕的
We would like to write three different classes (Server, Client, and Email) to simulate a system for sending and receiving email. Fill in the definitions below to finish the implementation!
Important: We suggest that you approach this problem by first filling out the Email class, then the register_client method of Server, the Client class, and lastly the send method of the Server class.

    ```py
    class Email:
        """Every email object has 3 instance attributes: the
        message, the sender name, and the recipient name.
        """
        def __init__(self, msg, sender_name, recipient_name):
            self.msg = msg
            self.sender_name = sender_name
            self.recipient_name = recipient_name

    class Server:
        """Each Server has an instance attribute clients, which
        is a dictionary that associates client names with
        client objects.
        """
        def __init__(self):
            self.clients = {}

        def send(self, email):
            """Take an email and put it in the inbox of the client
            it is addressed to.
            """
            self.clients[email.recipient_name].receive(email)

        def register_client(self, client, client_name):
            """Takes a client object and client_name and adds them
            to the clients instance attribute.
            """
            self.clients[client_name] = client

    class Client:
        """Every Client has instance attributes name (which is
        used for addressing emails to the client), server
        (which is used to send emails out to other clients), and
        inbox (a list of all emails the client has received).

        >>> s = Server()
        >>> a = Client(s, 'Alice')
        >>> b = Client(s, 'Bob')
        >>> a.compose('Hello, World!', 'Bob')
        >>> b.inbox[0].msg
        'Hello, World!'
        >>> a.compose('CS 61A Rocks!', 'Bob')
        >>> len(b.inbox)
        2
        >>> b.inbox[1].msg
        'CS 61A Rocks!'
        """
        def __init__(self, server, name):
            self.inbox = []
            self.server = server
            self.name = name
            server.register_client(self, name)

        def compose(self, msg, recipient_name):
            """Send an email with the given message msg to the
            given recipient client.
            """
            email = Email(msg, self.name, recipient_name)
            self.server.send(email)

        def receive(self, email):
            """Take an email and add it to the inbox of this
            client.
            """
            self.inbox.append(email)
    ```

- interators & generators
  - 一个比较清晰的解释：[python 中 yield 的用法详解——最简单，最清晰的解释_python yield_冯爽朗的博客-CSDN 博客](https://blog.csdn.net/mieleizhi0522/article/details/82142856)
  - 比较深入但是不清晰的 yield from：[深入理解 Python 中的 yield from 语法 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/267966140)
  - [一文彻底搞懂 Python 可迭代 (Iterable)、迭代器 (Iterator) 和生成器 (Generator) 的概念 - 掘金 (juejin.cn)](https://juejin.cn/post/6844903834381189127)
  - **iterable** 是一种 one by one 的数据类型，**iterator** 是真正接受存储在 iterable 中的值的对象。对 `iterable` 调用函数 `iter` 来生成 `iterator`，它将记录它在 `iterable` 中的位置
  - **generator** 是一种特殊的函数，它们用 **yield** 代替了 return，然后 one by one 地执行返回（返回后暂停并停在原地）。**yield from** 是一种将 generator 和 iterator 结合起来的语法，它用在 iterator 上，然后 yield 其中的每个值

- Q7: (Tutorial) Merge
Write a generator function merge that takes in two infinite generators a and b that are in increasing order without duplicates and returns a generator that has all the elements of both generators, in increasing order, without duplicates.

    ```py
    def merge(a, b):
        """
        >>> def sequence(start, step):
        ...     while True:
        ...         yield start
        ...         start += step
        >>> a = sequence(2, 3) # 2, 5, 8, 11, 14, ...
        >>> b = sequence(3, 2) # 3, 5, 7, 9, 11, 13, 15, ...
        >>> result = merge(a, b) # 2, 3, 5, 7, 8, 9, 11, 13, 14, 15
        >>> [next(result) for _ in range(10)]
        [2, 3, 5, 7, 8, 9, 11, 13, 14, 15]
        """
        is_done = False
        x = next(a)
        y = next(b)
        while not is_done:
            try:
                if x < y:
                    yield x
                    x = next(a)
                elif x == y:
                    yield x
                    x, y = next(a), next(b)
                else:
                    yield y
                    y = next(b)
            except StopIteration:
                is_done = True
    ```

### proj3: Ant
- 注意空列表的使用
    ```py
    lst = []
    print(lst == True) # False
    print(lst == None) # False
    if lst:
        print("typed")
    else:
        print("untyped") # untyped
    ```
- problem 8 好难
- optional 2 完全不会，抄网上代码明明一样的但是错的

***
## lecture 18: Special Object Methods
- `dir(object)` 返回对象的所有属性
- `repr(object)` 返回一个对象的字符串表示（可以转化为该对象的字符串），在交互式环境中输入一个对象时，实际上就是调用这个方法，对它使用 `eval()` 可以将其转化为对象（但不是同一个了）
- 当不确定对象是否有某个方法时，使用 `getattr(object, "name_of_method", False)`，如果不存在这个方法，会返回默认值 `False`，同时还有 `setattr()`
    - 事实上，我们每次使用 `object.something` 都在调用 `__getattribute` 方法
  - 上面说的那个方法还是不够方便，`hasattr(object, "name")` 更方便

### hw 05:
- 感觉很难的一题，看答案都想半天，自己肯定写不出来
    ```py
    def path_yielder(t, value):
        """Yields all possible paths from the root of t to a node with the label value
        as a list.

        >>> t1 = Tree(1, [Tree(2, [Tree(3), Tree(4, [Tree(6)]), Tree(5)]), Tree(5)])
        >>> print(t1)
        1
        2
            3
            4
            6
            5
        5
        >>> next(path_yielder(t1, 6))
        [1, 2, 4, 6]
        >>> path_to_5 = path_yielder(t1, 5)
        >>> sorted(list(path_to_5))
        [[1, 2, 5], [1, 5]]

        >>> t2 = Tree(0, [Tree(2, [t1])])
        >>> print(t2)
        0
        2
            1
            2
                3
                4
                6
                5
            5
        >>> path_to_2 = path_yielder(t2, 2)
        >>> sorted(list(path_to_2))
        [[0, 2], [0, 2, 1, 2]]
        """

        if t.label == value:
            yield [value]
        for b in t.branches:
            for path in path_yielder(b, value):
                yield [t.label] + path
    ```
- 注意 `len(lst)` 测量的是一阶
    ```py
    lst = [[1, 2], [3, 4]]
    print(len(lst)) # 2
    ```
- 注意 attribute 中，method 需要加括号

***
## lecture 19: Recursive Objects
- `'\n'.join(['Hi', 'how', 'are', 'you'])` 这个字符串方法将列表转化为字符串，用 `.` 的东西连接
- 用 OOP 的思想创建树和链表

## lecture 20: Complexity
- 基本上就是以前学过的复杂度

### DISC 07:
- Q5: (Tutorial) Multiply Lnks
Write a function that takes in a Python list of linked lists and multiplies them element-wise. It should return a new linked list.

If not all of the Link objects are of equal length, return a linked list whose length is that of the shortest linked list given. You may assume the Link objects are shallow linked lists, and that lst_of_lnks contains at least one linked list.

    ```py
    def multiply_lnks(lst_of_lnks):
        """
        >>> a = Link(2, Link(3, Link(5)))
        >>> b = Link(6, Link(4, Link(2)))
        >>> c = Link(4, Link(1, Link(0, Link(2))))
        >>> p = multiply_lnks([a, b, c])
        >>> p.first
        48
        >>> p.rest.first
        12
        >>> p.rest.rest.rest is Link.empty
        True
        """
        # Implementation Note: you might not need all lines in this skeleton code
        res = 1
        for link in lst_of_lnks:
            if link is Link.empty:
                return Link.empty
            res *= link.first
        next_links = [link.rest for link in lst_of_lnks]
        return Link(res, multiply_lnks(next_links))
    ```
- Q6: (Tutorial) Flip Two
Write a recursive function flip_two that takes as input a linked list s and mutates s so that every pair is flipped.挺有意思的一道题，每两个值翻转一次，抄来的那个实现更精妙

    ```py
    def flip_two(s):
        """
        >>> one_lnk = Link(1)
        >>> flip_two(one_lnk)
        >>> one_lnk
        Link(1)
        >>> lnk = Link(1, Link(2, Link(3, Link(4, Link(5)))))
        >>> flip_two(lnk)
        >>> lnk
        Link(2, Link(1, Link(4, Link(3, Link(5)))))
        """
        while s is not Link.empty:
            if s.rest is not Link.empty:
                s.first, s.rest.first = s.rest.first, s.first
                s = s.rest
            s = s.rest
        # while s and s.rest:
        #     s.first, s.rest.first = s.rest.first, s.first
        #     s = s.rest.rest
    ```
- Q8: (Tutorial) Find Paths
Hint: This question is similar to find_paths on Discussion 05.难度增强版，很难想说实话，看着答案也难想
Define the procedure find_paths that, given a Tree t and an entry, returns a list of lists containing the nodes along each path from the root of t to entry. You may return the paths in any order.
For instance, for the following tree tree_ex, find_paths should behave as specified in the function doctests.

    ```py
    def find_paths(t, entry):
        """
        >>> tree_ex = Tree(2, [Tree(7, [Tree(3), Tree(6, [Tree(5), Tree(11)])]), Tree(1, [Tree(5)])])
        >>> find_paths(tree_ex, 5)
        [[2, 7, 6, 5], [2, 1, 5]]
        >>> find_paths(tree_ex, 12)
        []
        """
        paths = []
        if t.label == entry:
            paths.append([t.label])
        for b in t.branches:
            for path in find_paths(b, entry):
                paths.append([t.label] + path)
        return paths
    ```

***
## Lecture 20: Memoization
- 用 $\theta$ 来表示下面代码中 `f` 被调用的次数和 `z < N` 的比较次数
    ```py
    z = 0
    for x in range(N):
        for y in range(N):
            while z < N:
                f(x, y, z)
                z += 1
    ```
  - 答案分别是 $\theta(N)$ 和 $\theta(N^2)$，注意这里 z 没有被清空 (a little tricky)
- count_coins 问题的解法，跟我以前想的不一样，现在我应该得要掌握两种方法了，一种累加，一种减少
    ```py
    def count_change(amount, coins = (50,25,10,5,1)):
        """Return the number of ways to make change for AMOUNT,where
        the coin denominations are given by COINS.
        """
        if amount == 0:
            return 1
        elif len(coins) == 0 or amount < 0: # allow amount to be minus
            return 0
        else:   # Ways with largest coin Ways without largest coin
            return count_change(amount - coins[0], coins) + count_change(amount, coins[1:])
    ```
  - 可以像斐波那契数列那样做一个字列表来优化，like below
    ```py
    def memoized_count_change(amount, coins = (50, 25, 10, 5, 1)):
        memo_table = {}
        def count_change(amount, coins):
            if (amount, coins) not in memo_table:
                memo_table[amount,coins] = full_count_change(amount, coins)
            return memo_table[amount,coins]
        def full_count_change(amount, coins):
            if amount == 0:
                return 1
            elif not coins:
                return 0
            elif amount >= coins[0]:
                return count_change(amount, coins[1:]) + count_change(amount-coins[0], coins)
            else:
                return count_change(amount, coins[1:])

        return count_change(amount,coins)
    ```
  - 使用字典的查询速度并不快，而且每次都要查询是否在字典中，优化如下
    ```py
    def count_change(amount, coins = (50, 25, 10, 5, 1)):
        # 0~50 (len(coins)+1) 种硬币，0~amount (amount+1) 种数量
        memo_table = [ [-1] * (len(coins)+1) for i in range(amount+1) ]
        def count_change(amount, coins):
            if memo_table[amount][len(coins)] == -1:
                raise RuntimeError("unfilled memo: {0}, {1}".format(amount,len(coins)))
            return memo_table[amount][len(coins)]
        def full_count_change(amount, coins):
            if amount == 0:
                return 1
            elif not coins:
                return 0
            elif amount >= coins[0]:
                return count_change(amount, coins[1:]) + count_change(amount - coins[0], coins)
            else:
                return count_change(amount, coins[1:])
        for a in range(0, amount+1):
            memo_table[a][0] = full_count_change(a, ())
        for k in range(1, len(coins)+1):
            for a in range(0, amount+1):
                memo_table[a][k] = full_count_change(a, coins[-k:])
        return count_change(amount, coins)
    ```
    - 有两点值得称道，一是将字典改为了二维列表，加快访问速度；二是存储方式以 amount 为先、coins 为次，保证每次计算新的值时，需要用到的旧的值都已经在列表中，顺序如下
        ![Alt text](./pictures/2.png)

***
## Lecture 22: Generics
- 格式化字符串的几种方法
- generic（泛型函数），一种可以对多种类型的对象进行操作的函数
- duck typing，在一个函数内基于它的行为（而不是类型）来使用任何类型的对象的能力
  - The duck test:"The parameter to this function must be a duck. If it looks like a duck and quacks like a duck, then we'll say it Is a duck!"
- python 鼓励你把所有东西变成 duck
  - 为此，我们可以定义方法中的 `__add__`、`__iadd__` 等来实现更宽广的适用范围
    ![Alt text](./pictures/3.png)

### lab 08:
Q2: Subsequences
A subsequence of a sequence S is a subset of elements from S, in the same order they appear in S. Consider the list [1, 2, 3]. Here are a few of it's subsequences [], [1, 3], [2], and [1, 2, 3].
Write a function that takes in a list and returns all possible subsequences of that list. The subsequences should be returned as a list of lists, where each nested list is a subsequence of the original input.
In order to accomplish this, you might first want to write a function insert_into_all that takes an item and a list of lists, adds the item to the beginning of each nested list, and returns the resulting list.

    ```py
    def insert_into_all(item, nested_list):
        """Return a new list consisting of all the lists in nested_list,
        but with item added to the front of each. You can assuming that
        nested_list is a list of lists.
        >>> nl = [[], [1, 2], [3]]
        >>> insert_into_all(0, nl)
        [[0], [0, 1, 2], [0, 3]]
        """
        return [[item] + lst for lst in nested_list]

    def subseqs(s):
        """Return a nested list (a list of lists) of all subsequences of S.
        The subsequences can appear in any order. You can assume S is a list.
        >>> seqs = subseqs([1, 2, 3])
        >>> sorted(seqs)
        [[], [1], [1, 2], [1, 2, 3], [1, 3], [2], [2, 3], [3]]
        >>> subseqs([])
        [[]]
        """
        if s == []:
            return [[]]
        else:
            rest = subseqs(s[1:])
            return rest + insert_into_all(s[0], rest)
    ```
- 加强版，更难，又不会做
    ```py
    def non_decrease_subseqs(s):
        """Assuming that S is a list, return a nested list of all subsequences
        of S (a list of lists) for which the elements of the subsequence
        are strictly nondecreasing. The subsequences can appear in any order.
        >>> seqs = non_decrease_subseqs([1, 3, 2])
        >>> sorted(seqs)
        [[], [1], [1, 2], [1, 3], [2], [3]]
        >>> non_decrease_subseqs([])
        [[]]
        >>> seqs2 = non_decrease_subseqs([1, 1, 2])
        >>> sorted(seqs2)
        [[], [1], [1], [1, 1], [1, 1, 2], [1, 2], [1, 2], [2]]
        """
        def subseq_helper(s, prev):
            if not s:
                return [[]]
            elif s[0] < prev:
                return subseq_helper(s[1:], prev)
            else:
                a = subseq_helper(s[1:], s[0])
                b = subseq_helper(s[1:], prev)
                return insert_into_all(s[0], a) + b
        return subseq_helper(s, 0)
    ```
  - 解释（但还是很难懂）
    - 基本思想：用一个 help 函数记录先前的值，如果当前的是 s[0] 比他小这个是 s[0] 就不加入排列中，然后如果大的话就两种情况，一种是加入一种是不加入。
    - subseq_helper 函数有两个参数：列表 s 和上一个元素的值 prev。如果列表 s 为空，则返回一个包含空列表的列表 `[[]]` 作为基本情况。否则，函数会根据当前元素和 prev 的值进行判断：
    - 如果当前元素小于 prev，则调用 subseq_helper 函数并跳过当前元素，继续递归处理剩余部分的序列。
    - 如果当前元素大于等于 prev，则分别调用 subseq_helper 函数来处理同时跳过和保留当前元素的两个情况，并将两个递归结果合并起来。
    - 合并的方法是调用 insert_into_all 函数，将当前元素插入到递归结果的每个子序列的开头。
- Q4: Number of Trees
A full binary tree is a tree where each node has either 2 branches or 0 branches, but never 1 branch.
Write a function which returns the number of unique full binary tree structures that have exactly n leaves.
For those interested in combinatorics, this problem does have a closed form solution   这题又好难，又是想不到

    ```py
    def num_trees(n):
        """Returns the number of unique full binary trees with exactly n leaves. e.g.
        1   2        3       3    ...
        *   *        *       *
        / \      / \     / \
        *   *    *   *   *   *
                / \         / \
                *   *       *   *
        >>> num_trees(1)
        1
        >>> num_trees(2)
        1
        >>> num_trees(3)
        2
        >>> num_trees(8)
        429
        """
        if n == 1 or n == 2:
            res = 1
        else:
            res = 0
            for i in range(1, n):
                res += num_trees(n - i) * num_trees(i)
        return res
    ```
- Q14: Long Paths
Implement long_paths, which returns a list of all paths in a tree with length at least n. A path in a tree is a list of node labels that starts with the root and ends at a leaf. Each subsequent element must be from a label of a branch of the previous value's node. The length of a path is the number of edges in the path (i.e. one less than the number of nodes in the path). Paths are ordered in the output list from left to right in the tree. See the doctests for some examples. 挺难的

    ```py
    def long_paths(t, n):
        """Return a list of all paths in t with length at least n.

        >>> long_paths(Tree(1), 0)
        [[1]]
        >>> long_paths(Tree(1), 1)
        []
        """
        if n <= 0 and t.is_leaf():   # 转换思维，n 代表还需要多少才能输出
            return [[t.label]]
        paths = []
        for b in t.branches:
            for path in long_paths(b, n - 1):
                paths.append([t.label] + path)
        return paths
    ```

***
## Lecture 23: Fun with Iterables
- 概念联系图
    ![Alt text](./pictures/4.png)
- 这节课围绕 iter 等相关概念讲了很多杂七杂八的内容，算是复习课

### mid_term 2:
- Q8: Implement word_finder, a generator function that yields each word that can be formed by following a path in a tree from the root to a leaf, where the words are specified in a list. When given the tree shown in the diagram below and a word list that includes ‘SO’ and ‘SAW’, the functionshould first yield ‘SO’ and then yield ‘SAW’.
Please read through the function header and doctests below. We have provided quite a few doctests to test different situations and demonstrate how the function should work. You can always call draw(t) on a particular tree object on code.cs61a.org to help you visualize its structure and understand the results of a doctest. 很难想

    ```py
    def word_finder(letter_tree, words_list):
        """ Generates each word that can be formed by following a path in TREE_OF_LETTERS from the root to a leaf,
        where WORDS_LIST is a list of allowed words (with no duplicates).
        >>> words = ['SO', 'SAT', 'SAME', 'SAW', 'SOW']
        >>> t = Tree("S", [Tree("O"), Tree("A", [Tree("Q"), Tree("W")]), Tree("C", [Tree("H")])])
        >>> gen = word_finder(t, words)
        >>> next(gen)
        'SO'
        >>> next(gen)
        'SAW'
        >>> list(word_finder(t, words))
        ['SO', 'SAW']
        >>> t = Tree("S", [Tree("I"), Tree("A", [Tree("Q"), Tree("E")]), Tree("C", [Tree("H")])])
        >>> list(word_finder(t, words))
        []
        >>> t = Tree("S", [Tree("O"), Tree("O")] )
        >>> list(word_finder(t, words))
        ['SO', 'SO']
        >>> words = ['TAB', 'TAR', 'BAT', 'BAR', 'RAT']
        >>> t = Tree("T", [Tree("A", [Tree("R"), Tree("B")])])
        >>> list(word_finder(t, words))
        ['TAR', 'TAB']
        >>> words = ['A', 'AN', 'AH']
        >>> t = Tree("A")
        >>> list(word_finder(t, words))
        ['A']
        >>> words = ['A', 'AN', 'AH']
        >>> t = Tree("A", [Tree("H"), Tree("N")])
        >>> list(word_finder(t, words))
        ['AH', 'AN']
        >>> words = ['GO', 'BEARS', 'GOB', 'EARS']
        >>> t = Tree("B", [Tree("E", [Tree("A", [Tree("R", [Tree("S")])])])])
        >>> list(word_finder(t, words))
        ['BEARS']
        >>> words = ['SO', 'SAM', 'SAT', 'SAME', 'SAW', 'SOW']
        >>> t = Tree("S", [Tree("O"), Tree("A", [Tree("Q"), Tree(1)]), Tree("C", [Tree(1)])])
        >>> gen = word_finder(t, words)
        >>> next(gen)
        'SO'
        >>> try:
        ...     next(gen)
        ... except TypeError:
        ...     print("Got a TypeError!")
        ... else:
        ...     print("Expected a TypeError!")
        Got a TypeError!
        """
        def word_finder(letter_tree, words_list):
            def string_builder(t, str):
                str += t.label
                if t.is_leaf() and str in words_list:
                    yield str
                for b in t.branches:
                    yield from string_builder(b, str)
            yield from string_builder(letter_tree, "")
    ```

***
## Lecture 24:Scheme
- 一个对我来说全新的语言，它是 Lisp 的一种方言，而 Lisp 是至今第二老的语言，怎么感觉有点过时了（
- 学它的意义应该是掌握一种完全不同的思维方法，称为 functional programming language。Scheme features first-class functions and optimized tail-recursion
- Scheme 把数据分成了 atoms 和 pairs 两种，这叫做 symbolic data，然后复杂一点的数据用 lists 表示 (pairs & lists)
- （OP E1 ... En）采用前缀表达式，本来就是树的形式
- `quote` does not simply evaluate operands，如 `scm> (quote (+ 1 2))`，可以简写为 `scm> '(+ 1 2)`
- 类似的 OP 还有 `if`、`and`、`or`、`not`、`lambda`、`define`、`cond`、`quotient` 等
- `quotient` 表示整除（注意不是 quote 相关的东西），是向 0 四舍五入，而不像 python 向负无穷
- `cons` 创建链表，`car` 取链表的第一个值，`cdr` 取链表的第二个值
- OP `=` works for numbers only，`eqv?` 范围更广，`eq?` 跟 python 中 `is` 一样，`equal?` 类似 `eq?` 但允许 pairs 的深度比较
- Scheme 中的 iter 可以写成 recursion 的形式，而且它的 tail recursion 是不会创建堆栈的，可以称为 tail recursion removal
- 如果有不清晰的地方可以看 lab10 任务前的 toturial：https://inst.eecs.berkeley.edu/~cs61a/sp21/lab/lab10/

### lab 10 & hw 06:
- 关于 scheme 中的 list
  - 我很疑惑 `(1 2 3)` 和 `(1 2 (3))` 有什么不同，以及 `scm> (list 1 (list 2 3) 4)     (1 (2 3) 4)` 这种结构是怎么实现的
  - 对此问了 GPT，纯一派胡言
  - 后来想了想，应该是用了 `quote`
- `define` 语句，`(define <name> <expression>)` 和 `(define (<name> <param1> <param2> ...) <body>)`，后者是 `define` 和 `lambda` 语句合用的简化
- `filter`,The filter procedure takes a predicate procedure and a list as arguments,and returns a new list containing only the elements for which the predicate returns true

***
## Lecture 25: Scheme Examples
- 回顾 python 中的 iteration 和 tail recursion，很大一部分（几乎所有？）的前者都可以转化为后者，而后者又可以方便地转化为 Scheme 中的递归
- 这里的 `append` 就像 python 中的 `extend`，不过是用于 linked list
- map、reverse 等函数在 scheme 中的实现
- Tree 在 scheme 中的实现，很烧脑，它是用 `quote` 实现树的层次的，数据的连接本身用了 linked list，这样就变成嵌套再嵌套（横向）、`quote` 再 `quote`（纵向）的感觉

### DICS 10:
-  List Concatenation
Write a function which takes two lists and concatenates them.
Notice that simply calling (cons a b) would not work because it will create a deep list. Do not call the builtin procedure append, since it does the same thing as list-concat should do.
    ```scheme
    (define (list-concat a b)
    (if (null? a)
        b
        (cons (car a) (list-concat (cdr a) b))))
    ```
- 比价下面两种表达，哪个创建了一个 procedure
    ```
    (define x (+ 1 2 3))
    (define (x) (+ 1 2 3))
    ```

***
## Lecture 26: Calculator
- Parse, takes text and returns an expression
  - 输入一段文本，用 Tokenizer（分词器）将其转化为 tokens（令牌），在进一步转化为树的表达式
- 大概理解了做一个 scheme 编译器的思路，因为 scheme 的语言特性，所有东西都是数据，因此不像别的程序需要做程序，它只需要读入，拆解成可以理解的形式，然后疯狂计算，输出。这里我们选择将其转化为 python 的格式，相当于是用 python 做的伪编译器？

***
## Lecture 27: interpreters
- 这节课听不懂一点
  - 后面的 lab 也做不动，对编译器一点兴趣没有
- `begin E1 E2 ... En` 依次计算 `Ei` 然后返回 `En` 作为其返回值
- `let`，局部赋值，跟 `define` 相比，后者是全局赋值且有定义函数的特殊用法
- tail-call optimization，减少调用栈

***
## Lecture 28: Undecidabilty
- 是否存在程序能够准确判定另一段程序在任意的输入下是否无限？答案是否
- 感觉有点像自指，这里称为咬尾
    ![Alt text](./pictures/5.png)
- 后面讲到了哥德尔定理，不过我没听了

### DISC 11:
- Scheme 里的 tree
    ```scheme
    (define (make-tree label branches) (cons label branches))
    (define (label tree)
        (car tree)
    )
    (define (branches tree)
        (cdr tree)
    )
    (define (tree-sum tree)
        (+ (label tree) (sum (map tree-sum (branches tree))))
    )
    (define (sum lst)
        (if (null? lst)
            0
            (+ (car lst) (sum (cdr lst)))))
    ```

***
## Lecture 29: Macros（宏）
- 首先讲了 C 语言中的宏，但是 Scheme（或者说 Lisp）中的宏大不一样
- Macros 先不计算它们的参数，但将返回值视为 scheme 表达式并自动计算
- `` ` `` 反引号，和 `,`、`@` 配合，如果里面没有那些东西，那它基本就和普通引号一样
    ![Alt text](./pictures/6.png)
    ![Alt text](./pictures/7.png)
  - 有点像 f-string
- 现在，我们可以将二者连用，定义 `unless` 的宏，用来偷懒（bushi
    ![Alt text](./pictures/8.png)
  - 一个比较复杂的例子
    ![Alt text](./pictures/9.png)
  - 这里解释一下，用的是常见的尾递归循环，传入 `high` 作为控制变量，每次减一，`so-far` 是已经处理的链表；这里之所以要把 `low` 重新赋值，是因为避免 `low` 如果是一个表达式的话在循环中多次计算（而 `high` 作为控制变量也算是重新赋值了一遍，只会算一次）。另外，为什么要重定义成加 `$` 符号呢？因为我们不想使用外部变量，也不想外部访问这里的内部变量避免错误
- 基本上，在 C 语言中我们只是用宏来做基本的文本替换减少重复，但在 Scheme 中，宏与反引号的配合使得宏成为一个能够拓展语法的更强大的存在

***
## Lecture 30: Declarative Programming（声明式编程）
- 过去我们做的都是命令式 (imperative) 编程
- relations,not functions
- 好骚的编程方式

### Lab 12:
- 宏定义经典用法
    ```scheme
    (define-macro (def func args body)
        `(define (,func ,@args) ,body)
    )
    ```
- 天才！用 let 递归
    ```scheme
    (define (repeatedly-cube n x)
    (if (zero? n)
        x
        (let ((y (repeatedly-cube (- n 1) x)))
            (* y y y))))
    ```

***
## Lecture 31: Regular Expressions
- Pattern Matching，我们经常需要跟字符串打交道，查找里面是否有匹配的 substring 然后做什么操作。通常的想法是，例如，在看到 `(` 后找 `)`，但我们也可以用 declarative programming 的思想来思考这个问题，这延展出 regular expressions（正则表达式）的概念
- python 中，正则表达式一般使用 raw-string 来避免 `\` 问题
- special characters:`\ () [] {} + * ? | $ ^ .`，除了它们之外的字符按照字面意思匹配，如果需要使用这些特殊字符，用 `\`（这也是为什么需要 r-string，避免两种含义的 `\` 混淆冲突）
  - `[]` 匹配其中的一个字符，其中 `-` 表示范围，`^` 表示反向（不匹配）
- `. \d \s \S \w \W` 等单字符匹配
- `P1P2 P* P+ P? P1|P2` 等匹配模式，有优先级，可以用 `()` 括起来
- `^ $ \b \B` 等 anchors
- Matching methods: re.fullmatch、re.match、re.search、re.finditer、re.sub 等
- `()` 有两种用处，一种是匹配模式的优先级，一种是 `.group()` 检索
- 好复杂，听不懂，知道在干什么，但看不懂具体在做什么

### DISC 12:
- Making Python Macro
- python 正常来说没有宏定义的功能，但是通过 f-string 和 `eval()` 我们可以达成类似的效果，如下
    ```py
    def make_lambda(params, body):
        """
        >>> f = eval(make_lambda("x, y", "x + y"))
        >>> f
        <function <lambda>>
        >>> f(1, 2)
        3
        >>> g = eval(make_lambda("a, b, c", "c if a > b else -c"))
        >>> g(1, 2, 3)
        -3
        >>> eval(make_lambda("f, x, y", "f(x, y)"))(f, 1, 2)
        3
        """
        return f"lambda {params}: {body}"

    def if_macro(condition, true_result, false_result):
        """
        >>> eval(if_macro("True", "3", "4"))
        3
        >>> eval(if_macro("0", "'if true'", "'if false'"))
        'if false'
        >>> eval(if_macro("1", "print('true')", "print('false')"))
        true
        >>> eval(if_macro("print('condition')", "print('true_result')", "print('false_result')"))
        condition
        false_result
        """
        if eval(f"{condition}"):
            return f"{true_result}"
        else:
            return f"{false_result}"
    ```

- scheme define 和 define-macro 的区别，看代码就知道了
```scheme
(define (if-function condition if-true if-false)
    `(if ,condition ,if-true ,if-false)
)

;scm> (if-function '(= 0 0) '2 '3)
;(if (= 0 0) 2 3)
;scm> (eval (if-function '(= 0 0) '2 '3))
;2

(define-macro (if-macro condition if-true if-false)
  `(if ,condition ,if-true ,if-false)
)

;scm> (if-macro (= 0 0) 2 3)
;2
```

***
## Lecture 32: BNF
- Describing Language Syntax: BNF(Backus-Naur-Form)
- 定义说起来蛮复杂，实际上还算简单，举个例子
    ![Alt text](./pictures/10.png)
- Extended BNF(EBNF)，BNF 的扩展，不比 BNF 高级但方便
- Syntax Tree
    ![Alt text](./pictures/11.png)
- 说实话，跟上节课一样，有点听不懂
- 视频推荐让看这个，但说实话看不太懂

### hw 09:
- Define the macro switch, which takes in an expression expr and a list of pairs, cases, where the first element of the pair is some value and the second element is a single expression. switch will evaluate the expression contained in the list of cases that corresponds to the value that expr evaluates to.
You may assume that the value expr evaluates to is always the first element of one of the pairs in cases. You can also assume that the first value of each pair in cases is a value.
```scheme
scm> (switch (+ 1 1) ((1 (print 'a))
                      (2 (print 'b))
                      (3 (print 'c))))
;;b
```
```scheme
(define-macro (switch expr cases)
	(cons _________
		(map (_________ (_________) (cons _________ (cdr case)))
    			cases))
)

(define-macro (switch expr cases)
  (cons 'cond
        (map (lambda (case)
               (cons `(eqv? ,expr ',(car case)) (cdr case)))
             cases)))

; ; 测试代码
(switch (+ 1 1)
        ((1 (print 'a)) (2 (print 'b)) (3 (print 'c)))
)

```
- 很 jb 难，完全想不到，首先 cases 是一个列表，我们可以用 map 对其中的每一项 (设作 case) 做操作，这个操作用匿名函数来完成，对每个 case 比较后组成新的列表给 cond 用，相当于又做了一个 cases，只不过这个 cases 中的 case 的 car 重新设定成了我们需要的表达式

***
## Lec 33: Review: Regular Expressions + BNF
- 正则表达式某项之后加 `{n}` 来指定次数，`{n, m}` 指定 n 到 m 次，`{n,}` 指定 n 次以上
- BNF 听不懂

## lab 13:
- 可以看看 lab 中的总结：[Lab 13: Regular Expressions, BNF | CS 61A Spring 2021 (berkeley.edu)](https://inst.eecs.berkeley.edu/~cs61a/sp21/lab/lab13/)
- 注意 `{}` 是属于 quantifier 一类的，表示 match 的次数
- `^` 在 `[]` 内表示反取（不取），在外则表示 match 开头

***
## DISC 13:
- macro 的复习：[Discussion 13 | CS 61A Spring 2021 (berkeley.edu)](https://inst.eecs.berkeley.edu/~cs61a/sp21/disc/disc13/)
- Write a macro that takes an expression expr and a number n and repeats the expression n times. For example, (repeat-n expr 2) should behave the same as (twice expr) from the introduction section of this worksheet. It's possible to pass in a combination as the second argument (e.g. (+ 1 2)) as long as it evaluates to a number. Be sure that you evaluate this expression in your macro so that you don't treat it as a list.
Complete the implementation for repeat-n so that its behavior matches the doctests below.
You may find it useful to implement the replicate procedure, which takes in a value x and a number n and returns a list with x repeated n times.
注意比对，其实我也不太清楚为什么我的实现不行
```scheme
(define (replicate x n)
  (if (zero? n)
      '()
      (cons x (replicate x (- n 1)))))

;;wrong
(define macro (repeat-n expr n)
  `(replicate ,expr ,n)
)

;;right
(define-macro (repeat-n expr n)
  `(begin ,@(replicate expr (eval n)))
)
```
- 在这里查看 scheme built-in function：[Scheme Built-In Procedure Reference | CS 61A Spring 2021 (berkeley.edu)](https://inst.eecs.berkeley.edu/~cs61a/sp21/articles/scheme-builtins/)
- Q3: List Comprehensions
Recall that list comprehensions in Python allow us to create lists out of iterables:
`[<map-expression> for <name> in <iterable> if <conditional-expression>]`
Define a procedure to implement list comprehensions in Scheme that can create lists out of lists. Specifically, we want a list-of macro that can be called as follows:
`(list-of <map-expression> 'for <name> 'in <list> 'if <conditional-expression>)`
The symbols for, in, and if must be quoted when calling list-of so that they will not be evaluated. The program will error if they have not been previously defined.
Calling list-of will return a new list constructed by doing the following for each element in `<list>`:
Bind `<name>` to the element.
If `<conditional-expression>` evaluates to a truth-y value, evaluate `<map-expression>` and add it to the result list.
看起来难，其实还是简单的
```scheme
(define (list-of map-expr for var in lst if filter-expr)
  `(map (lambda (,var) ,map-expr) (filter (lambda (,var) ,filter-expr) ,lst))
)

;;下一题
(define-macro (list-of map-expr for var in lst if filter-expr)
  (begin `(map (lambda (,var) ,map-expr) (filter (lambda (,var) ,filter-expr) ,lst)))
)
```

***
## Lec 35: introduction to SQL
- database 存储数据表
  - 数据表的 id 位唯一，其他都可变
  - 表示数据表之间关系的数据表
- SQL 是声明式语言，感觉有点像高中技术
- 这门课介绍的是 SQLite，SQL 的方言
- SQL 从 1 开始
- transction 概念，避免改了一个没改其它的时发生错误

### Lab 14:
- Implement split-at, which takes a list lst and a non-negative number n as input and returns a pair new such that (car new) is the first n elements of lst and (cdr new) is the remaining elements of lst. If n is greater than the length of lst, (car new) should be lst and (cdr new) should be nil.
很难，根本想不出来
```scheme
(define (split-at lst n)
  (if (or (null? lst) (= n 0))
      (cons '() lst)
      (let ((res (split-at (cdr lst) (- n 1))))
        (cons (cons (car lst) (car res)) (cdr res)))))
```
- Q3: Compose All
Implement compose-all, which takes a list of one-argument functions and returns a one-argument function that applies each function in that list in turn to its argument. For example, if func is the result of calling compose-all on a list of functions (f g h), then (func x) should be equivalent to the result of calling (h (g (f x))).
其实挺简单，但是不会做……
```scheme
(define (compose-all funcs)
  (if (eq? nil funcs)
      (lambda (x) x)
      (let ((first-func (car funcs))
            (rest-funcs (cdr funcs)))
        (lambda (x) ((compose-all rest-funcs) (first-func x)))
      )
  )
)
```
- Q4: Num Splits
Given a list of numbers s and a target difference d, how many different ways are there to split s into two subsets such that the sum of the first is within d of the sum of the second? The number of elements in each subset can differ.
You may assume that the elements in s are distinct and that d is always non-negative.
Note that the order of the elements within each subset does not matter, nor does the order of the subsets themselves. For example, given the list [1, 2, 3], you should not count [1, 2], [3] and [3], [1, 2] as distinct splits.
- 挺难的，我不会，需要创建辅助函数，用树递归遍历 `2^n` 种情况
```py
def num_splits(s, d):
    length = len(s)
    res = 0
    def helper(first, second, index):
        nonlocal res
        if index == length:
            if abs(first - second) <= d:
                res += 1
            return
        else:
            helper(first + s[index], second, index + 1)
            helper(first, second + s[index], index + 1)
    helper(0, 0, 0)
    return res // 2
```
- Q6: Align Skeleton
Have you wondered how your CS61A exams are graded online? To see how your submission differs from the solution skeleton code, okpy uses an algorithm very similar to the one below which shows us the minimum number of edit operations needed to transform the the skeleton code into your submission.
Similar to pawssible_patches in Cats, we consider two different edit operations:
    1. Insert a letter to the skeleton code
    2. Delete a letter from the skeleton code
Given two strings, skeleton and code, implement align_skeleton, a function that minimizes the edit distance between the two strings and returns a string of all the edits. Each addition is represented with +[], and each deletion is represented with -[]. For example:
```py
>>> align_skeleton(skeleton = "x=5", code = "x=6")
'x=+[6]-[5]'
>>> align_skeleton(skeleton = "while x<y", code = "for x<y")
'+[f]+[o]+[r]-[w]-[h]-[i]-[l]-[e]x<y'
```
In the first example, the +[6] represents adding a "6" to the skeleton code, while the -[5] represents removing a "5" to the skeleton code. In the second example, we add in the letters "f", "o", and "r" and remove the letters "w", "h", "i", "l", and "e" from the skeleton code to transform it to the submitted code.
```py
def align_skeleton(skeleton, code):
    skeleton, code = skeleton.replace(" ", ""), code.replace(" ", "")  # remove all the whitespaces
    def helper_align(skeleton_idx, code_idx):
        if skeleton_idx == len(skeleton) and code_idx == len(code):
            return "", 0
        if skeleton_idx < len(skeleton) and code_idx == len(code):
            edits = "".join(["-[" + c + "]" for c in skeleton[skeleton_idx:]])
            return edits, len(skeleton) - skeleton_idx
        if skeleton_idx == len(skeleton) and code_idx < len(code):
            edits = "".join(["+[" + c + "]" for c in code[code_idx:]])
            return edits, len(code) - code_idx

        possibilities = []
        skel_char, code_char = skeleton[skeleton_idx], code[code_idx]
        # Match
        if skel_char == code_char:
            edits, cost = helper_align(skeleton_idx + 1, code_idx + 1)
            edits = skeleton[skeleton_idx] + edits  # no change, choose skeleton or code are all right
            possibilities.append((edits, cost))
        # Insert
        edits, cost = helper_align(skeleton_idx, code_idx + 1)
        # edits = f"+[{code[code_idx]}]" + edits
        # possibilities.append((edits, cost))
        prefix = f"+[{code[code_idx]}]"
        possibilities.append((prefix + edits, cost + 1))
        # Delete
        edits, cost = helper_align(skeleton_idx + 1, code_idx)
        # edits = f"-[{skeleton[skeleton_idx]}]" + edits
        # possibilities.append((edits, cost))   # 为啥我的不行？？？
        prefix = f"-[{skeleton[skeleton_idx]}]"
        possibilities.append((prefix + edits, cost + 1))
        return min(possibilities, key=lambda x: x[1])
    result, cost = helper_align(0, 0)
    return result
```
- Fold Left、Fold Right、Filter With Fold、Reverse With Fold、Fold With Fold，后三个较难
```py
def foldl(link, fn, z):
    if link is Link.empty:
        return z
    z = fn(z, link.first)
    return foldl(link.rest, fn, z)

def foldr(link, fn, z):
    if link is Link.empty:
        return z
    else:
        return fn(link.first, foldr(link.rest, fn, z))

def filterl(lst, pred):
    # res = lst
    # while lst is not Link.empty and lst.rest is not Link.empty:
    #     if not pred(lst.rest.first):
    #         lst.rest = lst.rest.rest
    #     lst = lst.rest
    # if (lst is not Link.empty and not pred(lst.first)):
    #     lst.rest = Link.empty
    # return res
    return foldr(lst, lambda x, y: Link(x, y) if pred(x) else y, Link.empty)

def reverse(lst):
    return foldl(lst, lambda x, y: Link(y, x), Link.empty)   # 妙啊

identity = lambda x: x

def foldl2(link, fn, z):
    def step(x, g):
        return lambda t: fn(g(t), x)
    return foldr(link, step, identity)(z)
```

***
## Lecture 38: Conclusion
- What can you do with Python?
  - Almost anything! Thanks to libraries!
  1. Webapp backends (Flask, Django)
  2. Web scraping (BeautifulSoup)
  3. Natural Language Processing (NLTK)
  4. Data analysis (Numpy, Pandas, Matplotlib)
  5. Machine Learning (FastAi, PyTorch, Keras)
  6. Scientific computing (SciPy)
  7. Games (Pygame)
  8. Procedural generation - L Systems, Noise, Markov

<h3 style="font-size: value;"> <center>完结撒花~~~</center> </h3>