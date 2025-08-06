# LATER v1.0 Requirements Document

## Introduction

The LATER (Local Agent & Tool Execution Runtime) protocol is designed to provide a "just works" experience for Elixir developers who want to use local functions as tools for Large Language Models (LLMs). LATER serves as a local-first, in-process companion to the distributed ALTAR protocol, enabling seamless tool definition, registration, and execution within the same Elixir application process.

The protocol emphasizes simplicity, developer experience, and automated introspection while maintaining compatibility with ALTAR's data structures to provide a clear migration path for tools that need to be promoted to a distributed runtime environment.

## Requirements

### Requirement 1: Tool Definition and Registration

**User Story:** As an Elixir developer, I want to define local functions as LLM tools using a simple macro, so that I can quickly expose application functionality to AI agents without complex configuration.

#### Acceptance Criteria

1. WHEN a developer uses `use Gemini.Tools` in a module THEN the module SHALL have access to the `deftool/2` macro
2. WHEN a developer defines a function with `deftool name, do: function_body` THEN the system SHALL automatically generate a tool schema from the function signature
3. WHEN a tool is defined with `deftool` THEN the system SHALL automatically register the tool in the Local Tool Registry
4. WHEN a function has a `@doc` attribute THEN the system SHALL use it as the tool description in the generated schema
5. WHEN a function has typed parameters THEN the system SHALL map Elixir types to `Gemini.Types.Tooling.Schema` types automatically

### Requirement 2: Schema Generation and Type Mapping

**User Story:** As an Elixir developer, I want the system to automatically generate tool schemas from my function signatures, so that I don't need to manually define parameter schemas and type information.

#### Acceptance Criteria

1. WHEN a function parameter uses `is_integer/1` guard THEN the system SHALL map it to `:INTEGER` type
2. WHEN a function parameter uses `is_binary/1` guard THEN the system SHALL map it to `:STRING` type  
3. WHEN a function parameter uses `is_boolean/1` guard THEN the system SHALL map it to `:BOOLEAN` type
4. WHEN a function parameter uses `is_float/1` guard THEN the system SHALL map it to `:NUMBER` type
5. WHEN a function has default parameter values THEN the system SHALL mark those parameters as optional in the schema
6. WHEN a function parameter name is defined THEN the system SHALL use it as the property name in the schema
7. WHEN a function has a `@doc` string THEN the system SHALL use it as the tool description in the `FunctionDeclaration`

### Requirement 3: Local Tool Registry

**User Story:** As a system integrator, I want a centralized registry for all locally defined tools, so that the LLM integration can discover and access available tools within the application session.

#### Acceptance Criteria

1. WHEN a tool is registered via `deftool` THEN the registry SHALL store the tool with its generated `FunctionDeclaration` schema
2. WHEN the registry receives a `register/2` call THEN it SHALL store the tool definition with session scope
3. WHEN the registry receives a `lookup/2` call with session ID and tool name THEN it SHALL return the corresponding tool definition or error
4. WHEN the registry receives a `list_declarations/1` call with session ID THEN it SHALL return all `FunctionDeclaration` schemas for that session
5. WHEN a session is destroyed THEN the registry SHALL clean up all associated tool registrations

### Requirement 4: Local Tool Executor

**User Story:** As an LLM integration, I want to execute registered local tools using standardized function calls, so that I can invoke Elixir functions based on model responses without knowing implementation details.

#### Acceptance Criteria

1. WHEN the executor receives an `execute/2` call with session ID and `FunctionCall` struct THEN it SHALL locate the corresponding registered tool
2. WHEN a tool is found THEN the executor SHALL invoke the Elixir function with the provided parameters
3. WHEN a tool execution succeeds THEN the executor SHALL return `{:ok, result}` with the function's return value
4. WHEN a tool execution fails THEN the executor SHALL return `{:error, reason}` with structured error information
5. WHEN a tool is not found THEN the executor SHALL return `{:error, :tool_not_found}`
6. WHEN parameters don't match the tool schema THEN the executor SHALL return `{:error, :invalid_parameters}`

### Requirement 5: ALTAR Compatibility

**User Story:** As a developer planning to scale my application, I want tools defined with LATER to be compatible with ALTAR data structures, so that I can promote local tools to a distributed runtime without rewriting tool contracts.

#### Acceptance Criteria

1. WHEN a tool schema is generated THEN it SHALL use `Gemini.Types.Tooling.FunctionDeclaration` struct format
2. WHEN tool parameters are defined THEN they SHALL use `Gemini.Types.Tooling.Schema` struct format
3. WHEN a tool is invoked THEN it SHALL accept `Gemini.Types.Tooling.FunctionCall` struct format
4. WHEN tool results are returned THEN they SHALL be compatible with ALTAR's expected response format
5. WHEN a tool is promoted to ALTAR THEN the contract definition SHALL remain unchanged, only the execution mechanism changes

### Requirement 6: Session Management

**User Story:** As an application developer, I want tools to be scoped to specific sessions, so that different user interactions or application contexts can have isolated tool environments.

#### Acceptance Criteria

1. WHEN a session is created THEN the system SHALL provide a unique session identifier
2. WHEN tools are registered THEN they SHALL be associated with a specific session ID
3. WHEN tools are executed THEN they SHALL only be accessible within their registered session
4. WHEN a session ends THEN all associated tools SHALL be automatically cleaned up
5. WHEN multiple sessions exist THEN tools in one session SHALL NOT be accessible from another session

### Requirement 7: Error Handling and Validation

**User Story:** As a developer, I want comprehensive error handling and parameter validation, so that I can debug issues quickly and ensure tool calls are executed safely.

#### Acceptance Criteria

1. WHEN invalid parameters are provided to a tool THEN the system SHALL return structured error information
2. WHEN a tool function raises an exception THEN the system SHALL catch it and return a formatted error
3. WHEN a tool is not found THEN the system SHALL return a clear "tool not found" error
4. WHEN a session doesn't exist THEN the system SHALL return a "session not found" error
5. WHEN parameter types don't match the schema THEN the system SHALL return validation error details
6. WHEN an error occurs THEN the system SHALL include sufficient context for debugging

### Requirement 8: Integration with gemini_ex

**User Story:** As a gemini_ex user, I want LATER tools to integrate seamlessly with the existing Gemini API workflow, so that I can use local tools alongside remote API calls without changing my application architecture.

#### Acceptance Criteria

1. WHEN `Gemini.generate/2` is called with a prompt THEN it SHALL be able to discover LATER tools via the registry
2. WHEN the model returns a `FunctionCall` part THEN gemini_ex SHALL be able to execute it via the LATER executor
3. WHEN a local tool execution completes THEN the result SHALL be packaged into a `FunctionResponse` for the model
4. WHEN local and remote tools are both available THEN they SHALL work together seamlessly in the same conversation
5. WHEN a tool call fails THEN the error SHALL be properly communicated back to the model for recovery