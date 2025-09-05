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
  assert util.import_from_file_name("src/x.gleam") == "x"
  assert util.import_from_file_name("src/foo/bar/example.gleam")
    == "foo/bar/example"
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
      conf.ExtraImports("foo.gleam", [conf.Import("foo", ["foo-import"])]),
      conf.ExtraImports("bar.gleam", [conf.Import("foo", ["foo-import"])]),
      conf.ExtraImports("baz.gleam", [
        conf.Import("foo", ["foo-import"]),
        conf.Import("bar", ["bar-import"]),
        conf.Import("baz", ["baz-import"]),
      ]),
    ])
    == util.Config(
      ignore_files: [],
      verbose: False,
      preserve_files: False,
      extra_imports: dict.from_list([
        #("bar.gleam", [conf.Import("foo", ["foo-import"])]),
        #("baz.gleam", [
          conf.Import("foo", ["foo-import"]),
          conf.Import("bar", ["bar-import"]),
          conf.Import("baz", ["baz-import"]),
        ]),
        #("foo.gleam", [conf.Import("foo", ["foo-import"])]),
      ]),
      markdown_files: [],
    )
}
