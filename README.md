# Macpato

<a href="https://travis-ci.org/vic/macpato"><img src="https://travis-ci.org/vic/macpato.svg"></a>

Macpato is a macro for very simple pattern matching on quoted elixir expressions.

## Installation

[Available in Hex](https://hex.pm/packages/macpato), the package can be installed as:

  1. Add `macpato` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:macpato, "~> 0.1.2"}]
    end
    ```

## Usage

A typical pattern match on a quoted expression looks like this:

```elixir
{:foo, _ctx, _args} = quote(do: foo)
```

However for complex expression, the pattern to match the AST can get way longer.
macpato helps by giving you a way to create these patterns easily.

```elixir
iex> import Macpato
...> expr = quote do
...>   fn a, b, c -> a + b + c end
...> end
...> case expr do
...>   macpato(fn _, b, _ -> _ end) -> :b_is_second_arg
...>   _ -> :dunno
...> end
:b_is_second_arg
```

The `_` function is special inside macpato, and when given an argument
it will just place whatever you give it into the pattern.

This way you can for example, assign part of the match into a variable 
in this case to get the name of the third argument bellow:

```elixir
iex> import Macpato
...> expr = quote do
...>   fn a, b, c -> a + b + c end
...> end
...> case expr do
...>   macpato(fn _, _, _({name, _, _}) -> _ end) -> name
...>   _ -> :dunno
...> end
:c
```

Or use a pinned value, for example to check we are adding the number 22.

```elixir
iex> import Macpato
...> expr = quote do
...>   fn a -> a + 22 end
...> end
...> x = 22
...> case expr do
...>   macpato(fn _ -> _ + _(^x) end) -> :good
...>   _ -> :dunno
...> end
:good
```

You can capture arrays from the AST with `_(@)` for example:

```elixir
iex> import Macpato
...> expr = quote do
...>   fn a, b, c -> x end
...> end
...> case expr do
...>   macpato(fn _(@args) -> _ end) -> length(args)
...> end
3
```

Note that `macpato` can be used on any place where you can have a pattern in Elixir,
like macro definition arguments, cases, with expressions, etc.


See the [tests](https://github.com/vic/macpato/blob/master/test/macpato_test.exs) for more examples.
