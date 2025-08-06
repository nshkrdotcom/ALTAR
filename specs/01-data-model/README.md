# ALTAR Data Model (ADM) Specification v1.0

**Version:** 1.0.0
**Status:** Final

## 1. Introduction

### 1.1. Vision

The ALTAR Data Model (ADM) specification provides the universal, language-agnostic contract for defining AI tools and their interactions. It serves as the single source of truth for the structure of a tool, ensuring that any system implementing the LATER (local) or GRID (distributed) protocols can communicate and interoperate seamlessly.

### 1.2. Guiding Principles

*   **Universal Compatibility:** The data models are designed to be compatible with the function calling implementations of major LLM providers, ensuring easy integration.
*   **Structural Purity:** This specification defines *structure only*. It makes no assertions about how tools are executed, stored, or transported.
*   **Clarity and Precision:** The schemas are defined unambiguously to prevent misinterpretation by different language implementations.
*   **Extensibility:** The models are designed with future growth in mind, allowing for new types and properties to be added in a backward-compatible manner.

## 2. Core Data Structures

These data structures form the complete contract for defining and interacting with tools in the ALTAR ecosystem. They are presented in a language-neutral, JSON-like format.

### 2.1. Tool

A `Tool` represents a collection of capabilities that can be made available to an AI model. In v1.0, the primary capability is a set of function declarations.

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `function_declarations` | `Array[FunctionDeclaration]` | A list of functions that the model can request to call. |
| *Other tool types* | `Object` | *Reserved for future extensions (e.g., `retrieval`, `google_search`).* |

**Example:**
```json
{
  "function_declarations": [
    {
      "name": "get_current_weather",
      "description": "Get the current weather in a given location.",
      "parameters": {
        "type": "OBJECT",
        "properties": {
          "location": {
            "type": "STRING",
            "description": "The city and state, e.g. San Francisco, CA"
          },
          "unit": {
            "type": "STRING",
            "enum": ["celsius", "fahrenheit"]
          }
        },
        "required": ["location"]
      }
    }
  ]
}
```

### 2.2. FunctionDeclaration

A `FunctionDeclaration` is the heart of the specification. It provides a complete, structured definition of a single function or tool that an AI model can use.

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `name` | `String` | **Required.** The name of the function to be called. Must be a-z, A-Z, 0-9, or containing underscores and dashes, with a maximum length of 64. |
| `description` | `String` | **Required.** A detailed description of what the function does. This is used by the model to decide when and how to call the function. |
| `parameters` | `Schema` | The schema of the parameters that the function accepts, defined as a single object. |

### 2.3. Schema

The `Schema` object, based on a subset of the OpenAPI 3.0 specification, defines the structure of the `parameters` for a `FunctionDeclaration` or any nested object.

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `type` | `SchemaType (Enum)` | **Required.** The data type of the schema. |
| `description` | `String` | A description of the schema object or property. |
| `format` | `String` | *Reserved.* An optional field for providing more specific type information (e.g., "int32", "double", "date-time"). |
| `enum` | `Array[String]` | A list of valid string values for a `STRING` type. The model will only output one of these values. |
| `properties` | `Map[String, Schema]` | For `OBJECT` types, defines the properties of the object. The keys are the property names. |
| `required` | `Array[String]` | For `OBJECT` types, lists the names of the properties that are required. |
| `items` | `Schema` | For `ARRAY` types, defines the schema of the elements in the array. |

#### 2.3.1. SchemaType (Enum)

This enumeration defines the valid data types for a `Schema` object.

| Value | Description |
| :--- | :--- |
| `STRING` | A UTF-8 encoded string. |
| `NUMBER` | A floating-point number. |
| `INTEGER` | A whole number. |
| `BOOLEAN` | A true or false value. |
| `ARRAY` | An ordered list of items. The type of the items is defined in the `items` field. |
| `OBJECT` | A map of key-value pairs. The structure is defined in the `properties` field. |

**Example (Complex Schema):**
```json
{
  "type": "OBJECT",
  "properties": {
    "flight_number": {
      "type": "STRING",
      "description": "The flight number, e.g., 'AA123'."
    },
    "passengers": {
      "type": "ARRAY",
      "description": "A list of passengers on the flight.",
      "items": {
        "type": "OBJECT",
        "properties": {
          "name": { "type": "STRING" },
          "seat_number": { "type": "STRING" }
        },
        "required": ["name"]
      }
    }
  },
  "required": ["flight_number"]
}
```

### 2.4. FunctionCall

A `FunctionCall` is a data structure generated by the AI model, representing its request to invoke a specific tool with certain arguments.

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `name` | `String` | **Required.** The name of the function to call. This will match the `name` from a provided `FunctionDeclaration`. |
| `args` | `Map[String, Any]` | **Required.** A map of argument names to their values. The structure of this map will conform to the `parameters` schema of the corresponding `FunctionDeclaration`. |

**Example:**
```json
{
  "name": "get_current_weather",
  "args": {
    "location": "Tokyo, Japan",
    "unit": "celsius"
  }
}
```

### 2.5. FunctionResponse

A `FunctionResponse` is a data structure created by the host application after executing a tool. It contains the result of the tool's execution and is sent back to the model to continue the conversation.

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `name` | `String` | **Required.** The name of the function that was called. This must match the `name` from the `FunctionCall`. |
| `response` | `Object` | **Required.** The output of the function call. This must be a JSON-serializable object containing a `content` field with the result. |

**Example:**
```json
{
  "name": "get_current_weather",
  "response": {
    "content": {
      "temperature": 15,
      "conditions": "Cloudy with a chance of rain."
    }
  }
}
```

### 2.6. ErrorResponse

An `ErrorResponse` is a specialized `FunctionResponse` used to inform the model that a tool execution failed. This allows the model to reason about the failure and potentially try again or inform the user.

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `name` | `String` | **Required.** The name of the function that failed. |
| `response` | `Object` | **Required.** A JSON-serializable object containing an `error` field. |
| `response.error.message`| `String`| A human-readable description of why the tool failed. |
| `response.error.type`| `String` | *Optional.* A standardized error code (e.g., `TOOL_NOT_FOUND`, `PARAMETER_VALIDATION_FAILED`). |

**Example:**
```json
{
  "name": "get_stock_price",
  "response": {
    "error": {
      "message": "Invalid or unknown stock ticker symbol: 'XYZW'",
      "type": "PARAMETER_VALIDATION_FAILED"
    }
  }
}
```
