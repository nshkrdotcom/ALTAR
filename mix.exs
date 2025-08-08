defmodule Altar.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/nshkrdotcom/ALTAR"

  def project do
    [
      app: :altar,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      aliases: aliases(),
      preferred_cli_env: [
        check: :test,
        "check.ci": :test
      ],

      # Hex / Docs
      name: "Altar",
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Altar, []}
    ]
  end

  defp deps do
    [
      # Core runtime deps (none required currently)

      # Dev/Test dependencies
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.32", only: :dev, runtime: false},
      {:jason, "~> 1.4"}
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:mix, :ex_unit],
      flags: [:unmatched_returns, :error_handling, :race_conditions, :underspecs],
      ignore_warnings: ".dialyzer_ignore.exs",
      list_unused_filters: true
    ]
  end

  defp aliases do
    [
      check: ["format", "test", "credo --strict", "dialyzer"],
      "check.ci": [
        "deps.unlock --check-unused",
        "format --check-formatted",
        "test",
        "credo --strict",
        "dialyzer"
      ]
    ]
  end

  defp description do
    "Altar provides a robust, type-safe foundation for building AI agent tools in Elixir. It offers a clean protocol to define and execute tools locally, with a clear promotion path to future distributed systems."
  end

  defp package do
    [
      name: "altar",
      maintainers: ["nshkrdotcom"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Documentation" => "https://hexdocs.pm/altar"
      },
      files: ~w(lib assets .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "Altar",
      logo: "assets/altar-logo.svg",
      extras: ["README.md", "LICENSE"],
      groups_for_modules: [
        "Core Protocol": [
          Altar,
          Altar.Supervisor
        ],
        "ADM (Data Model)": [
          Altar.ADM,
          Altar.ADM.FunctionDeclaration,
          Altar.ADM.FunctionCall,
          Altar.ADM.ToolResult,
          Altar.ADM.ToolConfig
        ],
        "LATER (Local Runtime)": [
          Altar.LATER.Registry,
          Altar.LATER.Executor
        ]
      ],
      before_closing_head_tag: &mermaid_script/1,
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp mermaid_script(:html) do
    """
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <script>document.addEventListener("DOMContentLoaded", function() { mermaid.initialize({ startOnLoad: true }); });</script>
    """
  end

  defp mermaid_script(_), do: ""
end
