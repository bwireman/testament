# 📖 Testament

Doc tests for gleam! ✨

[![Package Version](https://img.shields.io/hexpm/v/testament)](https://hex.pm/packages/testament)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/testament/)

```sh
gleam add --dev testament
```

## Usage:

### Write some beautiful gleam code with Doc Comments 📒 (or Markdown!)

More info on [Writing Tests 🔗](https://hexdocs.pm/testament/writing_tests.html)

````gleam
////Example Module doc test
////```gleam
////: assert 1 + 1 == 2
////```

///Example function doc test
///adds two Ints
///```gleam
///: assert example.add(1, 2) == 3
///: assert example.add(1, -1) == 0
///```
pub fn add(a: Int, b: Int) -> Int {
  a + b
}
````

### Add testament to your test's main function

```gleam
import gleeunit
import testament

pub fn main() -> Nil {
  testament.test_main(gleeunit.main)
}
```

### ✨ Enjoy

```bash
gleam test
  Compiling example
   Compiled in 0.44s
    Running example_test.main
.
1 test, no failures
```

### Note

#### If seeing files you don't want checked in

(these should get deleted after the run)

```bash
echo -e "\ntest/testament/*" >> .gitignore
```

#### If running with Deno

```toml
[javascript.deno]
allow_read = true
allow_write = true
allow_env = ["TESTAMENT_WITH_DOCS", "PATHEXT", "PATH"]
allow_run = ["gleam"]
```
