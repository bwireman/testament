///```gleam
///: assert yo.yo() == "yo!"
///```
@external(erlang, "ffi", "yo")
@external(javascript, "../ffi.mjs", "yo")
pub fn yo() -> String
