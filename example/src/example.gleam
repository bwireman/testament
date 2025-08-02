//// Example Module docs
////: import example
////: assert example.add(1, 0) == example.sub(2, 1)

///other comment
/// ```
///: import example
///: let x = example.add(1, 2)
///: assert x == 3
/// ```
pub fn add(a: Int, b: Int) -> Int {
  a + b
}

///other comment
///: import example
///: let x = example.sub(1, 2)
///: assert x == -1
///: assert example.sub(2, 1) == 1
pub fn sub(a: Int, b: Int) -> Int {
  a - b
}
