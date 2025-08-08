defmodule Altar.ADM.FunctionDeclarationTest do
  use ExUnit.Case, async: true

  alias Altar.ADM.FunctionDeclaration

  describe "new/1" do
    test "creates a valid declaration with all keys" do
      attrs = %{name: "sum_numbers", description: "Adds numbers", parameters: %{type: "object"}}

      assert {:ok,
              %FunctionDeclaration{
                name: "sum_numbers",
                description: "Adds numbers",
                parameters: %{type: "object"}
              }} =
               FunctionDeclaration.new(attrs)
    end

    test "creates a valid declaration with omitted parameters (defaults to %{})" do
      attrs = %{name: "echo", description: "Echoes input"}

      assert {:ok,
              %FunctionDeclaration{
                name: "echo",
                description: "Echoes input",
                parameters: %{} = params
              }} =
               FunctionDeclaration.new(attrs)

      assert params == %{}
    end

    test "fails when name is missing" do
      assert {:error, "missing required name"} =
               FunctionDeclaration.new(%{description: "Adds numbers"})
    end

    test "fails when description is missing" do
      assert {:error, "missing required description"} = FunctionDeclaration.new(%{name: "sum"})
    end

    test "fails when name is an empty string" do
      assert {:error, _} = FunctionDeclaration.new(%{name: "", description: "Adds numbers"})
    end

    test "fails when name contains invalid characters" do
      # spaces / special symbols not allowed by ~r/^[a-zA-Z0-9_-]{1,64}$/
      for bad <- ["sum numbers", "sum!", "white space", "has.dot"] do
        assert {:error,
                "invalid name: must match ~r/^[a-zA-Z0-9_-]{1,64}$/ (alphanumeric, underscore, dash; max 64)"} =
                 FunctionDeclaration.new(%{name: bad, description: "desc"})
      end
    end

    test "fails when name is too long (65 characters)" do
      long = String.duplicate("a", 65)

      assert {:error,
              "invalid name: must match ~r/^[a-zA-Z0-9_-]{1,64}$/ (alphanumeric, underscore, dash; max 64)"} =
               FunctionDeclaration.new(%{name: long, description: "desc"})
    end

    test "fails when description is an empty string" do
      assert {:error, "description cannot be empty"} =
               FunctionDeclaration.new(%{name: "sum", description: "   "})
    end

    test "fails when parameters is not a map" do
      assert {:error, "parameters must be a map"} =
               FunctionDeclaration.new(%{name: "sum", description: "Adds", parameters: [a: 1]})
    end

    test "fails when input is not a map or keyword list" do
      assert_raise FunctionClauseError, fn -> FunctionDeclaration.new("not a map") end
      assert_raise FunctionClauseError, fn -> FunctionDeclaration.new(123) end
    end
  end
end
