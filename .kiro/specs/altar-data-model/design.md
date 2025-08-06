# ALTAR Data Model (ADM) v1.0 Design Document

**Version:** 1.0.0
**Status:** Final

## Overview

The ALTAR Data Model (ADM) v1.0 specification defines the foundational, language-agnostic data structures for AI tools and their interactions within the ALTAR ecosystem. This design synthesizes proven patterns from industry-leading LLM function calling APIs, particularly Google Gemini and OpenAI, while maintaining strict separation from execution and transport concerns.

The ADM serves as the universal contract that enables seamless interoperability between the LATER (Local Agent & Tool Execution Runtime) protocol for in-process tool execution and the GRID protocol for distributed tool orchestration. By establishing this common foundation, the ADM ensures that tools defined in one context can be seamlessly promoted or migrated to another without structural changes.

## Architecture

### Three-Layer Architecture Alignment

The ADM occupies the foundational layer of the ALTAR ecosystem's three-layer architecture:

```mermaid
graph TB
    subgraph "ALTAR Ecosystem Architecture"
        subgraph "Layer 3: GRID Protocol"
            GRID[Distributed Tool Orchestration<br/>Host-Runtime Communication<br/>Enterprise Security & Observability]
        end
        
        subgraph "Layer 2: LATER Protocol"
            LATER[Local Tool Execution<br/>In-Process Function Calls<br/>Development & Prototyping]
        end
        
        subgraph "Layer 1: ADM (This Specification)"
            ADM[Universal Data Structures<br/>Tool Definitions & Schemas<br/>Function Call Contracts]
        end
    end
    
    GRID --> ADM
    LATER --> ADM
    
    style ADM fill:#4338ca,stroke:#3730a3,color:#ffffff
    style LATER fill:#34d399,stroke:#25a274,color:#ffffff
    style GRID fill:#f59e0b,stroke:#d97706,color:#ffffff
```

### Design Principles

1. **Industry Compatibility**: Data structures directly align with Google Gemini's function calling API and OpenAPI 3.0 specifications
2. **Structural Purity**: No execution, transport, or session management concerns
3. **Language Neutrality**: Definitions use universal types that map to any programming language
4. **Extensibility**: Forward-compatible design allowing future enhancements
5. **Precision**: Unambiguous specifications preventing implementation inconsistencies

### Core Data Flow

The ADM defines the complete data flow for AI tool interactions:

```mermaid
sequenceDiagram
    participant AI as AI Model
    participant System as Host System
    participant Tool as Tool Implementation
    
    Note over AI,Tool: 1. Tool Discovery Phase
    System->>AI: Tool (with FunctionDeclarations)
    
    Note over AI,Tool: 2. Tool Invocation Phase
    AI->>System: FunctionCall (name + args)
    System->>Tool: Execute with validated parameters
    
    Note over AI,Tool: 3. Response Phase
    alt Success
        Tool->>System: Execution Result
        System->>AI: FunctionResponse (with content)
    else Failure
        Tool->>System: Execution Error
        System->>AI: ErrorResponse (with error details)
    end
```

## Components and Interfaces

### Data Structure Hierarchy

The ADM defines a hierarchical set of data structures, each serving a specific role in the tool interaction lifecycle:

```mermaid
classDiagram
    class Tool {
        +function_declarations: FunctionDeclaration[]
    }
    
    class FunctionDeclaration {
        +name: String
        +description: String
        +parameters: Schema
    }
    
    class Schema {
        +type: SchemaType
        +description: String
        +properties: Map~String,Schema~
        +required: String[]
        +items: Schema
        +enum: String[]
    }
    
    class SchemaType {
        <<enumeration>>
        STRING
        NUMBER
        INTEGER
        BOOLEAN
        ARRAY
        OBJECT
    }
    
    class FunctionCall {
        +name: String
        +args: Map~String,Any~
    }
    
    class ToolResult {
        +name: String
        +status: ResultStatus
        +content: Object
        +error: ErrorObject
    }
    
    class ResultStatus {
        <<enumeration>>
        SUCCESS
        ERROR
    }
    
    class ErrorObject {
        +message: String
        +type: String
    }
    
    Tool --> FunctionDeclaration
    FunctionDeclaration --> Schema
    Schema --> SchemaType
    Schema --> Schema : recursive
    FunctionCall ..> FunctionDeclaration : references
    ToolResult ..> FunctionCall : responds to
    ToolResult --> ResultStatus
    ToolResult --> ErrorObject
```

### Type System Design

The ADM implements a robust type system based on OpenAPI 3.0 specifications:

#### Primitive Types
- **STRING**: UTF-8 encoded text with optional enumeration constraints
- **NUMBER**: IEEE 754 double-precision floating-point numbers
- **INTEGER**: 64-bit signed integers
- **BOOLEAN**: True/false values

#### Complex Types
- **ARRAY**: Ordered collections with homogeneous element types
- **OBJECT**: Key-value maps with structured property schemas

#### Type Validation Rules
1. All parameters must conform to their declared schema
2. Required properties must be present in OBJECT types
3. Array elements must match the declared items schema
4. Enum values must be from the specified list
5. Nested objects support unlimited depth

## Data Models

### Tool Structure

The `Tool` serves as the top-level container for AI capabilities:

```json
{
  "function_declarations": [
    {
      "name": "function_name",
      "description": "Function description",
      "parameters": { /* Schema object */ }
    }
  ]
}
```

**Design Rationale**: The Tool structure is designed for extensibility, allowing future versions to add other capability types (e.g., retrieval, search) while maintaining backward compatibility.

### FunctionDeclaration Structure

The `FunctionDeclaration` defines individual tool capabilities:

```json
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
}
```

**Design Rationale**: The structure directly mirrors Google Gemini's function calling API, ensuring seamless integration with existing LLM clients while providing comprehensive parameter validation.

### Schema System Design

The `Schema` object provides recursive type definitions:

```json
{
  "type": "OBJECT",
  "description": "Flight booking request",
  "properties": {
    "passengers": {
      "type": "ARRAY",
      "description": "List of passengers",
      "items": {
        "type": "OBJECT",
        "properties": {
          "name": { "type": "STRING" },
          "age": { "type": "INTEGER" },
          "preferences": {
            "type": "OBJECT",
            "properties": {
              "meal": { "type": "STRING", "enum": ["vegetarian", "vegan", "regular"] },
              "seat": { "type": "STRING" }
            }
          }
        },
        "required": ["name", "age"]
      }
    }
  },
  "required": ["passengers"]
}
```

**Design Rationale**: The recursive schema design supports arbitrarily complex data structures while maintaining validation integrity at every level.

### Function Call and Response Design

The interaction model uses a discriminated union pattern for unambiguous result handling:

#### FunctionCall Structure
```json
{
  "name": "get_weather_forecast",
  "args": {
    "location": "Tokyo, Japan",
    "days": 3,
    "units": "celsius"
  }
}
```

#### ToolResult Structure (Success Case)
```json
{
  "name": "get_weather_forecast",
  "status": "SUCCESS",
  "content": {
    "location": "Tokyo, Japan",
    "forecast": [
      { "day": 1, "temperature": 22, "conditions": "sunny" },
      { "day": 2, "temperature": 19, "conditions": "cloudy" },
      { "day": 3, "temperature": 17, "conditions": "rainy" }
    ]
  }
}
```

#### ToolResult Structure (Error Case)
```json
{
  "name": "get_weather_forecast",
  "status": "ERROR",
  "error": {
    "message": "Invalid location: 'Nonexistent City' could not be found",
    "type": "PARAMETER_VALIDATION_FAILED"
  }
}
```

**Design Rationale**: The discriminated union pattern with explicit status fields eliminates parsing ambiguity and provides type-safe result handling in strongly-typed languages. This approach is more robust than inspecting nested object keys and aligns with modern protocol design patterns.

## Error Handling

### Error Classification

The ADM defines a structured approach to error handling:

1. **Validation Errors**: Parameter schema violations
2. **Execution Errors**: Tool implementation failures
3. **System Errors**: Infrastructure or resource issues

### Error Response Design

Error responses are embedded within the ToolResult structure and follow a consistent format:
- **message**: Human-readable error description
- **type**: Optional standardized error code for programmatic handling
- **context**: Additional error-specific information (future extension)

### Error Propagation Strategy

The ADM ensures that errors are:
1. Structured and machine-readable
2. Informative for debugging
3. Safe for AI model consumption
4. Consistent across all tool implementations

## Testing Strategy

### Schema Validation Testing

1. **Type Conformance**: Verify all primitive and complex types validate correctly
2. **Required Field Validation**: Ensure required properties are enforced
3. **Enum Constraint Testing**: Validate enumeration restrictions
4. **Recursive Schema Testing**: Test deeply nested object structures
5. **Array Validation**: Verify homogeneous array element type checking

### Compatibility Testing

1. **Gemini API Compatibility**: Verify structures work with Google Gemini function calling
2. **OpenAI Compatibility**: Test adaptation to OpenAI function calling format
3. **Cross-Language Serialization**: Ensure JSON serialization works across languages
4. **Version Compatibility**: Test forward and backward compatibility scenarios

### Integration Testing

1. **LATER Protocol Integration**: Verify ADM structures work with local execution
2. **GRID Protocol Integration**: Test compatibility with distributed execution
3. **Multi-Tool Scenarios**: Validate complex tool interaction patterns
4. **Error Handling Integration**: Test error propagation through protocol layers

### Performance Testing

1. **Schema Validation Performance**: Measure validation overhead for complex schemas
2. **Serialization Performance**: Test JSON encoding/decoding efficiency
3. **Memory Usage**: Verify efficient memory usage for large tool definitions
4. **Scalability**: Test behavior with hundreds of function declarations

## Serialization Format

**JSON is the canonical serialization format** for all ADM data structures when represented in textual form. This ensures cross-language compatibility and consistent interchange between different implementations. All ADM-compliant systems must support JSON serialization and deserialization of the defined data structures.

### Serialization Requirements

1. **Standard JSON**: All structures must serialize to valid JSON as defined by RFC 7159
2. **UTF-8 Encoding**: String values must use UTF-8 encoding
3. **Numeric Precision**: Numbers should preserve precision according to IEEE 754 standards
4. **Field Ordering**: Field order in JSON objects is not significant
5. **Null Handling**: Absent optional fields should be omitted rather than set to null

## Implementation Considerations

### Language-Neutral Design

The ADM specification is designed to be implementable in any programming language:

1. **Type Mapping**: Universal types map to language-specific equivalents
2. **JSON Serialization**: Standard JSON ensures cross-language compatibility
3. **Validation Logic**: Schema validation can be implemented using standard libraries
4. **Extension Points**: Future enhancements maintain backward compatibility

### Security Considerations

While the ADM focuses on data structures, it includes security-conscious design:

1. **Parameter Validation**: Strict schema validation prevents injection attacks
2. **Type Safety**: Strong typing prevents data corruption
3. **Error Information**: Error messages avoid exposing sensitive system details
4. **Extensibility**: Future security enhancements can be added without breaking changes

### Performance Optimization

The ADM design considers performance implications:

1. **Efficient Validation**: Schema validation can be optimized with caching
2. **Minimal Overhead**: Structures include only essential fields
3. **Streaming Support**: Design allows for future streaming enhancements
4. **Batch Operations**: Structure supports future batch operation extensions