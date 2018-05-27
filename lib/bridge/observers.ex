defmodule ChessPlus.Observers do
  defmacro __using__(_) do
    quote do
      require ChessPlus.Observers
      @before_compile ChessPlus.Observers
    end
  end

  defmacro __before_compile__(env) do
    observers = Module.get_attribute(env.module, :observers)
    quoted_expressions = Enum.map(observers, fn {event_name, listeners} ->
      quote do
        defmodule unquote(Module.concat(ChessPlus.Observer, event_name)) do
          use ChessPlus.Observable, domain: unquote(event_name)

          Enum.each(unquote(Enum.reverse(listeners)), fn listener ->
            observer listener
          end)
        end
      end
    end)

    inspect = quote do
      use PathFinder.Gatekeeper

      @impl(PathFinder.Gatekeeper)
      def inspect(next) do
        Enum.reduce(unquote(observers), next, fn {event_name, _}, nxt ->
          apply(Module.concat(ChessPlus.Observer, event_name), :inspect, [nxt])
        end)
      end
    end

    [inspect | quoted_expressions]
    |> Enum.reverse()
    |> (&{:__block__, [], &1}).()
  end
end
