defmodule ChessPlus.Well do

  defmacro __using__(_) do
    quote do
      use Guardian.Secret
      alias ChessPlus.Result
      @behaviour Guardian.Secret

      @type state :: term
      @type reply :: any
      @type updater :: (state -> state)
      @type id :: String.t
      @type sender :: %{ip: String.t, port: number}

      @spec update!(id, updater) :: state
      def update!(id, updater) do
        guard(id)
        call(id, {:update!, updater})
      end

      @spec update(id, (state -> Result.result)) :: Result.result
      def update(id, updater) do
        guard(id)
        call(id, {:update, updater})
      end

      @spec fetch(id) :: state
      def fetch(id) do
        update!(id, fn state -> state end)
      end

      def handle_call({:update!, updater}, _, state) do
        updater.(state)
        |> (&{:reply, &1, &1}).()
      end

      def handle_call({:update, updater}, _, state) do
        updater.(state)
        |> Result.map(&{:reply, {:ok, &1}, &1})
        |> Result.or_else_with(&{:reply, {:error, &1}, state})
      end
    end
  end

end
