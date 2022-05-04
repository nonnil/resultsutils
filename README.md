# resultutils
[resultutils](https://github.com/nonnil/resultutils) to make [Result](https://github.com/arnetheduck/nim-result) handling easier.

inspired by [optionsutils](https://github.com/PMunch/nim-optionsutils).

## Usage

```nim
import results, resultsutils

func greet(name: string): Result[string, string] =
  if name.len > 0:
    return ok("hi, " & name)
  return err("No name? 😐")

let hiNim: string = match greet "Nim":
  Ok(greet):
    greet
  Err(_):
    "Oh no! something went wrong 😨"

assert hiNim == "hi, Nim"
```

more code examples can be found [here](https://github.com/nonnil/resultutils/tree/main/tests)

## Installation
```bash
nimble install resultutils
```

or add a dependency to your .nimble file:

```text
requires "resultutils"
```