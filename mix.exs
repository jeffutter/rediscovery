defmodule Rediscovery.MixProject do
  use Mix.Project

  @name "Rediscovery"
  @version "0.3.3"
  @repo_url "https://github.com/jeffutter/rediscovery"

  def project do
    [
      app: :rediscovery,
      name: @name,
      version: @version,
      source_url: @repo_url,
      description: "Node discovery using redis",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: [
        test: "test --no-start"
      ],
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    case Mix.env() do
      :test ->
        [
          extra_applications: [:sasl, :logger],
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
      {:telemetry, "~> 0.4"},
      {:local_cluster, "~> 1.2", only: [:test]},
      {:ex_doc, "~> 0.20", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/jeffutter/rediscovery"}
    ]
  end

  defp docs do
    [
      main: @name,
      name: @name,
      canonical: "http://hexdocs.pm/rediscovery",
      source_url: @repo_url
    ]
  end
end
