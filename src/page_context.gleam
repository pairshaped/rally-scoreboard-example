//// Shared page context for generated Proute glue.
////
//// The unified source tree keeps this deliberately small until the Rust
//// projector decides which server services are allowed to survive in the
//// server target.

/// Proute/Rally page context token.
/// generated page init and update functions thread this through every page even
/// while the app keeps the context intentionally empty.
pub type PageContext {
  PageContext
}
