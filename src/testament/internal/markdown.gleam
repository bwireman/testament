import gleam/list
import gleam/regexp
import gleam/string

pub fn parse_snippets(content: String) -> List(String) {
  let assert Ok(rg) =
    regexp.compile(
      "^```gleam(?:\\s*(\\w+))?([\\s\\S]*?)^```$",
      regexp.Options(False, True),
    )
    as { "failed to compile markdown regex" }

  rg
  |> regexp.scan(content)
  |> list.map(fn(match) {
    match.content
    |> string.drop_start(8)
    |> string.drop_end(3)
    |> string.trim()
  })
}
