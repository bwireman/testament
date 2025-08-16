//// Testament config
////
//// # Example
//// ```gleam
//// import gleeunit
//// import testament
//// import testament/conf
////
//// pub fn main() -> Nil {
////  testament.test_main_with_opts(gleeunit.main, [
////   // ignore any doc tests in `src/ignored.gleam`
////   conf.IgnoreFiles(["src/ignored.gleam"]),
////   // add import `gleam/string` into tests for `src/string_util.gleam`
////   conf.ExtraImports("src/string_util.gleam", ["gleam/string"]),
////   // generate doc tests for gleam snippets in `docs/docs.md`
////   conf.Markdown(["docs/docs.md"]),
////  ])
//// }
//// ```

/// Options to change how testament works
pub type Conf {
  /// filepaths (relative to the `src` directory) whose docs should be ignored
  IgnoreFiles(filepaths: List(String))
  /// verbose logging for testament
  Verbose
  /// don't delete generated test files after the run
  PreserveFiles
  /// other modules to be imported for use in the generated test files
  ExtraImports(filepath: String, modules: List(String))
  /// create doc tests from markdown file
  Markdown(filepath: List(String))
}
