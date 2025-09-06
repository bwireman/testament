import gleeunit
import testament
import testament/conf

pub fn main() -> Nil {
  testament.test_main_with_opts(gleeunit.main, [
    conf.ExtraImports("src/example.gleam", [
      conf.Import("gleam/option", ["None", "Some"]),
      conf.Import("example", ["SuperInt"]),
    ]),
  ])
}
