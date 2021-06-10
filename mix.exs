defmodule EdgeDB.MixProject do
  use Mix.Project

  def project do
    [
      app: :edgedb,
      version: "0.0.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [
        warnings_as_errors: false
      ],
      consolidate_protocols: Mix.env() != :test,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        dialyzer: :test,
        credo: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.github": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_add_apps: [:ex_unit],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:crypto]
    ]
  end

  defp deps do
    [
      # core
      {:db_connection, "~> 2.0"},
      {:uuid, "~> 1.1"},
      {:decimal, "~> 2.0"},
      {:jason, "~> 1.2"},
      # dev/test
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.2", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test}
    ]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/support"]
  end

  defp elixirc_paths(_env) do
    ["lib"]
  end
end
