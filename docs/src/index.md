# Neverthrow.jl

```@example ex
using Neverthrow
```

## `map_ok`, `map`

plain function application : `map` is an alias for `map_ok` 

```@repl ex
square(x::Real) = x^2
map(square, Ok(2))
map(square, Err("oops"))
```

chaining / piping calls : `map` can't be used like this, use `map_ok` instead

```@repl ex
Err("oops") |> map_ok(square)
```

## `map_err`

```@repl ex
Ok(:success) |> map_err(square)
Err(3) |> map_err(square)
```

## `unwrap_or`

```@repl ex
Ok(2) |> map_ok(square) |> unwrap_or(10)
Err("oops") |> map_ok(square) |> unwrap_or(10)
```

## `and_then`

chaining results

```@repl ex
sq(x) = Ok(x^2)

(Ok(2)
 |> and_then(sq)
 |> and_then(sq))

(Ok(2)
 |> and_then(sq)
 |> and_then(Err))

(Ok(2)
 |> and_then(Err)
 |> and_then(sq))

(Err("oops")
 |> and_then(sq)
 |> and_then(sq))
```

flattening nested results

```@repl ex
Ok(Ok(42)) |> and_then(identity)
```

## `or_else`

```@repl ex
recover(query_result) = or_else(query_result) do reason
    reason === :not_found && return Ok("User does not exist")
    return Err(500)
end

recover(Ok("found"))
recover(Err(:not_found))
recover(Err(:pool_exhausted))
```


## `and_tee`

```@repl ex
log_result(x) = @info "Got result $x"

(Ok(2)
 |> and_tee(log_result)
 |> and_then(sq))
```

## `or_tee`

```@repl ex
log_error(x) = @error "Got error $x"

(Err("oops")
 |> or_tee(log_error)
 |> and_then(sq))
```

## `and_through`

```@repl ex
validate(x) = (x == :valid ? Ok() : Err("invalid user"))

Ok(:valid) |> and_through(validate)
Ok(:invalid) |> and_through(validate)
Err("no user") |> and_through(validate)
```

## `from_throwable`

```@repl ex
const safe_sqrt = from_throwable(sqrt)
safe_sqrt(2)
safe_sqrt(-1)
```

## `combine`

```@repl ex
(Ok(1), Ok("foo")) |> combine
(Ok(1), Err("boom")) |> combine
```

```@repl ex
x = Ok(1)
y = Ok(2)

combine(x, y) |> map_ok(splat(+))
```
