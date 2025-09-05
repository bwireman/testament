import gleam/list
import gleam/result
import gleam/string
import simplifile
import testament
import testament/conf

pub fn main() -> Nil {
  testament.test_main_with_opts(fn() { Nil }, [
    conf.PreserveFiles,
    conf.Verbose,
    conf.ExtraImports("src/example.gleam", [
      conf.Import("example", ["SuperInt"]),
    ]),
    conf.Markdown([
      "src/markdown_basic.md",
      "src/markdown_imports.md",
      "src/markdown_no_tests.md",
    ]),
  ])

  let assert Ok(files) =
    simplifile.get_files("test/testament")
    |> result.map(list.sort(_, string.compare))

  assert files
    == [
      "test/testament/example_doc_test.gleam",
      "test/testament/hello/dude_doc_test.gleam",
      "test/testament/hello/world_doc_test.gleam",
      "test/testament/hello/yo_doc_test.gleam",
      "test/testament/markdown_basic_md_doc_test.gleam",
      "test/testament/markdown_imports_md_doc_test.gleam",
    ]

  let assert Ok(Nil) = simplifile.delete("test/testament")
  Nil
}
