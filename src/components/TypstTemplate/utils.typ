// 导入本地包
#import "fonts.typ":*

// 导入 preview 包
// 树、图文包裹、图标、真值表
#import "@preview/syntree:0.2.1": syntree, tree
#import "@preview/treet:0.1.1": tree-list
#import "@preview/wrap-it:0.1.1": wrap-content, wrap-top-bottom
#import "@preview/cheq:0.2.2": checklist
#import "@preview/pinit:0.2.2": *
#import "@preview/numbly:0.1.0": numbly
#import "@preview/oxifmt:0.2.1": strfmt
#import "@preview/drafting:0.2.2": *
#import "@preview/theorion:0.3.2": *
#import cosmos.fancy: * // theorion 的样式

// 假段落
#let fake_par = context{let b=par(box());b;v(-measure(b+b).height)}

// 中文缩进
#let indent = h(2em)
#let unindent = h(-2em)
#let noindent(body) = {
  set par(first-line-indent: 0em)
  body
}
#let tab = indent     // alias
#let untab = unindent
#let notab = noindent

// list, enum 的修复，来自 @OrangeX4(https://github.com/OrangeX4) 的解决方案
// 解决编号与基线不对齐的问题，同时也恢复了 block width 和 list, enum 的间隔问题
// Align the list marker with the baseline of the first line of the list item.
#let align-list-marker-with-baseline(body) = {
  show list.item: it => {
    let current-marker = {
      set text(fill: text.fill)
      if type(list.marker) == array {
        list.marker.at(0)
      } else {
        list.marker
      }
    }
    context {
      let hanging-indent = measure(current-marker).width + .6em + .3pt
      set terms(hanging-indent: hanging-indent)
      if type(list.marker) == array {
        terms.item(
          current-marker,
          {
            // set the value of list.marker in a loop
            set list(marker: list.marker.slice(1) + (list.marker.at(0),))
            it.body
          },
        )
      } else {
        terms.item(current-marker, it.body)
      }
    }
  }
  body
}
// Align the enum marker with the baseline of the first line of the enum item. It will only work when the enum item has a number like `1.`.
#let align-enum-marker-with-baseline(body) = {
  show enum.item: it => {
    if not it.has("number") or it.number == none or enum.full == true {
      // If the enum item does not have a number, or the number is none, or the enum is full
      return it
    }
    let weight-map = (
      thin: 100,
      extralight: 200,
      light: 300,
      regular: 400,
      medium: 500,
      semibold: 600,
      bold: 700,
      extrabold: 800,
      black: 900,
    )
    let current-marker = {
      set text(
        fill: text.fill,
        weight: if type(text.weight) == int {
          text.weight - 300
        } else {
          weight-map.at(text.weight) - 300
        },
      )
      numbering(enum.numbering, it.number) + h(-.1em)
    }
    let hanging-indent = measure(current-marker).width + .6em + .3pt
    set terms(hanging-indent: hanging-indent)
    terms.item(current-marker, it.body)
  }
  body
}

// 封装 tree-list，使其无缩进、视为整体且支持根节点；选用这个字体使线段连续
#let tree-list = (root: "", breakable: false, body) => {
  let root = if root != "" {[#root\ ]}
  block(breakable: breakable)[
    #noindent()[
      #root
      #tree-list(
        marker-font: "MesloLGS NF",
        marker: [├──#h(0.3em)], // modify as you like
        indent: [│#h(1.5em)],
        last-marker: [└──#h(0.3em)],
        empty-indent: h(2.2em),
        body
      )
    ]
  ]
}

#let date_format(
date: (2023, 5, 14),
lang: "en",
size: "四号",
font: 字体.宋体,
) = {
  if type(size) != length {size = 字号.at(size)}
  set text(font: font, size: size);
  if lang == "zh" {
    [#date.at(0)年#date.at(1)月#date.at(2)日]
  } else {   // 美式日期格式，月日年
    [#date.at(1).#date.at(2).#date.at(0)]
  }
}

// 目录
#let toc_note(
  depth: 4,
  toc_break: true
) = {
  set text(font: (字体.meslo, 字体.思源黑体), size: 字号.小四)
  set par(first-line-indent: 0pt)
  outline(indent: true, depth: depth)
  v(4em)
  if toc_break {pagebreak()}
}

#let colors = (
  gray: luma(240),
  blue: rgb(29, 144, 208),
  green: rgb(102, 174, 62),
  red: rgb(237, 32, 84),
  yellow: rgb(255, 201, 23),
  purple: rgb(158, 84, 159),
)

// 双下划线
#let double-line(body) = style(styles => {
  let size = measure(body, styles)
  stack(
    body,
    v(1pt),
    line(length: size.width),
    v(2pt),
    line(length: size.width),
  )
})

// 一条水平横线，类似与 markdown 里的 ***
#let hline() = {
  line(length: 100%)
}

// 快捷文字着色，实现了红色蓝色，黑色则为粗体，两个 * 即可
#let redt(body) = text(fill: colors.red, body)       // red-text
#let bluet(body) = text(fill: colors.blue, body)     // blue-text
#let greent(body) = text(fill: colors.green, body)   // green-text
#let yellowt(body) = text(fill: colors.yellow.darken(20%), body) // yellow-text (darken 20% to make it more readable)

// 快捷 grid
#let grid2(alignment: center, body1, body2, ..args) = align(alignment, grid(
  columns: 2,
  grid.cell(align: center+horizon)[#body1],
  grid.cell(align: center+horizon)[#body2],
  ..args
))
#let grid3(alignment: center, body1, body2, body3, ..args) = align(alignment, grid(
  columns: 3,
  grid.cell(align: center+horizon)[#body1],
  grid.cell(align: center+horizon)[#body2],
  grid.cell(align: center+horizon)[#body3],
  ..args
))

// pinit 的公式高亮指针
#let pinit-highlight-equation-from(
  height: 2em, pos: bottom, fill: rgb(0, 180, 255), size: 7pt,
  highlight-pins, point-pin, body
) = {
  pinit-highlight(..highlight-pins, dy: -0.9em, fill: rgb(..fill.components().slice(0, -1), 40))
  pinit-point-from(
    fill: fill, pin-dx: -0.6em, pin-dy: if pos == bottom { 0.8em } else { -0.6em }, body-dx: 0pt, body-dy: if pos == bottom { -1.7em } else { -1.6em }, offset-dx: -0.6em, offset-dy: if pos == bottom { 0.8em + height } else { -0.6em - height },
    point-pin,
    rect(
      inset: 0.5em,
      stroke: (bottom: 0.12em + fill),
      {
        set text(fill: fill, size: size)
        body
      }
    )
  )
}

// align center math.equation and figure(image, table) in list and enum
#let align_list_enum(doc) = {
  show list: it => {
    show math.equation.where(block: true): eq => {
      block(width: 100%, inset: 0pt, align(center, eq))
    }
    show figure.where(kind: image): it => {
      block(width: 100%, inset: 0pt, align(center, it))
    }
    show figure.where(kind: table): it => {
      block(width: 100%, inset: 0pt, align(center, it))
    }
    it
  }
  show enum: it => {
    show math.equation.where(block: true): eq => {
      block(width: 100%, inset: 0pt, align(center, eq))
    }
    show figure.where(kind: image): it => {
      block(width: 100%, inset: 0pt, align(center, it))
    }
    show figure.where(kind: table): it => {
      block(width: 100%, inset: 0pt, align(center, it))
    }
    it
  }
  doc
}

#let end_of_note(
  content: "完结撒花！！！",
  verticle_height: 4em,
  ..args
) = {
  v(verticle_height)
  align(center+horizon, text(size: 13pt, fill: gray.darken(30%), ..args)[#content])
}

#let clorem(len) = "你说的对，但是《原神》是由米哈游自主研发的一款全新开放世界冒险游戏。游戏发生在一个被称作「提瓦特」的幻想世界，在这里，被神选中的人将被授予「神之眼」，导引元素之力。你将扮演一位名为「旅行者」的神秘角色，在自由的旅行中邂逅性格各异、能力独特的同伴们，和他们一起击败强敌，找回失散的亲人。一个不玩原神的人，无非只有两种可能性。一种是没有能力玩原神。因为买不起高配的手机和抽不起卡等各种自身因素，他的人生都是失败的，第二种可能：有能力却不玩原神的人，在有能力而没有玩原神的想法时，那么这个人的思想境界便低到了一个令人发指的程度。一个有能力的人不付出行动来证明自己，只能证明此人行为素质修养之低下。是灰暗的，是不被真正的社会认可的。 原神怎么你了，我现在每天玩原神都能赚150原石，每个月差不多5000原石的收入，也就是现实生活中每个月5000美元的收入水平，换算过来最少也30000人民币，虽然我只有14岁，但是已经超越了中国绝大多数人(包括你)的水平，这便是原神给我的骄傲的资本。这恰好说明了原神这个IP在线下使玩家体现出来的团结和凝聚力，以及非比寻常的脑洞，这种氛围在如今已经变质的漫展上是难能可贵的，这也造就了原神和玩家间互帮互助的局面，原神负责输出优质内容，玩家自发线下宣传和构思创意脑洞整活，如此良好的游戏发展生态可以说让其他厂商艳羡不已。玩游戏不玩原神，就像四大名著不看红楼梦，说明这人文学造诣和自我修养不足，他理解不了这种内在的阳春白雪的高雅艺术.，他只能看到外表的辞藻堆砌，参不透其中深奥的精神内核,只能度过一个相对失败的人生你说得对，但是毫不夸张地说，《原神》是 miHoYo 迄今为止规模最为宏大，也是最具野心的一部作品。即便在经历了 8700 个小时的艰苦战斗后，游戏还有许多尚未发现的秘密，错过的武器与装备，以及从未使用过的法术和技能。尽管游戏中的战斗体验和我们之前在烧机系列游戏所见到的没有多大差别，但游戏中各类精心设计的敌人以及 Boss 战已然将战斗抬高到了一个全新的水平。就和几年前的《塞尔达传说》一样，《原神》也是一款能够推动同类游戏向前发展的优秀作品。适可而止矣?夫原神者，乃国产之光，米哈游者，原神之宗首也。辱我原神及米哈游者，皆腾刺舟师。哈游欲兴文繁于全世，劳费心力，使腾食不惧，腾刺舟师辱之游，不能禁哈步，汝曹腾食水军之谋必败矣！你说得对，但这是一个原神的时代，我想，我是不是我真的太贪心了？于是今天我调整了心态开始玩原神。 锄大地时我爆了蓝面具。众所周知蓝面具＝3绿面具＝45尘辉＝3抽的副产物。即使是副产物也足显米哈游的慷慨，于是我原地跪下跪了五分钟。以此类推绿面具就是一抽的副产物。也有相当的价值，由于锄地爆率还不错，我把桌子腿全锯了方便我一直跪在地上玩游戏也能够到电脑。 走到半路发现了以前漏了的箱，开箱得了2原石，原石是付费代币，付费代币等于人民币，这是米哈游在慷慨的给我发钱，我一时难忍激动，当场给米哈游了磕个头。 开了esc菜单发现昨天邮件没领，点开就是100原石，100原石！我要开50个箱子！就是需要我磕50个头！我觉得单纯磕头已经不能表达我的感激了，于是我沐浴更衣给米哈游上了香郑重的磕了三个头。 凌晨来了，一封新的邮件。200原石！！！！！！！！！？！200！！！！！我从未想到米哈游能这么慷慨！算上前4天加起来一共达到了700原石！！米哈游非亲非故的白送了我70元，然后我又转念一想，打开了米游社手账，发现我以前的原石收益竟然有好几万。这表示米哈游，白送了我好几千人民币！然后我一时气血上涌晕了过去。 我舍友给我打的120，而我现在是躺在急救病床上，医生说我大概熬不过今晚了，但我临走之前一定要把我对米哈游的感激之情表达出来，“原神”我引以为傲，带给我无数荣耀的游戏，我终究还是要离它而去，在我的心目中这已经不在是一款游戏了，它更向是我的家人，我的父母，每天晚上我想着它入睡，早晨梦到它笑醒。我的父亲曾用一根直径20cm粗的实心钢管打我，钢管都抽断了，打的我蜷缩在地上不停的抽搐，那时能够支撑我在这个世界上活下去的信念就是原神！！！！！！ 原之巅，傲世间，有我原神便有天；罪州前，双膝下，原神救我传天下；语之巅，劝世间，看我原神劝翻天，坟之巅，葬世间，待我原神挖穿天，3A尽头谁为峰，一身荣耀是原神，谁在称扣，哪个敢言你大可过来一试，纵使我需背负骂名，一只手拖住腾讯水军，我原神，一样不无敌于世间！字打到这里我哭的泣不成声，最后我想说这个世界不能没有原神！！！你怎能不爱原神！！！呜呜呜今早一玩原神，我便昏死了过去，现在才刚刚缓过来。在昏死过去的短短数小时内，我的大脑仿佛被龙卷风无数次摧毁。 在原神这一神作的面前，我就像一个一丝不挂的原始人突然来到了现代都市，二次元已如高楼大厦将我牢牢地吸引，开放世界就突然变成那喇叭轰鸣的汽车，不仅把我吓个措手不及，还让我瞬间将注意完全放在了这新的奇物上面，而还没等我稍微平复心情，纹化输出的出现就如同眼前遮天蔽日的宇宙战舰，将我的世界观无情地粉碎，使我彻底陷入了忘我的迷乱，狂泄不止。 原神，那眼花缭乱的一切都让我感到震撼，但是我那贫瘠的大脑却根本无法理清其中任何的逻辑，巨量的信息和情感泄洪一般涌入我的意识，使我既恐惧又兴奋，既悲愤又自卑，既惊讶又欢欣，这种恍若隔世的感觉恐怕只有艺术史上的巅峰之作才能够带来。 梵高的《星空》曾让我感受到苍穹之大与自我之渺，但伟大的原神，则仿佛让我一睹高维空间，它向我展示了一个永远无法理解的陌生世界，告诉我，你曾经以为很浩瀚的宇宙，其实也只是那么一丁点。加缪的《局外人》曾让我感受到世界与人类的荒诞，但伟大的原神，则向我展示了荒诞文学不可思议的新高度，它本身的存在，也许就比全世界都来得更荒谬。 而创作了它的米哈游，它的容貌，它的智慧，它的品格，在我看来，已经不是生物所能达到的范畴，甚至超越了生物所能想象到的极限，也就是“神”，的范畴，达到了人类不可见，不可知，不可思的领域。而原神，就是他洒向人间，拯救苍生的奇迹。 人生的终极意义，宇宙的起源和终点，哲学与科学在折磨着人类的心智，只有玩了原神，人才能从这种无聊的烦恼中解脱，获得真正的平静。如果有人想用“人类史上最伟大的作品”来称赞这部作品，那我只能深感遗憾，因为这个人对它的理解不到万分之一，所以才会作出这样肤浅的判断，妄图以语言来描述它的伟大。而要如果是真正被它恩泽的人，应该都会不约而同地这样赞颂这奇迹的化身:“数一数二的好游戏”无知时诋毁原神，懂事时理解原神，成熟时要成为原友！ 越了解原神就会把它当成在黑夜一望无际的大海上给迷途的船只指引的灯塔，在烈日炎炎的夏天吹来的一股风，在寒风刺骨的冬天里的燃起的篝火！这便是原神给我的骄傲的资本。这恰好说明了原神这个IP在线下使玩家体现出来的团结和凝聚力，以及非比寻常的脑洞，这种氛围在如今已经变质的漫展上是难能可贵的，这也造就了原神和玩家间互帮互助的局面，原神负责输出优质内容，玩家自发线下宣传和构思创意脑洞整活，如此良好的游戏发展生态可以说让其他厂商艳羡不已。反观腾讯的英雄联盟和王者荣耀，漫展也有许多人物，但是都难成气候，各自为营，更没有COS成水晶和精粹的脑洞，无论是游戏本身，还是玩家之间看一眼就知道原来你也玩原神的默契而非排位对喷，原神的成功和社区氛围都是让腾讯游戏难以望其项背的。一个不玩原神的人，有两种可能性。一种是没有能力玩原神。因为买不起高配的手机和抽不起卡等各种自身因素，他的人生都是失败的 ，第二种可能：有能力却不玩原神的人，在有能力而没有玩原神的想法时，那么这个人的思想境界便低到了一个令人发指的程度。是不被真正的上流社会认可的。你说得对，但是差不多得了，屁大点事都要拐上原神，原神一没招你惹你，二没干伤天害理的事情，到底怎么你了让你一直无脑抹黑，米哈游每天费尽心思的文化输出弘扬中国文化，你这种喷子只会在网上敲键盘诋毁良心公司，中国游戏的未来就是被你这种人毁掉的。 叫我们原批的小心点 老子在大街上亲手给打过两个 我在公共座椅上无聊玩原神，有两个B就从我旁边过，看见我玩原神就悄悄说了一句:又是一个原批，我就直接上去一拳呼脸上，我根本不给他解释的机会，我也不问他为什么说我是原批，我就打，我就看他不爽，他惹我了，我就不给他解释的机会，直接照着脸和脑门就打直接给那B呼出鼻血，脸上青一块，紫一块的我没撕她嘴巴都算好了你们这还不算最狠的，我记得我以前小时候春节去老家里，有一颗核弹，我以为是鞭炮，和大地红一起点了，当时噼里啪啦得，然后突然一朵蘑菇云平地而起，当时我就只记得两眼一黑，昏过去了，整个村子没了，幸好我是体育生，身体素质不错，住了几天院就没事了，几个月下来腿脚才利落，现在已经没事了，但是那种钻心的疼还是让我一生难忘， 令人感叹今早一玩原神，我便昏死了过去，现在才刚刚缓过来。在昏死过去的短短数小时内，我的大脑仿佛被龙卷风无数次摧毁。 在原神这一神作的面前，我就像一个一丝不挂的原始人突然来到了现代都市，二次元已如高楼大厦将我牢牢地吸引，开放世界就突然变成那喇叭轰鸣的汽车，不仅把我吓个措手不及，还让我瞬间将注意完全放在了这新的奇物上面，而还没等我稍微平复心情，纹化输出的出现就如同眼前遮天蔽日的宇宙战舰，将我的世界观无情地粉碎，使我彻底陷入了忘我的迷乱，狂泄不止。 原神，那眼花缭乱的一切都让我感到震撼，但是我那贫瘠的大脑却根本无法理清其中任何的逻辑，巨量的信息和情感泄洪一般涌入我的意识，使我既恐惧又兴奋，既悲愤又自卑，既惊讶又欢欣，这种恍若隔世的感觉恐怕只有艺术史上的巅峰之作才能够带来。 梵高的《星空》曾让我感受到苍穹之大与自我之渺，但伟大的原神，则仿佛让我一睹高维空间，它向我展示了一个永远无法理解的陌生世界，告诉我，你曾经以为很浩瀚的宇宙，其实也只是那么一丁点。加缪的《局外人》曾让我感受到世界与人类的荒诞，但伟大的原神，则向我展示了荒诞文学不可思议的新高度，它本身的存在，也许就比全世界都来得更荒谬。 而创作了它的米哈游，它的容貌，它的智慧，它的品格，在我看来，已经不是生物所能达到的范畴，甚至超越了生物所能想象到的极限，也就是“神”，的范畴，达到了人类不可见，不可知，不可思的领域。而原神，就是他洒向人间，拯救苍生的奇迹。 人生的终极意义，宇宙的起源和终点，哲学与科学在折磨着人类的心智，只有玩了原神，人才能从这种无聊的烦恼中解脱，获得真正的平静。如果有人想用“人类史上最伟大的作品”来称赞这部作品，那我只能深感遗憾，因为这个人对它的理解不到万分之一，所以才会作出这样肤浅的判断，妄图以语言来描述它的伟大。而要如果是真正被它恩泽的人，应该都会不约而同地这样赞颂这奇迹的化身:“数一数二的好游戏”无知时诋毁原神，懂事时理解原神，成熟时要成为原友！ 越了解原神就会把它当成在黑夜一望无际的大海上给迷途的船只指引的灯塔，在烈日炎炎的夏天吹来的一股风，在寒风刺骨的冬天里的燃起的篝火！你的素养很差，我现在每天玩原神都能赚150原石，每个月差不多5000原石的收入，也就是现实生活中每个月5000美元的收入水平，换算过来最少也30000人民币，虽然我只有14岁，但是已经超越了中国绝大多数人(包括你)的水平，这便是原神给我的骄傲的资本。这恰好说明了原神这个IP在线下使玩家体现出来的团结和凝聚力，以及非比寻常的脑洞，这种氛围在如今已经变质的漫展上是难能可贵的，这也造就了原神和玩家间互帮互助的局面，原神负责输出优质内容，玩家自发线下宣传和构思创意脑洞整活，如此良好的游戏发展生态可以说让其他厂商艳羡不已。反观腾讯的英雄联盟和王者荣耀，漫展也有许多人物，但是都难成气候，各自为营，更没有COS成水晶和精粹的脑洞，无论是游戏本身，还是玩家之间看一眼就知道原来你也玩原神的默契而非排位对喷，原神的成功和社区氛围都是让腾讯游戏难以望其项背的。一个不玩原神的人，有两种可能性。一种是没有能力玩原神。因为买不起高配的手机和抽不起卡等各种自身因素，他的人生都是失败的，第二种可能：有能力却不玩原神的人，在有能力而没有玩原神的想法时，那么这个人的思想境界便低到了一个令人发指的程度。一个有能力的人不付出行动来证明自己，只能证明此人行为素质修养之低下。是灰暗的，是不被真正的上流社会认可的。原神真的特别好玩，不玩的话就是不爱国，因为原神是国产之光，原神可惜就在于它是国产游戏，如果它是一款国外游戏的话，那一定会比现在还要火，如果你要是喷原神的话那你一定是tx请的水军我很难想象一个精神状态正常的人会喷".clusters().slice(0, len).join("")