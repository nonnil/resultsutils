import std / [ unittest, asyncdispatch, macros ]
import results
import ../ src / resultutils

suite "match macro":

  func example(): Result[string, void] =
    ok("something is ok")

  func greet(name: string): Result[string, string] =
    if name.len > 0:
      return ok("hi, " & name)
    return err("No name? 😐")

  proc asyncGreet(name: string = ""): Future[Result[string, string]] {.async.} =
    if name.len > 0:
      return ok("hi, " & name)
    else:
      return err("No name? 😐")

  test "general":

    match example():
      Ok(someOk):
        check:
          someOk == "something is ok"
      Err(_):
        fail
    
  test "void type":

    func returnVoid(flag: bool): Result[void, void] =
      if flag:
        ok()
      
      else:
        err()            

    match returnVoid(true):
      Ok():
        checkpoint("void ok")
      Err():
        fail

    match returnVoid(false):
      Ok():
        fail
      Err():
        checkpoint("void err")

  test "assigned from match":

    let msg: string = match example():
      Ok(someOk):
        "ok msg"
      Err():
        "sorry, error"

    check:
      msg == "ok msg"

    # test with nnkCommand
    let hiNim: string = match greet "Nim":
      Ok(greet):
        greet
      Err(_):
        "Oh no! something went wrong 😨"

    check:
      hiNim == "hi, Nim"

  test "nested":
    let msg = match example():
      Ok(_):
        let inside = match "Rust".greet():
          Ok(greet):
            # check:
            #   greeted == "hi, Rust"
            greet
          Err(_):
            "internal error"
        inside
      Err():
        fail
        "external error"

    check:
      msg == "hi, Rust"

    match example():
      Ok(outer):
        check:
          outer == "something is ok"

        match greet("Rust"):
          Ok(greet):
            check:
              greet == "hi, Rust"

          Err():
            fail

      Err():
        fail

  test "async":
    match waitFor asyncGreet("Nim"):
      Ok(greet):
        check:
          greet == "hi, Nim"
      
      Err(error):
        check:
          error == "No name? 😐"

  test "nest in template":
    # related to https://github.com/nim-lang/Nim/issues/11091
    template greet() =
      match waitFor asyncGreet():
        Ok(hi):
          check:
            hi.len > 0

        Err(msg):
          check:
            msg == "No name? 😐"
    greet