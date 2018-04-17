defmodule ChessPlus.Dto.Waves do

  def exportLocation({domain, invocation}) do
    %{"Domain": domain, "Invocation": invocation}
  end

  def importLocation(%{"Location": %{"Domain": domain, "Invocation": invocation}}) do
    {domain, invocation}
  end

  def export({location, amplitude}, exportAmplitude) do
    amplitude
    |> exportAmplitude.()
    |> Map.put("Location", exportLocation(location))
  end

  def import(wave, importAmplitude) do
    {importLocation(wave), importAmplitude.(wave)}
  end
end
