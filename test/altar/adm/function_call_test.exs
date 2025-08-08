defmodule Altar.ADM.FunctionCallTest do
  use ExUnit.Case, async: true

  alias Altar.ADM.FunctionCall

  describe "new/1" do
    test "creates a valid call with all keys" do
      attrs = %{call_id: "c1", name: "sum", args: %{a: 1, b: 2}}
      assert {:ok, %FunctionCall{call_id: "c1", name: "sum", args: %{a: 1, b: 2}}} = FunctionCall.new(attrs)
    end

    test "creates a valid call with omitted args (defaults to %{})" do
      attrs = %{call_id: "c2", name: "echo"}
      assert {:ok, %FunctionCall{call_id: "c2", name: "echo", args: %{} = args}} = FunctionCall.new(attrs)
      assert args == %{}
    end

    test "fails when call_id is missing" do
      assert {:error, "missing required call_id"} = FunctionCall.new(%{name: "sum"})
    end

    test "fails when name is missing" do
      assert {:error, "missing required name"} = FunctionCall.new(%{call_id: "c1"})
    end

    test "fails when call_id is an empty string" do
      assert {:error, "call_id cannot be empty"} = FunctionCall.new(%{call_id: "   ", name: "sum"})
    end

    test "fails when name is an empty string" do
      assert {:error, "name cannot be empty"} = FunctionCall.new(%{call_id: "c1", name: "  "})
    end

    test "fails when args is not a map" do
      assert {:error, "args must be a map"} = FunctionCall.new(%{call_id: "c1", name: "sum", args: [a: 1]})
    end
  end
end
