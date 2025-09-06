import filepath
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import simplifile
import testament/conf
import testament/internal/constants
import testament/internal/parse
import testament/internal/stream

pub fn get_test_file_name(file: String) -> String {
  file
  |> string.replace("src", "")
  |> string.replace(".md", "_md.gleam")
  |> string.replace(".gleam", "_doc_test.gleam")
  |> filepath.join("testament", _)
  |> filepath.join("test", _)
}

pub fn clean_doc_tests() -> Result(Nil, simplifile.FileError) {
  use files <- result.try(simplifile.get_files("src"))
  files
  |> stream.new()
  |> stream.map(get_test_file_name)
  |> stream.to_list()
  |> simplifile.delete_all()
}

pub fn import_from_file_name(file: String) -> String {
  let assert Ok(module) =
    file
    |> filepath.strip_extension()
    |> filepath.split()
    |> list.rest()
    as { "could not construct file name for '" <> file <> "'" }

  list.fold(module, "", filepath.join)
}

pub fn create_tests_for_file(
  file: String,
  extra_imports: List(parse.Import),
) -> Result(Nil, simplifile.FileError) {
  let assert Ok(file_content) = simplifile.read(file)
    as { "could not read file '" <> file <> "'" }

  let #(imports, tests) = parse.get_doc_tests_imports_and_code(file_content)
  let imports = list.append(imports, extra_imports)

  do_create_tests(file, imports, tests)
}

pub fn create_tests_for_markdown_file(
  file: String,
  extra_imports: List(parse.Import),
) -> Result(Nil, simplifile.FileError) {
  let assert Ok(file_content) = simplifile.read(file)
    as { "could not read file '" <> file <> "'" }

  let #(imports, tests) = parse.parse_markdown_snippets(file_content)
  do_create_tests(file, list.append(imports, extra_imports), tests)
}

fn do_create_tests(
  filepath: String,
  imports: List(parse.Import),
  tests: List(parse.CodeBlock),
) -> Result(Nil, simplifile.FileError) {
  case tests {
    [] -> Ok(Nil)
    _ -> {
      let imports =
        imports
        |> list.unique()
        |> string.join(constants.newline)

      let test_file_name = get_test_file_name(filepath)

      let _ = simplifile.delete(test_file_name)

      let assert Ok(Nil) =
        test_file_name
        |> filepath.directory_name()
        |> simplifile.create_directory_all()
        as "failed to create test doc directory"

      let assert Ok(Nil) =
        simplifile.append(test_file_name, imports <> constants.newline)

      list.index_map(tests, fn(code, index) {
        string.join(
          ["\npub fn doc" <> int.to_string(index) <> "_test() {", code, "}\n"],
          constants.newline,
        )
        |> simplifile.append(test_file_name, _)
      })
      |> result.all()
      |> result.replace(Nil)
    }
  }
}

pub type Config {
  Config(
    ignore_files: List(String),
    verbose: Bool,
    preserve_files: Bool,
    extra_imports: dict.Dict(String, List(conf.Import)),
    markdown_files: List(String),
  )
}

pub fn combine_conf_values(opts: List(conf.Conf)) -> Config {
  list.fold(
    opts,
    Config(
      ignore_files: [],
      verbose: False,
      preserve_files: False,
      extra_imports: dict.new(),
      markdown_files: [],
    ),
    fn(cfg, opt) {
      case opt {
        conf.ExtraImports(file, imports) -> {
          Config(
            ..cfg,
            extra_imports: dict.insert(cfg.extra_imports, file, imports),
          )
        }
        conf.IgnoreFiles(files) ->
          Config(..cfg, ignore_files: list.append(cfg.ignore_files, files))
        conf.PreserveFiles -> Config(..cfg, preserve_files: True)

        conf.Verbose -> Config(..cfg, verbose: True)

        conf.Markdown(files) ->
          Config(..cfg, markdown_files: list.append(cfg.markdown_files, files))
      }
    },
  )
}

pub fn verbose_log(log: Bool, msg: String) -> Nil {
  case log {
    True -> io.println("testament: " <> msg)
    False -> Nil
  }
}

pub fn combine_unqualified(imports: List(conf.Import)) -> List(String) {
  list.group(imports, fn(i) { i.module })
  |> dict.to_list()
  |> list.fold([], fn(acc, i) {
    list.prepend(
      acc,
      conf.Import(
        module: pair.first(i),
        unqualified: list.flat_map(pair.second(i), fn(v) { v.unqualified }),
      ),
    )
  })
  |> list.map(fn(i) {
    case i {
      conf.Import(module, []) -> "import " <> module
      conf.Import(module, unqualified) ->
        "import "
        <> module
        <> ".{"
        <> string.join(list.unique(unqualified), ", ")
        <> "}"
    }
  })
}
