# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.2] - 2025-08-07

### Changed
- Updated CHANGELOG.md and included in docs package.

## [0.1.1] - 2025-08-07

### Changed
- Improved and clarified the documentation in the main `README.md` to better explain the core architectural principles.

## [0.1.0] - 2025-08-07

### 🎉 Added - First Implementation Release

This is the first official implementation release of the ALTAR protocol, providing a robust, production-ready foundation for local AI tool execution in Elixir.

#### 🏛️ Architectural Foundation (`Altar.ADM`)
- **Validated Data Model:** Implemented the complete `Altar.ADM` (ALTAR Data Model) layer with type-safe structs (`FunctionDeclaration`, `FunctionCall`, `ToolResult`, `ToolConfig`).
- **Smart Constructors:** All data model structs are created via `new/1` constructors that perform comprehensive validation, ensuring no malformed data can exist at runtime.

#### 🚀 Local Execution Runtime (`Altar.LATER`)
- **Stateful Tool Registry:** Implemented `Altar.LATER.Registry` as a robust `GenServer` to manage the state of registered tool functions safely. It prevents duplicate registrations and validates function arity.
- **Stateless Tool Executor:** Implemented the `Altar.LATER.Executor`, a pure and stateless module that safely executes tool calls. It includes `try/rescue` blocks to gracefully handle exceptions within tool code, always returning a valid `ToolResult`.

#### 🧬 OTP Compliance
- **Top-Level Supervisor:** Added `Altar.Supervisor` to manage the lifecycle of the `Registry` process, providing a named, discoverable endpoint (`Altar.LATER.Registry`) for easy application integration.

#### 🧪 Testing
- **Comprehensive Test Suite:** Added a full suite of ExUnit tests, achieving 100% coverage for all modules in the `ADM` and `LATER` layers. Tests validate all success paths, failure paths, and edge cases.

## [0.0.1] - 2025-08-03

### Added

- **Initial Project Setup**: Created the `mix.exs` file for the `altar` hex package.
- **Protocol Specification**: Finalized the v1.0 Altar Protocol specification, including the design, requirements, and implementation plan.
- **Documentation**: Created the initial `README.md` with project overview, vision, and documentation links.
- **Styling**: Applied a professional color scheme to all Mermaid diagrams based on the project logo.
- **Configuration**: Created a comprehensive `.gitignore` file for a standard Elixir project.
- **License**: Added the MIT License.

### Changed

- **Project Status**: The project is now considered v1.0 complete and is ready for implementation.

### Fixed

- N/A (Initial Release)
