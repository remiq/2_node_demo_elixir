defmodule Private.SecretService do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link __MODULE__, [], opts
  end

  def get_data do
    GenServer.call __MODULE__, :get
  end

  def get_data(node) do
    GenServer.call {__MODULE__, node}, :get
  end

  def init(_args) do
    Logger.info "SecretService started"
    {:ok, "secret data"}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end
end
