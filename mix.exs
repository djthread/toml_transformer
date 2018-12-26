defmodule TomlTransformer.MixProject do
  use Mix.Project

  def project do
    [
      app: :toml_transformer,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:toml, "~> 0.5"},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:credo, "~> 0.9.1", only: [:dev, :test]},
    ]
  end

  defp aliases do
    [
      lint: "credo --strict",
    ]
  end
end
