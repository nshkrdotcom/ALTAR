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
      docs: docs()
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
    "The canonical Elixir implementation of the Altar Host, a protocol for secure, observable, and stateful interoperability between AI agents and tools."
  end

  defp package do
    [
      maintainers: ["nshkrdotcom"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Sponsor" => "https://github.com/sponsors/nshkrdotcom",
        "Specification" => "https://github.com/nshkrdotcom/ALTAR/tree/main/.kiro/specs/altar-protocol"
      },
      files: ~w(lib assets .formatter.exs mix.exs README* LICENSE* CHANGELOG* docs)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      assets: "assets",
      logo: "assets/altar-logo.svg",
      source_ref: "v#{@version}",
      source_url: @source_url,
      before_closing_head_tag: &docs_before_closing_head_tag/1,
      before_closing_body_tag: &docs_before_closing_body_tag/1
    ]
  end

  defp docs_before_closing_head_tag(:html) do
    """
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    """
  end

  defp docs_before_closing_head_tag(_), do: ""

  defp docs_before_closing_body_tag(:html) do
    """
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        mermaid.initialize({
          startOnLoad: true,
          theme: "base",
          themeVariables: {
            'background': '#ffffff',
            'primaryColor': '#f8fafc',
            'primaryTextColor': '#1e293b',
            'lineColor': '#64748b',
            'secondaryColor': '#e2e8f0',
            'tertiaryColor': '#f1f5f9',
            'primaryBorderColor': '#4338ca',
            'secondaryBorderColor': '#cbd5e1',
            'tertiaryBorderColor': '#94a3b8'
          }
        });
      });
    </script>
    """
  end

  defp docs_before_closing_body_tag(_), do: ""
end
