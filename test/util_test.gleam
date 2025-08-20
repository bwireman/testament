import gleam/dict
import testament/conf
import testament/internal/util

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
