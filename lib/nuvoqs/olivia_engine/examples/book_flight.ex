defmodule Nuvoqs.OliviaEngine.Examples.BookFlight do
  @moduledoc """
  Example flow: Book a flight.

  Demonstrates:
  - Multi-node dialog with slot filling
  - Branching transitions based on intent (confirm/deny)
  - Terminal node with action execution
  - Slot interpolation in messages

  ## Setup

      # In your Application.start/2:
      Nuvoqs.OliviaEngine.Flow.Registry.register_module(Nuvoqs.OliviaEngine.Examples.BookFlight)

      # Register the action handler:
      Nuvoqs.OliviaEngine.Flow.Actions.register(:book_flight, fn ctx ->
        dest = ctx.slots[:destination]
        date = ctx.slots[:date]
        {:ok, "Flight to \#{dest} on \#{date} confirmed! Ref: #\#{:rand.uniform(99999)}"}
      end)
  """

  use Nuvoqs.OliviaEngine.Flow.DSL

  flow "book_flight" do
    node :greeting do
      say("Great, let's book a flight! Where would you like to go?")
      transition(:collect_info)
    end

    node :collect_info do
      slot :destination, entity: "wit$location", prompt: "Which city would you like to fly to?"
      slot :date, entity: "wit$datetime", prompt: "When would you like to travel?"
      slot :passengers, entity: "wit$number", prompt: "How many passengers?", required: false
      on_slots_filled(:confirm)
    end

    node :confirm do
      say("Let me confirm: flight to {{destination}} on {{date}}. Should I book it?")
      transition(:done, when: "confirm")
      transition(:collect_info, when: "deny")
      transition(:cancel, when: "cancel")
    end

    node :done do
      action(:book_flight)
      say("Your flight has been booked! Anything else I can help with?")
      terminal(true)
    end

    node :cancel do
      say("No problem, booking cancelled. Let me know if you need anything else.")
      terminal(true)
    end
  end
end
