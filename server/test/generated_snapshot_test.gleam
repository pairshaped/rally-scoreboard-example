//// Birdie snapshots for Scoreboard's checked-in generated files.
////
//// These snapshots make the hand-written generated target visible while the
//// Rally generators are rebuilt to match it.

import birdie
import gleam/list
import gleam/string
import simplifile

pub fn generated_source_files_match_snapshots_test() {
  generated_source_files()
  |> list.each(fn(path) { birdie.snap(read(path), snapshot_name(path)) })
}

fn generated_source_files() -> List(String) {
  ["../client/src", "../shared/src", "src"]
  |> list.flat_map(walk)
  |> list.filter(is_generated_source_file)
  |> list.sort(by: string.compare)
}

fn walk(path: String) -> List(String) {
  let assert Ok(entries) = simplifile.read_directory(at: path)

  entries
  |> list.flat_map(fn(entry) {
    let child = path <> "/" <> entry

    case simplifile.is_directory(child) {
      Ok(True) -> walk(child)
      _ -> [child]
    }
  })
}

fn is_generated_source_file(path: String) -> Bool {
  is_source_file(path)
  && {
    string.contains(path, "/generated/") || string.contains(path, "_generated_")
  }
}

fn is_source_file(path: String) -> Bool {
  string.ends_with(path, ".gleam")
  || string.ends_with(path, ".mjs")
  || string.ends_with(path, ".erl")
}

fn snapshot_name(path: String) -> String {
  path
  |> string.replace(each: "../", with: "")
  |> string.replace(each: "/", with: "__")
  |> string.replace(each: ".", with: "_")
  |> string.replace(each: "@", with: "_")
}

fn read(path: String) -> String {
  let assert Ok(source) = simplifile.read(path)
  source
}
