### **Agent Prompt: Create the LATER v1.0 Specification**

**Role:** You are a senior protocol architect specializing in AI agent interoperability and developer experience. Your task is to author a formal v1.0 specification document.

**Primary Objective:** Create the comprehensive and complete v1.0 specification for the **LATER (Local Agent & Tool Execution Runtime)** protocol. This specification must be clear, unambiguous, and ready for an Elixir engineering team to begin implementation.

**Core Philosophy & Guiding Principles:**
The LATER protocol must be designed with the following principles at its core:
1.  **Simplicity & Developer Experience:** The primary goal is to provide a "just works" experience for Elixir developers who want to use local functions as tools for an LLM. The interface should be intuitive and require minimal boilerplate.
2.  **Local-First, In-Process:** LATER is exclusively for defining and executing tools within the *same* Elixir application process. It does not involve networking or inter-process communication.
3.  **ALTAR Compatibility:** LATER is a *companion* to the ALTAR protocol, not a replacement. Its data structures, particularly for tool schemas, **must** be compatible with the `Gemini.Types.Tooling.FunctionDeclaration` and `Schema` structs to ensure a smooth "promotion path" for tools to a full ALTAR runtime.
4.  **Automated Introspection:** The protocol should rely on introspection (e.g., Elixir macros, function signatures, `@doc` attributes) to automatically generate the necessary tool schemas, minimizing manual schema definition.

**Contextual Foundation:**
You have been provided with three extensive context files: `gemini_ex`, `ALTAR`, and `snakepit`. Your design must be based on the "Option 3" strategy outlined in the `gemini_ex` analysis, which recommends creating a complementary, local-first specification that integrates seamlessly with `gemini_ex` and provides a clear migration path to the full, distributed ALTAR protocol.

You must use the data structures defined in `gemini_ex/types/response/generate_content_response.ex` (specifically `FunctionCall`) and the proposed `Gemini.Types.Tooling` module (containing `FunctionDeclaration`, `Schema`, etc.) as the canonical representation for tool schemas and invocations.

**Required Specification Sections:**

Your final output must be a single Markdown document containing the following sections:

1.  **Introduction:**
    *   **Vision:** Briefly state LATER's purpose.
    *   **Guiding Principles:** List the core philosophy points.
    *   **Relationship to ALTAR:** Clearly define LATER as a local companion to the distributed ALTAR protocol, emphasizing the compatible schemas and the promotion path.

2.  **Core Concepts:**
    *   **Tool Definition:** A local Elixir function exposed to the runtime.
    *   **Local Tool Registry:** An in-process, session-scoped registry holding tool definitions and their schemas.
    *   **Local Tool Executor:** The component responsible for invoking a registered Elixir function based on a `FunctionCall` from the model.

3.  **Specification Details:**
    *   **Tool Declaration API (The `deftool` Macro):**
        *   Define the syntax and usage of a `use Gemini.Tools` and `deftool/2` macro.
        *   Specify how it introspects the function's name, arguments (including default values), and `@doc` string to generate the tool's schema.
        *   Explain how it automatically registers the generated tool into the Local Tool Registry.
    *   **Schema Generation & Type Mapping:**
        *   Define the explicit mapping from Elixir types to the `Gemini.Types.Tooling.Schema` types. (e.g., `is_integer/1` -> `:INTEGER`, `is_binary/1` -> `:STRING`, `is_boolean/1` -> `:BOOLEAN`, `is_float/1` -> `:NUMBER`).
        *   Explain how function argument names become schema property names and how `@doc` becomes the description.
    *   **Local Tool Registry API:**
        *   Specify the Elixir behaviour for the registry (e.g., `LATER.Registry`).
        *   Define the functions: `register/2` (for the macro to call), `lookup/2`, and `list_declarations/1` (to provide tools to `gemini_ex`).
    *   **Local Tool Executor API:**
        *   Specify the Elixir behaviour for the executor (e.g., `LATER.Executor`).
        *   Define the primary function: `execute/2`, which takes a session ID and a `Gemini.Types.Tooling.FunctionCall` struct and returns `{:ok, result}` or `{:error, reason}`.

4.  **Data Models (Elixir Structs):**
    *   Define the internal `LATER.Tool` struct that the registry will store. It must contain the generated `FunctionDeclaration` schema and a reference to the actual Elixir function (`{module, function, arity}`).

5.  **Example End-to-End Workflow:**
    *   Provide a clear, step-by-step example of using LATER within a `gemini_ex` application.
    *   Use a Mermaid sequence diagram and Elixir code blocks.
    *   The flow must cover:
        1.  Defining a tool with `deftool`.
        2.  Calling `Gemini.generate/2` with a prompt that triggers the tool.
        3.  How `gemini_ex` uses the `LATER.Registry` to get the tool declaration.
        4.  How the model returns a `FunctionCall` part.
        5.  How `gemini_ex` uses the `LATER.Executor` to run the local function.
        6.  How the result is packaged into a `FunctionResponse` and sent back to the model for a final answer.

6.  **Promotion Path to ALTAR:**
    *   Explicitly describe how a tool defined with `deftool` can be migrated to a separate `snakepit`/ALTAR runtime.
    *   Emphasize that because the `FunctionDeclaration` schema is compatible, the *contract* remains the same, and only the execution mechanism (local call vs. network RPC) changes.
    *   Provide a brief code example showing the "before" (LATER) and "after" (ALTAR/snakepit) invocation.

**Final Instructions:**
*   The output must be a single, well-formatted Markdown document.
*   Use Elixir code blocks for all examples.
*   Use Mermaid diagrams where appropriate to illustrate flows.
*   The tone should be authoritative and technical, suitable for an official specification document.
