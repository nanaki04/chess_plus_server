defmodule ChessPlus.Result do
  alias LifeBloom.Bloom
  alias ChessPlus.Matrix

  @type result :: {:ok, term}
    | {:error, String.t}

  @spec retn(term) :: result
  def retn(value), do: {:ok, value}

  @spec map(result, fun) :: result
  def map({:ok, value}, handle) do
    {:ok, handle.(value)}
  end

  def map(err, _), do: err

  def result <|> handle, do: map(result, handle)

  @spec appl(result, result) :: result
  def appl({:ok, handle}, {:ok, value}) do
    Bloom.sow(handle)
    |> Bloom.nurish(value)
    |> (&{:ok, &1}).()
  end

  def appl({:ok, _}, err), do: err

  def appl(err, _), do: err

  def handle <~> result, do: appl(handle, result)

  @spec bind(result, fun) :: result
  def bind({:ok, value}, handle) do
    handle.(value)
  end

  def bind(err, _), do: err

  def result ~>> handle, do: bind(result, handle)

  @spec unwrap([result]) :: result
  def unwrap(results) when is_list(results) do
    Enum.reduce(results, {:ok, []}, fn
      {:ok, value}, {:ok, lst} -> {:ok, [value | lst]}
      _, {:error, _} = error -> error
      error, _ -> error
    end)
    |> (fn
      {:ok, lst} -> {:ok, Enum.reverse(lst)}
      error -> error
    end).()
  end

  @spec flatten(result) :: result
  def flatten({:ok, {:ok, val}}), do: {:ok, val}
  def flatten({:ok, {:error, err}}), do: {:error, err}
  def flatten({:error, err}), do: {:error, err}

  @spec flat_map(Enum.t, fun) :: result
  def flat_map(enumerable, fun) do
    Enum.reduce(enumerable, {:ok, []}, fn
      element, acc ->
        {:ok, &Kernel.++/2}
        <~> acc
        <~> fun.(element)
    end)
  end

  @spec unwrap_matrix(Matrix.matrix) :: result
  def unwrap_matrix(matrix) do
    rows = Matrix.rows(matrix)
    |> unwrap()

    cols = Matrix.columns(matrix)
    |> Enum.map(&unwrap/1)
    |> unwrap()

    items = Matrix.items(matrix)
    |> Enum.map(&unwrap/1)
    |> unwrap()

    {:ok, &Matrix.zip/3}
    <~> rows
    <~> cols
    <~> items
  end

  @spec or_else(result, term) :: term
  def or_else({:error, _}, default), do: default
  def or_else({:ok, val}, _), do: val
  def or_else(invalid), do: ChessPlus.Logger.warn(invalid)

  @spec or_else_with(result, fun) :: term
  def or_else_with({:error, err}, handle), do: handle.(err)
  def or_else_with({:ok, val}, _), do: val
  def or_else_with(invalid), do: ChessPlus.Logger.warn(invalid)

  @spec expect(result) :: term
  def expect({:error, msg}), do: throw msg
  def expect(ok), do: ok

  def warn({:error, msg}) do
    ChessPlus.Logger.warn(msg)
    {:error, msg}
  end
  def warn(ok), do: ok

  @spec into(result, Collectable.t) :: result
  def into(result, collectable) do
    result
    <|> fn mp -> Enum.into(mp, collectable) end
  end
end
