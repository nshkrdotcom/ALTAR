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

**JSON is the canonical serialization format** for all ADM data structures when represented in textual form. This ensures cross-language compatibility and consistent interchange between different implementations. All ADM-compliant systems must support JSON serialization and deserialization of the defined data structures.

### 2.1. JSON Serialization Requirements

The ADM specification mandates JSON as the universal serialization format to ensure language-neutral data interchange and compatibility across diverse implementation environments.

#### 2.1.1. Standard Compliance and Encoding

- **JSON Standard:** All structures must serialize to valid JSON as defined by RFC 7159 (The JavaScript Object Notation Data Interchange Format)
- **Character Encoding:** String values must use UTF-8 encoding to support international character sets and ensure consistent text representation across systems
- **Numeric Precision:** Numbers must preserve precision according to IEEE 754 double-precision floating-point format, ensuring consistent numeric representation across programming languages and platforms

#### 2.1.2. Data Type Mapping

ADM data structures use language-neutral type definitions that map consistently to JSON:

- **STRING** → JSON string with UTF-8 encoding
- **NUMBER** → JSON number (IEEE 754 double-precision)
- **INTEGER** → JSON number (64-bit signed integer range)
- **BOOLEAN** → JSON boolean (true/false)
- **ARRAY** → JSON array with homogeneous element types
- **OBJECT** → JSON object with string keys and typed values

#### 2.1.3. Validation and Constraints

- **Schema Validation:** All serialized data must conform to the declared Schema definitions
- **Type Safety:** JSON values must match their declared ADM types during deserialization
- **Range Validation:** Numeric values must fall within the valid range for their declared type (INTEGER vs NUMBER)
- **Required Fields:** All fields marked as required in Schema definitions must be present in serialized JSON

#### 2.1.4. Language-Specific Type Mappings

To ensure consistent implementation across different programming languages, the following table provides a canonical mapping from ADM's abstract types to common language-specific types. Implementers should adhere to these mappings to maintain cross-language compatibility.

| ADM Type | Python | TypeScript | Go | Notes |
|----------|--------|------------|----|-------|
| `STRING` | `str` | `string` | `string` | Should be UTF-8 encoded. |
| `NUMBER` | `float` | `number` | `float64` | Corresponds to IEEE 754 double-precision. |
| `INTEGER` | `int` | `number` | `int64` | Should support 64-bit signed integers. TypeScript's `number` can represent integers up to `Number.MAX_SAFE_INTEGER`, beyond which `bigint` may be needed. |
| `BOOLEAN` | `bool` | `boolean` | `bool` | Represents `true` or `false`. |
| `ARRAY` | `list` | `any[]` or `T[]` | `[]interface{}` or `[]T` | Represents an ordered collection of items. `T` denotes the type of the elements if homogeneous. |
| `OBJECT` | `dict` | `{[key: string]: any}` or a defined `interface` | `map[string]interface{}` or a defined `struct` | Represents a key-value map. Keys must be strings. |

### 2.2. Serialization Rules

The following rules govern how ADM data structures are serialized to and deserialized from JSON format, ensuring consistent behavior across all implementations.

#### 2.2.1. Field Ordering and Structure

- **Field Order Independence:** The order of fields in JSON objects is not semantically significant. Implementations must not rely on field ordering for correctness
- **Consistent Serialization:** While field order is not significant, implementations should maintain consistent ordering when possible for debugging and human readability
- **Nested Object Handling:** Field ordering rules apply recursively to all nested objects within the data structure

#### 2.2.2. Null Value and Optional Field Handling

- **Absent Optional Fields:** Optional fields that are not provided should be omitted from the JSON representation rather than being set to null
- **Null Value Prohibition:** ADM structures do not use null values. Missing optional data is represented by field absence
- **Required Field Enforcement:** Required fields must always be present with valid, non-null values conforming to their declared type
- **Empty Value Handling:** Empty strings, empty arrays, and empty objects are valid values when they conform to the field's schema definition

#### 2.2.3. JSON Compliance and Compatibility

- **RFC 7159 Compliance:** All serialized JSON must conform to RFC 7159 specifications for maximum compatibility
- **Unicode Support:** Full Unicode character support through UTF-8 encoding ensures international compatibility
- **Numeric Representation:** Numbers must be represented in standard JSON numeric format without scientific notation unless required for precision
- **Boolean Representation:** Boolean values must use lowercase `true` and `false` as defined in the JSON specification
- **String Escaping:** String values must properly escape special characters according to JSON string escaping rules

#### 2.2.4. Cross-Language Compatibility

- **Language-Neutral Format:** JSON serialization ensures that ADM structures can be exchanged between implementations in different programming languages
- **Type System Mapping:** Each programming language implementation must provide appropriate mappings between ADM types and native language types
- **Precision Preservation:** Numeric precision must be maintained during serialization/deserialization cycles across language boundaries
- **Validation Consistency:** Schema validation must produce consistent results regardless of the implementing language

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
- **Required:** Yes
- **Purpose:** Defines all the callable functions that this tool provides
- **Constraints:** 
  - Must contain at least one function declaration
  - All function names within the array must be unique
  - Each element must be a valid FunctionDeclaration object
- **Validation:** 
  - Array cannot be empty
  - Function name uniqueness must be enforced
  - All declarations must pass FunctionDeclaration validation
- **Extensibility:** Future versions may add additional capability types (e.g., retrieval, search) alongside function declarations
- **Structure:** Maintains order as defined, though order is not semantically significant

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

**AI Assistant Tool with Multiple Capabilities**
```json
{
  "function_declarations": [
    {
      "name": "analyze_document",
      "description": "Analyzes a document and extracts key information, entities, and insights",
      "parameters": {
        "type": "OBJECT",
        "properties": {
          "document": {
            "type": "OBJECT",
            "properties": {
              "content": {
                "type": "STRING",
                "description": "The document content to analyze"
              },
              "format": {
                "type": "STRING",
                "enum": ["text", "markdown", "html", "pdf"],
                "description": "Format of the document content"
              },
              "metadata": {
                "type": "OBJECT",
                "properties": {
                  "title": { "type": "STRING" },
                  "author": { "type": "STRING" },
                  "created_date": { "type": "STRING" },
                  "language": { "type": "STRING" }
                }
              }
            },
            "required": ["content", "format"]
          },
          "analysis_options": {
            "type": "OBJECT",
            "properties": {
              "extract_entities": {
                "type": "BOOLEAN",
                "description": "Whether to extract named entities"
              },
              "sentiment_analysis": {
                "type": "BOOLEAN",
                "description": "Whether to perform sentiment analysis"
              },
              "summarize": {
                "type": "BOOLEAN",
                "description": "Whether to generate a summary"
              },
              "key_phrases": {
                "type": "BOOLEAN",
                "description": "Whether to extract key phrases"
              },
              "language_detection": {
                "type": "BOOLEAN",
                "description": "Whether to detect document language"
              }
            }
          }
        },
        "required": ["document"]
      }
    },
    {
      "name": "generate_report",
      "description": "Generates a formatted report based on provided data and template",
      "parameters": {
        "type": "OBJECT",
        "properties": {
          "data": {
            "type": "ARRAY",
            "items": {
              "type": "OBJECT",
              "description": "Data records for the report"
            },
            "description": "Array of data objects to include in the report"
          },
          "template": {
            "type": "OBJECT",
            "properties": {
              "format": {
                "type": "STRING",
                "enum": ["pdf", "html", "markdown", "csv", "excel"],
                "description": "Output format for the report"
              },
              "sections": {
                "type": "ARRAY",
                "items": {
                  "type": "OBJECT",
                  "properties": {
                    "title": { "type": "STRING" },
                    "type": {
                      "type": "STRING",
                      "enum": ["summary", "table", "chart", "text"]
                    },
                    "data_fields": {
                      "type": "ARRAY",
                      "items": { "type": "STRING" }
                    }
                  },
                  "required": ["title", "type"]
                }
              },
              "styling": {
                "type": "OBJECT",
                "properties": {
                  "theme": {
                    "type": "STRING",
                    "enum": ["corporate", "minimal", "colorful", "academic"]
                  },
                  "include_charts": { "type": "BOOLEAN" },
                  "include_summary": { "type": "BOOLEAN" }
                }
              }
            },
            "required": ["format", "sections"]
          }
        },
        "required": ["data", "template"]
      }
    }
  ]
}
```

**Development and Testing Tool**
```json
{
  "function_declarations": [
    {
      "name": "run_test_suite",
      "description": "Executes automated test suites and returns detailed results",
      "parameters": {
        "type": "OBJECT",
        "properties": {
          "test_config": {
            "type": "OBJECT",
            "properties": {
              "suite_name": {
                "type": "STRING",
                "description": "Name of the test suite to run"
              },
              "test_types": {
                "type": "ARRAY",
                "items": {
                  "type": "STRING",
                  "enum": ["unit", "integration", "e2e", "performance", "security"]
                },
                "description": "Types of tests to include"
              },
              "parallel_execution": {
                "type": "BOOLEAN",
                "description": "Whether to run tests in parallel"
              },
              "max_workers": {
                "type": "INTEGER",
                "description": "Maximum number of parallel workers"
              },
              "timeout_seconds": {
                "type": "INTEGER",
                "description": "Timeout for individual tests in seconds"
              }
            },
            "required": ["suite_name", "test_types"]
          },
          "environment": {
            "type": "OBJECT",
            "properties": {
              "name": {
                "type": "STRING",
                "enum": ["development", "staging", "production"],
                "description": "Target environment for testing"
              },
              "variables": {
                "type": "OBJECT",
                "description": "Environment-specific variables"
              },
              "database_config": {
                "type": "OBJECT",
                "properties": {
                  "use_test_db": { "type": "BOOLEAN" },
                  "seed_data": { "type": "BOOLEAN" },
                  "cleanup_after": { "type": "BOOLEAN" }
                }
              }
            },
            "required": ["name"]
          },
          "reporting": {
            "type": "OBJECT",
            "properties": {
              "formats": {
                "type": "ARRAY",
                "items": {
                  "type": "STRING",
                  "enum": ["junit", "json", "html", "console"]
                },
                "description": "Output formats for test reports"
              },
              "include_coverage": {
                "type": "BOOLEAN",
                "description": "Whether to include code coverage metrics"
              },
              "coverage_threshold": {
                "type": "NUMBER",
                "description": "Minimum coverage percentage required"
              }
            }
          }
        },
        "required": ["test_config", "environment"]
      }
    },
    {
      "name": "deploy_application",
      "description": "Deploys application to specified environment with rollback capabilities",
      "parameters": {
        "type": "OBJECT",
        "properties": {
          "deployment": {
            "type": "OBJECT",
            "properties": {
              "application_name": { "type": "STRING" },
              "version": { "type": "STRING" },
              "environment": {
                "type": "STRING",
                "enum": ["development", "staging", "production"]
              },
              "strategy": {
                "type": "STRING",
                "enum": ["blue_green", "rolling", "canary", "recreate"]
              }
            },
            "required": ["application_name", "version", "environment", "strategy"]
          },
          "configuration": {
            "type": "OBJECT",
            "properties": {
              "replicas": { "type": "INTEGER" },
              "resources": {
                "type": "OBJECT",
                "properties": {
                  "cpu_limit": { "type": "STRING" },
                  "memory_limit": { "type": "STRING" },
                  "storage_size": { "type": "STRING" }
                }
              },
              "health_checks": {
                "type": "OBJECT",
                "properties": {
                  "readiness_probe": { "type": "STRING" },
                  "liveness_probe": { "type": "STRING" },
                  "startup_probe": { "type": "STRING" }
                }
              }
            }
          },
          "rollback_config": {
            "type": "OBJECT",
            "properties": {
              "auto_rollback": { "type": "BOOLEAN" },
              "failure_threshold": { "type": "INTEGER" },
              "previous_version": { "type": "STRING" }
            }
          }
        },
        "required": ["deployment"]
      }
    }
  ]
}
```

**IoT Device Management Tool**
```json
{
  "function_declarations": [
    {
      "name": "manage_iot_devices",
      "description": "Manages IoT devices including configuration, monitoring, and firmware updates",
      "parameters": {
        "type": "OBJECT",
        "properties": {
          "action": {
            "type": "STRING",
            "enum": ["configure", "monitor", "update_firmware", "reboot", "factory_reset"],
            "description": "Action to perform on the devices"
          },
          "device_selector": {
            "type": "OBJECT",
            "properties": {
              "device_ids": {
                "type": "ARRAY",
                "items": { "type": "STRING" },
                "description": "Specific device IDs to target"
              },
              "device_types": {
                "type": "ARRAY",
                "items": {
                  "type": "STRING",
                  "enum": ["sensor", "actuator", "gateway", "camera", "thermostat"]
                },
                "description": "Device types to target"
              },
              "locations": {
                "type": "ARRAY",
                "items": { "type": "STRING" },
                "description": "Physical locations to target"
              },
              "firmware_versions": {
                "type": "ARRAY",
                "items": { "type": "STRING" },
                "description": "Target devices with specific firmware versions"
              }
            }
          },
          "configuration": {
            "type": "OBJECT",
            "properties": {
              "settings": {
                "type": "OBJECT",
                "description": "Device-specific configuration settings"
              },
              "network": {
                "type": "OBJECT",
                "properties": {
                  "wifi_ssid": { "type": "STRING" },
                  "wifi_password": { "type": "STRING" },
                  "static_ip": { "type": "STRING" },
                  "dns_servers": {
                    "type": "ARRAY",
                    "items": { "type": "STRING" }
                  }
                }
              },
              "security": {
                "type": "OBJECT",
                "properties": {
                  "encryption_enabled": { "type": "BOOLEAN" },
                  "certificate_path": { "type": "STRING" },
                  "access_control": {
                    "type": "ARRAY",
                    "items": {
                      "type": "OBJECT",
                      "properties": {
                        "user_id": { "type": "STRING" },
                        "permissions": {
                          "type": "ARRAY",
                          "items": {
                            "type": "STRING",
                            "enum": ["read", "write", "admin", "configure"]
                          }
                        }
                      },
                      "required": ["user_id", "permissions"]
                    }
                  }
                }
              }
            }
          },
          "scheduling": {
            "type": "OBJECT",
            "properties": {
              "immediate": { "type": "BOOLEAN" },
              "scheduled_time": { "type": "STRING" },
              "maintenance_window": {
                "type": "OBJECT",
                "properties": {
                  "start_time": { "type": "STRING" },
                  "end_time": { "type": "STRING" },
                  "timezone": { "type": "STRING" }
                }
              }
            }
          }
        },
        "required": ["action", "device_selector"]
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
- **Required:** Yes
- **Purpose:** Serves as the function identifier for invocation
- **Constraints:**
  - **Content:** Must contain only alphanumeric characters (a-z, A-Z, 0-9), underscores (`_`), and dashes (`-`).
  - **Length:** Maximum of 64 characters.
  - **Start Character:** Must start with a letter or an underscore.
  - **Uniqueness:** Must be unique within the containing `Tool`.
- **Validation:** Must match the pattern `^[a-zA-Z_][a-zA-Z0-9_-]{0,63}$`
- **Examples:** `get_weather`, `create_user`, `send_email`, `calculate_tax`
- **Case Sensitivity:** Function names are case-sensitive

**description**
- **Type:** String
- **Required:** Yes
- **Purpose:** Provides context for AI models and human developers
- **Constraints:**
  - **Presence:** Must be a non-empty string (minimum 1 character after trimming whitespace).
  - **Clarity:** Should be clear, concise, and describe what the function does, not how it works.
  - **Length:** Recommended maximum of 1000 characters for readability.
- **Validation:** Cannot be null, undefined, or consist only of whitespace
- **Best Practices:** Include expected behavior, side effects, and any important limitations
- **Content Guidelines:** Should be informative enough for AI models to understand function purpose

**parameters**
- **Type:** `Schema` object
- **Required:** Yes
- **Purpose:** Defines the structure and validation rules for function input parameters
- **Constraints:** Must be a valid Schema object (typically of type "OBJECT")
- **Validation:** Must conform to all Schema validation rules
- **Note:** Even functions with no parameters must include a parameters field with an empty OBJECT schema
- **Structure:** Root schema should typically be of type "OBJECT" to define named parameters

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
- **Required:** Yes
- **Purpose:** Defines the fundamental data type for validation
- **Constraints:** Must be one of the defined SchemaType values (STRING, NUMBER, INTEGER, BOOLEAN, ARRAY, OBJECT)
- **Validation:** Must match exactly one of the enumerated values

**description**
- **Type:** String
- **Required:** No
- **Purpose:** Provides human-readable context for the data field
- **Constraints:** Should be non-empty when present
- **Best Practices:** Should be concise but informative, especially for complex nested structures
- **Usage:** Recommended for all fields to improve clarity and maintainability

**properties**
- **Type:** Map of property names to Schema objects
- **Required:** No (conditional)
- **Usage:** Required for OBJECT types that have defined properties
- **Purpose:** Defines the structure and validation rules for object properties
- **Constraints:** All values must be valid Schema objects
- **Validation:** Property names must be valid JSON object keys
- **Note:** Empty properties map indicates an object that accepts any properties

**required**
- **Type:** Array of strings
- **Required:** No
- **Usage:** Used with OBJECT types to specify mandatory properties
- **Constraints:** All strings must correspond to keys in the properties map
- **Default:** Empty array (no required properties)
- **Validation:** Cannot contain duplicate property names

**items**
- **Type:** Schema object
- **Required:** Conditional (Yes for ARRAY types)
- **Usage:** Required for ARRAY types
- **Purpose:** Defines the schema that all array elements must conform to
- **Constraints:** Must be a valid Schema object
- **Note:** Supports homogeneous arrays (all elements same type)
- **Validation:** Must be present when type is ARRAY

**enum**
- **Type:** Array of strings
- **Required:** No
- **Usage:** Used with STRING types to restrict values to a specific set
- **Purpose:** Provides enumeration constraints for string values
- **Constraints:** Must contain at least one value, all values must be unique strings
- **Validation:** Input must exactly match one of the enum values (case-sensitive)

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

// Machine learning model configuration
{
  "type": "OBJECT",
  "description": "Machine learning model training configuration",
  "properties": {
    "model": {
      "type": "OBJECT",
      "properties": {
        "architecture": {
          "type": "STRING",
          "enum": ["transformer", "cnn", "rnn", "lstm", "gru", "bert", "gpt"],
          "description": "Model architecture type"
        },
        "layers": {
          "type": "ARRAY",
          "items": {
            "type": "OBJECT",
            "properties": {
              "type": {
                "type": "STRING",
                "enum": ["dense", "conv2d", "lstm", "attention", "dropout", "batch_norm"]
              },
              "units": { "type": "INTEGER" },
              "activation": {
                "type": "STRING",
                "enum": ["relu", "sigmoid", "tanh", "softmax", "linear"]
              },
              "dropout_rate": { "type": "NUMBER" },
              "kernel_size": {
                "type": "ARRAY",
                "items": { "type": "INTEGER" }
              }
            },
            "required": ["type"]
          }
        },
        "hyperparameters": {
          "type": "OBJECT",
          "properties": {
            "learning_rate": { "type": "NUMBER" },
            "batch_size": { "type": "INTEGER" },
            "epochs": { "type": "INTEGER" },
            "optimizer": {
              "type": "STRING",
              "enum": ["adam", "sgd", "rmsprop", "adagrad"]
            },
            "loss_function": {
              "type": "STRING",
              "enum": ["mse", "mae", "categorical_crossentropy", "binary_crossentropy"]
            }
          },
          "required": ["learning_rate", "batch_size", "epochs"]
        }
      },
      "required": ["architecture", "layers", "hyperparameters"]
    },
    "data": {
      "type": "OBJECT",
      "properties": {
        "training_set": {
          "type": "OBJECT",
          "properties": {
            "path": { "type": "STRING" },
            "format": {
              "type": "STRING",
              "enum": ["csv", "json", "parquet", "tfrecord", "hdf5"]
            },
            "preprocessing": {
              "type": "ARRAY",
              "items": {
                "type": "OBJECT",
                "properties": {
                  "operation": {
                    "type": "STRING",
                    "enum": ["normalize", "standardize", "one_hot_encode", "tokenize", "resize"]
                  },
                  "parameters": { "type": "OBJECT" }
                },
                "required": ["operation"]
              }
            }
          },
          "required": ["path", "format"]
        },
        "validation_split": { "type": "NUMBER" },
        "test_split": { "type": "NUMBER" }
      },
      "required": ["training_set"]
    },
    "training": {
      "type": "OBJECT",
      "properties": {
        "early_stopping": {
          "type": "OBJECT",
          "properties": {
            "enabled": { "type": "BOOLEAN" },
            "patience": { "type": "INTEGER" },
            "monitor": {
              "type": "STRING",
              "enum": ["loss", "accuracy", "val_loss", "val_accuracy"]
            }
          }
        },
        "checkpointing": {
          "type": "OBJECT",
          "properties": {
            "enabled": { "type": "BOOLEAN" },
            "frequency": { "type": "INTEGER" },
            "save_best_only": { "type": "BOOLEAN" }
          }
        },
        "distributed": {
          "type": "OBJECT",
          "properties": {
            "enabled": { "type": "BOOLEAN" },
            "strategy": {
              "type": "STRING",
              "enum": ["mirrored", "parameter_server", "multi_worker"]
            },
            "num_workers": { "type": "INTEGER" }
          }
        }
      }
    }
  },
  "required": ["model", "data"]
}

// Complex workflow definition
{
  "type": "OBJECT",
  "description": "Automated workflow definition with conditional logic",
  "properties": {
    "workflow": {
      "type": "OBJECT",
      "properties": {
        "name": { "type": "STRING" },
        "version": { "type": "STRING" },
        "description": { "type": "STRING" },
        "triggers": {
          "type": "ARRAY",
          "items": {
            "type": "OBJECT",
            "properties": {
              "type": {
                "type": "STRING",
                "enum": ["schedule", "webhook", "file_change", "manual", "api_call"]
              },
              "config": {
                "type": "OBJECT",
                "properties": {
                  "cron_expression": { "type": "STRING" },
                  "webhook_url": { "type": "STRING" },
                  "file_patterns": {
                    "type": "ARRAY",
                    "items": { "type": "STRING" }
                  },
                  "conditions": {
                    "type": "ARRAY",
                    "items": {
                      "type": "OBJECT",
                      "properties": {
                        "field": { "type": "STRING" },
                        "operator": {
                          "type": "STRING",
                          "enum": ["equals", "not_equals", "contains", "greater_than", "less_than"]
                        },
                        "value": { "type": "STRING" }
                      },
                      "required": ["field", "operator", "value"]
                    }
                  }
                }
              }
            },
            "required": ["type", "config"]
          }
        },
        "steps": {
          "type": "ARRAY",
          "items": {
            "type": "OBJECT",
            "properties": {
              "id": { "type": "STRING" },
              "name": { "type": "STRING" },
              "type": {
                "type": "STRING",
                "enum": ["action", "condition", "loop", "parallel", "wait"]
              },
              "action": {
                "type": "OBJECT",
                "properties": {
                  "type": {
                    "type": "STRING",
                    "enum": ["http_request", "database_query", "file_operation", "email", "script"]
                  },
                  "config": { "type": "OBJECT" },
                  "timeout_seconds": { "type": "INTEGER" },
                  "retry_policy": {
                    "type": "OBJECT",
                    "properties": {
                      "max_attempts": { "type": "INTEGER" },
                      "backoff_strategy": {
                        "type": "STRING",
                        "enum": ["linear", "exponential", "fixed"]
                      },
                      "delay_seconds": { "type": "INTEGER" }
                    }
                  }
                }
              },
              "condition": {
                "type": "OBJECT",
                "properties": {
                  "expression": { "type": "STRING" },
                  "true_branch": { "type": "STRING" },
                  "false_branch": { "type": "STRING" }
                }
              },
              "dependencies": {
                "type": "ARRAY",
                "items": { "type": "STRING" },
                "description": "Step IDs that must complete before this step"
              },
              "error_handling": {
                "type": "OBJECT",
                "properties": {
                  "on_failure": {
                    "type": "STRING",
                    "enum": ["continue", "stop", "retry", "rollback"]
                  },
                  "notification": {
                    "type": "OBJECT",
                    "properties": {
                      "enabled": { "type": "BOOLEAN" },
                      "channels": {
                        "type": "ARRAY",
                        "items": {
                          "type": "STRING",
                          "enum": ["email", "slack", "webhook", "sms"]
                        }
                      },
                      "recipients": {
                        "type": "ARRAY",
                        "items": { "type": "STRING" }
                      }
                    }
                  }
                }
              }
            },
            "required": ["id", "name", "type"]
          }
        },
        "variables": {
          "type": "OBJECT",
          "description": "Global workflow variables"
        },
        "outputs": {
          "type": "ARRAY",
          "items": {
            "type": "OBJECT",
            "properties": {
              "name": { "type": "STRING" },
              "value": { "type": "STRING" },
              "type": {
                "type": "STRING",
                "enum": ["string", "number", "boolean", "object", "array"]
              }
            },
            "required": ["name", "value", "type"]
          }
        }
      },
      "required": ["name", "version", "triggers", "steps"]
    }
  },
  "required": ["workflow"]
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
- **Required:** Yes
- **Purpose:** Identifies the specific function to invoke within the tool
- **Constraints:** 
  - Must exactly match the name of a function declared in the associated Tool's function_declarations
  - Case-sensitive matching
  - Must follow the same naming rules as FunctionDeclaration names (alphanumeric, underscores, dashes, max 64 chars)
- **Validation:** Must reference an existing, valid function declaration
- **Error Handling:** Invalid function names should result in clear error messages

**args**
- **Type:** Map of string keys to JSON-serializable values
- **Required:** Yes
- **Purpose:** Provides the input parameters for the function invocation
- **Constraints:** 
  - Must conform to the parameter schema defined in the referenced FunctionDeclaration
  - All required parameters must be present
  - Parameter values must match their declared types
  - Optional parameters may be omitted
- **Serialization:** Must be JSON-serializable (strings, numbers, booleans, arrays, objects, null)
- **Validation:** Schema validation must be performed before function execution
- **Structure:** Keys must match parameter names exactly (case-sensitive)
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

**Real-World E-commerce Function Call**
```json
{
  "name": "process_order",
  "args": {
    "order": {
      "customer_id": "CUST-789123",
      "items": [
        {
          "product_id": "PROD-001",
          "quantity": 2,
          "unit_price": 29.99,
          "customizations": {
            "color": "blue",
            "size": "L",
            "engraving": "Happy Birthday!"
          }
        },
        {
          "product_id": "PROD-045",
          "quantity": 1,
          "unit_price": 149.99,
          "warranty_extension": true
        }
      ],
      "shipping": {
        "method": "express",
        "address": {
          "street": "123 Main St",
          "city": "San Francisco",
          "state": "CA",
          "zip": "94105",
          "country": "US"
        },
        "instructions": "Leave at front door"
      },
      "payment": {
        "method": "credit_card",
        "card_last_four": "1234",
        "billing_address_same": true
      },
      "promotions": [
        {
          "code": "SAVE20",
          "discount_percent": 20,
          "applied_to": ["PROD-001"]
        }
      ]
    },
    "processing_options": {
      "send_confirmation_email": true,
      "update_inventory": true,
      "create_shipping_label": true,
      "fraud_check": true
    }
  }
}
```

**AI Model Configuration Function Call**
```json
{
  "name": "configure_ai_model",
  "args": {
    "model_config": {
      "model_type": "language_model",
      "version": "v2.1",
      "parameters": {
        "temperature": 0.7,
        "max_tokens": 2048,
        "top_p": 0.9,
        "frequency_penalty": 0.1,
        "presence_penalty": 0.1
      },
      "system_prompt": "You are a helpful AI assistant specialized in technical documentation.",
      "safety_settings": {
        "content_filtering": true,
        "toxicity_threshold": 0.8,
        "bias_detection": true
      },
      "capabilities": [
        {
          "type": "text_generation",
          "enabled": true,
          "max_length": 4000
        },
        {
          "type": "code_analysis",
          "enabled": true,
          "supported_languages": ["python", "javascript", "java", "go"]
        },
        {
          "type": "document_summarization",
          "enabled": false
        }
      ]
    },
    "deployment_settings": {
      "environment": "production",
      "scaling": {
        "min_instances": 2,
        "max_instances": 10,
        "auto_scale": true
      },
      "monitoring": {
        "log_level": "info",
        "metrics_enabled": true,
        "alert_thresholds": {
          "response_time_ms": 5000,
          "error_rate_percent": 5.0
        }
      }
    }
  }
}
```

**Complex Data Analytics Function Call**
```json
{
  "name": "analyze_business_metrics",
  "args": {
    "analysis_request": {
      "metrics": [
        {
          "name": "revenue_growth",
          "type": "percentage",
          "time_period": "quarterly",
          "segments": ["product_line", "region", "customer_tier"]
        },
        {
          "name": "customer_acquisition_cost",
          "type": "currency",
          "time_period": "monthly",
          "segments": ["marketing_channel", "product_category"]
        },
        {
          "name": "churn_rate",
          "type": "percentage",
          "time_period": "monthly",
          "segments": ["subscription_type", "customer_age_group"]
        }
      ],
      "date_range": {
        "start_date": "2024-01-01",
        "end_date": "2024-12-31",
        "comparison_periods": [
          {
            "name": "previous_year",
            "start_date": "2023-01-01",
            "end_date": "2023-12-31"
          },
          {
            "name": "industry_benchmark",
            "source": "external_dataset",
            "dataset_id": "industry_saas_2024"
          }
        ]
      },
      "filters": [
        {
          "field": "customer_type",
          "operator": "in",
          "values": ["enterprise", "mid_market"]
        },
        {
          "field": "product_version",
          "operator": "greater_than_or_equal",
          "values": ["2.0"]
        }
      ],
      "aggregations": [
        {
          "type": "sum",
          "field": "revenue",
          "group_by": ["month", "product_line"]
        },
        {
          "type": "average",
          "field": "deal_size",
          "group_by": ["sales_rep", "quarter"]
        },
        {
          "type": "count_distinct",
          "field": "customer_id",
          "group_by": ["acquisition_channel"]
        }
      ]
    },
    "output_config": {
      "format": "comprehensive_report",
      "visualizations": [
        {
          "type": "line_chart",
          "metrics": ["revenue_growth"],
          "x_axis": "time_period",
          "y_axis": "percentage",
          "grouping": "product_line"
        },
        {
          "type": "bar_chart",
          "metrics": ["customer_acquisition_cost"],
          "x_axis": "marketing_channel",
          "y_axis": "cost_usd",
          "comparison": "previous_year"
        },
        {
          "type": "heatmap",
          "metrics": ["churn_rate"],
          "x_axis": "customer_tier",
          "y_axis": "month",
          "color_scale": "red_yellow_green"
        }
      ],
      "statistical_tests": [
        {
          "type": "t_test",
          "hypothesis": "revenue_growth_significant",
          "confidence_level": 0.95
        },
        {
          "type": "correlation_analysis",
          "variables": ["marketing_spend", "customer_acquisition_cost"],
          "method": "pearson"
        }
      ],
      "export_formats": ["pdf", "excel", "json"],
      "include_raw_data": false,
      "executive_summary": true
    }
  }
}
```

**Multi-Cloud Infrastructure Management Function Call**
```json
{
  "name": "manage_cloud_infrastructure",
  "args": {
    "operation": "deploy_multi_region",
    "infrastructure": {
      "application": {
        "name": "web-app-prod",
        "version": "v2.3.1",
        "architecture": "microservices",
        "components": [
          {
            "name": "api-gateway",
            "type": "load_balancer",
            "replicas": 3,
            "resources": {
              "cpu": "2 cores",
              "memory": "4GB",
              "storage": "50GB SSD"
            },
            "auto_scaling": {
              "enabled": true,
              "min_replicas": 2,
              "max_replicas": 10,
              "cpu_threshold": 70,
              "memory_threshold": 80
            }
          },
          {
            "name": "user-service",
            "type": "microservice",
            "replicas": 5,
            "resources": {
              "cpu": "1 core",
              "memory": "2GB",
              "storage": "20GB SSD"
            },
            "database": {
              "type": "postgresql",
              "version": "14.2",
              "instance_class": "db.r5.large",
              "storage": "100GB",
              "backup_retention": 7,
              "multi_az": true
            }
          },
          {
            "name": "notification-service",
            "type": "microservice",
            "replicas": 3,
            "resources": {
              "cpu": "0.5 cores",
              "memory": "1GB",
              "storage": "10GB SSD"
            },
            "message_queue": {
              "type": "rabbitmq",
              "instance_type": "mq.m5.large",
              "durability": true,
              "clustering": true
            }
          }
        ]
      },
      "regions": [
        {
          "name": "us-east-1",
          "provider": "aws",
          "primary": true,
          "availability_zones": ["us-east-1a", "us-east-1b", "us-east-1c"],
          "network": {
            "vpc_cidr": "10.0.0.0/16",
            "public_subnets": ["10.0.1.0/24", "10.0.2.0/24"],
            "private_subnets": ["10.0.10.0/24", "10.0.20.0/24"],
            "nat_gateway": true,
            "internet_gateway": true
          }
        },
        {
          "name": "europe-west1",
          "provider": "gcp",
          "primary": false,
          "availability_zones": ["europe-west1-a", "europe-west1-b"],
          "network": {
            "vpc_cidr": "10.1.0.0/16",
            "public_subnets": ["10.1.1.0/24", "10.1.2.0/24"],
            "private_subnets": ["10.1.10.0/24", "10.1.20.0/24"],
            "cloud_nat": true
          }
        }
      ],
      "security": {
        "encryption": {
          "at_rest": true,
          "in_transit": true,
          "key_management": "cloud_kms"
        },
        "network_policies": [
          {
            "name": "api-gateway-ingress",
            "type": "ingress",
            "ports": [80, 443],
            "sources": ["0.0.0.0/0"],
            "protocols": ["tcp"]
          },
          {
            "name": "internal-services",
            "type": "ingress",
            "ports": [8080, 9090],
            "sources": ["10.0.0.0/8"],
            "protocols": ["tcp"]
          }
        ],
        "identity_access": {
          "rbac_enabled": true,
          "service_accounts": [
            {
              "name": "api-gateway-sa",
              "permissions": ["read_secrets", "write_logs"]
            },
            {
              "name": "user-service-sa",
              "permissions": ["read_database", "write_database", "read_secrets"]
            }
          ]
        }
      },
      "monitoring": {
        "metrics": {
          "enabled": true,
          "retention_days": 30,
          "custom_metrics": [
            {
              "name": "api_response_time",
              "type": "histogram",
              "labels": ["endpoint", "method", "status_code"]
            },
            {
              "name": "active_users",
              "type": "gauge",
              "labels": ["region", "service"]
            }
          ]
        },
        "logging": {
          "enabled": true,
          "level": "info",
          "structured": true,
          "retention_days": 90
        },
        "alerting": {
          "rules": [
            {
              "name": "high_error_rate",
              "condition": "error_rate > 5%",
              "duration": "5m",
              "severity": "critical",
              "notifications": ["pagerduty", "slack"]
            },
            {
              "name": "high_latency",
              "condition": "p95_latency > 2s",
              "duration": "10m",
              "severity": "warning",
              "notifications": ["slack"]
            }
          ]
        }
      }
    },
    "deployment_strategy": {
      "type": "blue_green",
      "rollback_enabled": true,
      "health_checks": {
        "readiness_probe": "/health/ready",
        "liveness_probe": "/health/live",
        "startup_probe": "/health/startup",
        "timeout_seconds": 30,
        "failure_threshold": 3
      },
      "traffic_splitting": {
        "enabled": true,
        "initial_percentage": 10,
        "increment_percentage": 25,
        "increment_interval_minutes": 15
      }
    }
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
- **Required:** Yes
- **Purpose:** Identifies which function produced this result
- **Constraints:**
  - **Matching:** Must exactly match the `name` from the corresponding `FunctionCall` (case-sensitive).
  - **Validity:** Must be a non-empty string corresponding to a valid function name.
- **Usage:** Enables correlation between calls and responses in batch scenarios.

**status**
- **Type:** `ResultStatus` enumeration
- **Required:** Yes
- **Purpose:** Indicates whether the function execution succeeded or failed.
- **Constraints:**
  - **Value:** Must be one of the `ResultStatus` enumeration values (`SUCCESS` or `ERROR`).
  - **Implication:** Determines which of the conditional fields (`content` or `error`) must be present.

**content** (conditional)
- **Type:** JSON-serializable object
- **Required:** Conditional (Yes when `status` is `SUCCESS`)
- **Purpose:** Contains the actual result data from successful function execution.
- **Constraints:**
  - **Presence:** Required if `status` is `SUCCESS`; must be absent if `status` is `ERROR`.
  - **Format:** Must be a JSON-serializable object, array, primitive, or null.
  - **Size:** Should be of a reasonable size for transport and processing (implementation-dependent).

**error** (conditional)
- **Type:** `ErrorObject`
- **Required:** Conditional (Yes when `status` is `ERROR`)
- **Purpose:** Provides structured error information for failed executions.
- **Constraints:**
  - **Presence:** Required if `status` is `ERROR`; must be absent if `status` is `SUCCESS`.
  - **Structure:** Must be a valid `ErrorObject`.

#### 3.5.5. ErrorObject Field Specifications

**message**
- **Type:** String
- **Required:** Yes
- **Purpose:** Human-readable description of what went wrong.
- **Constraints:**
  - **Presence:** Must be a non-empty and informative string (minimum 1 character after trimming whitespace).
  - **Security:** Should not expose sensitive system information or internal implementation details.
  - **Length:** Recommended maximum of 500 characters for practical display purposes.
- **Best Practices:** Should be clear, actionable, and safe for AI model consumption.

**type**
- **Type:** String
- **Required:** No
- **Purpose:** Standardized error code for programmatic error handling.
- **Constraints:**
  - **Format:** Should follow a consistent naming convention (e.g., `UPPER_SNAKE_CASE`) when present.
  - **Extensibility:** New error types can be added without breaking existing implementations.
- **Examples:** `PARAMETER_VALIDATION_FAILED`, `RESOURCE_NOT_FOUND`, `PERMISSION_DENIED`
- **Usage:** Enables consistent error handling across different function implementations.

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

**Successful Function Execution with Nested Object Result**
```json
{
  "name": "analyze_document",
  "status": "SUCCESS",
  "content": {
    "summary": "This document discusses quarterly financial performance with positive growth trends.",
    "entities": [
      {
        "text": "Q3 2024",
        "type": "DATE",
        "confidence": 0.95
      },
      {
        "text": "Microsoft Corporation",
        "type": "ORGANIZATION",
        "confidence": 0.98
      }
    ],
    "sentiment": {
      "overall": "positive",
      "confidence": 0.87,
      "scores": {
        "positive": 0.72,
        "neutral": 0.21,
        "negative": 0.07
      }
    },
    "key_phrases": [
      "revenue growth",
      "market expansion",
      "customer satisfaction"
    ],
    "language": {
      "detected": "en",
      "confidence": 0.99
    },
    "metadata": {
      "word_count": 1247,
      "reading_time_minutes": 5,
      "complexity_score": "intermediate"
    }
  }
}
```

**Successful Function Execution with Mixed Data Types**
```json
{
  "name": "generate_report",
  "status": "SUCCESS",
  "content": {
    "report_id": "RPT-2024-001",
    "generated_at": "2024-02-15T10:30:00Z",
    "format": "pdf",
    "file_size_bytes": 2048576,
    "pages": 15,
    "sections": [
      {
        "title": "Executive Summary",
        "page_range": [1, 2],
        "charts_included": false
      },
      {
        "title": "Financial Analysis",
        "page_range": [3, 8],
        "charts_included": true,
        "chart_types": ["bar", "line", "pie"]
      },
      {
        "title": "Recommendations",
        "page_range": [9, 15],
        "charts_included": false
      }
    ],
    "download_url": "https://reports.example.com/download/RPT-2024-001.pdf",
    "expires_at": "2024-02-22T10:30:00Z",
    "access_permissions": {
      "public": false,
      "requires_authentication": true,
      "allowed_users": ["user_123", "user_456"]
    }
  }
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

**Error Response for Rate Limiting**
```json
{
  "name": "send_email",
  "status": "ERROR",
  "error": {
    "message": "Rate limit exceeded: maximum 100 emails per hour. Try again in 45 minutes.",
    "type": "RATE_LIMIT_EXCEEDED"
  }
}
```

**Error Response for Configuration Issues**
```json
{
  "name": "backup_database",
  "status": "ERROR",
  "error": {
    "message": "Database backup failed: S3 credentials not configured or invalid",
    "type": "CONFIGURATION_ERROR"
  }
}
```

**Error Response for Invalid State**
```json
{
  "name": "cancel_order",
  "status": "ERROR",
  "error": {
    "message": "Cannot cancel order ORD-12345: order has already been shipped",
    "type": "INVALID_STATE"
  }
}
```

**Successful Complex Analytics Result**
```json
{
  "name": "analyze_business_metrics",
  "status": "SUCCESS",
  "content": {
    "analysis_id": "ANALYSIS-2024-001",
    "generated_at": "2024-02-15T14:30:00Z",
    "time_period": {
      "start_date": "2024-01-01",
      "end_date": "2024-12-31",
      "total_days": 366
    },
    "metrics_summary": {
      "revenue_growth": {
        "current_period": 23.5,
        "previous_period": 18.2,
        "change": 5.3,
        "trend": "increasing",
        "statistical_significance": 0.95
      },
      "customer_acquisition_cost": {
        "current_period": 245.67,
        "previous_period": 289.34,
        "change": -43.67,
        "trend": "decreasing",
        "by_channel": {
          "organic": 89.23,
          "paid_search": 312.45,
          "social_media": 198.76,
          "referral": 156.89
        }
      },
      "churn_rate": {
        "current_period": 4.2,
        "previous_period": 5.8,
        "change": -1.6,
        "trend": "improving",
        "by_segment": {
          "enterprise": 2.1,
          "mid_market": 4.8,
          "small_business": 6.7
        }
      }
    },
    "detailed_analysis": {
      "top_performing_segments": [
        {
          "segment": "enterprise_customers",
          "metric": "revenue_growth",
          "value": 34.2,
          "contribution_percent": 67.8
        },
        {
          "segment": "product_line_premium",
          "metric": "profit_margin",
          "value": 42.1,
          "contribution_percent": 23.4
        }
      ],
      "areas_of_concern": [
        {
          "segment": "small_business",
          "metric": "churn_rate",
          "value": 6.7,
          "threshold": 5.0,
          "recommendation": "Implement targeted retention campaigns"
        }
      ],
      "correlations": [
        {
          "variables": ["marketing_spend", "customer_acquisition_cost"],
          "correlation_coefficient": -0.73,
          "p_value": 0.002,
          "interpretation": "Strong negative correlation - increased marketing spend reduces CAC"
        }
      ]
    },
    "visualizations": [
      {
        "type": "line_chart",
        "title": "Revenue Growth Trend",
        "data_url": "https://analytics.example.com/charts/revenue_growth_2024.png",
        "interactive_url": "https://analytics.example.com/interactive/revenue_growth_2024"
      },
      {
        "type": "heatmap",
        "title": "Churn Rate by Segment and Month",
        "data_url": "https://analytics.example.com/charts/churn_heatmap_2024.png"
      }
    ],
    "recommendations": [
      {
        "priority": "high",
        "category": "customer_retention",
        "description": "Focus retention efforts on small business segment",
        "expected_impact": "Reduce churn by 1.5-2.0 percentage points",
        "implementation_timeline": "3-6 months"
      },
      {
        "priority": "medium",
        "category": "marketing_optimization",
        "description": "Increase investment in organic and referral channels",
        "expected_impact": "Reduce overall CAC by 15-20%",
        "implementation_timeline": "2-4 months"
      }
    ],
    "export_links": {
      "pdf_report": "https://reports.example.com/business_metrics_2024.pdf",
      "excel_data": "https://reports.example.com/business_metrics_2024.xlsx",
      "raw_json": "https://api.example.com/analytics/raw_data/ANALYSIS-2024-001"
    }
  }
}
```

**Successful Infrastructure Deployment Result**
```json
{
  "name": "manage_cloud_infrastructure",
  "status": "SUCCESS",
  "content": {
    "deployment_id": "DEPLOY-2024-0215-001",
    "status": "completed",
    "started_at": "2024-02-15T10:00:00Z",
    "completed_at": "2024-02-15T10:45:32Z",
    "duration_minutes": 45.53,
    "regions_deployed": [
      {
        "region": "us-east-1",
        "provider": "aws",
        "status": "healthy",
        "components": [
          {
            "name": "api-gateway",
            "status": "running",
            "replicas": {
              "desired": 3,
              "running": 3,
              "ready": 3
            },
            "endpoints": [
              "https://api-prod-us-east-1.example.com"
            ],
            "health_check": {
              "status": "passing",
              "last_check": "2024-02-15T10:44:00Z",
              "response_time_ms": 45
            }
          },
          {
            "name": "user-service",
            "status": "running",
            "replicas": {
              "desired": 5,
              "running": 5,
              "ready": 5
            },
            "database": {
              "status": "available",
              "endpoint": "user-db-prod.cluster-xyz.us-east-1.rds.amazonaws.com",
              "connections": {
                "active": 12,
                "max": 100
              }
            }
          },
          {
            "name": "notification-service",
            "status": "running",
            "replicas": {
              "desired": 3,
              "running": 3,
              "ready": 3
            },
            "message_queue": {
              "status": "available",
              "messages_in_queue": 0,
              "consumers_connected": 3
            }
          }
        ],
        "network": {
          "vpc_id": "vpc-0123456789abcdef0",
          "load_balancer": {
            "dns_name": "prod-lb-123456789.us-east-1.elb.amazonaws.com",
            "status": "active",
            "target_health": "healthy"
          }
        },
        "monitoring": {
          "dashboard_url": "https://monitoring.example.com/dashboard/us-east-1",
          "alerts_configured": 15,
          "metrics_collecting": true
        }
      },
      {
        "region": "europe-west1",
        "provider": "gcp",
        "status": "healthy",
        "components": [
          {
            "name": "api-gateway",
            "status": "running",
            "replicas": {
              "desired": 3,
              "running": 3,
              "ready": 3
            },
            "endpoints": [
              "https://api-prod-europe-west1.example.com"
            ]
          }
        ],
        "network": {
          "vpc_id": "projects/example-prod/global/networks/prod-vpc-eu",
          "load_balancer": {
            "ip_address": "34.102.136.180",
            "status": "active"
          }
        }
      }
    ],
    "traffic_distribution": {
      "us-east-1": {
        "percentage": 70,
        "requests_per_minute": 1250
      },
      "europe-west1": {
        "percentage": 30,
        "requests_per_minute": 535
      }
    },
    "security": {
      "certificates": {
        "status": "valid",
        "expires_at": "2025-02-15T00:00:00Z",
        "auto_renewal": true
      },
      "network_policies": {
        "applied": 8,
        "status": "enforced"
      },
      "encryption": {
        "at_rest": "enabled",
        "in_transit": "enabled",
        "key_rotation": "automatic"
      }
    },
    "cost_estimate": {
      "monthly_usd": 2847.50,
      "breakdown": {
        "compute": 1650.00,
        "storage": 245.00,
        "network": 312.50,
        "database": 485.00,
        "monitoring": 155.00
      }
    },
    "next_steps": [
      "Configure automated backups",
      "Set up disaster recovery procedures",
      "Schedule security audit",
      "Optimize resource allocation based on usage patterns"
    ]
  }
}
```

**Error Response for Complex Validation Failure**
```json
{
  "name": "manage_cloud_infrastructure",
  "status": "ERROR",
  "error": {
    "message": "Infrastructure deployment failed: Multiple validation errors detected in configuration",
    "type": "PARAMETER_VALIDATION_FAILED",
    "details": {
      "validation_errors": [
        {
          "field": "regions[0].network.vpc_cidr",
          "error": "CIDR block 10.0.0.0/16 overlaps with existing VPC in region us-east-1",
          "suggested_value": "10.2.0.0/16"
        },
        {
          "field": "infrastructure.components[1].database.instance_class",
          "error": "Instance class 'db.r5.large' not available in region europe-west1",
          "available_options": ["db.n1-standard-2", "db.n1-standard-4", "db.n1-highmem-2"]
        },
        {
          "field": "security.network_policies[0].sources",
          "error": "Source IP range '0.0.0.0/0' violates security policy for production environments",
          "recommendation": "Use specific IP ranges or implement WAF"
        }
      ],
      "warnings": [
        {
          "field": "infrastructure.components[0].auto_scaling.max_replicas",
          "warning": "Maximum replicas (10) may exceed regional quota limits",
          "current_quota": 8,
          "recommendation": "Request quota increase or reduce max_replicas to 8"
        }
      ],
      "failed_at_stage": "pre_deployment_validation",
      "rollback_required": false
    }
  }
}
```

**Error Response for Service Dependency Failure**
```json
{
  "name": "analyze_business_metrics",
  "status": "ERROR",
  "error": {
    "message": "Analysis failed due to data warehouse connection timeout after 30 seconds",
    "type": "SERVICE_UNAVAILABLE",
    "details": {
      "service": "data_warehouse",
      "endpoint": "analytics-db.internal.example.com:5432",
      "error_code": "CONNECTION_TIMEOUT",
      "retry_after_seconds": 300,
      "alternative_actions": [
        "Use cached data from last successful run (2 hours old)",
        "Run analysis on subset of data from backup source",
        "Schedule analysis for later execution when service is restored"
      ],
      "incident_id": "INC-2024-0215-003",
      "estimated_resolution": "2024-02-15T16:00:00Z"
    }
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

## 4. Protocol Versioning and Evolution

### 4.1. Versioning Strategy

The ALTAR Data Model (ADM) follows a semantic versioning approach to ensure predictable evolution while maintaining backward compatibility across the ecosystem. This strategy provides clear guidelines for implementers and consumers of the specification.

#### 4.1.1. Semantic Versioning

The ADM uses semantic versioning (SemVer) with the format `MAJOR.MINOR.PATCH`:

- **MAJOR version** (X.0.0): Incremented for incompatible changes that break existing implementations
- **MINOR version** (0.X.0): Incremented for backward-compatible functionality additions
- **PATCH version** (0.0.X): Incremented for backward-compatible bug fixes and clarifications

**Current Version:** 1.0.0

#### 4.1.2. Version Compatibility Matrix

| Version Change | Compatibility | Description | Examples |
|----------------|---------------|-------------|----------|
| PATCH (1.0.0 → 1.0.1) | Full backward compatibility | Documentation clarifications, typo fixes, example improvements | Correcting field descriptions, adding usage examples |
| MINOR (1.0.0 → 1.1.0) | Backward compatible | New optional fields, additional enum values, new data structures | Adding optional metadata fields, new SchemaType values |
| MAJOR (1.0.0 → 2.0.0) | Breaking changes | Required field changes, field removals, type changes | Changing required fields, removing deprecated structures |

#### 4.1.3. Backward Compatibility Guarantees

**PATCH Version Guarantees:**
- All existing data structures remain unchanged
- All field definitions remain identical
- All validation rules remain consistent
- All JSON serialization formats remain compatible
- Documentation improvements and clarifications only

**MINOR Version Guarantees:**
- All existing required fields remain required with same types
- All existing optional fields remain optional with same types
- New optional fields may be added to existing structures
- New data structures may be introduced
- New enum values may be added (with proper default handling)
- All existing JSON serialization remains valid

**MAJOR Version Changes:**
- May modify or remove existing required fields
- May change field types or validation rules
- May remove deprecated data structures
- May introduce incompatible serialization changes
- Requires explicit migration planning

#### 4.1.4. Deprecation and Migration Policies

**Deprecation Process:**
1. **Announcement:** Deprecated features are marked in documentation with deprecation notices
2. **Grace Period:** Minimum of one MAJOR version cycle before removal
3. **Migration Guide:** Detailed migration instructions provided for all breaking changes
4. **Tooling Support:** Where possible, automated migration tools are provided

**Deprecation Timeline:**
- **Version N.x.x:** Feature marked as deprecated with migration guidance
- **Version (N+1).0.0:** Deprecated feature may be removed with breaking change notice
- **Minimum Support:** Deprecated features supported for at least 12 months

**Migration Support:**
- **Documentation:** Comprehensive migration guides for each major version
- **Examples:** Before/after examples showing migration patterns
- **Validation:** Tools to validate compatibility between versions
- **Testing:** Reference test suites to verify migration correctness

#### 4.1.5. Version Declaration and Discovery

**Specification Versioning:**
- Each specification document includes version information in the header
- Version follows the format: "ALTAR Data Model (ADM) Specification vX.Y.Z"
- Status field indicates: Draft, Release Candidate, Final, Deprecated

**Implementation Versioning:**
- Implementations should declare their supported ADM version
- Version compatibility should be validated at runtime when possible
- Cross-version compatibility should be handled gracefully

**Version Negotiation:**
- Higher-layer protocols (LATER, GRID) may implement version negotiation
- Implementations should support the highest mutually compatible version
- Fallback to lower versions should maintain functional compatibility

#### 4.1.6. Change Management Process

**Specification Changes:**
1. **Proposal:** Changes proposed through formal specification process
2. **Review:** Community and maintainer review of proposed changes
3. **Classification:** Changes classified as PATCH, MINOR, or MAJOR
4. **Implementation:** Reference implementation updated
5. **Testing:** Comprehensive testing including backward compatibility
6. **Release:** Version released with detailed changelog

**Breaking Change Requirements:**
- **Justification:** Clear rationale for why breaking change is necessary
- **Impact Assessment:** Analysis of affected implementations and users
- **Migration Path:** Detailed migration instructions and tooling
- **Timeline:** Minimum notice period before breaking change takes effect

**Community Input:**
- **RFC Process:** Request for Comments for significant changes
- **Feedback Period:** Minimum 30-day comment period for major changes
- **Stakeholder Review:** Input from LATER and GRID protocol maintainers
- **Implementation Feedback:** Testing and feedback from reference implementations

### 4.2. Extension Points and Future Evolution

The ADM specification is designed with strategic extension points that enable future enhancements while maintaining backward compatibility. These extension points provide controlled expansion paths for new capabilities without disrupting existing implementations.

#### 4.2.1. Structural Extension Points

**Tool Structure Extensions:**
The `Tool` structure is designed for extensibility beyond function declarations:

```json
{
  "function_declarations": [...],
  // Future extension points:
  "retrieval_declarations": [...],    // Future: Document/data retrieval capabilities
  "search_declarations": [...],       // Future: Search and indexing capabilities
  "workflow_declarations": [...],     // Future: Multi-step workflow definitions
  "metadata": {                       // Future: Tool metadata and annotations
    "version": "1.0.0",
    "author": "...",
    "tags": [...],
    "capabilities": [...]
  }
}
```

**Schema Type System Extensions:**
The `SchemaType` enumeration can be extended with new types:

```json
{
  "type": "DATETIME",     // Future: Native datetime support
  "type": "BINARY",       // Future: Binary data support
  "type": "REFERENCE",    // Future: Cross-schema references
  "type": "UNION",        // Future: Union type support
  "type": "TUPLE"         // Future: Fixed-length array with mixed types
}
```

**ToolResult Extensions:**
The discriminated union pattern supports additional result types:

```json
{
  "name": "function_name",
  "status": "PARTIAL",    // Future: Partial success status
  "status": "STREAMING",  // Future: Streaming response support
  "content": {...},
  "metadata": {           // Future: Execution metadata
    "execution_time": 150,
    "resource_usage": {...},
    "warnings": [...]
  }
}
```

#### 4.2.2. Reserved Fields and Namespaces

**Reserved Field Names:**
The following field names are reserved for future use across all data structures:

- `_adm_*`: Reserved for ADM specification metadata
- `_version`: Reserved for structure-level versioning
- `_extensions`: Reserved for implementation-specific extensions
- `_metadata`: Reserved for system-generated metadata
- `_deprecated`: Reserved for deprecation markers
- `_experimental`: Reserved for experimental features

**Namespace Conventions:**
- **Core ADM:** No prefix (current specification)
- **LATER Protocol:** `later_*` prefix for LATER-specific extensions
- **GRID Protocol:** `grid_*` prefix for GRID-specific extensions
- **Vendor Extensions:** `vendor_name_*` prefix for vendor-specific additions
- **Experimental:** `x_*` prefix for experimental features

#### 4.2.3. Extension Guidelines

**Backward Compatibility Requirements:**
1. **Additive Only:** Extensions must only add new optional fields or structures
2. **Default Behavior:** Missing extension fields must have sensible default behavior
3. **Graceful Degradation:** Implementations must function without understanding extensions
4. **Validation Tolerance:** Unknown fields should be ignored, not cause validation failures

**Extension Design Principles:**
1. **Minimal Impact:** Extensions should not affect core ADM functionality
2. **Clear Semantics:** Extension behavior must be well-defined and documented
3. **Implementation Optional:** Extensions should be optional for basic ADM compliance
4. **Composability:** Extensions should work together without conflicts

**Extension Documentation Requirements:**
1. **Specification:** Formal specification document for each extension
2. **Examples:** Comprehensive examples showing extension usage
3. **Migration:** Clear migration path from non-extended to extended versions
4. **Testing:** Test suites validating extension behavior and compatibility

#### 4.2.4. Future Capability Roadmap

**Planned Extensions (Future Versions):**

**v1.1.0 - Enhanced Metadata:**
- Tool metadata and versioning support
- Function deprecation markers
- Usage analytics hooks
- Performance hints and constraints

**v1.2.0 - Advanced Type System:**
- Union types for flexible parameter schemas
- Conditional schemas based on other parameters
- Cross-reference support between schemas
- Enhanced validation constraints

**v1.3.0 - Streaming and Async Support:**
- Streaming response indicators
- Asynchronous execution markers
- Progress reporting structures
- Cancellation support

**v2.0.0 - Multi-Modal Capabilities:**
- Non-function tool types (retrieval, search)
- Binary data type support
- Media type handling
- Workflow composition primitives

#### 4.2.5. Implementation Extension Guidelines

**Custom Extensions:**
Implementations may add custom extensions following these guidelines:

```json
{
  "function_declarations": [...],
  "x_custom_metadata": {              // Experimental prefix
    "implementation": "my-tool-v1.0",
    "custom_features": [...]
  },
  "vendor_acme_config": {             // Vendor-specific prefix
    "acme_specific_setting": "value"
  }
}
```

**Extension Validation:**
- Core ADM validation must pass regardless of extensions
- Extension-specific validation should be separate and optional
- Unknown extensions should be preserved during serialization/deserialization
- Extension conflicts should be detected and reported

**Extension Discovery:**
- Implementations should declare supported extensions
- Extension capabilities should be discoverable at runtime
- Version compatibility should include extension compatibility
- Fallback behavior should be defined for unsupported extensions

#### 4.2.6. Compatibility During Evolution

**Forward Compatibility:**
- Current implementations should handle future extensions gracefully
- Unknown fields should be preserved and ignored
- Core functionality should remain unaffected by extensions
- Serialization should maintain unknown fields

**Backward Compatibility:**
- New versions should support older data formats
- Extension removal should follow deprecation process
- Migration tools should handle extension changes
- Legacy support should be maintained for reasonable periods

**Cross-Protocol Compatibility:**
- Extensions should consider LATER and GRID protocol needs
- Protocol-specific extensions should not conflict with core ADM
- Extension namespacing should prevent cross-protocol conflicts
- Shared extensions should be promoted to core ADM when appropriate

## 5. Conclusion

The ALTAR Data Model (ADM) v1.0 specification provides a robust, language-agnostic foundation for defining and interacting with AI tools. By establishing a universal contract for data structures, the ADM ensures seamless interoperability across the ALTAR ecosystem, from local development with the LATER protocol to distributed production environments with the GRID protocol.

This document serves as the authoritative v1.0 reference for all ADM implementations. Adherence to this specification is essential for ensuring that tools are portable, compatible, and can evolve gracefully within the broader ALTAR architecture.

---

**Note:** This specification supersedes and replaces all previous drafts, including any existing documentation in this directory. The structures defined herein represent the final, authoritative v1.0 specification for the ALTAR Data Model.