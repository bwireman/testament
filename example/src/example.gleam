//// Example Module docs
////: assert example.add(1, 0) == example.sub(2, 1)

import gleam/option

///other comment
/// ```
///: let x = example.add(1, 2)
///: assert x == 3
///:
///: let y =
///: example.add(1, 1)
///: |> example.add(2)
///: |> example.add(3)
///:
///: assert y == {x * 2} + 1
/// ```
/// with implicit assert
/// ```
///: example.add(1, 2)
///:: 3
/// ```
pub fn add(a: Int, b: Int) -> Int {
  a + b
}

///other comment
///: let x = example.sub(1, 2)
///: assert x == -1
///: assert example.sub(2, 1) == 1
pub fn sub(a: Int, b: Int) -> Int {
  a - b
}

pub type SuperInt {
  SuperInt(v: Int)
}

///: let x = example.super_add(SuperInt(1), SuperInt(2))
///: assert x == Some(SuperInt(3))
///: assert example.super_add(SuperInt(-10), SuperInt(1)) == None
pub fn super_add(a: SuperInt, b: SuperInt) -> option.Option(SuperInt) {
  let sum = a.v + b.v
  case sum > 0 {
    True -> option.Some(SuperInt(sum))
    _ -> option.None
  }
}
