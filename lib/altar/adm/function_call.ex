defmodule Altar.ADM.FunctionCall do
  @moduledoc """
  FunctionCall represents a request to invoke a function by name with arguments.

  Use `new/1` to construct validated instances.
  """

  @enforce_keys [:call_id, :name]
  defstruct call_id: nil,
            name: nil,
            args: %{}

  @typedoc """
  A validated FunctionCall.
  """
  @type t :: %__MODULE__{
          call_id: String.t(),
          name: String.t(),
          args: map()
        }

  @doc """
  Construct a new validated `FunctionCall`.

  Accepts a map or keyword list with:
  - `:call_id` (required): non-empty string
  - `:name` (required): non-empty string
  - `:args` (optional): map(), defaults to `%{}`

  Returns `{:ok, %FunctionCall{}}` on success or `{:error, reason}`.
  """
  @spec new(map() | keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = normalize_attrs(attrs, [:call_id, :name, :args])

    with {:ok, call_id} <- require_non_empty_string(attrs, :call_id, "call_id"),
         {:ok, name} <- require_non_empty_string(attrs, :name, "name"),
         {:ok, args} <- optional_map(attrs, :args, %{}, "args") do
      {:ok,
       %__MODULE__{
         call_id: call_id,
         name: name,
         args: args
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # -- Attribute helpers -----------------------------------------------------

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

  @spec require_non_empty_string(map(), atom(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  defp require_non_empty_string(attrs, key, label) do
    case Map.fetch(attrs, key) do
      {:ok, value} when is_binary(value) ->
        if String.trim(value) == "" do
          {:error, "#{label} cannot be empty"}
        else
          {:ok, value}
        end

      {:ok, _} ->
        {:error, "#{label} must be a string"}

      :error ->
        {:error, "missing required #{label}"}
    end
  end

  @spec optional_map(map(), atom(), map(), String.t()) :: {:ok, map()} | {:error, String.t()}
  defp optional_map(attrs, key, default, label) do
    case Map.fetch(attrs, key) do
      {:ok, value} when is_map(value) -> {:ok, value}
      {:ok, _} -> {:error, "#{label} must be a map"}
      :error -> {:ok, default}
    end
  end
end
