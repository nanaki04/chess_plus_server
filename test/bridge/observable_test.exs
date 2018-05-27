defmodule ChessPlus.ObservableTest do
  use ExUnit.Case
  doctest ChessPlus.Observable

  test "can subscribe to observables" do
    defmodule TestObserver do
      use ChessPlus.Wave

      @impl(ChessPlus.Wave)
      def flow(_, _) do
        {:ok, ["Event Fired"]}
      end
    end

    defmodule TestObservable do
      use ChessPlus.Observable, domain: :test

      observer TestObserver
    end

    defmodule Finder do
      use PathFinder
      use PathFinder.Footprints

      gatekeeper TestObservable
      footprints __MODULE__
    end

    result = Finder.follow(:event, :test, [:wave, :sender])

    assert {:ok, ["Event Fired"]} = result
  end
end
