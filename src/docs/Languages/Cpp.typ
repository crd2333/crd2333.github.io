#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Cpp 笔记",
  lang: "zh",
)

= Cpp+ 笔记
== Cpp 面向对象
=== 关键字 this
- 感觉上跟 python 中的 self 差不多，只不过是隐式的指针常量
  - 可以看看这两篇文章比较一下区别: #link("https://www.cnblogs.com/douzi2/p/5579608.html")[C++中的this和Python的self对比 - 宋桓公 - 博客园 (cnblogs.com)]、#link("https://muyuuuu.github.io/2022/05/12/Cpp-this-and-python-self/")[C++ 中的 this 和 Python 中的 self | Just for Life. (muyuuuu.github.io)]
- `const` 修饰的成员函数实际上是对 `this` 加 `const` 修饰，变为 ```cpp const 类名 *const this```

=== 静态成员 static
- 可以对函数也可以对变量，用 static 修饰后会使得这个成员变成类似 python 中的类变量，使得类也能调用这个成员（当然实例也还是可以，只不过共用了）
- 注意对静态成员函数而言，没有 this 这个关键字，因为是对类（或者说所有实例）而言，那 this 就失去意义；而且静态成员只能访问同样的静态成员变量和静态成员函数，因为如果是对类调用时没有实例给你访问
- static
#tlt(
  columns: 2,
  [Static free functions],
  [#strike[Internal linkage] (deprecated)],
  [Static global variables],
  [#strike[Internal linkage] (deprecated)],
  [Static local variables],
  [Persistent storage],
  [Static member variables],
  [Shared by all instances],
  [Static member function],
  [Shared by all instances,can only access static member variables],
)
- A non-local static object is:
  + defined at global or namespace scope
  + declared static in a class
  + defined static at file scope
  - Order of construction 在一个文件内是确定的，但在多个文件时是不确定的，因此 non-local static object 可能引发问题
  - 解决方法是：拒绝 non-local static object，或者把这种都放在一个文件中，以免发生意料外的情况

=== 成员函数 Menber Function
==== 构造函数 & 析构函数 Constructors & Destructors <构造函数和析构函数>
- #link("https://www.runoob.com/cplusplus/cpp-constructor-destructor.html")[C++ 类构造函数 & 析构函数 | 菜鸟教程 (runoob.com)]
- 类构造函数
  - 它需要被放在 public 中；不加 `void`、`int` 等返回类型；名字和类名相同。它可以用于为某些成员变量设置初始值（即初始化），并做一些操作比如输出初始化信息等。可以带参数，且可以配合成员初始化列表来使用
  - 成员初始化列表 (Member Initialization List)：用于初始化类的成员变量
  - 成员初始化列表和普通的类构造函数的区别在于：性能，以及对 const 变量、引用变量的处理。总之能用初始化列表就用初始化列表
  - 注意按照声明的顺序初始化，而不是按照 list 里的顺序，否则将导致不可预测的结果 (ub!)，销毁的顺序则是相反的
  - 参考：#link("https://zhuanlan.zhihu.com/p/386604081")[C++成员初始化列表 - 知乎 (zhihu.com)]、#link("https://www.cnblogs.com/BlueTzar/articles/1223169.html")[C++类构造函数初始化列表 - BlueTzar - 博客园 (cnblogs.com)]

- 类析构函数
  - 它需要被放在 public 中；不加 `void`、`int` 等返回类型；名字和类名相同，前面带一个`~`；不能带参数。它会在每次删除所创建的对象时执行并释放资源，也可以同时做一些操作比如输出删除信息等

- Constructor 不能修饰为 virtual，而 Destructor 可以（而且更应该，如果它为基类的话）；Constructor 能被 overloaded，而 Destructor 不能

- 拷贝构造函数（复制构造函数，Copy Constructor）
  - 用于从一个已有的对象创建新的类对象。它需要被放在 public 中；不加 `void`、`int` 等返回类型；名字和类名相同。那如何与类构造函数区分呢？答案是参数，用对象的常量引用（否则用值传递会出现递归调用问题）
  - 语法 ```cpp T(const T& w) {...}```
  - 如果类的设计者不写复制构造函数，编译器就会自动生成复制构造函数。大多数情况下，其作用是实现从源对象到目标对象逐个字节的复制，即使得目标对象的每个成员变量都变得和源对象相等。编译器自动生成的复制构造函数称为“默认复制构造函数”
  - 注意，默认构造函数（即无参构造函数）不一定存在（程序员写了就不会自动生成），但是复制构造函数总是会存在。一般默认复制构造函数也能工作得很好，但在涉及指针的时候需要小心 (shallow or deep copy)
  - 拷贝构造函数常见于三种情况：直接从一个对象创建并初始化另一个对象、函数创建形参需要复制一个对象、函数返回对象需要复制一个对象
  - copy constructor 在返回值时的调用与否
    ```cpp
    Person copy_func(char *who) {
        Person local(who);
        local.print();
        return local; // copy ctor called!
    }
    Person nocopy_func(char *who) {
        return Person(who);
    } // no copy needed!
    ```

- 委托构造函数
  - 委托构造函数使得部分初始化的代码更加简洁
  - 使用了委托构造函数就不能在初始化列表中初始化其它成员。这种情况下可以用一个私有的构造函数实现目的，通过私有保证平时访问不到它
    ```cpp
    class MyClass {
    private:
        int a, b;
        // 私有构造函数，用于初始化所有成员
        MyClass(int a, int b) : a(a), b(b) {}
    public:
        // 公有构造函数，委托给私有构造函数
        MyClass(int a) : MyClass(a, 0) {}
        // 公有构造函数，委托给私有构造函数
        MyClass() : MyClass(0, 0) {}
    };
    ```

- 移动构造函数，见 @左值引用和右值引用 移动语义部分

=== 友元函数 Friend Function
- 是定义在类外部，但有权访问类的所有私有(private)成员和保护(protected)成员。尽管友元函数的原型有在类的定义中出现过，但是友元函数并不是成员函数
- 友元也可以是一个类，该类被称为友元类，在这种情况下，整个类及其所有成员都是友元
  ```cpp
  public:
    friend void friend_func(classname obj);
  ```

==== 类成员函数的修饰符
- 有以下这些：
  - const, override, final, static, virtual, friend
- const 修饰
  - `void print() const;` 类成员函数的声明语法，下面简称为常函数
  - `const` 表示约定了不会在函数中修改对象（不要错误理解为成员函数是常量），并且通过引用、指针返回的值也是常量（实际上这个 `const` 是加在了 `this` 上）
    - 但也有例外，用 `mutable` 修饰的成员变量可以在常函数中修改
  - 另外，const 对象只能调用常函数，而不能调用非常函数
    ```cpp
    class A {
    public:
        A(int x) : val(x) {}
        // 不能注释，否则 const 对象没有 print() 函数
        void print() const { cout << "const " << val << endl; }
        // 可以注释掉，都用上面那个
        void print() { cout << "no const " << val << endl; }
    private:
        int val;
    };
    int main() {
        A ob1(1);
        const A ob2(2);
        ob2.print();
        ob1.print();
    }
    ```

=== 继承与多态 Inheritance & Polymorphism
==== 继承
- 类之间可以继承，被继承的叫做*基类（父类）*，继承的叫做*派生类（子类）*
- 基类可以是一个或多个，需要指定修饰符以指定继承方式(public, protected, private)
  - 公有继承(public): public $arrow.r$ public, protected $arrow.r$ protected, private $arrow.r$ unavailable(can indirectly)
  - 保护继承(protected): public, protected $arrow.r$ protected
  - 私有继承(private): public, protected $arrow.r$ private
  - 总而言之，同一个类可以访问自己的 public, protected, private；派生类不能访问 private；外部类不能访问 protected, private
- 这些特殊成员不能被继承：基类的构造函数（这个好像不太对）、析构函数和拷贝构造函数；基类的重载运算符；基类的友元函数

- [ ] 虚继承和虚基类，参考 #link("https://zhuanlan.zhihu.com/p/342271992")[C++虚继承和虚基类详解]

- Upcast 与 Return types relaxation
  - 当把派生类的指针或引用赋给基类的指针或引用时，称为 upcast
  ```
  Manager pete( "Pete", "444-55-6666", "Bakery");
  Employee* ep = &pete; // Upcast
  Employee& er = pete;  // Upcast
  ```
  - Return types relaxation 类似

- 继承中的构造、析构顺序
  - 一个自己编的构造函数和初始化列表和析构函数和派生类的例子
    ```cpp
    class C {
    public:
        C() { cout << 8; }
        ~C() { cout << 9; }
    };
    class A {
    private:
        int x;
    public:
        A () { cout << 0; }
        A(int x) : x(x) { cout << 1; }
        A(A& a) { cout << 2; }
        ~A() { if (x == 0) cout << 3; else cout << 4;}
        void set_x(int x) { this->x = x; cout << 5; }
    };
    class B : public A {
    private:
        C c;
        A a;
    public:
        B() : a(1) {
            cout << 6;
            A a(3);
        }
        ~B() {
            // 这里 A, c, a 还没被析构
            cout << 7;
        } // 这里 a, c, A 先后被析构
    };

    int main() {
        B b;
        return 0; // 0816147493
    }
    ```

- Inheritance 中的覆盖与重定义
  - 当在派生类中定义了与基类同名的函数，基类的函数（包括重载）会被隐藏
  - virtual 关键字会改变这一行为，这就是多态

==== 多态与虚函数
- 当类之间存在*层次结构*，并且类之间是通过*继承*关联时，就会用到*多态*
- 但有时会因为*静态链接*（函数调用在程序执行前就准备好了，有时候这也被称为*早绑定*）而出错，这时需要用到 *virtual* 关键字，相应的，这种操作被称为*动态链接*，或*后期绑定*
- 虚函数只要声明了就一定要定义（实现），不然会报错。但有时我们无法在基类中给出确切的定义，这时候就需要定义*纯虚函数*：`virtual void func() = 0;`
- 为什么我们需要虚函数呢？纯虚函数用来规范派生类的行为，即接口。而在 python 中不需要这样是因为 python 具有独一套的框架环境体系
- 我们将包含纯虚函数的类称为抽象类，抽象类不能定义实例（因为它的 virtual 函数未定义，不是为了拿来用的，是为了给其他类提供一个可以继承的适当的基类），但可以声明指向实现该抽象类的具体类的指针或引用。
- 父类声明的纯虚函数或定义的虚函数在实现它的子类中就变成了虚函数，子类的子类即孙子类可以覆盖该虚函数，由多态方式调用的时候动态绑定。但我们也可以加个 final 让该子类的实现成为最终版本不再覆盖，如下
  ```cpp
  class Base
  {
    public:
      virtual void func() { // 或者也可以定义为纯虚函数
        cout<<"This is Base, the beta version of func"<<endl;
      }
  };
  class _Base: public Base
  {
    public:
      void func() final { // 最终版本
        cout<<"This is _Base, the final version of func"<<endl;
      }
  };
  ```
- virtual 虚函数
  - 多态可以通过虚函数 (virtual function) 来实现，虚函数可以通过在成员函数的前面加上 virtual 关键字来定义，这会让编译器在运行时动态绑定函数的地址。派生类重写的虚函数前面也可以加上 virtual 关键字作为提示，但不是必须的
  - 如果一个函数被声明为虚函数，那么在运行时，调用该函数的代码将根据对象的实际类型来决定调用哪个版本的函数。这就是所谓的*动态绑定*或*运行时多态性*
  - 如果不想在基类中给出虚函数的实现，可以将虚函数定义为纯虚函数 (pure virtual function)，形式为 `virtual type func(args) = 0`。这会让基类变为抽象类，无法实例化，只能作为接口使用
    - 抽象基类更进一步，Protocol/Interface classes，即*协议类*。其 variables 均为 static，其 member function 要么是 static 的，要么是 pure virtual 的
  - 为了确认派生类成功重写了基类的虚函数，可以在基类的虚函数后面加上 override 关键字，例如 `void func() override { ... }`。这样如果派生类没有成功重写基类的虚函数，编译器便会报错。override 关键字可以和 final 关键字一起使用，例如 `void func() final override { ... }`，顺序并不要紧
- 一个例子
  ```cpp
  class Ellipse : public Shape {
  public:
      Ellipse(float maj, float minr);
      virtual void render(); // will define own
  protected:
      float major_axis, minor_axis;
  };
  class Circle : public Ellipse {
  public:
      Circle(float radius):Ellipse(radius, radius){}
      virtual void render();
  };

  void render(Shape* p) {
      p->render(); // calls correct render function
  } // for given Shape!
  void func() {
      Ellipse ell(10, 20);
      ell.render(); // static -- Ellipse::render();
      Circle circ(40);
      circ.render(); // static -- Circle::render();
      render(&ell); // dynamic -- Ellipse::render();
      render(&circ); // dynamic -- Circle::render()
  }
  ```
- 总结：定义一个函数为虚函数，不代表函数为不被实现的函数。定义它为虚函数是为了允许用基类的指针来调用子类的这个函数。定义一个函数为纯虚函数，才代表函数没有被实现。定义纯虚函数是为了实现一个接口，起到一个规范的作用，规范继承这个类的程序员必须实现这个函数

==== 虚函数的实现
- *虚函数表*：拥有虚函数的类会自动生成一个虚函数表 `vtbl` （属于类而不是对象，一般存在程序的数据段，更确切地是 `.rodata` 段），是一个指针数组，里面的元素是虚函数的函数指针
- *虚表指针*：创建对象时对象内部会自动生成一个虚表指针 `*vptr` （通常会在对象内存的最起始位置），指向类的虚表 `vtbl` 在调用虚函数时，会经由 `vptr` 找到 `vtbl`，再通过 `vtbl` 中的函数指针找到对应虚函数的代码并进行调用
  - `vptr` 的值是在构造函数的*初始化列表*中写进去的。因此执行基类构造函数的时候，`vptr` 还指向基类的虚表；执行派生类构造函数的 body 的时候，`vptr` 就指向派生类的虚表了
- 普通函数、虚函数、虚函数表都是同一个类的所有对象公有的，只有成员变量和虚表指针是每个对象私有的
- 自然，非虚函数可以直接调用，不用经过虚表，这符合 C 的零成本抽象原则
- 一个例子
  #grid(
    columns: 2,
    column-gutter: 4pt,
    [
      ```cpp
      class A {
      public:
          virtual void vfunc1();
          virtual void vfunc2();
          void func1();
          void func2();
      private:
          int m_data1, m_data2;
      };
      class B : public A {
      public:
          void vfunc1() override;
          void func1();
      private:
          int m_data3;
      };
      class C: public B {
      public:
          void vfunc2() override;
          void func2();
      private:
          int m_data1, m_data4;
      };
      B bobject;       // 类 B 的一个对象
      A* p = &bobject; // 通过基类指针 *p 指向派生类 B 的对象
      ```
    ],
    [
      - 这些类的虚表如图所示
        #fig("/public/assets/Languages/Cpp/2025-01-11-13-19-00.png")
    ]
  )
  - 可以发现，通过基类指针 `p`，可以访问基类中的所有非虚成员，无法访问派生类独有的非虚成员（其内存位置在基类成员之后），却可以通过虚表来访问派生类重写的虚函数
    - 若想访问派生类独有的非虚成员，可以通过强制类型转换，将 `p` 转换为派生类的指针，如 `(B*)p->func2()`
    - 不要重载 (overwrite) 继承而来的非虚函数（区别于 override)，因为会破坏多态性和 is-a 原则

== 重载函数和重载运算符 Overload
- Cpp 允许在同一作用域中的某个函数和运算符指定多个定义，分别称为函数重载和运算符重载。
  - 当你调用一个重载函数和重载运算符时，编译器通过你所使用的参数类型与定义中的参数类型进行比较，决定选用最合适的定义。这被称为*重载决策*
- 重载函数：实现鸭子类型
  - 在同一个作用域内，可以声明几个功能类似的同名函数，但是这些同名函数的形式参数（指参数的个数、类型或者顺序）必须不同。比如，定义一个同名但对 int、double 类型做不同处理的函数
  - 重载函数中的 const：#link("https://www.cnblogs.com/qingergege/p/7609533.html")[C++中const用于函数重载]
- 重载运算符
  - 我们重载大部分 Cpp 内置的运算符，来达到一些特殊效果
  - 所谓重载的运算符，是带有特殊名称的函数，由关键字 operator 和需要重载的运算符直接连接而成，重载运算符需要带参数和返回类型
  - 运算符重载的同时也可以发生函数重载！
  - 值得注意的是：运算重载符不可以改变语法结构、不可以改变操作数的个数、不可以改变优先级、不可以改变结合性
  - 非友元函数的非成员函数是不能被重载的（重载只能用于对象相关）

#note(caption: "类重载、覆盖、重定义之间的区别")[
  + 重载是指同一个类中函数具有的不同的参数列表，而函数名相同的函数。重载要求参数列表必须不同，比如参数的类型不同、参数的个数不同、参数的顺序不同。如果仅仅是函数的返回值不同是没办法重载的，因为重载要求参数列表必须不同。
  + 覆盖是指子类重写从基类继承过来的函数。被重写的函数不能是 static 的，必须是 virtual 的。但是函数名、返回值、参数列表都必须和基类相同（发生在基类和子类）
  + 重定义也叫做隐藏，子类重新定义父类中有相同名称的非虚函数（参数列表可以不同）。
]

- 重载运算符，但是有一些是没法重载的，比如 `::`、`.*`、`?:`、`sizeof`、`typeid` 以及四种 `cast`
  - 可能会疑惑 `.*` 是个啥
  ```cpp
  class MyClass {
  public:
      int myNumber;
      void myFunction() { std::cout << "Function Called" << std::endl; }
  };

  int main() {
      MyClass obj;
      int MyClass::*ptrToNumber = &MyClass::myNumber;
      void (MyClass::*ptrToFunction)() = &MyClass::myFunction;

      obj.*ptrToNumber = 45; // 使用 .* 运算符访问成员变量
      std::cout << "myNumber: " << obj.*ptrToNumber << std::endl; // 输出: myNumber: 45

      (obj.*ptrToFunction)(); // 使用 .* 运算符调用成员函数

      return 0;
  }
    ```
- 成员函数重载与非成员函数重载
  - 对二元运算符而言，如果在类内重载，第一个参数是隐式的，否则如果在类外重载，第一个参数需要显式指定
  - 除此之外，类内 (member) 和类外（global，通常会声明为 friend）还有诸多不同，比如是否会进行类型转换（前者不会后者会）等
  - 总而言之，单目运算符最好用类内，`=`、`[]`、`->`、`->*` 必须用类内，其它二元运算符最好用类外
- 参数和返回值应该是否应该引用或是常量？参考运算符原型是怎么写的
  #fig("/public/assets/Languages/Cpp/img-2024-05-14-15-22-59.png", width:50%)
  - 以及赋值运算符（拷贝赋值运算符） `T& operator=(const T& other);` 返回引用以支持连续赋值
    - 赋值运算符是 cpp 六大默认成员函数之一；它必须是一个成员函数；需要 delete 掉原有的资源，然后再分配新的资源（重要！）
- operators `++` 和 `--`
  - 怎么记呢？前缀用引用返回，后缀加个参数（编译器自动补 $0$），分别返回左值和右值
  ```cpp
  const Integer& operator++();   // prefix++
  const Integer operator++(int); // ++postfix
  const Integer& operator--();   // prefix--
  const Integer operator--(int); // --postfix
  ```
- 关系运算符
  - implement `!=` in terms of `==`
  - implement `>`, `>=`, `<=` in terms of `<`
  ```cpp
  bool operator==(const Integer& rhs) const;
  bool operator!=(const Integer& rhs) const;
  bool operator<(const Integer& rhs) const;
  bool operator>(const Integer& rhs) const;
  bool operator<=(const Integer& rhs) const;
  bool operator>=(const Integer& rhs) const;
  ```

== Cpp 类型
=== 基础类型
- 一些基础类型的大小
```cpp
std::cout << sizeof(int) << std::endl;   // 4
std::cout << sizeof(long) << std::endl;  // 4
std::cout << sizeof(long long) << std::endl; // 8
std::cout << sizeof(void*) << std::endl; // 8
```
=== class, struct, union
- cpp 的 struct 实际上已经扩充到和 class 差不多了，只有细微的差别
  - 也就是说，struct 现在几乎也可以当做 class 来使用了
  - 习惯上，不涉及数据处理的方法的数据类型封装才会用 struct，否则使用 class。也就是依然当做 C 中的 struct 使用
- Union（联合）是一种用于节省空间的特殊的结构体（or 类？），它的所有成员共用一个内存空间，只能同时存储一个值。
- 与结构体类似，有匿名和非匿名两种
- 可以为联合的成员指定长度，通过冒号操作符实现更精细的控制
  ```cpp
  union U {
  unsigned short int aa; // 要么用这个
  struct {               // 要么用这个
    unsigned int bb : 7;//(bit 0-6)
    unsigned int cc : 6;//(bit 7-12)
    unsigned int dd : 3;//(bit 13-15)
  };
  } u; // 总共 16 位，2 字节
  ```

=== 类型转换 Type Conversion
- 类型转换
  - cpp 会使用单参数构造函数和 implicit conversion operator 进行隐式类型转换
  - 可以通过 explicit 关键字来阻止
  - 类型转换运算符
    + 必须是成员函数，不能是友元函数 ，因为转换的主体是本类的对象。不能作为友元函数或普通函数
    + 没有参数，因为是把自己转换，无需参数
    + 不能指定返回类型，因为返回类型同函数名
    + 编译器会在 X $=>$ T 时调用它
    ```cpp
    X::operator T() const {

    }
    ```
  - 事实上，使用这种东西会导致很多预想不到的问题，因此最好不要使用，或者使用“人为” explicit 的类型转换
    ```cpp
    T to_T() const;
    ```
- Casting operators
  - #link("https://zhuanlan.zhihu.com/p/151744661")[Cpp 四种 cast]
  - static_cast: explicit type conversion, not safe for object pointers（但反过来，也不会增加检查的开销）
    + 在程序编译时刻进行类型转换，不会进行运行时检查。常用于基本类型的转换，比如 `int` 转 `char`
    + 类的 upcast，子类的指针或者引用转换为基类（安全）
    + 类的 downcast，基类的指针或引用转换为子类（不安全，没有类型检查）
  - dynamic_cast: 只能用在指向类的指针或引用，允许 upcast 和 downcast（当不完整时返回 nullptr）
    + 用于运行时类型识别，只能用于多态类
    + 类的 upcast，子类的指针或引用转化为基类（安全）
    + 类的 downcast，基类的指针或引用转化为子类（安全，有类型检查）
  - const_cast: add or removes constness for 指针、引用、对象
  - reinterpret_cast: 数据和指针（引用）之间的转换，最自由，没有类型检査

== 函数 Function
=== 内联函数 Inline Function
- 在函数前加一个 inline 的修饰
  - 免去函数开销，如同预编译指令（跟 macro 很像，但更复杂更偏向编译层面）
  - 比 macro 好，因为有类型检查
  - 它的 declaration 等同于 definition(?)
  - inline 是用于实现而非声明，因此它应当被加在函数定义前而不是函数声明前
  - 最好放置在头文件中
  - inline 不一定会被编译器实现（当函数太大或者递归）
  - class 中的函数默认都是 inline 的，class 外的函数则不会
  - 内联函数并不是 Cpp 相对 C 独有的，不过在 Cpp 中用的更多（隐式内联）
- 参考:
  + #link("https://blog.csdn.net/qq_35902025/article/details/127912415")[内联函数详解（搞清内联的本质及用法）\_c++内联函数\_赵大宝字的博客-CSDN博客]
  + #link("https://www.cnblogs.com/zsq1993/p/5978743.html")[内联函数的声明和定义]

=== 函数默认参数 Default Arguments
- C++ 允许在函数声明或定义中为一个或多个参数指定默认值，这样在调用函数时可以忽略这些参数
- 它们必须从右向左添加默认值，否则会报错
  ```cpp
  int harpo(int n, int m = 4, int j = 5);
  int chico(int n, int m = 6, int j); //illeagle
  ```
- 当函数采用先声明后定义的方式时，只能在声明中指定默认值，而不能在定义中指定默认值
- 在底层，其实也是利用了函数重载实现。所以一般来说慎用默认参数，不如自己显式地重载（这点跟 Python 的灵活性不同）

=== 匿名函数 Lambda Function <Lambda>
- 匿名函数的概念等很好理解，这里不多赘述
- 匿名函数的优点
  + 可以就地定义，比函数更方便
  + 局部作用域更容易控制，有助于减少命名冲突
  + 利用捕获机制自动捕获上下文中的变量，比普通函数更方便
  + 结合 std::function, std::bind 使用达成更多功能，参考 #link("http://www.debugself.com/2017/09/20/cpp_bind_fun/")[c++11 function、bind用法详解]
- 格式为：```Cpp [捕获列表](参数列表) mutable throw(...) -> return_type { /* body */ } ```
  + *可能为空的*捕获列表，指明定义环境中的那些变量能被用在 lambda 表达式内，以及这些变量的捕捉形式
  + *可选的*参数列表，指明 lambda 表达式所需的参数
  + *可选的* mutable 修饰符，指明该 lambda 表达式可能会修改它自身的状态（即改变通过值捕获的变量的副本）
  + *可选的* `->` 形式的返回类型声明
  + 表达式体，指明要执行的代码
- 捕获的举例如下：
  + `[]`，空捕获列表，不捕获任何变量，此时引用外部变量则会提示编译错误
  + `[=]`，默认按值捕获全部变量
  + `[&]`，默认按引用捕获全部变量
  + `[=,&x,&y]`，默认按值捕获全部变量，但是变量 `x, y` 按引用捕获
  + `[=,x,y]`，编译出错，变量 `x, y` 按值捕获，和默认按值捕获全部变量重复
  + `[x,y]`，只按值捕获变量 `x, y`
  + `[&x,&y]`，只按引用捕获变量 `x, y`
  + `[=x,=y]`，编译出错，应为 `[x, y]`
  + `[this]`，捕获 this 指针，然后在 Lambda 表达式内部就可以直接引用类成员了
- 参数列表，和普通函数一样，不赘述
- mutable
  ```cpp
  int x = 1;
  auto f = [x]() { x++; };   // 编译错误，不能修改 x 的值
  f();
  ```
  - 但是如果加上 `mutable` 就可以了（但由于是值捕获，所以不会改变外部变量的值）
- `throw`，跟普通函数一样，不赘述
- 返回类型
  - 一般情况下，编译器会自动推断出 lambda 的返回类型。但是如果函数体里面有多个返回语句，或者有一些常量 return 返回时候，编译器可能无法自动推断
- 函数体：注意匿名函数外面最后需要添加一个 `;` 分号
- 匿名函数的实质
  - 每当你定义一个 lambda 表达式后，编译器会自动生成一个匿名类（这个类当然重载了 `()` 运算符），我们称为闭包类型 (closure type)
  - 例子
  ```cpp
  int x = 1;
  auto f = [x]() mutable { x++; cout<< x <<endl; };
  f(); // 2
  f(); // 3
  ```
- 泛型：赋值给 auto

=== 可调用对象 Callable Object <Callable_Object>
- 类似于 Python 那样把函数当作变量传递
- 参考：
  + #link("https://www.cnblogs.com/tuapu/p/14167159.html")[C++11中的std::bind和std::function]
  + #link("https://cloud.tencent.com/developer/article/2388825")[理解C++ std::function灵活性与可调用对象的妙用]
- [ ] 待补充

== 引用 Reference
- 引用是已经存在的某个变量的别名，一旦把引用初始化为某个变量，就可以通过这个别名来访问那个变量
- 引用的作用可以借由指针来理解，但又不同于指针
  - 不存在空引用，引用必须连接到一块合法的内存
  - 引用必须在创建时被初始化。指针可以在任何时间被初始化
  - 引用初始化后就不能指向其他对象或者重复初始化为其他对象，指针可以在任何时间指向其他对象
  - 引用在底层是一个 `T *const`，其本质为*指针常量*（指针本身是常量，而指向的对象不是）
- 引用的简单例子
  ```cpp
  int i = 1;
  int &j = i; // j 是 i 的引用
  ```
- 引用作为函数参数的例子，很简单就略去了
- 引用作为函数返回值的例子，相对复杂一些，说是可以使程序更易读，虽然我看半天反应不过来
  ```cpp
  include <iostream>

  using namespace std;

  double vals[] = {10.1, 12.6};

  double& setValues(int i) {
    double& ref = vals[i];
    return ref;   // 返回第 i 个元素的引用，ref 是一个引用变量，ref 引用 vals[i]
  }

  int main ()
  {
    cout << "改变前的值" << endl;
    for (int i = 0; i < 2; i++)
      cout << "vals[" << i << "] = " << vals[i] << endl;
    setValues(1) = 20.23; // 改变第 2 个元素
    cout << "改变后的值" << endl;
    for (int i = 0; i < 2; i++)
      cout << "vals[" << i << "] = " << vals[i] << endl;
    return 0;
  }
  ```
- 关于值传递、指针传递、引用传递的选择
#info(caption: [Tips])[
  - Pass in an object if you want to store it
  - Pass in a const pointer or reference if you want to get the values
  - Pass in a pointer or reference if you want to do something to it
  - Pass out an object if you create it in the function
  - Pass out pointer or reference of the passed in only
  - Never new something and return the pointer
]

==== 左值引用和右值引用 <左值引用和右值引用>
- 左值与右值
  - 左值 (Lvalue) 和右值 (Rvalue) 根据表达式是否可以*在赋值操作中作为左侧项*来区分，或者通过是否能取地址和是否有名字来区分
  - 左值是一个表达式，它指向内存中的一个固定地址。左值通常指变量的名字，它们在程序的整个运行期间都存在
  - 右值是一个临时的、不可重复使用的表达式。右值通常包括字面量、临时生成的对象以及即将被销毁的对象
  - 之所以要使用右值引用，是为了
    + 支持移动语义，减少不必要的内存拷贝
    + 支持完美转发，避免重载函数的重复定义
    + 拓展可变参数模板，实现更加灵活的模板编程
- 移动语义
  - 移动语义涉及右值引用 (`type&&`)，用于绑定临时对象和 `std::move()` 函数返回的对象，它的目的是更精细地控制内存分配，加快程序运行速度
    - `std::move()` 将一个对象的左值引用转换为右值引用，实质上是一个静态类型转换，告诉编译器将一个左值当作右值来处理
  - 默认成员函数又多了移动构造函数和移动赋值操作符函数
  - 可以看这篇文章，很通透 #link("https://zhuanlan.zhihu.com/p/455848360")[一文入魂：妈妈再也不担心我不懂C++移动语义了]
- 完美转发
  - 完美转发是指在函数模板中保持参数的原始类型，不改变参数的类型，不改变参数的左值或右值属性
  - 一个经典例子
  ```cpp
  void process(int& i) {
    std::cout << "处理左值: " << i << std::endl;
  }
  void process(int&& i) {
    std::cout << "处理右值: " << i << std::endl;
  }
  // 完美转发的函数模板
  template<typename T>
  void logAndProcess(T&& param) {
    // 调用 process 函数，同时保持 param 的左值 / 右值特性
    process(std::forward<T>(param));
  }
  int main() {
    int a = 5;
    logAndProcess(a);  // a 是左值，将调用处理左值的重载
    logAndProcess(10); // 10 是右值，将调用处理右值的重载
    return 0;
  }
  ```

== 指针 Pointer
- 原始指针跟 C 里面应该没什么区别

=== `malloc` and `free`, `new` and `delete`
- `malloc` 并不是系统调用，而是 C 的库函数
  - 当分配内存小于 $128KB$ 时，调用 `brk` syscall，从 heap 分配内存，否则调用 `mmap` syscall，从文件映射区分配内存
  - 为什么不都用 `mmap`？因为 `mmap` 分配的内存每次释放的时候都会归还给 OS，重新分配时都处于缺页状态
- `free` 如何确定要释放的内存大小？
  - `malloc` 会在分配的内存块前面多分配一个 `size_t` 的空间，记录分配的内存大小
  - `free` 会根据这个值来释放内存（对传入的内存地址向左偏移 `sizeof(size_t)` 字节）
- `malloc` 和 `new` 的区别
  - `malloc` 是库函数，`new` 是运算符；前者只分配内存，后者还会调用构造函数；前者返回 `void*`，后者返回指定类型的指针；前者失败返回 `NULL`，后者失败抛出异常
  - `new` 申请内存的步骤：调用 `operator new` 分配内存，调用构造函数初始化对象，返回对象指针
- `delete` 的步骤：调用析构函数，调用 `operator delete` 释放内存

=== 智能指针
- 智能指针是*封装了原生指针的类模板*，用于自动管理对象的生命周期，主要有 `unique_ptr`, `shared_ptr`, `weak_ptr`，在 `<memory>` 头文件中
- 从三个层次理解智能指针：
  + 用一种叫做 RAII（Resource Acquisition Is Initialization，资源获取即初始化）的技术对普通指针进行封装，使得智能指针实质是一个对象，行为表现得却像一个指针
  + 作用是确保动态资源得到安全释放，避免内存泄漏
  + 还有一个作用是把值语义转换成引用语义
- `unique_ptr`
  - 不能拷贝和赋值，只能通过移动语义转换所有权
  - 什么时候用？相比原始指针确保动态资源能得到释放，相比 `shared_ptr` 开销小，大多数场景下用到的应该都是 `unique_ptr`
- `shared_ptr`
  - 是 `unique_ptr` 的两倍空间，维护了一个引用计数，当引用计数为 $0$ 时自动释放资源
  - 什么时候用？通常用于一些资源创建昂贵比较耗时的场景， 比如涉及到文件读写、网络连接、数据库连接等。当需要共享资源的所有权时，例如，一个资源需要被多个对象共享，但是不知道哪个对象会最后释放它
- `weak_ptr`
  - *不具有普通指针的行为*，而是配合 `shared_ptr` 使用，用于解决循环引用问题
  - 什么时候用？当两个对象相互引用，且其中一个对象是 `shared_ptr` 类型时，会导致循环引用，从而导致内存泄漏。此时可以使用 `weak_ptr` 来解决这个问题
  - `weak_ptr` 的绑定不会影响 `shared_ptr` 的引用计数，可以用 `use_count()` 监测计数。它也可以通过 `expire()` 判断是否已释放，用 `lock()` 获取 `shared_ptr` 对象
- 例子
  ```cpp
  int main() {
      {
          std::unique_ptr<int> uptr(new int(10)); //  绑定动态对象
          // std::unique_ptr<int> uptr2 = uptr;   // 不能赋值
          // std::unique_ptr<int> uptr2(uptr);    // 不能拷贝
          std::unique_ptr<int> uptr2 = std::move(uptr); // 转换所有权
          uptr2.release(); // 释放所有权
      } // 超过 unique_ptr 的作用域，自动释放
      {
          int a = 10;
          std::shared_ptr<int> ptra = std::make_shared<int>(a);
          std::shared_ptr<int> ptra2(ptra); // copy
          std::cout << ptra.use_count() << std::endl;

          int b = 20;
          int *pb = &a;
          // std::shared_ptr<int> ptrb = pb;  // error，需要转换为 shared_ptr
          std::shared_ptr<int> ptrb = std::make_shared<int>(b);
          ptra2 = ptrb;
          pb = ptrb.get();

          std::cout << ptra.use_count() << std::endl;
          std::cout << ptrb.use_count() << std::endl;
      }
  }
  ```
- 参考
  + #link("https://www.cnblogs.com/rebrobot/p/18215501")[现代 C++ 智能指针详解：原理、应用和陷阱]
  + #link("https://www.cnblogs.com/wxquare/p/4759020.html")[C++11 中智能指针的原理、使用、实现
]

== 常量 Constant
- Run-time constant 和 Compile-time constant
  ```cpp
  const int x = 123; // x 为编译时常量 (Compile-time constant)，123为字面量 (literal)
  // 在这种简单的情况下，编译器会直接把 x 优化为汇编里的立即数，存储在静态存储区
  cin >> size;
  const int SIZE = size; // SIZE为运行时常量 (Runtime constant)，只有运行的时候才能知道常量的值
  // 因此编译器只能把它设置成变量，然后保证它不会被修改，这样就会存储在栈或堆里，跟普通变量一样
  // 这里的 const 纯粹是编译器帮你检查的工具，对二进制来说完全是透明的
  // 所以实际上更好的叫法是只读 read only
  ```
- 修改常量
  ```cpp
  const int a = 1;
  int size;
  cin >> size; // input 1
  const int SIZE = size;
  cout << a << ", " << SIZE << endl;
  int* p = (int*)&a; // 不会成功，因为 a 是 compile-time constant
  *p = 10;
  p = (int*)&SIZE;   // 会成功，因为 SIZE 是 run-time constant
  *p = 10;
  cout << a << ", " << SIZE << endl;
  // p = *const_cast<string*>(&a); // const cast 只能调节类型限定符；不能更改基础类型
  // *p = 10;                      // 也就是说，如果它不是基础类型，compile-time constant 还真能这样改
  cout << a << ", " << SIZE << endl;
  ```

- 关于可变长数组和 Run-time constant:
    ```cpp
    int x;
    cin >> x;
    const int size = x;
    double classAverage[size]; // error!
    ```
  - 说是会报错，但实际上，只要不用 msvc 编译器，就不会
  - C99 引入的特性，C++ 也支持
- Compile-time constants in classes
  ```cpp
  class HasArray {
      const int size = 1;
      int array[size]; // ERROR!
  };
  ```
  - 这样会报“非静态成员引用必须与特定对象相对”的错（在没有创建对象的情况下访问非静态成员）
  - 解决办法是声明为 `static const int size=1;`
  - 或者使用匿名枚举 hack: `enum { size = 1 };`（编译时会被替换为 1）
- 指针常量和常量指针
  - 区别在于 `const` 在 `*` 的左右
  ```cpp
  int a = 1, b = 2;
  int* const p = &a;  // 指针常量，指针是常量，但指向内容不是
  const int* q = &a;  // 常量指针，指针指向内容是常量，但指针不是
                      // 或者写为 int const *q = &a; 效果是一模一样的
  *p = 9;             // 成功
  // p = &b;          // 错误
  // *q = 9;          // 错误
  q = &b;             // 成功
  a = 3;              // 但无论哪种，都不妨碍直接改 a
  ```

== 模板 Template
- 模板是 C++ 支持参数化多态的工具，使用模板可以使用户为类或者函数声明一种一般模式，使得类中的某些数据成员或者成员函数的参数、返回值取得任意类型
  - 通俗来讲，就是让程序员编写与类型无关的代码，而专注于语义实现。比如编写了一个交换两个 int 类型的 swap 函数，那它不重载就无法交换 double 类型
  - 模板如何转化为不同类型？跟 `auto` 类似，由编译器自动推导，本质上是把程序员所需的重复工作交给编译器
- 模板通常有两种形式：函数模板和类模板
  - 函数模板针对仅参数类型不同的函数
  - 类模板针对仅数据成员和成员函数类型不同的类
- 注意：模板的声明或定义只能在全局，命名空间或类范围内进行。即不能在局部范围，函数内进行
- 函数模板的格式
  ```cpp
  template <class 形参名, class 形参名, ......>
  返回类型 函数名(参数列表) {
    ...
  }
  ```
- 类模板的格式
  ```cpp
  template <class 形参名, class 形参名, ......>
  class 类名 {
    ...
  };
  ```
- 一个结合的例子
  ```cpp
  template<class T>
  class A {
  public:
      T g(T a,T b);
      A();
  };

  template<class T>
  A<T>::A() {}

  template<class T>
  T A<T>::g(T a,T b) {
      return a + b;
  }

  int main(){
      A<int> a;
      cout << a.g(1,2) << endl;
      return 0;
  }
  ```
- 不能为同一个模板类型形参指定两种不同的类型（针对函数模板）
  - 针对 Template functions：在输入参数的时候不会进行类型检查，也不会做隐式或显式类型转换。比如 `template<class T>void h(T a, T b){}`，语句调用 `h(2, 3.2)` 将出错，因为该语句给同一模板形参T指定了两种类型，第一个实参 `2` 把模板形参 `T` 指定为 `int`，而第二个实参 `3.2` 把模板形参指定为 `double`，两种类型的形参不一致，会出错。
  - 针对 Template classes：当我们声明类对象为：`A<int> a`，比如 `template<class T>T g(T a, T b){}`，语句调用 `a.g(2, 3.2)` 在编译时不会出错，但会有警告，因为在声明类对象的时候已经将 `T` 转换为 `int` 类型，而第二个实参 `3.2` 把模板形参指定为 `double`，在运行时，会对 `3.2` 进行强制类型转换为 `3`。当我们声明类的对象为：`A<double> a`，此时就不会有上述的警告，因为从 `int` 到 `double` 是自动类型转换。
- 类型形参与非类型形参
  - 前面那些 `T` 就是类型形参，指代之后实例化时的类型；还有非类型形参
  - 非类型形参只能是常量（或常量表达式），另外只能是整型，指针和引用
  - 非类型模板参数 (non-type template parameter) 常常用在容器的上限之类的地方。在 cpp17 后，这个 parameter 甚至可以是 auto 来让编译器自行推断
    ```cpp
    template <class T, int bounds = 100>
    class FixedVector{
    private:
        T elements[bounds]; // fixed size array!
    }
    ```
- 参考：#link("https://www.runoob.com/w3cnote/c-templates-detail.html")[C++ 模板详解 | 菜鸟教程 (runoob.com)]

- 模板和继承
  - 好像没什么好说的，基类是不是模板类以及派生类是不是模板类四种情况都支持

- Simulate virtual function in generic programming
  - OOP PPT 38 页，没看懂，有点自指的感觉

- typename 与 template
  - #link("https://feihu.me/blog/2014/the-origin-and-usage-of-typename/")[关于 typename]

- traits based design & policy based design
  - 又没看懂

- template template parameters


==== 模板特化
- 不同与模板实例化。常用在为一个特定的类型提供特殊的实现
- 对多个模板参数还分为*偏特化*和*全特化*
- 比如下面的例子中，我们实现了两个类型的比较，适用于大多数类型如 `int`, `double`，但无法用于 `char*`，这时需要函数模板特化
  ```cpp
  #include <iostream>
  #include <cstring>
  // 一般的函数模版
  template <class T>
  int compare(const T left, const T right) {
      std::cout <<"in template<class T>..." << std::endl;
      return (left - right);
  }

  // 这个是一个特化的函数模版
  template < >
  int compare<const char*>(const char* left, const char* right) {
      std::cout << "in special template< >..." << std::endl;
      return strcmp(left, right);
  }

  // 特化的函数模版, 两个特化的模版本质相同, 因此编译器会报错
  // error: redefinition of 'int compare(T, T) [with T = const char*]'|
  // template < >
  // int compare(const char* left, const char* right) {
  //     std::cout << "in special template< >..." <<std::endl;
  //     return strcmp(left, right);
  // }

  // 这个其实本质是函数重载，跟模版特化没有关系，但是会优先调用它
  int compare(char* left, char* right) {
      std::cout <<"in overload function..." << std::endl;
      return strcmp(left, right);
  }

  int main() {
      compare(1, 4);
      const char *left = "gatieme";
      const char *right = "jeancheng";
      compare(left, right);
      return 0;
  }
  ```

== Namespace
- Namespace
  - `using` 既可以对某个 namespace，也可以是对 namespace 内的某个 object
  - namespace aliases
  - namespace composition
    - 如果两个 namespace 有相同的 object，采用先出现的那个
  - namespace selection
  - multiple namespace(same name): 同名的多个 namespace——叠加

== File I/O
- 首先引入头文件 `#include <fstream>`，其中包含三个类：ofstream、ifstream、fstream，分别用于写、读、读写（包括两个功能）
- 打开文件与关闭文件
  ```cpp
  ofstream outfile;
  outfile.open("file.dat", ios::out | ios::trunc ); // 写入模式打开文件
  ifstream  infile;
  infile.open("file.dat", ios::out | ios::in ); // 读取模式打开文件
  outfile.close(); // 关闭文件
  infile.close(); // 关闭文件
  ```
  - 打开文件的第一个参数是文件名，第二个参数是打开模式。打开模式有：ios::in（输入）、ios::out（输出）、ios::ate（定位到文件尾）、ios::app（追加）、ios::trunc（删除原有内容）。具体参见 #link("https://www.runoob.com/cplusplus/cpp-files-streams.html")[C++ 文件和流 | 菜鸟教程 (runoob.com)]
- 至于具体的读写操作，就是用 `<<` 和 `>>`，用法与 cin、cout 类似。给出写入文件的例子
  ```cpp
  #include <fstream>
  #include <iostream>
  using namespace std;
  ofstream outfile;
  outfile.open("file.dat", ios::out | ios::trunc );
  outfile << "Hello, World!" << endl;
  outfile.close();
  ```

== 异常 Exception
- Objects on stack destroyed properly
- try-catch 在执行时会应用基类转换
  ```cpp
  class MathErr {
      // ...
      virtual void diagnostic();
  };
  class OverflowErr : public MathErr { }
  class UnderflowErr : public MathErr { }
  class ZeroDivideErr : public MathErr { }

  try {
      throw UnderFlowErr();  // code to exercise math options
  } catch (ZeroDivideErr& e) {
      // handle zero divide case
  } catch (MathErr& e) {
      // handle other math errors
  } catch (...) {
      // any other exceptions
  }
  ```
- 在 `catch` 中还可以再次重抛异常 `throw;` （后面不用跟任何东西），用于告诉上级代码这里出问题了
- 函数的 exception specifications
  - 用跟成员初始化列表类似的语法，但是成员函数和非成员函数都可以用
  - 不在编译时刻检查，而是在运行时刻抛出 `unexpected` 异常
  - 这个 `: throw()` 的语法好像错了，删掉 `:` 才能过编译
    ```cpp
    PrintManager::print(Document&) : throw(BadDocument) {
        ... // raises or doesn’t handle BadDocument
    }
    void goodguy() : throw() { // 显式说明不会抛出任何异常（会处理所有异常），c++11 后应当使用 noexcept 关键字
        ... // handles all exceptions
    }
    void average() {
        ... // no spec, no checking（他可能会抛出任何异常）
    }
    ```
- 如果在 constructors 中使用 `throw`，确保先释放已经分配的资源；destructors 中无法抛出异常（因此如果发生异常，程序会直接寄掉）
- Destructors and exceptions
  - Destructors 在 object exits from scope 时被调用，或者抛出 exception 时清空 stack 上资源时被调用（在栈中的本地变量都会被正确析构，但 `throw` 出来的东西直到 `catch` 之后才被析构）
  - 如果在 exception 中，调用的 destructor 也抛出异常，那么程序会唤起 `std::terminate()` 来终止程序
- 最好用 reference 来捕捉引用
  - 使用 value 捕捉需要额外拷贝且会产生 slicing problem（派生异常被基异常捕捉，将会被截断）
  - 使用 pointer 捕捉导致正常代码和异常处理代码的耦合
  - #link("https://blog.csdn.net/u014038273/article/details/77816762")[C++之通过引用（reference）捕获异常（12）---《More Effective C++》]
- 没有被捕捉的异常会唤起 `std::terminate()` 来终止程序，但是可以通过 `std::set_terminate()` 来设置自定义的终止函数（甚至设置一个不终止的函数来拦截）
- 标准 exception 类
  ```cpp
  class exception{
  public:
      exception () throw(); // 构造函数
      exception (const exception&) throw(); // 拷贝构造函数
      exception& operator= (const exception&) throw(); // 运算符重载
      virtual ~exception() throw(); // 虚析构函数
      virtual const char* what() const throw();
      // 虚函数，用于描述错误的具体情况
      // 继承的时候要override这个what()函数
  };
  ```

- #link("https://www.baiy.cn/doc/cpp/inside_exception.htm")[C++异常机制的实现方式和开销分析]

== OOP 复习时的一些易错题
- 这些易错题感觉还是比较深入的，对 cpp 机理的理解要求比较高
```cpp
#include <iostream>
struct A {
    virtual void f() { std::cout << "Af" << std::endl; }
    virtual void f(int) { std::cout << "Afi" << std::endl; }
    virtual void f(int, int) { std::cout << "Afii" << std::endl; }
};
struct B : A {
    void f() override { std::cout << "Bf" << std::endl; }
    void f(int) override { std::cout << "Bfi" << std::endl; }
};
struct C : B {
    void f() override { std::cout << "Cf" << std::endl; }
};

int main() {
    C xxx;
    C* c = &xxx;
    B* b = &xxx;
    A* a = &xxx;
    // for each one of the following calls, determine the output
    // or if it causes a compile error
    a->f();     // output or compile error?
    a->f(1);    // output or compile error?
    a->f(1, 2); // output or compile error?
    b->f();     // output or compile error?
    b->f(1);    // output or compile error?
    //   b->f(1, 2); // output or compile error?
    c->f();     // output or compile error?
    //   c->f(1);    // output or compile error?
    //   c->f(1, 2); // output or compile error?

    return 0;
}
```

```cpp
#include <iostream>
using namespace std;

class A{
public:
    void F(int) { cout << "A:F(int)" << endl; }
    void F(double) { cout << "A:F(double)" << endl; }
    void F2(int) { cout << "A:F2(int)" << endl; }
};
class B : public A {
public:
    void F(double) {
        cout << "B:F(double)" << endl;
    }
};

int main() {
    B b;
    b.F(2.0); // B:F(double)
    b.F(2);   // B:F(double)
    b.F2(2);  // A:F2(int)
}
```

```cpp
class C {
public:
    explicit C(int) {
        std::cout << "i" << std::endl;
    }
    C(double) {
        std::cout << "d" << std::endl;
    }
};
int main() {
    C c1(7);  // "i"
    C c2 = 7; // "d"
}
```

```cpp
struct A {
    virtual void foo(int a = 1) {
        std::cout << "A" << '\n' << a;
    }
};
struct B : public A {
    virtual void foo(int a = 2) {
        std::cout << "B" << '\n' << a;
    }
};

int main () {
    A* a = new B;
    a->foo();  // B, then 1
}
```

```cpp
class A {
public:
    static void f(double) { std::cout << "f(double)" << std::endl; }
    void f(int) { std::cout << "f(int)" << std::endl; }
};
int main() {
    A a;
    const A b;
    a.f(3);  // f(int)
    b.f(3);  // f(double)
}
```

```cpp
int f(int a) {
    return ++a;
}
int g(int &a) {
    return ++a;
}
int main() {
    int i = 0, j = 0, m = 0, n = 0;
    i += f(i);
    j += g(j);  // pay attention to '+='
    cout << "i=" << i << endl;  // i=1
    cout << "j=" << j << endl;  // j=2
}
```

```cpp
class A {
public:
    A() { cout << "A()" << endl;}
    ~A() {cout << "~A()" << endl;}
};
class B : public A {
public:
    B() { cout << "B()" << endl;}
    ~B() {cout << "~B()" << endl;}
};
int main() {
    A* ap = new B[2]; // A() A() B() B()
    delete ap;        // 调用了 A 的析构函数，然后段错误（？
}
```

== 属性
- “属性”是 C11 标准中的新语法，用于让程序员在代码中提供额外信息。相较于风格各异的传统方式(`attribute`, `__declspec`, `#pragma`...)，“属性”语法致力于将各种“方言”进行统一。
- 我们有理由担心属性的大量使用会引起 C++ 语言的混乱，很可能将产生很多 C++ 语言的“方言”。所以，我们推荐仅在不影响源代码的业务逻辑的前提下，才使用属性来帮助编译器作更好的错误检查（例如，`[[noreturn]]`，或者是帮助代码优化（例如，`[[carries_dependency]]`）
- 一些简单的例子：
  ```cpp
  // 使用[[nodiscard]]避免忽略重要返回值
  [[nodiscard]] int calculateImportantValue() {
      // ... 计算逻辑 ...
      return result;
  }
  void someFunction() {
      calculateImportantValue(); // 编译器将警告此行忽略了返回值
  }

  // 利用[[likely]]和[[unlikely]]指导优化
  void processCondition(bool condition) {
      if ([[likely]] condition) {
          // ... 常见情况处理 ...
      } else {
          // ... 较少发生的情况 ...
      }
  }
  ```


== 其它
- `std::optional`，C++17 新增的模板类，用于表示一个可能为空的值

= Cpp 新特性整理
== C++11
- 成员初始化列表，参见 @构造函数和析构函数
- 移动语义，参见 @左值引用和右值引用
- Lambda 表达式，参见 @Lambda
- 可调用对象，参见 @Callable_Object
- 智能指针
- 可参考 #link("https://blog.csdn.net/jiange_zh/article/details/79356417")[C++11常用新特性快速一览]

== C++14
- Lambda 表达式的泛型

== C++17
- if 和 switch 语句中初始化变量
  - 字面意思，好处在于不用在外面初始化，而且不会污染外部作用域

= Cpp STL 库整理
- 可以参考 #link("https://zhuanlan.zhihu.com/p/542115773")[C++ STL 十六大容器 —— 底层原理与特性分析]

== Array
- 跟 Cpp 的 `[]` 数组无限接近，所有元素按照内存地址线性排列，并不维护任何多余数据比如 `size`
- 但它毕竟是标准模板库的一员，支持 `begin(), end(), front(), back(), at(), empty(), data(), fill(), swap(), ...` 等标准接口

== Vector
- 内部就是一段连续的线性内存空间，用三个迭代器来表示：`begin()`, `end()`, `capacity()`
- 与数组相比，它有更多的灵活性和功能，可以自动管理内存，允许动态地插入和删除元素。它高效的秘诀在于每次空间不够时，重新分配并拷贝到一块更大的内存空间 (e.g. 50% plus)
- `push_back()` and `emplace_back()`
  - 当使用Push_back时会先调用类的有参构造函数创建一个临时变量，再将这个元素拷贝或者移动到容器之中，而emplace_back则是直接在容器尾部进行构造比push_back少进行一次构造函数调用。在大部分场景中emplace_back可以替换push_back，但是push_back会比emplace_back更加安全，emplace_back只能用于直接在容器中构造新元素的情况，如果要将现有的对象添加到容器中则需要使用push_back
```cpp

```

== List
- 内部用双向链表实现
```cpp
list<int> l;
std::list<int> numbers;

numbers.push_back(1); // 向列表中添加元素
numbers.push_back(2);
numbers.push_back(3);

std::cout << "First element: " << numbers.front() << std::endl; // 访问并打印列表的第一个元素

std::cout << "Last element: " << numbers.back() << std::endl; // 访问并打印列表的最后一个元素

std::cout << "List elements: "; // 遍历列表并打印所有元素
for (auto it = numbers.begin(); it != numbers.end(); ++it)
    std::cout << *it << " ";
std::cout << std::endl;

numbers.pop_back(); // 删除列表中的最后一个元素

std::cout << "List elements after removing the last element: "; // 再次遍历列表并打印所有元素
for (auto it = numbers.begin(); it != numbers.end(); ++it)
    std::cout << *it << " ";
std::cout << std::endl;
```

== Stack
- `<stack>` 的底层容器可以是任何支持随机访问迭代器的序列容器，如 `vector` 或 `deque`
- `<stack>` 不提供直接访问栈中元素的方法，只能通过 `top()` 访问栈顶元素
- 尝试在空栈上调用 `top()` 或 `pop()` 将导致未定义行为
```cpp
std::stack<int> s;

s.push(1); // 向栈中添加元素
s.push(2);
s.push(3);

std::cout << "Top element is: " << s.top() << std::endl; // 访问栈顶元素

s.pop(); // 移除栈顶元素
std::cout << "After popping, top element is: " << s.top() << std::endl;

if (!s.empty()) { // 检查栈是否为空
    std::cout << "Stack is not empty." << std::endl;
}

std::cout << "Size of stack: " << s.size() << std::endl; // 打印栈的大小
```

== Map, Unordered_map
- 有序和无序的 map，前者用红黑树实现，后者用哈希表实现
- 所以优缺点也分别就是 “有序但是慢”，“无序但是快”
- 为什么不叫 `hash_map`？因为 `unordered_map` 是 C++11 新增的，在这之前一些编译器提供了自己的非标准扩展。但有了这个标准库的替代实现后，之前的这些扩展就不再需要了

== Deque
- 参考 #link("https://blog.csdn.net/yl_puyu/article/details/103361874")[[C++系列] 58. deque底层实现原理剖析]

#quote(caption: "Copied from Zhr")[
  - 常见容器的迭代器类型如下：
  + 有随机访问迭代器的容器包括 vector, deque, array
  + 有双向迭代迭代器的容器包括 list, set, map, multiset, multimap
  + 有前向迭代迭代器的容器包括 forward_list, unordered_set, unordered_map, unordered_multiset, unordered_multimap
  + 不支持迭代器的容器包括 stack, queue, priority_queue
  - 除了常见的 iterator 类型以外，STL 容器还提供了 const_iterator 类型，它只能访问容器中的常量元素，不能修改元素的值。而对于支持双向迭代器的容器，STL 容器还提供了 reverse_iterator 和 const_reverse_iterator 类型，它们可以逆序访问容器中的元素。

  - 支持迭代器的容器一般都有以下方法：
    + `begin()` 返回指向容器第一个元素的迭代器
    + `end()` 返回指向容器最后一个元素的下一个位置的迭代器
    + `cbegin()` 返回指向容器第一个元素的常量迭代器
    + `cend()` 返回指向容器最后一个元素的下一个位置的常量迭代器
    + `rbegin()` 返回指向容器最后一个元素的反向迭代器
    + `rend()` 返回指向容器第一个元素的前一个位置的反向迭代器
]
