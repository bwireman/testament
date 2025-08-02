import filepath
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import glexer
import glexer/token
import simplifile

const prefix = ":"

const open = token.CommentDoc(prefix <> "{")

const close = token.CommentDoc(prefix <> "}")

pub fn get_test_file_name(file: String) -> String {
  file
  |> string.replace("src", "")
  |> string.replace(".gleam", "_doc_test.gleam")
  |> filepath.join("testament", _)
  |> filepath.join("test", _)
}

pub fn get_doc_tests_imports_and_code(
  code: String,
  other_imports: List(String),
) -> #(String, String) {
  let cases =
    code
    |> glexer.new()
    |> glexer.lex()
    |> list.map(pair.first)
    |> list.filter(is_doc)
    |> list.fold(DocState(False, []), fold_doc_state)

  let lines = case cases.in {
    True -> list.append(cases.lines, [close])
    _ -> cases.lines
  }

  lines
  |> list.filter(is_doctest_line)
  |> list.map(token.to_source)
  |> list.map(string.crop(_, prefix))
  |> list.map(string.drop_start(_, 1))
  |> list.map(string.trim)
  |> list.fold(#(other_imports, []), split_imports_and_code)
  |> pair.map_first(list.unique)
  |> pair.map_first(string.join(_, "\n"))
  |> pair.map_second(string.join(_, "\n"))
}

type DocState {
  DocState(in: Bool, lines: List(token.Token))
}

fn fold_doc_state(state: DocState, line: token.Token) {
  case state, line {
    DocState(False, lines), token.CommentDoc(":" <> _)
    | DocState(False, lines), token.CommentModule(":" <> _)
    -> DocState(True, list.append(lines, [open, line]))

    DocState(True, lines), token.CommentDoc(":" <> _)
    | DocState(True, lines), token.CommentModule(":" <> _)
    -> DocState(..state, lines: list.append(lines, [line]))

    DocState(True, lines), _ ->
      DocState(False, list.append(lines, [line, close]))

    _, _ -> DocState(..state, lines: list.append(state.lines, [line]))
  }
}

pub fn is_doc(t: token.Token) -> Bool {
  case t {
    token.CommentDoc(_) -> True
    token.CommentModule(_) -> True
    _ -> False
  }
}

pub fn is_doctest_line(t: token.Token) -> Bool {
  case t {
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
    True -> pair.map_first(code, list.append(_, [line]))
    False -> pair.map_second(code, list.append(_, [line]))
  }
}

pub fn clean_doc_tests() -> Result(Nil, simplifile.FileError) {
  use files <- result.try(simplifile.get_files("src"))
  files
  |> list.map(get_test_file_name)
  |> simplifile.delete_all()
}

pub fn import_from_file_name(file: String) {
  let assert Ok(module) =
    file
    |> filepath.strip_extension
    |> filepath.split()
    |> list.rest()

  "import " <> list.fold(module, "", filepath.join)
}

pub fn create_tests_for_file(file: String, extra_imports: List(String)) {
  let assert Ok(file_content) = simplifile.read(file)

  let #(imports, code) =
    get_doc_tests_imports_and_code(file_content, extra_imports)

  case string.is_empty(code) {
    True -> Ok(Nil)
    _ -> {
      let test_file_name = get_test_file_name(file)

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
