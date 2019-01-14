defmodule Auctoritas.MixProject do
  use Mix.Project

  def project do
    [
      app: :auctoritas,
      version: "0.4.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Auctoritas",
      source_url: "https://github.com/nkyian/auctoritas"
    ]
  end

  defp description() do
    "Session like authentication library for Elixir applications"
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "auctoritas",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/nkyian/auctoritas"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Auctoritas.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:secure_random, "~> 0.5"},
      {:cachex, "~> 3.1"},
      {:jason, "~> 1.1"}
    ]
  end
end
