defmodule Altar.ADM.ToolConfigTest do
  use ExUnit.Case, async: true

  alias Altar.ADM.ToolConfig

  describe "new/1" do
    test "creates a config for each valid mode" do
      for mode <- [:auto, :any, :none] do
        assert {:ok, %ToolConfig{mode: ^mode, function_names: []}} = ToolConfig.new(%{mode: mode})
      end
    end

    test "creates a config with mode :any and list of function_names" do
      assert {:ok, %ToolConfig{mode: :any, function_names: ["a", "b"]}} =
               ToolConfig.new(%{mode: :any, function_names: ["a", "b"]})
    end

    test "creates a config with omitted function_names (defaults to [])" do
      assert {:ok, %ToolConfig{mode: :auto, function_names: []}} = ToolConfig.new(%{mode: :auto})
    end

    test "fails when mode is missing" do
      assert {:error, "missing required mode"} = ToolConfig.new(%{})
    end

    test "fails when mode is invalid" do
      assert {:error, "mode must be one of :auto | :any | :none"} = ToolConfig.new(%{mode: :all})
      assert {:error, "mode must be one of :auto | :any | :none"} = ToolConfig.new(%{mode: "auto"})
    end

    test "fails when function_names is not a list of strings" do
      assert {:error, "function_names must be a list of strings"} =
               ToolConfig.new(%{mode: :auto, function_names: "not a list"})

      assert {:error, "function_names must be a list of strings"} =
               ToolConfig.new(%{mode: :auto, function_names: ["ok", :not_ok]})
    end
  end
end
