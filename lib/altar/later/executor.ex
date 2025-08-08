defmodule Altar.LATER.Executor do
  @moduledoc """
  Stateless tool execution for the Local Agent & Tool Execution Runtime (LATER).

  This module provides a pure, stateless API to execute a registered tool using
  a validated `Altar.ADM.FunctionCall`. It looks up the tool in the
  `Altar.LATER.Registry`, invokes the implementation with the provided args, and
  returns an `Altar.ADM.ToolResult` via the validating constructor.
  """

  alias Altar.ADM
  alias Altar.ADM.{FunctionCall, ToolResult}
  alias Altar.LATER.Registry

  @doc """
  Execute a tool call against the given registry.

  The function is pure with respect to input arguments: it looks up the
  implementation function via the supplied registry pid/name and
  deterministically constructs a `ToolResult` based on the outcome of executing
  that function with `function_call.args`.

  - If the tool is found and executes without raising, returns
    `{:ok, %ToolResult{is_error: false, content: result}}`.
  - If the tool raises, returns `{:ok, %ToolResult{is_error: true, content: %{error: ...}}}`.
  - If the tool is not found, returns `{:ok, %ToolResult{is_error: true, content: %{error: ...}}}`.
  """
  @spec execute_tool(GenServer.server(), FunctionCall.t()) :: {:ok, ToolResult.t()}
  def execute_tool(registry, %FunctionCall{call_id: call_id, name: function_name, args: args}) do
    case Registry.lookup_tool(registry, function_name) do
      {:ok, fun} ->
        result_tuple = try_execute(fun, args)
        build_tool_result(call_id, result_tuple)

      {:error, :not_found} ->
        {:ok, error_result!(call_id, "tool not found: #{function_name}")}
    end
  end

  # -- Internal helpers -------------------------------------------------------

  @spec try_execute((map() -> any()), map()) :: {:ok, any()} | {:error, Exception.t(), list()}
  defp try_execute(fun, args) when is_function(fun, 1) and is_map(args) do
    try do
      {:ok, fun.(args)}
    rescue
      exception -> {:error, exception, __STACKTRACE__}
    end
  end

  @spec build_tool_result(String.t(), {:ok, any()} | {:error, Exception.t(), list()}) ::
          {:ok, ToolResult.t()}
  defp build_tool_result(call_id, {:ok, value}) do
    {:ok, tool_result} = ADM.new_tool_result(%{call_id: call_id, content: value, is_error: false})
    {:ok, tool_result}
  end

  defp build_tool_result(call_id, {:error, exception, _stacktrace}) do
    message = Exception.message(exception)
    {:ok, error_result!(call_id, "execution failed: #{message}")}
  end

  @spec error_result!(String.t(), String.t()) :: ToolResult.t()
  defp error_result!(call_id, message) when is_binary(call_id) and is_binary(message) do
    {:ok, tool_result} =
      ADM.new_tool_result(%{call_id: call_id, is_error: true, content: %{error: message}})

    tool_result
  end
end
