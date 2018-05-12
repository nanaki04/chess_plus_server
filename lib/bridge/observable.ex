defmodule ChessPlus.Observable do

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import ChessPlus.Observable

      Module.register_attribute(__MODULE__, :observer, accumulate: true)
      @domain Keyword.get(opts, :domain, :global)
      @before_compile ChessPlus.Observable
    end
  end

  defmacro __before_compile__(env) do
    mod = env.module
    domain = Module.get_attribute(mod, :domain)
    observers = Module.get_attribute(mod, :observer)

    quote do
      use PathFinder.Gatekeeper

      @impl(PathFinder.Gatekeeper)
      def inspect(next) do
        fn
          %{footprint: :event, breadcrum: unquote(domain)} = state ->
            %{
              state
              | footprints: Keyword.put(
                state.footprints, :event, [{unquote(domain), {:self, unquote(mod), :fire, []}}]
              )
            }
            |> next.()
          state ->
            next.(state)
        end
      end

      def fire(wave, sender) do
        import ChessPlus.Result, only: [<~>: 2]

        Enum.reduce(unquote(observers), {:ok, []}, fn obs, result ->
          {:ok, &Kernel.++/2}
          <~> result
          <~> obs.flow(wave, sender)
        end)
      end
    end
  end

  defmacro observer(obs) do
    quote do
      @observer unquote(obs)
    end
  end

end
