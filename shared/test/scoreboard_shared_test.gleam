//// Shared package smoke tests.
////
//// These tests keep the shared API package compiling on its own, separate
//// from the client and server packages that import it.

import gleeunit
import gleeunit/should
import shared/api/to_server

pub fn main() {
  gleeunit.main()
}

pub fn public_to_server_contract_compiles_test() {
  to_server.LoadGames
  |> should.equal(to_server.LoadGames)
}
