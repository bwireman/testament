# Writing Tests

Testament can create tests stored in

- Doc Comments `///`
- Module Comments `////`
- Markdown Snippets `` ```gleam ``

Both Doc and module comment lines need to additionally start with a `:`. With
each file generating one shared test file each.

## Examples

````gleam
//// Example Module docs
////: assert example.add(1, 0) == example.sub(2, 1)

///other comment
/// ```
///: let x = example.add(1, 2)
///: assert x == 3
///:
///: let y =
///: example.add(1, 1)
///: |> example.add(2)
///: |> example.add(3)
///:
///: assert y == {x * 2} + 1
/// ```
pub fn add(a: Int, b: Int) -> Int {
  a + b
}

/// first test
///: let x = example.sub(1, 2)
///: assert x == -1
///: assert example.sub(2, 1) == 1
/// start a second test
///: assert example.sub(2, -1) == 3
pub fn sub(a: Int, b: Int) -> Int {
  a - b
}
````

### Imports

- Each test file automatically imports the module it came from
- Other imports can be used as normal
- Additionally imports can be configured in
  [config](https://hexdocs.pm/testament/testament/conf.html)

```gleam
///: import gleam/int
///: assert example.add(2, 1) == int.add(1, 2)
pub fn add(a: Int, b: Int) -> Int {
  a - b
}
```
