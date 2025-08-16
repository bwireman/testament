import gleam/list
import gleam/pair
import gleam/regexp
import gleam/string
import glexer

pub fn parse_snippets(content: String) -> #(List(String), List(String)) {
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
    |> glexer.new()
    |> glexer.discard_comments()
    |> glexer.lex()
    |> glexer.to_source()
    |> string.split("\n")
    |> list.fold(#([], ""), fn(acc, line) {
      case string.starts_with(line, "import") {
        True -> pair.map_first(acc, list.append(_, [line]))
        _ -> pair.map_second(acc, fn(l) { string.concat([l, "\n", line]) })
      }
    })
  })
  |> list.fold(#([], []), fn(acc, block) {
    acc
    |> pair.map_first(list.append(_, pair.first(block)))
    |> pair.map_second(list.append(_, [pair.second(block)]))
  })
}
