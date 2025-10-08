defmodule Altar.ADM.ToolManifestTest do
  use ExUnit.Case, async: true

  alias Altar.ADM.{ToolManifest, Tool}

  doctest ToolManifest

  describe "new/1 - basic creation" do
    test "creates minimal manifest with empty tools" do
      assert {:ok, manifest} = ToolManifest.new(%{version: "1.0.0", tools: []})
      assert manifest.version == "1.0.0"
      assert manifest.tools == []
      assert manifest.metadata == nil
    end

    test "creates manifest with single tool" do
      {:ok, tool} =
        Tool.new(%{
          function_declarations: [
            %{name: "test", description: "Test", parameters: %{}}
          ]
        })

      assert {:ok, manifest} = ToolManifest.new(%{version: "1.0.0", tools: [tool]})
      assert length(manifest.tools) == 1
    end

    test "creates manifest with multiple tools" do
      {:ok, tool1} =
        Tool.new(%{
          function_declarations: [%{name: "func1", description: "F1", parameters: %{}}]
        })

      {:ok, tool2} =
        Tool.new(%{
          function_declarations: [%{name: "func2", description: "F2", parameters: %{}}]
        })

      assert {:ok, manifest} = ToolManifest.new(%{version: "1.0.0", tools: [tool1, tool2]})
      assert length(manifest.tools) == 2
    end

    test "creates manifest with metadata" do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "1.0.0",
          tools: [],
          metadata: %{
            "environment" => "production",
            "deployed_at" => "2025-10-07T12:00:00Z"
          }
        })

      assert manifest.metadata["environment"] == "production"
      assert manifest.metadata["deployed_at"] == "2025-10-07T12:00:00Z"
    end

    test "requires version field" do
      assert {:error, error} = ToolManifest.new(%{tools: []})
      assert error =~ "missing or invalid version"
    end

    test "requires tools field" do
      assert {:error, error} = ToolManifest.new(%{version: "1.0.0"})
      assert error =~ "missing or invalid tools"
    end
  end

  describe "new/1 - version validation" do
    test "accepts valid semantic version" do
      assert {:ok, _} = ToolManifest.new(%{version: "1.0.0", tools: []})
      assert {:ok, _} = ToolManifest.new(%{version: "2.1.3", tools: []})
      assert {:ok, _} = ToolManifest.new(%{version: "10.20.30", tools: []})
    end

    test "accepts semantic version with pre-release" do
      assert {:ok, _} = ToolManifest.new(%{version: "1.0.0-alpha", tools: []})
      assert {:ok, _} = ToolManifest.new(%{version: "1.0.0-beta.1", tools: []})
    end

    test "accepts semantic version with build metadata" do
      assert {:ok, _} = ToolManifest.new(%{version: "1.0.0+20130313144700", tools: []})
      assert {:ok, _} = ToolManifest.new(%{version: "1.0.0-beta+exp.sha.5114f85", tools: []})
    end

    test "rejects invalid version format" do
      assert {:error, error} = ToolManifest.new(%{version: "1.0", tools: []})
      assert error =~ "version must be valid semantic version"

      assert {:error, error} = ToolManifest.new(%{version: "v1.0.0", tools: []})
      assert error =~ "version must be valid semantic version"

      assert {:error, error} = ToolManifest.new(%{version: "abc", tools: []})
      assert error =~ "version must be valid semantic version"
    end

    test "rejects non-string version" do
      assert {:error, error} = ToolManifest.new(%{version: 1.0, tools: []})
      assert error =~ "missing or invalid version"
    end
  end

  describe "new/1 - tool validation" do
    test "creates manifest from Tool structs" do
      {:ok, tool} =
        Tool.new(%{
          function_declarations: [%{name: "test", description: "Test", parameters: %{}}]
        })

      assert {:ok, manifest} = ToolManifest.new(%{version: "1.0.0", tools: [tool]})
      assert length(manifest.tools) == 1
    end

    test "creates manifest from raw maps" do
      assert {:ok, manifest} =
               ToolManifest.new(%{
                 version: "1.0.0",
                 tools: [
                   %{
                     function_declarations: [
                       %{name: "test", description: "Test", parameters: %{}}
                     ]
                   }
                 ]
               })

      assert length(manifest.tools) == 1
    end

    test "validates all tools" do
      # Invalid tool (empty function_declarations)
      assert {:error, error} =
               ToolManifest.new(%{
                 version: "1.0.0",
                 tools: [
                   %{function_declarations: []}
                 ]
               })

      assert error =~ "invalid tool"
    end

    test "rejects non-array tools" do
      assert {:error, error} = ToolManifest.new(%{version: "1.0.0", tools: "not an array"})
      assert error =~ "missing or invalid tools"
    end
  end

  describe "new/1 - global unique names validation" do
    test "enforces unique function names across all tools" do
      {:ok, tool1} =
        Tool.new(%{
          function_declarations: [%{name: "duplicate", description: "Tool 1", parameters: %{}}]
        })

      {:ok, tool2} =
        Tool.new(%{
          function_declarations: [%{name: "duplicate", description: "Tool 2", parameters: %{}}]
        })

      assert {:error, error} = ToolManifest.new(%{version: "1.0.0", tools: [tool1, tool2]})
      assert error =~ "duplicate function names across tools"
      assert error =~ "duplicate"
    end

    test "allows same function name in single tool (already caught by Tool)" do
      # This should be caught by Tool.new validation
      assert {:error, error} =
               ToolManifest.new(%{
                 version: "1.0.0",
                 tools: [
                   %{
                     function_declarations: [
                       %{name: "test", description: "First", parameters: %{}},
                       %{name: "test", description: "Second", parameters: %{}}
                     ]
                   }
                 ]
               })

      assert error =~ "duplicate function names"
    end

    test "allows different function names across tools" do
      {:ok, tool1} =
        Tool.new(%{
          function_declarations: [%{name: "func1", description: "Tool 1", parameters: %{}}]
        })

      {:ok, tool2} =
        Tool.new(%{
          function_declarations: [%{name: "func2", description: "Tool 2", parameters: %{}}]
        })

      assert {:ok, manifest} = ToolManifest.new(%{version: "1.0.0", tools: [tool1, tool2]})
      assert length(manifest.tools) == 2
    end
  end

  describe "new/1 - metadata validation" do
    test "accepts valid metadata map" do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "1.0.0",
          tools: [],
          metadata: %{"key" => "value"}
        })

      assert manifest.metadata == %{"key" => "value"}
    end

    test "rejects non-map metadata" do
      assert {:error, error} =
               ToolManifest.new(%{version: "1.0.0", tools: [], metadata: "string"})

      assert error =~ "metadata must be a map"
    end

    test "allows nil metadata (omitted)" do
      {:ok, manifest} = ToolManifest.new(%{version: "1.0.0", tools: []})
      assert manifest.metadata == nil
    end
  end

  describe "all_function_names/1" do
    test "returns empty list for manifest with no tools" do
      {:ok, manifest} = ToolManifest.new(%{version: "1.0.0", tools: []})
      assert ToolManifest.all_function_names(manifest) == []
    end

    test "returns function names from single tool" do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "1.0.0",
          tools: [
            %{
              function_declarations: [
                %{name: "func1", description: "F1", parameters: %{}},
                %{name: "func2", description: "F2", parameters: %{}}
              ]
            }
          ]
        })

      names = ToolManifest.all_function_names(manifest)
      assert length(names) == 2
      assert "func1" in names
      assert "func2" in names
    end

    test "returns sorted function names from multiple tools" do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "1.0.0",
          tools: [
            %{function_declarations: [%{name: "zebra", description: "Z", parameters: %{}}]},
            %{function_declarations: [%{name: "alpha", description: "A", parameters: %{}}]},
            %{function_declarations: [%{name: "beta", description: "B", parameters: %{}}]}
          ]
        })

      names = ToolManifest.all_function_names(manifest)
      assert names == ["alpha", "beta", "zebra"]
    end
  end

  describe "find_function/2" do
    setup do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "1.0.0",
          tools: [
            %{
              function_declarations: [
                %{name: "tool1_func", description: "Tool 1 Function", parameters: %{}}
              ]
            },
            %{
              function_declarations: [
                %{name: "tool2_func", description: "Tool 2 Function", parameters: %{}}
              ]
            }
          ]
        })

      {:ok, manifest: manifest}
    end

    test "finds function in first tool", %{manifest: manifest} do
      assert {:ok, {0, decl}} = ToolManifest.find_function(manifest, "tool1_func")
      assert decl.name == "tool1_func"
      assert decl.description == "Tool 1 Function"
    end

    test "finds function in second tool", %{manifest: manifest} do
      assert {:ok, {1, decl}} = ToolManifest.find_function(manifest, "tool2_func")
      assert decl.name == "tool2_func"
      assert decl.description == "Tool 2 Function"
    end

    test "returns error for non-existent function", %{manifest: manifest} do
      assert {:error, :not_found} = ToolManifest.find_function(manifest, "nonexistent")
    end
  end

  describe "has_function?/2" do
    setup do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "1.0.0",
          tools: [
            %{function_declarations: [%{name: "exists", description: "E", parameters: %{}}]}
          ]
        })

      {:ok, manifest: manifest}
    end

    test "returns true for existing function", %{manifest: manifest} do
      assert ToolManifest.has_function?(manifest, "exists")
    end

    test "returns false for non-existent function", %{manifest: manifest} do
      refute ToolManifest.has_function?(manifest, "nonexistent")
    end
  end

  describe "tool_count/1 and function_count/1" do
    test "returns zero for empty manifest" do
      {:ok, manifest} = ToolManifest.new(%{version: "1.0.0", tools: []})
      assert ToolManifest.tool_count(manifest) == 0
      assert ToolManifest.function_count(manifest) == 0
    end

    test "returns correct counts for single tool" do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "1.0.0",
          tools: [
            %{
              function_declarations: [
                %{name: "f1", description: "F1", parameters: %{}},
                %{name: "f2", description: "F2", parameters: %{}}
              ]
            }
          ]
        })

      assert ToolManifest.tool_count(manifest) == 1
      assert ToolManifest.function_count(manifest) == 2
    end

    test "returns correct counts for multiple tools" do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "1.0.0",
          tools: [
            %{function_declarations: [%{name: "f1", description: "F1", parameters: %{}}]},
            %{
              function_declarations: [
                %{name: "f2", description: "F2", parameters: %{}},
                %{name: "f3", description: "F3", parameters: %{}}
              ]
            },
            %{function_declarations: [%{name: "f4", description: "F4", parameters: %{}}]}
          ]
        })

      assert ToolManifest.tool_count(manifest) == 3
      assert ToolManifest.function_count(manifest) == 4
    end
  end

  describe "to_map/1 and from_map/1 - JSON serialization" do
    test "round-trips minimal manifest" do
      {:ok, manifest} = ToolManifest.new(%{version: "1.0.0", tools: []})

      map = ToolManifest.to_map(manifest)
      assert map["version"] == "1.0.0"
      assert map["tools"] == []
      refute Map.has_key?(map, "metadata")

      {:ok, parsed} = ToolManifest.from_map(map)
      assert parsed.version == "1.0.0"
      assert parsed.tools == []
      assert parsed.metadata == nil
    end

    test "round-trips manifest with tools" do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "2.1.0",
          tools: [
            %{function_declarations: [%{name: "test", description: "Test", parameters: %{}}]}
          ]
        })

      map = ToolManifest.to_map(manifest)
      {:ok, parsed} = ToolManifest.from_map(map)

      assert parsed.version == "2.1.0"
      assert length(parsed.tools) == 1
      assert hd(ToolManifest.all_function_names(parsed)) == "test"
    end

    test "round-trips manifest with metadata" do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "1.0.0",
          tools: [],
          metadata: %{
            "environment" => "staging",
            "region" => "us-west-2",
            "commit" => "abc123"
          }
        })

      map = ToolManifest.to_map(manifest)
      {:ok, parsed} = ToolManifest.from_map(map)

      assert parsed.metadata["environment"] == "staging"
      assert parsed.metadata["region"] == "us-west-2"
      assert parsed.metadata["commit"] == "abc123"
    end

    test "omits nil metadata in to_map" do
      {:ok, manifest} = ToolManifest.new(%{version: "1.0.0", tools: []})

      map = ToolManifest.to_map(manifest)
      refute Map.has_key?(map, "metadata")
    end

    test "from_map validates version" do
      assert {:error, error} = ToolManifest.from_map(%{"version" => "invalid", "tools" => []})
      assert error =~ "version must be valid semantic version"
    end

    test "from_map validates tools" do
      assert {:error, error} =
               ToolManifest.from_map(%{"version" => "1.0.0", "tools" => "invalid"})

      assert error =~ "missing or invalid tools"
    end

    test "from_map validates global uniqueness" do
      map = %{
        "version" => "1.0.0",
        "tools" => [
          %{
            "function_declarations" => [
              %{"name" => "dup", "description" => "D1", "parameters" => %{}}
            ]
          },
          %{
            "function_declarations" => [
              %{"name" => "dup", "description" => "D2", "parameters" => %{}}
            ]
          }
        ]
      }

      assert {:error, error} = ToolManifest.from_map(map)
      assert error =~ "duplicate function names across tools"
    end
  end

  describe "to_json/1 and from_json/1" do
    test "round-trips manifest through JSON" do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "1.2.3",
          tools: [
            %{function_declarations: [%{name: "func", description: "Function", parameters: %{}}]}
          ],
          metadata: %{"env" => "prod"}
        })

      {:ok, json} = ToolManifest.to_json(manifest)
      assert is_binary(json)
      assert String.contains?(json, "1.2.3")
      assert String.contains?(json, "func")

      {:ok, parsed} = ToolManifest.from_json(json)
      assert parsed.version == "1.2.3"
      assert length(parsed.tools) == 1
      assert parsed.metadata["env"] == "prod"
    end

    test "produces pretty-printed JSON" do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "1.0.0",
          tools: [
            %{function_declarations: [%{name: "test", description: "Test", parameters: %{}}]}
          ]
        })

      {:ok, json} = ToolManifest.to_json(manifest)
      # Pretty-printed JSON should have newlines
      assert String.contains?(json, "\n")
    end

    test "from_json rejects invalid JSON" do
      assert {:error, error} = ToolManifest.from_json("not valid json")
      assert error =~ "JSON decode error"
    end

    test "from_json validates manifest structure" do
      json = ~s({"version": "invalid", "tools": []})
      assert {:error, error} = ToolManifest.from_json(json)
      assert error =~ "version must be valid semantic version"
    end
  end

  describe "edge cases" do
    test "accepts keyword list as input" do
      {:ok, tool} =
        Tool.new(%{
          function_declarations: [%{name: "test", description: "Test", parameters: %{}}]
        })

      assert {:ok, manifest} = ToolManifest.new(version: "1.0.0", tools: [tool])
      assert manifest.version == "1.0.0"
    end

    test "handles complex metadata" do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "1.0.0",
          tools: [],
          metadata: %{
            "nested" => %{
              "deep" => %{
                "value" => 123
              }
            },
            "array" => [1, 2, 3],
            "bool" => true,
            "null" => nil
          }
        })

      assert manifest.metadata["nested"]["deep"]["value"] == 123
      assert manifest.metadata["array"] == [1, 2, 3]
      assert manifest.metadata["bool"] == true
    end
  end

  describe "real-world production manifest" do
    test "creates production-ready manifest" do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "2.1.0",
          tools: [
            %{
              function_declarations: [
                %{
                  name: "get_weather",
                  description: "Get current weather",
                  parameters: %{"location" => "string"}
                },
                %{
                  name: "get_forecast",
                  description: "Get weather forecast",
                  parameters: %{"location" => "string", "days" => "integer"}
                }
              ]
            },
            %{
              function_declarations: [
                %{
                  name: "search_database",
                  description: "Search database",
                  parameters: %{"query" => "string"}
                }
              ]
            }
          ],
          metadata: %{
            "environment" => "production",
            "region" => "us-east-1",
            "deployed_at" => "2025-10-07T12:00:00Z",
            "deployed_by" => "ops-team@example.com",
            "git_commit" => "abc123def456",
            "approver" => "security-team@example.com"
          }
        })

      assert manifest.version == "2.1.0"
      assert ToolManifest.tool_count(manifest) == 2
      assert ToolManifest.function_count(manifest) == 3
      assert length(ToolManifest.all_function_names(manifest)) == 3
      assert manifest.metadata["environment"] == "production"
    end

    test "can save and load manifest file" do
      {:ok, manifest} =
        ToolManifest.new(%{
          version: "1.0.0",
          tools: [
            %{function_declarations: [%{name: "test", description: "Test", parameters: %{}}]}
          ]
        })

      # Simulate file I/O
      {:ok, json} = ToolManifest.to_json(manifest)
      {:ok, loaded} = ToolManifest.from_json(json)

      assert loaded.version == manifest.version
      assert ToolManifest.tool_count(loaded) == ToolManifest.tool_count(manifest)
    end
  end
end
