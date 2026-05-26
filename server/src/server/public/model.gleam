//// Public backend model.
////
//// Holds server-side state owned by the public Mount. The example keeps it
//// intentionally small so dispatch and transport shape stay easy to inspect.

pub type Model {
  Model(notice: String)
}
