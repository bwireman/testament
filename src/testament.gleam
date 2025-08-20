import argv
import envoy
import filepath
import gleam/dict
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import platform
import shellout
import simplifile
import testament/conf
import testament/internal/util

const help = "📖 Testament
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

    _ -> {
      io.print_error("Unknown command")
      shellout.exit(1)
    }
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
  test_main_with_opts(run_tests, [])
}

///Add testament to your test's main function and you're good to go!
///You can use gleeunit or any other testing framework.
///- Config options [here](https://hexdocs.pm/testament/testament/conf.html)
/// ```gleam
/// import gleeunit
/// import testament
/// import testament/conf
///
/// pub fn main() -> Nil {
///   testament.test_main_with_opts(gleeunit.main, [conf.IgnoreFiles(["src/example.gleam"])])
/// }
/// ```
pub fn test_main_with_opts(run_tests: fn() -> Nil, opts: List(conf.Conf)) -> Nil {
  let cfg = util.combine_conf_values(opts)

  case envoy.get(docs_env_var) {
    Ok(_) -> run_tests()

    Error(_) -> {
      util.verbose_log(cfg.verbose, "reading src directory")
      let assert Ok(files) = simplifile.get_files("src")
        as "could not read 'src' directory"

      let files =
        list.filter(files, fn(f) {
          string.ends_with(f, ".gleam") && !list.contains(cfg.ignore_files, f)
        })

      let assert Ok(Nil) =
        list.try_each(files, fn(file) {
          util.verbose_log(cfg.verbose, "creating doc tests for: " <> file)

          let imports =
            dict.get(cfg.extra_imports, file)
            |> result.unwrap([])

          util.create_tests_for_file(file, imports)
        })
        as "failed to read source files"

      let assert Ok(Nil) =
        list.try_each(cfg.markdown_files, fn(file) {
          util.verbose_log(cfg.verbose, "creating doc tests for: " <> file)

          let imports =
            dict.get(cfg.extra_imports, file)
            |> result.unwrap([])

          util.create_tests_for_markdown_file(file, imports)
        })
        as "failed to read source files"

      util.verbose_log(cfg.verbose, "compiling doc tests")

      let args = case platform.runtime() {
        platform.Erlang -> ["erlang"]
        platform.Bun -> list.append(js_args, ["bun"])
        platform.Deno -> list.append(js_args, ["deno"])
        platform.Node -> list.append(js_args, ["node"])
        _ -> panic as "testament: invalid runtime or target"
      }

      let args = list.append(["test", "--target"], args)

      util.verbose_log(
        cfg.verbose,
        "running '" <> string.join(["gleam", ..args], " ") <> "'",
      )

      let res =
        shellout.command("gleam", args, ".", [
          shellout.LetBeStderr,
          shellout.LetBeStdout,
          shellout.SetEnvironment([#(docs_env_var, "1")]),
        ])

      case cfg.preserve_files {
        False -> {
          util.verbose_log(cfg.verbose, "deleting generated doc tests")

          let assert Ok(Nil) =
            simplifile.delete(filepath.join("test", "testament"))
            as "failed to clean doc test"

          Nil
        }
        _ -> {
          let assert Ok(_) =
            shellout.command("gleam", ["format", "test/testament"], ".", [])
            as "failed to format generated tests"

          Nil
        }
      }

      case res {
        Error(#(code, _)) -> shellout.exit(code)
        Ok(_) -> Nil
      }
    }
  }
}
