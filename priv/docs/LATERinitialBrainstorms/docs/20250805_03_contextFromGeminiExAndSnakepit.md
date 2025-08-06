Create the specification for this: ````` 

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

*   The tone should be authoritative and technical, suitable for an official specification document.`````  `````--- START FILE: snakepit/lib/snakepit/bridge/tool_registry.ex ---

defmodule Snakepit.Bridge.InternalToolSpec do

  @moduledoc """

  Internal specification for a tool in the registry.

  Separate from the protobuf ToolSpec to avoid conflicts.

  """

  defstruct name: nil,

            # :local or :remote

            type: nil,

            # Function reference for local tools

            handler: nil,

            # Worker ID for remote tools

            worker_id: nil,

            parameters: [],

            description: "",

            metadata: %{},

            exposed_to_python: false

  @type t :: %__MODULE__{

          name: String.t(),

          type: :local | :remote,

          handler: (any() -> any()) | nil,

          worker_id: String.t() | nil,

          parameters: list(map()),

          description: String.t(),

          metadata: map(),

          exposed_to_python: boolean()

        }

end

defmodule Snakepit.Bridge.ToolRegistry do

  @moduledoc """

  Registry for managing tool metadata and execution.

  Maintains a registry of both local (Elixir) and remote (Python) tools,

  handles tool discovery, registration, and provides execution dispatch.

  """

  use GenServer

  require Logger

  alias Snakepit.Bridge.InternalToolSpec

  @table_name :snakepit_tool_registry

  # Client API

  @doc """

  Starts the ToolRegistry GenServer.

  """

  def start_link(opts \\ []) do

    GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  end

  @doc """

  Registers a local Elixir tool.

  """

  def register_elixir_tool(session_id, tool_name, handler, metadata \\ %{}) do

    GenServer.call(__MODULE__, {:register_elixir_tool, session_id, tool_name, handler, metadata})

  end

  @doc """

  Registers a remote Python tool.

  """

  def register_python_tool(session_id, tool_name, worker_id, metadata \\ %{}) do

    GenServer.call(

      __MODULE__,

      {:register_python_tool, session_id, tool_name, worker_id, metadata}

    )

  end

  @doc """

  Registers multiple tools at once (used by Python workers on startup).

  """

  def register_tools(session_id, tool_specs) do

    GenServer.call(__MODULE__, {:register_tools, session_id, tool_specs})

  end

  @doc """

  Gets a specific tool by name.

  """

  def get_tool(session_id, tool_name) do

    case :ets.lookup(@table_name, {session_id, tool_name}) do

      [{_key, tool_spec}] -> {:ok, tool_spec}

      [] -> {:error, "Tool #{tool_name} not found for session #{session_id}"}

    end

  end

  @doc """

  Lists all tools available for a session.

  """

  def list_tools(session_id) do

    pattern = {{session_id, :_}, :_}

    tools = :ets.match_object(@table_name, pattern)

    Enum.map(tools, fn {{_session_id, _tool_name}, tool_spec} -> tool_spec end)

  end

  @doc """

  Lists only Elixir tools exposed to Python for a session.

  """

  def list_exposed_elixir_tools(session_id) do

    list_tools(session_id)

    |> Enum.filter(fn tool -> tool.type == :local && tool.exposed_to_python end)

  end

  @doc """

  Executes a local Elixir tool.

  """

  def execute_local_tool(session_id, tool_name, params) do

    with {:ok, tool} <- get_tool(session_id, tool_name),

         :local <- tool.type do

      try do

        result = apply(tool.handler, [params])

        {:ok, result}

      rescue

        e -> {:error, "Tool execution failed: #{inspect(e)}"}

      end

    else

      {:error, _} = error -> error

      _ -> {:error, "Tool #{tool_name} is not a local tool"}

    end

  end

  @doc """

  Removes all tools for a session (cleanup).

  """

  def cleanup_session(session_id) do

    GenServer.call(__MODULE__, {:cleanup_session, session_id})

  end

  # Server Callbacks

  @impl true

  def init(_opts) do

    # Create ETS table for fast lookups

    :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])

    Logger.info("ToolRegistry started with ETS table: #{@table_name}")

    {:ok, %{}}

  end

  @impl true

  def handle_call({:register_elixir_tool, session_id, tool_name, handler, metadata}, _from, state) do

    tool_spec = %InternalToolSpec{

      name: tool_name,

      type: :local,

      handler: handler,

      parameters: Map.get(metadata, :parameters, []),

      description: Map.get(metadata, :description, ""),

      metadata: metadata,

      exposed_to_python: Map.get(metadata, :exposed_to_python, false)

    }

    :ets.insert(@table_name, {{session_id, tool_name}, tool_spec})

    Logger.debug("Registered Elixir tool: #{tool_name} for session: #{session_id}")

    {:reply, :ok, state}

  end

  @impl true

  def handle_call(

        {:register_python_tool, session_id, tool_name, worker_id, metadata},

        _from,

        state

      ) do

    tool_spec = %InternalToolSpec{

      name: tool_name,

      type: :remote,

      worker_id: worker_id,

      parameters: Map.get(metadata, :parameters, []),

      description: Map.get(metadata, :description, ""),

      metadata: metadata

    }

    :ets.insert(@table_name, {{session_id, tool_name}, tool_spec})

    Logger.debug("Registered Python tool: #{tool_name} for session: #{session_id}")

    {:reply, :ok, state}

  end

  @impl true

  def handle_call({:register_tools, session_id, tool_specs}, _from, state) do

    # Register multiple tools at once

    results =

      Enum.map(tool_specs, fn spec ->

        tool_spec = %InternalToolSpec{

          name: spec.name,

          type: :remote,

          worker_id: spec.worker_id,

          parameters: spec.parameters,

          description: spec.description,

          metadata: spec.metadata || %{}

        }

        :ets.insert(@table_name, {{session_id, spec.name}, tool_spec})

        spec.name

      end)

    Logger.info("Registered #{length(results)} tools for session: #{session_id}")

    {:reply, {:ok, results}, state}

  end

  @impl true

  def handle_call({:cleanup_session, session_id}, _from, state) do

    pattern = {{session_id, :_}, :_}

    num_deleted = :ets.match_delete(@table_name, pattern)

    Logger.debug("Cleaned up #{num_deleted} tools for session: #{session_id}")

    {:reply, :ok, state}

  end

end

--- END FILE: snakepit/lib/snakepit/bridge/tool_registry.ex ---

--- START FILE: snakepit/lib/snakepit/bridge/session.ex ---

defmodule Snakepit.Bridge.Session do

  @moduledoc """

  Session data structure for centralized session management.

  Extended in Stage 1 to support variables alongside programs.

  Variables are stored by ID with a name index for fast lookups.

  """

  alias Snakepit.Bridge.Variables.Variable

  @type t :: %__MODULE__{

          id: String.t(),

          programs: map(),

          variables: %{String.t() => Variable.t()},

          # name -> id mapping

          variable_index: %{String.t() => String.t()},

          metadata: map(),

          created_at: integer(),

          last_accessed: integer(),

          last_worker_id: String.t() | nil,

          ttl: integer(),

          stats: map()

        }

  @enforce_keys [:id, :created_at, :ttl]

  defstruct [

    :id,

    :created_at,

    :last_accessed,

    :last_worker_id,

    :ttl,

    programs: %{},

    variables: %{},

    variable_index: %{},

    metadata: %{},

    stats: %{

      variable_count: 0,

      program_count: 0,

      total_variable_updates: 0

    }

  ]

  @doc """

  Creates a new session with the given ID and options.

  """

  @spec new(String.t(), keyword()) :: t()

  def new(id, opts \\ []) when is_binary(id) do

    now = System.monotonic_time(:second)

    # 1 hour default

    ttl = Keyword.get(opts, :ttl, 3600)

    metadata = Keyword.get(opts, :metadata, %{})

    %__MODULE__{

      id: id,

      created_at: now,

      last_accessed: now,

      ttl: ttl,

      metadata: metadata,

      programs: Keyword.get(opts, :programs, %{}),

      last_worker_id: Keyword.get(opts, :last_worker_id, nil)

    }

  end

  @doc """

  Updates the last_accessed timestamp to the current time.

  ## Parameters

  - `session` - The session to touch

  ## Returns

  Updated session with current last_accessed timestamp.

  """

  @spec touch(t()) :: t()

  def touch(%__MODULE__{} = session) do

    %{session | last_accessed: System.monotonic_time(:second)}

  end

  @doc """

  Checks if a session has expired based on its TTL.

  ## Parameters

  - `session` - The session to check

  - `current_time` - Optional current time (defaults to current monotonic time)

  ## Returns

  `true` if the session has expired, `false` otherwise.

  """

  @spec expired?(t(), integer() | nil) :: boolean()

  def expired?(%__MODULE__{} = session, current_time \\ nil) do

    current_time = current_time || System.monotonic_time(:second)

    session.last_accessed + session.ttl < current_time

  end

  @doc """

  Validates that a session struct has all required fields and valid data.

  ## Parameters

  - `session` - The session to validate

  ## Returns

  `:ok` if valid, `{:error, reason}` if invalid.

  """

  @spec validate(t()) :: :ok | {:error, term()}

  def validate(%__MODULE__{} = session) do

    cond do

      not is_binary(session.id) or session.id == "" ->

        {:error, :invalid_id}

      not is_map(session.programs) ->

        {:error, :invalid_programs}

      not is_map(session.metadata) ->

        {:error, :invalid_metadata}

      not is_integer(session.created_at) ->

        {:error, :invalid_created_at}

      not is_integer(session.last_accessed) ->

        {:error, :invalid_last_accessed}

      not (is_binary(session.last_worker_id) or is_nil(session.last_worker_id)) ->

        {:error, :invalid_last_worker_id}

      not is_integer(session.ttl) or session.ttl < 0 ->

        {:error, :invalid_ttl}

      session.last_accessed < session.created_at ->

        {:error, :invalid_timestamps}

      true ->

        :ok

    end

  end

  def validate(_), do: {:error, :not_a_session}

  @doc """

  Adds or updates a program in the session.

  ## Parameters

  - `session` - The session to update

  - `program_id` - The program identifier

  - `program_data` - The program data to store

  ## Returns

  Updated session with the program added/updated.

  """

  @spec put_program(t(), String.t(), term()) :: t()

  def put_program(%__MODULE__{} = session, program_id, program_data)

      when is_binary(program_id) do

    is_update = Map.has_key?(session.programs, program_id)

    programs = Map.put(session.programs, program_id, program_data)

    stats =

      if not is_update do

        %{session.stats | program_count: session.stats.program_count + 1}

      else

        session.stats

      end

    %{session | programs: programs, stats: stats}

  end

  @doc """

  Gets a program from the session.

  ## Parameters

  - `session` - The session to query

  - `program_id` - The program identifier

  ## Returns

  `{:ok, program_data}` if found, `{:error, :not_found}` if not found.

  """

  @spec get_program(t(), String.t()) :: {:ok, term()} | {:error, :not_found}

  def get_program(%__MODULE__{} = session, program_id) when is_binary(program_id) do

    case Map.get(session.programs, program_id) do

      nil -> {:error, :not_found}

      program_data -> {:ok, program_data}

    end

  end

  @doc """

  Removes a program from the session.

  ## Parameters

  - `session` - The session to update

  - `program_id` - The program identifier to remove

  ## Returns

  Updated session with the program removed.

  """

  @spec delete_program(t(), String.t()) :: t()

  def delete_program(%__MODULE__{} = session, program_id) when is_binary(program_id) do

    programs = Map.delete(session.programs, program_id)

    %{session | programs: programs}

  end

  @doc """

  Updates session metadata.

  ## Parameters

  - `session` - The session to update

  - `key` - The metadata key

  - `value` - The metadata value

  ## Returns

  Updated session with the metadata updated.

  """

  @spec put_metadata(t(), term(), term()) :: t()

  def put_metadata(%__MODULE__{} = session, key, value) do

    metadata = Map.put(session.metadata, key, value)

    %{session | metadata: metadata}

  end

  @doc """

  Gets metadata from the session.

  ## Parameters

  - `session` - The session to query

  - `key` - The metadata key

  - `default` - Default value if key not found

  ## Returns

  The metadata value or the default.

  """

  @spec get_metadata(t(), term(), term()) :: term()

  def get_metadata(%__MODULE__{} = session, key, default \\ nil) do

    Map.get(session.metadata, key, default)

  end

  @doc """

  Adds or updates a variable in the session.

  Updates both the variables map and the name index.

  Also updates session statistics.

  """

  @spec put_variable(t(), String.t(), Variable.t()) :: t()

  def put_variable(%__MODULE__{} = session, var_id, %Variable{} = variable)

      when is_binary(var_id) do

    # Check if it's an update

    is_update = Map.has_key?(session.variables, var_id)

    # Update variables map

    variables = Map.put(session.variables, var_id, variable)

    # Update name index

    variable_index = Map.put(session.variable_index, to_string(variable.name), var_id)

    # Update stats

    stats =

      if is_update do

        %{session.stats | total_variable_updates: session.stats.total_variable_updates + 1}

      else

        %{

          session.stats

          | variable_count: session.stats.variable_count + 1,

            total_variable_updates: session.stats.total_variable_updates + 1

        }

      end

    %{session | variables: variables, variable_index: variable_index, stats: stats}

  end

  @doc """

  Gets a variable by ID or name.

  Supports both atom and string identifiers. Names are resolved

  through the variable index for O(1) lookup.

  """

  @spec get_variable(t(), String.t() | atom()) :: {:ok, Variable.t()} | {:error, :not_found}

  def get_variable(%__MODULE__{} = session, identifier) when is_atom(identifier) do

    get_variable(session, to_string(identifier))

  end

  def get_variable(%__MODULE__{} = session, identifier) when is_binary(identifier) do

    # First check if it's a direct ID

    case Map.get(session.variables, identifier) do

      nil ->

        # Try to resolve as a name through the index

        case Map.get(session.variable_index, identifier) do

          nil ->

            {:error, :not_found}

          var_id ->

            # Get by resolved ID

            case Map.get(session.variables, var_id) do

              # Shouldn't happen

              nil -> {:error, :not_found}

              variable -> {:ok, variable}

            end

        end

      variable ->

        {:ok, variable}

    end

  end

  @doc """

  Removes a variable from the session.

  """

  @spec delete_variable(t(), String.t() | atom()) :: t()

  def delete_variable(%__MODULE__{} = session, identifier) do

    case get_variable(session, identifier) do

      {:ok, variable} ->

        # Remove from variables

        variables = Map.delete(session.variables, variable.id)

        # Remove from index

        variable_index = Map.delete(session.variable_index, to_string(variable.name))

        # Update stats

        stats = %{session.stats | variable_count: session.stats.variable_count - 1}

        %{session | variables: variables, variable_index: variable_index, stats: stats}

      {:error, :not_found} ->

        session

    end

  end

  @doc """

  Lists all variables in the session.

  Returns them sorted by creation time (oldest first).

  """

  @spec list_variables(t()) :: [Variable.t()]

  def list_variables(%__MODULE__{} = session) do

    session.variables

    |> Map.values()

    |> Enum.sort_by(& &1.created_at)

  end

  @doc """

  Lists variables matching a pattern.

  Supports wildcards: "temp_*" matches "temp_1", "temp_2", etc.

  """

  @spec list_variables(t(), String.t()) :: [Variable.t()]

  def list_variables(%__MODULE__{} = session, pattern) when is_binary(pattern) do

    regex =

      pattern

      |> String.replace("*", ".*")

      |> Regex.compile!()

    session.variables

    |> Map.values()

    |> Enum.filter(fn var ->

      Regex.match?(regex, to_string(var.name))

    end)

    |> Enum.sort_by(& &1.created_at)

  end

  @doc """

  Checks if a variable exists by name or ID.

  """

  @spec has_variable?(t(), String.t() | atom()) :: boolean()

  def has_variable?(%__MODULE__{} = session, identifier) do

    case get_variable(session, identifier) do

      {:ok, _} -> true

      {:error, :not_found} -> false

    end

  end

  @doc """

  Gets all variable names in the session.

  """

  @spec variable_names(t()) :: [String.t()]

  def variable_names(%__MODULE__{} = session) do

    Map.keys(session.variable_index)

  end

  @doc """

  Gets session statistics.

  """

  @spec get_stats(t()) :: map()

  def get_stats(%__MODULE__{} = session) do

    Map.merge(session.stats, %{

      age: System.monotonic_time(:second) - session.created_at,

      time_since_access: System.monotonic_time(:second) - session.last_accessed,

      total_items: session.stats.variable_count + session.stats.program_count

    })

  end

end

--- END FILE: snakepit/lib/snakepit/bridge/session.ex ---

--- START FILE: snakepit/lib/snakepit/bridge/session_store.ex ---

defmodule Snakepit.Bridge.SessionStore do

  @moduledoc """

  Centralized session store using ETS for high-performance session management.

  This GenServer manages a centralized ETS table for storing session data,

  providing CRUD operations, TTL-based expiration, and automatic cleanup.

  The store is designed for high concurrency with optimized ETS settings.

  """

  use GenServer

  require Logger

  alias Snakepit.Bridge.Session

  alias Snakepit.Bridge.Variables.{Variable, Types}

  @default_table_name :snakepit_sessions

  # 1 minute

  @cleanup_interval 60_000

  # 1 hour

  @default_ttl 3600

  ## Client API

  @doc """

  Starts the SessionStore GenServer.

  ## Options

  - `:name` - The name to register the GenServer (default: __MODULE__)

  - `:table_name` - The ETS table name (default: :snakepit_sessions)

  - `:cleanup_interval` - Cleanup interval in milliseconds (default: 60_000)

  - `:default_ttl` - Default TTL for sessions in seconds (default: 3600)

  """

  @spec start_link(keyword()) :: GenServer.on_start()

  def start_link(opts \\ []) do

    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)

  end

  @doc """

  Creates a new session with the given ID and options.

  ## Parameters

  - `session_id` - Unique session identifier

  - `opts` - Keyword list of options passed to Session.new/2

  ## Returns

  `{:ok, session}` if successful, `{:error, reason}` if failed.

  ## Examples

      {:ok, session} = SessionStore.create_session("session_123")

      {:ok, session} = SessionStore.create_session("session_456", ttl: 7200)

  """

  @spec create_session(String.t(), keyword()) :: {:ok, Session.t()} | {:error, term()}

  def create_session(session_id, opts \\ []) when is_binary(session_id) do

    GenServer.call(__MODULE__, {:create_session, session_id, opts})

  end

  @spec create_session(GenServer.server(), String.t(), keyword()) ::

          {:ok, Session.t()} | {:error, term()}

  def create_session(server, session_id, opts) when is_binary(session_id) do

    GenServer.call(server, {:create_session, session_id, opts})

  end

  @doc """

  Gets a session by ID, automatically updating the last_accessed timestamp.

  ## Parameters

  - `session_id` - The session identifier

  ## Returns

  `{:ok, session}` if found, `{:error, :not_found}` if not found.

  """

  @spec get_session(String.t()) :: {:ok, Session.t()} | {:error, :not_found}

  def get_session(session_id) when is_binary(session_id) do

    get_session(__MODULE__, session_id)

  end

  @spec get_session(GenServer.server(), String.t()) :: {:ok, Session.t()} | {:error, :not_found}

  def get_session(server, session_id) when is_binary(session_id) do

    GenServer.call(server, {:get_session, session_id})

  end

  @doc """

  Updates a session using the provided update function.

  The update function receives the current session and should return

  the updated session. The operation is atomic.

  ## Parameters

  - `session_id` - The session identifier

  - `update_fn` - Function that takes a session and returns an updated session

  ## Returns

  `{:ok, updated_session}` if successful, `{:error, reason}` if failed.

  ## Examples

      {:ok, session} = SessionStore.update_session("session_123", fn session ->

        Session.put_program(session, "prog_1", %{data: "example"})

      end)

  """

  @spec update_session(String.t(), (Session.t() -> Session.t())) ::

          {:ok, Session.t()} | {:error, term()}

  def update_session(session_id, update_fn)

      when is_binary(session_id) and is_function(update_fn, 1) do

    update_session(__MODULE__, session_id, update_fn)

  end

  @spec update_session(GenServer.server(), String.t(), (Session.t() -> Session.t())) ::

          {:ok, Session.t()} | {:error, term()}

  def update_session(server, session_id, update_fn)

      when is_binary(session_id) and is_function(update_fn, 1) do

    GenServer.call(server, {:update_session, session_id, update_fn})

  end

  @doc """

  Deletes a session by ID.

  ## Parameters

  - `session_id` - The session identifier

  ## Returns

  `:ok` always (idempotent operation).

  """

  @spec delete_session(String.t()) :: :ok

  def delete_session(session_id) when is_binary(session_id) do

    delete_session(__MODULE__, session_id)

  end

  @spec delete_session(GenServer.server(), String.t()) :: :ok

  def delete_session(server, session_id) when is_binary(session_id) do

    GenServer.call(server, {:delete_session, session_id})

  end

  @doc """

  Manually triggers cleanup of expired sessions.

  ## Returns

  The number of sessions that were cleaned up.

  """

  @spec cleanup_expired_sessions() :: non_neg_integer()

  def cleanup_expired_sessions do

    cleanup_expired_sessions(__MODULE__)

  end

  @spec cleanup_expired_sessions(GenServer.server()) :: non_neg_integer()

  def cleanup_expired_sessions(server) do

    GenServer.call(server, :cleanup_expired_sessions)

  end

  @doc """

  Gets statistics about the session store.

  ## Returns

  A map containing various statistics about the session store.

  """

  @spec get_stats() :: map()

  def get_stats do

    get_stats(__MODULE__)

  end

  @spec get_stats(GenServer.server()) :: map()

  def get_stats(server) do

    GenServer.call(server, :get_stats)

  end

  @doc """

  Lists all active session IDs.

  ## Returns

  A list of all active session IDs.

  """

  @spec list_sessions() :: [String.t()]

  def list_sessions do

    list_sessions(__MODULE__)

  end

  @spec list_sessions(GenServer.server()) :: [String.t()]

  def list_sessions(server) do

    GenServer.call(server, :list_sessions)

  end

  @doc """

  Checks if a session exists.

  ## Parameters

  - `session_id` - The session identifier

  ## Returns

  `true` if the session exists, `false` otherwise.

  """

  @spec session_exists?(String.t()) :: boolean()

  def session_exists?(session_id) when is_binary(session_id) do

    session_exists?(__MODULE__, session_id)

  end

  @spec session_exists?(GenServer.server(), String.t()) :: boolean()

  def session_exists?(server, session_id) when is_binary(session_id) do

    GenServer.call(server, {:session_exists, session_id})

  end

  ## Global Program Storage API

  @doc """

  Stores a program globally, accessible to any worker.

  This is used for anonymous operations where programs need to be

  accessible across different pool workers.

  ## Parameters

  - `program_id` - Unique program identifier

  - `program_data` - Program data to store

  ## Returns

  `:ok` if successful, `{:error, reason}` if failed.

  """

  @spec store_global_program(String.t(), map()) :: :ok | {:error, term()}

  def store_global_program(program_id, program_data) when is_binary(program_id) do

    store_global_program(__MODULE__, program_id, program_data)

  end

  @spec store_global_program(GenServer.server(), String.t(), map()) :: :ok | {:error, term()}

  def store_global_program(server, program_id, program_data) when is_binary(program_id) do

    GenServer.call(server, {:store_global_program, program_id, program_data})

  end

  @doc """

  Retrieves a globally stored program.

  ## Parameters

  - `program_id` - The program identifier

  ## Returns

  `{:ok, program_data}` if found, `{:error, :not_found}` if not found.

  """

  @spec get_global_program(String.t()) :: {:ok, map()} | {:error, :not_found}

  def get_global_program(program_id) when is_binary(program_id) do

    get_global_program(__MODULE__, program_id)

  end

  @spec get_global_program(GenServer.server(), String.t()) :: {:ok, map()} | {:error, :not_found}

  def get_global_program(server, program_id) when is_binary(program_id) do

    GenServer.call(server, {:get_global_program, program_id})

  end

  @doc """

  Deletes a globally stored program.

  ## Parameters

  - `program_id` - The program identifier

  ## Returns

  `:ok` always (idempotent operation).

  """

  @spec delete_global_program(String.t()) :: :ok

  def delete_global_program(program_id) when is_binary(program_id) do

    delete_global_program(__MODULE__, program_id)

  end

  @spec delete_global_program(GenServer.server(), String.t()) :: :ok

  def delete_global_program(server, program_id) when is_binary(program_id) do

    GenServer.call(server, {:delete_global_program, program_id})

  end

  ## Variable API

  @doc """

  Registers a new variable in a session.

  ## Options

    * `:constraints` - Type-specific constraints

    * `:metadata` - Additional metadata

    * `:description` - Human-readable description

  ## Examples

      iex> SessionStore.register_variable("session_1", :temperature, :float, 0.7,

      ...>   constraints: %{min: 0.0, max: 2.0},

      ...>   description: "LLM generation temperature"

      ...> )

      {:ok, "var_temperature_1234567"}

  """

  @spec register_variable(String.t(), atom() | String.t(), atom(), any(), keyword()) ::

          {:ok, String.t()} | {:error, term()}

  def register_variable(session_id, name, type, initial_value, opts \\ []) do

    GenServer.call(__MODULE__, {:register_variable, session_id, name, type, initial_value, opts})

  end

  @doc """

  Gets a variable by ID or name.

  Supports both string and atom identifiers. Names are resolved

  through the session's variable index.

  """

  @spec get_variable(String.t(), String.t() | atom()) ::

          {:ok, Variable.t()} | {:error, term()}

  def get_variable(session_id, identifier) do

    GenServer.call(__MODULE__, {:get_variable, session_id, identifier})

  end

  @doc """

  Gets a variable's current value directly.

  Convenience function that returns just the value.

  """

  @spec get_variable_value(String.t(), String.t() | atom(), any()) :: any()

  def get_variable_value(session_id, identifier, default \\ nil) do

    case get_variable(session_id, identifier) do

      {:ok, variable} -> variable.value

      {:error, _} -> default

    end

  end

  @doc """

  Updates a variable's value with validation.

  The variable's type constraints are enforced and version

  is automatically incremented.

  """

  @spec update_variable(String.t(), String.t() | atom(), any(), map()) ::

          :ok | {:error, term()}

  def update_variable(session_id, identifier, new_value, metadata \\ %{}) do

    GenServer.call(__MODULE__, {:update_variable, session_id, identifier, new_value, metadata})

  end

  @doc """

  Lists all variables in a session.

  Returns variables sorted by creation time (oldest first).

  """

  @spec list_variables(String.t()) :: {:ok, [Variable.t()]} | {:error, term()}

  def list_variables(session_id) do

    GenServer.call(__MODULE__, {:list_variables, session_id})

  end

  @doc """

  Lists variables matching a pattern.

  Supports wildcards: "temp_*" matches "temp_1", "temp_2", etc.

  """

  @spec list_variables(String.t(), String.t()) :: {:ok, [Variable.t()]} | {:error, term()}

  def list_variables(session_id, pattern) do

    GenServer.call(__MODULE__, {:list_variables, session_id, pattern})

  end

  @doc """

  Deletes a variable from the session.

  """

  @spec delete_variable(String.t(), String.t() | atom()) :: :ok | {:error, term()}

  def delete_variable(session_id, identifier) do

    GenServer.call(__MODULE__, {:delete_variable, session_id, identifier})

  end

  @doc """

  Checks if a variable exists.

  """

  @spec has_variable?(String.t(), String.t() | atom()) :: boolean()

  def has_variable?(session_id, identifier) do

    case get_variable(session_id, identifier) do

      {:ok, _} -> true

      _ -> false

    end

  end

  ## Batch Operations

  @doc """

  Gets multiple variables efficiently.

  Returns a map of identifier => variable for found variables

  and a list of missing identifiers.

  """

  @spec get_variables(String.t(), [String.t() | atom()]) ::

          {:ok, %{found: map(), missing: [String.t()]}} | {:error, term()}

  def get_variables(session_id, identifiers) do

    GenServer.call(__MODULE__, {:get_variables, session_id, identifiers})

  end

  @doc """

  Updates multiple variables.

  ## Options

    * `:atomic` - If true, all updates must succeed or none are applied

    * `:metadata` - Metadata to apply to all updates

  Returns a map of identifier => :ok | {:error, reason}

  """

  @spec update_variables(String.t(), map(), keyword()) ::

          {:ok, map()} | {:error, term()}

  def update_variables(session_id, updates, opts \\ []) do

    GenServer.call(__MODULE__, {:update_variables, session_id, updates, opts})

  end

  @doc """

  Exports all variables from a session.

  Used for session migration in Stage 4.

  """

  @spec export_variables(String.t()) :: {:ok, [map()]} | {:error, term()}

  def export_variables(session_id) do

    with {:ok, variables} <- list_variables(session_id) do

      # Use to_export_map to exclude internal fields

      exported = Enum.map(variables, &Variable.to_export_map/1)

      # Debug output

      require Logger

      Logger.debug("Exporting #{length(exported)} variables from session #{session_id}")

      Enum.each(exported, fn var_map ->

        Logger.debug("Exported variable: #{inspect(var_map, pretty: true)}")

        Logger.debug("Exported fields: #{inspect(Map.keys(var_map))}")

      end)

      {:ok, exported}

    end

  end

  @doc """

  Imports variables into a session.

  Used for session restoration in Stage 4.

  """

  @spec import_variables(String.t(), [map()]) :: {:ok, integer()} | {:error, term()}

  def import_variables(session_id, variable_maps) do

    GenServer.call(__MODULE__, {:import_variables, session_id, variable_maps})

  end

  ## GenServer Callbacks

  @impl true

  def init(opts) do

    # Get table name from options or use default

    table_name = Keyword.get(opts, :table_name, @default_table_name)

    # Create ETS table with optimized concurrency settings

    table =

      :ets.new(table_name, [

        :set,

        :public,

        :named_table,

        {:read_concurrency, true},

        {:write_concurrency, true},

        {:decentralized_counters, true}

      ])

    # Create global programs table

    global_programs_table_name = :"#{table_name}_global_programs"

    global_programs_table =

      :ets.new(global_programs_table_name, [

        :set,

        :public,

        :named_table,

        {:read_concurrency, true},

        {:write_concurrency, true},

        {:decentralized_counters, true}

      ])

    cleanup_interval = Keyword.get(opts, :cleanup_interval, @cleanup_interval)

    default_ttl = Keyword.get(opts, :default_ttl, @default_ttl)

    # 1 hour default

    global_program_ttl = Keyword.get(opts, :global_program_ttl, 3600)

    # Schedule periodic cleanup

    Process.send_after(self(), :cleanup_expired_sessions, cleanup_interval)

    state = %{

      table: table,

      table_name: table_name,

      global_programs_table: global_programs_table,

      global_programs_table_name: global_programs_table_name,

      cleanup_interval: cleanup_interval,

      default_ttl: default_ttl,

      global_program_ttl: global_program_ttl,

      stats: %{

        sessions_created: 0,

        sessions_deleted: 0,

        sessions_expired: 0,

        cleanup_runs: 0,

        global_programs_stored: 0,

        global_programs_deleted: 0,

        global_programs_expired: 0

      }

    }

    Logger.info(

      "SessionStore started with table #{table} and global programs table #{global_programs_table}"

    )

    {:ok, state}

  end

  @impl true

  def handle_call({:create_session, session_id, opts}, _from, state) do

    case :ets.lookup(state.table, session_id) do

      [{^session_id, _existing_session}] ->

        {:reply, {:error, :already_exists}, state}

      [] ->

        # Set default TTL if not provided

        opts = Keyword.put_new(opts, :ttl, state.default_ttl)

        session = Session.new(session_id, opts)

        case Session.validate(session) do

          :ok ->

            # Store as {session_id, {last_accessed, ttl, session}} for efficient cleanup

            ets_record = {session_id, {session.last_accessed, session.ttl, session}}

            :ets.insert(state.table, ets_record)

            new_stats = Map.update(state.stats, :sessions_created, 1, &(&1 + 1))

            {:reply, {:ok, session}, %{state | stats: new_stats}}

          {:error, reason} ->

            {:reply, {:error, reason}, state}

        end

    end

  end

  @impl true

  def handle_call({:update_session, session_id, update_fn}, _from, state) do

    case :ets.lookup(state.table, session_id) do

      [{^session_id, {_last_accessed, _ttl, session}}] ->

        try do

          updated_session = update_fn.(session)

          case Session.validate(updated_session) do

            :ok ->

              # Touch the session to update last_accessed

              touched_session = Session.touch(updated_session)

              # Store as {session_id, {last_accessed, ttl, session}} for efficient cleanup

              ets_record =

                {session_id,

                 {touched_session.last_accessed, touched_session.ttl, touched_session}}

              :ets.insert(state.table, ets_record)

              {:reply, {:ok, touched_session}, state}

            {:error, reason} ->

              {:reply, {:error, reason}, state}

          end

        rescue

          error ->

            Logger.error("Error updating session #{session_id}: #{inspect(error)}")

            {:reply, {:error, {:update_failed, error}}, state}

        end

      [] ->

        {:reply, {:error, :not_found}, state}

    end

  end

  @impl true

  def handle_call(:cleanup_expired_sessions, _from, state) do

    {expired_count, new_stats} = do_cleanup_expired_sessions(state.table, state.stats)

    {:reply, expired_count, %{state | stats: new_stats}}

  end

  @impl true

  def handle_call(:get_stats, _from, state) do

    current_sessions = :ets.info(state.table, :size)

    memory_usage = :ets.info(state.table, :memory) * :erlang.system_info(:wordsize)

    stats =

      Map.merge(state.stats, %{

        current_sessions: current_sessions,

        memory_usage_bytes: memory_usage,

        table_info: :ets.info(state.table)

      })

    {:reply, stats, state}

  end

  @impl true

  def handle_call({:get_session, session_id}, _from, state) do

    case :ets.lookup(state.table, session_id) do

      [{^session_id, {_last_accessed, _ttl, session}}] ->

        # Touch the session to update last_accessed

        touched_session = Session.touch(session)

        # Store as {session_id, {last_accessed, ttl, session}} for efficient cleanup

        ets_record =

          {session_id, {touched_session.last_accessed, touched_session.ttl, touched_session}}

        :ets.insert(state.table, ets_record)

        {:reply, {:ok, touched_session}, state}

      [] ->

        {:reply, {:error, :not_found}, state}

    end

  end

  @impl true

  def handle_call({:delete_session, session_id}, _from, state) do

    :ets.delete(state.table, session_id)

    new_stats = Map.update(state.stats, :sessions_deleted, 1, &(&1 + 1))

    {:reply, :ok, %{state | stats: new_stats}}

  end

  @impl true

  def handle_call(:list_sessions, _from, state) do

    session_ids = :ets.select(state.table, [{{:"$1", :_}, [], [:"$1"]}])

    {:reply, session_ids, state}

  end

  @impl true

  def handle_call({:session_exists, session_id}, _from, state) do

    exists =

      case :ets.lookup(state.table, session_id) do

        [{^session_id, _}] -> true

        [] -> false

      end

    {:reply, exists, state}

  end

  @impl true

  def handle_call({:store_global_program, program_id, program_data}, _from, state) do

    # Store with timestamp for potential TTL cleanup

    timestamp = System.monotonic_time(:second)

    program_entry = {program_id, program_data, timestamp}

    :ets.insert(state.global_programs_table, program_entry)

    new_stats = Map.update!(state.stats, :global_programs_stored, &(&1 + 1))

    {:reply, :ok, %{state | stats: new_stats}}

  end

  @impl true

  def handle_call({:get_global_program, program_id}, _from, state) do

    case :ets.lookup(state.global_programs_table, program_id) do

      [{^program_id, program_data, _timestamp}] ->

        {:reply, {:ok, program_data}, state}

      [] ->

        {:reply, {:error, :not_found}, state}

    end

  end

  @impl true

  def handle_call({:delete_global_program, program_id}, _from, state) do

    :ets.delete(state.global_programs_table, program_id)

    new_stats = Map.update!(state.stats, :global_programs_deleted, &(&1 + 1))

    {:reply, :ok, %{state | stats: new_stats}}

  end

  @impl true

  def handle_call({:upsert_worker_session, session_id, worker_id}, _from, state) do

    case :ets.lookup(state.table, session_id) do

      [{^session_id, {_last_accessed, _ttl, session}}] ->

        # Session exists, update it

        updated_session =

          session

          |> Map.put(:last_worker_id, worker_id)

          |> Session.touch()

        # Store as {session_id, {last_accessed, ttl, session}} for efficient cleanup

        ets_record =

          {session_id, {updated_session.last_accessed, updated_session.ttl, updated_session}}

        :ets.insert(state.table, ets_record)

        {:reply, :ok, state}

      [] ->

        # Session doesn't exist, create it with worker affinity

        opts = [ttl: state.default_ttl]

        session =

          Session.new(session_id, opts)

          |> Map.put(:last_worker_id, worker_id)

        case Session.validate(session) do

          :ok ->

            # Store as {session_id, {last_accessed, ttl, session}} for efficient cleanup

            ets_record = {session_id, {session.last_accessed, session.ttl, session}}

            :ets.insert(state.table, ets_record)

            new_stats = Map.update(state.stats, :sessions_created, 1, &(&1 + 1))

            {:reply, :ok, %{state | stats: new_stats}}

          {:error, reason} ->

            # Session affinity is best-effort; log validation errors but don't fail

            Logger.warning("Failed to validate session for worker affinity: #{inspect(reason)}")

            {:reply, :ok, state}

        end

    end

  end

  @impl true

  def handle_call({:register_variable, session_id, name, type, initial_value, opts}, _from, state) do

    with {:ok, session} <- get_session_internal(state, session_id),

         {:ok, type_module} <- Types.get_type_module(type),

         {:ok, validated_value} <- type_module.validate(initial_value),

         constraints = get_option(opts, :constraints, %{}),

         :ok <- type_module.validate_constraints(validated_value, constraints) do

      var_id = generate_variable_id(name)

      now = System.monotonic_time(:second)

      variable =

        Variable.new(%{

          id: var_id,

          name: name,

          type: type,

          value: validated_value,

          constraints: constraints,

          metadata: build_variable_metadata(opts),

          version: 0,

          created_at: now,

          last_updated_at: now

        })

      updated_session = Session.put_variable(session, var_id, variable)

      new_state = store_session(state, session_id, updated_session)

      # Emit telemetry

      :telemetry.execute(

        [:snakepit, :session_store, :variable, :registered],

        %{count: 1},

        %{session_id: session_id, type: type}

      )

      Logger.info("Registered variable #{name} (#{var_id}) in session #{session_id}")

      {:reply, {:ok, var_id}, new_state}

    else

      {:error, reason} ->

        {:reply, {:error, reason}, state}

    end

  end

  @impl true

  def handle_call({:get_variable, session_id, identifier}, _from, state) do

    with {:ok, session} <- get_session_internal(state, session_id),

         {:ok, variable} <- Session.get_variable(session, identifier) do

      # Touch the session

      updated_session = Session.touch(session)

      new_state = store_session(state, session_id, updated_session)

      # Emit telemetry

      :telemetry.execute(

        [:snakepit, :session_store, :variable, :get],

        %{count: 1},

        %{session_id: session_id, cache_hit: false}

      )

      {:reply, {:ok, variable}, new_state}

    else

      error -> {:reply, error, state}

    end

  end

  @impl true

  def handle_call({:update_variable, session_id, identifier, new_value, metadata}, _from, state) do

    with {:ok, session} <- get_session_internal(state, session_id),

         {:ok, variable} <- Session.get_variable(session, identifier),

         {:ok, type_module} <- Types.get_type_module(variable.type),

         {:ok, validated_value} <- type_module.validate(new_value),

         :ok <- type_module.validate_constraints(validated_value, variable.constraints) do

      # Check if optimizing (Stage 4 feature)

      if Variable.optimizing?(variable) do

        {:reply, {:error, :variable_locked_for_optimization}, state}

      else

        updated_variable =

          Variable.update_value(variable, validated_value,

            metadata: metadata,

            source: Map.get(metadata, "source", "elixir")

          )

        updated_session = Session.put_variable(session, variable.id, updated_variable)

        new_state = store_session(state, session_id, updated_session)

        # Emit telemetry

        :telemetry.execute(

          [:snakepit, :session_store, :variable, :updated],

          %{count: 1, version: updated_variable.version},

          %{session_id: session_id, type: variable.type}

        )

        Logger.debug("Updated variable #{identifier} in session #{session_id}")

        # TODO: In Stage 3, notify observers here

        {:reply, :ok, new_state}

      end

    else

      error -> {:reply, error, state}

    end

  end

  @impl true

  def handle_call({:list_variables, session_id}, _from, state) do

    with {:ok, session} <- get_session_internal(state, session_id) do

      variables = Session.list_variables(session)

      {:reply, {:ok, variables}, state}

    else

      error -> {:reply, error, state}

    end

  end

  @impl true

  def handle_call({:list_variables, session_id, pattern}, _from, state) do

    with {:ok, session} <- get_session_internal(state, session_id) do

      variables = Session.list_variables(session, pattern)

      {:reply, {:ok, variables}, state}

    else

      error -> {:reply, error, state}

    end

  end

  @impl true

  def handle_call({:delete_variable, session_id, identifier}, _from, state) do

    with {:ok, session} <- get_session_internal(state, session_id),

         {:ok, variable} <- Session.get_variable(session, identifier) do

      if Variable.optimizing?(variable) do

        {:reply, {:error, :variable_locked_for_optimization}, state}

      else

        updated_session = Session.delete_variable(session, identifier)

        new_state = store_session(state, session_id, updated_session)

        Logger.info("Deleted variable #{identifier} from session #{session_id}")

        {:reply, :ok, new_state}

      end

    else

      error -> {:reply, error, state}

    end

  end

  @impl true

  def handle_call({:get_variables, session_id, identifiers}, _from, state) do

    with {:ok, session} <- get_session_internal(state, session_id) do

      result =

        Enum.reduce(identifiers, %{found: %{}, missing: []}, fn id, acc ->

          case Session.get_variable(session, id) do

            {:ok, variable} ->

              %{acc | found: Map.put(acc.found, to_string(id), variable)}

            {:error, :not_found} ->

              %{acc | missing: [to_string(id) | acc.missing]}

          end

        end)

      # Reverse missing list to maintain order

      result = %{result | missing: Enum.reverse(result.missing)}

      # Touch session

      updated_session = Session.touch(session)

      new_state = store_session(state, session_id, updated_session)

      {:reply, {:ok, result}, new_state}

    else

      error -> {:reply, error, state}

    end

  end

  @impl true

  def handle_call({:update_variables, session_id, updates, opts}, _from, state) do

    atomic = Keyword.get(opts, :atomic, false)

    metadata = get_option(opts, :metadata, %{})

    with {:ok, session} <- get_session_internal(state, session_id) do

      if atomic do

        handle_atomic_updates(session, updates, metadata, state, session_id)

      else

        handle_non_atomic_updates(session, updates, metadata, state, session_id)

      end

    else

      error -> {:reply, error, state}

    end

  end

  @impl true

  def handle_call({:import_variables, session_id, variable_maps}, _from, state) do

    with {:ok, session} <- get_session_internal(state, session_id) do

      {updated_session, count} =

        Enum.reduce(variable_maps, {session, 0}, fn var_map, {sess, cnt} ->

          variable = Variable.new(var_map)

          {Session.put_variable(sess, variable.id, variable), cnt + 1}

        end)

      new_state = store_session(state, session_id, updated_session)

      Logger.info("Imported #{count} variables into session #{session_id}")

      {:reply, {:ok, count}, new_state}

    else

      error -> {:reply, error, state}

    end

  end

  @impl true

  def handle_info(:cleanup_expired_sessions, state) do

    {_expired_count, new_stats} = do_cleanup_expired_sessions(state.table, state.stats)

    {_expired_global_count, newer_stats} =

      do_cleanup_expired_global_programs(

        state.global_programs_table,

        state.global_program_ttl,

        new_stats

      )

    # Schedule next cleanup

    Process.send_after(self(), :cleanup_expired_sessions, state.cleanup_interval)

    {:noreply, %{state | stats: newer_stats}}

  end

  @impl true

  def handle_info(msg, state) do

    Logger.warning("SessionStore received unexpected message: #{inspect(msg)}")

    {:noreply, state}

  end

  @doc """

  Stores a program in a session.

  """

  @spec store_program(String.t(), String.t(), map()) :: :ok | {:error, term()}

  def store_program(session_id, program_id, program_data) do

    update_session(session_id, fn session ->

      programs = Map.get(session, :programs, %{})

      updated_programs = Map.put(programs, program_id, program_data)

      Map.put(session, :programs, updated_programs)

    end)

    |> case do

      {:ok, _} -> :ok

      error -> error

    end

  end

  @doc """

  Updates a program in a session.

  """

  @spec update_program(String.t(), String.t(), map()) :: :ok | {:error, term()}

  def update_program(session_id, program_id, program_data) do

    store_program(session_id, program_id, program_data)

  end

  @doc """

  Gets a program from a session.

  """

  @spec get_program(String.t(), String.t()) :: {:ok, map()} | {:error, :not_found}

  def get_program(session_id, program_id) do

    case get_session(session_id) do

      {:ok, session} ->

        programs = Map.get(session, :programs, %{})

        case Map.get(programs, program_id) do

          nil -> {:error, :not_found}

          program_data -> {:ok, program_data}

        end

      {:error, :not_found} ->

        {:error, :not_found}

    end

  end

  @doc """

  Stores worker-session affinity mapping.

  """

  @spec store_worker_session(String.t(), String.t()) :: :ok

  def store_worker_session(session_id, worker_id) do

    GenServer.call(__MODULE__, {:upsert_worker_session, session_id, worker_id})

  end

  ## Private Functions

  defp do_cleanup_expired_sessions(table, stats) do

    current_time = System.monotonic_time(:second)

    # High-performance cleanup using ETS select_delete with optimized storage format

    # Match on {session_id, {last_accessed, ttl, _session}} where last_accessed + ttl < current_time

    match_spec = [

      {{:_, {:"$1", :"$2", :_}},

       [

         {:<, {:+, :"$1", :"$2"}, current_time}

       ], [true]}

    ]

    # Atomically find and delete all expired sessions using native ETS operations

    # This runs in C code and doesn't block the GenServer process

    expired_count = :ets.select_delete(table, match_spec)

    if expired_count > 0 do

      Logger.debug(

        "Cleaned up #{expired_count} expired sessions using high-performance select_delete"

      )

    end

    new_stats =

      stats

      |> Map.update(:sessions_expired, expired_count, &(&1 + expired_count))

      |> Map.update(:cleanup_runs, 1, &(&1 + 1))

    {expired_count, new_stats}

  end

  # Clean up expired global programs using efficient ETS select_delete

  defp do_cleanup_expired_global_programs(table, ttl, stats) do

    current_time = System.monotonic_time(:second)

    expiration_time = current_time - ttl

    # Match spec: {program_id, _program_data, timestamp} where timestamp < expiration_time

    # In the tuple: program_id is at element 1, program_data is at element 2, timestamp is at element 3

    match_spec = [

      {{:_, :_, :"$1"}, [{:<, :"$1", expiration_time}], [true]}

    ]

    # Atomically find and delete all expired global programs

    expired_count = :ets.select_delete(table, match_spec)

    if expired_count > 0 do

      Logger.debug("Cleaned up #{expired_count} expired global programs")

    end

    new_stats = Map.update(stats, :global_programs_expired, expired_count, &(&1 + expired_count))

    {expired_count, new_stats}

  end

  # Private helpers for variable operations

  defp get_option(opts, key, default) when is_map(opts) do

    Map.get(opts, key, default)

  end

  defp get_option(opts, key, default) when is_list(opts) do

    Keyword.get(opts, key, default)

  end

  defp get_option(_, _, default), do: default

  defp get_session_internal(state, session_id) do

    case :ets.lookup(state.table, session_id) do

      [{^session_id, {_last_accessed, _ttl, session}}] -> {:ok, session}

      [] -> {:error, :session_not_found}

    end

  end

  defp store_session(state, session_id, session) do

    touched_session = Session.touch(session)

    ets_record =

      {session_id, {touched_session.last_accessed, touched_session.ttl, touched_session}}

    :ets.insert(state.table, ets_record)

    state

  end

  defp generate_variable_id(name) do

    timestamp = System.unique_integer([:positive, :monotonic])

    "var_#{name}_#{timestamp}"

  end

  defp build_variable_metadata(opts) do

    base_metadata = %{

      "source" => "elixir",

      "created_by" => "session_store"

    }

    # Add description if provided

    base_metadata =

      if desc = get_option(opts, :description, nil) do

        Map.put(base_metadata, "description", desc)

      else

        base_metadata

      end

    # Merge any additional metadata

    Map.merge(base_metadata, get_option(opts, :metadata, %{}))

  end

  defp handle_atomic_updates(session, updates, metadata, state, session_id) do

    # First validate all updates

    validation_results =

      Enum.reduce(updates, %{}, fn {id, value}, acc ->

        case validate_update(session, id, value) do

          :ok -> acc

          {:error, reason} -> Map.put(acc, to_string(id), reason)

        end

      end)

    if map_size(validation_results) == 0 do

      # All valid, apply updates

      {updated_session, results} =

        Enum.reduce(updates, {session, %{}}, fn {id, value}, {sess, res} ->

          case apply_update(sess, id, value, metadata) do

            {:ok, new_sess} ->

              {new_sess, Map.put(res, to_string(id), :ok)}

            {:error, reason} ->

              # Shouldn't happen after validation

              {sess, Map.put(res, to_string(id), {:error, reason})}

          end

        end)

      new_state = store_session(state, session_id, updated_session)

      {:reply, {:ok, results}, new_state}

    else

      # Validation failed, return errors

      {:reply, {:error, {:validation_failed, validation_results}}, state}

    end

  end

  defp handle_non_atomic_updates(session, updates, metadata, state, session_id) do

    {updated_session, results} =

      Enum.reduce(updates, {session, %{}}, fn {id, value}, {sess, res} ->

        case apply_update(sess, id, value, metadata) do

          {:ok, new_sess} ->

            {new_sess, Map.put(res, to_string(id), :ok)}

          {:error, reason} ->

            {sess, Map.put(res, to_string(id), {:error, reason})}

        end

      end)

    new_state = store_session(state, session_id, updated_session)

    {:reply, {:ok, results}, new_state}

  end

  defp validate_update(session, identifier, value) do

    with {:ok, variable} <- Session.get_variable(session, identifier),

         {:ok, type_module} <- Types.get_type_module(variable.type),

         {:ok, validated_value} <- type_module.validate(value),

         :ok <- type_module.validate_constraints(validated_value, variable.constraints) do

      :ok

    end

  end

  defp apply_update(session, identifier, value, metadata) do

    with {:ok, variable} <- Session.get_variable(session, identifier),

         {:ok, type_module} <- Types.get_type_module(variable.type),

         {:ok, validated_value} <- type_module.validate(value),

         :ok <- type_module.validate_constraints(validated_value, variable.constraints) do

      updated_variable = Variable.update_value(variable, validated_value, metadata: metadata)

      updated_session = Session.put_variable(session, variable.id, updated_variable)

      {:ok, updated_session}

    end

  end

end

--- END FILE: snakepit/lib/snakepit/bridge/session_store.ex ---

--- START FILE: snakepit/lib/snakepit/grpc/bridge_server.ex ---

defmodule Snakepit.GRPC.BridgeServer do

  @moduledoc """

  gRPC server implementation for the Snakepit Bridge service.

  Handles variable operations, tool execution, and session management

  through the unified bridge protocol.

  """

  use GRPC.Server, service: Snakepit.Bridge.BridgeService.Service

  alias Snakepit.Bridge.SessionStore

  alias Snakepit.Bridge.Variables.{Variable, Types}

  alias Snakepit.Bridge.Serialization

  alias Snakepit.Bridge.ToolRegistry

  alias Snakepit.Bridge.{

    PingRequest,

    PingResponse,

    InitializeSessionResponse,

    CleanupSessionRequest,

    CleanupSessionResponse,

    GetSessionRequest,

    GetSessionResponse,

    HeartbeatRequest,

    HeartbeatResponse,

    RegisterVariableResponse,

    GetVariableRequest,

    GetVariableResponse,

    SetVariableResponse,

    BatchGetVariablesResponse,

    BatchSetVariablesResponse,

    ListVariablesResponse,

    DeleteVariableResponse,

    OptimizationStatus,

    ExecuteToolRequest,

    ExecuteToolResponse,

    RegisterToolsRequest,

    RegisterToolsResponse,

    GetExposedElixirToolsRequest,

    GetExposedElixirToolsResponse,

    ExecuteElixirToolRequest,

    ExecuteElixirToolResponse,

    ToolSpec,

    ParameterSpec

  }

  alias Snakepit.Bridge.Variable, as: ProtoVariable

  alias Google.Protobuf.{Any, Timestamp}

  require Logger

  # Health & Session Management

  def ping(%PingRequest{message: message}, _stream) do

    Logger.debug("Ping received: #{message}")

    %PingResponse{

      message: "pong: #{message}",

      server_time: %Timestamp{seconds: System.system_time(:second), nanos: 0}

    }

  end

  def initialize_session(request, _stream) do

    Logger.info("Initializing session: #{request.session_id}")

    case SessionStore.create_session(request.session_id, metadata: request.metadata) do

      {:ok, _session} ->

        %InitializeSessionResponse{

          success: true,

          error_message: nil,

          # Stage 2

          available_tools: %{},

          initial_variables: %{}

        }

      {:error, :already_exists} ->

        raise GRPC.RPCError,

          status: :already_exists,

          message: "Session already exists: #{request.session_id}"

      {:error, reason} ->

        raise GRPC.RPCError,

          status: :internal,

          message: format_error(reason)

    end

  end

  def cleanup_session(%CleanupSessionRequest{session_id: session_id, force: _force}, _stream) do

    Logger.info("Cleaning up session: #{session_id}")

    # TODO: Implement force flag when supported by SessionStore

    # SessionStore.delete_session always returns :ok

    SessionStore.delete_session(session_id)

    %CleanupSessionResponse{

      success: true,

      resources_cleaned: 1

    }

  end

  def get_session(%GetSessionRequest{session_id: session_id}, _stream) do

    Logger.debug("GetSession: #{session_id}")

    case SessionStore.get_session(session_id) do

      {:ok, session} ->

        variables = Map.get(session, :variables, %{})

        tools = Map.get(session, :tools, %{})

        metadata = Map.get(session, :metadata, %{})

        variable_count = map_size(variables)

        tool_count = map_size(tools)

        %GetSessionResponse{

          session_id: session_id,

          metadata: metadata,

          created_at: %Timestamp{seconds: session.created_at, nanos: 0},

          variable_count: variable_count,

          tool_count: tool_count

        }

      {:error, :not_found} ->

        raise GRPC.RPCError,

          status: :not_found,

          message: "Session not found: #{session_id}"

    end

  end

  def heartbeat(%HeartbeatRequest{session_id: session_id, client_time: _client_time}, _stream) do

    Logger.debug("Heartbeat: #{session_id}")

    # Check if session exists and update last_accessed

    session_valid =

      case SessionStore.get_session(session_id) do

        {:ok, _session} ->

          # Getting the session automatically updates last_accessed

          true

        {:error, :not_found} ->

          false

      end

    %HeartbeatResponse{

      server_time: %Timestamp{seconds: System.system_time(:second), nanos: 0},

      session_valid: session_valid

    }

  end

  # Variable Operations

  def register_variable(request, _stream) do

    Logger.debug("RegisterVariable: session=#{request.session_id}, name=#{request.name}")

    with {:ok, initial_value} <-

           decode_any_value(request.initial_value, request.initial_binary_value),

         {:ok, constraints} <- decode_constraints(request.constraints_json),

         {:ok, var_id} <-

           SessionStore.register_variable(

             request.session_id,

             request.name,

             String.to_atom(request.type),

             initial_value,

             constraints: constraints,

             metadata: request.metadata

           ) do

      %RegisterVariableResponse{

        success: true,

        variable_id: var_id

      }

    else

      {:error, {:validation_failed, _} = reason} ->

        raise GRPC.RPCError,

          status: :invalid_argument,

          message: format_error(reason)

      {:error, :session_not_found} ->

        raise GRPC.RPCError,

          status: :not_found,

          message: "Session not found: #{request.session_id}"

      {:error, reason} ->

        raise GRPC.RPCError,

          status: :internal,

          message: format_error(reason)

    end

  end

  def get_variable(

        %GetVariableRequest{session_id: session_id, variable_identifier: identifier},

        _stream

      ) do

    Logger.debug("GetVariable: session=#{session_id}, id=#{identifier}")

    case SessionStore.get_variable(session_id, identifier) do

      {:ok, variable} ->

        case encode_variable(variable) do

          {:ok, proto_var} ->

            %GetVariableResponse{

              variable: proto_var,

              # TODO: Implement caching in Stage 3

              from_cache: false

            }

          {:error, reason} ->

            Logger.error("Failed to encode variable: #{inspect(reason)}")

            raise GRPC.RPCError, status: :internal, message: format_error(reason)

        end

      {:error, :not_found} ->

        raise GRPC.RPCError, status: :not_found, message: "Variable not found: #{identifier}"

      {:error, :session_not_found} ->

        raise GRPC.RPCError, status: :not_found, message: "Session not found: #{session_id}"

      {:error, reason} ->

        raise GRPC.RPCError, status: :internal, message: format_error(reason)

    end

  end

  def set_variable(request, _stream) do

    Logger.debug("SetVariable: session=#{request.session_id}, id=#{request.variable_identifier}")

    # First get the variable to know its type

    with {:ok, variable} <-

           SessionStore.get_variable(request.session_id, request.variable_identifier),

         {:ok, decoded_value} <-

           decode_typed_value(request.value, variable.type, request.binary_value),

         :ok <-

           SessionStore.update_variable(

             request.session_id,

             request.variable_identifier,

             decoded_value,

             request.metadata

           ) do

      # Get updated variable for version

      new_version =

        case SessionStore.get_variable(request.session_id, request.variable_identifier) do

          {:ok, updated} -> updated.version

          _ -> variable.version + 1

        end

      %SetVariableResponse{

        success: true,

        new_version: new_version

      }

    else

      {:error, :not_found} ->

        raise GRPC.RPCError,

          status: :not_found,

          message: "Variable not found: #{request.variable_identifier}"

      {:error, :session_not_found} ->

        raise GRPC.RPCError,

          status: :not_found,

          message: "Session not found: #{request.session_id}"

      {:error, {:validation_failed, _} = reason} ->

        raise GRPC.RPCError,

          status: :invalid_argument,

          message: format_error(reason)

      {:error, reason} ->

        raise GRPC.RPCError,

          status: :internal,

          message: format_error(reason)

    end

  end

  def get_variables(request, _stream) do

    Logger.debug(

      "GetVariables: session=#{request.session_id}, count=#{length(request.variable_identifiers)}"

    )

    case SessionStore.get_variables(request.session_id, request.variable_identifiers) do

      {:ok, %{found: found, missing: missing}} ->

        # Encode all found variables

        encoded_vars =

          Enum.reduce(found, %{}, fn {id, variable}, acc ->

            case encode_variable(variable) do

              {:ok, proto_var} -> Map.put(acc, id, proto_var)

              # Skip encoding errors

              {:error, _} -> acc

            end

          end)

        %BatchGetVariablesResponse{

          variables: encoded_vars,

          missing_variables: missing

        }

      {:error, :session_not_found} ->

        raise GRPC.RPCError,

          status: :not_found,

          message: "Session not found: #{request.session_id}"

      {:error, reason} ->

        raise GRPC.RPCError, status: :internal, message: format_error(reason)

    end

  end

  def set_variables(request, _stream) do

    Logger.debug(

      "SetVariables: session=#{request.session_id}, count=#{map_size(request.updates)}"

    )

    # Decode all values first

    case decode_updates_map(request.session_id, request.updates, request.binary_updates) do

      {:ok, decoded_updates} ->

        opts = [

          atomic: request.atomic,

          metadata: request.metadata

        ]

        case SessionStore.update_variables(request.session_id, decoded_updates, opts) do

          {:ok, results} ->

            # Convert results to response format

            errors =

              Enum.reduce(results, %{}, fn {id, result}, acc ->

                case result do

                  :ok -> acc

                  {:error, reason} -> Map.put(acc, id, format_error(reason))

                end

              end)

            # Get new versions for successful updates

            new_versions =

              Enum.reduce(results, %{}, fn {id, result}, acc ->

                case result do

                  :ok ->

                    case SessionStore.get_variable(request.session_id, id) do

                      {:ok, var} -> Map.put(acc, id, var.version)

                      _ -> acc

                    end

                  _ ->

                    acc

                end

              end)

            %BatchSetVariablesResponse{

              success: map_size(errors) == 0,

              errors: errors,

              new_versions: new_versions

            }

          {:error, {:validation_failed, errors}} ->

            # Convert validation errors

            error_map =

              Enum.reduce(errors, %{}, fn {id, reason}, acc ->

                Map.put(acc, id, format_error(reason))

              end)

            %BatchSetVariablesResponse{

              success: false,

              errors: error_map,

              new_versions: %{}

            }

          {:error, reason} ->

            raise GRPC.RPCError, status: :internal, message: format_error(reason)

        end

      {:error, reason} ->

        raise GRPC.RPCError, status: :invalid_argument, message: format_error(reason)

    end

  end

  def list_variables(request, _stream) do

    Logger.debug("ListVariables: session=#{request.session_id}")

    case SessionStore.get_session(request.session_id) do

      {:ok, session} ->

        # Apply pattern filter if provided

        variables =

          if request.pattern && request.pattern != "" do

            pattern = String.replace(request.pattern, "*", ".*")

            regex = Regex.compile!(pattern)

            session.variables

            |> Map.values()

            |> Enum.filter(fn var ->

              Regex.match?(regex, to_string(var.name))

            end)

          else

            Map.values(session.variables)

          end

        # Encode all variables

        encoded_vars =

          Enum.reduce(variables, [], fn variable, acc ->

            case encode_variable(variable) do

              {:ok, proto_var} -> [proto_var | acc]

              # Skip encoding errors

              {:error, _} -> acc

            end

          end)

          |> Enum.reverse()

        %ListVariablesResponse{

          variables: encoded_vars

        }

      {:error, :not_found} ->

        raise GRPC.RPCError,

          status: :not_found,

          message: "Session not found: #{request.session_id}"

    end

  end

  def delete_variable(request, _stream) do

    Logger.debug(

      "DeleteVariable: session=#{request.session_id}, id=#{request.variable_identifier}"

    )

    case SessionStore.delete_variable(request.session_id, request.variable_identifier) do

      :ok ->

        %DeleteVariableResponse{

          success: true

        }

      {:error, :not_found} ->

        raise GRPC.RPCError,

          status: :not_found,

          message: "Variable not found: #{request.variable_identifier}"

      {:error, :session_not_found} ->

        raise GRPC.RPCError,

          status: :not_found,

          message: "Session not found: #{request.session_id}"

      {:error, reason} ->

        raise GRPC.RPCError,

          status: :internal,

          message: format_error(reason)

    end

  end

  # TODO: Implement remaining handlers

  def execute_tool(%ExecuteToolRequest{} = request, _stream) do

    Logger.info("ExecuteTool: #{request.tool_name} for session #{request.session_id}")

    start_time = System.monotonic_time(:millisecond)

    with {:ok, _session} <- SessionStore.get_session(request.session_id),

         {:ok, tool} <- ToolRegistry.get_tool(request.session_id, request.tool_name),

         {:ok, result} <- execute_tool_handler(tool, request, request.session_id) do

      execution_time = System.monotonic_time(:millisecond) - start_time

      %ExecuteToolResponse{

        success: true,

        result: encode_tool_result(result),

        error_message: nil,

        metadata: %{

          "execution_time" => to_string(execution_time),

          "tool_type" => to_string(tool.type)

        },

        execution_time_ms: execution_time

      }

    else

      {:error, reason} ->

        %ExecuteToolResponse{

          success: false,

          result: nil,

          error_message: format_error(reason),

          metadata: %{},

          execution_time_ms: System.monotonic_time(:millisecond) - start_time

        }

    end

  end

  defp execute_tool_handler(%{type: :local} = tool, request, session_id) do

    # Execute local Elixir tool

    params = decode_tool_parameters(request.parameters)

    ToolRegistry.execute_local_tool(session_id, tool.name, params)

  end

  defp execute_tool_handler(%{type: :remote} = tool, request, session_id) do

    # Forward to Python worker

    Logger.debug("Executing remote tool #{tool.name} on worker #{tool.worker_id}")

    with {:ok, worker_port} <- get_worker_port(tool.worker_id),

         {:ok, channel} <- create_worker_channel(worker_port),

         {:ok, result} <- forward_tool_to_worker(channel, request, session_id) do

      # Channel will be cleaned up automatically

      {:ok, result}

    else

      {:error, reason} ->

        Logger.error("Failed to execute remote tool #{tool.name}: #{inspect(reason)}")

        {:error, "Remote tool execution failed: #{inspect(reason)}"}

    end

  end

  defp decode_tool_parameters(params) do

    params

    |> Enum.map(fn {key, any_value} ->

      # Decode the protobuf Any value

      decoded =

        case any_value do

          %Any{type_url: "type.googleapis.com/google.protobuf.StringValue", value: value} ->

            # The value is JSON encoded as bytes, decode it

            case Jason.decode(value) do

              {:ok, decoded} -> decoded

              # Return as-is if not valid JSON

              {:error, _} -> value

            end

          _ ->

            # Try to use the serialization module

            Serialization.decode_any(any_value)

        end

      {key, decoded}

    end)

    |> Map.new()

  end

  # Helper functions for remote tool execution

  defp get_worker_port(worker_id) do

    # For now, try to get from the worker registry

    # In a production implementation, this would be stored in a registry

    case Registry.lookup(Snakepit.Pool.Registry, worker_id) do

      [{pid, _}] when is_pid(pid) ->

        # Try to get port from worker state - this is a simplified approach

        try do

          case GenServer.call(pid, :get_port, 1000) do

            {:ok, port} -> {:ok, port}

            _ -> {:error, "Could not get port from worker"}

          end

        catch

          _exit, _reason -> {:error, "Worker not responding"}

        end

      [] ->

        {:error, "Worker not found: #{worker_id}"}

    end

  end

  defp create_worker_channel(port) do

    try do

      GRPC.Stub.connect("localhost:#{port}")

    rescue

      error -> {:error, "Failed to connect to worker: #{inspect(error)}"}

    end

  end

  defp forward_tool_to_worker(channel, request, session_id) do

    # Forward the ExecuteToolRequest to the Python worker's gRPC server

    alias Snakepit.Bridge.BridgeService.Stub

    # Create the request to forward to the worker

    worker_request = %ExecuteToolRequest{

      session_id: session_id,

      tool_name: request.tool_name,

      parameters: request.parameters,

      metadata: request.metadata

    }

    try do

      case Stub.execute_tool(channel, worker_request) do

        {:ok, response} ->

          if response.success do

            {:ok, response.result}

          else

            {:error, response.error_message}

          end

        {:error, reason} ->

          {:error, "gRPC call failed: #{inspect(reason)}"}

      end

    rescue

      error -> {:error, "Exception during gRPC call: #{inspect(error)}"}

    end

  end

  def execute_streaming_tool(_request, _stream) do

    raise GRPC.RPCError,

      status: :unimplemented,

      message: "Streaming tool execution not yet implemented"

  end

  def watch_variables(_request, _stream) do

    raise GRPC.RPCError,

      status: :unimplemented,

      message: "Variable watching not yet implemented (Stage 3)"

  end

  # Encoding/Decoding Helpers

  defp decode_any_value(%Any{} = any_value, binary_data) do

    Serialization.decode_any(any_value, binary_data)

  end

  defp decode_typed_value(%Any{} = any_value, expected_type, binary_data) do

    with {:ok, decoded} <- Serialization.decode_any(any_value, binary_data),

         {:ok, validated} <- Types.validate_value(decoded, expected_type) do

      {:ok, validated}

    end

  end

  defp decode_constraints(json) do

    case Serialization.parse_constraints(json) do

      {:ok, constraints} ->

        # Convert string keys to atoms

        atomized =

          Enum.reduce(constraints, %{}, fn {k, v}, acc ->

            Map.put(acc, String.to_atom(k), v)

          end)

        {:ok, atomized}

      {:error, reason} ->

        {:error, {:invalid_constraints, reason}}

    end

  end

  defp encode_variable(variable, default_source \\ :ELIXIR) do

    with {:ok, value_any, binary_data} <- encode_any_value(variable.value, variable.type) do

      # Check metadata for source, falling back to default

      source =

        case variable.metadata["source"] do

          "python" -> :PYTHON

          "elixir" -> :ELIXIR

          "PYTHON" -> :PYTHON

          "ELIXIR" -> :ELIXIR

          nil -> default_source

          _ -> default_source

        end

      proto_var = %ProtoVariable{

        id: variable.id,

        name: to_string(variable.name),

        type: to_string(variable.type),

        value: value_any,

        constraints_json: Jason.encode!(variable.constraints),

        metadata: variable.metadata,

        source: source,

        last_updated_at: %Timestamp{seconds: variable.last_updated_at, nanos: 0},

        version: variable.version,

        optimization_status: encode_optimization_status(variable),

        # Set binary_value if we have binary data

        binary_value: binary_data

      }

      {:ok, proto_var}

    end

  end

  defp encode_any_value(value, type) do

    case Serialization.encode_any(value, type) do

      {:ok, %{type_url: type_url, value: encoded_value}, binary_data} ->

        {:ok,

         %Any{

           type_url: type_url,

           value: encoded_value

         }, binary_data}

      {:error, reason} ->

        {:error, "Failed to encode value: #{inspect(reason)}"}

    end

  end

  defp encode_optimization_status(variable) do

    if Variable.optimizing?(variable) do

      %OptimizationStatus{

        optimizing: true,

        optimizer_id: variable.optimization_status.optimizer_id || "",

        started_at:

          if(variable.optimization_status.started_at,

            do: %Timestamp{seconds: variable.optimization_status.started_at, nanos: 0},

            else: nil

          )

      }

    else

      %OptimizationStatus{

        optimizing: false

      }

    end

  end

  defp decode_updates_map(session_id, updates, binary_updates) do

    # First get variable types for decoding

    identifiers = Map.keys(updates)

    case SessionStore.get_variables(session_id, identifiers) do

      {:ok, %{found: found}} ->

        decoded =

          Enum.reduce_while(updates, {:ok, %{}}, fn {id, any_val}, {:ok, acc} ->

            case Map.get(found, to_string(id)) do

              nil ->

                {:halt, {:error, "Variable not found: #{id}"}}

              variable ->

                # Check if we have binary data for this variable

                binary_data = Map.get(binary_updates, id)

                case decode_typed_value(any_val, variable.type, binary_data) do

                  {:ok, value} -> {:cont, {:ok, Map.put(acc, id, value)}}

                  {:error, reason} -> {:halt, {:error, reason}}

                end

            end

          end)

        decoded

      {:error, reason} ->

        {:error, reason}

    end

  end

  defp format_error(reason) when is_binary(reason), do: reason

  defp format_error(reason) when is_atom(reason), do: to_string(reason)

  defp format_error({:error, reason}), do: format_error(reason)

  defp format_error({:unknown_type, type}), do: "Unknown type: #{inspect(type)}"

  defp format_error({:invalid_constraints, reason}), do: "Invalid constraints: #{reason}"

  defp format_error({:validation_failed, details}) when is_map(details) do

    "Validation failed: #{inspect(details)}"

  end

  defp format_error(reason), do: inspect(reason)

  # Tool Registration & Discovery

  def register_tools(%RegisterToolsRequest{} = request, _stream) do

    Logger.info("RegisterTools for session #{request.session_id}, worker: #{request.worker_id}")

    with {:ok, _session} <- SessionStore.get_session(request.session_id) do

      # Convert proto ToolRegistration to internal format

      tool_specs =

        Enum.map(request.tools, fn tool_reg ->

          %{

            name: tool_reg.name,

            description: tool_reg.description,

            parameters: tool_reg.parameters,

            metadata:

              Map.put(

                tool_reg.metadata,

                "supports_streaming",

                to_string(tool_reg.supports_streaming)

              ),

            worker_id: request.worker_id

          }

        end)

      case ToolRegistry.register_tools(request.session_id, tool_specs) do

        {:ok, registered_names} ->

          tool_ids =

            Map.new(registered_names, fn name -> {name, "#{request.session_id}:#{name}"} end)

          %RegisterToolsResponse{

            success: true,

            tool_ids: tool_ids,

            error_message: nil

          }

        {:error, reason} ->

          %RegisterToolsResponse{

            success: false,

            tool_ids: %{},

            error_message: format_error(reason)

          }

      end

    else

      {:error, reason} ->

        %RegisterToolsResponse{

          success: false,

          tool_ids: %{},

          error_message: format_error(reason)

        }

    end

  end

  def get_exposed_elixir_tools(%GetExposedElixirToolsRequest{session_id: session_id}, _stream) do

    Logger.debug("GetExposedElixirTools for session #{session_id}")

    tools = ToolRegistry.list_exposed_elixir_tools(session_id)

    tool_specs =

      Enum.map(tools, fn tool ->

        # Convert metadata, handling different value types

        metadata =

          Map.new(tool.metadata, fn

            {k, v} when is_binary(v) or is_atom(v) or is_number(v) ->

              {to_string(k), to_string(v)}

            {k, v} when is_list(v) ->

              # Don't include complex lists in metadata

              {to_string(k), inspect(v)}

            {k, v} ->

              # For other types, use inspect

              {to_string(k), inspect(v)}

          end)

        # Remove parameters from metadata since they're handled separately

        metadata = Map.delete(metadata, "parameters")

        %ToolSpec{

          name: tool.name,

          description: tool.description,

          parameters: encode_parameter_specs(tool.parameters),

          metadata: metadata,

          supports_streaming: Map.get(metadata, "supports_streaming", "false") == "true",

          required_variables: Map.get(metadata, "required_variables", [])

        }

      end)

    %GetExposedElixirToolsResponse{

      tools: tool_specs

    }

  end

  def execute_elixir_tool(%ExecuteElixirToolRequest{} = request, _stream) do

    Logger.info("ExecuteElixirTool: #{request.tool_name} for session #{request.session_id}")

    start_time = System.monotonic_time(:millisecond)

    with {:ok, _session} <- SessionStore.get_session(request.session_id),

         {:ok, tool} <- ToolRegistry.get_tool(request.session_id, request.tool_name),

         :local <- tool.type,

         params <- decode_tool_parameters(request.parameters),

         {:ok, result} <-

           ToolRegistry.execute_local_tool(request.session_id, request.tool_name, params) do

      execution_time = System.monotonic_time(:millisecond) - start_time

      %ExecuteElixirToolResponse{

        success: true,

        result: encode_tool_result(result),

        error_message: nil,

        metadata: %{

          "execution_time" => to_string(execution_time)

        },

        execution_time_ms: execution_time

      }

    else

      :remote ->

        %ExecuteElixirToolResponse{

          success: false,

          result: nil,

          error_message: "Tool #{request.tool_name} is not an Elixir tool",

          metadata: %{},

          execution_time_ms: System.monotonic_time(:millisecond) - start_time

        }

      {:error, reason} ->

        %ExecuteElixirToolResponse{

          success: false,

          result: nil,

          error_message: format_error(reason),

          metadata: %{},

          execution_time_ms: System.monotonic_time(:millisecond) - start_time

        }

    end

  end

  defp encode_parameter_specs(params) when is_list(params) do

    Enum.map(params, fn param ->

      # Convert atom keys to strings

      param =

        case param do

          %{} -> Map.new(param, fn {k, v} -> {to_string(k), v} end)

          _ -> param

        end

      %ParameterSpec{

        name: Map.get(param, "name", ""),

        type: to_string(Map.get(param, "type", "any")),

        description: to_string(Map.get(param, "description", "")),

        required: Map.get(param, "required", false),

        default_value: encode_default_value(Map.get(param, "default")),

        validation_json: Jason.encode!(Map.get(param, "validation", %{}))

      }

    end)

  end

  defp encode_parameter_specs(_), do: []

  defp encode_default_value(nil), do: nil

  defp encode_default_value(value), do: encode_tool_result(value)

  defp encode_tool_result(value) do

    # Encode tool results as JSON since we don't know the specific type

    case Jason.encode(value) do

      {:ok, json_string} when is_binary(json_string) ->

        # Ensure the value is properly encoded as bytes

        %Any{

          type_url: "type.googleapis.com/google.protobuf.StringValue",

          # This should already be a binary string

          value: json_string

        }

      {:error, _} ->

        # Fallback: encode as string representation

        %Any{

          type_url: "type.googleapis.com/google.protobuf.StringValue",

          # inspect always returns a string

          value: inspect(value)

        }

    end

  end

end

--- END FILE: snakepit/lib/snakepit/grpc/bridge_server.ex ---

--- START FILE: snakepit/lib/snakepit.ex ---

defmodule Snakepit do

  @moduledoc """

  Snakepit - A generalized high-performance pooler and session manager.

  Extracted from DSPex V3 pool implementation, Snakepit provides:

  - Concurrent worker initialization and management

  - Stateless pool system with session affinity 

  - Generalized adapter pattern for any external process

  - High-performance OTP-based process management

  ## Basic Usage

      # Configure in config/config.exs

      config :snakepit,

        pooling_enabled: true,

        adapter_module: YourAdapter

      # Execute commands on any available worker

      {:ok, result} = Snakepit.execute("ping", %{test: true})

      

      # Session-based execution with worker affinity

      {:ok, result} = Snakepit.execute_in_session("my_session", "command", %{})

  ## Domain-Specific Helpers

  For ML/DSP workflows with program management, see `Snakepit.SessionHelpers`:

      # ML program creation and execution

      {:ok, result} = Snakepit.SessionHelpers.execute_program_command(

        "session_id", "create_program", %{signature: "input -> output"}

      )

  """

  @doc """

  Convenience function to execute commands on the pool.

  """

  def execute(command, args, opts \\ []) do

    Snakepit.Pool.execute(command, args, opts)

  end

  @doc """

  Executes a command in session context with worker affinity.

  This function executes commands with session-based worker affinity,

  ensuring that subsequent calls with the same session_id prefer

  the same worker when possible for state continuity.

  Args are passed through unchanged - no domain-specific enhancement.

  For ML/DSP program workflows, use `Snakepit.SessionHelpers.execute_program_command/4`.

  """

  def execute_in_session(session_id, command, args, opts \\ []) do

    # Add session_id to opts for session affinity

    opts_with_session = Keyword.put(opts, :session_id, session_id)

    # Execute command with session affinity (no args enhancement)

    execute(command, args, opts_with_session)

  end

  @doc """

  Get pool statistics.

  """

  def get_stats(pool \\ Snakepit.Pool) do

    Snakepit.Pool.get_stats(pool)

  end

  @doc """

  List workers from the pool.

  """

  def list_workers(pool \\ Snakepit.Pool) do

    Snakepit.Pool.list_workers(pool)

  end

  @doc """

  Executes a streaming command with a callback function.

  ## Examples

      Snakepit.execute_stream("batch_inference", %{items: [...]}, fn chunk ->

        IO.puts("Received: \#{inspect(chunk)}")

      end)

  ## Options

    * `:pool` - The pool to use (default: `Snakepit.Pool`)

    * `:timeout` - Request timeout in ms (default: 300000)

    * `:session_id` - Run in a specific session

  ## Returns

  Returns `:ok` on success or `{:error, reason}` on failure.

  Note: Streaming is only supported with gRPC adapters.

  """

  @spec execute_stream(String.t(), map(), function(), keyword()) :: :ok | {:error, term()}

  def execute_stream(command, args \\ %{}, callback_fn, opts \\ []) do

    ensure_started!()

    adapter = Application.get_env(:snakepit, :adapter_module)

    unless function_exported?(adapter, :uses_grpc?, 0) and adapter.uses_grpc?() do

      {:error, :streaming_not_supported}

    else

      Snakepit.Pool.execute_stream(command, args, callback_fn, opts)

    end

  end

  @doc """

  Executes a command in a session with a callback function.

  """

  @spec execute_in_session_stream(String.t(), String.t(), map(), function(), keyword()) ::

          :ok | {:error, term()}

  def execute_in_session_stream(session_id, command, args \\ %{}, callback_fn, opts \\ []) do

    ensure_started!()

    adapter = Application.get_env(:snakepit, :adapter_module)

    unless function_exported?(adapter, :uses_grpc?, 0) and adapter.uses_grpc?() do

      {:error, :streaming_not_supported}

    else

      opts_with_session = Keyword.put(opts, :session_id, session_id)

      Snakepit.Pool.execute_stream(command, args, callback_fn, opts_with_session)

    end

  end

  defp ensure_started! do

    case Application.ensure_all_started(:snakepit) do

      {:ok, _} -> :ok

      {:error, _} -> raise "Snakepit application not started"

    end

  end

  @doc """

  Starts the Snakepit application, executes a given function,

  and ensures graceful shutdown.

  This is the recommended way to use Snakepit for short-lived scripts or

  Mix tasks to prevent orphaned processes.

  It handles the full OTP application lifecycle (start, run, stop)

  automatically.

  ## Examples

      # In a Mix task

      Snakepit.run_as_script(fn ->

        {:ok, result} = Snakepit.execute("my_command", %{data: "value"})

        IO.inspect(result)

      end)

      # For demos or scripts

      Snakepit.run_as_script(fn ->

        MyApp.run_load_test()

      end)

  ## Options

    * `:timeout` - Maximum time to wait for pool initialization (default: 15000ms)

  ## Returns

  Returns the result of the provided function, or `{:error, reason}` if

  the pool fails to initialize.

  """

  @spec run_as_script((-> any()), keyword()) :: any() | {:error, term()}

  def run_as_script(fun, opts \\ []) when is_function(fun, 0) do

    timeout = Keyword.get(opts, :timeout, 15_000)

    # Ensure all dependencies are started, including Snakepit itself

    {:ok, _apps} = Application.ensure_all_started(:snakepit)

    # Deterministically wait for the pool to be fully initialized

    case Snakepit.Pool.await_ready(Snakepit.Pool, timeout) do

      :ok ->

        try do

          fun.()

        after

          IO.puts("\n[Snakepit] Script execution finished. Shutting down gracefully...")

          # This is the crucial step: ensure the application is stopped,

          # which will trigger all terminate/2 cleanup callbacks.

          Application.stop(:snakepit)

          # Give the cleanup callbacks a moment to execute

          # This is still needed because Application.stop is async

          Process.sleep(500)

          IO.puts("[Snakepit] Shutdown complete.")

        end

      {:error, :timeout} ->

        IO.puts("[Snakepit] Error: Pool failed to initialize within #{timeout}ms")

        Application.stop(:snakepit)

        {:error, :pool_initialization_timeout}

    end

  end

  # Note: For ML/DSP program management functionality, see Snakepit.SessionHelpers

end

--- END FILE: snakepit/lib/snakepit.ex ---

--- START FILE: snakepit/priv/proto/snakepit_bridge.proto ---

syntax = "proto3";

package snakepit.bridge;

import "google/protobuf/any.proto";

import "google/protobuf/timestamp.proto";

service BridgeService {

  // Health & Session Management

  rpc Ping(PingRequest) returns (PingResponse);

  rpc InitializeSession(InitializeSessionRequest) returns (InitializeSessionResponse);

  rpc CleanupSession(CleanupSessionRequest) returns (CleanupSessionResponse);

  rpc GetSession(GetSessionRequest) returns (GetSessionResponse);

  rpc Heartbeat(HeartbeatRequest) returns (HeartbeatResponse);

  

  // Variable Operations

  rpc GetVariable(GetVariableRequest) returns (GetVariableResponse);

  rpc SetVariable(SetVariableRequest) returns (SetVariableResponse);

  rpc GetVariables(BatchGetVariablesRequest) returns (BatchGetVariablesResponse);

  rpc SetVariables(BatchSetVariablesRequest) returns (BatchSetVariablesResponse);

  rpc RegisterVariable(RegisterVariableRequest) returns (RegisterVariableResponse);

  rpc ListVariables(ListVariablesRequest) returns (ListVariablesResponse);

  rpc DeleteVariable(DeleteVariableRequest) returns (DeleteVariableResponse);

  

  // Tool Execution

  rpc ExecuteTool(ExecuteToolRequest) returns (ExecuteToolResponse);

  rpc ExecuteStreamingTool(ExecuteToolRequest) returns (stream ToolChunk);

  

  // Tool Registration & Discovery

  rpc RegisterTools(RegisterToolsRequest) returns (RegisterToolsResponse);

  rpc GetExposedElixirTools(GetExposedElixirToolsRequest) returns (GetExposedElixirToolsResponse);

  rpc ExecuteElixirTool(ExecuteElixirToolRequest) returns (ExecuteElixirToolResponse);

  

  // Streaming & Reactive

  rpc WatchVariables(WatchVariablesRequest) returns (stream VariableUpdate);

  

  // Advanced Features (Stage 4)

  rpc AddDependency(AddDependencyRequest) returns (AddDependencyResponse);

  rpc StartOptimization(StartOptimizationRequest) returns (StartOptimizationResponse);

  rpc StopOptimization(StopOptimizationRequest) returns (StopOptimizationResponse);

  rpc GetVariableHistory(GetVariableHistoryRequest) returns (GetVariableHistoryResponse);

  rpc RollbackVariable(RollbackVariableRequest) returns (RollbackVariableResponse);

}

// Core Messages

message PingRequest {

  string message = 1;

}

message PingResponse {

  string message = 1;

  google.protobuf.Timestamp server_time = 2;

}

message InitializeSessionRequest {

  string session_id = 1;

  map<string, string> metadata = 2;

  SessionConfig config = 3;

}

message SessionConfig {

  bool enable_caching = 1;

  int32 cache_ttl_seconds = 2;

  bool enable_telemetry = 3;

}

message InitializeSessionResponse {

  bool success = 1;

  string error_message = 2;

  map<string, ToolSpec> available_tools = 3;

  map<string, Variable> initial_variables = 4;

}

message CleanupSessionRequest {

  string session_id = 1;

  bool force = 2;

}

message CleanupSessionResponse {

  bool success = 1;

  int32 resources_cleaned = 2;

}

// Variable Messages

message Variable {

  string id = 1;

  string name = 2;

  string type = 3;

  google.protobuf.Any value = 4;

  string constraints_json = 5;

  map<string, string> metadata = 6;

  enum Source {

    ELIXIR = 0;

    PYTHON = 1;

  }

  Source source = 7;

  google.protobuf.Timestamp last_updated_at = 8;

  int32 version = 9;

  

  // Advanced fields (Stage 4)

  string access_control_json = 10;

  OptimizationStatus optimization_status = 11;

  

  // Binary data field for large values (e.g., tensors, embeddings)

  // When present, this takes precedence over the Any value field

  // Format should be specified in metadata (e.g., "binary_format": "numpy", "dtype": "float32")

  bytes binary_value = 12;

}

message OptimizationStatus {

  bool optimizing = 1;

  string optimizer_id = 2;

  google.protobuf.Timestamp started_at = 3;

}

message RegisterVariableRequest {

  string session_id = 1;

  string name = 2;

  string type = 3;

  google.protobuf.Any initial_value = 4;

  string constraints_json = 5;

  map<string, string> metadata = 6;

  

  // Binary data for large initial values (e.g., tensors, embeddings)

  // When present, this takes precedence over the Any initial_value field for data

  bytes initial_binary_value = 7;

}

message RegisterVariableResponse {

  bool success = 1;

  string variable_id = 2;

  string error_message = 3;

}

message GetVariableRequest {

  string session_id = 1;

  string variable_identifier = 2; // Can be ID or name

  bool bypass_cache = 3;

}

message GetVariableResponse {

  Variable variable = 1;

  bool from_cache = 2;

}

message SetVariableRequest {

  string session_id = 1;

  string variable_identifier = 2;

  google.protobuf.Any value = 3;

  map<string, string> metadata = 4;

  int32 expected_version = 5; // For optimistic locking

  

  // Binary data for large values (e.g., tensors, embeddings)

  // When present, this takes precedence over the Any value field for data

  bytes binary_value = 6;

}

message SetVariableResponse {

  bool success = 1;

  string error_message = 2;

  int32 new_version = 3;

}

message BatchGetVariablesRequest {

  string session_id = 1;

  repeated string variable_identifiers = 2;

  bool include_metadata = 3;

  bool bypass_cache = 4;

}

message BatchGetVariablesResponse {

  map<string, Variable> variables = 1;

  repeated string missing_variables = 2;

}

message BatchSetVariablesRequest {

  string session_id = 1;

  map<string, google.protobuf.Any> updates = 2;

  map<string, string> metadata = 3;

  bool atomic = 4;

  

  // Binary data for large values, keyed by variable identifier

  // When a key exists here, its data takes precedence over the Any value in updates

  map<string, bytes> binary_updates = 5;

}

message BatchSetVariablesResponse {

  bool success = 1;

  map<string, string> errors = 2;

  map<string, int32> new_versions = 3;

}

message ListVariablesRequest {

  string session_id = 1;

  string pattern = 2; // Optional wildcard pattern for filtering

}

message ListVariablesResponse {

  repeated Variable variables = 1;

}

message DeleteVariableRequest {

  string session_id = 1;

  string variable_identifier = 2; // Can be ID or name

}

message DeleteVariableResponse {

  bool success = 1;

  string error_message = 2;

}

// Tool Messages

message ToolSpec {

  string name = 1;

  string description = 2;

  repeated ParameterSpec parameters = 3;

  map<string, string> metadata = 4;

  bool supports_streaming = 5;

  repeated string required_variables = 6;

}

message ParameterSpec {

  string name = 1;

  string type = 2;

  string description = 3;

  bool required = 4;

  google.protobuf.Any default_value = 5;

  string validation_json = 6;

}

message ExecuteToolRequest {

  string session_id = 1;

  string tool_name = 2;

  map<string, google.protobuf.Any> parameters = 3;

  map<string, string> metadata = 4;

  bool stream = 5;

  

  // Binary parameters for large data (e.g., images, audio, video)

  // Keys should match parameter names, metadata should describe format

  map<string, bytes> binary_parameters = 6;

}

message ExecuteToolResponse {

  bool success = 1;

  google.protobuf.Any result = 2;

  string error_message = 3;

  map<string, string> metadata = 4;

  int64 execution_time_ms = 5;

}

message ToolChunk {

  string chunk_id = 1;

  bytes data = 2;

  bool is_final = 3;

  map<string, string> metadata = 4;

}

// Streaming Messages

message WatchVariablesRequest {

  string session_id = 1;

  repeated string variable_identifiers = 2;

  bool include_initial_values = 3;

}

message VariableUpdate {

  string variable_id = 1;

  Variable variable = 2;

  string update_source = 3;

  map<string, string> update_metadata = 4;

  google.protobuf.Timestamp timestamp = 5;

  string update_type = 6; // "value_change", "constraint_change", etc.

}

// Advanced Messages (Stage 4)

message AddDependencyRequest {

  string session_id = 1;

  string from_variable = 2;

  string to_variable = 3;

  string dependency_type = 4;

}

message AddDependencyResponse {

  bool success = 1;

  string error_message = 2;

}

message StartOptimizationRequest {

  string session_id = 1;

  string variable_identifier = 2;

  string optimizer_id = 3;

  map<string, string> optimizer_config = 4;

}

message StartOptimizationResponse {

  bool success = 1;

  string error_message = 2;

  string optimization_id = 3;

}

message StopOptimizationRequest {

  string session_id = 1;

  string variable_identifier = 2;

  bool force = 3;

}

message StopOptimizationResponse {

  bool success = 1;

  google.protobuf.Any final_value = 2;

}

message GetVariableHistoryRequest {

  string session_id = 1;

  string variable_identifier = 2;

  int32 limit = 3;

}

message GetVariableHistoryResponse {

  repeated VariableHistoryEntry entries = 1;

}

message VariableHistoryEntry {

  int32 version = 1;

  google.protobuf.Any value = 2;

  google.protobuf.Timestamp timestamp = 3;

  string changed_by = 4;

  map<string, string> metadata = 5;

}

message RollbackVariableRequest {

  string session_id = 1;

  string variable_identifier = 2;

  int32 target_version = 3;

}

message RollbackVariableResponse {

  bool success = 1;

  Variable variable = 2;

  string error_message = 3;

}

// Session Management Messages

message GetSessionRequest {

  string session_id = 1;

}

message GetSessionResponse {

  string session_id = 1;

  map<string, string> metadata = 2;

  google.protobuf.Timestamp created_at = 3;

  int32 variable_count = 4;

  int32 tool_count = 5;

}

message HeartbeatRequest {

  string session_id = 1;

  google.protobuf.Timestamp client_time = 2;

}

message HeartbeatResponse {

  google.protobuf.Timestamp server_time = 1;

  bool session_valid = 2;

}

// Tool Registration & Discovery Messages

message RegisterToolsRequest {

  string session_id = 1;

  repeated ToolRegistration tools = 2;

  string worker_id = 3;

}

message ToolRegistration {

  string name = 1;

  string description = 2;

  repeated ParameterSpec parameters = 3;

  map<string, string> metadata = 4;

  bool supports_streaming = 5;

}

message RegisterToolsResponse {

  bool success = 1;

  map<string, string> tool_ids = 2;

  string error_message = 3;

}

message GetExposedElixirToolsRequest {

  string session_id = 1;

}

message GetExposedElixirToolsResponse {

  repeated ToolSpec tools = 1;

}

message ExecuteElixirToolRequest {

  string session_id = 1;

  string tool_name = 2;

  map<string, google.protobuf.Any> parameters = 3;

  map<string, string> metadata = 4;

}

message ExecuteElixirToolResponse {

  bool success = 1;

  google.protobuf.Any result = 2;

  string error_message = 3;

  map<string, string> metadata = 4;

  int64 execution_time_ms = 5;

}--- END FILE: snakepit/priv/proto/snakepit_bridge.proto ---

--- START FILE: snakepit/priv/python/snakepit_bridge/base_adapter.py ---

"""

Base adapter class for Snakepit Python adapters.

Provides tool discovery and registration functionality that all adapters should inherit from.

"""

import inspect

from typing import List, Dict, Any, Callable, Optional

from dataclasses import dataclass

import logging

from snakepit_bridge_pb2 import ToolRegistration, ParameterSpec

import snakepit_bridge_pb2 as pb2

logger = logging.getLogger(__name__)

@dataclass

class ToolMetadata:

    """Metadata for a tool function."""

    description: str = ""

    supports_streaming: bool = False

    parameters: List[Dict[str, Any]] = None

    required_variables: List[str] = None

    

    def __post_init__(self):

        if self.parameters is None:

            self.parameters = []

        if self.required_variables is None:

            self.required_variables = []

def tool(description: str = "", 

         supports_streaming: bool = False,

         required_variables: List[str] = None):

    """

    Decorator to mark a method as a tool and attach metadata.

    

    Example:

        @tool(description="Search for items", supports_streaming=True)

        def search(self, query: str, limit: int = 10):

            return search_results

    """

    def decorator(func):

        metadata = ToolMetadata(

            description=description or func.__doc__ or "",

            supports_streaming=supports_streaming,

            required_variables=required_variables or []

        )

        func._tool_metadata = metadata

        return func

    return decorator

class BaseAdapter:

    """Base class for all Snakepit Python adapters."""

    

    def __init__(self):

        self._tools_cache = None

        

    def get_tools(self) -> List[ToolRegistration]:

        """

        Discover and return tool specifications for all tools in this adapter.

        

        Returns:

            List of ToolRegistration protobuf messages

        """

        if self._tools_cache is not None:

            return self._tools_cache

            

        tools = []

        

        # Discover all methods marked with @tool decorator

        for name, method in inspect.getmembers(self, inspect.ismethod):

            if hasattr(method, '_tool_metadata'):

                tool_reg = self._create_tool_registration(name, method)

                tools.append(tool_reg)

        

        # Also discover execute_tool methods for backward compatibility

        if hasattr(self, 'execute_tool') and not any(t.name == 'execute_tool' for t in tools):

            # Legacy support - treat execute_tool as a tool if not decorated

            tool_reg = ToolRegistration(

                name='execute_tool',

                description='Legacy tool execution method',

                supports_streaming=False,

                parameters=[],

                metadata={}

            )

            tools.append(tool_reg)

        

        self._tools_cache = tools

        return tools

    

    def _create_tool_registration(self, name: str, method: Callable) -> ToolRegistration:

        """Create a ToolRegistration from a method and its metadata."""

        metadata = getattr(method, '_tool_metadata', ToolMetadata())

        

        # Extract parameters from function signature

        sig = inspect.signature(method)

        parameters = []

        

        for param_name, param in sig.parameters.items():

            if param_name == 'self':

                continue

                

            param_spec = self._create_parameter_spec(param_name, param)

            parameters.append(param_spec)

        

        # Create metadata dict

        tool_metadata = {

            'adapter_class': self.__class__.__name__,

            'module': self.__class__.__module__,

        }

        

        if metadata.required_variables:

            tool_metadata['required_variables'] = ','.join(metadata.required_variables)

        

        return ToolRegistration(

            name=name,

            description=metadata.description,

            parameters=parameters,

            supports_streaming=metadata.supports_streaming,

            metadata=tool_metadata

        )

    

    def _create_parameter_spec(self, name: str, param: inspect.Parameter) -> ParameterSpec:

        """Create a ParameterSpec from a function parameter."""

        # Determine type from annotation

        param_type = 'any'

        if param.annotation != inspect.Parameter.empty:

            type_name = getattr(param.annotation, '__name__', str(param.annotation))

            param_type = type_name.lower()

        

        # Check if required

        required = param.default == inspect.Parameter.empty

        

        # Create parameter spec

        param_spec = ParameterSpec(

            name=name,

            type=param_type,

            description="",  # Could be enhanced with docstring parsing

            required=required

        )

        

        # Set default value if present

        if param.default != inspect.Parameter.empty:

            # For now, store defaults as JSON in validation_json

            # In a full implementation, we'd properly serialize to Any

            import json

            param_spec.validation_json = json.dumps({

                'default': param.default

            })

        

        return param_spec

    

    def call_tool(self, tool_name: str, **kwargs) -> Any:

        """

        Call a tool by name with the given parameters.

        

        This is used internally by the framework to dispatch tool calls.

        """

        if not hasattr(self, tool_name):

            raise AttributeError(f"Tool '{tool_name}' not found in {self.__class__.__name__}")

        

        method = getattr(self, tool_name)

        if not callable(method):

            raise TypeError(f"'{tool_name}' is not a callable tool")

        

        return method(**kwargs)

    

    def register_with_session(self, session_id: str, stub) -> List[str]:

        """

        Register all tools from this adapter with the Elixir session.

        

        Args:

            session_id: The session ID to register tools with

            stub: The gRPC stub to use for registration

            

        Returns:

            List of registered tool names

        """

        tools = self.get_tools()

        

        if not tools:

            logger.warning(f"No tools found in adapter {self.__class__.__name__}")

            return []

        

        # Create registration request

        request = pb2.RegisterToolsRequest(

            session_id=session_id,

            tools=tools,

            worker_id=f"python-{id(self)}"  # Use object ID as worker ID

        )

        

        try:

            response = stub.RegisterTools(request)

            # Handle async stub returning UnaryUnaryCall - properly invoke it

            if hasattr(response, '__await__') or hasattr(response, 'result'):

                # This is a UnaryUnaryCall object, get the actual result

                try:

                    response = response.result()

                except AttributeError:

                    # Try calling it directly if it's a callable

                    if callable(response):

                        response = response()

                    else:

                        logger.warning("RegisterTools returned UnaryUnaryCall but couldn't extract result")

                        return []

            if response.success:

                logger.info(f"Registered {len(tools)} tools for session {session_id}")

                return list(response.tool_ids.keys())

            else:

                logger.error(f"Failed to register tools: {response.error_message}")

                return []

        except Exception as e:

            logger.error(f"Error registering tools: {e}")

            return []--- END FILE: snakepit/priv/python/snakepit_bridge/base_adapter.py ---

--- START FILE: snakepit/priv/python/grpc_server.py ---

#!/usr/bin/env python3

"""

Stateless gRPC bridge server for DSPex.

This server acts as a proxy for state operations (forwarding to Elixir)

and as an execution environment for Python tools.

"""

import argparse

import asyncio

import grpc

import logging

import signal

import sys

import time

import inspect

from concurrent import futures

from datetime import datetime

from typing import Optional

# Add the package to Python path

sys.path.insert(0, '.')

import snakepit_bridge_pb2 as pb2

import snakepit_bridge_pb2_grpc as pb2_grpc

from snakepit_bridge.session_context import SessionContext

from snakepit_bridge.serialization import TypeSerializer

from google.protobuf.timestamp_pb2 import Timestamp

from google.protobuf import any_pb2

import json

import functools

import traceback

import pickle

logging.basicConfig(

    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',

    level=logging.INFO

)

logger = logging.getLogger(__name__)

def grpc_error_handler(func):

    """

    Decorator to handle unexpected exceptions in gRPC service methods.

    

    Converts Python exceptions into proper gRPC errors with detailed

    error messages while avoiding exposing sensitive information.

    """

    @functools.wraps(func)

    async def wrapper(self, request, context):

        method_name = func.__name__

        try:

            return await func(self, request, context)

        except grpc.RpcError:

            # Re-raise gRPC errors as-is

            raise

        except ValueError as e:

            # Invalid input errors

            logger.warning(f"{method_name} - ValueError: {str(e)}")

            await context.abort(grpc.StatusCode.INVALID_ARGUMENT, str(e))

        except NotImplementedError as e:

            # Unimplemented features

            logger.info(f"{method_name} - NotImplementedError: {str(e)}")

            await context.abort(grpc.StatusCode.UNIMPLEMENTED, str(e))

        except TimeoutError as e:

            # Timeout errors

            logger.warning(f"{method_name} - TimeoutError: {str(e)}")

            await context.abort(grpc.StatusCode.DEADLINE_EXCEEDED, "Operation timed out")

        except PermissionError as e:

            # Permission errors

            logger.warning(f"{method_name} - PermissionError: {str(e)}")

            await context.abort(grpc.StatusCode.PERMISSION_DENIED, "Permission denied")

        except FileNotFoundError as e:

            # Resource not found

            logger.warning(f"{method_name} - FileNotFoundError: {str(e)}")

            await context.abort(grpc.StatusCode.NOT_FOUND, "Resource not found")

        except Exception as e:

            # Catch-all for unexpected errors

            error_id = f"{method_name}_{int(time.time() * 1000)}"

            logger.error(f"{error_id} - Unexpected error: {type(e).__name__}: {str(e)}")

            logger.error(f"{error_id} - Traceback:\n{traceback.format_exc()}")

            

            # Return a generic error message to avoid exposing internals

            await context.abort(

                grpc.StatusCode.INTERNAL,

                f"Internal server error (ID: {error_id}). Please check server logs for details."

            )

    

    # Handle both sync and async functions

    if asyncio.iscoroutinefunction(func):

        return wrapper

    else:

        @functools.wraps(func)

        def sync_wrapper(self, request, context):

            method_name = func.__name__

            try:

                return func(self, request, context)

            except grpc.RpcError:

                raise

            except ValueError as e:

                logger.warning(f"{method_name} - ValueError: {str(e)}")

                context.abort(grpc.StatusCode.INVALID_ARGUMENT, str(e))

            except NotImplementedError as e:

                logger.info(f"{method_name} - NotImplementedError: {str(e)}")

                context.abort(grpc.StatusCode.UNIMPLEMENTED, str(e))

            except Exception as e:

                error_id = f"{method_name}_{int(time.time() * 1000)}"

                logger.error(f"{error_id} - Unexpected error: {type(e).__name__}: {str(e)}")

                logger.error(f"{error_id} - Traceback:\n{traceback.format_exc()}")

                context.abort(

                    grpc.StatusCode.INTERNAL,

                    f"Internal server error (ID: {error_id}). Please check server logs for details."

                )

        return sync_wrapper

class BridgeServiceServicer(pb2_grpc.BridgeServiceServicer):

    """

    Stateless implementation of the gRPC bridge service.

    

    For state operations, this server acts as a proxy to the Elixir BridgeServer.

    For tool execution, it creates ephemeral contexts that callback to Elixir for state.

    """

    

    def __init__(self, adapter_class, elixir_address: str):

        self.adapter_class = adapter_class

        self.elixir_address = elixir_address

        self.server: Optional[grpc.aio.Server] = None

        

        # Create async client channel for async operations (proxying)

        self.elixir_channel = grpc.aio.insecure_channel(elixir_address)

        self.elixir_stub = pb2_grpc.BridgeServiceStub(self.elixir_channel)

        

        # Create sync client channel for SessionContext

        self.sync_elixir_channel = grpc.insecure_channel(elixir_address)

        self.sync_elixir_stub = pb2_grpc.BridgeServiceStub(self.sync_elixir_channel)

        

        logger.info(f"Python server initialized with Elixir backend at {elixir_address}")

    

    async def close(self):

        """Clean up resources."""

        if self.elixir_channel:

            await self.elixir_channel.close()

        if self.sync_elixir_channel:

            self.sync_elixir_channel.close()

    

    # Health & Session Management

    

    async def Ping(self, request, context):

        """Health check endpoint - handled locally."""

        logger.debug(f"Ping received: {request.message}")

        

        response = pb2.PingResponse()

        response.message = f"Pong from Python: {request.message}"

        

        # Set current timestamp

        timestamp = Timestamp()

        timestamp.GetCurrentTime()

        response.server_time.CopyFrom(timestamp)

        

        return response

    

    async def InitializeSession(self, request, context):

        """

        Initialize a session - proxy to Elixir.

        

        The Python server maintains no session state.

        All session data is managed by Elixir.

        """

        logger.info(f"Proxying InitializeSession for: {request.session_id}")

        return await self.elixir_stub.InitializeSession(request)

    

    async def CleanupSession(self, request, context):

        """Clean up a session - proxy to Elixir."""

        logger.info(f"Proxying CleanupSession for: {request.session_id}")

        return await self.elixir_stub.CleanupSession(request)

    

    async def GetSession(self, request, context):

        """Get session details - proxy to Elixir."""

        logger.debug(f"Proxying GetSession for: {request.session_id}")

        return await self.elixir_stub.GetSession(request)

    

    async def Heartbeat(self, request, context):

        """Send heartbeat - proxy to Elixir."""

        logger.debug(f"Proxying Heartbeat for: {request.session_id}")

        return await self.elixir_stub.Heartbeat(request)

    

    # Variable Operations - All Proxied to Elixir

    

    async def RegisterVariable(self, request, context):

        """Register a variable - proxy to Elixir."""

        logger.debug(f"Proxying RegisterVariable: {request.name}")

        return await self.elixir_stub.RegisterVariable(request)

    

    async def GetVariable(self, request, context):

        """Get a variable - proxy to Elixir."""

        logger.debug(f"Proxying GetVariable: {request.variable_identifier}")

        return await self.elixir_stub.GetVariable(request)

    

    async def SetVariable(self, request, context):

        """Set a variable - proxy to Elixir."""

        logger.debug(f"Proxying SetVariable: {request.variable_identifier}")

        return await self.elixir_stub.SetVariable(request)

    

    async def GetVariables(self, request, context):

        """Get multiple variables - proxy to Elixir."""

        logger.debug(f"Proxying GetVariables for {len(request.variable_identifiers)} variables")

        return await self.elixir_stub.GetVariables(request)

    

    async def SetVariables(self, request, context):

        """Set multiple variables - proxy to Elixir."""

        logger.debug(f"Proxying SetVariables for {len(request.updates)} variables")

        return await self.elixir_stub.SetVariables(request)

    

    async def ListVariables(self, request, context):

        """List variables - proxy to Elixir."""

        logger.debug(f"Proxying ListVariables with pattern: {request.pattern}")

        return await self.elixir_stub.ListVariables(request)

    

    async def DeleteVariable(self, request, context):

        """Delete a variable - proxy to Elixir."""

        logger.debug(f"Proxying DeleteVariable: {request.variable_identifier}")

        return await self.elixir_stub.DeleteVariable(request)

    

    # Tool Execution - Stateless with Ephemeral Context

    

    @grpc_error_handler

    async def ExecuteTool(self, request, context):

        """Executes a non-streaming tool."""

        logger.info(f"ExecuteTool: {request.tool_name} for session {request.session_id}")

        start_time = time.time()

        

        try:

            # Ensure session exists in Elixir

            init_request = pb2.InitializeSessionRequest(session_id=request.session_id)

            try:

                self.sync_elixir_stub.InitializeSession(init_request)

            except grpc.RpcError as e:

                # Session might already exist, that's ok

                if e.code() != grpc.StatusCode.ALREADY_EXISTS:

                    logger.debug(f"InitializeSession for {request.session_id}: {e}")

            

            # Create ephemeral context for this request

            session_context = SessionContext(self.sync_elixir_stub, request.session_id)

            

            # Create adapter instance for this request

            adapter = self.adapter_class()

            adapter.set_session_context(session_context)

            

            # Register adapter tools with the session (for new BaseAdapter)

            if hasattr(adapter, 'register_with_session'):

                registered_tools = adapter.register_with_session(request.session_id, self.sync_elixir_stub)

                logger.info(f"Registered {len(registered_tools)} tools for session {request.session_id}")

            

            # Initialize adapter if needed

            if hasattr(adapter, 'initialize'):

                await adapter.initialize()

            

            # Decode parameters from protobuf Any using TypeSerializer

            arguments = {key: TypeSerializer.decode_any(any_msg) for key, any_msg in request.parameters.items()}

            # Also handle binary parameters if present

            for key, binary_val in request.binary_parameters.items():

                arguments[key] = pickle.loads(binary_val)

            

            # Execute the tool

            if not hasattr(adapter, 'execute_tool'):

                raise grpc.RpcError(grpc.StatusCode.UNIMPLEMENTED, "Adapter does not support 'execute_tool'")

            

            # CORRECT: Await the async method

            import inspect

            if inspect.iscoroutinefunction(adapter.execute_tool):

                result_data = await adapter.execute_tool(

                    tool_name=request.tool_name,

                    arguments=arguments,

                    context=session_context

                )

            else:

                result_data = adapter.execute_tool(

                    tool_name=request.tool_name,

                    arguments=arguments,

                    context=session_context

                )

            

            # Check if a generator was mistakenly returned (should have been called via streaming endpoint)

            if inspect.isgenerator(result_data) or inspect.isasyncgen(result_data):

                logger.warning(f"Tool '{request.tool_name}' returned a generator but was called via non-streaming ExecuteTool. Returning empty result.")

                result_data = {"error": "Streaming tool called on non-streaming endpoint."}

            

            # CORRECT: Use the robust TypeValidator and TypeSerializer for ALL types.

            # This removes the need for custom `snakepit.map` logic.

            response = pb2.ExecuteToolResponse(success=True)

            from snakepit_bridge.types import TypeValidator

            

            # Infer the type of the result

            result_type = TypeValidator.infer_type(result_data)

            

            # Use the centralized serializer to encode the result correctly

            any_msg, binary_data = TypeSerializer.encode_any(result_data, result_type.value)

            

            # The result from encode_any is already a protobuf Any message, so we just assign it

            response.result.CopyFrom(any_msg)

            if binary_data:

                response.binary_result = binary_data

                

            response.execution_time_ms = int((time.time() - start_time) * 1000)

            

            return response

                

        except Exception as e:

            logger.error(f"ExecuteTool failed: {e}", exc_info=True)

            response = pb2.ExecuteToolResponse()

            response.success = False

            response.error_message = str(e)

            return response

    

    @grpc_error_handler

    def ExecuteStreamingTool(self, request, context):

        """Executes a streaming tool."""

        logger.info(f"ExecuteStreamingTool: {request.tool_name} for session {request.session_id}")

        logger.info(f"ExecuteStreamingTool request.stream: {request.stream}")

        

        # Debug logging to file

        with open("/tmp/grpc_streaming_debug.log", "a") as f:

            f.write(f"ExecuteStreamingTool called: {request.tool_name} at {time.time()}\n")

            f.flush()

        

        try:

            # Ensure session exists in Elixir

            init_request = pb2.InitializeSessionRequest(session_id=request.session_id)

            try:

                self.sync_elixir_stub.InitializeSession(init_request)

            except grpc.RpcError as e:

                # Session might already exist, that's ok

                if e.code() != grpc.StatusCode.ALREADY_EXISTS:

                    logger.debug(f"InitializeSession for {request.session_id}: {e}")

            

            # Create ephemeral context for this request

            logger.info(f"Creating SessionContext for {request.session_id}")

            session_context = SessionContext(self.sync_elixir_stub, request.session_id)

            

            # Create adapter instance for this request

            logger.info(f"Creating adapter instance: {self.adapter_class}")

            adapter = self.adapter_class()

            adapter.set_session_context(session_context)

            

            # Register adapter tools with the session (for new BaseAdapter)

            if hasattr(adapter, 'register_with_session'):

                registered_tools = adapter.register_with_session(request.session_id, self.sync_elixir_stub)

                logger.info(f"Registered {len(registered_tools)} tools for session {request.session_id}")

            

            # Initialize adapter if needed

            if hasattr(adapter, 'initialize') and inspect.iscoroutinefunction(adapter.initialize):

                # Can't await in a sync function, so skip async initialization

                logger.warning("Skipping async adapter initialization in streaming context")

            elif hasattr(adapter, 'initialize'):

                adapter.initialize()

            

            # Decode parameters from protobuf Any using TypeSerializer

            arguments = {key: TypeSerializer.decode_any(any_msg) for key, any_msg in request.parameters.items()}

            # Also handle binary parameters if present

            for key, binary_val in request.binary_parameters.items():

                arguments[key] = pickle.loads(binary_val)

            

            # Execute the tool

            if not hasattr(adapter, 'execute_tool'):

                context.abort(grpc.StatusCode.UNIMPLEMENTED, "Adapter does not support tool execution")

                return

            

            # Can't await in sync function - just call it directly

            import inspect

            

            if inspect.iscoroutinefunction(adapter.execute_tool):

                # Can't handle async execute_tool in sync ExecuteStreamingTool

                context.abort(grpc.StatusCode.UNIMPLEMENTED, "Async adapters not supported for streaming")

                return

            else:

                stream_iterator = adapter.execute_tool(

                    tool_name=request.tool_name,

                    arguments=arguments,

                    context=session_context

                )

            

            # Handle both sync and async generators

            chunk_id_counter = 0

            

            # Import StreamChunk for proper handling

            from snakepit_bridge.adapters.showcase.tool import StreamChunk

            

            logger.info(f"Stream iterator type: {type(stream_iterator)}")

            logger.info(f"Has __aiter__: {hasattr(stream_iterator, '__aiter__')}")

            logger.info(f"Has __iter__: {hasattr(stream_iterator, '__iter__')}")

            

            # Since ExecuteStreamingTool is now sync, we can only handle sync iterators

            if hasattr(stream_iterator, '__aiter__'):

                # Can't handle async generators in a sync function

                logger.error("Tool returned async generator but ExecuteStreamingTool is sync")

                context.abort(grpc.StatusCode.INTERNAL, "Async generators not supported")

                return

            elif hasattr(stream_iterator, '__iter__'):

                logger.info(f"Processing sync iterator for {request.tool_name}")

                # Debug to file

                with open("/tmp/grpc_streaming_debug.log", "a") as f:

                    f.write(f"Starting iteration at {time.time()}\n")

                    f.flush()

                    

                for chunk_data in stream_iterator:

                    logger.info(f"Got chunk data: {chunk_data}")

                    with open("/tmp/grpc_streaming_debug.log", "a") as f:

                        f.write(f"Got chunk: {chunk_data} at {time.time()}\n")

                        f.flush()

                    # This is the same processing logic

                    if isinstance(chunk_data, StreamChunk):

                        data_payload = chunk_data.data

                    else:

                        data_payload = chunk_data

                    data_bytes = json.dumps(data_payload).encode('utf-8')

                    chunk_id_counter += 1

                    chunk = pb2.ToolChunk(

                        chunk_id=f"{request.tool_name}-{chunk_id_counter}",

                        data=data_bytes,

                        is_final=False

                    )

                    logger.info(f"Yielding chunk {chunk_id_counter}: {chunk.chunk_id}")

                    with open("/tmp/grpc_streaming_debug.log", "a") as f:

                        f.write(f"Yielding chunk_id={chunk.chunk_id} at {time.time()}\n")

                        f.flush()

                    yield chunk

            else:

                # This handles non-generator returns

                logger.info(f"Non-generator return from {request.tool_name}")

                data_bytes = json.dumps(stream_iterator).encode('utf-8')

                yield pb2.ToolChunk(

                    chunk_id=f"{request.tool_name}-1",

                    data=data_bytes,

                    is_final=True

                )

            

            # Yield the final empty chunk after the loop

            logger.info(f"Yielding final chunk for {request.tool_name}")

            with open("/tmp/grpc_streaming_debug.log", "a") as f:

                f.write(f"Yielding final chunk at {time.time()}\n")

                f.flush()

            yield pb2.ToolChunk(is_final=True)

                

        except Exception as e:

            logger.error(f"ExecuteStreamingTool failed: {e}", exc_info=True)

            context.abort(grpc.StatusCode.INTERNAL, str(e))

    

    async def WatchVariables(self, request, context):

        """Watch variables for changes - placeholder for Stage 3."""

        context.set_code(grpc.StatusCode.UNIMPLEMENTED)

        context.set_details('WatchVariables not implemented until Stage 3')

        # For streaming RPCs, we need to yield, not return

        return

        yield  # Make this a generator but never actually yield anything

    

    # Advanced Features - Stage 4 Placeholders

    

    async def AddDependency(self, request, context):

        """Add dependency - proxy to Elixir when implemented."""

        logger.debug("Proxying AddDependency")

        return await self.elixir_stub.AddDependency(request)

    

    async def StartOptimization(self, request, context):

        """Start optimization - proxy to Elixir when implemented."""

        logger.debug("Proxying StartOptimization")

        return await self.elixir_stub.StartOptimization(request)

    

    async def StopOptimization(self, request, context):

        """Stop optimization - proxy to Elixir when implemented."""

        logger.debug("Proxying StopOptimization")

        return await self.elixir_stub.StopOptimization(request)

    

    async def GetVariableHistory(self, request, context):

        """Get variable history - proxy to Elixir when implemented."""

        logger.debug("Proxying GetVariableHistory")

        return await self.elixir_stub.GetVariableHistory(request)

    

    async def RollbackVariable(self, request, context):

        """Rollback variable - proxy to Elixir when implemented."""

        logger.debug("Proxying RollbackVariable")

        return await self.elixir_stub.RollbackVariable(request)

    

    def set_server(self, server):

        """Set the server reference for graceful shutdown."""

        self.server = server

async def serve_with_shutdown(port: int, adapter_module: str, elixir_address: str, shutdown_event: asyncio.Event):

    """Start the stateless gRPC server with proper shutdown handling."""

    # print(f"GRPC_SERVER_LOG: Starting serve function with fixed shutdown (v4)", flush=True)

    

    # Import the adapter

    module_parts = adapter_module.split('.')

    module_name = '.'.join(module_parts[:-1])

    class_name = module_parts[-1]

    

    try:

        module = __import__(module_name, fromlist=[class_name])

        adapter_class = getattr(module, class_name)

    except (ImportError, AttributeError) as e:

        logger.error(f"Failed to import adapter {adapter_module}: {e}")

        sys.exit(1)

    

    # Create server

    server = grpc.aio.server(

        futures.ThreadPoolExecutor(max_workers=10),

        options=[

            ('grpc.max_send_message_length', 100 * 1024 * 1024),  # 100MB

            ('grpc.max_receive_message_length', 100 * 1024 * 1024),

        ]

    )

    

    servicer = BridgeServiceServicer(adapter_class, elixir_address)

    servicer.set_server(server)

    

    pb2_grpc.add_BridgeServiceServicer_to_server(servicer, server)

    

    # Listen on port

    actual_port = server.add_insecure_port(f'[::]:{port}')

    

    if actual_port == 0 and port != 0:

        logger.error(f"Failed to bind to port {port}")

        sys.exit(1)

    

    await server.start()

    

    # Signal that the server is ready

    print(f"GRPC_READY:{actual_port}", flush=True)

    # print(f"GRPC_SERVER_LOG: Server started with new shutdown logic v2", flush=True)

    logger.info(f"gRPC server started on port {actual_port}")

    logger.info(f"Connected to Elixir backend at {elixir_address}")

    

    # The shutdown_event is passed in from main()

    # print(f"GRPC_SERVER_LOG: Using shutdown event from main, handlers already registered", flush=True)

    

    # Wait for either termination or shutdown signal

    # print("GRPC_SERVER_LOG: Starting main event loop wait", flush=True)

    server_task = asyncio.create_task(server.wait_for_termination())

    shutdown_task = asyncio.create_task(shutdown_event.wait())

    

    try:

        done, pending = await asyncio.wait(

            [server_task, shutdown_task],

            return_when=asyncio.FIRST_COMPLETED

        )

        

        # print(f"GRPC_SERVER_LOG: Event loop returned, shutdown_event.is_set()={shutdown_event.is_set()}", flush=True)

        

        # Cancel pending tasks

        for task in pending:

            task.cancel()

        

        # If shutdown was triggered, stop the server gracefully

        if shutdown_event.is_set():

            # print("GRPC_SERVER_LOG: Shutdown event triggered, stopping server...", flush=True)

            await servicer.close()

            await server.stop(grace_period=0.5)  # Quick stop for tests

            # print("GRPC_SERVER_LOG: Server stopped successfully", flush=True)

    except Exception as e:

        # print(f"GRPC_SERVER_LOG: Exception in main loop: {e}", flush=True)

        raise

async def serve(port: int, adapter_module: str, elixir_address: str):

    """Legacy entry point - creates its own shutdown event."""

    shutdown_event = asyncio.Event()

    await serve_with_shutdown(port, adapter_module, elixir_address, shutdown_event)

async def shutdown(server):

    """Gracefully shutdown the server."""

    await server.stop(grace_period=5)

def main():

    # print(f"GRPC_SERVER_LOG: main() called at {datetime.now()}", flush=True)

    parser = argparse.ArgumentParser(description='DSPex gRPC Bridge Server')

    parser.add_argument('--port', type=int, default=0,

                        help='Port to listen on (0 for dynamic allocation)')

    parser.add_argument('--adapter', type=str, required=True,

                        help='Python module path to adapter class')

    parser.add_argument('--elixir-address', type=str, required=True,

                        help='Address of the Elixir gRPC server (e.g., localhost:50051)')

    parser.add_argument('--snakepit-run-id', type=str, default='',

                        help='Snakepit run ID for process cleanup')

    

    args = parser.parse_args()

    

    # Set up signal handlers at the module level before running asyncio

    shutdown_event = None

    

    def handle_signal(signum, frame):

        # print(f"GRPC_SERVER_LOG: Received signal {signum} in main process", flush=True)

        if shutdown_event and not shutdown_event.is_set():

            # Schedule the shutdown in the running loop

            asyncio.get_running_loop().call_soon_threadsafe(shutdown_event.set)

    

    signal.signal(signal.SIGTERM, handle_signal)

    signal.signal(signal.SIGINT, handle_signal)

    

    # Create and run the server with the shutdown event

    loop = asyncio.new_event_loop()

    asyncio.set_event_loop(loop)

    shutdown_event = asyncio.Event()

    

    try:

        loop.run_until_complete(serve_with_shutdown(args.port, args.adapter, args.elixir_address, shutdown_event))

    finally:

        loop.close()

if __name__ == '__main__':

    main()--- END FILE: snakepit/priv/python/grpc_server.py ---

--- START FILE: snakepit/priv/python/snakepit_bridge/session_context.py ---

"""

Enhanced SessionContext with comprehensive variable support and intelligent caching.

"""

from typing import Any, Dict, List, Optional, Union, TypeVar, Generic

from contextlib import contextmanager

from datetime import datetime, timedelta

from threading import Lock

import weakref

import logging

import json

from dataclasses import dataclass, field

from enum import Enum

import asyncio

import inspect

from snakepit_bridge_pb2 import (

    Variable, RegisterVariableRequest, RegisterVariableResponse,

    GetVariableRequest, GetVariableResponse, SetVariableRequest, SetVariableResponse,

    BatchGetVariablesRequest, BatchGetVariablesResponse,

    BatchSetVariablesRequest, BatchSetVariablesResponse,

    ListVariablesRequest, ListVariablesResponse,

    DeleteVariableRequest, DeleteVariableResponse,

    OptimizationStatus,

    GetExposedElixirToolsRequest, GetExposedElixirToolsResponse,

    ExecuteElixirToolRequest, ExecuteElixirToolResponse,

    ToolSpec

)

from snakepit_bridge_pb2_grpc import BridgeServiceStub

from google.protobuf.any_pb2 import Any

from .types import (

    VariableType, 

    TypeValidator,

    serialize_value,

    deserialize_value,

    validate_constraints

)

logger = logging.getLogger(__name__)

T = TypeVar('T')

@dataclass

class CachedVariable:

    """Cached variable with TTL tracking."""

    variable: Variable

    cached_at: datetime

    ttl: timedelta = field(default_factory=lambda: timedelta(seconds=5))

    

    @property

    def expired(self) -> bool:

        return datetime.now() > self.cached_at + self.ttl

    

    def refresh(self, variable: Variable):

        self.variable = variable

        self.cached_at = datetime.now()

class VariableNotFoundError(KeyError):

    """Raised when a variable is not found."""

    pass

class VariableProxy(Generic[T]):

    """

    Proxy object for lazy variable access.

    

    Provides attribute-style access to variable values with

    automatic synchronization.

    """

    

    def __init__(self, context: 'SessionContext', name: str):

        self._context = weakref.ref(context)

        self._name = name

        self._lock = Lock()

    

    @property

    def value(self) -> T:

        """Get the current value."""

        ctx = self._context()

        if ctx is None:

            raise RuntimeError("SessionContext has been destroyed")

        return ctx.get_variable(self._name)

    

    @value.setter

    def value(self, new_value: T):

        """Update the value."""

        ctx = self._context()

        if ctx is None:

            raise RuntimeError("SessionContext has been destroyed")

        ctx.update_variable(self._name, new_value)

    

    def __repr__(self):

        try:

            return f"<Variable {self._name}={self.value}>"

        except:

            return f"<Variable {self._name} (not loaded)>"

class SessionContext:

    """

    Enhanced session context with comprehensive variable support.

    

    Provides intuitive Python API for variable management with

    intelligent caching to minimize gRPC calls.

    """

    

    def __init__(self, stub: BridgeServiceStub, session_id: str, strict_mode: bool = False):

        self.stub = stub

        self.session_id = session_id

        self._cache: Dict[str, CachedVariable] = {}

        self._cache_lock = Lock()

        self._default_ttl = timedelta(seconds=5)

        self._proxies: Dict[str, VariableProxy] = {}

        self.strict_mode = strict_mode

        

        # Tool registry remains from Stage 0

        self._tools = {}

        

        # Elixir tool proxies

        self._elixir_tools = {}

        self._load_elixir_tools()

        

        logger.info(f"Created SessionContext for session {session_id} (strict_mode={strict_mode})")

    

    def __enter__(self):

        """Support using SessionContext as a context manager."""

        return self

    

    def __exit__(self, exc_type, exc_val, exc_tb):

        """Automatically cleanup when exiting context."""

        self.cleanup()

        return False

    

    # Variable Registration

    

    def register_variable(

        self,

        name: str,

        var_type: Union[str, VariableType],

        initial_value: Any,

        constraints: Optional[Dict[str, Any]] = None,

        metadata: Optional[Dict[str, str]] = None,

        ttl: Optional[timedelta] = None

    ) -> str:

        """

        Register a new variable in the session.

        

        Args:

            name: Variable name (must be unique in session)

            var_type: Type of the variable

            initial_value: Initial value

            constraints: Type-specific constraints

            metadata: Additional metadata

            ttl: Cache TTL for this variable

            

        Returns:

            Variable ID

            

        Raises:

            ValueError: If type validation fails

            RuntimeError: If registration fails

        """

        # Convert type

        if isinstance(var_type, str):

            var_type = VariableType[var_type.upper()]

        

        # Validate value against type

        validator = TypeValidator.get_validator(var_type)

        validated_value = validator.validate(initial_value)

        

        # Validate constraints if provided

        if constraints:

            validate_constraints(validated_value, var_type, constraints)

        

        # Serialize for gRPC

        value_any, binary_data = serialize_value(validated_value, var_type)

        

        # Convert constraints to JSON

        import json

        constraints_json = json.dumps(constraints) if constraints else ""

        

        request = RegisterVariableRequest(

            session_id=self.session_id,

            name=name,

            type=var_type.value,

            initial_value=value_any,

            constraints_json=constraints_json,

            metadata=metadata or {},

            initial_binary_value=binary_data if binary_data else b""

        )

        

        response = self.stub.RegisterVariable(request)

        

        if not response.success:

            raise RuntimeError(f"Failed to register variable: {response.error_message}")

        

        var_id = response.variable_id

        logger.info(f"Registered variable {name} ({var_id}) of type {var_type}")

        

        # Invalidate cache for this name

        self._invalidate_cache(name)

        

        return var_id

    

    # Variable Access

    

    def get_variable(self, identifier: str) -> Any:

        """

        Get a variable's value by name or ID.

        

        Uses cache when possible to minimize gRPC calls.

        

        Args:

            identifier: Variable name or ID

            

        Returns:

            The variable's current value

            

        Raises:

            VariableNotFoundError: If variable doesn't exist

        """

        # Check cache first

        with self._cache_lock:

            cached = self._cache.get(identifier)

            if cached and not cached.expired:

                logger.debug(f"Cache hit for variable {identifier}")

                return deserialize_value(

                    cached.variable.value, 

                    VariableType(cached.variable.type)

                )

        

        # Cache miss - fetch from server

        logger.debug(f"Cache miss for variable {identifier}")

        

        request = GetVariableRequest(

            session_id=self.session_id,

            variable_identifier=identifier

        )

        

        try:

            response = self.stub.GetVariable(request)

        except Exception as e:

            if "not found" in str(e).lower():

                raise VariableNotFoundError(f"Variable not found: {identifier}")

            raise

        

        variable = response.variable

        

        # Update cache (by both ID and name)

        with self._cache_lock:

            cached_var = CachedVariable(

                variable=variable,

                cached_at=datetime.now(),

                ttl=self._default_ttl

            )

            self._cache[variable.id] = cached_var

            self._cache[variable.name] = cached_var

        

        # Deserialize and return value

        return deserialize_value(

            variable.value,

            VariableType(variable.type),

            variable.binary_value if variable.binary_value else None

        )

    

    def update_variable(

        self,

        identifier: str,

        new_value: Any,

        metadata: Optional[Dict[str, str]] = None

    ) -> None:

        """

        Update a variable's value.

        

        Performs write-through caching for consistency.

        

        Args:

            identifier: Variable name or ID

            new_value: New value (will be validated)

            metadata: Additional metadata for the update

            

        Raises:

            ValueError: If value doesn't match type/constraints

            VariableNotFoundError: If variable doesn't exist

        """

        # First get the variable to know its type

        # This also populates the cache

        self.get_variable(identifier)

        

        # Get from cache to access type info

        with self._cache_lock:

            cached = self._cache.get(identifier)

            if not cached:

                raise RuntimeError("Variable should be in cache")

            

            var_type = VariableType(cached.variable.type)

        

        # Validate new value

        validator = TypeValidator.get_validator(var_type)

        validated_value = validator.validate(new_value)

        

        # Serialize for gRPC

        value_any, binary_data = serialize_value(validated_value, var_type)

        

        request = SetVariableRequest(

            session_id=self.session_id,

            variable_identifier=identifier,

            value=value_any,

            metadata=metadata or {},

            binary_value=binary_data if binary_data else b""

        )

        

        response = self.stub.SetVariable(request)

        

        if not response.success:

            raise RuntimeError(f"Failed to update variable: {response.error_message}")

        

        # Invalidate cache for write-through consistency

        self._invalidate_cache(identifier)

        

        logger.info(f"Updated variable {identifier}")

    

    def list_variables(self, pattern: Optional[str] = None) -> List[Dict[str, Any]]:

        """

        List all variables or those matching a pattern.

        

        Args:

            pattern: Optional wildcard pattern (e.g., "temp_*")

            

        Returns:

            List of variable info dictionaries

        """

        request = ListVariablesRequest(

            session_id=self.session_id,

            pattern=pattern or ""

        )

        

        response = self.stub.ListVariables(request)

        

        variables = []

        for var in response.variables:

            var_type = VariableType(var.type)

            variables.append({

                'id': var.id,

                'name': var.name,

                'type': var_type.value,

                'value': deserialize_value(var.value, var_type),

                'version': var.version,

                'constraints': json.loads(var.constraints_json) if var.constraints_json else {},

                'metadata': dict(var.metadata),

                'optimizing': var.optimization_status.optimizing if var.optimization_status else False

            })

            

            # Update cache opportunistically

            with self._cache_lock:

                cached_var = CachedVariable(

                    variable=var,

                    cached_at=datetime.now(),

                    ttl=self._default_ttl

                )

                self._cache[var.id] = cached_var

                self._cache[var.name] = cached_var

        

        return variables

    

    def delete_variable(self, identifier: str) -> None:

        """

        Delete a variable from the session.

        

        Args:

            identifier: Variable name or ID

            

        Raises:

            RuntimeError: If deletion fails

        """

        request = DeleteVariableRequest(

            session_id=self.session_id,

            variable_identifier=identifier

        )

        

        response = self.stub.DeleteVariable(request)

        

        if not response.success:

            raise RuntimeError(f"Failed to delete variable: {response.error_message}")

        

        # Remove from cache

        self._invalidate_cache(identifier)

        

        # Remove proxy if exists

        self._proxies.pop(identifier, None)

        

        logger.info(f"Deleted variable {identifier}")

    

    # Batch Operations

    

    def get_variables(self, identifiers: List[str]) -> Dict[str, Any]:

        """

        Get multiple variables efficiently.

        

        Uses cache and batches uncached requests.

        

        Args:

            identifiers: List of variable names or IDs

            

        Returns:

            Dict mapping identifier to value

        """

        result = {}

        uncached = []

        

        # Check cache first

        with self._cache_lock:

            for identifier in identifiers:

                cached = self._cache.get(identifier)

                if cached and not cached.expired:

                    var_type = VariableType(cached.variable.type)

                    result[identifier] = deserialize_value(

                        cached.variable.value,

                        var_type

                    )

                else:

                    uncached.append(identifier)

        

        # Batch fetch uncached

        if uncached:

            request = BatchGetVariablesRequest(

                session_id=self.session_id,

                variable_identifiers=uncached

            )

            

            response = self.stub.GetVariables(request)

            

            # Process found variables

            for var_id, var in response.variables.items():

                var_type = VariableType(var.type)

                value = deserialize_value(var.value, var_type, var.binary_value if var.binary_value else None)

                

                # Update result

                result[var_id] = value

                result[var.name] = value

                

                # Update cache

                with self._cache_lock:

                    cached_var = CachedVariable(

                        variable=var,

                        cached_at=datetime.now(),

                        ttl=self._default_ttl

                    )

                    self._cache[var.id] = cached_var

                    self._cache[var.name] = cached_var

            

            # Handle missing

            for missing in response.missing_variables:

                if missing in identifiers:

                    raise VariableNotFoundError(f"Variable not found: {missing}")

        

        return result

    

    def update_variables(

        self,

        updates: Dict[str, Any],

        atomic: bool = False,

        metadata: Optional[Dict[str, str]] = None

    ) -> Dict[str, Union[bool, str]]:

        """

        Update multiple variables efficiently.

        

        Args:

            updates: Dict mapping identifier to new value

            atomic: If True, all updates must succeed

            metadata: Metadata for all updates

            

        Returns:

            Dict mapping identifier to success/error

        """

        # First, get all variables to know their types

        var_info = self.get_variables(list(updates.keys()))

        

        # Prepare updates with proper serialization

        serialized_updates = {}

        binary_updates = {}

        for identifier, new_value in updates.items():

            # Get variable type from cache

            with self._cache_lock:

                cached = self._cache.get(identifier)

                if not cached:

                    continue

                var_type = VariableType(cached.variable.type)

            

            # Validate and serialize

            validator = TypeValidator.get_validator(var_type)

            validated = validator.validate(new_value)

            value_any, binary_data = serialize_value(validated, var_type)

            serialized_updates[identifier] = value_any

            if binary_data:

                binary_updates[identifier] = binary_data

        

        request = BatchSetVariablesRequest(

            session_id=self.session_id,

            updates=serialized_updates,

            atomic=atomic,

            metadata=metadata or {},

            binary_updates=binary_updates

        )

        

        response = self.stub.SetVariables(request)

        

        if not response.success:

            # Return errors

            return {k: v for k, v in response.errors.items()}

        

        # Process results

        results = {}

        for identifier in updates:

            if identifier in response.errors:

                results[identifier] = response.errors[identifier]

            else:

                results[identifier] = True

                # Invalidate cache

                self._invalidate_cache(identifier)

        

        return results

    

    # Pythonic Access Patterns

    

    def __getitem__(self, name: str) -> Any:

        """Allow dict-style access: value = ctx['temperature']"""

        return self.get_variable(name)

    

    def __setitem__(self, name: str, value: Any):

        """

        Allow dict-style updates: ctx['temperature'] = 0.8

        

        In strict mode, only allows updating existing variables.

        In normal mode, auto-registers new variables.

        """

        try:

            self.update_variable(name, value)

        except VariableNotFoundError:

            if self.strict_mode:

                raise VariableNotFoundError(

                    f"Variable '{name}' not found. In strict mode, variables must be explicitly "

                    f"registered with register_variable() before assignment."

                )

            # Auto-register if doesn't exist (non-strict mode)

            var_type = TypeValidator.infer_type(value)

            self.register_variable(name, var_type, value)

    

    def __contains__(self, name: str) -> bool:

        """Check if variable exists: 'temperature' in ctx"""

        try:

            self.get_variable(name)

            return True

        except VariableNotFoundError:

            return False

    

    @property

    def v(self) -> 'VariableNamespace':

        """

        Attribute-style access to variables.

        

        Example:

            ctx.v.temperature = 0.8

            print(ctx.v.temperature)

        """

        return VariableNamespace(self)

    

    def variable(self, name: str) -> VariableProxy:

        """

        Get a variable proxy for repeated access.

        

        The proxy provides efficient access to a single variable.

        """

        if name not in self._proxies:

            self._proxies[name] = VariableProxy(self, name)

        return self._proxies[name]

    

    @contextmanager

    def batch_updates(self):

        """

        Context manager for batched updates.

        

        Example:

            with ctx.batch_updates() as batch:

                batch['var1'] = 10

                batch['var2'] = 20

                batch['var3'] = 30

        """

        batch = BatchUpdater(self)

        yield batch

        batch.commit()

    

    # Cache Management

    

    def set_cache_ttl(self, ttl: timedelta):

        """Set default cache TTL for variables."""

        self._default_ttl = ttl

    

    def clear_cache(self):

        """Clear all cached variables."""

        with self._cache_lock:

            self._cache.clear()

        logger.info("Cleared variable cache")

    

    def _invalidate_cache(self, identifier: str):

        """Invalidate cache entry for a variable."""

        with self._cache_lock:

            # Try to remove by identifier

            self._cache.pop(identifier, None)

            

            # Also check if it's cached by the other key

            to_remove = []

            for key, cached in self._cache.items():

                if cached.variable.id == identifier or cached.variable.name == identifier:

                    to_remove.append(key)

            

            for key in to_remove:

                self._cache.pop(key, None)

    

    def _deserialize_constraints(self, constraints_json: str) -> Dict[str, Any]:

        """Deserialize constraint values."""

        if not constraints_json:

            return {}

        import json

        try:

            return json.loads(constraints_json)

        except:

            return {}

    

    def cleanup(self, force: bool = False):

        """

        Clean up resources associated with this session context.

        

        This method:

        1. Clears local caches and proxies

        2. Sends a CleanupSession RPC to the server to release server-side resources

        

        Args:

            force: If True, forces cleanup even if there are active references

        """

        # Clear local resources first

        self.clear_cache()

        self._proxies.clear()

        

        # Send cleanup request to server

        try:

            from snakepit_bridge_pb2 import CleanupSessionRequest

            

            request = CleanupSessionRequest(

                session_id=self.session_id,

                force=force

            )

            

            response = self.stub.CleanupSession(request)

            

            if response.success:

                logger.info(f"Successfully cleaned up session {self.session_id} "

                          f"(cleaned {response.resources_cleaned} resources)")

            else:

                logger.warning(f"Failed to cleanup session {self.session_id} on server")

                

        except Exception as e:

            logger.error(f"Error during session cleanup: {e}")

        

        logger.info(f"Cleaned up session context for {self.session_id}")

    

    # Existing tool methods remain...

    

    def register_tool(self, tool_class):

        """Register a tool (from Stage 0)."""

        # Implementation remains from Stage 0

        pass

    

    def call_tool(self, tool_name: str, **kwargs):

        """Call a tool (Python or Elixir)."""

        # Check if it's an Elixir tool first

        if tool_name in self._elixir_tools:

            return self.call_elixir_tool(tool_name, **kwargs)

        

        # Otherwise, try Python tools

        if tool_name in self._tools:

            tool = self._tools[tool_name]

            return tool(**kwargs)

        

        raise ValueError(f"Tool '{tool_name}' not found")

    

    def _load_elixir_tools(self):

        """Load available Elixir tools from the server."""

        try:

            request = GetExposedElixirToolsRequest(session_id=self.session_id)

            response = self.stub.GetExposedElixirTools(request)

            # Handle async stub returning UnaryUnaryCall - properly invoke it

            if hasattr(response, '__await__') or hasattr(response, 'result'):

                # This is a UnaryUnaryCall object, get the actual result

                try:

                    response = response.result()

                except AttributeError:

                    # Try calling it directly if it's a callable

                    if callable(response):

                        response = response()

                    else:

                        logger.warning("GetExposedElixirTools returned UnaryUnaryCall but couldn't extract result")

                        return

            

            for tool_spec in response.tools:

                proxy = self._create_tool_proxy(tool_spec)

                self._elixir_tools[tool_spec.name] = proxy

                

            logger.info(f"Loaded {len(self._elixir_tools)} Elixir tools for session {self.session_id}")

        except Exception as e:

            logger.warning(f"Failed to load Elixir tools: {e}")

    

    def _create_tool_proxy(self, tool_spec: ToolSpec):

        """Create a Python callable proxy for an Elixir tool."""

        def proxy(**kwargs):

            return self.call_elixir_tool(tool_spec.name, **kwargs)

        

        # Set metadata on the proxy function

        proxy.__name__ = tool_spec.name

        proxy.__doc__ = tool_spec.description

        

        # Add parameter information if available

        if tool_spec.parameters:

            param_info = []

            for param in tool_spec.parameters:

                param_str = f"{param.name}: {param.type}"

                if param.required:

                    param_str += " (required)"

                if param.description:

                    param_str += f" - {param.description}"

                param_info.append(param_str)

            

            if proxy.__doc__:

                proxy.__doc__ += "\n\nParameters:\n" + "\n".join(param_info)

            else:

                proxy.__doc__ = "Parameters:\n" + "\n".join(param_info)

        

        return proxy

    

    def call_elixir_tool(self, tool_name: str, **kwargs):

        """

        Execute an Elixir tool via gRPC.

        

        Args:

            tool_name: Name of the Elixir tool to execute

            **kwargs: Parameters to pass to the tool

            

        Returns:

            The result from the Elixir tool

            

        Raises:

            RuntimeError: If the tool execution fails

        """

        # Serialize parameters

        parameters = {}

        for key, value in kwargs.items():

            try:

                # Serialize to Any protobuf

                any_value = Any()

                # For now, use JSON serialization

                any_value.type_url = "type.googleapis.com/google.protobuf.StringValue"

                any_value.value = json.dumps(value).encode('utf-8')

                parameters[key] = any_value

            except Exception as e:

                raise ValueError(f"Failed to serialize parameter '{key}': {e}")

        

        # Create request

        request = ExecuteElixirToolRequest(

            session_id=self.session_id,

            tool_name=tool_name,

            parameters=parameters,

            metadata={}

        )

        

        # Execute tool

        try:

            response = self.stub.ExecuteElixirTool(request)

            

            if response.success:

                # Deserialize result

                if response.result and response.result.value:

                    # For now, assume JSON deserialization

                    result = json.loads(response.result.value.decode('utf-8'))

                    return result

                else:

                    return None

            else:

                raise RuntimeError(f"Elixir tool execution failed: {response.error_message}")

                

        except Exception as e:

            logger.error(f"Error calling Elixir tool '{tool_name}': {e}")

            raise

    

    @property

    def elixir_tools(self) -> Dict[str, Any]:

        """Get dictionary of available Elixir tools."""

        return self._elixir_tools.copy()

class VariableNamespace:

    """

    Namespace for attribute-style variable access.

    

    Provides ctx.v.variable_name syntax.

    """

    

    def __init__(self, context: SessionContext):

        self._context = weakref.ref(context)

    

    def __getattr__(self, name: str) -> Any:

        ctx = self._context()

        if ctx is None:

            raise RuntimeError("SessionContext has been destroyed")

        return ctx.get_variable(name)

    

    def __setattr__(self, name: str, value: Any):

        if name.startswith('_'):

            super().__setattr__(name, value)

        else:

            ctx = self._context()

            if ctx is None:

                raise RuntimeError("SessionContext has been destroyed")

            try:

                ctx.update_variable(name, value)

            except VariableNotFoundError:

                # Auto-register

                var_type = TypeValidator.infer_type(value)

                ctx.register_variable(name, var_type, value)

class BatchUpdater:

    """Collect updates for batch submission."""

    

    def __init__(self, context: SessionContext):

        self.context = context

        self.updates = {}

    

    def __setitem__(self, name: str, value: Any):

        self.updates[name] = value

    

    def commit(self, atomic: bool = False):

        """Commit all updates."""

        if self.updates:

            return self.context.update_variables(self.updates, atomic=atomic)

        return {}--- END FILE: snakepit/priv/python/snakepit_bridge/session_context.py ---

--- START FILE: snakepit/priv/python/snakepit_bridge/adapters/showcase/showcase_adapter.py ---

"""

Refactored ShowcaseAdapter that delegates to specialized handlers.

This adapter demonstrates best practices for Snakepit adapters:

1. All state is managed through SessionContext (Elixir's SessionStore)

2. Code is organized into domain-specific handlers

3. Python workers remain stateless for better scalability

"""

from typing import Dict, Any

from snakepit_bridge import SessionContext

from snakepit_bridge.base_adapter import BaseAdapter, tool

from .handlers import (

    BasicOpsHandler,

    SessionOpsHandler,

    BinaryOpsHandler,

    StreamingOpsHandler,

    ConcurrentOpsHandler,

    VariableOpsHandler,

    MLWorkflowHandler

)

class ShowcaseAdapter(BaseAdapter):

    """Main adapter demonstrating Snakepit features through specialized handlers."""

    

    def __init__(self):

        super().__init__()

        

        # Initialize handlers

        self.handlers = {

            'basic': BasicOpsHandler(),

            'session': SessionOpsHandler(),

            'binary': BinaryOpsHandler(),

            'streaming': StreamingOpsHandler(),

            'concurrent': ConcurrentOpsHandler(),

            'variable': VariableOpsHandler(),

            'ml': MLWorkflowHandler()

        }

        

        # Build tool registry from all handlers

        self._handler_tools = {}

        for handler in self.handlers.values():

            self._handler_tools.update(handler.get_tools())

        

        # Session context will be set by the framework

        self.session_context = None

    

    def set_session_context(self, session_context):

        """Set the session context for this adapter instance."""

        self.session_context = session_context

    

    # Legacy method for backward compatibility

    def execute_tool(self, tool_name: str, arguments: Dict[str, Any], context) -> Any:

        """Execute a tool by name with given arguments (legacy support)."""

        if tool_name in self._handler_tools:

            tool = self._handler_tools[tool_name]

            return tool.func(context, **arguments)

        else:

            # Try the new tool system

            return self.call_tool(tool_name, **arguments)

    

    # Expose key handler methods as tools using the decorator

    

    @tool(description="Get adapter information and capabilities")

    def adapter_info(self) -> Dict[str, Any]:

        """Return information about the adapter capabilities."""

        return self.handlers['basic'].get_tools()['adapter_info'].func(self.session_context)

    

    @tool(description="Echo back provided arguments")

    def echo(self, **kwargs) -> Dict[str, Any]:

        """Echo back all provided arguments."""

        return self.handlers['basic'].get_tools()['echo'].func(self.session_context, **kwargs)

    

    @tool(description="Execute basic operations like echo and add")

    def basic_echo(self, message: str) -> str:

        """Echo a message back."""

        return self.handlers['basic'].get_tools()['echo'].func(self.session_context, message=message)

    

    @tool(description="Add two numbers")

    def basic_add(self, a: float, b: float) -> float:

        """Add two numbers together."""

        return self.handlers['basic'].get_tools()['add'].func(self.session_context, a=a, b=b)

    

    @tool(description="Process text with various operations")

    def process_text(self, text: str, operation: str = "upper") -> Dict[str, Any]:

        """Process text with specified operation (upper, lower, reverse, length)."""

        operations = {

            "upper": lambda t: t.upper(),

            "lower": lambda t: t.lower(), 

            "reverse": lambda t: t[::-1],

            "length": lambda t: len(t)

        }

        

        if operation in operations:

            result = operations[operation](text)

            return {

                "original": text,

                "operation": operation,

                "result": result,

                "success": True

            }

        else:

            return {

                "original": text,

                "operation": operation,

                "error": f"Unknown operation: {operation}",

                "available_operations": list(operations.keys()),

                "success": False

            }

    

    @tool(description="Get basic statistics and system information")

    def get_stats(self) -> Dict[str, Any]:

        """Return basic statistics about the adapter and system."""

        import time

        import psutil

        import os

        

        return {

            "adapter": {

                "name": "ShowcaseAdapter",

                "version": "2.0.0",

                "registered_tools": len([m for m in dir(self) if hasattr(getattr(self, m), '_tool_metadata')]),

                "session_id": self.session_context.session_id if self.session_context else None

            },

            "system": {

                "timestamp": time.time(),

                "pid": os.getpid(),

                "memory_usage_mb": round(psutil.Process().memory_info().rss / 1024 / 1024, 2),

                "cpu_percent": psutil.cpu_percent(interval=0.1)

            },

            "success": True

        }

    

    @tool(description="Perform text analysis using ML")

    def ml_analyze_text(self, text: str) -> Dict[str, Any]:

        """Analyze text using machine learning."""

        return self.handlers['ml'].get_tools()['analyze_text'].func(self.session_context, text=text)

    

    @tool(description="Process binary data", supports_streaming=False)

    def process_binary(self, data: bytes, operation: str = 'checksum') -> Any:

        """Process binary data with specified operation."""

        return self.handlers['binary'].get_tools()['process_binary'].func(

            self.session_context, 

            data=data, 

            operation=operation

        )

    

    @tool(description="Demonstrate variable operations")

    def variable_demo(self, name: str, value: Any) -> Dict[str, Any]:

        """Demonstrate variable storage and retrieval."""

        return self.handlers['variable'].get_tools()['variable_demo'].func(

            self.session_context,

            name=name,

            value=value

        )

    

    @tool(description="Stream data in chunks", supports_streaming=True)

    def stream_data(self, count: int = 5, delay: float = 1.0):

        """Stream data chunks with optional delay."""

        handler_tool = self.handlers['streaming'].get_tools()['stream_data']

        # This returns a generator for streaming

        return handler_tool.func(self.session_context, count=count, delay=delay)

    

    @tool(description="Execute concurrent tasks")

    def concurrent_demo(self, task_count: int = 3) -> Dict[str, Any]:

        """Execute multiple tasks concurrently."""

        return self.handlers['concurrent'].get_tools()['concurrent_demo'].func(

            self.session_context,

            task_count=task_count

        )

    

    @tool(description="Demonstrate integration with Elixir tools", 

          required_variables=["elixir_tools_enabled"])

    def call_elixir_demo(self, tool_name: str, **kwargs) -> Any:

        """

        Demonstrate calling an Elixir tool from Python.

        

        This showcases the bidirectional tool bridge where Python

        can seamlessly call tools implemented in Elixir.

        """

        if not self.session_context:

            raise RuntimeError("Session context not initialized")

        

        # Check if Elixir tools are available

        if tool_name in self.session_context.elixir_tools:

            result = self.session_context.call_elixir_tool(tool_name, **kwargs)

            return {

                'tool': tool_name,

                'result': result,

                'source': 'elixir',

                'message': f'Successfully called Elixir tool: {tool_name}'

            }

        else:

            available = list(self.session_context.elixir_tools.keys())

            return {

                'error': f'Elixir tool {tool_name} not found',

                'available_tools': available,

                'hint': 'Make sure the tool is registered in Elixir with exposed_to_python: true'

            }--- END FILE: snakepit/priv/python/snakepit_bridge/adapters/showcase/showcase_adapter.py ---

`````