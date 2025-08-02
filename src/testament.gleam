import argv
import envoy
import filepath
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import platform
import shellout
import simplifile
import testament/internal/util

const help = "Testament 📖
Doc tests for gleam! ✨

- `create`: create doc test files
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
      let _ = clean_doc_tests()

      Nil
    }

    ["clean", "all"] -> {
      let _ = clean_doc_tests()
      let _ = simplifile.delete(filepath.join("test", "testament"))

      Nil
    }

    ["create"] -> {
      let _ = clean_doc_tests()
      let assert Ok(files) = simplifile.get_files("src")
      let assert Ok(_) = list.try_each(files, create_tests_for_file)

      Nil
    }

    ["h"] | ["help"] -> io.println(help)

    _ -> io.print_error("Unknown command")
  }
}

const docs_env_var = "TESTAMENT_WITH_DOCS"

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

  let assert Ok(_) = list.try_each(files, create_tests_for_file)
  case envoy.get(docs_env_var) {
    Ok("1") -> run_tests()

    Error(_) | Ok(_) -> {
      let args = case platform.runtime() {
        platform.Erlang -> ["erlang"]
        platform.Bun -> ["javascript", "--runtime", "bun"]
        platform.Deno -> ["javascript", "--runtime", "deno"]
        platform.Node -> ["javascript", "--runtime", "node"]
        platform.Browser | platform.OtherRuntime(_) ->
          panic as "testament: invalid runtime or target"
      }

      let _ =
        shellout.command("gleam", ["test", "--target", ..args], ".", [
          shellout.LetBeStderr,
          shellout.LetBeStdout,
          shellout.SetEnvironment([#(docs_env_var, "1")]),
        ])

      let assert Ok(_) = clean_doc_tests()

      Nil
    }
  }
}

fn clean_doc_tests() -> Result(Nil, simplifile.FileError) {
  use files <- result.try(simplifile.get_files("src"))
  files
  |> list.map(util.get_test_file_name)
  |> simplifile.delete_all()
}

fn create_tests_for_file(file: String) {
  let assert Ok(file_content) = simplifile.read(file)

  let #(imports, code) = util.get_doc_tests_imports_and_code(file_content)

  case string.is_empty(code) {
    True -> Ok(Nil)
    _ -> {
      let test_file_name = util.get_test_file_name(file)

      let _ =
        test_file_name
        |> filepath.directory_name()
        |> simplifile.create_directory_all()

      let test_content =
        string.join([imports, "pub fn doc_test() {", code, "}"], "\n")

      let _ = simplifile.delete(test_file_name)

      let assert Ok(Nil) = simplifile.append(test_file_name, test_content)
    }
  }
}
