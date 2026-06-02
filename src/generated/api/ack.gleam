import gleam/option.{type Option}

pub type ApiLoadError {
  ApiLoadError(message: String)
}

pub type ApiSaveError {
  ApiSaveError(field: Option(String), message: String)
}
