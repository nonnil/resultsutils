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
  ## more code examples can be found `here<https://github.com/nonnil/resultsutils/blob/main/tests/test_match.nim>`_
  
  expectKind results, { nnkCall, nnkIdent, nnkCommand, nnkDotExpr, nnkStmtListExpr, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice }
  expectKind node, nnkStmtList

  type
    ResultKind = enum
      Ok
      Err

  func parseResultKind(node: NimNode): ResultKind =
    # a case label. expect `Ok` or `Err`.
    expectKind node, { nnkIdent, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice }
    if node.kind == nnkIdent:
      case $node
      of "Ok": return Ok
      of "Err": return Err
      else:
        error "Only \"Err\" and \"Ok\" are allowed as case labels"

    else:
      case $node
      of "OK", "Ok": return Ok
      of "ERR", "Err": return Err
      else:
        error "Only \"Err\" and \"Ok\" are allowed as case labels"

  var
    okIdent, okBody: NimNode
    errIdent, errBody: NimNode
  
  for child in node:
    expectKind child, nnkCall 

    # expectKind child[1], { nnkIdent, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice, nnkStmtList }

    let resultType = parseResultKind(child[0])
    var resultIdent, body: NimNode = nil

    # an ident
    if child[1].kind in { nnkIdent, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice }:
      # a body
      expectKind child[2], { nnkStmtList, nnkOpenSymChoice, nnkClosedSymChoice }
      resultIdent = if child[1].kind == nnkIdent: child[1]
        else: ident($child[1])
        # elif child[1].kind in { nnkSym, nnkOpenSymChoice, nnkClosedSymChoice }: ident($child[1])

      body = child[2]

    # if ident is not passed on
    else:
      expectKind child[1], { nnkStmtList, nnkOpenSymChoice, nnkClosedSymChoice }
      body = child[1]

    case resultType
    of Ok:
      okIdent = if (resultIdent.isNil) or ($resultIdent == "_"): nil
                else: resultIdent
      okBody = body

    of Err:
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