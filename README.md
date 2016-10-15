# Expat

Expat is a macro for very simple pattern matching on quoted elixir expressions.

## Installation

[Available in Hex](https://hex.pm/packages/expat), the package can be installed as:

  1. Add `expat` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:expat, "~> 0.1.1"}]
    end
    ```

## Usage

A typical pattern match on a quoted expression looks like this:

```elixir
{:foo, _ctx, _args} = quote(do: foo)
```

However for complex expression, the pattern to match the AST can get way longer.
expat helps by giving you a way to create these patterns easily.

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

The `_` function is special inside expat, and when given an argument
it will just place whatever you give it into the pattern.

This way you can for example, assign part of the match into a variable 
in this case to get the name of the third argument bellow:

```elixir
iex> import Expat
...> expr = quote do
...>   fn a, b, c -> a + b + c end
...> end
...> case expr do
...>   expat(fn _, _, _({name, _, _}) -> _ end) -> name
...>   _ -> :dunno
...> end
:c
```

Or use a pinned value, for example to check we are adding the number 22.

```elixir
iex> import Expat
...> expr = quote do
...>   fn a -> a + 22 end
...> end
...> x = 22
...> case expr do
...>   expat(fn _ -> _ + _(^x) end) -> :good
...>   _ -> :dunno
...> end
:good
```

You can capture arrays from the AST with `_(@)` for example:

```elixir
iex> import Expat
...> expr = quote do
...>   fn a, b, c -> x end
...> end
...> case expr do
...>   expat(fn _(@args) -> _ end) -> length(args)
...> end
3
```

Note that `expat` can be used on any place where you can have a pattern in Elixir,
like macro definition arguments, cases, with expressions, etc.
