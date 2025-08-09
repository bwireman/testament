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
}
