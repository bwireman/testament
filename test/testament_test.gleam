import birdie
import glam/doc
import gleam/dict
import gleam/list
import gleam/string
import gleeunit
import glexer/token
import simplifile
import testament/conf
import testament/internal/markdown
import testament/internal/util

pub fn main() -> Nil {
  gleeunit.main()
}

fn snapshot_doc_test(title: String, src: String) {
  let #(imports, code) = util.get_doc_tests_imports_and_code(src)

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
  assert util.is_doc(token.CommentDoc(""))
  assert util.is_doc(token.CommentDoc(":"))
  assert util.is_doc(token.CommentModule(""))
  assert util.is_doc(token.CommentModule(":"))
  assert !util.is_doc(token.CommentNormal(""))
  assert !util.is_doc(token.CommentNormal(":"))
  assert !util.is_doc(token.UpperName(""))
  assert !util.is_doc(token.UpperName(":"))
}

pub fn is_doctest_line_test() {
  assert util.is_doctest_line(token.CommentDoc(":"))
  assert !util.is_doctest_line(token.CommentDoc(""))
  assert util.is_doctest_line(token.CommentModule(":"))
  assert !util.is_doctest_line(token.CommentModule(""))
  assert !util.is_doctest_line(token.CommentNormal(":"))
  assert !util.is_doctest_line(token.CommentNormal(""))
  assert !util.is_doctest_line(token.UpperName(":"))
  assert !util.is_doctest_line(token.UpperName(""))
}

pub fn fold_doc_state_test() {
  assert util.DocState(False, [], [])
    |> util.fold_doc_state(token.String(": "))
    == util.DocState(False, [], [])

  assert util.DocState(False, [], [])
    |> util.fold_doc_state(token.CommentDoc(": "))
    == util.DocState(True, [token.CommentDoc(": ")], [])

  assert util.DocState(False, [], [])
    |> util.fold_doc_state(token.CommentModule(": "))
    == util.DocState(True, [token.CommentModule(": ")], [])

  assert util.DocState(True, [], [])
    |> util.fold_doc_state(token.CommentDoc(": "))
    == util.DocState(True, [token.CommentDoc(": ")], [])

  assert util.DocState(True, [], [])
    |> util.fold_doc_state(token.CommentModule(": "))
    == util.DocState(True, [token.CommentModule(": ")], [])

  assert util.DocState(True, [token.CommentModule(": let x = 2 + 2")], [])
    |> util.fold_doc_state(token.CommentModule(": assert x == 4"))
    |> util.fold_doc_state(token.CommentModule("pub fn x"))
    == util.DocState(False, [], [
      [
        token.CommentModule(": let x = 2 + 2"),
        token.CommentModule(": assert x == 4"),
      ],
    ])

  assert util.DocState(True, [], [])
    |> util.fold_doc_state(token.CommentDoc(" "))
    == util.DocState(False, [], [[]])

  assert util.DocState(True, [], [])
    |> util.fold_doc_state(token.CommentModule(" "))
    == util.DocState(False, [], [[]])
}

pub fn split_imports_and_code_test() {
  let x = #([], [])

  assert util.split_imports_and_code(x, "import foo") == #(["import foo"], [])
  assert util.split_imports_and_code(x, "let x = 1") == #([], ["let x = 1"])
}

pub fn get_doc_tests_imports_and_code_test() {
  assert util.get_doc_tests_imports_and_code("") == #([], [])
  assert util.get_doc_tests_imports_and_code("   ") == #([], [])
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

pub fn markdown_test() {
  let assert Ok(code) = simplifile.read("test/markdown.md")

  assert markdown.parse_snippets(code)
    == #(["import gleam/int"], [
      "\nlet x = 1 + 1\nassert x == 2",
      "\nassert int.add(1, 1) == 2",
    ])
}
