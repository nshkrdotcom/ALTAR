defmodule Altar.ADM.FunctionDeclaration do
  @moduledoc """
  FunctionDeclaration represents a callable function's contract in the ADM.

  This structure mirrors industry patterns (e.g., Gemini, OpenAPI) while
  remaining intentionally simple. It defines the function's name, human-readable
  description, and a parameters schema (as a map for now).

  Use `new/1` to construct validated instances.
  """

  @typedoc """
  The parameters schema represented as a plain map for now (OpenAPI Schema-like).
  """
  @type parameters_schema :: map()

  @enforce_keys [:name, :description]
  defstruct name: nil,
            description: nil,
            parameters: %{}

  @typedoc """
  The validated FunctionDeclaration struct.
  """
  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          parameters: parameters_schema()
        }

  @doc """
  Construct a new validated `FunctionDeclaration`.

  Accepts a map or keyword list with:
  - `:name` (required): string matching ~r/^[a-zA-Z0-9_-]{1,64}$/
  - `:description` (required): non-empty string
  - `:parameters` (optional): map() – defaults to `%{}`

  Returns `{:ok, %FunctionDeclaration{}}` on success or `{:error, reason}`.
  """
  @spec new(map() | keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = normalize_attrs(attrs, [:name, :description, :parameters])

    with {:ok, name} <- require_string(attrs, :name, "name"),
         :ok <- validate_name(name),
         {:ok, description} <- require_string(attrs, :description, "description"),
         :ok <- validate_non_empty_string(description, "description"),
         {:ok, parameters} <- optional_map(attrs, :parameters, %{}, "parameters") do
      {:ok,
       %__MODULE__{
         name: name,
         description: description,
         parameters: parameters
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # -- Validation helpers ----------------------------------------------------

  @name_regex ~r/^[a-zA-Z0-9_-]{1,64}$/

  @spec validate_name(String.t()) :: :ok | {:error, String.t()}
  defp validate_name(name) when is_binary(name) do
    if Regex.match?(@name_regex, name) do
      :ok
    else
      {:error,
       "invalid name: must match ~r/^[a-zA-Z0-9_-]{1,64}$/ (alphanumeric, underscore, dash; max 64)"}
    end
  end

  @spec validate_non_empty_string(String.t(), String.t()) :: :ok | {:error, String.t()}
  defp validate_non_empty_string(value, field_name)
       when is_binary(value) and is_binary(field_name) do
    if String.trim(value) == "" do
      {:error, "#{field_name} cannot be empty"}
    else
      :ok
    end
  end

  # -- Attribute decoding helpers -------------------------------------------

  @spec normalize_attrs(map() | keyword(), [atom()]) :: map()
  defp normalize_attrs(attrs, allowed_keys) when is_list(attrs) do
    attrs
    |> Map.new()
    |> normalize_attrs(allowed_keys)
  end

  defp normalize_attrs(%{} = attrs, allowed_keys) do
    # Accept either atom or string keys; keep only allowed
    for key <- allowed_keys, reduce: %{} do
      acc ->
        value = Map.get(attrs, key)
        value = if value == nil, do: Map.get(attrs, Atom.to_string(key)), else: value
        if value == nil, do: acc, else: Map.put(acc, key, value)
    end
  end

  defp require_string(attrs, key, label) do
    case Map.fetch(attrs, key) do
      {:ok, value} when is_binary(value) -> {:ok, value}
      {:ok, _} -> {:error, "#{label} must be a string"}
      :error -> {:error, "missing required #{label}"}
    end
  end

  defp optional_map(attrs, key, default, label) do
    case Map.fetch(attrs, key) do
      {:ok, value} when is_map(value) -> {:ok, value}
      {:ok, _} -> {:error, "#{label} must be a map"}
      :error -> {:ok, default}
    end
  end
end
