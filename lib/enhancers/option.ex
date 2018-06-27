defmodule ChessPlus.Option do
  alias LifeBloom.Bloom

  @type option :: {:some, term}
    | :none

  @type result :: ChessPlus.Result.result

  @spec retn(term) :: option
  def retn(value), do: {:some, value}

  @spec map(option, fun) :: option
  def map({:some, value}, handle) do
    {:some, handle.(value)}
  end

  def map(none, _), do: none

  def option <|> handle, do: map(option, handle)

  @spec appl(option, option) :: option
  def appl({:some, handle}, {:some, value}) do
    Bloom.sow(handle)
    |> Bloom.nurish(value)
    |> (&{:some, &1}).()
  end

  def appl(_, _), do: :none

  def handle <~> option, do: appl(handle, option)

  @spec bind(option, fun) :: option
  def bind({:some, value}, handle) do
    handle.(value)
  end

  def bind(_, _), do: :none

  def option ~>> handle, do: bind(option, handle)

  @spec or_else(option, term) :: term
  def or_else(:none, default), do: default
  def or_else({:some, val}, _), do: val

  @spec or_else_with(option, fun) :: option
  def or_else_with(:none, handle), do: handle.()
  def or_else_with(some, _), do: some

  @spec orFinally(option, fun) :: any
  def orFinally(:none, handle), do: handle.()
  def orFinally(some, _), do: some

  @spec from_result(result) :: option
  def from_result({:ok, value}), do: {:some, value}
  def from_result({:error, _}), do: :none

  @spec to_result(option) :: result
  def to_result({:some, value}), do: {:ok, value}
  def to_result(:none), do: {:error, "No value found"}

  @spec unwrap([option]) :: option
  def unwrap(options) do
    Enum.reduce(options, [], fn
      {:some, value}, acc -> [value | acc]
      :none, acc -> acc
    end)
    |> case() do
      [] -> :none
      lst -> {:some, Enum.reverse(lst)}
    end
  end
end
