pub const prefix = ":"

pub const newline = "\n"

pub const docs_env_var = "TESTAMENT_WITH_DOCS"

pub const js_args = ["javascript", "--runtime"]

pub const help = "📖 Testament
Doc tests for gleam! ✨

- `clean`: delete doc test files
- `clean all`: delete all doc test files (useful after code reorgs) 'test/**/*_doc_test.gleam' 
- `help`: prints this help message

-----------------------
Usage:

Write some beautiful gleam code with Doc Comments
```gleam
////Example Module
////```gleam
////: assert 1 + 1 == 2
////```

///adds two Ints
///```gleam
///: assert example.add(1, 2) == 3
///: assert example.add(1, -1) == 0
/// ```
pub fn add(a: Int, b: Int) -> Int {
  a + b
}
```

Add testament to your test's main function
```gleam
import gleeunit
import testament

pub fn main() -> Nil {
  testament.test_main(gleeunit.main)
}
```

Enjoy
```bash
gleam test
  Compiling example
   Compiled in 0.44s
    Running example_test.main
.
1 tests, no failures
```
"
