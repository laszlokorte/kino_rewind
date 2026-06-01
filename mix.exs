defmodule KinoRewind.MixProject do
  use Mix.Project

  def project do
    [
      app: :kino_rewind,
      version: "0.3.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      source_url: "https://github.com/laszlokorte/kino_zoetrope",
      package: package()
    ]
  end

  defp package() do
    %{
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/laszlokorte/kino_rewind"}
    }
  end

  defp description() do
    "Helper for rendering 3d and 4d `Nx.Tensor` as image sequences in Livebook via VegaLite."
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nx, "~> 0.12.0"},
      {:vega_lite, "~> 0.1.11"},
      {:colorex, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
