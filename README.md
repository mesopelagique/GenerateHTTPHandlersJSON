# GenerateHTTPHandlersJSON

Define your 4D Web Server API routes **in your code**, as comments above each
handler function — and let a method generate `HTTPHandlers.json` for you.

[![Blog](https://img.shields.io/badge/blog-blue.svg?style=flat)](https://mesopelagique.github.io/2026/06/29/generate-http-handlers-json.html)
## Why

4D's Web Server dispatches incoming HTTP requests to handler functions through a
[`HTTPHandlers.json`](https://developer.4d.com/docs/WebServer/http-request-handler#handler-definition)
file: each entry maps a URL `pattern` (or `regexPattern`) and HTTP `verbs` to a
`class` / `method`.

When I code the entry point of an API I want to **stay in the 4D code editor**,
not leave it to hand-edit a JSON file (`HTTPHandlers.json`, or any other
configuration method). Like in other languages where you declare an HTTP server,
I'd rather write the route pattern right next to the function that serves it — so
I write it in a comment, and this method reads those comments and generates the
JSON.

> A fully dynamic mechanism would require 4D to support annotations. Until then,
> this generator gives you the same ergonomics: routes live in the code.

You then have a choice:

- **Copy** the [`GenerateHTTPHandlers`](Project/Sources/Methods/GenerateHTTPHandlers.4dm)
  method into your own project, **or**
- **include this project as a component**,

and run the method whenever you want — at startup (if you authorize host
database events) or on demand.

## How it works

[`GenerateHTTPHandlers`](Project/Sources/Methods/GenerateHTTPHandlers.4dm)
([documentation](Documentation/Methods/GenerateHTTPHandlers.md)):

1. Scans every `.4dm` file in `Project/Sources/Classes`.
2. Keeps only **shared singleton** classes (the file must contain
   `shared singleton Class constructor`).
3. For each function whose signature receives a
   [`4D.IncomingMessage`](https://developer.4d.com/docs/API/IncomingMessageClass)
   and returns a
   [`4D.OutgoingMessage`](https://developer.4d.com/docs/API/OutgoingMessageClass),
   it reads the comment line **directly above** the function.
4. If that comment matches `// @VERB(pattern)`, it records an entry.
5. Writes all entries to `Project/Sources/HTTPHandlers.json`.

### Annotation format

Put the annotation on the line **immediately above** the `Function` declaration:

```
// @VERB(pattern)
```

- `VERB` → the HTTP method (`GET`, `POST`, …); it is lowercased into the
  `verbs` field of the generated handler.
- `pattern` → the URL pattern, written between the parentheses, and emitted as
  the `pattern` field.

### Example handler class

```4d
// Class: MyAPI  ->  shared singleton

shared singleton Class constructor()

// @GET(/hello)
Function getHello($request : 4D.IncomingMessage) : 4D.OutgoingMessage
	var $response:=4D.OutgoingMessage.new()
	$response.setBody("Hello, world!")
	return $response

// @POST(/users)
Function createUser($request : 4D.IncomingMessage) : 4D.OutgoingMessage
	var $response:=4D.OutgoingMessage.new()
	$response.setBody($request.getBody())
	return $response
```

Running `GenerateHTTPHandlers` then produces `Project/Sources/HTTPHandlers.json`:

```json
[
	{ "class": "MyAPI", "method": "getHello",   "pattern": "/hello", "verbs": "get" },
	{ "class": "MyAPI", "method": "createUser", "pattern": "/users", "verbs": "post" }
]
```

## Usage

### Run at startup (component)

When this project is included as a component, the
[`onHostDatabaseEvent`](Project/Sources/DatabaseMethods/onHostDatabaseEvent.4dm)
database method calls `GenerateHTTPHandlers` on
`On after host database startup`. This fires only if the host database
**authorizes host database events** for the component.

### Run on demand

`GenerateHTTPHandlers` is a shared project method — call it whenever you like:

```4d
GenerateHTTPHandlers
```

For example from a build/CI step, from the Runtime Explorer, or right after you
add or edit a handler, then restart the Web Server so it reloads
`HTTPHandlers.json`.

## Documentation

- Method reference: [`Documentation/Methods/GenerateHTTPHandlers.md`](Documentation/Methods/GenerateHTTPHandlers.md)
- 4D — [IncomingMessage class](https://developer.4d.com/docs/API/IncomingMessageClass)
- 4D — [OutgoingMessage class](https://developer.4d.com/docs/API/OutgoingMessageClass)
- 4D — [HTTP request handler · handler definition](https://developer.4d.com/docs/WebServer/http-request-handler#handler-definition)

## Continuous integration

GitHub Actions workflows are provided under `.github/workflows`:

- `build.yml` — compiles the project on every push / pull request touching `.4dm` files.
- `release.yml` — builds, packages and attaches an archive when a GitHub release is published.

## License

[MIT](LICENSE) © Eric Marchand (mesopelagique)
