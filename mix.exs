defmodule Starchoice.MixProject do
  use Mix.Project

  def project do
    [
      app: :starchoice,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end

  def application, do: []
end
