defmodule Altar.LATER.RegistryTest do
  use ExUnit.Case, async: true

  alias Altar.ADM
  alias Altar.ADM.FunctionDeclaration
  alias Altar.LATER.Registry

  setup do
    registry = start_supervised!(Registry)
    %{registry: registry}
  end

  describe "register_tool/3" do
    test "successfully registers a valid tool", %{registry: registry} do
      {:ok, %FunctionDeclaration{} = decl} =
        ADM.new_function_declaration(%{name: "sum", description: "sum two numbers"})

      assert :ok = Registry.register_tool(registry, decl, fn %{"a" => a, "b" => b} -> a + b end)
    end

    test "fails when registering a duplicate tool name", %{registry: registry} do
      {:ok, %FunctionDeclaration{} = decl} =
        ADM.new_function_declaration(%{name: "dup", description: "duplicate"})

      assert :ok = Registry.register_tool(registry, decl, fn _ -> :ok end)

      assert {:error, :already_registered} =
               Registry.register_tool(registry, decl, fn _ -> :ok end)
    end

    test "fails when function does not have arity 1", %{registry: registry} do
      {:ok, %FunctionDeclaration{} = decl} =
        ADM.new_function_declaration(%{name: "bad_arity", description: "invalid arity"})

      assert {:error, :invalid_function_arity} =
               Registry.register_tool(registry, decl, fn -> :ok end)

      assert {:error, :invalid_function_arity} =
               Registry.register_tool(registry, decl, fn _a, _b -> :ok end)
    end
  end

  describe "lookup_tool/2" do
    test "successfully looks up a registered tool", %{registry: registry} do
      {:ok, %FunctionDeclaration{} = decl} =
        ADM.new_function_declaration(%{name: "echo", description: "echo"})

      fun = fn args -> args end
      :ok = Registry.register_tool(registry, decl, fun)

      assert {:ok, returned_fun} = Registry.lookup_tool(registry, "echo")
      assert is_function(returned_fun, 1)
      assert returned_fun.(%{"a" => 1}) == %{"a" => 1}
    end

    test "returns not_found for unknown tool", %{registry: registry} do
      assert {:error, :not_found} = Registry.lookup_tool(registry, "missing")
    end
  end
end
