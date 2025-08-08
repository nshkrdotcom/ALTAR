defmodule Altar.ADM.ToolResultTest do
  use ExUnit.Case, async: true

  alias Altar.ADM.ToolResult

  describe "new/1" do
    test "creates a standard, non-error result with defaults" do
      assert {:ok, %ToolResult{call_id: "c1", content: nil, is_error: false}} =
               ToolResult.new(%{call_id: "c1"})
    end

    test "creates an explicit non-error result with content" do
      assert {:ok, %ToolResult{call_id: "c1", content: %{value: 3}, is_error: false}} =
               ToolResult.new(%{call_id: "c1", content: %{value: 3}, is_error: false})
    end

    test "creates an explicit error result with error content" do
      assert {:ok, %ToolResult{call_id: "c1", content: %{error: "boom"}, is_error: true}} =
               ToolResult.new(%{call_id: "c1", is_error: true, content: %{error: "boom"}})

      assert {:ok, %ToolResult{call_id: "c1", content: %{"error" => "boom"}, is_error: true}} =
               ToolResult.new(%{call_id: "c1", is_error: true, content: %{"error" => "boom"}})
    end

    test "fails when call_id is missing" do
      assert {:error, "missing required call_id"} = ToolResult.new(%{})
    end

    test "fails when is_error is not a boolean" do
      assert {:error, "is_error must be a boolean"} =
               ToolResult.new(%{call_id: "c1", is_error: 1})

      assert {:error, "is_error must be a boolean"} =
               ToolResult.new(%{call_id: "c1", is_error: "yes"})
    end

    test "fails when is_error is true but content does not include error key" do
      assert {:error, _} = ToolResult.new(%{call_id: "c1", is_error: true, content: :oops})

      assert {:error, _} =
               ToolResult.new(%{call_id: "c1", is_error: true, content: %{reason: "no key"}})

      assert {:error, _} = ToolResult.new(%{call_id: "c1", is_error: true})
    end
  end
end
