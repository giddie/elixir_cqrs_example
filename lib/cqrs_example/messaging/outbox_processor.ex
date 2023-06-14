defmodule CqrsExample.Messaging.OutboxProcessor do
  @moduledoc false

  alias __MODULE__, as: Self
  alias CqrsExample.Messaging
  alias CqrsExample.Repo

  use GenServer

  defmodule State do
    @moduledoc false

    alias __MODULE__, as: Self

    @enforce_keys [:notifications_pid, :listen_reference]
    defstruct @enforce_keys

    @type t :: %Self{
            notifications_pid: pid(),
            listen_reference: {:some, reference()} | :none
          }

    @spec new(pid()) :: Self.t()
    def new(notifications_pid) when is_pid(notifications_pid) do
      %Self{
        notifications_pid: notifications_pid,
        listen_reference: :none
      }
    end
  end

  # Client

  @spec start_link(Keyword.t()) :: {:ok, pid()}
  def start_link(opts \\ []) do
    GenServer.start_link(Self, opts, name: __MODULE__)
  end

  @spec check_for_new_messages() :: :ok
  def check_for_new_messages() do
    GenServer.cast(Self, :check_for_new_messages)
  end

  # Server

  @impl GenServer
  def init(_opts) do
    {:ok, notifications_pid} = Postgrex.Notifications.start_link(Repo.config())
    state = State.new(notifications_pid)
    send(self(), :process_outbox)

    {:ok, state}
  end

  @impl GenServer
  def handle_cast(:check_for_new_messages, %State{} = state) do
    send(self(), :process_outbox)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:process_outbox, %State{} = state) do
    num_processed = Messaging.process_outbox_batch()

    if num_processed > 0 do
      if state.listen_reference != :none do
        send(self(), :unsubscribe_from_insert_notification)
      end

      send(self(), :process_outbox)
    else
      if state.listen_reference == :none do
        send(self(), :subscribe_to_insert_notification)
        send(self(), :process_outbox)
      end
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        :subscribe_to_insert_notification,
        %State{listen_reference: :none} = state
      ) do
    {:ok, listen_reference} =
      Postgrex.Notifications.listen(state.notifications_pid, "messaging__outbox_messages")

    state = %{state | listen_reference: {:some, listen_reference}}

    {:noreply, state}
  end

  def handle_info(:subscribe_to_insert_notification, %State{} = state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        :unsubscribe_from_insert_notification,
        %State{listen_reference: {:some, listen_reference}} = state
      ) do
    :ok = Postgrex.Notifications.unlisten(state.notifications_pid, listen_reference)

    state = %{state | listen_reference: :none}

    {:noreply, state}
  end

  def handle_info(:unsubscribe_from_insert_notification, %State{} = state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {:notification, _notification_pid, _listen_ref, "messaging__outbox_messages", _message},
        %State{} = state
      ) do
    send(self(), :process_outbox)
    {:noreply, state}
  end
end
