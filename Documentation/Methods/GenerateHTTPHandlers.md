Generates `Project/Sources/HTTPHandlers.json` from `// @VERB(pattern)` comments written above your handler functions.

## Description

`GenerateHTTPHandlers` lets you declare 4D Web Server routes directly in your
code instead of hand-editing the
[`HTTPHandlers.json`](https://developer.4d.com/docs/WebServer/http-request-handler#handler-definition)
file. It is a **shared** project method and takes no parameters.

When called, it:

1. Scans every `.4dm` file in `Project/Sources/Classes`.
2. Skips any class that is not a **shared singleton** (the file must contain the
   text `shared singleton Class constructor`).
3. Iterates over the class lines and considers only function signatures that
   contain `Function `, receive a
   [`4D.IncomingMessage`](https://developer.4d.com/docs/API/IncomingMessageClass)
   and return a
   [`4D.OutgoingMessage`](https://developer.4d.com/docs/API/OutgoingMessageClass).
4. Reads the comment on the line **immediately above** that signature. If it
   matches `// @VERB(pattern)`, it extracts:
   - `verbs` — the HTTP method before `(`, lowercased (`GET` → `get`);
   - `pattern` — the text between `(` and `)`;
   - `method` — the function name after `Function `, up to `(`;
   - `class` — the class file name.
5. Pushes `{ class, method, pattern, verbs }` for each match and writes the full
   array to `Project/Sources/HTTPHandlers.json`
   (`JSON Stringify` with the pretty-print option).

### Annotation format

```
// @VERB(pattern)
Function <name>($request : 4D.IncomingMessage) : 4D.OutgoingMessage
```

The annotation must be on the line directly above the `Function` declaration,
and the signature must reference both `IncomingMessage` and `OutgoingMessage`
for the handler to be picked up.

### When to call it

- **At host startup** — the `onHostDatabaseEvent` database method calls it on
  `On after host database startup` when this project is included as a component
  and the host authorizes host database events.
- **On demand** — call `GenerateHTTPHandlers` from anywhere (build step,
  Runtime Explorer, …). Restart the Web Server afterwards so it reloads
  `HTTPHandlers.json`.

## Example

```4d
// Class MyAPI (shared singleton)

// @GET(/hello)
Function getHello($request : 4D.IncomingMessage) : 4D.OutgoingMessage
	var $response:=4D.OutgoingMessage.new()
	$response.setBody("Hello, world!")
	return $response
```

Calling the generator:

```4d
GenerateHTTPHandlers
```

produces in `Project/Sources/HTTPHandlers.json`:

```json
[
	{ "class": "MyAPI", "method": "getHello", "pattern": "/hello", "verbs": "get" }
]
```
