defmodule LiveRSS.MixProject do
  use Mix.Project

  def project do
    [
      app: :liverss,
      version: "0.2.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        name: :liverss,
        licenses: ["MIT"],
        description: "Stream RSS feeds with this GenServer",
        source_url: "https://github.com/vinibrsl/liverss",
        homepage_url: "https://github.com/vinibrsl/liverss",
        links: %{"GitHub" => "https://github.com/vinibrsl/liverss"}
      ],
      docs: [
        name: "LiveRSS",
        main: "LiveRSS",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      # applications: [:inets, :ssl],
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:fast_rss, "~> 0.5.0"},
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false}
    ]
  end
end
