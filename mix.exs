defmodule Starchoice.MixProject do
  use Mix.Project

  @version "0.1.1"
  @description "Map decoding library"
  @github "https://github.com/nicklayb/starchoice"

  def project do
    [
      app: :starchoice,
      version: @version,
      elixir: "~> 1.8",
      description: @description,
      source_url: @github,
      docs: [
        main: "readme",
        extras: ["README.md"]
      ],
      package: package(),
      deps: [
        {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
        {:credo, "~> 0.6", only: [:dev, :test]},
        {:excoveralls, "~> 0.10", only: :test}
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test]
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @github
      },
      files: ["lib", "mix.exs", "mix.lock", "README.md", "LICENSE"],
      maintainers: ["Nicolas Boisvert"]
    ]
  end
end
