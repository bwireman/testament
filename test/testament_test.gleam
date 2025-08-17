import birdie
import glam/doc
import gleam/dict
import gleam/list
import gleam/string
import gleeunit
import glexer/token
import simplifile
import testament/conf
import testament/internal/parse
import testament/internal/util

pub fn main() -> Nil {
  gleeunit.main()
}

fn prep_snapshot(
  title: String,
  src: String,
  imports: List(String),
  code: List(String),
) {
  [
    "src:\n" <> src,
    "imports:\n" <> string.join(imports, "\n"),
    "code:\n" <> string.join(code, "\n####################\n\n"),
  ]
  |> list.map(doc.from_string)
  |> doc.concat_join([doc.from_string("\n\n====================\n\n")])
  |> doc.to_string(99)
  |> birdie.snap(title)
}

fn snapshot_doc_test(title: String, src: String) {
  let #(imports, code) = parse.get_doc_tests_imports_and_code(src)

  prep_snapshot(title, src, imports, code)
}

fn snapshot_markdown_doc_test(title: String, src: String) {
  let #(imports, code) = parse.parse_markdown_snippets(src)

  prep_snapshot(title, src, imports, code)
}

pub fn get_test_file_name_test() {
  assert util.get_test_file_name("src/x.gleam")
    == "test/testament/x_doc_test.gleam"
  assert util.get_test_file_name("src/foo/bar/example.gleam")
    == "test/testament/foo/bar/example_doc_test.gleam"
}

pub fn import_from_file_name_test() {
  assert util.import_from_file_name("src/x.gleam") == "import x"
  assert util.import_from_file_name("src/foo/bar/example.gleam")
    == "import foo/bar/example"
}

pub fn is_doc_test() {
  assert parse.is_doc(token.CommentDoc(""))
  assert parse.is_doc(token.CommentDoc(":"))
  assert parse.is_doc(token.CommentModule(""))
  assert parse.is_doc(token.CommentModule(":"))
  assert !parse.is_doc(token.CommentNormal(""))
  assert !parse.is_doc(token.CommentNormal(":"))
  assert !parse.is_doc(token.UpperName(""))
  assert !parse.is_doc(token.UpperName(":"))
}

pub fn is_doctest_line_test() {
  assert parse.is_doctest_line(token.CommentDoc(":"))
  assert !parse.is_doctest_line(token.CommentDoc(""))
  assert parse.is_doctest_line(token.CommentModule(":"))
  assert !parse.is_doctest_line(token.CommentModule(""))
  assert !parse.is_doctest_line(token.CommentNormal(":"))
  assert !parse.is_doctest_line(token.CommentNormal(""))
  assert !parse.is_doctest_line(token.UpperName(":"))
  assert !parse.is_doctest_line(token.UpperName(""))
}

pub fn fold_doc_state_test() {
  assert parse.DocState(False, [], [])
    |> parse.fold_doc_state(token.String(": "))
    == parse.DocState(False, [], [])

  assert parse.DocState(False, [], [])
    |> parse.fold_doc_state(token.CommentDoc(": "))
    == parse.DocState(True, [token.CommentDoc(": ")], [])

  assert parse.DocState(False, [], [])
    |> parse.fold_doc_state(token.CommentModule(": "))
    == parse.DocState(True, [token.CommentModule(": ")], [])

  assert parse.DocState(True, [], [])
    |> parse.fold_doc_state(token.CommentDoc(": "))
    == parse.DocState(True, [token.CommentDoc(": ")], [])

  assert parse.DocState(True, [], [])
    |> parse.fold_doc_state(token.CommentModule(": "))
    == parse.DocState(True, [token.CommentModule(": ")], [])

  assert parse.DocState(True, [token.CommentModule(": let x = 2 + 2")], [])
    |> parse.fold_doc_state(token.CommentModule(": assert x == 4"))
    |> parse.fold_doc_state(token.CommentModule("pub fn x"))
    == parse.DocState(False, [], [
      [
        token.CommentModule(": let x = 2 + 2"),
        token.CommentModule(": assert x == 4"),
      ],
    ])

  assert parse.DocState(True, [], [])
    |> parse.fold_doc_state(token.CommentDoc(" "))
    == parse.DocState(False, [], [[]])

  assert parse.DocState(True, [], [])
    |> parse.fold_doc_state(token.CommentModule(" "))
    == parse.DocState(False, [], [[]])
}

pub fn split_imports_and_code_test() {
  let x = #([], [])

  assert parse.split_imports_and_code(x, "import foo") == #(["import foo"], [])
  assert parse.split_imports_and_code(x, "let x = 1") == #([], ["let x = 1"])
}

pub fn get_doc_tests_imports_and_code_test() {
  assert parse.get_doc_tests_imports_and_code("") == #([], [])
  assert parse.get_doc_tests_imports_and_code("   ") == #([], [])
  snapshot_doc_test(
    "add",
    "///```
///: import gleam/io
///: assert add(1, 1) == 2
///: assert add(0, 0) == 0
///```
pub fn add(x: Int, y: Int) {
  x + y
}",
  )

  snapshot_doc_test(
    "requires prefix",
    "///```
///import gleam/io
///assert add(1, 1) == 2
///```
pub fn add(x: Int, y: Int) {
  x + y
}",
  )

  snapshot_doc_test(
    "multiple",
    "/// add numbers
///```
///: import gleam/io
///: assert add(1, 1) == 2
///: assert add(0, 0) == 0
///```
pub fn add(x: Int, y: Int) {
  x + y
}

/// subtracts numbers
///: import gleam/io
///: assert sub(1, 1) == 0
///: assert sub(1, 0) == 1
pub fn sub(x: Int, y: Int) {
  x - y
}",
  )

  snapshot_doc_test(
    "normal comments",
    "///```
//: import gleam/io
//: assert add(1, 1) == 2
///```
pub fn add(x: Int, y: Int) {
  x + y
}",
  )

  snapshot_doc_test(
    "module docs",
    "////```
////: import gleam/io
////: assert 1 + 1 == 2
////```
",
  )

  snapshot_doc_test(
    "weird formatting",
    "///```
///:  import  gleam/io
///:  import  gleam/io
///:assert  add(1 , 1)  ==  2
///```
pub fn add(x: Int, y: Int) {
  x + y
}",
  )
}

pub fn combine_conf_values_test() {
  assert util.combine_conf_values([])
    == util.Config(
      ignore_files: [],
      verbose: False,
      preserve_files: False,
      extra_imports: dict.new(),
      markdown_files: [],
    )

  assert util.combine_conf_values([conf.PreserveFiles])
    == util.Config(
      ignore_files: [],
      verbose: False,
      preserve_files: True,
      extra_imports: dict.new(),
      markdown_files: [],
    )

  assert util.combine_conf_values([conf.Verbose])
    == util.Config(
      ignore_files: [],
      verbose: True,
      preserve_files: False,
      extra_imports: dict.new(),
      markdown_files: [],
    )

  assert util.combine_conf_values([
      conf.IgnoreFiles(["foo", "bar"]),
      conf.IgnoreFiles(["baz"]),
    ])
    == util.Config(
      ignore_files: ["foo", "bar", "baz"],
      verbose: False,
      preserve_files: False,
      extra_imports: dict.new(),
      markdown_files: [],
    )

  assert util.combine_conf_values([
      conf.ExtraImports("foo", ["bar"]),
      conf.ExtraImports("bar", ["foo"]),
      conf.ExtraImports("baz", ["baz", "foo", "bar"]),
    ])
    == util.Config(
      ignore_files: [],
      verbose: False,
      preserve_files: False,
      extra_imports: dict.new()
        |> dict.insert("foo", ["import bar"])
        |> dict.insert("bar", ["import foo"])
        |> dict.insert("baz", ["import baz", "import foo", "import bar"]),
      markdown_files: [],
    )
}

pub fn markdown_parse_snippets_test() {
  let assert Ok(code) = simplifile.read("test/markdown.md")

  assert parse.parse_markdown_snippets(code)
    == #(["import gleam/int"], [
      "assert int.add(1, 1) == 2",
      "let x = 1 + 1\nassert x == 2",
    ])

  snapshot_markdown_doc_test(
    "basic no tests",
    "
# example

1. one
1. two
1. three

## foo
bar
### Bar
baz
",
  )

  snapshot_markdown_doc_test(
    "basic",
    "
# example
```gleam
let x = 2
assert x - 1 == 1
```
",
  )

  snapshot_markdown_doc_test(
    "basic 4 ticks",
    "
# example
````gleam
let x = 2
assert x - 1 == 1
````
",
  )

  snapshot_markdown_doc_test(
    "basic import",
    "
# example
```gleam
import gleam/int
import gleam/int
let x = 2
assert x - 1 == 1
```
",
  )
}
