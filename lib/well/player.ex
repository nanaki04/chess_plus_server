defmodule ChessPlus.Well.Player do
  alias __MODULE__, as: Player

  @type player :: %Player{
    name: String.t
  }
  defstruct name: ""

end
