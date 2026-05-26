//// Generated. Do not edit.
////
//// Shared route union for one Mount. The server, client router,
//// request context, and SSR handler all import this type so route matching
//// stays in one shape.
////
//// Derived from the Mount pages discovered by Rally.

pub type Route {
  Games
  GamesId(id: String)
  Standings
  NotFound
}
