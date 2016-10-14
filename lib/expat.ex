defmodule Expat do

  @moduledoc ~S"""

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
      ...>   expat(fn _, _, ^^x -> _ end) ->
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

  defmacro expat(expr, opts \\ []) do
    expr
    |> Macro.prewalk(&pre(&1, opts))
    |> Macro.escape
    |> Macro.prewalk(&pos(&1, opts))
  end

  defp pre(expr, opts) do
    expr
    |> exref()
    |> placeholder()
    |> meta(Keyword.get(opts, :meta, false))
    |> context(Keyword.get(opts, :context, false))
  end

  defp pos(expr, _opts) do
    expr
    |> ref
    |> lowdash
  end

  defp exref({:^, _, [ref]}), do: {:_expat_ref, ref}
  defp exref(any), do: any

  defp placeholder({:_, _, _}), do: :_expat_
  defp placeholder(any), do: any

  defp meta({a, _, c}, false), do: {a, :_expat_, c}
  defp meta(any, _), do: any

  defp context({a, b, c}, false) when is_atom(a) and is_atom(c), do: {a, b, :_expat_}
  defp context(any, _), do: any

  # pin to variable
  defp ref({:_expat_ref, {:_expat_ref, {:{}, _, [a, _, _]}}}), do: {a, [], nil}
  # assign to variable
  defp ref({:_expat_ref, {:{}, _, [a, _, _]}}), do: {:^, [], [{a, [], nil}]}
  defp ref(any), do: any

  defp lowdash(:_expat_), do: {:_, [], Elixir}
  defp lowdash(any), do: any

end
