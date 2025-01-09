
// #show list.item: it => {
//   for body in it.fields() {
//     it = it + h(1fr)
//   }
//   it.fields()
//   // it
// }
//
#show math.equation.where(block: true): eq => {
  block(width: 100%, inset: 0pt, align(center, eq))
}
// #show image: it => {
// #show figure.where(kind: "image"): it => {
//   block(width: 100%, inset: 0pt, align(center, it))
// }
#show list: it => {
  show figure.where(kind: "image"): it => {
    block(width: 100%, inset: 0pt, align(center, it))
  }
  it
}

// #let fig(alignment: center, ..args) = align(alignment, image(..args))
#let fig(..args) = figure(
  kind: "image",
  supplement: none,
  image(..args)
)

// #let a = figure(image("/public/assets/Courses/CV/2024-09-20-17-00-54.png"))
#let a = fig("/public/assets/Courses/CV/2024-09-20-17-00-54.png")
#a.fields()

- 透视投影
  // #figure(image("/public/assets/Courses/CV/2024-09-20-17-00-54.png", width: 60%))
  #fig("/public/assets/Courses/CV/2024-09-20-17-00-54.png", width: 60%)



= test1
- test
  $ a + b $
  - second level
    #figure(box([1]))
- first level
- first level2

= test2
- test
  $ a + b $
  #align(center, "test")

#let a = list(
  [test1],
  list(
    [test2]
  )
)
