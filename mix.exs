defmodule Rediscovery.MixProject do
  use Mix.Project

  def project do
    [
      app: :rediscovery,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: [
        test: "test --no-start"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    case Mix.env() do
      :test ->
        [
          extra_applications: [:logger],
          mod: {Rediscovery.Application, []}
        ]

      _ ->
        [
          extra_applications: [:logger]
        ]
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:redix, "~> 1.0.0"},
      {:nimble_options, "~> 0.3.0"},
      {:local_cluster, "~> 1.2", only: [:test]}
    ]
  end
end
