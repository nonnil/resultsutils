## Utility macros for easier handling of Result
import std / [ macros ]
import results

macro match*(results: untyped, node: untyped): untyped =
  ## It can be used like a general ``case`` branch, but expect ``Result`` as the first argument.
  ## 
  ## Use ``_`` ident for the return value discard.
  ## 
  ## ``ident`` is not required for ``void`` type.
  ## 
  ## .. code-block:: nim
  ##   func example(): Result[string, void] =
  ##     ok("something is ok")
  ## 
  ##   match example():
  ##     Ok(someOk):
  ##       assert someOk == "something is ok"
  ##     # not required an ident
  ##     Err():
  ##       break
  ## 
  ## Assign a content of ``Result`` directly from ``match`` to a variable:
  ## 
  ## .. code-block:: nim
  ##   func greet(name: string): Result[string, string] =
  ##     if name.len > 0:
  ##       return ok("hi, " & name)
  ## 
  ##     return err("No name? 😐")
  ## 
  ##   let msg: string = match greet "Nim":
  ##     Ok(greet):
  ##       greet
  ##     # discard an error content
  ##     Err(_):
  ##       "Oh no! something went wrong 😨"
  ##    
  ##    assert msg == "hi, Nim"
  ## 
  ## more code examples can be found `here<https://github.com/nonnil/resultutils/blob/main/tests/test_match.nim>`_

  expectKind results, { nnkCall, nnkIdent, nnkCommand, nnkDotExpr }
  expectKind node, nnkStmtList

  type
    ResultKind = enum
      Ok
      Err

  func isResultKind(str: string): bool =
    case str
    of $Ok, $Err:
      true

    else: false

  var
    okIdent, okBody: NimNode
    errIdent, errBody: NimNode
  
  for child in node:
    expectKind child, nnkCall 
    # a case label. expect `Ok` or `Err`.
    expectKind child[0], nnkIdent
      
    let resultType = $child[0]
    var resultIdent, body: NimNode = nil

    # an ident
    if child[1].kind == nnkIdent:
      # a body
      expectKind child[2], nnkStmtList
      resultIdent = child[1]
      body = child[2]

    # if ident is not passed on
    else:
      expectKind child[1], nnkStmtList
      body = child[1]

    if not resultType.isResultKind(): error "Only \"Err\" and \"Ok\" are allowed as case labels"
    case resultType
    of $Ok:
      okIdent = if (resultIdent.isNil) or ($resultIdent == "_"): nil
                else: resultIdent
      okBody = body

    of $Err:
      errIdent = if (resultIdent.isNil) or ($resultIdent == "_"): nil
                 else: resultIdent
      errBody = body

  let
    tmp = genSym(nskLet)
    getSym = bindSym"get"
    errorSym = bindSym"error"

    # ignore assign if the ident is `_` or nil
    okAssign = if okIdent.isNil: newEmptyNode()
               else: quote do:
      let `okIdent` = `getSym`(`tmp`)

    # ignore assign if the ident is `_` or nil
    errAssign = if errIdent.isNil: newEmptyNode()
                else: quote do:
      let `errIdent` = `errorSym`(`tmp`)

  result = quote do:
    let `tmp` = `results`
    if `tmp`.isOk:
      `okAssign`
      `okBody`
    
    else:
      `errAssign`
      `errBody`