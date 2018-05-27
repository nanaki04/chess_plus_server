defmodule ChessPlus.ObserversTest do
  use ExUnit.Case
  doctest ChessPlus.Observers

  test "can subscribe" do
    defmodule TestObserver do
      use ChessPlus.Wave

      @impl(ChessPlus.Wave)
      def flow(_, _) do
        {:ok, ["Event Fired"]}
      end
    end

    defmodule TestObserver2 do
      use ChessPlus.Wave

      @impl(ChessPlus.Wave)
      def flow(wave, sender) do
        {:ok, [{wave, sender}]}
      end
    end

    defmodule TestObserverRegistry do
      use ChessPlus.Observers

      @observers [
        test: [
          TestObserver,
          TestObserver2
        ]
      ]
    end

    defmodule Finder do
      use PathFinder
      use PathFinder.Footprints

      gatekeeper TestObserverRegistry
      footprints __MODULE__
    end

    result = Finder.follow(:event, :test, [:wave, :sender])

    assert {:ok, [
      "Event Fired",
      {:wave, :sender}
    ]} = result
  end
end
