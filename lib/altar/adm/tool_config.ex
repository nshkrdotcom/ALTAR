defmodule Altar.ADM.ToolConfig do
  @moduledoc """
  ToolConfig encapsulates model/tool-calling configuration, including mode and
  an optional allowlist of function names.

  Use `new/1` to construct validated instances.
  """

  @typedoc """
  Tool selection mode.
  """
  @type mode :: :auto | :any | :none

  @enforce_keys [:mode]
  defstruct mode: :auto,
            function_names: []

  @typedoc """
  A validated ToolConfig struct.
  """
  @type t :: %__MODULE__{
          mode: mode(),
          function_names: [String.t()]
        }

  @doc """
  Construct a new validated `ToolConfig`.

  Accepts a map or keyword list with:
  - `:mode` (required): one of `:auto | :any | :none`
  - `:function_names` (optional): list of strings, defaults to `[]`

  Returns `{:ok, %ToolConfig{}}` on success or `{:error, reason}`.
  """
  @spec new(map() | keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = normalize_attrs(attrs, [:mode, :function_names])

    with {:ok, mode} <- require_mode(attrs),
         {:ok, function_names} <- optional_string_list(attrs, :function_names, []) do
      {:ok,
       %__MODULE__{
         mode: mode,
         function_names: function_names
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # -- Validation helpers ----------------------------------------------------

  @valid_modes [:auto, :any, :none]

  @spec require_mode(map()) :: {:ok, mode()} | {:error, String.t()}
  defp require_mode(attrs) do
    case Map.fetch(attrs, :mode) do
      {:ok, value} when value in @valid_modes -> {:ok, value}
      {:ok, _} -> {:error, "mode must be one of :auto | :any | :none"}
      :error -> {:error, "missing required mode"}
    end
  end

  @spec optional_string_list(map(), atom(), [String.t()]) :: {:ok, [String.t()]} | {:error, String.t()}
  defp optional_string_list(attrs, key, default) do
    case Map.fetch(attrs, key) do
      {:ok, value} when is_list(value) -> if Enum.all?(value, &is_binary/1), do: {:ok, value}, else: {:error, "#{key} must be a list of strings"}
      {:ok, _} -> {:error, "#{key} must be a list of strings"}
      :error -> {:ok, default}
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
    for key <- allowed_keys, reduce: %{} do
      acc ->
        value = Map.get(attrs, key)
        value = if value == nil, do: Map.get(attrs, Atom.to_string(key)), else: value
        if value == nil, do: acc, else: Map.put(acc, key, value)
    end
  end
end
