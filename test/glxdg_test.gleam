import gleeunit
import gleeunit/should
import glxdg as x
import glxdg.{type AppName}

pub fn main() {
  gleeunit.main()
}

pub fn app_name_create_problem_empty_test() {
  x.app("")
  |> should.equal(Error(
    "The 'name' for the application is empty. Provide a name.",
  ))
}

pub fn app_name_good_test() {
  x.app("foobar")
  |> should.equal(Ok(x.unsafe_app("foobar")))
}
