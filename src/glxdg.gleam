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
import gleam/option
import envoy

pub fn main() {
  let a = app("")
  let b = app("x")

  io.debug(a)
  io.debug(b)

  b
  |> result.map(fn(app) {
    //io.debug(app_runtime_dir(app))
    io.debug(app_config_dir(app))
    io.debug(app_cache_dir(app))
    io.debug(app_data_dir(app))
    io.debug(app_state_dir(app))
  })

  // --

  io.debug(desktop_dir())
  io.debug(downloads_dir())
  io.debug(pictures_dir())
  io.debug(videos_dir())
  io.debug(music_dir())
  io.debug(documents_dir())
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

pub type Xdg {
  // Project dirs
  XdgRuntimeHome
  XdgConfigHome
  XdgCacheHome
  XdgDataHome
  XdgStateHome

  // User dirs
  XdgDesktopDir
  XdgDownloadDir
  XdgPicturesDir
  XdgVideosDir
  XdgMusicDir
  XdgDocumentsDir
}

pub type XdgError {
  EnvVarNotAvailable(String)
  EnvVarInvalid(String)
  EnvVarHomeProblem(String)
}

pub fn var_name(var: Xdg) -> String {
  case var {
    // Project dirs
    XdgRuntimeHome -> "XDG_RUNTIME_DIR"
    XdgConfigHome -> "XDG_CONFIG_HOME"
    XdgCacheHome -> "XDG_CACHE_HOME"
    XdgDataHome -> "XDG_DATA_HOME"
    XdgStateHome -> "XDG_STATE_HOME"

    // User dirs
    XdgDesktopDir -> "XDG_DESKTOP_DIR"
    XdgDownloadDir -> "XDG_DOWNLOAD_DIR"
    XdgPicturesDir -> "XDG_PICTURES_DIR"
    XdgVideosDir -> "XDG_VIDEOS_DIR"
    XdgMusicDir -> "XDG_MUSIC_DIR"
    XdgDocumentsDir -> "XDG_DOCUMENTS_DIR"
  }
}

pub fn env_get(var: Xdg) -> Result(#(String, String), XdgError) {
  let name = var_name(var)

  envoy.get(name)
  |> result.map(fn(value) { #(name, value) })
  |> result.map_error(fn(_) {
    EnvVarNotAvailable(
      "Requested environment variable - " <> name <> " - could not be found.",
    )
  })
}

pub fn env_home() -> Result(String, XdgError) {
  case envoy.get("HOME") {
    Ok(value) ->
      case string.is_empty(value) {
        True ->
          Error(EnvVarHomeProblem(
            "User $HOME is defined but appears to be empty. "
            <> "Check your system, it's likely misconfigured.",
          ))

        False -> Ok(value)
      }

    Error(_) ->
      Error(EnvVarHomeProblem(
        "User $HOME is not defined. It's required. "
        <> "Check your system, it's likely misconfigured.",
      ))
  }
}

// Project dirs

// pub fn app_runtime_dir(app: AppName) {
//  case envoy.get("XDG_RUNTIME_DIR") {
//    Ok(v) ->
//      check_absolute(v)
//      |> result.map(fn(_) { v <> "/" <> app.v })

//    Error(_) -> Error("Could not find expected XDG runtime dir.")
//  }
//}

pub fn app_config_dir(app: AppName) {
  app_use_var_or_fallback(app, XdgConfigHome, ".config")
}

pub fn app_cache_dir(app: AppName) {
  app_use_var_or_fallback(app, XdgCacheHome, ".cache")
}

pub fn app_data_dir(app: AppName) {
  app_use_var_or_fallback(app, XdgDataHome, ".local/share")
}

pub fn app_state_dir(app: AppName) {
  app_use_var_or_fallback(app, XdgStateHome, ".local/state")
}

fn app_use_var_or_fallback(app: AppName, var: Xdg, fallback_dir: String) {
  case env_get(var) {
    Ok(#(name, value)) ->
      validate_path(name, value)
      |> result.map(make_path(_, app.v))

    Error(_) -> {
      env_home()
      |> result.map(make_path(_, fallback_dir <> "/" <> app.v))
    }
  }
}

// User dirs

pub fn desktop_dir() -> Result(String, XdgError) {
  use_var_or_fallback(XdgDesktopDir, "Desktop")
}

pub fn documents_dir() -> Result(String, XdgError) {
  use_var_or_fallback(XdgDocumentsDir, "Documents")
}

pub fn pictures_dir() -> Result(String, XdgError) {
  use_var_or_fallback(XdgPicturesDir, "Pictures")
}

pub fn videos_dir() -> Result(String, XdgError) {
  use_var_or_fallback(XdgVideosDir, "Videos")
}

pub fn music_dir() -> Result(String, XdgError) {
  use_var_or_fallback(XdgMusicDir, "Music")
}

pub fn downloads_dir() -> Result(String, XdgError) {
  use_var_or_fallback(XdgDownloadDir, "Downloads")
}

fn use_var_or_fallback(var: Xdg, fallback_dir: String) {
  case env_get(var) {
    Ok(#(name, value)) -> validate_path(name, value)

    Error(_) -> {
      env_home()
      |> result.map(make_path(_, fallback_dir))
    }
  }
}

fn validate_path(var: String, value: String) -> Result(String, XdgError) {
  case string.is_empty(value), is_absolute(value) {
    False, True -> Ok(value)
    _, _ ->
      Error(EnvVarInvalid(
        "The environment variable - "
        <> var
        <> " - is not an absolute path or is empty. "
        <> "Check your system, it's likely misconfigured.",
      ))
  }
}

fn make_path(base, specific) {
  base <> "/" <> specific
}

fn user_home(with_home_fn: fn(String) -> String) {
  case envoy.get("HOME") {
    Ok(h) -> Ok(with_home_fn(h))
    Error(_) ->
      Error("User $HOME is not defined. It's required. Check your system.")
  }
}

fn is_absolute(path: String) {
  True
}
