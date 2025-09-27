import gleam/list
import gleam/pair
import gleam/regexp
import gleam/string
import glexer
import glexer/token
import testament/internal/constants
import testament/internal/stream

pub type Import =
  String

pub type CodeBlock =
  String

pub type ImportsAndCode =
  #(List(Import), List(CodeBlock))

pub fn parse_markdown_snippets(content: String) -> ImportsAndCode {
  let assert Ok(rg) =
    regexp.compile(
      "^```gleam(?:\\s*(\\w+))?([\\s\\S]*?)^```$",
      regexp.Options(False, True),
    )
    as { "failed to compile markdown regex" }

  rg
  |> regexp.scan(content)
  |> stream.new()
  |> stream.map(fn(match) {
    match.content
    |> string.replace("```gleam", "")
    |> string.replace("```", "")
    |> string.trim()
    |> glexer.new()
    |> glexer.discard_comments()
    |> glexer.lex()
    |> glexer.to_source()
    |> string.split(constants.newline)
    |> list.fold(#([], []), split_imports_and_code)
    |> pair.map_second(string.join(_, constants.newline))
  })
  |> stream.to_list()
  |> prep_imports()
}

pub fn get_doc_tests_imports_and_code(code: String) -> ImportsAndCode {
  let prefix_len = string.length(constants.prefix)

  code
  |> glexer.new()
  |> glexer.discard_whitespace()
  |> glexer.lex()
  |> stream.new()
  |> stream.map(pair.first)
  |> stream.filter(is_doc)
  |> stream.to_list()
  |> collect_test_lines()
  |> stream.new()
  |> stream.map(fn(tokens) {
    tokens
    |> stream.new()
    |> stream.filter(is_doctest_line)
    |> stream.map(token.to_source)
    |> stream.map(string.crop(_, constants.prefix))
    |> stream.map(string.drop_start(_, prefix_len))
    |> stream.map(string.trim)
    |> stream.to_list()
    |> list.fold(#([], []), split_imports_and_code)
    |> pair.map_second(string.join(_, constants.newline))
  })
  |> stream.to_list()
  |> prep_imports()
}

fn collect_test_lines(tokens: List(token.Token)) -> List(List(token.Token)) {
  let state = list.fold(tokens, DocState(False, [], [], 0), fold_doc_state)

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
    implicit_asserts: Int,
  )
}

pub fn split_imports_and_code(
  code: ImportsAndCode,
  line: String,
) -> ImportsAndCode {
  case string.starts_with(line, constants.importline) {
    True -> pair.map_first(code, list.prepend(_, line))
    False -> pair.map_second(code, list.append(_, [line]))
  }
}

const letters = [
  "a",
  "b",
  "c",
  "d",
  "e",
  "f",
  "g",
  "h",
  "i",
  "j",
  "l",
  "m",
  "n",
  "o",
  "p",
  "q",
  "r",
  "s",
  "t",
  "u",
  "v",
  "w",
  "x",
  "y",
  "z",
]

fn prep_implicit_assert(
  state: DocState,
  lines: List(token.Token),
  expected_val: CodeBlock,
) {
  let assert [v] = list.sample(letters, 1) as "failed to create implicit_assert"
  let name = string.repeat(v, state.implicit_asserts + 1)

  let assert #([token.CommentDoc(":" <> prev)], rest) = list.split(lines, 1)
    as "improper use of ::"

  let prev = token.CommentDoc(": let " <> name <> " =" <> prev)

  let line = token.CommentDoc(": assert " <> name <> " == " <> expected_val)

  DocState(
    ..state,
    in: True,
    lines: [line, prev, ..rest],
    implicit_asserts: state.implicit_asserts + 1,
  )
}

pub fn fold_doc_state(state: DocState, line: token.Token) -> DocState {
  case state, line {
    DocState(False, lines, _, _), token.CommentDoc("::" <> expected_val)
    | DocState(False, lines, _, _), token.CommentModule("::" <> expected_val)
    -> prep_implicit_assert(state, lines, expected_val)

    DocState(False, lines, _, _), token.CommentDoc(":" <> _)
    | DocState(False, lines, _, _), token.CommentModule(":" <> _)
    -> DocState(..state, in: True, lines: [line, ..lines])

    DocState(True, lines, _, _), token.CommentDoc("::" <> expected_val)
    | DocState(True, lines, _, _), token.CommentModule("::" <> expected_val)
    -> prep_implicit_assert(state, lines, expected_val)

    DocState(True, lines, _, _), token.CommentDoc(":" <> _)
    | DocState(True, lines, _, _), token.CommentModule(":" <> _)
    -> DocState(..state, lines: [line, ..lines])

    DocState(True, lines, bodies, implicit_asserts), _ ->
      DocState(
        in: False,
        lines: [],
        test_bodies: list.prepend(bodies, list.reverse(lines)),
        implicit_asserts: implicit_asserts,
      )

    _, _ -> state
  }
}

fn prep_imports(blocks: List(#(List(Import), CodeBlock))) -> ImportsAndCode {
  blocks
  |> list.fold(#([], []), fn(acc, block) {
    acc
    |> pair.map_first(list.append(_, pair.first(block)))
    |> pair.map_second(list.prepend(_, pair.second(block)))
  })
  |> pair.map_first(list.unique)
}
