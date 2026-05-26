//// Admin backend model.
////
//// Holds server-side state owned by the admin Mount. The example keeps it
//// intentionally small so dispatch and transport shape stay easy to inspect.

pub type Model {
  Model(audit_note: String)
}
