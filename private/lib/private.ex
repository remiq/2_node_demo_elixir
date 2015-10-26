defmodule Private do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Private.SecretService, [[name: Private.SecretService]])
      #worker(Private.SecretService, [[name: {:via, :gproc, Private.SecretService}]])
    ]
    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
