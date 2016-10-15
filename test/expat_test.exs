defmodule ExpatTest do
  use ExUnit.Case

  import Expat

  doctest Expat

  test "can match a literal value" do
    assert expat(2) = 2
  end

  test "can match a name" do
    assert expat(hola) = quote(do: hola)
  end

  test "can match a simple call" do
    assert expat(hola(adios)) = quote(do: hola(adios))
  end

  test "can match a simple call with placeholder" do
    assert expat(hola(_)) = quote(do: hola(adios))
  end

  test "can create a variable with part of the pattern" do
    assert expat(hola(_(x))) = quote(do: hola(adios))
    assert {:adios, _, _} = x
  end

  test "can bind a variable with part of the pattern" do
    x = 22
    assert expat(hola(_(^x))) = quote(do: hola(22))
  end

  test "can match placeholder on function arg and body" do
    assert expat(fn _ -> _ end) = quote(do: fn hola -> adios end)
  end

  test "can embed another pattern with _" do
    assert expat(fn a, _({n, _, _}) -> c end) = quote(do: fn a, b -> c end)
    assert :b == n
  end

  test "can capture a function arguments with _(@)" do
    assert expat(fn _(@args) -> c end) = quote(do: fn a, b, c -> c end)
    assert 3 == length(args)
  end

  test "can match a binary op" do
    assert expat(_(a) | _) = quote(do: x | y)
    assert expat(x) = a
  end

  test "can capture a call args" do
    assert expat(x(_(@args))) = quote(do: x(1, 2, 3))
    assert [1, 2, 3] == args
  end

  test "can capture a simple array" do
    assert expat([_(@items)])  = quote(do: [1, 2, 3])
    assert [1, 2, 3] == items
  end

  test "can capture from array concat" do
    assert expat(fn [_(@[x, y, z])] -> _ end) = quote(do: fn [a, b, c | d] -> x end)
    assert expat(a) = x
    assert expat(b) = y
    assert expat(c | d) = z
  end

end
