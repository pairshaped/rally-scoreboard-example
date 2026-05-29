//// Generated. Do not edit.
////
//// Server authentication helpers.
//// Derived from the Generator Framework's server authentication runtime contract.
//// Emits sign-in code hashing and authentication result types used by
//// generated SSR handlers.

import gleam/bit_array
import gleam/crypto
import gleam/string

const hash_version = "v=1"

const sign_in_code_hash_prefix = "runtime-sign-in-code-hmac-sha256"

const sign_in_code_alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

const sign_in_code_length = 5

/// Per-page authentication policy, declared as `pub const page_authentication` in page modules.
/// Required: the user must be authenticated to view the page.
/// Optional: identity is resolved if available, but the page loads either way.
pub type AuthenticationPolicy {
  Required
  Optional
}

/// Return type for authentication-enabled `load` functions.
/// Page: render the page with data and optionally set/clear cookies.
/// Redirect: send the user elsewhere (e.g., after sign-in or permission failure).
pub type LoadResult(data) {
  Page(data: data, cookies: List(Cookie))
  Redirect(url: String, cookies: List(Cookie))
}

/// A cookie to set or clear in the SSR response.
pub type Cookie {
  SetCookie(name: String, value: String, max_age: Int)
  ClearCookie(name: String)
}

/// Hashing can fail only if the Erlang crypto app is unavailable or broken.
pub type HashError {
  CryptoUnavailable
}

/// Generate a short, human-friendly sign-in code.
///
/// These codes are meant for short-lived sign-in flows, not long-lived session
/// tokens or API tokens.
pub fn generate_sign_in_code() -> String {
  let alphabet_size = string.length(sign_in_code_alphabet)
  // Drop byte values that would make modulo selection favor earlier chars.
  let rejection_threshold = 256 / alphabet_size * alphabet_size
  crypto.strong_random_bytes(16)
  |> pick_sign_in_code_chars(
    alphabet_size:,
    rejection_threshold:,
    needed: sign_in_code_length,
    accumulator: "",
  )
}

/// Hash a scoped sign-in code for storage with an app secret.
///
/// The scope is usually an email address or other lookup value. The Generator Framework
/// normalizes the scope and code before hashing. The secret key should be a
/// stable app secret that is not stored in the database.
///
/// Sign-in codes are short, so this uses HMAC-SHA256 instead of a bare fast hash.
/// A leaked database cannot brute-force stored codes without the app secret.
pub fn hash_sign_in_code(
  scope scope: String,
  code code: String,
  secret_key secret_key: String,
) -> String {
  let digest = sign_in_code_digest(scope:, code:, secret_key:)
  encode_sign_in_code_hash(hash: digest)
}

/// Hash a scoped sign-in code, returning an error shape for callers that keep
/// all authentication hashing on an explicit error path. HMAC hashing does not
/// normally fail.
pub fn try_hash_sign_in_code(
  scope scope: String,
  code code: String,
  secret_key secret_key: String,
) -> Result(String, HashError) {
  Ok(hash_sign_in_code(scope:, code:, secret_key:))
}

/// Check a submitted sign-in code against a stored hash.
pub fn verify_sign_in_code(
  stored stored: String,
  scope scope: String,
  code code: String,
  secret_key secret_key: String,
) -> Bool {
  case parse_sign_in_code_hash(stored:) {
    Ok(expected) -> {
      let actual = sign_in_code_digest(scope:, code:, secret_key:)
      crypto.secure_compare(actual, expected)
    }
    Error(Nil) -> False
  }
}

fn sign_in_code_input(scope scope: String, code code: String) -> String {
  normalize(value: scope) <> ":" <> normalize(value: code)
}

fn sign_in_code_digest(
  scope scope: String,
  code code: String,
  secret_key secret_key: String,
) -> BitArray {
  crypto.hmac(<<sign_in_code_input(scope:, code:):utf8>>, crypto.Sha256, <<
    secret_key:utf8,
  >>)
}

fn encode_sign_in_code_hash(hash hash: BitArray) -> String {
  string.concat([
    "$",
    sign_in_code_hash_prefix,
    "$",
    hash_version,
    "$",
    bit_array.base64_url_encode(hash, False),
  ])
}

fn parse_sign_in_code_hash(stored stored: String) -> Result(BitArray, Nil) {
  case string.split(stored, on: "$") {
    ["", prefix, version, hash]
      if prefix == sign_in_code_hash_prefix && version == hash_version
    -> {
      bit_array.base64_url_decode(hash)
    }
    _ -> Error(Nil)
  }
}

fn normalize(value value: String) -> String {
  value
  |> string.trim
  |> string.uppercase
}

fn pick_sign_in_code_chars(
  bytes bytes: BitArray,
  alphabet_size alphabet_size: Int,
  rejection_threshold rejection_threshold: Int,
  needed needed: Int,
  accumulator accumulator: String,
) -> String {
  case needed, bytes {
    0, _ -> accumulator

    _, <<byte_value, rest:bits>> ->
      case byte_value >= rejection_threshold {
        True ->
          pick_sign_in_code_chars(
            bytes: rest,
            alphabet_size:,
            rejection_threshold:,
            needed:,
            accumulator:,
          )
        False -> {
          let index = byte_value % alphabet_size
          let char = string.slice(sign_in_code_alphabet, index, 1)
          pick_sign_in_code_chars(
            bytes: rest,
            alphabet_size:,
            rejection_threshold:,
            needed: needed - 1,
            accumulator: accumulator <> char,
          )
        }
      }

    _, _ ->
      crypto.strong_random_bytes(16)
      |> pick_sign_in_code_chars(
        alphabet_size:,
        rejection_threshold:,
        needed:,
        accumulator:,
      )
  }
}
