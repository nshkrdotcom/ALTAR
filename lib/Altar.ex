defmodule Altar do
  @moduledoc """
  ALTAR application entrypoint.

  Boots the top-level supervisor that manages the Local Agent & Tool Execution
  Runtime (LATER) processes.
  """

  use Application

  @impl true
  def start(_type, _args) do
    Altar.Supervisor.start_link(:ok)
  end
end
