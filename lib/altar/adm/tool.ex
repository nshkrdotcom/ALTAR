defmodule Altar.ADM.Tool do
  @moduledoc """
  Tool structure for ALTAR Data Model (ADM).

  A Tool is the top-level container for AI capabilities, providing a standardized
  way to declare and organize function-based tools. It wraps one or more
  FunctionDeclaration structures.

  ## Structure

  A Tool contains:
  - `function_declarations` - Array of one or more FunctionDeclaration structs

  ## Examples

      # Simple tool with single function
      {:ok, tool} = Tool.new(%{
        function_declarations: [
          %Altar.ADM.FunctionDeclaration{
            name: "get_weather",
            description: "Get current weather",
            parameters: %{}
          }
        ]
      })

      # Complex tool with multiple related functions
      {:ok, tool} = Tool.new(%{
        function_declarations: [
          weather_forecast_declaration,
          weather_alerts_declaration,
          weather_history_declaration
        ]
      })

  ## JSON Serialization

  Tools can be serialized to/from JSON for interchange:

      {:ok, json} = Jason.encode(Tool.to_map(tool))
      {:ok, tool} = Tool.from_map(Jason.decode!(json))
  """

  alias Altar.ADM.FunctionDeclaration

  @enforce_keys [:function_declarations]
  defstruct [:function_declarations]

  @typedoc """
  A validated Tool structure.
  """
  @type t :: %__MODULE__{
          function_declarations: [FunctionDeclaration.t(), ...]
        }

  @doc """
  Construct a new validated Tool.

  ## Required Fields

  - `:function_declarations` - Non-empty list of FunctionDeclaration structs

  ## Validation Rules

  1. Must have at least one function declaration
  2. All elements must be valid FunctionDeclaration structs
  3. Function names must be unique within the tool
  4. Tool must be JSON-serializable

  Returns `{:ok, tool}` or `{:error, reason}`.

  ## Examples

      # From existing FunctionDeclarations
      {:ok, decl1} = FunctionDeclaration.new(%{name: "add", description: "Add numbers", parameters: %{}})
      {:ok, decl2} = FunctionDeclaration.new(%{name: "multiply", description: "Multiply", parameters: %{}})
      {:ok, tool} = Tool.new(%{function_declarations: [decl1, decl2]})

      # From raw maps (will be converted to FunctionDeclarations)
      {:ok, tool} = Tool.new(%{
        function_declarations: [
          %{name: "add", description: "Add numbers", parameters: %{}},
          %{name: "multiply", description: "Multiply", parameters: %{}}
        ]
      })
  """
  @spec new(map() | keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = normalize_attrs(attrs)

    with {:ok, declarations} <- extract_function_declarations(attrs),
         :ok <- validate_non_empty(declarations),
         :ok <- validate_unique_names(declarations) do
      {:ok, %__MODULE__{function_declarations: declarations}}
    end
  end

  @doc """
  Get a list of all function names defined in this tool.

  ## Examples

      iex> {:ok, tool} = Altar.ADM.Tool.new(%{
      ...>   function_declarations: [
      ...>     %{name: "add", description: "Add", parameters: %{}},
      ...>     %{name: "multiply", description: "Multiply", parameters: %{}}
      ...>   ]
      ...> })
      iex> Altar.ADM.Tool.function_names(tool)
      ["add", "multiply"]
  """
  @spec function_names(t()) :: [String.t()]
  def function_names(%__MODULE__{function_declarations: declarations}) do
    Enum.map(declarations, & &1.name)
  end

  @doc """
  Find a function declaration by name.

  Returns `{:ok, declaration}` if found, `{:error, :not_found}` otherwise.

  ## Examples

      {:ok, decl} = Tool.find_function(tool, "add")
      {:error, :not_found} = Tool.find_function(tool, "nonexistent")
  """
  @spec find_function(t(), String.t()) :: {:ok, FunctionDeclaration.t()} | {:error, :not_found}
  def find_function(%__MODULE__{function_declarations: declarations}, name)
      when is_binary(name) do
    case Enum.find(declarations, &(&1.name == name)) do
      nil -> {:error, :not_found}
      declaration -> {:ok, declaration}
    end
  end

  @doc """
  Convert tool to JSON-serializable map.

  ## Examples

      map = Tool.to_map(tool)
      json = Jason.encode!(map)
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{function_declarations: declarations}) do
    %{
      "function_declarations" =>
        Enum.map(declarations, fn decl ->
          %{
            "name" => decl.name,
            "description" => decl.description,
            "parameters" => decl.parameters
          }
        end)
    }
  end

  @doc """
  Parse tool from JSON-deserialized map.

  ## Examples

      json = ~s({"function_declarations": [{"name": "add", "description": "Add", "parameters": {}}]})
      map = Jason.decode!(json)
      {:ok, tool} = Tool.from_map(map)
  """
  @spec from_map(map()) :: {:ok, t()} | {:error, String.t()}
  def from_map(%{"function_declarations" => declarations}) when is_list(declarations) do
    new(%{function_declarations: declarations})
  end

  def from_map(_) do
    {:error, "invalid tool map: missing or invalid function_declarations"}
  end

  # -- Private validation helpers --------------------------------------------

  defp extract_function_declarations(%{function_declarations: declarations})
       when is_list(declarations) do
    # Convert maps to FunctionDeclarations if needed
    validated_declarations =
      Enum.reduce_while(declarations, {:ok, []}, fn decl, {:ok, acc} ->
        case ensure_function_declaration(decl) do
          {:ok, validated_decl} -> {:cont, {:ok, [validated_decl | acc]}}
          {:error, reason} -> {:halt, {:error, "invalid function declaration: #{reason}"}}
        end
      end)

    case validated_declarations do
      {:ok, list} -> {:ok, Enum.reverse(list)}
      error -> error
    end
  end

  defp extract_function_declarations(_) do
    {:error, "missing or invalid function_declarations (must be non-empty array)"}
  end

  defp ensure_function_declaration(%FunctionDeclaration{} = decl), do: {:ok, decl}

  defp ensure_function_declaration(map) when is_map(map) do
    FunctionDeclaration.new(map)
  end

  defp ensure_function_declaration(_) do
    {:error, "function declaration must be a FunctionDeclaration struct or map"}
  end

  defp validate_non_empty([]), do: {:error, "function_declarations cannot be empty"}
  defp validate_non_empty(_), do: :ok

  defp validate_unique_names(declarations) do
    names = Enum.map(declarations, & &1.name)
    unique_names = Enum.uniq(names)

    if length(names) == length(unique_names) do
      :ok
    else
      duplicates = names -- unique_names
      {:error, "duplicate function names: #{inspect(duplicates)}"}
    end
  end

  defp normalize_attrs(attrs) when is_list(attrs), do: Map.new(attrs)

  defp normalize_attrs(%{} = attrs) do
    # Accept both atom and string keys
    Map.new(attrs, fn
      {"function_declarations", v} -> {:function_declarations, v}
      {:function_declarations, v} -> {:function_declarations, v}
      {k, v} -> {k, v}
    end)
  end
end
