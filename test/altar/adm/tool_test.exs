defmodule Altar.ADM.ToolTest do
  use ExUnit.Case, async: true

  alias Altar.ADM.{Tool, FunctionDeclaration}

  doctest Tool

  describe "new/1 - basic creation" do
    test "creates tool with single function declaration" do
      {:ok, decl} =
        FunctionDeclaration.new(%{
          name: "get_weather",
          description: "Get current weather",
          parameters: %{}
        })

      assert {:ok, tool} = Tool.new(%{function_declarations: [decl]})
      assert length(tool.function_declarations) == 1
      assert hd(tool.function_declarations).name == "get_weather"
    end

    test "creates tool with multiple function declarations" do
      {:ok, decl1} = FunctionDeclaration.new(%{name: "add", description: "Add", parameters: %{}})
      {:ok, decl2} = FunctionDeclaration.new(%{name: "sub", description: "Sub", parameters: %{}})

      assert {:ok, tool} = Tool.new(%{function_declarations: [decl1, decl2]})
      assert length(tool.function_declarations) == 2
    end

    test "creates tool from raw maps" do
      assert {:ok, tool} =
               Tool.new(%{
                 function_declarations: [
                   %{name: "func1", description: "First function", parameters: %{}},
                   %{name: "func2", description: "Second function", parameters: %{}}
                 ]
               })

      assert length(tool.function_declarations) == 2
      assert hd(tool.function_declarations).name == "func1"
    end

    test "requires function_declarations field" do
      assert {:error, error} = Tool.new(%{})
      assert error =~ "missing or invalid function_declarations"
    end

    test "rejects empty function_declarations array" do
      assert {:error, error} = Tool.new(%{function_declarations: []})
      assert error =~ "function_declarations cannot be empty"
    end

    test "rejects non-array function_declarations" do
      assert {:error, error} = Tool.new(%{function_declarations: "not an array"})
      assert error =~ "missing or invalid function_declarations"
    end
  end

  describe "new/1 - validation" do
    test "validates all function declarations" do
      # Invalid declaration (missing name)
      assert {:error, error} =
               Tool.new(%{
                 function_declarations: [
                   %{description: "No name", parameters: %{}}
                 ]
               })

      assert error =~ "invalid function declaration"
    end

    test "enforces unique function names" do
      {:ok, decl1} =
        FunctionDeclaration.new(%{name: "test", description: "First", parameters: %{}})

      {:ok, decl2} =
        FunctionDeclaration.new(%{name: "test", description: "Second", parameters: %{}})

      assert {:error, error} = Tool.new(%{function_declarations: [decl1, decl2]})
      assert error =~ "duplicate function names"
      assert error =~ "test"
    end

    test "allows different function names" do
      {:ok, decl1} =
        FunctionDeclaration.new(%{name: "func1", description: "First", parameters: %{}})

      {:ok, decl2} =
        FunctionDeclaration.new(%{name: "func2", description: "Second", parameters: %{}})

      assert {:ok, _tool} = Tool.new(%{function_declarations: [decl1, decl2]})
    end
  end

  describe "function_names/1" do
    test "returns list of function names" do
      {:ok, tool} =
        Tool.new(%{
          function_declarations: [
            %{name: "add", description: "Add", parameters: %{}},
            %{name: "multiply", description: "Multiply", parameters: %{}}
          ]
        })

      names = Tool.function_names(tool)
      assert names == ["add", "multiply"]
    end

    test "returns empty list for tool with single function" do
      {:ok, tool} =
        Tool.new(%{
          function_declarations: [
            %{name: "single", description: "Single", parameters: %{}}
          ]
        })

      names = Tool.function_names(tool)
      assert names == ["single"]
    end
  end

  describe "find_function/2" do
    setup do
      {:ok, tool} =
        Tool.new(%{
          function_declarations: [
            %{name: "get_weather", description: "Weather", parameters: %{}},
            %{name: "get_time", description: "Time", parameters: %{}}
          ]
        })

      {:ok, tool: tool}
    end

    test "finds existing function by name", %{tool: tool} do
      assert {:ok, decl} = Tool.find_function(tool, "get_weather")
      assert decl.name == "get_weather"
      assert decl.description == "Weather"
    end

    test "returns error for non-existent function", %{tool: tool} do
      assert {:error, :not_found} = Tool.find_function(tool, "nonexistent")
    end

    test "finds second function", %{tool: tool} do
      assert {:ok, decl} = Tool.find_function(tool, "get_time")
      assert decl.name == "get_time"
    end
  end

  describe "to_map/1 and from_map/1 - JSON serialization" do
    test "round-trips simple tool" do
      {:ok, tool} =
        Tool.new(%{
          function_declarations: [
            %{name: "test", description: "Test function", parameters: %{}}
          ]
        })

      map = Tool.to_map(tool)
      assert is_map(map)
      assert map["function_declarations"]
      assert length(map["function_declarations"]) == 1

      {:ok, parsed} = Tool.from_map(map)
      assert length(parsed.function_declarations) == 1
      assert hd(parsed.function_declarations).name == "test"
    end

    test "round-trips tool with multiple functions" do
      {:ok, tool} =
        Tool.new(%{
          function_declarations: [
            %{name: "func1", description: "First", parameters: %{}},
            %{name: "func2", description: "Second", parameters: %{}}
          ]
        })

      map = Tool.to_map(tool)
      {:ok, parsed} = Tool.from_map(map)

      assert length(parsed.function_declarations) == 2
      names = Tool.function_names(parsed)
      assert "func1" in names
      assert "func2" in names
    end

    test "preserves function parameters" do
      {:ok, tool} =
        Tool.new(%{
          function_declarations: [
            %{
              name: "greet",
              description: "Greet user",
              parameters: %{
                "name" => %{"type" => "string"}
              }
            }
          ]
        })

      map = Tool.to_map(tool)
      {:ok, parsed} = Tool.from_map(map)

      decl = hd(parsed.function_declarations)
      assert decl.parameters == %{"name" => %{"type" => "string"}}
    end

    test "from_map validates function declarations" do
      # Invalid: duplicate names
      invalid_map = %{
        "function_declarations" => [
          %{"name" => "test", "description" => "First", "parameters" => %{}},
          %{"name" => "test", "description" => "Second", "parameters" => %{}}
        ]
      }

      assert {:error, error} = Tool.from_map(invalid_map)
      assert error =~ "duplicate function names"
    end

    test "from_map rejects missing function_declarations" do
      assert {:error, error} = Tool.from_map(%{})
      assert error =~ "missing or invalid function_declarations"
    end

    test "from_map rejects invalid function_declarations" do
      assert {:error, error} = Tool.from_map(%{"function_declarations" => "not an array"})
      assert error =~ "missing or invalid function_declarations"
    end
  end

  describe "integration with Jason" do
    test "can encode and decode with Jason" do
      {:ok, tool} =
        Tool.new(%{
          function_declarations: [
            %{name: "test", description: "Test", parameters: %{}}
          ]
        })

      map = Tool.to_map(tool)
      {:ok, json} = Jason.encode(map)
      {:ok, decoded_map} = Jason.decode(json)
      {:ok, parsed_tool} = Tool.from_map(decoded_map)

      assert hd(parsed_tool.function_declarations).name == "test"
    end

    test "pretty prints JSON" do
      {:ok, tool} =
        Tool.new(%{
          function_declarations: [
            %{name: "test", description: "Test function", parameters: %{}}
          ]
        })

      map = Tool.to_map(tool)
      {:ok, json} = Jason.encode(map, pretty: true)

      assert String.contains?(json, "function_declarations")
      assert String.contains?(json, "test")
    end
  end

  describe "edge cases" do
    test "accepts keyword list as input" do
      {:ok, decl} = FunctionDeclaration.new(%{name: "test", description: "Test", parameters: %{}})

      assert {:ok, tool} = Tool.new(function_declarations: [decl])
      assert length(tool.function_declarations) == 1
    end

    test "handles mixed FunctionDeclaration structs and maps" do
      {:ok, decl} =
        FunctionDeclaration.new(%{name: "struct", description: "Struct", parameters: %{}})

      assert {:ok, tool} =
               Tool.new(%{
                 function_declarations: [
                   decl,
                   %{name: "map", description: "Map", parameters: %{}}
                 ]
               })

      assert length(tool.function_declarations) == 2
      names = Tool.function_names(tool)
      assert "struct" in names
      assert "map" in names
    end

    test "preserves order of function declarations" do
      {:ok, tool} =
        Tool.new(%{
          function_declarations: [
            %{name: "first", description: "1", parameters: %{}},
            %{name: "second", description: "2", parameters: %{}},
            %{name: "third", description: "3", parameters: %{}}
          ]
        })

      names = Tool.function_names(tool)
      assert names == ["first", "second", "third"]
    end
  end

  describe "real-world examples" do
    test "creates weather tool with multiple related functions" do
      {:ok, tool} =
        Tool.new(%{
          function_declarations: [
            %{
              name: "get_current_weather",
              description: "Get current weather for a location",
              parameters: %{"location" => "string"}
            },
            %{
              name: "get_weather_forecast",
              description: "Get weather forecast",
              parameters: %{"location" => "string", "days" => "integer"}
            },
            %{
              name: "get_weather_alerts",
              description: "Get weather alerts",
              parameters: %{"location" => "string"}
            }
          ]
        })

      assert length(tool.function_declarations) == 3
      assert {:ok, _} = Tool.find_function(tool, "get_current_weather")
      assert {:ok, _} = Tool.find_function(tool, "get_weather_forecast")
      assert {:ok, _} = Tool.find_function(tool, "get_weather_alerts")
    end

    test "creates calculator tool" do
      {:ok, tool} =
        Tool.new(%{
          function_declarations: [
            %{name: "add", description: "Add two numbers", parameters: %{}},
            %{name: "subtract", description: "Subtract", parameters: %{}},
            %{name: "multiply", description: "Multiply", parameters: %{}},
            %{name: "divide", description: "Divide", parameters: %{}}
          ]
        })

      assert length(tool.function_declarations) == 4
      names = Tool.function_names(tool)
      assert length(names) == 4
    end
  end
end
