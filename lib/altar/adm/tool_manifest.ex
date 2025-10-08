defmodule Altar.ADM.ToolManifest do
  @moduledoc """
  ToolManifest structure for ALTAR Data Model (ADM).

  A ToolManifest is a collection of tools that represents the complete set of
  capabilities available in a GRID Host's STRICT mode. It provides version
  tracking, metadata, and governance information for tool deployment.

  ## Structure

  A ToolManifest contains:
  - `version` - Semantic version of this manifest
  - `tools` - Array of Tool structures
  - `metadata` - Optional deployment metadata (environment, timestamp, etc.)

  ## Use Cases

  1. **GRID STRICT Mode** - Static manifest loaded at Host startup
  2. **Tool Governance** - Versioned, auditable tool deployments
  3. **Multi-Environment** - Different manifests for dev/staging/prod
  4. **Change Tracking** - Version history of tool availability

  ## Examples

      # Create a manifest
      {:ok, manifest} = ToolManifest.new(%{
        version: "1.0.0",
        tools: [weather_tool, calculator_tool],
        metadata: %{
          "environment" => "production",
          "deployed_at" => "2025-10-07T12:00:00Z",
          "deployed_by" => "ops@example.com"
        }
      })

      # Load from JSON file (GRID Host startup)
      manifest_json = File.read!("tool_manifest.json")
      {:ok, manifest} = ToolManifest.from_json(manifest_json)

  ## JSON Serialization

  Manifests are typically stored as JSON files:

      # Save manifest
      json = ToolManifest.to_json(manifest)
      File.write!("tool_manifest.json", json)

      # Load manifest
      {:ok, manifest} = ToolManifest.from_json(File.read!("tool_manifest.json"))
  """

  alias Altar.ADM.Tool

  @enforce_keys [:version, :tools]
  defstruct [:version, :tools, :metadata]

  @typedoc """
  A validated ToolManifest structure.
  """
  @type t :: %__MODULE__{
          version: String.t(),
          tools: [Tool.t()],
          metadata: %{optional(String.t()) => any()} | nil
        }

  @doc """
  Construct a new validated ToolManifest.

  ## Required Fields

  - `:version` - Semantic version string (e.g., "1.0.0")
  - `:tools` - List of Tool structs (can be empty for minimal manifests)

  ## Optional Fields

  - `:metadata` - Map of arbitrary metadata (environment, deployment info, etc.)

  ## Validation Rules

  1. Version must be a valid semantic version string
  2. Tools must be a list (can be empty)
  3. All tools must be valid Tool structs
  4. Tool names across all functions must be globally unique
  5. Metadata must be a map if provided

  Returns `{:ok, manifest}` or `{:error, reason}`.

  ## Examples

      # Minimal manifest
      {:ok, manifest} = ToolManifest.new(%{
        version: "1.0.0",
        tools: []
      })

      # Production manifest with metadata
      {:ok, manifest} = ToolManifest.new(%{
        version: "2.1.0",
        tools: [tool1, tool2, tool3],
        metadata: %{
          "environment" => "production",
          "region" => "us-east-1",
          "deployed_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "git_commit" => "abc123",
          "approver" => "security-team@example.com"
        }
      })
  """
  @spec new(map() | keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = normalize_attrs(attrs)

    with {:ok, version} <- validate_version(attrs),
         {:ok, tools} <- extract_tools(attrs),
         :ok <- validate_global_unique_names(tools),
         {:ok, metadata} <- optional_metadata(attrs) do
      {:ok,
       %__MODULE__{
         version: version,
         tools: tools,
         metadata: metadata
       }}
    end
  end

  @doc """
  Get a list of all function names across all tools in the manifest.

  Useful for checking tool availability in GRID STRICT mode.

  ## Examples

      iex> {:ok, manifest} = Altar.ADM.ToolManifest.new(%{
      ...>   version: "1.0.0",
      ...>   tools: [
      ...>     %{function_declarations: [%{name: "add", description: "Add", parameters: %{}}]},
      ...>     %{function_declarations: [%{name: "multiply", description: "Multiply", parameters: %{}}]}
      ...>   ]
      ...> })
      iex> Altar.ADM.ToolManifest.all_function_names(manifest)
      ["add", "multiply"]
  """
  @spec all_function_names(t()) :: [String.t()]
  def all_function_names(%__MODULE__{tools: tools}) do
    tools
    |> Enum.flat_map(&Tool.function_names/1)
    |> Enum.sort()
  end

  @doc """
  Find a function declaration by name across all tools.

  Returns `{:ok, {tool_index, declaration}}` if found, `{:error, :not_found}` otherwise.

  ## Examples

      {:ok, {0, decl}} = ToolManifest.find_function(manifest, "get_weather")
      {:error, :not_found} = ToolManifest.find_function(manifest, "nonexistent")
  """
  @spec find_function(t(), String.t()) ::
          {:ok, {non_neg_integer(), Altar.ADM.FunctionDeclaration.t()}}
          | {:error, :not_found}
  def find_function(%__MODULE__{tools: tools}, name) when is_binary(name) do
    tools
    |> Enum.with_index()
    |> Enum.find_value({:error, :not_found}, fn {tool, idx} ->
      case Tool.find_function(tool, name) do
        {:ok, declaration} -> {:ok, {idx, declaration}}
        {:error, :not_found} -> nil
      end
    end)
  end

  @doc """
  Check if a function name exists in the manifest.

  ## Examples

      true = ToolManifest.has_function?(manifest, "get_weather")
      false = ToolManifest.has_function?(manifest, "nonexistent")
  """
  @spec has_function?(t(), String.t()) :: boolean()
  def has_function?(%__MODULE__{} = manifest, name) do
    case find_function(manifest, name) do
      {:ok, _} -> true
      {:error, :not_found} -> false
    end
  end

  @doc """
  Get the number of tools in the manifest.
  """
  @spec tool_count(t()) :: non_neg_integer()
  def tool_count(%__MODULE__{tools: tools}), do: length(tools)

  @doc """
  Get the total number of functions across all tools.
  """
  @spec function_count(t()) :: non_neg_integer()
  def function_count(%__MODULE__{tools: tools}) do
    Enum.reduce(tools, 0, fn tool, acc ->
      acc + length(tool.function_declarations)
    end)
  end

  @doc """
  Convert manifest to JSON-serializable map.

  ## Examples

      map = ToolManifest.to_map(manifest)
      {:ok, json} = Jason.encode(map, pretty: true)
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{version: version, tools: tools, metadata: metadata}) do
    base = %{
      "version" => version,
      "tools" => Enum.map(tools, &Tool.to_map/1)
    }

    if metadata do
      Map.put(base, "metadata", metadata)
    else
      base
    end
  end

  @doc """
  Parse manifest from JSON-deserialized map.

  ## Examples

      map = Jason.decode!(json_string)
      {:ok, manifest} = ToolManifest.from_map(map)
  """
  @spec from_map(map()) :: {:ok, t()} | {:error, String.t()}
  def from_map(map) when is_map(map) do
    normalized =
      Map.new(map, fn
        {"version", v} -> {:version, v}
        {"tools", v} -> {:tools, v}
        {"metadata", v} -> {:metadata, v}
        {k, v} -> {k, v}
      end)

    new(normalized)
  end

  @doc """
  Convert manifest to pretty-printed JSON string.

  ## Examples

      json = ToolManifest.to_json(manifest)
      File.write!("manifest.json", json)
  """
  @spec to_json(t()) :: {:ok, String.t()} | {:error, Jason.EncodeError.t()}
  def to_json(%__MODULE__{} = manifest) do
    manifest
    |> to_map()
    |> Jason.encode(pretty: true)
  end

  @doc """
  Parse manifest from JSON string.

  ## Examples

      json = File.read!("manifest.json")
      {:ok, manifest} = ToolManifest.from_json(json)
  """
  @spec from_json(String.t()) :: {:ok, t()} | {:error, String.t()}
  def from_json(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, map} -> from_map(map)
      {:error, %Jason.DecodeError{} = e} -> {:error, "JSON decode error: #{Exception.message(e)}"}
    end
  end

  # -- Private validation helpers --------------------------------------------

  defp validate_version(%{version: version}) when is_binary(version) do
    # Basic semver validation: MAJOR.MINOR.PATCH
    if Regex.match?(~r/^\d+\.\d+\.\d+(-[\w.]+)?(\+[\w.]+)?$/, version) do
      {:ok, version}
    else
      {:error, "version must be valid semantic version (e.g., '1.0.0')"}
    end
  end

  defp validate_version(_) do
    {:error, "missing or invalid version"}
  end

  defp extract_tools(%{tools: tools}) when is_list(tools) do
    # Convert maps to Tools if needed
    validated_tools =
      Enum.reduce_while(tools, {:ok, []}, fn tool, {:ok, acc} ->
        case ensure_tool(tool) do
          {:ok, validated_tool} -> {:cont, {:ok, [validated_tool | acc]}}
          {:error, reason} -> {:halt, {:error, "invalid tool: #{reason}"}}
        end
      end)

    case validated_tools do
      {:ok, list} -> {:ok, Enum.reverse(list)}
      error -> error
    end
  end

  defp extract_tools(_) do
    {:error, "missing or invalid tools (must be array)"}
  end

  defp ensure_tool(%Tool{} = tool), do: {:ok, tool}

  defp ensure_tool(map) when is_map(map) do
    # Use Tool.new which handles both atom and string keys
    Tool.new(map)
  end

  defp ensure_tool(_) do
    {:error, "tool must be a Tool struct or map"}
  end

  defp validate_global_unique_names(tools) do
    all_names =
      tools
      |> Enum.flat_map(&Tool.function_names/1)

    unique_names = Enum.uniq(all_names)

    if length(all_names) == length(unique_names) do
      :ok
    else
      duplicates = all_names -- unique_names
      {:error, "duplicate function names across tools: #{inspect(duplicates)}"}
    end
  end

  defp optional_metadata(%{metadata: metadata}) when is_map(metadata), do: {:ok, metadata}
  defp optional_metadata(%{metadata: _}), do: {:error, "metadata must be a map"}
  defp optional_metadata(_), do: {:ok, nil}

  defp normalize_attrs(attrs) when is_list(attrs), do: Map.new(attrs)

  defp normalize_attrs(%{} = attrs) do
    # Accept both atom and string keys
    Map.new(attrs, fn
      {"version", v} -> {:version, v}
      {"tools", v} -> {:tools, v}
      {"metadata", v} -> {:metadata, v}
      {k, v} when is_atom(k) -> {k, v}
      {k, v} -> {String.to_atom(k), v}
    end)
  end
end
