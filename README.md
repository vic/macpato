# Expat

Expat is a macro for very simple pattern matching on quoted elixir expressions.

## Installation

[Available in Hex](https://hex.pm/packages/expat), the package can be installed as:

  1. Add `expat` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:expat, "~> 0.1.0"}]
    end
    ```

## Usage

A typical pattern match on a quoted expression looks like this:

```elixir
assert {:foo, _ctx, _args} = quote(do: foo)
```

However as the complex expression, the complex the AST, and
sometimes you just want to pattern match on it

```elixir
iex> import Expat
...> expr = quote do
...>   fn a, b, c -> a + b + c end
...> end
...> case expr do
...>   expat(fn _, b, _ -> _ end) -> :b_is_second_arg
...>   _ -> :dunno
...> end
:b_is_second_arg
```

You can use the pin operator to bind a new variable, for
example, to get the name of the third argument bellow:

```elixir
iex> import Expat
...> expr = quote do
...>   fn a, b, c -> a + b + c end
...> end
...> case expr do
...>   expat(fn _, _, ^x -> _ end) ->
...>     with({name, _, _} <- x, do: name)
...>   _ -> :dunno
...> end
:c
```

The double pin lets you check on existing variables as in normal patterns.
The following example checks that we are adding the number 22

```elixir
iex> import Expat
...> expr = quote do
...>   fn a -> a + 22 end
...> end
...> x = 22
...> case expr do
...>   expat(fn _ -> _ + ^^x end) -> :good
...>   _ -> :dunno
...> end
:good
```


