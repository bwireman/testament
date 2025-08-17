import gleam/list
import gleam/pair
import gleam/regexp
import gleam/string
import glexer
import glexer/token

const prefix = ":"

pub type Import =
  String

pub type CodeBlock =
  String

pub type ImportsAndCode =
  #(List(Import), List(CodeBlock))

pub fn parse_markdown_snippets(content: String) -> ImportsAndCode {
  let assert Ok(rg) =
    regexp.compile(
      "^````?gleam(?:\\s*(\\w+))?([\\s\\S]*?)^````?$",
      regexp.Options(False, True),
    )
    as { "failed to compile markdown regex" }

  rg
  |> regexp.scan(content)
  |> list.map(fn(match) {
    match.content
    |> string.replace("````gleam", "")
    |> string.replace("```gleam", "")
    |> string.replace("````", "")
    |> string.replace("```", "")
    |> string.trim()
    |> glexer.new()
    |> glexer.discard_comments()
    |> glexer.lex()
    |> glexer.to_source()
    |> string.split("\n")
    |> list.fold(#([], []), split_imports_and_code)
    |> pair.map_second(string.join(_, "\n"))
  })
  |> list.fold(#([], []), fn(acc, block) {
    acc
    |> pair.map_first(list.append(_, pair.first(block)))
    |> pair.map_second(list.append(_, [pair.second(block)]))
  })
  |> pair.map_first(list.unique)
}

pub fn get_doc_tests_imports_and_code(code: String) -> ImportsAndCode {
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
  |> pair.map_first(list.unique)
}

pub fn collect_test_lines(tokens: List(token.Token)) -> List(List(token.Token)) {
  let state = list.fold(tokens, DocState(False, [], []), fold_doc_state)

  case state.lines {
    [] -> state.test_bodies
    _ -> list.prepend(state.test_bodies, list.reverse(state.lines))
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

pub type DocState {
  DocState(
    in: Bool,
    lines: List(token.Token),
    test_bodies: List(List(token.Token)),
  )
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
