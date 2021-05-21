defmodule EdgeDB.MixProject do
  use Mix.Project

  def project do
    [
      app: :edgedb,
      version: "0.0.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_options: [
        warnings_as_errors: true
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        credo: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.github": :test,
        "coveralls.html": :test
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
      {:credo, "~> 1.2", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test}
    ]
  end
end
