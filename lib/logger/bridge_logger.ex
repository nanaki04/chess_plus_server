defmodule ChessPlus.Logger.Bridge do
  use PathFinder.Gatekeeper
  alias LifeBloom.Bloom

  @env Mix.env()

  @impl(PathFinder.Gatekeeper)
  def inspect(next) do
    log_seed = Bloom.sow(&log/2)
    fn state ->
      log_seed = Bloom.nurish(log_seed, state)
      state_after = next.(state)
      Bloom.nurish(log_seed, state_after)
    end
  end

  @spec log(term, term) :: term
  def log(state_before, state_after) do
    %{
      wave: hd(state_before.gifts),
      sender: hd(tl(state_before.gifts)),
      result: state_after.result
    }
    |> ChessPlus.Logger.log(:flow)

    state_after
  end
end
