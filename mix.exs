defmodule Auctoritas.MixProject do
  use Mix.Project

  def project do
    [
      app: :auctoritas,
      version: "0.1.0",
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
    "Session like authentication library for Phoenix/Elixir applications"
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "auctoritas",
      # These are the default files included in the package
      files: ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE*
                license* CHANGELOG* changelog* src),
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
