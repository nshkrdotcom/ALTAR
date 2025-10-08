defmodule Altar.ADM.SchemaTest do
  use ExUnit.Case, async: true

  alias Altar.ADM.Schema

  doctest Schema

  describe "new/1 - basic types" do
    test "creates valid STRING schema" do
      assert {:ok, schema} = Schema.new(%{type: :STRING})
      assert schema.type == :STRING
      assert schema.description == nil
    end

    test "creates valid NUMBER schema" do
      assert {:ok, schema} = Schema.new(%{type: :NUMBER})
      assert schema.type == :NUMBER
    end

    test "creates valid INTEGER schema" do
      assert {:ok, schema} = Schema.new(%{type: :INTEGER})
      assert schema.type == :INTEGER
    end

    test "creates valid BOOLEAN schema" do
      assert {:ok, schema} = Schema.new(%{type: :BOOLEAN})
      assert schema.type == :BOOLEAN
    end

    test "creates valid OBJECT schema" do
      assert {:ok, schema} = Schema.new(%{type: :OBJECT})
      assert schema.type == :OBJECT
    end

    test "creates ARRAY schema with items" do
      assert {:ok, schema} =
               Schema.new(%{
                 type: :ARRAY,
                 items: %{type: :STRING}
               })

      assert schema.type == :ARRAY
      assert schema.items.type == :STRING
    end

    test "requires type field" do
      assert {:error, error} = Schema.new(%{})
      assert error =~ "missing required field: type"
    end

    test "rejects invalid type" do
      assert {:error, error} = Schema.new(%{type: :INVALID})
      assert error =~ "invalid type"
    end
  end

  describe "new/1 - with description" do
    test "accepts string description" do
      assert {:ok, schema} =
               Schema.new(%{
                 type: :STRING,
                 description: "A test string"
               })

      assert schema.description == "A test string"
    end

    test "rejects non-string description" do
      assert {:error, error} = Schema.new(%{type: :STRING, description: 123})
      assert error =~ "description must be a string"
    end
  end

  describe "new/1 - OBJECT type with properties" do
    test "creates OBJECT with nested properties" do
      assert {:ok, schema} =
               Schema.new(%{
                 type: :OBJECT,
                 properties: %{
                   "name" => %{type: :STRING},
                   "age" => %{type: :INTEGER}
                 }
               })

      assert schema.type == :OBJECT
      assert schema.properties["name"].type == :STRING
      assert schema.properties["age"].type == :INTEGER
    end

    test "creates OBJECT with required fields" do
      assert {:ok, schema} =
               Schema.new(%{
                 type: :OBJECT,
                 properties: %{
                   "name" => %{type: :STRING}
                 },
                 required: ["name"]
               })

      assert schema.required == ["name"]
    end

    test "rejects required as non-list" do
      assert {:error, error} =
               Schema.new(%{
                 type: :OBJECT,
                 required: "name"
               })

      assert error =~ "required must be a list"
    end

    test "rejects required with non-strings" do
      assert {:error, error} =
               Schema.new(%{
                 type: :OBJECT,
                 required: [123]
               })

      assert error =~ "required must be a list of strings"
    end

    test "creates deeply nested OBJECT schema" do
      assert {:ok, schema} =
               Schema.new(%{
                 type: :OBJECT,
                 properties: %{
                   "user" => %{
                     type: :OBJECT,
                     properties: %{
                       "profile" => %{
                         type: :OBJECT,
                         properties: %{
                           "email" => %{type: :STRING}
                         }
                       }
                     }
                   }
                 }
               })

      assert schema.type == :OBJECT
      user_schema = schema.properties["user"]
      assert user_schema.type == :OBJECT
      profile_schema = user_schema.properties["profile"]
      assert profile_schema.type == :OBJECT
      assert profile_schema.properties["email"].type == :STRING
    end
  end

  describe "new/1 - ARRAY type" do
    test "requires items schema" do
      assert {:error, error} = Schema.new(%{type: :ARRAY})
      assert error =~ "ARRAY type requires items schema"
    end

    test "creates ARRAY with items schema" do
      assert {:ok, schema} =
               Schema.new(%{
                 type: :ARRAY,
                 items: %{type: :STRING}
               })

      assert schema.items.type == :STRING
    end

    test "creates ARRAY of OBJECTS" do
      assert {:ok, schema} =
               Schema.new(%{
                 type: :ARRAY,
                 items: %{
                   type: :OBJECT,
                   properties: %{
                     "id" => %{type: :INTEGER},
                     "name" => %{type: :STRING}
                   }
                 }
               })

      assert schema.items.type == :OBJECT
      assert schema.items.properties["id"].type == :INTEGER
    end

    test "supports min_items constraint" do
      assert {:ok, schema} =
               Schema.new(%{
                 type: :ARRAY,
                 items: %{type: :STRING},
                 min_items: 1
               })

      assert schema.min_items == 1
    end

    test "supports max_items constraint" do
      assert {:ok, schema} =
               Schema.new(%{
                 type: :ARRAY,
                 items: %{type: :STRING},
                 max_items: 10
               })

      assert schema.max_items == 10
    end
  end

  describe "new/1 - constraints" do
    test "supports enum constraint" do
      assert {:ok, schema} =
               Schema.new(%{
                 type: :STRING,
                 enum: ["red", "green", "blue"]
               })

      assert schema.enum == ["red", "green", "blue"]
    end

    test "supports pattern constraint for STRING" do
      assert {:ok, schema} =
               Schema.new(%{
                 type: :STRING,
                 pattern: "^[a-z]+$"
               })

      assert schema.pattern == "^[a-z]+$"
    end

    test "supports min_length and max_length for STRING" do
      assert {:ok, schema} =
               Schema.new(%{
                 type: :STRING,
                 min_length: 3,
                 max_length: 50
               })

      assert schema.min_length == 3
      assert schema.max_length == 50
    end

    test "supports minimum and maximum for NUMBER" do
      assert {:ok, schema} =
               Schema.new(%{
                 type: :NUMBER,
                 minimum: 0.0,
                 maximum: 100.0
               })

      assert schema.minimum == 0.0
      assert schema.maximum == 100.0
    end

    test "supports format hint" do
      assert {:ok, schema} =
               Schema.new(%{
                 type: :STRING,
                 format: "email"
               })

      assert schema.format == "email"
    end

    test "rejects non-integer for min_items" do
      assert {:error, error} =
               Schema.new(%{
                 type: :ARRAY,
                 items: %{type: :STRING},
                 min_items: "3"
               })

      assert error =~ "min_items must be a non-negative integer"
    end

    test "rejects negative integer for min_items" do
      assert {:error, error} =
               Schema.new(%{
                 type: :ARRAY,
                 items: %{type: :STRING},
                 min_items: -1
               })

      assert error =~ "min_items must be a non-negative integer"
    end
  end

  describe "validate/2 - STRING type" do
    test "validates valid string" do
      {:ok, schema} = Schema.new(%{type: :STRING})
      assert :ok = Schema.validate(schema, "hello")
    end

    test "rejects non-string" do
      {:ok, schema} = Schema.new(%{type: :STRING})
      assert {:error, error} = Schema.validate(schema, 123)
      assert error =~ "expected STRING"
    end

    test "validates min_length" do
      {:ok, schema} = Schema.new(%{type: :STRING, min_length: 3})
      assert :ok = Schema.validate(schema, "hello")
      assert {:error, error} = Schema.validate(schema, "hi")
      assert error =~ "string length must be >= 3"
    end

    test "validates max_length" do
      {:ok, schema} = Schema.new(%{type: :STRING, max_length: 5})
      assert :ok = Schema.validate(schema, "hello")
      assert {:error, error} = Schema.validate(schema, "hello world")
      assert error =~ "string length must be <= 5"
    end

    test "validates pattern" do
      {:ok, schema} = Schema.new(%{type: :STRING, pattern: "^[a-z]+$"})
      assert :ok = Schema.validate(schema, "hello")
      assert {:error, error} = Schema.validate(schema, "Hello123")
      assert error =~ "does not match pattern"
    end

    test "validates enum" do
      {:ok, schema} = Schema.new(%{type: :STRING, enum: ["red", "green", "blue"]})
      assert :ok = Schema.validate(schema, "red")
      assert {:error, error} = Schema.validate(schema, "yellow")
      assert error =~ "must be one of"
    end
  end

  describe "validate/2 - INTEGER type" do
    test "validates valid integer" do
      {:ok, schema} = Schema.new(%{type: :INTEGER})
      assert :ok = Schema.validate(schema, 42)
    end

    test "rejects non-integer" do
      {:ok, schema} = Schema.new(%{type: :INTEGER})
      assert {:error, error} = Schema.validate(schema, "42")
      assert error =~ "expected INTEGER"
    end

    test "rejects float" do
      {:ok, schema} = Schema.new(%{type: :INTEGER})
      assert {:error, error} = Schema.validate(schema, 42.5)
      assert error =~ "expected INTEGER"
    end

    test "validates minimum" do
      {:ok, schema} = Schema.new(%{type: :INTEGER, minimum: 0})
      assert :ok = Schema.validate(schema, 5)
      assert {:error, error} = Schema.validate(schema, -1)
      assert error =~ "value must be >= 0"
    end

    test "validates maximum" do
      {:ok, schema} = Schema.new(%{type: :INTEGER, maximum: 100})
      assert :ok = Schema.validate(schema, 50)
      assert {:error, error} = Schema.validate(schema, 150)
      assert error =~ "value must be <= 100"
    end

    test "validates enum" do
      {:ok, schema} = Schema.new(%{type: :INTEGER, enum: [1, 2, 3]})
      assert :ok = Schema.validate(schema, 2)
      assert {:error, error} = Schema.validate(schema, 5)
      assert error =~ "must be one of"
    end
  end

  describe "validate/2 - NUMBER type" do
    test "validates valid number (float)" do
      {:ok, schema} = Schema.new(%{type: :NUMBER})
      assert :ok = Schema.validate(schema, 42.5)
    end

    test "validates valid number (integer)" do
      {:ok, schema} = Schema.new(%{type: :NUMBER})
      assert :ok = Schema.validate(schema, 42)
    end

    test "rejects non-number" do
      {:ok, schema} = Schema.new(%{type: :NUMBER})
      assert {:error, error} = Schema.validate(schema, "42.5")
      assert error =~ "expected NUMBER"
    end

    test "validates minimum" do
      {:ok, schema} = Schema.new(%{type: :NUMBER, minimum: 0.0})
      assert :ok = Schema.validate(schema, 5.5)
      assert {:error, _} = Schema.validate(schema, -1.0)
    end

    test "validates maximum" do
      {:ok, schema} = Schema.new(%{type: :NUMBER, maximum: 100.0})
      assert :ok = Schema.validate(schema, 50.5)
      assert {:error, _} = Schema.validate(schema, 150.0)
    end
  end

  describe "validate/2 - BOOLEAN type" do
    test "validates true" do
      {:ok, schema} = Schema.new(%{type: :BOOLEAN})
      assert :ok = Schema.validate(schema, true)
    end

    test "validates false" do
      {:ok, schema} = Schema.new(%{type: :BOOLEAN})
      assert :ok = Schema.validate(schema, false)
    end

    test "rejects non-boolean" do
      {:ok, schema} = Schema.new(%{type: :BOOLEAN})
      assert {:error, error} = Schema.validate(schema, "true")
      assert error =~ "expected BOOLEAN"
    end
  end

  describe "validate/2 - OBJECT type" do
    test "validates valid object" do
      {:ok, schema} =
        Schema.new(%{
          type: :OBJECT,
          properties: %{
            "name" => %{type: :STRING},
            "age" => %{type: :INTEGER}
          },
          required: ["name"]
        })

      assert :ok = Schema.validate(schema, %{"name" => "Alice", "age" => 30})
    end

    test "rejects non-map" do
      {:ok, schema} = Schema.new(%{type: :OBJECT})
      assert {:error, error} = Schema.validate(schema, "not a map")
      assert error =~ "expected OBJECT"
    end

    test "validates required properties" do
      {:ok, schema} =
        Schema.new(%{
          type: :OBJECT,
          properties: %{
            "name" => %{type: :STRING}
          },
          required: ["name"]
        })

      assert {:error, error} = Schema.validate(schema, %{})
      assert error =~ "missing required properties"
      assert error =~ "name"
    end

    test "accepts required property with atom key" do
      {:ok, schema} =
        Schema.new(%{
          type: :OBJECT,
          properties: %{
            "name" => %{type: :STRING}
          },
          required: ["name"]
        })

      # Should accept atom keys as well
      assert :ok = Schema.validate(schema, %{name: "Alice"})
    end

    test "validates property types" do
      {:ok, schema} =
        Schema.new(%{
          type: :OBJECT,
          properties: %{
            "age" => %{type: :INTEGER}
          }
        })

      assert :ok = Schema.validate(schema, %{"age" => 30})
      assert {:error, error} = Schema.validate(schema, %{"age" => "thirty"})
      assert error =~ "property age"
    end

    test "allows additional properties" do
      {:ok, schema} =
        Schema.new(%{
          type: :OBJECT,
          properties: %{
            "name" => %{type: :STRING}
          }
        })

      assert :ok = Schema.validate(schema, %{"name" => "Alice", "extra" => "value"})
    end

    test "validates nested objects" do
      {:ok, schema} =
        Schema.new(%{
          type: :OBJECT,
          properties: %{
            "user" => %{
              type: :OBJECT,
              properties: %{
                "email" => %{type: :STRING}
              },
              required: ["email"]
            }
          }
        })

      assert :ok = Schema.validate(schema, %{"user" => %{"email" => "test@example.com"}})
      assert {:error, _} = Schema.validate(schema, %{"user" => %{}})
    end
  end

  describe "validate/2 - ARRAY type" do
    test "validates valid array" do
      {:ok, schema} = Schema.new(%{type: :ARRAY, items: %{type: :STRING}})
      assert :ok = Schema.validate(schema, ["a", "b", "c"])
    end

    test "rejects non-list" do
      {:ok, schema} = Schema.new(%{type: :ARRAY, items: %{type: :STRING}})
      assert {:error, error} = Schema.validate(schema, "not an array")
      assert error =~ "expected ARRAY"
    end

    test "validates item types" do
      {:ok, schema} = Schema.new(%{type: :ARRAY, items: %{type: :STRING}})
      assert {:error, error} = Schema.validate(schema, ["a", 123, "c"])
      assert error =~ "item[1]"
    end

    test "validates min_items" do
      {:ok, schema} = Schema.new(%{type: :ARRAY, items: %{type: :STRING}, min_items: 2})
      assert :ok = Schema.validate(schema, ["a", "b"])
      assert {:error, error} = Schema.validate(schema, ["a"])
      assert error =~ "array length must be >= 2"
    end

    test "validates max_items" do
      {:ok, schema} = Schema.new(%{type: :ARRAY, items: %{type: :STRING}, max_items: 3})
      assert :ok = Schema.validate(schema, ["a", "b", "c"])
      assert {:error, error} = Schema.validate(schema, ["a", "b", "c", "d"])
      assert error =~ "array length must be <= 3"
    end

    test "validates array of objects" do
      {:ok, schema} =
        Schema.new(%{
          type: :ARRAY,
          items: %{
            type: :OBJECT,
            properties: %{
              "id" => %{type: :INTEGER}
            }
          }
        })

      assert :ok = Schema.validate(schema, [%{"id" => 1}, %{"id" => 2}])
      assert {:error, _} = Schema.validate(schema, [%{"id" => "one"}])
    end
  end

  describe "to_map/1 and from_map/1 - JSON serialization" do
    test "round-trips simple STRING schema" do
      {:ok, schema} = Schema.new(%{type: :STRING, description: "Test"})
      map = Schema.to_map(schema)
      assert map["type"] == "STRING"
      assert map["description"] == "Test"

      {:ok, parsed} = Schema.from_map(map)
      assert parsed.type == :STRING
      assert parsed.description == "Test"
    end

    test "round-trips OBJECT schema with properties" do
      {:ok, schema} =
        Schema.new(%{
          type: :OBJECT,
          properties: %{
            "name" => %{type: :STRING},
            "age" => %{type: :INTEGER, minimum: 0}
          },
          required: ["name"]
        })

      map = Schema.to_map(schema)
      {:ok, parsed} = Schema.from_map(map)

      assert parsed.type == :OBJECT
      assert parsed.properties["name"].type == :STRING
      assert parsed.properties["age"].type == :INTEGER
      assert parsed.properties["age"].minimum == 0
      assert parsed.required == ["name"]
    end

    test "round-trips ARRAY schema" do
      {:ok, schema} =
        Schema.new(%{
          type: :ARRAY,
          items: %{type: :STRING, min_length: 1},
          min_items: 1,
          max_items: 10
        })

      map = Schema.to_map(schema)
      {:ok, parsed} = Schema.from_map(map)

      assert parsed.type == :ARRAY
      assert parsed.items.type == :STRING
      assert parsed.items.min_length == 1
      assert parsed.min_items == 1
      assert parsed.max_items == 10
    end

    test "round-trips complex nested schema" do
      {:ok, schema} =
        Schema.new(%{
          type: :OBJECT,
          properties: %{
            "users" => %{
              type: :ARRAY,
              items: %{
                type: :OBJECT,
                properties: %{
                  "name" => %{type: :STRING},
                  "roles" => %{
                    type: :ARRAY,
                    items: %{type: :STRING, enum: ["admin", "user"]}
                  }
                }
              }
            }
          }
        })

      map = Schema.to_map(schema)
      {:ok, parsed} = Schema.from_map(map)

      assert parsed.type == :OBJECT
      users_schema = parsed.properties["users"]
      assert users_schema.type == :ARRAY
      user_schema = users_schema.items
      assert user_schema.type == :OBJECT
      roles_schema = user_schema.properties["roles"]
      assert roles_schema.items.enum == ["admin", "user"]
    end

    test "omits nil fields in to_map" do
      {:ok, schema} = Schema.new(%{type: :STRING})
      map = Schema.to_map(schema)

      # Should only have type, not all the nil fields
      assert Map.has_key?(map, "type")
      refute Map.has_key?(map, "description")
      refute Map.has_key?(map, "minimum")
      refute Map.has_key?(map, "maximum")
    end
  end

  describe "edge cases" do
    test "accepts keyword list as input" do
      assert {:ok, schema} = Schema.new(type: :STRING, description: "Test")
      assert schema.type == :STRING
      assert schema.description == "Test"
    end

    test "handles empty OBJECT schema" do
      {:ok, schema} = Schema.new(%{type: :OBJECT})
      assert :ok = Schema.validate(schema, %{})
      assert :ok = Schema.validate(schema, %{"any" => "value"})
    end

    test "handles empty ARRAY" do
      {:ok, schema} = Schema.new(%{type: :ARRAY, items: %{type: :STRING}})
      assert :ok = Schema.validate(schema, [])
    end

    test "validates enum with mixed types" do
      {:ok, schema} = Schema.new(%{type: :STRING, enum: ["one", "two", "three"]})
      assert :ok = Schema.validate(schema, "one")
    end
  end
end
