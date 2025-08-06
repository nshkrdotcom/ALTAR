# ALTAR Data Model (ADM) Specification v1.0

**Version:** 1.0.0  
**Status:** Final  
**Date:** February 2025

## 1. Introduction

### 1.1. Purpose and Scope

The ALTAR Data Model (ADM) v1.0 specification defines the foundational, language-agnostic data structures for AI tools and their interactions within the ALTAR ecosystem. This specification serves as the universal contract that enables seamless interoperability between different components of the ALTAR architecture, ensuring that tools defined in one context can be seamlessly promoted or migrated to another without structural changes.

The ADM provides the complete data structure definitions for:
- Tool capability declarations and metadata
- Function parameter schemas and validation rules
- Function call request and response formats
- Error handling and status reporting structures

This specification is designed to be the single source of truth for tool structure definitions across the entire ALTAR ecosystem, replacing and superseding all previous drafts and implementations.

### 1.2. Three-Layer Architecture

The ALTAR ecosystem is built on a three-layer architecture, with the ADM serving as the foundational layer:

```
┌─────────────────────────────────────────────────────────────┐
│                    Layer 3: GRID Protocol                  │
│              Distributed Tool Orchestration                │
│         Host-Runtime Communication & Enterprise            │
│              Security & Observability                      │
└─────────────────────────────────────────────────────────────┘
                                │
                                │ imports ADM structures
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                   Layer 2: LATER Protocol                  │
│                 Local Tool Execution                       │
│            In-Process Function Calls                       │
│             Development & Prototyping                      │
└─────────────────────────────────────────────────────────────┘
                                │
                                │ imports ADM structures
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                Layer 1: ADM (This Specification)           │
│              Universal Data Structures                     │
│           Tool Definitions & Schemas                       │
│             Function Call Contracts                        │
└─────────────────────────────────────────────────────────────┘
```

**Layer 1 - ALTAR Data Model (ADM):** Defines the universal data structures and contracts for AI tool interactions. This layer is purely structural and contains no execution or transport logic.

**Layer 2 - LATER Protocol:** Implements local, in-process tool execution using ADM data structures. LATER provides the runtime environment for development and prototyping scenarios.

**Layer 3 - GRID Protocol:** Implements distributed tool orchestration using ADM data structures. GRID provides enterprise-grade security, observability, and scalability for production deployments.

### 1.3. Relationship to LATER and GRID Protocols

The ADM serves as the foundational contract that both LATER and GRID protocols import and implement:

**LATER Protocol Integration:**
- LATER imports all ADM data structures for local tool execution
- Tool definitions created using ADM structures work seamlessly in LATER environments
- LATER provides the execution runtime while ADM provides the data contracts

**GRID Protocol Integration:**
- GRID imports all ADM data structures for distributed tool orchestration
- Tools defined using ADM structures can be promoted from LATER to GRID without modification
- GRID adds transport, security, and observability layers while preserving ADM contracts

**Interoperability Benefits:**
- Tools defined once using ADM structures work in both LATER and GRID environments
- Migration between local and distributed execution requires no structural changes
- Consistent data formats enable seamless ecosystem integration

### 1.4. Design Principles

**Industry Compatibility:** All data structures align with established industry patterns, particularly Google Gemini's function calling API and OpenAPI 3.0 specifications, ensuring seamless integration with existing LLM clients and tools.

**Structural Purity:** The ADM defines only data structures and contracts. It contains no references to execution logic, runtimes, sessions, networking, transport, or host-specific concerns. These responsibilities belong to the higher-layer protocols.

**Language Neutrality:** All definitions use universal, language-agnostic terms and JSON serialization, enabling consistent implementation across any programming language.

**Extensibility:** The specification is designed for forward compatibility, allowing future enhancements while maintaining backward compatibility with existing implementations.

**Precision and Clarity:** Every data structure is defined unambiguously with comprehensive field documentation, validation rules, and examples to prevent implementation inconsistencies.

### 1.5. Industry Compatibility

The ADM is designed for seamless integration with existing AI and API ecosystems through alignment with established industry standards.

#### Google Gemini API Compatibility

The ADM data structures align directly with Google Gemini's function calling API:

- **Tool Structure**: The `function_declarations` array maps directly to Gemini's tools format
- **Function Declarations**: ADM FunctionDeclaration structure matches Gemini's format exactly, with automatic type case conversion (ADM's uppercase `STRING` → Gemini's lowercase `string`)
- **Function Calls**: ADM FunctionCall structure is directly compatible with Gemini-generated function calls
- **Response Handling**: ADM ToolResult can be adapted to Gemini's expected response format through simple transformation

This compatibility enables ADM-defined tools to work seamlessly with `gemini_ex` and other Gemini API clients.

#### OpenAPI 3.0 Schema Compliance

The ADM Schema type system implements the core subset of OpenAPI 3.0 JSON Schema Object specification:

- **Core Types**: Full support for all basic types (string, number, integer, boolean, array, object)
- **Structure**: Implements `properties`, `required`, `items`, and `enum` fields as defined in OpenAPI 3.0
- **Validation**: Compatible with standard OpenAPI validation tools for supported features
- **Limitations**: Advanced validation constraints (minLength, maxLength, pattern, format) are not supported in v1.0

This compliance ensures ADM schemas can be validated using standard OpenAPI tooling and integrated into existing API documentation workflows.

## 2. Serialization Format

**JSON is the canonical serialization format** for all ADM data structures. This ensures cross-language compatibility and consistent interchange between different implementations.

### 2.1. Serialization Requirements

- **Standard Compliance:** All structures must serialize to valid JSON as defined by RFC 7159
- **Character Encoding:** String values must use UTF-8 encoding
- **Numeric Precision:** Numbers must preserve precision according to IEEE 754 standards
- **Field Ordering:** Field order in JSON objects is not significant
- **Null Handling:** Absent optional fields should be omitted rather than set to null

## 3. Core Data Structures

The following sections define the complete set of data structures that form the ADM specification. Each structure includes comprehensive field documentation, validation rules, and practical examples.

### 3.1. Tool Structure

The `Tool` structure serves as the top-level container for AI capabilities, providing a standardized way to declare and organize function-based tools within the ALTAR ecosystem.

#### 3.1.1. Structure Definition

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `function_declarations` | `FunctionDeclaration[]` | Yes | Array of function declarations that define the capabilities provided by this tool |

#### 3.1.2. Field Specifications

**function_declarations**
- **Type:** Array of `FunctionDeclaration` objects
- **Constraints:** Must contain at least one function declaration
- **Purpose:** Defines all the callable functions that this tool provides
- **Extensibility:** Future versions may add additional capability types (e.g., retrieval, search) alongside function declarations

#### 3.1.3. Validation Rules

1. The `function_declarations` array must not be empty
2. Each element in the array must be a valid `FunctionDeclaration` object
3. Function names within a single tool must be unique
4. The tool structure must be serializable to valid JSON

#### 3.1.4. JSON Schema Representation

```json
{
  "type": "object",
  "properties": {
    "function_declarations": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/FunctionDeclaration"
      },
      "minItems": 1,
      "description": "Array of function declarations defining tool capabilities"
    }
  },
  "required": ["function_declarations"],
  "additionalProperties": false
}
```

#### 3.1.5. Examples

**Simple Tool with Single Function**
```json
{
  "function_declarations": [
    {
      "name": "get_current_time",
      "description": "Returns the current date and time in ISO 8601 format",
      "parameters": {
        "type": "OBJECT",
        "properties": {
          "timezone": {
            "type": "STRING",
            "description": "Timezone identifier (e.g., 'America/New_York', 'UTC')",
            "enum": ["UTC", "America/New_York", "Europe/London", "Asia/Tokyo"]
          }
        },
        "required": []
      }
    }
  ]
}
```

**Complex Tool with Multiple Functions**
```json
{
  "function_declarations": [
    {
      "name": "get_weather_forecast",
      "description": "Retrieves weather forecast for a specified location and time period",
      "parameters": {
        "type": "OBJECT",
        "properties": {
          "location": {
            "type": "STRING",
            "description": "City and state or country, e.g., 'San Francisco, CA'"
          },
          "days": {
            "type": "INTEGER",
            "description": "Number of days to forecast (1-7)"
          },
          "units": {
            "type": "STRING",
            "enum": ["celsius", "fahrenheit"],
            "description": "Temperature units"
          }
        },
        "required": ["location"]
      }
    },
    {
      "name": "get_weather_alerts",
      "description": "Retrieves active weather alerts for a specified location",
      "parameters": {
        "type": "OBJECT",
        "properties": {
          "location": {
            "type": "STRING",
            "description": "City and state or country, e.g., 'San Francisco, CA'"
          },
          "severity": {
            "type": "STRING",
            "enum": ["minor", "moderate", "severe", "extreme"],
            "description": "Minimum alert severity level"
          }
        },
        "required": ["location"]
      }
    }
  ]
}
```

**Enterprise Tool with Complex Parameters**
```json
{
  "function_declarations": [
    {
      "name": "create_support_ticket",
      "description": "Creates a new support ticket in the enterprise ticketing system",
      "parameters": {
        "type": "OBJECT",
        "properties": {
          "title": {
            "type": "STRING",
            "description": "Brief title describing the issue"
          },
          "description": {
            "type": "STRING",
            "description": "Detailed description of the issue"
          },
          "priority": {
            "type": "STRING",
            "enum": ["low", "medium", "high", "critical"],
            "description": "Priority level for the ticket"
          },
          "category": {
            "type": "STRING",
            "enum": ["technical", "billing", "account", "feature_request"],
            "description": "Category of the support request"
          },
          "assignee": {
            "type": "OBJECT",
            "properties": {
              "team": {
                "type": "STRING",
                "description": "Team to assign the ticket to"
              },
              "user_id": {
                "type": "STRING",
                "description": "Specific user ID to assign (optional)"
              }
            },
            "required": ["team"]
          },
          "attachments": {
            "type": "ARRAY",
            "items": {
              "type": "OBJECT",
              "properties": {
                "filename": {
                  "type": "STRING",
                  "description": "Name of the attached file"
                },
                "content_type": {
                  "type": "STRING",
                  "description": "MIME type of the attachment"
                },
                "size": {
                  "type": "INTEGER",
                  "description": "File size in bytes"
                }
              },
              "required": ["filename", "content_type"]
            },
            "description": "Optional file attachments"
          }
        },
        "required": ["title", "description", "priority", "category"]
      }
    }
  ]
}
```

#### 3.1.6. Design Rationale

The Tool structure is intentionally minimal and extensible:

1. **Single Responsibility:** Currently focuses on function declarations, but the structure allows for future capability types
2. **Industry Alignment:** Directly compatible with Google Gemini's function calling API structure
3. **Validation Clarity:** Simple structure makes validation straightforward and unambiguous
4. **Future Extensibility:** Additional fields can be added (e.g., `retrieval_declarations`, `search_declarations`) without breaking existing implementations
5. **Namespace Isolation:** Each tool maintains its own namespace of function names, preventing conflicts

#### 3.1.7. Implementation Notes

**Language-Specific Considerations:**
- In strongly-typed languages, implement as a class or struct with appropriate field types
- In dynamically-typed languages, ensure runtime validation of the structure
- All implementations must support JSON serialization/deserialization

**Validation Implementation:**
- Validate that function names are unique within the tool
- Ensure all function declarations conform to the FunctionDeclaration specification
- Implement schema validation for the overall tool structure

**Error Handling:**
- Invalid tool structures should result in clear, actionable error messages
- Validation errors should specify which function declaration failed and why
- Tools with duplicate function names should be rejected during validation

### 3.2. FunctionDeclaration Structure

The `FunctionDeclaration` structure defines individual callable functions within a tool, specifying their interface, parameters, and behavior contract.

#### 3.2.1. Structure Definition

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `String` | Yes | Unique identifier for the function within the tool |
| `description` | `String` | Yes | Human-readable description of the function's purpose and behavior |
| `parameters` | `Schema` | Yes | Schema object defining the function's input parameters |

#### 3.2.2. Field Specifications

**name**
- **Type:** String
- **Constraints:** 
  - Must contain only alphanumeric characters (a-z, A-Z, 0-9), underscores (_), and dashes (-)
  - Maximum length of 64 characters
  - Must start with a letter or underscore
  - Must be unique within the containing tool
- **Purpose:** Serves as the function identifier for invocation
- **Examples:** `get_weather`, `create_user`, `send_email`, `calculate_tax`

**description**
- **Type:** String
- **Constraints:** 
  - Must be non-empty
  - Should be clear and concise (recommended 1-3 sentences)
  - Should describe what the function does, not how it works
- **Purpose:** Provides context for AI models and human developers
- **Best Practices:** Include expected behavior, side effects, and any important limitations

**parameters**
- **Type:** `Schema` object
- **Constraints:** Must be a valid Schema object (typically of type "OBJECT")
- **Purpose:** Defines the structure and validation rules for function input parameters
- **Note:** Even functions with no parameters must include a parameters field with an empty OBJECT schema

#### 3.2.3. Validation Rules

1. **Name Validation:**
   - Must match the pattern: `^[a-zA-Z_][a-zA-Z0-9_-]{0,63}$`
   - Must be unique within the containing tool
   - Case-sensitive comparison for uniqueness

2. **Description Validation:**
   - Must be a non-empty string
   - Should not exceed 1000 characters (recommended limit)

3. **Parameters Validation:**
   - Must be a valid Schema object
   - Root schema should typically be of type "OBJECT"
   - All nested schemas must be valid

#### 3.2.4. JSON Schema Representation

```json
{
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "pattern": "^[a-zA-Z_][a-zA-Z0-9_-]{0,63}$",
      "description": "Function identifier for invocation"
    },
    "description": {
      "type": "string",
      "minLength": 1,
      "maxLength": 1000,
      "description": "Human-readable function description"
    },
    "parameters": {
      "$ref": "#/definitions/Schema",
      "description": "Schema defining function input parameters"
    }
  },
  "required": ["name", "description", "parameters"],
  "additionalProperties": false
}
```

#### 3.2.5. Examples

**Simple Function with Basic Parameters**
```json
{
  "name": "get_user_profile",
  "description": "Retrieves user profile information by user ID",
  "parameters": {
    "type": "OBJECT",
    "properties": {
      "user_id": {
        "type": "STRING",
        "description": "Unique identifier for the user"
      }
    },
    "required": ["user_id"]
  }
}
```

**Function with No Parameters**
```json
{
  "name": "get_system_status",
  "description": "Returns the current system health and status information",
  "parameters": {
    "type": "OBJECT",
    "properties": {},
    "required": []
  }
}
```

**Complex Function with Nested Parameters**
```json
{
  "name": "schedule_meeting",
  "description": "Schedules a new meeting with specified participants and details",
  "parameters": {
    "type": "OBJECT",
    "properties": {
      "title": {
        "type": "STRING",
        "description": "Meeting title or subject"
      },
      "start_time": {
        "type": "STRING",
        "description": "Meeting start time in ISO 8601 format"
      },
      "duration_minutes": {
        "type": "INTEGER",
        "description": "Meeting duration in minutes"
      },
      "participants": {
        "type": "ARRAY",
        "items": {
          "type": "OBJECT",
          "properties": {
            "email": {
              "type": "STRING",
              "description": "Participant email address"
            },
            "role": {
              "type": "STRING",
              "enum": ["organizer", "required", "optional"],
              "description": "Participant role in the meeting"
            },
            "send_invitation": {
              "type": "BOOLEAN",
              "description": "Whether to send calendar invitation"
            }
          },
          "required": ["email", "role"]
        },
        "description": "List of meeting participants"
      },
      "location": {
        "type": "OBJECT",
        "properties": {
          "type": {
            "type": "STRING",
            "enum": ["physical", "virtual", "hybrid"],
            "description": "Type of meeting location"
          },
          "address": {
            "type": "STRING",
            "description": "Physical address (required for physical/hybrid meetings)"
          },
          "virtual_link": {
            "type": "STRING",
            "description": "Virtual meeting link (required for virtual/hybrid meetings)"
          },
          "room_capacity": {
            "type": "INTEGER",
            "description": "Maximum room capacity (optional for physical meetings)"
          }
        },
        "required": ["type"]
      },
      "recurrence": {
        "type": "OBJECT",
        "properties": {
          "pattern": {
            "type": "STRING",
            "enum": ["daily", "weekly", "monthly", "yearly"],
            "description": "Recurrence pattern"
          },
          "interval": {
            "type": "INTEGER",
            "description": "Interval between occurrences (e.g., every 2 weeks)"
          },
          "end_date": {
            "type": "STRING",
            "description": "End date for recurrence in ISO 8601 format"
          },
          "occurrences": {
            "type": "INTEGER",
            "description": "Maximum number of occurrences"
          }
        },
        "required": ["pattern"]
      }
    },
    "required": ["title", "start_time", "duration_minutes", "participants"]
  }
}
```

**Data Processing Function with Validation**
```json
{
  "name": "process_financial_data",
  "description": "Processes and validates financial transaction data, applying business rules and generating reports",
  "parameters": {
    "type": "OBJECT",
    "properties": {
      "transactions": {
        "type": "ARRAY",
        "items": {
          "type": "OBJECT",
          "properties": {
            "transaction_id": {
              "type": "STRING",
              "description": "Unique transaction identifier"
            },
            "amount": {
              "type": "NUMBER",
              "description": "Transaction amount (positive for credits, negative for debits)"
            },
            "currency": {
              "type": "STRING",
              "enum": ["USD", "EUR", "GBP", "JPY", "CAD", "AUD"],
              "description": "Transaction currency code"
            },
            "timestamp": {
              "type": "STRING",
              "description": "Transaction timestamp in ISO 8601 format"
            },
            "category": {
              "type": "STRING",
              "enum": ["income", "expense", "transfer", "investment", "fee"],
              "description": "Transaction category"
            },
            "account": {
              "type": "OBJECT",
              "properties": {
                "account_id": {
                  "type": "STRING",
                  "description": "Account identifier"
                },
                "account_type": {
                  "type": "STRING",
                  "enum": ["checking", "savings", "credit", "investment"],
                  "description": "Type of account"
                }
              },
              "required": ["account_id", "account_type"]
            },
            "metadata": {
              "type": "OBJECT",
              "properties": {
                "merchant": {
                  "type": "STRING",
                  "description": "Merchant name (for purchases)"
                },
                "reference": {
                  "type": "STRING",
                  "description": "External reference number"
                },
                "tags": {
                  "type": "ARRAY",
                  "items": {
                    "type": "STRING"
                  },
                  "description": "User-defined tags for categorization"
                }
              }
            }
          },
          "required": ["transaction_id", "amount", "currency", "timestamp", "category", "account"]
        },
        "description": "Array of financial transactions to process"
      },
      "validation_rules": {
        "type": "OBJECT",
        "properties": {
          "max_amount": {
            "type": "NUMBER",
            "description": "Maximum allowed transaction amount"
          },
          "allowed_currencies": {
            "type": "ARRAY",
            "items": {
              "type": "STRING"
            },
            "description": "List of allowed currency codes"
          },
          "require_merchant": {
            "type": "BOOLEAN",
            "description": "Whether merchant information is required for expense transactions"
          }
        }
      },
      "output_format": {
        "type": "STRING",
        "enum": ["summary", "detailed", "csv", "json"],
        "description": "Desired output format for the processing report"
      }
    },
    "required": ["transactions", "output_format"]
  }
}
```

#### 3.2.6. Design Rationale

The FunctionDeclaration structure balances simplicity with comprehensive functionality:

1. **Industry Compatibility:** Directly mirrors Google Gemini's function calling API structure
2. **Validation Clarity:** Name constraints prevent common integration issues
3. **Flexibility:** Schema-based parameters support arbitrarily complex input structures
4. **AI-Friendly:** Clear descriptions help AI models understand function capabilities
5. **Developer Experience:** Comprehensive examples and validation rules reduce implementation errors

#### 3.2.7. Implementation Notes

**Name Validation Implementation:**
```javascript
function validateFunctionName(name) {
  const pattern = /^[a-zA-Z_][a-zA-Z0-9_-]{0,63}$/;
  return pattern.test(name);
}
```

**Common Validation Errors:**
- Names starting with numbers: `"2get_data"` → Invalid
- Names with spaces: `"get data"` → Invalid  
- Names with special characters: `"get@data"` → Invalid
- Names exceeding 64 characters → Invalid
- Empty descriptions → Invalid
- Invalid parameter schemas → Invalid

**Best Practices:**
- Use descriptive, action-oriented function names
- Include examples in descriptions when helpful
- Design parameters for clarity and type safety
- Consider backward compatibility when evolving function signatures
- Validate all inputs thoroughly before processing

### 3.3. Schema Type System

The Schema type system provides a comprehensive, recursive structure for defining and validating data types within function parameters. Based on OpenAPI 3.0 specifications, it supports both primitive and complex data types with full validation capabilities.

#### 3.3.1. Schema Structure Definition

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `SchemaType` | Yes | The data type of the schema |
| `description` | `String` | No | Human-readable description of the data |
| `properties` | `Map<String, Schema>` | No | Object properties (required when type is OBJECT) |
| `required` | `String[]` | No | Array of required property names (used with OBJECT type) |
| `items` | `Schema` | No | Schema for array elements (required when type is ARRAY) |
| `enum` | `String[]` | No | Array of allowed string values (used with STRING type) |

#### 3.3.2. SchemaType Enumeration

The `SchemaType` enumeration defines the supported data types:

| Type | Description | JSON Representation | Validation Rules |
|------|-------------|-------------------|------------------|
| `STRING` | UTF-8 encoded text | `"STRING"` | Must be valid UTF-8 string |
| `NUMBER` | IEEE 754 double-precision floating-point | `"NUMBER"` | Must be valid numeric value |
| `INTEGER` | 64-bit signed integer | `"INTEGER"` | Must be whole number within range |
| `BOOLEAN` | True/false value | `"BOOLEAN"` | Must be exactly `true` or `false` |
| `ARRAY` | Ordered collection of elements | `"ARRAY"` | Must have `items` field defining element schema |
| `OBJECT` | Key-value map with structured properties | `"OBJECT"` | May have `properties` and `required` fields |

#### 3.3.3. Field Specifications

**type**
- **Type:** SchemaType enumeration value
- **Purpose:** Defines the fundamental data type for validation
- **Constraints:** Must be one of the defined SchemaType values

**description**
- **Type:** String (optional)
- **Purpose:** Provides human-readable context for the data field
- **Best Practices:** Should be concise but informative, especially for complex nested structures

**properties**
- **Type:** Map of property names to Schema objects
- **Usage:** Required for OBJECT types that have defined properties
- **Purpose:** Defines the structure and validation rules for object properties
- **Note:** Empty properties map indicates an object that accepts any properties

**required**
- **Type:** Array of strings
- **Usage:** Used with OBJECT types to specify mandatory properties
- **Constraints:** All strings must correspond to keys in the properties map
- **Default:** Empty array (no required properties)

**items**
- **Type:** Schema object
- **Usage:** Required for ARRAY types
- **Purpose:** Defines the schema that all array elements must conform to
- **Note:** Supports homogeneous arrays (all elements same type)

**enum**
- **Type:** Array of strings
- **Usage:** Used with STRING types to restrict values to a specific set
- **Purpose:** Provides enumeration constraints for string values
- **Validation:** Input must exactly match one of the enum values

#### 3.3.4. Recursive Schema Support

The Schema system supports unlimited nesting depth, enabling complex data structures:

```json
{
  "type": "OBJECT",
  "properties": {
    "user": {
      "type": "OBJECT",
      "properties": {
        "profile": {
          "type": "OBJECT",
          "properties": {
            "preferences": {
              "type": "ARRAY",
              "items": {
                "type": "OBJECT",
                "properties": {
                  "category": { "type": "STRING" },
                  "settings": {
                    "type": "OBJECT",
                    "properties": {
                      "enabled": { "type": "BOOLEAN" },
                      "values": {
                        "type": "ARRAY",
                        "items": { "type": "STRING" }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

#### 3.3.5. JSON Schema Representation

```json
{
  "type": "object",
  "properties": {
    "type": {
      "type": "string",
      "enum": ["STRING", "NUMBER", "INTEGER", "BOOLEAN", "ARRAY", "OBJECT"],
      "description": "The data type of the schema"
    },
    "description": {
      "type": "string",
      "description": "Human-readable description of the data"
    },
    "properties": {
      "type": "object",
      "additionalProperties": {
        "$ref": "#/definitions/Schema"
      },
      "description": "Object properties (for OBJECT type)"
    },
    "required": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Required property names (for OBJECT type)"
    },
    "items": {
      "$ref": "#/definitions/Schema",
      "description": "Schema for array elements (for ARRAY type)"
    },
    "enum": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Allowed string values (for STRING type)"
    }
  },
  "required": ["type"],
  "additionalProperties": false
}
```

#### 3.3.6. Examples

**Primitive Type Schemas**

```json
// String with enumeration
{
  "type": "STRING",
  "description": "User role in the system",
  "enum": ["admin", "user", "guest"]
}

// Number with description
{
  "type": "NUMBER",
  "description": "Temperature in degrees Celsius"
}

// Integer for counting
{
  "type": "INTEGER",
  "description": "Number of items to process"
}

// Boolean flag
{
  "type": "BOOLEAN",
  "description": "Whether to send confirmation email"
}
```

**Array Type Schemas**

```json
// Array of strings
{
  "type": "ARRAY",
  "description": "List of email addresses",
  "items": {
    "type": "STRING",
    "description": "Valid email address"
  }
}

// Array of objects
{
  "type": "ARRAY",
  "description": "List of user accounts",
  "items": {
    "type": "OBJECT",
    "properties": {
      "id": {
        "type": "STRING",
        "description": "Unique user identifier"
      },
      "name": {
        "type": "STRING",
        "description": "User's full name"
      },
      "active": {
        "type": "BOOLEAN",
        "description": "Whether the account is active"
      }
    },
    "required": ["id", "name"]
  }
}

// Nested array structure
{
  "type": "ARRAY",
  "description": "Matrix of numeric values",
  "items": {
    "type": "ARRAY",
    "description": "Row of numbers",
    "items": {
      "type": "NUMBER",
      "description": "Individual matrix element"
    }
  }
}
```

**Object Type Schemas**

```json
// Simple object
{
  "type": "OBJECT",
  "description": "User contact information",
  "properties": {
    "email": {
      "type": "STRING",
      "description": "Primary email address"
    },
    "phone": {
      "type": "STRING",
      "description": "Phone number with country code"
    }
  },
  "required": ["email"]
}

// Complex nested object
{
  "type": "OBJECT",
  "description": "E-commerce order details",
  "properties": {
    "order_id": {
      "type": "STRING",
      "description": "Unique order identifier"
    },
    "customer": {
      "type": "OBJECT",
      "description": "Customer information",
      "properties": {
        "id": {
          "type": "STRING",
          "description": "Customer ID"
        },
        "name": {
          "type": "STRING",
          "description": "Customer full name"
        },
        "email": {
          "type": "STRING",
          "description": "Customer email address"
        },
        "shipping_address": {
          "type": "OBJECT",
          "description": "Shipping address details",
          "properties": {
            "street": {
              "type": "STRING",
              "description": "Street address"
            },
            "city": {
              "type": "STRING",
              "description": "City name"
            },
            "state": {
              "type": "STRING",
              "description": "State or province"
            },
            "postal_code": {
              "type": "STRING",
              "description": "Postal or ZIP code"
            },
            "country": {
              "type": "STRING",
              "enum": ["US", "CA", "GB", "DE", "FR", "JP", "AU"],
              "description": "Country code"
            }
          },
          "required": ["street", "city", "postal_code", "country"]
        }
      },
      "required": ["id", "name", "email"]
    },
    "items": {
      "type": "ARRAY",
      "description": "Ordered items",
      "items": {
        "type": "OBJECT",
        "properties": {
          "product_id": {
            "type": "STRING",
            "description": "Product identifier"
          },
          "name": {
            "type": "STRING",
            "description": "Product name"
          },
          "quantity": {
            "type": "INTEGER",
            "description": "Number of items ordered"
          },
          "price": {
            "type": "NUMBER",
            "description": "Unit price in USD"
          },
          "options": {
            "type": "OBJECT",
            "description": "Product customization options",
            "properties": {
              "color": {
                "type": "STRING",
                "enum": ["red", "blue", "green", "black", "white"],
                "description": "Product color"
              },
              "size": {
                "type": "STRING",
                "enum": ["XS", "S", "M", "L", "XL", "XXL"],
                "description": "Product size"
              },
              "gift_wrap": {
                "type": "BOOLEAN",
                "description": "Whether to include gift wrapping"
              }
            }
          }
        },
        "required": ["product_id", "name", "quantity", "price"]
      }
    },
    "payment": {
      "type": "OBJECT",
      "description": "Payment information",
      "properties": {
        "method": {
          "type": "STRING",
          "enum": ["credit_card", "debit_card", "paypal", "bank_transfer"],
          "description": "Payment method"
        },
        "currency": {
          "type": "STRING",
          "enum": ["USD", "EUR", "GBP", "CAD", "AUD"],
          "description": "Payment currency"
        },
        "total": {
          "type": "NUMBER",
          "description": "Total amount charged"
        }
      },
      "required": ["method", "currency", "total"]
    }
  },
  "required": ["order_id", "customer", "items", "payment"]
}
```

**Advanced Schema Patterns**

```json
// Configuration object with flexible structure
{
  "type": "OBJECT",
  "description": "Application configuration settings",
  "properties": {
    "database": {
      "type": "OBJECT",
      "description": "Database connection settings",
      "properties": {
        "host": { "type": "STRING" },
        "port": { "type": "INTEGER" },
        "name": { "type": "STRING" },
        "ssl": { "type": "BOOLEAN" }
      },
      "required": ["host", "name"]
    },
    "features": {
      "type": "OBJECT",
      "description": "Feature flags",
      "properties": {
        "analytics": { "type": "BOOLEAN" },
        "notifications": { "type": "BOOLEAN" },
        "beta_features": {
          "type": "ARRAY",
          "items": {
            "type": "STRING",
            "enum": ["new_ui", "advanced_search", "ai_assistant"]
          }
        }
      }
    },
    "integrations": {
      "type": "ARRAY",
      "description": "Third-party integrations",
      "items": {
        "type": "OBJECT",
        "properties": {
          "name": { "type": "STRING" },
          "enabled": { "type": "BOOLEAN" },
          "config": {
            "type": "OBJECT",
            "description": "Integration-specific configuration"
          }
        },
        "required": ["name", "enabled"]
      }
    }
  }
}
```

#### 3.3.7. Validation Rules

**Type-Specific Validation:**

1. **STRING Type:**
   - Must be valid UTF-8 encoded text
   - If `enum` is specified, value must match exactly one enum value
   - Empty strings are valid unless explicitly prohibited

2. **NUMBER Type:**
   - Must be valid IEEE 754 double-precision floating-point number
   - Supports positive, negative, and zero values
   - Special values (NaN, Infinity) should be handled according to implementation requirements

3. **INTEGER Type:**
   - Must be whole number within 64-bit signed integer range (-2^63 to 2^63-1)
   - Decimal values are invalid for INTEGER type

4. **BOOLEAN Type:**
   - Must be exactly `true` or `false`
   - String representations ("true", "false") are invalid

5. **ARRAY Type:**
   - Must have `items` field defining element schema
   - All elements must conform to the items schema
   - Empty arrays are valid

6. **OBJECT Type:**
   - All properties must conform to their defined schemas
   - Required properties must be present
   - Additional properties handling depends on implementation policy

**Cross-Field Validation:**
- `required` array elements must exist in `properties` map
- `items` field is mandatory for ARRAY types
- `enum` field is only valid for STRING types
- Recursive schemas must not create infinite loops

#### 3.3.8. Design Rationale

The Schema type system design prioritizes:

1. **OpenAPI Compatibility:** Direct alignment with OpenAPI 3.0 JSON Schema Object
2. **Type Safety:** Clear type definitions prevent runtime errors
3. **Flexibility:** Recursive structure supports arbitrarily complex data
4. **Validation Clarity:** Unambiguous rules for data validation
5. **Industry Standards:** Uses established patterns from JSON Schema specification

#### 3.3.9. Implementation Notes

**Validation Algorithm:**
```javascript
function validateSchema(data, schema) {
  switch (schema.type) {
    case 'STRING':
      if (typeof data !== 'string') return false;
      if (schema.enum && !schema.enum.includes(data)) return false;
      return true;
    
    case 'NUMBER':
      return typeof data === 'number' && !isNaN(data);
    
    case 'INTEGER':
      return Number.isInteger(data);
    
    case 'BOOLEAN':
      return typeof data === 'boolean';
    
    case 'ARRAY':
      if (!Array.isArray(data)) return false;
      return data.every(item => validateSchema(item, schema.items));
    
    case 'OBJECT':
      if (typeof data !== 'object' || data === null) return false;
      
      // Check required properties
      if (schema.required) {
        for (const prop of schema.required) {
          if (!(prop in data)) return false;
        }
      }
      
      // Validate properties
      if (schema.properties) {
        for (const [key, value] of Object.entries(data)) {
          if (key in schema.properties) {
            if (!validateSchema(value, schema.properties[key])) return false;
          }
        }
      }
      
      return true;
    
    default:
      return false;
  }
}
```

**Common Implementation Patterns:**
- Use recursive validation for nested structures
- Implement schema caching for performance optimization
- Provide detailed error messages for validation failures
- Support schema composition and inheritance for complex scenarios
- Consider implementing schema versioning for backward compatibility

### 3.4. FunctionCall Structure

The `FunctionCall` structure represents a request to invoke a specific function within a tool, containing the function name and its arguments. This structure is used by AI models to request tool execution and must reference a function declared in the corresponding Tool's function_declarations.

#### 3.4.1. Structure Definition

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `String` | Yes | Name of the function to invoke, must match a FunctionDeclaration name |
| `args` | `Map<String, Any>` | Yes | Arguments to pass to the function, must conform to the function's parameter schema |

#### 3.4.2. Field Specifications

**name**
- **Type:** String
- **Constraints:** 
  - Must exactly match the name of a function declared in the associated Tool's function_declarations
  - Case-sensitive matching
  - Must follow the same naming rules as FunctionDeclaration names
- **Purpose:** Identifies which function to invoke
- **Validation:** Must reference an existing, valid function declaration

**args**
- **Type:** Map of string keys to JSON-serializable values
- **Constraints:** 
  - Must conform to the parameter schema defined in the referenced FunctionDeclaration
  - All required parameters must be present
  - Parameter values must match their declared types
  - Additional parameters not defined in the schema should be rejected
- **Purpose:** Provides the input data for function execution
- **Serialization:** Must be JSON-serializable (strings, numbers, booleans, arrays, objects, null)

#### 3.4.3. Validation Rules

1. **Function Reference Validation:**
   - The `name` field must reference an existing FunctionDeclaration in the associated Tool
   - Function name matching is case-sensitive and must be exact

2. **Parameter Validation:**
   - All arguments in `args` must conform to the parameter schema defined in the referenced FunctionDeclaration
   - Required parameters must be present in the args map
   - Parameter types must match their schema definitions exactly
   - Enum constraints must be respected for string parameters

3. **JSON Serialization:**
   - All values in the `args` map must be JSON-serializable
   - Complex objects must conform to their nested schema definitions
   - Arrays must contain elements of the correct type as defined in the schema

#### 3.4.4. JSON Schema Representation

```json
{
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "pattern": "^[a-zA-Z_][a-zA-Z0-9_-]{0,63}$",
      "description": "Name of the function to invoke"
    },
    "args": {
      "type": "object",
      "description": "Function arguments as key-value pairs"
    }
  },
  "required": ["name", "args"],
  "additionalProperties": false
}
```

#### 3.4.5. Examples

**Simple Function Call with Basic Parameters**
```json
{
  "name": "get_weather_forecast",
  "args": {
    "location": "San Francisco, CA",
    "days": 3,
    "units": "celsius"
  }
}
```

**Function Call with No Parameters**
```json
{
  "name": "get_system_status",
  "args": {}
}
```

**Complex Function Call with Nested Objects**
```json
{
  "name": "schedule_meeting",
  "args": {
    "title": "Project Planning Session",
    "start_time": "2025-02-10T14:00:00Z",
    "duration_minutes": 60,
    "participants": [
      {
        "email": "alice@example.com",
        "role": "organizer",
        "send_invitation": true
      },
      {
        "email": "bob@example.com",
        "role": "required",
        "send_invitation": true
      },
      {
        "email": "charlie@example.com",
        "role": "optional",
        "send_invitation": false
      }
    ],
    "location": {
      "type": "virtual",
      "virtual_link": "https://meet.example.com/abc-def-ghi"
    }
  }
}
```

**Function Call with Array Parameters**
```json
{
  "name": "process_financial_data",
  "args": {
    "transactions": [
      {
        "transaction_id": "txn_001",
        "amount": -45.67,
        "currency": "USD",
        "timestamp": "2025-02-08T10:30:00Z",
        "category": "expense",
        "account": {
          "account_id": "acc_checking_001",
          "account_type": "checking"
        },
        "metadata": {
          "merchant": "Coffee Shop Downtown",
          "tags": ["food", "coffee"]
        }
      },
      {
        "transaction_id": "txn_002",
        "amount": 2500.00,
        "currency": "USD",
        "timestamp": "2025-02-08T09:00:00Z",
        "category": "income",
        "account": {
          "account_id": "acc_checking_001",
          "account_type": "checking"
        },
        "metadata": {
          "reference": "SALARY_FEB_2025"
        }
      }
    ],
    "validation_rules": {
      "max_amount": 10000.00,
      "allowed_currencies": ["USD", "EUR"],
      "require_merchant": true
    },
    "output_format": "detailed"
  }
}
```

**Function Call with String Enumeration**
```json
{
  "name": "create_support_ticket",
  "args": {
    "title": "Unable to access dashboard",
    "description": "User reports that the main dashboard is not loading after login. Error message shows 'Connection timeout'.",
    "priority": "high",
    "category": "technical",
    "assignee": {
      "team": "frontend-support"
    },
    "attachments": [
      {
        "filename": "error_screenshot.png",
        "content_type": "image/png",
        "size": 245760
      }
    ]
  }
}
```

#### 3.4.6. Parameter Type Examples

**STRING Parameters**
```json
{
  "name": "send_notification",
  "args": {
    "message": "Your order has been shipped",
    "channel": "email",  // Must match enum values if defined
    "recipient": "user@example.com"
  }
}
```

**NUMBER and INTEGER Parameters**
```json
{
  "name": "calculate_compound_interest",
  "args": {
    "principal": 10000.50,      // NUMBER type
    "rate": 0.05,               // NUMBER type  
    "periods": 12,              // INTEGER type
    "years": 5                  // INTEGER type
  }
}
```

**BOOLEAN Parameters**
```json
{
  "name": "update_user_preferences",
  "args": {
    "user_id": "user_123",
    "email_notifications": true,     // BOOLEAN type
    "sms_notifications": false,      // BOOLEAN type
    "marketing_emails": true         // BOOLEAN type
  }
}
```

**ARRAY Parameters with Different Element Types**
```json
{
  "name": "batch_process_items",
  "args": {
    "item_ids": ["item_1", "item_2", "item_3"],  // Array of strings
    "quantities": [10, 25, 5],                   // Array of integers
    "prices": [19.99, 45.50, 12.75],            // Array of numbers
    "active_flags": [true, false, true]          // Array of booleans
  }
}
```

#### 3.4.7. Design Rationale

The FunctionCall structure design emphasizes:

1. **Simplicity:** Minimal structure with only essential fields (name and args)
2. **Type Safety:** Arguments must conform to declared parameter schemas
3. **Industry Compatibility:** Aligns with Google Gemini and OpenAI function calling patterns
4. **JSON Serialization:** All arguments must be JSON-serializable for cross-language compatibility
5. **Validation Clarity:** Clear rules for parameter validation and function reference checking

#### 3.4.8. Implementation Notes

**Validation Implementation:**
```javascript
function validateFunctionCall(functionCall, tool) {
  // Find the function declaration
  const functionDecl = tool.function_declarations.find(
    decl => decl.name === functionCall.name
  );
  
  if (!functionDecl) {
    throw new Error(`Function '${functionCall.name}' not found in tool`);
  }
  
  // Validate arguments against parameter schema
  return validateSchema(functionCall.args, functionDecl.parameters);
}
```

**Common Validation Errors:**
- Function name not found in tool declarations
- Missing required parameters in args
- Parameter type mismatches (e.g., string instead of integer)
- Invalid enum values for string parameters
- Non-JSON-serializable values in args
- Additional parameters not defined in schema

**Best Practices:**
- Always validate function calls against their declarations before execution
- Provide clear error messages for validation failures
- Ensure all argument values are JSON-serializable
- Consider parameter sanitization for security
- Log function calls for debugging and audit purposes

### 3.5. ToolResult Structure

The `ToolResult` structure represents the response from a function call execution, using a discriminated union pattern to handle both successful results and error conditions in a type-safe manner. This unified structure replaces separate response and error types, providing unambiguous result handling.

#### 3.5.1. Structure Definition

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `String` | Yes | Name of the function that was invoked |
| `status` | `ResultStatus` | Yes | Execution status indicating success or failure |
| `content` | `Object` | Conditional | Result data (required when status is SUCCESS) |
| `error` | `ErrorObject` | Conditional | Error information (required when status is ERROR) |

#### 3.5.2. ResultStatus Enumeration

The `ResultStatus` enumeration defines the possible execution outcomes:

| Status | Description | Required Fields |
|--------|-------------|-----------------|
| `SUCCESS` | Function executed successfully | `content` field must be present |
| `ERROR` | Function execution failed | `error` field must be present |

#### 3.5.3. ErrorObject Structure

The `ErrorObject` provides structured error information:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `message` | `String` | Yes | Human-readable error description |
| `type` | `String` | No | Standardized error code for programmatic handling |

#### 3.5.4. Field Specifications

**name**
- **Type:** String
- **Purpose:** Identifies which function produced this result
- **Constraints:** Must match the name from the corresponding FunctionCall
- **Usage:** Enables correlation between calls and responses in batch scenarios

**status**
- **Type:** ResultStatus enumeration
- **Purpose:** Indicates whether the function execution succeeded or failed
- **Values:** Either "SUCCESS" or "ERROR"
- **Validation:** Determines which conditional fields must be present

**content** (conditional)
- **Type:** JSON-serializable object
- **Required When:** status is "SUCCESS"
- **Purpose:** Contains the actual result data from successful function execution
- **Constraints:** Must be JSON-serializable (objects, arrays, primitives, null)
- **Structure:** Can be any valid JSON structure appropriate for the function's return type

**error** (conditional)
- **Type:** ErrorObject
- **Required When:** status is "ERROR"
- **Purpose:** Provides structured error information for failed executions
- **Usage:** Enables both human-readable error messages and programmatic error handling

#### 3.5.5. ErrorObject Field Specifications

**message**
- **Type:** String
- **Purpose:** Human-readable description of what went wrong
- **Constraints:** Must be non-empty and informative
- **Best Practices:** Should be clear, actionable, and safe for AI model consumption

**type** (optional)
- **Type:** String
- **Purpose:** Standardized error code for programmatic error handling
- **Examples:** "PARAMETER_VALIDATION_FAILED", "RESOURCE_NOT_FOUND", "PERMISSION_DENIED"
- **Usage:** Enables consistent error handling across different function implementations

#### 3.5.6. Validation Rules

1. **Discriminated Union Validation:**
   - When status is "SUCCESS", the `content` field must be present and `error` field must be absent
   - When status is "ERROR", the `error` field must be present and `content` field must be absent
   - Both `content` and `error` fields cannot be present simultaneously

2. **Content Validation:**
   - Content must be JSON-serializable
   - Content can be any valid JSON type (object, array, string, number, boolean, null)
   - Complex objects should follow consistent structure patterns

3. **Error Validation:**
   - Error message must be non-empty string
   - Error type, if present, should follow consistent naming conventions
   - Error information should not expose sensitive system details

#### 3.5.7. JSON Schema Representation

```json
{
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "pattern": "^[a-zA-Z_][a-zA-Z0-9_-]{0,63}$",
      "description": "Name of the function that was invoked"
    },
    "status": {
      "type": "string",
      "enum": ["SUCCESS", "ERROR"],
      "description": "Execution status"
    },
    "content": {
      "description": "Result data (required when status is SUCCESS)"
    },
    "error": {
      "type": "object",
      "properties": {
        "message": {
          "type": "string",
          "minLength": 1,
          "description": "Human-readable error description"
        },
        "type": {
          "type": "string",
          "description": "Standardized error code"
        }
      },
      "required": ["message"],
      "additionalProperties": false,
      "description": "Error information (required when status is ERROR)"
    }
  },
  "required": ["name", "status"],
  "additionalProperties": false,
  "oneOf": [
    {
      "properties": {
        "status": { "const": "SUCCESS" }
      },
      "required": ["content"],
      "not": { "required": ["error"] }
    },
    {
      "properties": {
        "status": { "const": "ERROR" }
      },
      "required": ["error"],
      "not": { "required": ["content"] }
    }
  ]
}
```

#### 3.5.8. Examples

**Successful Function Execution with Simple Result**
```json
{
  "name": "get_current_time",
  "status": "SUCCESS",
  "content": {
    "timestamp": "2025-02-08T15:30:45Z",
    "timezone": "UTC",
    "formatted": "February 8, 2025 at 3:30 PM UTC"
  }
}
```

**Successful Function Execution with Complex Result**
```json
{
  "name": "get_weather_forecast",
  "status": "SUCCESS",
  "content": {
    "location": "San Francisco, CA",
    "current_conditions": {
      "temperature": 18,
      "humidity": 65,
      "conditions": "partly cloudy",
      "wind_speed": 12
    },
    "forecast": [
      {
        "date": "2025-02-09",
        "high": 20,
        "low": 12,
        "conditions": "sunny",
        "precipitation_chance": 10
      },
      {
        "date": "2025-02-10",
        "high": 17,
        "low": 10,
        "conditions": "cloudy",
        "precipitation_chance": 30
      },
      {
        "date": "2025-02-11",
        "high": 15,
        "low": 8,
        "conditions": "rainy",
        "precipitation_chance": 80
      }
    ],
    "units": "celsius",
    "last_updated": "2025-02-08T15:30:00Z"
  }
}
```

**Successful Function Execution with Array Result**
```json
{
  "name": "list_user_accounts",
  "status": "SUCCESS",
  "content": [
    {
      "account_id": "acc_001",
      "account_type": "checking",
      "balance": 2547.83,
      "currency": "USD",
      "status": "active"
    },
    {
      "account_id": "acc_002", 
      "account_type": "savings",
      "balance": 15230.45,
      "currency": "USD",
      "status": "active"
    },
    {
      "account_id": "acc_003",
      "account_type": "credit",
      "balance": -1205.67,
      "currency": "USD",
      "status": "active"
    }
  ]
}
```

**Successful Function Execution with Primitive Result**
```json
{
  "name": "calculate_tax",
  "status": "SUCCESS",
  "content": 1247.50
}
```

**Error Response with Basic Information**
```json
{
  "name": "get_weather_forecast",
  "status": "ERROR",
  "error": {
    "message": "Invalid location: 'Nonexistent City' could not be found in weather database",
    "type": "PARAMETER_VALIDATION_FAILED"
  }
}
```

**Error Response with Detailed Information**
```json
{
  "name": "process_financial_data",
  "status": "ERROR",
  "error": {
    "message": "Transaction validation failed: amount exceeds maximum allowed limit of $10,000.00 for transaction txn_003",
    "type": "BUSINESS_RULE_VIOLATION"
  }
}
```

**Error Response for System Failures**
```json
{
  "name": "create_support_ticket",
  "status": "ERROR",
  "error": {
    "message": "Unable to create support ticket due to temporary service unavailability. Please try again in a few minutes.",
    "type": "SERVICE_UNAVAILABLE"
  }
}
```

**Error Response for Permission Issues**
```json
{
  "name": "delete_user_account",
  "status": "ERROR",
  "error": {
    "message": "Insufficient permissions to delete user account. Admin privileges required.",
    "type": "PERMISSION_DENIED"
  }
}
```

**Error Response for Missing Resources**
```json
{
  "name": "get_user_profile",
  "status": "ERROR",
  "error": {
    "message": "User with ID 'user_999' not found",
    "type": "RESOURCE_NOT_FOUND"
  }
}
```

#### 3.5.9. Common Error Types

The following standardized error types are recommended for consistent error handling:

| Error Type | Description | Usage |
|------------|-------------|-------|
| `PARAMETER_VALIDATION_FAILED` | Input parameters failed schema validation | Invalid or missing required parameters |
| `RESOURCE_NOT_FOUND` | Requested resource does not exist | User, file, record not found |
| `PERMISSION_DENIED` | Insufficient permissions for operation | Authorization failures |
| `BUSINESS_RULE_VIOLATION` | Operation violates business logic rules | Limits exceeded, invalid state transitions |
| `SERVICE_UNAVAILABLE` | External service or dependency unavailable | Database down, API timeout |
| `RATE_LIMIT_EXCEEDED` | Too many requests in time period | API rate limiting |
| `INVALID_STATE` | Resource in invalid state for operation | Account suspended, order already shipped |
| `CONFIGURATION_ERROR` | System configuration issue | Missing API keys, invalid settings |

#### 3.5.10. Design Rationale

The ToolResult discriminated union design provides:

1. **Type Safety:** Clear distinction between success and error cases prevents parsing ambiguity
2. **Consistency:** Unified structure for all function responses simplifies handling logic
3. **Extensibility:** Error types can be standardized and extended without breaking changes
4. **Debugging:** Function name correlation enables tracing in complex execution scenarios
5. **AI-Friendly:** Structured errors provide clear feedback for AI model learning and adaptation

#### 3.5.11. Implementation Notes

**Discriminated Union Validation:**
```javascript
function validateToolResult(result) {
  if (result.status === 'SUCCESS') {
    if (!('content' in result)) {
      throw new Error('SUCCESS status requires content field');
    }
    if ('error' in result) {
      throw new Error('SUCCESS status cannot have error field');
    }
  } else if (result.status === 'ERROR') {
    if (!('error' in result)) {
      throw new Error('ERROR status requires error field');
    }
    if ('content' in result) {
      throw new Error('ERROR status cannot have content field');
    }
    if (!result.error.message || result.error.message.trim() === '') {
      throw new Error('Error message cannot be empty');
    }
  } else {
    throw new Error(`Invalid status: ${result.status}`);
  }
  
  return true;
}
```

**Type-Safe Result Handling:**
```javascript
function handleToolResult(result) {
  switch (result.status) {
    case 'SUCCESS':
      // TypeScript/strongly-typed languages can guarantee content exists
      console.log('Function succeeded:', result.content);
      return result.content;
      
    case 'ERROR':
      // TypeScript/strongly-typed languages can guarantee error exists
      console.error('Function failed:', result.error.message);
      if (result.error.type) {
        console.error('Error type:', result.error.type);
      }
      throw new Error(result.error.message);
      
    default:
      throw new Error(`Unknown result status: ${result.status}`);
  }
}
```

**Best Practices:**
- Always validate the discriminated union constraints
- Use standardized error types for consistent error handling
- Ensure error messages are informative but don't expose sensitive information
- Include function name for correlation in batch processing scenarios
- Consider implementing retry logic based on error types
- Log both successful and failed function executions for monitoring

---

**Note:** This specification supersedes and replaces all previous drafts, including any existing documentation in this directory. The structures defined herein represent the final, authoritative v1.0 specification for the ALTAR Data Model.