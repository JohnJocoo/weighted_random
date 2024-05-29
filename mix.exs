defmodule WeightedRandom.MixProject do
  use Mix.Project

  def project do
    [
      app: :better_weighted_random,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
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
      {:stream_data, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.33", only: :dev, runtime: false},
      {:earmark, "~> 1.4", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end

  defp description do
    """
    Weighted random pick library optimised for quick take_one and take_n operations.
    """
  end

  defp package do
    [
     files: ["lib", "mix.exs", "README.md"],
     maintainers: ["Anton Frolov"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/JohnJocoo/weighted_random",
              "Docs" => "https://hexdocs.pm/better_weighted_random/"}
     ]
  end
end
