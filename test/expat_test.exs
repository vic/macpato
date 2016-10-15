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


end
