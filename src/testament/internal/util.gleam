import filepath
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import glexer
import glexer/token
import simplifile
import testament/conf
import testament/internal/markdown

const prefix = ":"

pub fn get_test_file_name(file: String) -> String {
  file
  |> string.replace("src", "")
  |> string.replace(".gleam", "_doc_test.gleam")
  |> filepath.join("testament", _)
  |> filepath.join("test", _)
}

pub type DocState {
  DocState(
    in: Bool,
    lines: List(token.Token),
    test_bodies: List(List(token.Token)),
  )
}

pub type Import =
  String

pub type CodeBlock =
  String

pub fn get_doc_tests_imports_and_code(
  code: String,
) -> #(List(Import), List(CodeBlock)) {
  let prefix_len = string.length(prefix)

  code
  |> glexer.new()
  |> glexer.discard_whitespace()
  |> glexer.lex()
  |> list.map(pair.first)
  |> list.filter(is_doc)
  |> collect_test_lines()
  |> list.map(fn(tokens) {
    tokens
    |> list.filter(is_doctest_line)
    |> list.map(token.to_source)
    |> list.map(string.crop(_, prefix))
    |> list.map(string.drop_start(_, prefix_len))
    |> list.map(string.trim)
    |> list.fold(#([], []), split_imports_and_code)
    |> pair.map_second(string.join(_, "\n"))
  })
  |> list.fold(#([], []), fn(acc, block) {
    acc
    |> pair.map_first(list.append(_, pair.first(block)))
    |> pair.map_second(list.prepend(_, pair.second(block)))
  })
}

pub fn collect_test_lines(tokens: List(token.Token)) -> List(List(token.Token)) {
  let state = list.fold(tokens, DocState(False, [], []), fold_doc_state)

  case state.lines {
    [] -> state.test_bodies
    _ -> list.prepend(state.test_bodies, list.reverse(state.lines))
  }
}

pub fn fold_doc_state(state: DocState, line: token.Token) {
  case state, line {
    DocState(False, lines, _), token.CommentDoc(":" <> _)
    | DocState(False, lines, _), token.CommentModule(":" <> _)
    -> DocState(..state, in: True, lines: [line, ..lines])

    DocState(True, lines, _), token.CommentDoc(":" <> _)
    | DocState(True, lines, _), token.CommentModule(":" <> _)
    -> DocState(..state, lines: [line, ..lines])

    DocState(True, lines, bodies), _ ->
      DocState(
        in: False,
        lines: [],
        test_bodies: list.prepend(bodies, list.reverse(lines)),
      )

    _, _ -> state
  }
}

pub fn is_doc(line: token.Token) -> Bool {
  case line {
    token.CommentDoc(_) -> True
    token.CommentModule(_) -> True
    _ -> False
  }
}

pub fn is_doctest_line(line: token.Token) -> Bool {
  case line {
    token.CommentDoc(":" <> _) -> True
    token.CommentModule(":" <> _) -> True
    _ -> False
  }
}

pub fn split_imports_and_code(
  code: #(List(String), List(String)),
  line: String,
) -> #(List(String), List(String)) {
  case string.starts_with(line, "import") {
    True -> pair.map_first(code, list.prepend(_, line))
    False -> pair.map_second(code, list.append(_, [line]))
  }
}

pub fn clean_doc_tests() -> Result(Nil, simplifile.FileError) {
  use files <- result.try(simplifile.get_files("src"))
  files
  |> list.map(get_test_file_name)
  |> simplifile.delete_all()
}

pub fn import_from_file_name(file: String) -> String {
  let assert Ok(module) =
    file
    |> filepath.strip_extension()
    |> filepath.split()
    |> list.rest()
    as { "could not construct file name for '" <> file <> "'" }

  "import " <> list.fold(module, "", filepath.join)
}

pub fn create_tests_for_file(
  file: String,
  extra_imports: List(String),
) -> Result(Nil, simplifile.FileError) {
  let assert Ok(file_content) = simplifile.read(file)
    as { "could not read file '" <> file <> "'" }

  let #(imports, tests) = get_doc_tests_imports_and_code(file_content)
  do_create_tests(file, list.append(imports, extra_imports), tests)
}

pub fn create_tests_for_markdown_file(
  file: String,
  extra_imports: List(String),
) -> Result(Nil, simplifile.FileError) {
  let tests = markdown.parse_snippets(file)
  do_create_tests(file, extra_imports, tests)
}

fn do_create_tests(filepath: String, imports: List(String), tests: List(String)) {
  case tests {
    [] -> Ok(Nil)
    _ -> {
      let imports = string.join(imports, "\n")

      let test_file_name = get_test_file_name(filepath)

      let _ = simplifile.delete(test_file_name)

      let assert Ok(Nil) =
        test_file_name
        |> filepath.directory_name()
        |> simplifile.create_directory_all()
        as "failed to create test doc directory"

      let assert Ok(Nil) = simplifile.append(test_file_name, imports <> "\n")

      list.index_map(tests, fn(code, index) {
        string.join(
          ["\npub fn doc" <> int.to_string(index) <> "_test() {", code, "}\n"],
          "\n",
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
    extra_imports: dict.Dict(String, List(String)),
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
        conf.ExtraImports(file, imports) ->
          Config(
            ..cfg,
            extra_imports: dict.insert(
              cfg.extra_imports,
              file,
              imports
                |> list.map(string.trim)
                |> list.map(string.append("import ", _)),
            ),
          )
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

pub fn verbose_log(log: Bool, msg: String) {
  case log {
    True -> io.println("testament: " <> msg)
    False -> Nil
  }
}
