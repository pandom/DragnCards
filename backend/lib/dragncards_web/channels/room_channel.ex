defmodule DragnCardsWeb.RoomChannel do
  @moduledoc """
  This channel will handle individual game rooms.
  """
  use DragnCardsWeb, :channel
  alias DragnCardsGame.{Card, GameUIServer, GameUI}

  require Logger


  def join("room:" <> room_slug, _payload, %{assigns: %{user_id: user_id}} = socket) do
    state = GameUIServer.state(room_slug)

    socket =
      socket
      |> assign(:room_slug, room_slug)

    send(self, :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, %{assigns: %{room_slug: room_slug, user_id: user_id}, channel_pid: pid} = socket) do
    # state = GameUIServer.state(room_slug)
    IO.puts("nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn after join")
    IO.inspect(socket)
    GameUIServer.add_player_to_room(room_slug, user_id, pid)
    notify(socket, user_id)
    {:noreply, socket}
  end

  def handle_in("request_state", _payload, %{assigns: %{room_slug: room_slug}} = socket) do
    state = GameUIServer.state(room_slug)
    {:reply, {:ok, client_state(socket, state)}, socket}
  end

  def handle_in(
    "game_action",
    %{
      "action" => action,
      "options" => options,
      "timestamp" => timestamp,
    },
    %{assigns: %{room_slug: room_slug, user_id: user_id}} = socket
  ) do
    GameUIServer.game_action(room_slug, user_id, action, options)
    state = GameUIServer.state(room_slug)

    notify(socket, user_id)

    {:reply, {:ok, "game_action"}, socket}
  end

  def handle_in(
    "set_seat",
    %{
      "player_i" => player_i,
      "new_user_id" => new_user_id,
      "timestamp" => timestamp,
    },
    %{assigns: %{room_slug: room_slug, user_id: user_id}} = socket
  ) do
    GameUIServer.set_seat(room_slug, user_id, player_i, new_user_id)

    notify(socket, user_id)

    {:reply, :ok, socket}
  end

  def handle_in(
    "close_room",
    %{},
    %{assigns: %{room_slug: room_slug, user_id: user_id}} = socket
  ) do
    GameUIServer.close_room(room_slug, user_id)

    notify(socket, user_id)

    {:reply, :ok, socket}
  end

  @doc """
  notify_from_outside/1: Tell everyone in the channel to send a message
  asking for a state update.
  This used to broadcast game state to everyone, but game state can contain
  private information.  So we tell everyone to ask for an update instead. Since
  we're over a websocket, the extra cost shouldn't be that bad.
  SERVER: "ask_for_update", %{}
  CLIENT: "request_state", %{}
  SERVER: "phx_reply", %{personalized state}

  Note 1: After making this, I found a Phoenix Channel mechanism that lets
  you intercept and change outgoing messages.  That might be better.
  Note 2: "Outside" here means a caller from anywhere in the system can call
  this, unlike "notify".
  """
  def notify_from_outside(room_slug) do
    payload = %{user_id: 0}
    DragnCardsWeb.Endpoint.broadcast!("room:" <> room_slug, "ask_for_update", payload)
  end

  def terminate({:normal, _payload}, socket) do
    # Closed normally. Do nothing.
    {:ok}
  end

  def terminate({:shutdown, :left}, socket) do
    on_terminate(socket)
  end

  def terminate({:shutdown, :closed}, socket) do
    on_terminate(socket)
  end

  def terminate(_reason, socket) do
    on_terminate(socket)
  end

  defp on_terminate(%{assigns: %{room_slug: room_slug, user_id: user_id}, channel_pid: pid} = socket) do
    state = GameUIServer.leave(room_slug, user_id, pid)
    notify(socket, user_id)
  end

  defp notify(socket, user_id) do
    # Fake a phx_reply event to everyone
    payload = %{
      response: %{user_id: user_id},
      status: "ok"
    }

    broadcast!(socket, "ask_for_update", payload)
  end

  # This is what part of the state gets sent to the client.
  # It can be used to transform or hide it before they get it.
  defp client_state(socket, state) do
    state
  end
end
