defmodule ChessPlus.Logger.RuleLogger do
  alias ChessPlus.Delta.VerifyRules
  alias ChessPlus.Well.Rules
  alias ChessPlus.Logger

  @env Mix.env()
  @filter [:defeat, :remise]

  @spec log(VerifyRules.t, Rules.clause, (VerifyRules.t, Rules.clause -> boolean)) :: term
  def log(rule_state, clause, verify) do
    %{
      rule: rule_state.rule,
      piece: rule_state.piece,
      clause: clause,
      duelist: rule_state.duelist,
      is_simulation: rule_state.is_simulation,
      result: verify.(rule_state, clause)
    }
    |> log_rule()
    |> (fn %{result: result} -> result end).()
  end

  def log_rule(%{rule: {type, _}, result: true} = state) do
    case Enum.find([:move, :conquer], fn t -> t == type end) do
      nil -> state
      _ -> Logger.log(state, :rule, @env)
    end
  end

  def log_rule(%{rule: {type, _}} = state) do
    case Enum.find(@filter, fn t -> t == type end) do
      nil -> state
      _ -> Logger.log(state, :rule, @env)
    end
  end

end
