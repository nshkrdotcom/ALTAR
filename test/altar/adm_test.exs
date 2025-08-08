defmodule Altar.ADMTest do
  use ExUnit.Case, async: true

  alias Altar.ADM
  alias Altar.ADM.{FunctionCall, FunctionDeclaration, ToolResult, ToolConfig}

  describe "facade functions" do
    test "new_function_call/1 passes through success from FunctionCall.new/1" do
      attrs = %{call_id: "c1", name: "sum", args: %{a: 1}}
      assert {:ok, %FunctionCall{}} = ADM.new_function_call(attrs)
    end

    test "new_function_call/1 passes through error from FunctionCall.new/1" do
      assert {:error, "missing required name"} = ADM.new_function_call(%{call_id: "c1"})
    end

    test "new_function_declaration/1 passes through success and error" do
      assert {:ok, %FunctionDeclaration{}} =
               ADM.new_function_declaration(%{name: "echo", description: "desc"})

      assert {:error, _} = ADM.new_function_declaration(%{description: "desc"})
    end

    test "new_tool_result/1 passes through success and error" do
      assert {:ok, %ToolResult{}} = ADM.new_tool_result(%{call_id: "c1"})
      assert {:error, _} = ADM.new_tool_result(%{})
    end

    test "new_tool_config/1 passes through success and error" do
      assert {:ok, %ToolConfig{}} = ADM.new_tool_config(%{mode: :auto})
      assert {:error, _} = ADM.new_tool_config(%{})
    end
  end
end
