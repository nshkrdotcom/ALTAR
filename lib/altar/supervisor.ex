defmodule Altar.Supervisor do
  @moduledoc """
  Top-level supervisor for the ALTAR application.

  Manages the Local Agent & Tool Execution Runtime (LATER) processes, starting
  with a named `Altar.LATER.Registry` so it can be discovered by other
  components without passing around pids.
  """

  use Supervisor

  alias Altar.LATER.Registry

  @doc """
  Start the top-level supervisor.
  """
  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(init_arg \\ :ok) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  @spec init(term()) ::
          {:ok, {Supervisor.sup_flags(), [Supervisor.child_spec()]}}
          | {:ok, [Supervisor.child_spec()]}
          | :ignore
  def init(_init_arg) do
    children = [
      {Registry, name: Registry}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
