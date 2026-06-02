@target(erlang)
@external(erlang, "app_topics_ffi", "start")
pub fn start() -> Nil {
  Nil
}

@target(erlang)
@external(erlang, "app_topics_ffi", "join")
pub fn join(_topic: String) -> Nil {
  Nil
}

@target(erlang)
@external(erlang, "app_topics_ffi", "broadcast")
pub fn broadcast(_topic: String, _frame: BitArray) -> Nil {
  Nil
}
