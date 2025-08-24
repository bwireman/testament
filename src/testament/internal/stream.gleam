import gleam/function
import gleam/list

pub opaque type Stream(a, b) {
  Step(List(a), fn(List(a)) -> List(b))
}

pub fn new(vals: List(a)) -> Stream(a, a) {
  Step(vals, function.identity)
}

pub fn map(s: Stream(a, b), f: fn(b) -> c) -> Stream(a, c) {
  let Step(values, curr) = s

  Step(values, fn(vals) { curr(vals) |> list.map(f) })
}

pub fn filter(s: Stream(a, b), f: fn(b) -> Bool) -> Stream(a, b) {
  let Step(values, curr) = s

  Step(values, fn(vals) { curr(vals) |> list.filter(f) })
}

pub fn to_list(s: Stream(a, b)) -> List(b) {
  let Step(values, curr) = s

  curr(values)
}
