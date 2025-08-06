### **Agent Prompt: Establish the Foundational LATER v1.0 Specification**

**Role:** You are a senior protocol architect. Your primary task is to draft the foundational v1.0 specification for the **LATER (Local Agent & Tool Execution Runtime)** protocol. This document will serve as the guiding architectural blueprint for all subsequent work, including detailed requirements and reference implementations.

**Core Mandate & Strategic Clarifications:**

Your specification must establish the following core principles, resolving key architectural tensions:

1.  **Protocol, Not Implementation:** LATER is a **protocol specification**, not a library. The `gemini_ex` project will contain its first *canonical implementation*, but the specification itself must be written in a general, abstract, and implementation-agnostic way. All examples and definitions should clearly distinguish between the abstract protocol requirement and a specific language's implementation pattern.

2.  **Language-Agnostic by Design:** The protocol's core concepts (Registry, Executor, Schemas) must be defined in a way that is not inherently tied to Elixir.
    *   **The Metaprogramming Challenge:** You must address the fact that languages with powerful metaprogramming (like Elixir macros or Python decorators) have a significant advantage in implementing LATER seamlessly. Resolve this by structuring the specification in two parts:
        1.  The **Abstract Protocol**, which defines *what* components must exist and *what* their behaviors are.
        2.  A **Canonical Implementation Pattern**, which describes *how* a language like Elixir can meet these requirements idiomatically (e.g., via a `deftool` macro). This pattern serves as a reference for other languages to achieve the same outcome using their own idiomatic techniques (e.g., decorators, annotations).

**Required Specification Sections:**

Your final output must be a single, formal Markdown document containing the following sections:

1.  **Introduction & Vision:**
    *   Define LATER as a language-agnostic protocol for in-process tool execution by AI agents.
    *   State its guiding principles: simplicity, developer experience, and automated schema generation.
    *   Crucially, define its relationship to the ALTAR protocol as a compatible, local-first companion, emphasizing the shared schema models as the bridge for tool "promotion."

2.  **Abstract Protocol Definition (Language-Agnostic):**
    *   Define the conceptual components required for a LATER-compliant system:
        *   **Tool Declaration Mechanism:** The requirement that a compliant implementation *must* provide a mechanism for developers to declare a local function as a tool and have its schema automatically introspected and generated.
        *   **Local Tool Registry:** The required behaviors of the registry. It must store and retrieve tool definitions (schema + function reference) and scope them to a runtime session.
        *   **Local Tool Executor:** The required behaviors of the executor. It must accept a standard `FunctionCall` data structure and reliably invoke the corresponding local function.

3.  **Canonical Implementation Pattern (Elixir):**
    *   Describe how the Elixir implementation fulfills the abstract protocol requirements.
    *   **Tool Declaration:** Detail the `deftool` macro as Elixir's idiomatic implementation of the "Tool Declaration Mechanism."
    *   **Registry & Executor:** Briefly explain how OTP primitives (e.g., GenServer, ETS) can be used to implement the required Registry and Executor behaviors.
    *   *Note:* This section serves as a clear, concrete example for developers implementing LATER in other languages.

4.  **Data Models (The Universal Contract):**
    *   Define the language-agnostic data structures that form the core of the protocol.
    *   These **must** be compatible with `gemini_ex` and ALTAR. Use the `FunctionDeclaration`, `Schema`, `FunctionCall`, and `FunctionResponse` structures from the provided `gemini_ex` context as the basis for these definitions. This section is the universal contract that ensures interoperability.

5.  **Integration with a Host Application (e.g., `gemini_ex`):**
    *   Describe the abstract interaction flow between a host application (like an LLM client) and a LATER-compliant implementation.
    *   Explain how the host discovers tools from the registry, passes them to the LLM, receives a `FunctionCall`, dispatches it to the executor, and sends the `FunctionResponse` back to the LLM. This illustrates the protocol's practical use case.

**Final Instructions:**
*   Produce a single, well-structured Markdown document.
*   The tone must be that of a formal specification: clear, precise, and unambiguous.
*   Explicitly separate the abstract protocol requirements from the specific Elixir implementation patterns to clearly communicate the language-agnostic vision.
*   Once this foundational specification is complete, we will use it as the new context to revisit and refine the detailed `REQUIREMENTS.md` from your previous response.