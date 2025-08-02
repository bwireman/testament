import argv
import envoy
import filepath
import gleam/io
import gleam/list
import platform
import shellout
import simplifile
import testament/internal/util

const help = "Testament 📖
Doc tests for gleam! ✨

- `clean`: delete doc test files
- `clean all`: delete all doc test files (useful after code reorgs) 'test/**/*_doc_test.gleam' 
- `help`: prints this help message

-----------------------
Usage:

Write some beautiful gleam code with Doc Comments
```gleam
///adds two Ints
///```
///: import example
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

pub fn main() -> Nil {
  case argv.load().arguments {
    ["clean"] -> {
      let _ = util.clean_doc_tests()

      Nil
    }

    ["clean", "all"] -> {
      let _ = util.clean_doc_tests()
      let _ = simplifile.delete(filepath.join("test", "testament"))

      Nil
    }

    ["-h"] | ["h"] | ["--help"] | ["help"] -> io.println(help)

    _ -> io.print_error("Unknown command")
  }
}

const docs_env_var = "TESTAMENT_WITH_DOCS"

const js_args = ["javascript", "--runtime"]

///Add testament to your test's main function and you're good to go!
///You can use gleeunit or any other testing framework
/// ```gleam
/// import gleeunit
/// import testament
/// 
/// pub fn main() -> Nil {
///   testament.test_main(gleeunit.main)
/// }
/// ```
pub fn test_main(run_tests: fn() -> Nil) -> Nil {
  let assert Ok(files) = simplifile.get_files("src")

  let assert Ok(_) =
    list.try_each(files, fn(file) {
      util.create_tests_for_file(file, [util.import_from_file_name(file)])
    })
  case envoy.get(docs_env_var) {
    Ok("1") -> run_tests()

    Error(_) | Ok(_) -> {
      let args = case platform.runtime() {
        platform.Erlang -> ["erlang"]
        platform.Bun -> list.append(js_args, ["bun"])
        platform.Deno -> list.append(js_args, ["deno"])
        platform.Node -> list.append(js_args, ["node"])
        platform.Browser | platform.OtherRuntime(_) ->
          panic as "testament: invalid runtime or target"
      }

      let _ =
        shellout.command("gleam", ["test", "--target", ..args], ".", [
          shellout.LetBeStderr,
          shellout.LetBeStdout,
          shellout.SetEnvironment([#(docs_env_var, "1")]),
        ])

      let assert Ok(_) = util.clean_doc_tests()

      Nil
    }
  }
}
