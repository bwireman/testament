import birdie
import glam/doc
import gleam/list
import gleeunit
import glexer/token
import testament/internal/util

pub fn main() -> Nil {
  gleeunit.main()
}

fn snapshot_doc_test(title: String, src: String) {
  let #(imports, code) = util.get_doc_tests_imports_and_code(src)

  ["src:\n" <> src, "imports:\n" <> imports, "code:\n" <> code]
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

pub fn is_doc_test() {
  assert util.is_doc(token.CommentDoc(""))
  assert util.is_doc(token.CommentDoc(":"))
  assert util.is_doc(token.CommentModule(""))
  assert util.is_doc(token.CommentModule(":"))
  assert !util.is_doc(token.CommentNormal(""))
  assert !util.is_doc(token.CommentNormal(":"))
}

pub fn is_doctest_line_test() {
  assert util.is_doctest_line(token.CommentDoc(":"))
  assert util.is_doctest_line(token.CommentModule(":"))
  assert !util.is_doctest_line(token.CommentDoc(""))
  assert !util.is_doctest_line(token.CommentModule(""))
  assert !util.is_doctest_line(token.CommentNormal(""))
  assert !util.is_doctest_line(token.CommentNormal(":"))
}

pub fn split_imports_and_code_test() {
  assert util.split_imports_and_code(#([], []), "import foo")
    == #(["import foo"], [])
  assert util.split_imports_and_code(#([], []), "let x = 1")
    == #([], ["let x = 1"])
}

pub fn get_doc_tests_imports_and_code_test() {
  assert util.get_doc_tests_imports_and_code("") == #("", "")
  assert util.get_doc_tests_imports_and_code("   ") == #("", "")
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
    "doc comments only",
    "///```
//: import gleam/io
//: assert add(1, 1) == 2
///```
pub fn add(x: Int, y: Int) {
  x + y
}",
  )

  snapshot_doc_test(
    "reduces imports",
    "///```
///: import gleam/io
///: import gleam/string
///: import gleam/list
///: import gleam/list
///: import gleam/io
///```
",
  )

  snapshot_doc_test(
    "module docs",
    "////```
////: import gleam/io
////: assert 1 + 1 == 2
////```
",
  )
}
