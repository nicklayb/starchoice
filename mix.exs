defmodule Starchoice.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "Map decoding library"
  @github "https://github.com/nicklayb/starchoice"
  def project do
    [
      app: :starchoice,
      version: @version,
      elixir: "~> 1.8",
      description: @description,
      source_url: @github,
      package: package()
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @github
      },
      files: ["lib", "mix.exs", "mix.lock"],
      maintainers: ["Nicolas Boisvert"]
    ]
  end
end
