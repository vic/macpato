defmodule Expat do

  @moduledoc false
  @foo ~S"""

  iex> import Expat
  ...> expr = quote do
  ...>   fn a, b, c -> a + b + c end
  ...> end
  ...> case expr do
  ...>   expat(fn _, b, _ -> _ end) -> :b_is_second_arg
  ...>   _ -> :dunno
  ...> end
  :b_is_second_arg



  iex> import Expat
  ...> expr = quote do
  ...>   fn a, b, c -> a + b + c end
  ...> end
  ...> case expr do
  ...>   expat(fn _, _, _(^x) -> _ end) ->
  ...>     with({name, _, _} <- x, do: name)
  ...>   _ -> :dunno
  ...> end
  :c


  iex> import Expat
  ...> expr = quote do
  ...>   fn a -> a + 22 end
  ...> end
  ...> x = 22
  ...> case expr do
  ...>   expat(fn _ -> _ + ^x end) -> :good
  ...>   _ -> :dunno
  ...> end
  :good

  """

  defmodule Pre do
    def walk(expr, opts) do
      Macro.prewalk(expr, &step(&1, opts))
    end

    defp step({:^, _, [expr]}, _), do: [expat: expr]
    defp step(expr, opts) do
      expr
      |> lowd()
      |> meta(Keyword.get(opts, :meta, false))
      |> context(Keyword.get(opts, :meta, false))
    end

    defp lowd({:_, _, nil}), do: wildcard
    defp lowd(any), do: any

    defp meta({a, _, c}, false), do: {a, wildcard, c}
    defp meta(any, _), do: any

    defp context({a, b, c}, false) when is_atom(a) and is_atom(c), do: {a, b, wildcard}
    defp context(any, _), do: any

    defp wildcard do
      [expat: :_]
    end
  end

  defmodule Post do
    def walk(expr, _opts) do
      Macro.prewalk(expr, &step/1)
    end

    # wildcard
    defp step(expat: :_), do: {:_, [], nil}

    # assign to variable
    defp step(expat: [expat: {:{}, [], [name, _, _]}]) when is_atom(name) do
      {name, [], nil}
    end

    # pin to variable
    defp step(expat: {:{}, [], [name, _, _]}) when is_atom(name) do
      {:^, [], [{name, [], nil}]}
    end

    defp step(expat: expat) do
      raise "NEL #{inspect expat}"
    end
    defp step(any), do: any

  end

  defmacro expat(expr, opts \\ []) do
    expat_expr(expr, opts)
  end

  def expat_expr(expr, opts \\ []) do
    expr
    |> Pre.walk(opts)
    |> Macro.escape
    |> Post.walk(opts)
  end

end
