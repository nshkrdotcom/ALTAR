defmodule ALTAR.MixProject do
  use Mix.Project

  @version "0.0.1"
  @source_url "https://github.com/nshkrdotcom/ALTAR"

  def project do
    [
      app: :altar,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "ALTAR",
      docs: [
        main: "ALTAR",
        source_ref: "v#{@version}",
        source_url: @source_url
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    ALTAR (The Agent & Tool Arbitration Protocol) is the canonical Elixir implementation of the Altar Host.
    It is a comprehensive, language-agnostic, and transport-agnostic protocol designed to enable secure,
    observable, and stateful interoperability between autonomous agents, AI models, and traditional software systems.
    """
  end

  defp package do
    [
      maintainers: ["nshkrdotcom"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Sponsor" => "https://github.com/sponsors/nshkrdotcom",
        "Specification" => "https://github.com/nshkrdotcom/ALTAR/tree/main/.kiro/specs/altar-protocol"
      }
    ]
  end
end
