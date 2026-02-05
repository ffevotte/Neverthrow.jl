module Neverthrow

export Ok, Err
export is_ok, is_err, unwrap
export map_ok, map_err
export unwrap_or, and_then, or_else
export and_tee, or_tee, and_through
export from_throwable, combine

abstract type Result end

struct Ok{T} <: Result
    value :: T
end

struct Err{T} <: Result
    value :: T
end

Ok() = Ok(nothing)
Err() = Err(nothing)

Base.:(==)(a::Ok{T}, b::Ok{T}) where {T} = (a.value == b.value)
Base.:(==)(a::Err{T}, b::Err{T}) where {T} = (a.value == b.value)

is_ok(result::Result) = result isa Ok
is_err(result::Result) = !is_ok(result)

unwrap(result::Result) = result.value

map_ok(f, result::Ok)  = Ok(f(unwrap(result)))
map_ok(_, result::Err) = result
map_ok(f) = result -> map_ok(f, result)
Base.map(f, r::Result) = map_ok(f, r)

map_err(_, result::Ok)  = result
map_err(f, result::Err) = Err(f(unwrap(result)))
map_err(f) = result -> map_err(f, result)

unwrap_or(result::Ok,  _) = unwrap(result)
unwrap_or(_::Err,  value) = value
unwrap_or(value) = result -> unwrap_or(result, value)

and_then(f, result::Ok)  = f(unwrap(result))
and_then(_, result::Err) = result
and_then(f) = result -> and_then(f, result)

or_else(_, result::Ok)  = result
or_else(f, result::Err) = f(unwrap(result))
or_else(f) = result -> or_else(f, result)

and_tee(f, result::Ok)  = begin f(unwrap(result)); result end
and_tee(_, result::Err) = result
and_tee(f) = result -> and_tee(f, result)

or_tee(_, result::Ok)  = result
or_tee(f, result::Err) = begin f(unwrap(result)); result end
or_tee(f) = result -> or_tee(f, result)

and_through(f, result::Ok)  = f(unwrap(result)) |> and_then(_ -> result)
and_through(_, result::Err) = result
and_through(f) = result -> and_through(f, result)


default_exc2err(exc) = sprint(showerror, exc)

from_throwable(f, exc2err=default_exc2err) = function(x)
    try
        Ok(f(x))
    catch e
        Err(exc2err(e))
    end
end

function combine(results)
    idx = findfirst(is_err, results)
    if idx === nothing
        Ok(map(unwrap, results))
    else
        results[idx]
    end
end

combine(args...) = combine(args)

end # module Neverthrow
