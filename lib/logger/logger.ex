defmodule ChessPlus.Logger do

  @env Mix.env()
  @blue [atom: :light_blue, map: :green, regex: :green, list: :cyan, number: :cyan, tuple: :cyan, reset: IO.ANSI.reset]
  @red [atom: :red, map: :yellow, regex: :yellow, list: :yellow, number: :yellow, tuple: :yellow, reset: IO.ANSI.reset]

  def log(state) do
    log(state, :log, @env)
  end

  def log(state, label) do
    log(state, label, @env)
  end

  def log(state, _, :prod), do: state

  def log(state, :log, _) do
    IO.inspect(state, label: IO.ANSI.light_blue <> "Log" <> IO.ANSI.reset)
  end

  def log(state, :flow, _) do
    IO.inspect(state, label: IO.ANSI.cyan <> "Flow" <> IO.ANSI.reset, syntax_colors: @blue)
  end

  def warn(state) do
    warn(state, @env)
  end

  def warn(state, :prod), do: state

  def warn(state, _) when is_binary(state) do
    IO.inspect(IO.ANSI.red <> state <> IO.ANSI.reset, label: IO.ANSI.red <> "Warning" <> IO.ANSI.reset)
  end

  def warn(state, _) do
    IO.inspect(state, label: IO.ANSI.red <> "Warning" <> IO.ANSI.reset, syntax_colors: @red)
  end

end
