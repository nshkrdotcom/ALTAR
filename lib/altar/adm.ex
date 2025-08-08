defmodule Altar.ADM do
  @moduledoc """
  ALTAR Data Model (ADM) – the universal contract layer for tools.

  This namespace provides foundational, validated data structures shared by the
  LATER (local) and GRID (distributed) protocols. Construct values via the
  validating constructors exposed both on each struct module and as ergonomic
  pass-through helpers here.
  """

  alias Altar.ADM.{FunctionDeclaration, FunctionCall, ToolResult, ToolConfig}

  @doc """
  Create a new `FunctionDeclaration` via validated constructor.
  """
  @spec new_function_declaration(map() | keyword()) :: {:ok, FunctionDeclaration.t()} | {:error, String.t()}
  def new_function_declaration(attrs), do: FunctionDeclaration.new(attrs)

  @doc """
  Create a new `FunctionCall` via validated constructor.
  """
  @spec new_function_call(map() | keyword()) :: {:ok, FunctionCall.t()} | {:error, String.t()}
  def new_function_call(attrs), do: FunctionCall.new(attrs)

  @doc """
  Create a new `ToolResult` via validated constructor.
  """
  @spec new_tool_result(map() | keyword()) :: {:ok, ToolResult.t()} | {:error, String.t()}
  def new_tool_result(attrs), do: ToolResult.new(attrs)

  @doc """
  Create a new `ToolConfig` via validated constructor.
  """
  @spec new_tool_config(map() | keyword()) :: {:ok, ToolConfig.t()} | {:error, String.t()}
  def new_tool_config(attrs), do: ToolConfig.new(attrs)
end
