//// Example Module docs
////: assert example.add(1, 0) == example.sub(2, 1)

///other comment
/// ```
///: let x = example.add(1, 2)
///: assert x == 3
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
