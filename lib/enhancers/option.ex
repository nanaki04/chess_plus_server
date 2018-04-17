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

  @spec orElse(option, term) :: term
  def orElse(:none, default), do: default
  def orElse({:some, val}, _), do: val

  @spec orElseWith(option, fun) :: option
  def orElseWith(:none, handle), do: handle.()
  def orElseWith(some, _), do: some

  @spec orFinally(option, fun) :: any
  def orFinally(:none, handle), do: handle.()
  def orFinally(some, _), do: some

  @spec fromResult(result) :: option
  def fromResult({:ok, value}), do: {:some, value}
  def fromResult({:error, _}), do: :none

  @spec toResult(option) :: result
  def toResult({:some, value}), do: {:ok, value}
  def toResult(:none), do: {:error, "No value found"}

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
