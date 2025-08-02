import filepath
import gleam/list
import gleam/pair
import gleam/string
import glexer
import glexer/token

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

pub fn get_doc_tests_imports_and_code(code: String) -> #(String, String) {
  let cases =
    code
    |> glexer.new()
    |> glexer.lex()
    |> list.map(pair.first)
    |> list.filter(is_commentdoc)
    |> list.fold(DocState(False, []), fold_doc_state)

  let lines = case cases.in {
    True -> list.append(cases.lines, [close])
    _ -> cases.lines
  }

  lines
  |> list.filter(is_doctest_line)
  |> list.map(token.to_source)
  |> list.map(string.drop_start(_, string.length(prefix) + 3))
  |> list.map(string.trim)
  |> list.fold(#([], []), split_imports_and_code)
  |> pair.map_first(list.unique)
  |> pair.map_first(string.join(_, "\n"))
  |> pair.map_second(string.join(_, "\n"))
}

type DocState {
  DocState(in: Bool, lines: List(token.Token))
}

fn fold_doc_state(state: DocState, line: token.Token) {
  case state, line {
    DocState(False, lines), token.CommentDoc(":" <> _) ->
      DocState(True, list.append(lines, [open, line]))

    DocState(True, lines), token.CommentDoc(":" <> _) ->
      DocState(..state, lines: list.append(lines, [line]))

    DocState(True, lines), _ ->
      DocState(False, list.append(lines, [line, close]))

    _, _ -> DocState(..state, lines: list.append(state.lines, [line]))
  }
}

pub fn is_commentdoc(t: token.Token) -> Bool {
  case t {
    token.CommentDoc(_) -> True
    _ -> False
  }
}

pub fn is_doctest_line(t: token.Token) -> Bool {
  case t {
    token.CommentDoc(":" <> _) -> True
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
