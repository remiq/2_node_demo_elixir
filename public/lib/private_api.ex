defmodule Public.PrivateAPI do
  @module Private.SecretService
  @node :"private@kyon.pl"
  def get_data do
    GenServer.call {@module, @node}, :get
  end
end
