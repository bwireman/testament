import simplifile
import testament/internal/markdown

pub fn markdown_test() {
  let assert Ok(code) = simplifile.read("test/markdown.md")

  assert markdown.parse_snippets(code)
    == [
      "let x = 1 + 1\nassert x == 2",
      "import gleam/int\nassert int.add(1, 1) == 2",
    ]
}
