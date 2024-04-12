//// The library focus is to provide information for general
//// paths important in a Linux system nowadays for the developer
//// of applications.
//// 
//// These things are provided by what is so called the XDG Spec
//// wich tell us where an application should save its state, cache
//// and configuration for example.
////
//// The library does not create, check the existence of these places
//// or if they are writable or any other conditions. That is up
//// to the consumer of the library.
////
//// Two major parts are provided:
////   - Places where you should put **application** things.
////   - Some important user visible directories, like where is the
////     **downloads** folder.
//// 
//// Usage:
////   - first create an **application name** with `app`.
////     Example: `app("foobar")`
////   - check for potential errors - it returns a Result.
////   - for example, get information about where that application 
////     configuration folder should be.
////     Example:
////     ```
////     let foobar = app("foobar")
////     foobar |> result.map(fn(app) { io.println(app_config_dir(app)) }
////     ```
//// 
//// Notes:
////   - information is linux only. macos, windows, or any *bsds are in scope.
////   - should work both on erland and on node and deno runtimes.

import gleam/io
import gleam/string
import gleam/result
import envoy

pub fn main() {
  let a = app("")
  let b = app("x")

  io.debug(a)
  io.debug(b)

  b
  |> result.map(fn(app) {
    io.debug(app_cache_dir(app))
    io.debug(app_config_dir(app))
    io.debug(app_runtime_dir(app))
    io.debug(app_state_dir(app))
  })

  // --

  io.debug(desktop_dir())
  io.debug(documents_dir())
  io.debug(pictures_dir())
  io.debug(videos_dir())
  io.debug(music_dir())
  io.debug(downloads_dir())
}

pub opaque type AppName {
  AppName(v: String)
}

pub fn app(name: String) -> Result(AppName, String) {
  case string.is_empty(name) {
    True -> Error("The 'name' for the application is empty. Provide a name.")
    False -> Ok(AppName(name))
  }
}

pub fn app_cache_dir(app: AppName) {
  case envoy.get("XDG_CACHE_HOME") {
    Ok(v) ->
      check_absolute(v)
      |> result.map(fn(_) { v <> "/" <> app.v })

    Error(_) -> user_home(fn(h) { h <> "/" <> ".cache" <> "/" <> app.v })
  }
}

pub fn app_config_dir(app: AppName) {
  case envoy.get("XDG_CONFIG_HOME") {
    Ok(v) ->
      check_absolute(v)
      |> result.map(fn(_) { v <> "/" <> app.v })

    Error(_) -> user_home(fn(h) { h <> "/" <> ".config" <> "/" <> app.v })
  }
}

pub fn app_runtime_dir(app: AppName) {
  case envoy.get("XDG_RUNTIME_DIR") {
    Ok(v) ->
      check_absolute(v)
      |> result.map(fn(_) { v <> "/" <> app.v })

    Error(_) -> Error("Could not find expected XDG runtime dir.")
  }
}

pub fn app_data_dir(app: AppName) {
  case envoy.get("XDG_DATA_HOME") {
    Ok(v) ->
      check_absolute(v)
      |> result.map(fn(_) { v <> "/" <> app.v })

    Error(_) -> user_home(fn(h) { h <> "/" <> ".local/share" <> "/" <> app.v })
  }
}

pub fn app_state_dir(app: AppName) {
  case envoy.get("XDG_STATE_HOME") {
    Ok(v) ->
      check_absolute(v)
      |> result.map(fn(_) { v <> "/" <> app.v })

    Error(_) -> user_home(fn(h) { h <> "/" <> ".local/state" <> "/" <> app.v })
  }
}

pub fn desktop_dir() {
  case envoy.get("XDG_DESKTOP_DIR") {
    Ok(v) -> check_absolute(v)
    Error(_) -> user_home(fn(h) { h <> "/" <> "Desktop" })
  }
}

pub fn documents_dir() {
  case envoy.get("XDG_DOCUMENTS_DIR") {
    Ok(v) -> check_absolute(v)
    Error(_) -> user_home(fn(h) { h <> "/" <> "Documents" })
  }
}

pub fn pictures_dir() {
  case envoy.get("XDG_PICTURES_DIR") {
    Ok(v) -> check_absolute(v)
    Error(_) -> user_home(fn(h) { h <> "/" <> "Pictures" })
  }
}

pub fn videos_dir() {
  case envoy.get("XDG_VIDEOS_DIR") {
    Ok(v) -> check_absolute(v)
    Error(_) -> user_home(fn(h) { h <> "/" <> "Videos" })
  }
}

pub fn music_dir() {
  case envoy.get("XDG_MUSIC_DIR") {
    Ok(v) -> check_absolute(v)
    Error(_) -> user_home(fn(h) { h <> "/" <> "Music" })
  }
}

pub fn downloads_dir() {
  case envoy.get("XDG_DOWNLOAD_DIR") {
    Ok(v) -> check_absolute(v)
    Error(_) -> user_home(fn(h) { h <> "/" <> "Downloads" })
  }
}

fn user_home(with_home_fn: fn(String) -> String) {
  case envoy.get("HOME") {
    Ok(h) -> Ok(with_home_fn(h))
    Error(_) ->
      Error("User $HOME is not defined. It's required. Check your system.")
  }
}

fn check_absolute(path: String) {
  case is_absolute(path) {
    True -> Ok(path)
    False ->
      Error(
        "The read env variable does not represent an absolute path. Check your system.",
      )
  }
}

fn is_absolute(path: String) {
  True
}
