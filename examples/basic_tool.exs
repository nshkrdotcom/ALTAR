# Basic ALTAR LATER tool execution example.
#
# Run:
#   mix run examples/basic_tool.exs

alias Altar.ADM
alias Altar.LATER.{Executor, Registry}

defmodule AltarExample.Tools do
  def get_weather(%{"location" => location, "unit" => unit}) do
    %{
      temperature: 72,
      unit: unit,
      forecast: "Sunny in #{location}"
    }
  end
end

{:ok, _pid} = Registry.start_link(name: :altar_registry)

{:ok, declaration} =
  ADM.new_function_declaration(%{
    name: "get_weather",
    description: "Get the current weather for a location.",
    parameters: %{
      type: "object",
      properties: %{
        location: %{type: "string"},
        unit: %{type: "string", enum: ["fahrenheit", "celsius"]}
      },
      required: ["location", "unit"]
    }
  })

:ok = Registry.register_tool(:altar_registry, declaration, &AltarExample.Tools.get_weather/1)

{:ok, call} =
  ADM.new_function_call(%{
    call_id: "call_123",
    name: "get_weather",
    args: %{"location" => "Honolulu, HI", "unit" => "fahrenheit"}
  })

{:ok, result} = Executor.execute_tool(:altar_registry, call)
IO.inspect(result, label: "Tool result")
