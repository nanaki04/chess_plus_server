defmodule ChessPlus.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: ChessPlus.Worker.start_link(arg)
      # {ChessPlus.Worker, arg},
      ChessPlus.Gateway.Udp,
      ChessPlus.Gateway.Tcp,
      ChessPlus.Well.PlayerRegistry,
      {Task.Supervisor, name: ChessPlus.Task.Supervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChessPlus.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
