defmodule Altar.LATER.Registry do
  @moduledoc """
  Registry of tool implementations for the Local Agent & Tool Execution Runtime (LATER).

  This module manages an in-process registry of tool functions keyed by their
  validated `Altar.ADM.FunctionDeclaration.name`. It is implemented as a
  `GenServer` for safe, serialized updates and queries.

  State is a map of `function_name :: String.t()` to implementation
  functions of arity 1 that accept the tool arguments map.
  """

  use GenServer

  alias Altar.ADM.FunctionDeclaration

  @typedoc """
  A tool implementation function. Must be arity-1 and accept a map of arguments.
  """
  @type tool_fun :: (map() -> any())

  @typedoc """
  The internal state of the registry process.
  """
  @type state :: %{optional(String.t()) => tool_fun()}

  # -- Public API -------------------------------------------------------------

  @doc """
  Start the registry process.

  Standard `GenServer.start_link/3` options are accepted.
  """
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) when is_list(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @doc """
  Register a tool implementation under the provided declaration's name.

  - `registry` is the pid or name of the registry process
  - `declaration` is a validated `%Altar.ADM.FunctionDeclaration{}`
  - `fun` is an arity-1 function that accepts a map of arguments

  Returns `:ok` on success or `{:error, reason}` if registration fails
  (e.g., name already registered or invalid function arity).
  """
  @spec register_tool(GenServer.server(), FunctionDeclaration.t(), tool_fun()) ::
          :ok | {:error, term()}
  def register_tool(registry, %FunctionDeclaration{name: name}, fun)
      when is_function(fun, 1) and is_binary(name) do
    GenServer.call(registry, {:register_tool, name, fun})
  end

  def register_tool(_registry, %FunctionDeclaration{name: _name}, fun)
      when not is_function(fun, 1) do
    {:error, :invalid_function_arity}
  end

  @doc """
  Look up a tool implementation by its function name.

  Returns `{:ok, fun}` when found or `{:error, :not_found}` otherwise.
  """
  @spec lookup_tool(GenServer.server(), String.t()) :: {:ok, tool_fun()} | {:error, :not_found}
  def lookup_tool(registry, function_name) when is_binary(function_name) do
    GenServer.call(registry, {:lookup_tool, function_name})
  end

  # -- GenServer callbacks ----------------------------------------------------

  @impl true
  @spec init(state()) :: {:ok, state()}
  def init(_init_arg) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:register_tool, name, fun}, _from, state) do
    case Map.has_key?(state, name) do
      true -> {:reply, {:error, :already_registered}, state}
      false -> {:reply, :ok, Map.put(state, name, fun)}
    end
  end

  @impl true
  def handle_call({:lookup_tool, name}, _from, state) do
    case Map.fetch(state, name) do
      {:ok, fun} -> {:reply, {:ok, fun}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end
end
