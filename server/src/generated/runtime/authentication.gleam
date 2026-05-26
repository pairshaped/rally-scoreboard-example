//// Generated. Do not edit.
////
//// Server authentication helpers.
//// Derived from the Generator Framework's server authentication runtime contract.
//// Emits password/code hashing and authentication result types used by
//// generated SSR handlers.

import gleam/bit_array
import gleam/crypto
import gleam/int
import gleam/result
import gleam/string

const password_hash_prefix = "runtime-pbkdf2-sha256"

const password_hash_version = "v=1"

const pbkdf2_iterations = 600_000

const password_salt_bytes = 16

const password_hash_bytes = 32

const sign_in_code_hash_prefix = "runtime-sign-in-code-hmac-sha256"

const sign_in_code_alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

const sign_in_code_length = 5

@external(erlang, "server_generated_runtime_authentication_ffi", "pbkdf2_hmac_sha256")
fn pbkdf2_hmac_sha256(
  secret: BitArray,
  salt: BitArray,
  iterations: Int,
  length: Int,
) -> BitArray

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

/// Hash an authentication secret for storage.
///
/// This is intended for secrets that will be checked later, such as passwords
/// or other submitted credentials. It uses PBKDF2-SHA256 with a fresh salt and
/// stores the algorithm, version, iteration count, salt, and hash together.
///
/// Panics only if the Erlang crypto app is unavailable. Application code that
/// wants to handle that case explicitly should use `try_hash` instead.
pub fn hash(secret secret: String) -> String {
  let salt = crypto.strong_random_bytes(password_salt_bytes)
  let hashed =
    pbkdf2_hmac_sha256(
      <<secret:utf8>>,
      salt,
      pbkdf2_iterations,
      password_hash_bytes,
    )

  encode_password_hash(salt:, hash: hashed)
}

/// Hash an authentication secret for storage, returning an error rather than panicking.
/// Use this when the caller needs to log or react to a hashing failure.
pub fn try_hash(secret secret: String) -> Result(String, HashError) {
  let salt = crypto.strong_random_bytes(password_salt_bytes)
  let hashed =
    pbkdf2_hmac_sha256(
      <<secret:utf8>>,
      salt,
      pbkdf2_iterations,
      password_hash_bytes,
    )

  Ok(encode_password_hash(salt:, hash: hashed))
}

/// Check a submitted authentication secret against a stored hash.
pub fn verify(stored stored: String, secret secret: String) -> Bool {
  case parse_password_hash(stored) {
    Ok(#(iterations, salt, expected)) -> {
      let actual =
        pbkdf2_hmac_sha256(
          <<secret:utf8>>,
          salt,
          iterations,
          bit_array.byte_size(expected),
        )

      crypto.secure_compare(actual, expected)
    }
    Error(Nil) -> False
  }
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

/// Hash a scoped sign-in code, returning an error shape compatible with
/// `try_hash`. HMAC hashing does not normally fail.
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

fn encode_password_hash(salt salt: BitArray, hash hash: BitArray) -> String {
  string.concat([
    "$",
    password_hash_prefix,
    "$",
    password_hash_version,
    "$i=",
    int.to_string(pbkdf2_iterations),
    "$",
    bit_array.base64_url_encode(salt, False),
    "$",
    bit_array.base64_url_encode(hash, False),
  ])
}

fn parse_password_hash(
  stored: String,
) -> Result(#(Int, BitArray, BitArray), Nil) {
  case string.split(stored, on: "$") {
    ["", prefix, version, iterations, salt, hash]
      if prefix == password_hash_prefix && version == password_hash_version
    -> {
      use iterations <- result.try(parse_iterations(iterations))
      use salt <- result.try(bit_array.base64_url_decode(salt))
      use hash <- result.try(bit_array.base64_url_decode(hash))
      Ok(#(iterations, salt, hash))
    }
    _ -> Error(Nil)
  }
}

fn parse_iterations(value: String) -> Result(Int, Nil) {
  case string.split_once(value, on: "=") {
    Ok(#("i", raw)) -> int.parse(raw)
    _ -> Error(Nil)
  }
}

fn encode_sign_in_code_hash(hash hash: BitArray) -> String {
  string.concat([
    "$",
    sign_in_code_hash_prefix,
    "$",
    password_hash_version,
    "$",
    bit_array.base64_url_encode(hash, False),
  ])
}

fn parse_sign_in_code_hash(stored stored: String) -> Result(BitArray, Nil) {
  case string.split(stored, on: "$") {
    ["", prefix, version, hash]
      if prefix == sign_in_code_hash_prefix && version == password_hash_version
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
