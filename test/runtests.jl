using Test
using Neverthrow

square(x::Real) = x^2

sq(x::Real) = Ok(square(x))

side_effect!(target, retval) = function(x)
    target[] = x+1
    return retval
end

@testset "Neverthrow" verbose=true begin
    @testset "constructors & operators" begin
	@test Ok(1) isa Ok{Int}
        @test Ok() isa Ok{Nothing}

        @test Err("oops") isa Err{String}
        @test Err() isa Err{Nothing}

        for x in (1, (1,2,3), [1,2,3], :symbol, "string")
            @test Ok(x) == Ok(identity.(x))
            @test Err(x) == Err(identity.(x))
            @test Ok(x) != Err(x)
        end

        @test Ok(1) != Ok(2)
        @test Err(1) != Err(2)
    end

    @testset "map & map_ok" begin
        @test map(square, Ok(2)) == Ok(4)
        @test map(square, Err("oops")) == Err("oops")

        @test map_ok(square, Ok(2)) == Ok(4)
        @test map_ok(square, Err("oops")) == Err("oops")

        @test Ok(2) |> map_ok(square) == Ok(4)
    end

    @testset "map_err" begin
        @test map_err(square, Ok(2)) == Ok(2)
        @test map_err(square, Err(3)) == Err(9)
        @test Err(3) |> map_err(square) == Err(9)
    end

    @testset "unwrap_or" begin
        @test Ok(2) |> unwrap_or(10) == 2
        @test Err("oops") |> unwrap_or(10) == 10
    end

    @testset "and_then" begin
        @test (Ok(2) |> and_then(sq)  |> and_then(sq))  == Ok(16)
        @test (Ok(2) |> and_then(sq)  |> and_then(Err)) == Err(4)
        @test (Ok(2) |> and_then(Err) |> and_then(sq))  == Err(2)
        @test (Err() |> and_then(sq)  |> and_then(sq))  == Err()

        @test Ok(Ok(42)) |> and_then(identity) == Ok(42)
    end

    @testset "or_else" begin
        @test Ok(3)  |> or_else(sq) == Ok(3)
        @test Err(3) |> or_else(sq) == Ok(9)
    end

    @testset "and_tee" begin
        let a = Ref(0)
            # Ok result + Ok side_effect
            a[] = 0
            @test Ok(1) |> and_tee(side_effect!(a, Ok(2))) == Ok(1)
            @test a[] == 2

            # Ok result + Err side_effect
            a[] = 0
            @test Ok(1) |> and_tee(side_effect!(a, Err("oops"))) == Ok(1)
            @test a[] == 2

            # Err result + Ok side_effect
            a[] = 0
            @test Err("boom") |> and_tee(side_effect!(a, Ok(2))) == Err("boom")
            @test a[] == 0

            # Err result + Err side_effect
            a[] = 0
            @test Err("boom") |> and_tee(side_effect!(a, Err("oops"))) == Err("boom")
            @test a[] == 0
        end
    end

    @testset "or_tee" begin
        let a = Ref(0)
            # Ok result + Ok side_effect
            a[] = 0
            @test Ok(1) |> or_tee(side_effect!(a, Ok(2))) == Ok(1)
            @test a[] == 0

            # Ok result + Err side_effect
            a[] = 0
            @test Ok(1) |> or_tee(side_effect!(a, Err("oops"))) == Ok(1)
            @test a[] == 0

            # Err result + Ok side_effect
            a[] = 0
            @test Err(2) |> or_tee(side_effect!(a, Ok(2))) == Err(2)
            @test a[] == 3

            # Err result + Err side_effect
            a[] = 0
            @test Err(2) |> or_tee(side_effect!(a, Err("oops"))) == Err(2)
            @test a[] == 3
        end
    end

    @testset "and_through" begin
        let a = Ref(0)
            # Ok result + Ok side effect
            a[] = 0
            @test Ok(1) |> and_through(side_effect!(a, Ok(2))) == Ok(1)
            @test a[] == 2

            # Ok result + Err side_effect
            a[] = 0
            @test Ok(1) |> and_through(side_effect!(a, Err("oops"))) == Err("oops")
            @test a[] == 2

            # Err result + Ok side_effect
            a[] = 0
            @test Err("boom") |> and_through(side_effect!(a, Ok(2))) == Err("boom")
            @test a[] == 0

            # Err result + Err side_effect
            a[] = 0
            @test Err("boom") |> and_through(side_effect!(a, Err("oops"))) == Err("boom")
            @test a[] == 0
        end
    end

    @testset "from_throwable" begin
        let
            safe_sqrt = from_throwable(sqrt)
            @test safe_sqrt(4) == Ok(2.0)
            @test safe_sqrt(-1) isa Err{String}
        end

        let
            safe_sqrt = from_throwable(sqrt, identity)
            @test safe_sqrt(4) == Ok(2.0)
            @test safe_sqrt(-1) isa Err{DomainError}
        end
    end

    @testset "combine" begin
        @test (Ok(1), Ok(2)) |> combine == Ok((1, 2))
        @test [Ok(1), Ok(2)] |> combine == Ok([1, 2])
        @test combine(Ok(i^2) for i in 1:3) == Ok([1, 4, 9])
        @test combine(Ok(1), Ok(2)) == Ok((1, 2))

        @test (Ok(1), Err("oops")) |> combine == Err("oops")
        @test (Err("oops"), Ok(2)) |> combine == Err("oops")
    end
end
