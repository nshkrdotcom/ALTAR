defmodule Altar.ADM.ToolResult do
  @moduledoc """
  ToolResult correlates a `FunctionCall` with its outcome.

  Use `new/1` to construct validated instances. This simple v1 structure records
  whether the result is an error and carries the content payload.
  """

  @enforce_keys [:call_id]
  defstruct call_id: nil,
            content: nil,
            is_error: false

  @typedoc """
  A validated ToolResult.
  """
  @type t :: %__MODULE__{
          call_id: String.t(),
          content: any(),
          is_error: boolean()
        }

  @doc """
  Construct a new validated `ToolResult`.

  Accepts a map or keyword list with:
  - `:call_id` (required): non-empty string; correlates with the triggering call
  - `:content` (optional): any term; if `is_error: true`, should ideally be a map like `%{error: "..."}`
  - `:is_error` (optional): boolean, defaults to `false`

  Returns `{:ok, %ToolResult{}}` on success or `{:error, reason}`.
  """
  @spec new(map() | keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = normalize_attrs(attrs, [:call_id, :content, :is_error])

    with {:ok, call_id} <- require_non_empty_string(attrs, :call_id, "call_id"),
         {:ok, is_error} <- optional_boolean(attrs, :is_error, false, "is_error"),
         {:ok, content} <- optional_any(attrs, :content, nil) do
      case validate_content_for_error(content, is_error) do
        :ok ->
          {:ok,
           %__MODULE__{
             call_id: call_id,
             content: content,
             is_error: is_error
           }}

        {:error, reason} -> {:error, reason}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec validate_content_for_error(any(), boolean()) :: :ok | {:error, String.t()}
  defp validate_content_for_error(content, true) do
    cond do
      is_map(content) and Map.has_key?(content, :error) -> :ok
      is_map(content) and Map.has_key?(content, "error") -> :ok
      true ->
        {:error,
         "for is_error: true, content should include an :error key (e.g., %{error: \"description\"})"}
    end
  end

  defp validate_content_for_error(_content, false), do: :ok

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

  @spec require_non_empty_string(map(), atom(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp require_non_empty_string(attrs, key, label) do
    case Map.fetch(attrs, key) do
      {:ok, value} when is_binary(value) ->
        if String.trim(value) == "" do
          {:error, "#{label} cannot be empty"}
        else
          {:ok, value}
        end

      {:ok, _} -> {:error, "#{label} must be a string"}
      :error -> {:error, "missing required #{label}"}
    end
  end

  @spec optional_boolean(map(), atom(), boolean(), String.t()) :: {:ok, boolean()} | {:error, String.t()}
  defp optional_boolean(attrs, key, default, label) do
    case Map.fetch(attrs, key) do
      {:ok, value} when is_boolean(value) -> {:ok, value}
      {:ok, _} -> {:error, "#{label} must be a boolean"}
      :error -> {:ok, default}
    end
  end

  @spec optional_any(map(), atom(), any()) :: {:ok, any()}
  defp optional_any(attrs, key, default) do
    case Map.fetch(attrs, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:ok, default}
    end
  end
end
