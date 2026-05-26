//// Generated. Do not edit.
////
//// Server environment helpers.
//// Derived from Rally's server environment runtime contract.
//// Reads APP_ENV so generated handlers can branch on dev/prod behavior.

import envoy
import gleam/result
import gleam/string

type AppEnv {
  Dev
  Prod
}

fn app_env() -> AppEnv {
  envoy.get("APP_ENV")
  |> result.unwrap("dev")
  |> app_env_from_string
}

fn app_env_from_string(value: String) -> AppEnv {
  case string.lowercase(value) {
    "prod" | "production" -> Prod
    _ -> Dev
  }
}

pub fn app_env_name() -> String {
  case app_env() {
    Dev -> "dev"
    Prod -> "prod"
  }
}

pub fn is_dev() -> Bool {
  app_env() == Dev
}

pub fn secure_cookies() -> Bool {
  secure_cookies_for(app_env())
}

fn secure_cookies_for(app_env: AppEnv) -> Bool {
  app_env == Prod
}
