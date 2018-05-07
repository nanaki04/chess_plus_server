defmodule ChessPlus.Well do

  defmacro __using__(_) do
    quote do
      use Guardian.Secret
      @behaviour Guardian.Secret

      @type state :: term
      @type reply :: any
      @type updater :: (state -> {reply, state})
      @type id :: String.t
      @type sender :: %{ip: String.t, port: number}

      @spec update(id, updater) :: state
      def update(id, updater) do
        guard(id)
        call(id, {:update, updater})
      end

      @spec fetch(id) :: state
      def fetch(id) do
        update(id, fn state -> state end)
      end

      def handle_call({:update, updater}, _, state) do
        updater.(state)
        |> (&{:reply, &1, &1}).()
      end
    end
  end

end
