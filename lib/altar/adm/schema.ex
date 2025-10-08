defmodule Altar.ADM.Schema do
  @moduledoc """
  Schema definition for ALTAR Data Model (ADM).

  Provides a complete type system following OpenAPI 3.0 patterns for describing
  function parameters, return values, and data structures. Supports nested objects,
  arrays, enumerations, and comprehensive validation constraints.

  ## Schema Types

  - `:STRING` - Text values with optional pattern/format constraints
  - `:NUMBER` - Floating-point numeric values
  - `:INTEGER` - Whole number values
  - `:BOOLEAN` - True/false values
  - `:OBJECT` - Structured objects with typed properties
  - `:ARRAY` - Ordered collections with item type constraints

  ## Examples

      # Simple string schema
      {:ok, schema} = Schema.new(%{
        type: :STRING,
        description: "User's email address"
      })

      # Object schema with nested properties
      {:ok, schema} = Schema.new(%{
        type: :OBJECT,
        properties: %{
          "name" => %{type: :STRING},
          "age" => %{type: :INTEGER, minimum: 0}
        },
        required: ["name"]
      })

      # Array schema
      {:ok, schema} = Schema.new(%{
        type: :ARRAY,
        items: %{type: :STRING},
        description: "List of tags"
      })
  """

  @type schema_type :: :STRING | :NUMBER | :INTEGER | :BOOLEAN | :OBJECT | :ARRAY

  @enforce_keys [:type]
  defstruct [
    :type,
    :description,
    :properties,
    :required,
    :items,
    :enum,
    :format,
    :minimum,
    :maximum,
    :pattern,
    :min_items,
    :max_items,
    :min_length,
    :max_length
  ]

  @typedoc """
  A validated Schema structure.
  """
  @type t :: %__MODULE__{
          type: schema_type(),
          description: String.t() | nil,
          properties: %{optional(String.t()) => t()} | nil,
          required: [String.t()] | nil,
          items: t() | nil,
          enum: [any()] | nil,
          format: String.t() | nil,
          minimum: number() | nil,
          maximum: number() | nil,
          pattern: String.t() | nil,
          min_items: non_neg_integer() | nil,
          max_items: non_neg_integer() | nil,
          min_length: non_neg_integer() | nil,
          max_length: non_neg_integer() | nil
        }

  @valid_types [:STRING, :NUMBER, :INTEGER, :BOOLEAN, :OBJECT, :ARRAY]

  @doc """
  Construct a new validated Schema.

  ## Required Fields

  - `:type` - One of #{inspect(@valid_types)}

  ## Optional Fields

  - `:description` - Human-readable description
  - `:properties` - Map of property schemas (for OBJECT type)
  - `:required` - List of required property names (for OBJECT type)
  - `:items` - Schema for array items (for ARRAY type)
  - `:enum` - List of allowed values
  - `:format` - Format hint (e.g., "email", "uri", "date-time")
  - `:minimum` - Minimum numeric value (for NUMBER/INTEGER)
  - `:maximum` - Maximum numeric value (for NUMBER/INTEGER)
  - `:pattern` - Regex pattern (for STRING)
  - `:min_items` - Minimum array length (for ARRAY)
  - `:max_items` - Maximum array length (for ARRAY)
  - `:min_length` - Minimum string length (for STRING)
  - `:max_length` - Maximum string length (for STRING)

  Returns `{:ok, schema}` or `{:error, reason}`.
  """
  @spec new(map() | keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = normalize_attrs(attrs)

    with {:ok, type} <- validate_type(attrs),
         {:ok, description} <- optional_string(attrs, :description),
         {:ok, properties} <- validate_properties(attrs, type),
         {:ok, required} <- validate_required(attrs, type),
         {:ok, items} <- validate_items(attrs, type),
         {:ok, enum_values} <- optional_list(attrs, :enum),
         {:ok, format} <- optional_string(attrs, :format),
         {:ok, minimum} <- optional_number(attrs, :minimum),
         {:ok, maximum} <- optional_number(attrs, :maximum),
         {:ok, pattern} <- optional_string(attrs, :pattern),
         {:ok, min_items} <- optional_non_neg_integer(attrs, :min_items),
         {:ok, max_items} <- optional_non_neg_integer(attrs, :max_items),
         {:ok, min_length} <- optional_non_neg_integer(attrs, :min_length),
         {:ok, max_length} <- optional_non_neg_integer(attrs, :max_length) do
      {:ok,
       %__MODULE__{
         type: type,
         description: description,
         properties: properties,
         required: required,
         items: items,
         enum: enum_values,
         format: format,
         minimum: minimum,
         maximum: maximum,
         pattern: pattern,
         min_items: min_items,
         max_items: max_items,
         min_length: min_length,
         max_length: max_length
       }}
    end
  end

  @doc """
  Validate a value against this schema.

  Returns `:ok` if the value conforms to the schema, or `{:error, reason}` otherwise.

  ## Examples

      {:ok, schema} = Schema.new(%{type: :STRING, min_length: 3})
      :ok = Schema.validate(schema, "hello")
      {:error, _} = Schema.validate(schema, "hi")
  """
  @spec validate(t(), any()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{type: :STRING} = schema, value) when is_binary(value) do
    with :ok <- validate_string_length(schema, value),
         :ok <- validate_pattern(schema, value),
         :ok <- validate_enum(schema, value) do
      :ok
    end
  end

  def validate(%__MODULE__{type: :STRING}, value),
    do: {:error, "expected STRING, got #{inspect(value)}"}

  def validate(%__MODULE__{type: :INTEGER} = schema, value) when is_integer(value) do
    with :ok <- validate_numeric_range(schema, value),
         :ok <- validate_enum(schema, value) do
      :ok
    end
  end

  def validate(%__MODULE__{type: :INTEGER}, value),
    do: {:error, "expected INTEGER, got #{inspect(value)}"}

  def validate(%__MODULE__{type: :NUMBER} = schema, value) when is_number(value) do
    with :ok <- validate_numeric_range(schema, value),
         :ok <- validate_enum(schema, value) do
      :ok
    end
  end

  def validate(%__MODULE__{type: :NUMBER}, value),
    do: {:error, "expected NUMBER, got #{inspect(value)}"}

  def validate(%__MODULE__{type: :BOOLEAN} = schema, value) when is_boolean(value) do
    validate_enum(schema, value)
  end

  def validate(%__MODULE__{type: :BOOLEAN}, value),
    do: {:error, "expected BOOLEAN, got #{inspect(value)}"}

  def validate(%__MODULE__{type: :OBJECT} = schema, value) when is_map(value) do
    with :ok <- validate_required_properties(schema, value),
         :ok <- validate_object_properties(schema, value),
         :ok <- validate_enum(schema, value) do
      :ok
    end
  end

  def validate(%__MODULE__{type: :OBJECT}, value),
    do: {:error, "expected OBJECT, got #{inspect(value)}"}

  def validate(%__MODULE__{type: :ARRAY} = schema, value) when is_list(value) do
    with :ok <- validate_array_length(schema, value),
         :ok <- validate_array_items(schema, value),
         :ok <- validate_enum(schema, value) do
      :ok
    end
  end

  def validate(%__MODULE__{type: :ARRAY}, value),
    do: {:error, "expected ARRAY, got #{inspect(value)}"}

  @doc """
  Convert schema to JSON-serializable map.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = schema) do
    schema
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new(fn
      {:type, type} ->
        {"type", Atom.to_string(type)}

      {:properties, props} when is_map(props) ->
        {"properties", Map.new(props, fn {k, v} -> {k, to_map(v)} end)}

      {:items, items} when is_struct(items) ->
        {"items", to_map(items)}

      {k, v} ->
        {Atom.to_string(k), v}
    end)
  end

  @doc """
  Parse schema from JSON-deserialized map.
  """
  @spec from_map(map()) :: {:ok, t()} | {:error, String.t()}
  def from_map(map) when is_map(map) do
    normalized =
      map
      |> Map.new(fn
        {"type", type} when is_binary(type) ->
          {:type, String.to_existing_atom(type)}

        {"properties", props} when is_map(props) ->
          {:properties,
           Map.new(props, fn {k, v} ->
             case from_map(v) do
               {:ok, schema} -> {k, schema}
               _ -> {k, v}
             end
           end)}

        {"items", items} when is_map(items) ->
          case from_map(items) do
            {:ok, schema} -> {:items, schema}
            _ -> {:items, items}
          end

        {k, v} ->
          {String.to_existing_atom(k), v}
      end)

    new(normalized)
  rescue
    ArgumentError -> {:error, "invalid schema map: unknown atoms"}
  end

  # -- Private validation helpers --------------------------------------------

  defp validate_type(attrs) do
    case Map.get(attrs, :type) do
      type when type in @valid_types ->
        {:ok, type}

      nil ->
        {:error, "missing required field: type"}

      other ->
        {:error, "invalid type: #{inspect(other)}, must be one of #{inspect(@valid_types)}"}
    end
  end

  defp validate_properties(attrs, :OBJECT) do
    case Map.get(attrs, :properties) do
      nil ->
        {:ok, nil}

      props when is_map(props) ->
        # Recursively validate property schemas
        validated =
          Enum.reduce_while(props, {:ok, %{}}, fn {name, prop_schema}, {:ok, acc} ->
            case convert_to_schema(prop_schema) do
              {:ok, schema} -> {:cont, {:ok, Map.put(acc, name, schema)}}
              {:error, reason} -> {:halt, {:error, "property #{name}: #{reason}"}}
            end
          end)

        validated

      _ ->
        {:error, "properties must be a map"}
    end
  end

  defp validate_properties(_attrs, _type), do: {:ok, nil}

  defp validate_required(attrs, :OBJECT) do
    case Map.get(attrs, :required) do
      nil ->
        {:ok, nil}

      list when is_list(list) ->
        if Enum.all?(list, &is_binary/1) do
          {:ok, list}
        else
          {:error, "required must be a list of strings"}
        end

      _ ->
        {:error, "required must be a list"}
    end
  end

  defp validate_required(_attrs, _type), do: {:ok, nil}

  defp validate_items(attrs, :ARRAY) do
    case Map.get(attrs, :items) do
      nil -> {:error, "ARRAY type requires items schema"}
      items -> convert_to_schema(items)
    end
  end

  defp validate_items(_attrs, _type), do: {:ok, nil}

  defp convert_to_schema(%__MODULE__{} = schema), do: {:ok, schema}
  defp convert_to_schema(map) when is_map(map), do: new(map)
  defp convert_to_schema(_), do: {:error, "schema must be a Schema struct or map"}

  defp validate_string_length(%{min_length: min}, value) when not is_nil(min) do
    if String.length(value) >= min do
      :ok
    else
      {:error, "string length must be >= #{min}"}
    end
  end

  defp validate_string_length(%{max_length: max}, value) when not is_nil(max) do
    if String.length(value) <= max do
      :ok
    else
      {:error, "string length must be <= #{max}"}
    end
  end

  defp validate_string_length(_, _), do: :ok

  defp validate_pattern(%{pattern: pattern}, value) when not is_nil(pattern) do
    case Regex.compile(pattern) do
      {:ok, regex} ->
        if Regex.match?(regex, value) do
          :ok
        else
          {:error, "string does not match pattern: #{pattern}"}
        end

      {:error, _} ->
        {:error, "invalid regex pattern: #{pattern}"}
    end
  end

  defp validate_pattern(_, _), do: :ok

  defp validate_numeric_range(%{minimum: min}, value) when not is_nil(min) do
    if value >= min, do: :ok, else: {:error, "value must be >= #{min}"}
  end

  defp validate_numeric_range(%{maximum: max}, value) when not is_nil(max) do
    if value <= max, do: :ok, else: {:error, "value must be <= #{max}"}
  end

  defp validate_numeric_range(_, _), do: :ok

  defp validate_enum(%{enum: enum_values}, value) when not is_nil(enum_values) do
    if value in enum_values do
      :ok
    else
      {:error, "value must be one of #{inspect(enum_values)}"}
    end
  end

  defp validate_enum(_, _), do: :ok

  defp validate_required_properties(%{required: required, properties: properties}, value)
       when not is_nil(required) and not is_nil(properties) do
    missing =
      Enum.reject(required, fn prop_name ->
        Map.has_key?(value, prop_name) or Map.has_key?(value, String.to_atom(prop_name))
      end)

    if Enum.empty?(missing) do
      :ok
    else
      {:error, "missing required properties: #{inspect(missing)}"}
    end
  end

  defp validate_required_properties(_, _), do: :ok

  defp validate_object_properties(%{properties: properties}, value) when not is_nil(properties) do
    Enum.reduce_while(value, :ok, fn {key, val}, _acc ->
      prop_name = to_string(key)

      case Map.get(properties, prop_name) do
        # Allow additional properties
        nil ->
          {:cont, :ok}

        schema ->
          case validate(schema, val) do
            :ok -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, "property #{prop_name}: #{reason}"}}
          end
      end
    end)
  end

  defp validate_object_properties(_, _), do: :ok

  defp validate_array_length(%{min_items: min}, value) when not is_nil(min) do
    if length(value) >= min do
      :ok
    else
      {:error, "array length must be >= #{min}"}
    end
  end

  defp validate_array_length(%{max_items: max}, value) when not is_nil(max) do
    if length(value) <= max do
      :ok
    else
      {:error, "array length must be <= #{max}"}
    end
  end

  defp validate_array_length(_, _), do: :ok

  defp validate_array_items(%{items: items_schema}, value) when not is_nil(items_schema) do
    value
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {item, idx}, _acc ->
      case validate(items_schema, item) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, "item[#{idx}]: #{reason}"}}
      end
    end)
  end

  defp validate_array_items(_, _), do: :ok

  # -- Attribute helpers -----------------------------------------------------

  defp normalize_attrs(attrs) when is_list(attrs), do: Map.new(attrs)
  defp normalize_attrs(%{} = attrs), do: attrs

  defp optional_string(attrs, key) do
    case Map.get(attrs, key) do
      nil -> {:ok, nil}
      val when is_binary(val) -> {:ok, val}
      _ -> {:error, "#{key} must be a string"}
    end
  end

  defp optional_list(attrs, key) do
    case Map.get(attrs, key) do
      nil -> {:ok, nil}
      val when is_list(val) -> {:ok, val}
      _ -> {:error, "#{key} must be a list"}
    end
  end

  defp optional_number(attrs, key) do
    case Map.get(attrs, key) do
      nil -> {:ok, nil}
      val when is_number(val) -> {:ok, val}
      _ -> {:error, "#{key} must be a number"}
    end
  end

  defp optional_non_neg_integer(attrs, key) do
    case Map.get(attrs, key) do
      nil -> {:ok, nil}
      val when is_integer(val) and val >= 0 -> {:ok, val}
      _ -> {:error, "#{key} must be a non-negative integer"}
    end
  end
end
