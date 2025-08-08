defmodule Altar.LATER.ExecutorTest do
  use ExUnit.Case, async: true

  alias Altar.ADM
  alias Altar.ADM.{FunctionCall, FunctionDeclaration, ToolResult}
  alias Altar.LATER.{Registry, Executor}

  # Simple tool functions used in tests
  def sum_tool(%{"a" => a, "b" => b}), do: a + b
  def error_tool(_), do: raise("kaboom!")

  setup do
    registry = start_supervised!(Registry)

    {:ok, %FunctionDeclaration{} = sum_decl} =
      ADM.new_function_declaration(%{name: "sum", description: "sum"})

    {:ok, %FunctionDeclaration{} = err_decl} =
      ADM.new_function_declaration(%{name: "explode", description: "boom"})

    :ok = Registry.register_tool(registry, sum_decl, &__MODULE__.sum_tool/1)
    :ok = Registry.register_tool(registry, err_decl, &__MODULE__.error_tool/1)

    %{registry: registry}
  end

  describe "execute_tool/2" do
    test "executes a registered tool successfully and returns non-error result", %{
      registry: registry
    } do
      {:ok, %FunctionCall{} = call} =
        ADM.new_function_call(%{call_id: "c1", name: "sum", args: %{"a" => 2, "b" => 3}})

      assert {:ok, %ToolResult{is_error: false, content: 5}} =
               Executor.execute_tool(registry, call)
    end

    test "returns error result when tool is not found", %{registry: registry} do
      {:ok, %FunctionCall{} = call} =
        ADM.new_function_call(%{call_id: "c2", name: "missing", args: %{}})

      assert {:ok, %ToolResult{is_error: true, content: %{error: message}}} =
               Executor.execute_tool(registry, call)

      assert message == "tool not found: missing"
    end

    test "returns error result when tool execution raises", %{registry: registry} do
      {:ok, %FunctionCall{} = call} =
        ADM.new_function_call(%{call_id: "c3", name: "explode", args: %{}})

      assert {:ok, %ToolResult{is_error: true, content: %{error: message}}} =
               Executor.execute_tool(registry, call)

      assert message == "execution failed: kaboom!"
    end
  end
end
