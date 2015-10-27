# 2 node demo

Example of connecting two Elixir nodes throu SSH tunnel.

![
    node Public {
      package ErlangVM1 {
        component IEx
        component PublicService
        IEx -- PublicService
      }
    }
    node Private {
      package ErlangVM2 {
        component SecretService
      }
      database Secret
      SecretService -- Secret
    }
    PublicService ..> SecretService
](http://plantuml.com:80/plantuml/png/oyjFILK8A4tAoKnMgEPIK2X8JCvEJ4zLS2tAISnB3_Cr18igA2JdvnRavwNcbIXukbQWYK2q1wSMbMKcfuBbW6eKT7Kn96gvQhdom1OMPPObbgHYjT48myRWrEIYr19aOnGKKX9B4fCIYrEXaa0H55KWsw4ojLmepb3GqxD3LGi0)

## Step 0 - Only private server

Start iex in private/

    /private$ iex -S mix
    Erlang/OTP 18 [erts-7.1] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]

    Compiled lib/secret_service.ex
    Generated private app

    17:07:59.889 [info]  SecretService started
    Interactive Elixir (1.1.0) - press Ctrl+C to exit (type h() ENTER for help)
    iex(1)> Private.SecretService.
    get_data/0      start_link/1    
    iex(1)> Private.SecretService.get_data
    "secret data"

## Step 1 - One server, one vm

Start :private in :public vm by ensuring public/mix.exs contains:

    [applications: [:logger, :private]]

Start iex in public/

    /public$ iex -S mix
    Erlang/OTP 18 [erts-7.1] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]


    17:15:05.855 [info]  SecretService started
    Interactive Elixir (1.1.0) - press Ctrl+C to exit (type h() ENTER for help)
    iex(1)> Private.SecretService.get_data
    "secret data"

## Step 2 - One server, two vms

Don't start :private in :public vm, by ensuring public/mix.es contains:

    [applications: [:logger]]

Start private iex in one console

    /private$ iex --sname private -S mix
    Erlang/OTP 18 [erts-7.1] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]


    17:26:26.831 [info]  SecretService started
    Interactive Elixir (1.1.0) - press Ctrl+C to exit (type h() ENTER for help)
    iex(private@NEWBORN)1> Private.SecretService.get_data
    "secret data"

Start public iex in second console and try to use Private.SecretService

    /public$ iex --sname public -S mix
    Erlang/OTP 18 [erts-7.1] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]

    Compiled lib/public.ex
    Generated public app
    Interactive Elixir (1.1.0) - press Ctrl+C to exit (type h() ENTER for help)
    iex(public@NEWBORN)1> Private.SecretService.get_data
    ** (exit) exited in: GenServer.call(Private.SecretService, :get, 5000)
        ** (EXIT) no process
        (elixir) lib/gen_server.ex:544: GenServer.call/3

It fails, because there is no connection between VMs and there is no process
registered under atom Private.SecretService.

Connect private to public (or vice versa, it doesn't matter)

    iex(public@NEWBORN)2> Node.connect :"private@NEWBORN"
    true
    iex(public@NEWBORN)3> Private.SecretService.get_data         
    ** (exit) exited in: GenServer.call(Private.SecretService, :get, 5000)
        ** (EXIT) no process
        (elixir) lib/gen_server.ex:544: GenServer.call/3

Nodes are connected, but Private.SecretService is registered as local.

    iex(public@NEWBORN)5> Process.whereis Private.SecretService
    nil
    iex(private@NEWBORN)2> Process.whereis Private.SecretService
    #PID<0.94.0>

You can access it using `get_data/1`

    iex(public@NEWBORN)6> Private.SecretService.get_data :"private@NEWBORN"
    "secret data"

`get_data/1` uses GenServer API to call remote node. What would happen, if
we didn't connect to private node first. Let's try it by restarting public iex.

    /public$ iex --sname public -S mix
    Erlang/OTP 18 [erts-7.1] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]

    Interactive Elixir (1.1.0) - press Ctrl+C to exit (type h() ENTER for help)
    iex(public@NEWBORN)1> Node.list
    []
    iex(public@NEWBORN)2> Private.SecretService.get_data :"private@NEWBORN"
    "secret data"
    iex(public@NEWBORN)3> Node.list
    [:private@NEWBORN]

We listed all connected nodes (1) and private is not connected. We called
GenServer with atom name of node (2) and it connected automatically as we see
result and connected node on list (3).

## Step 3 - two servers, two vms, raw tcp

Warning: In this step you connect two Erlang nodes using raw TCP connection.
This is very insecure and will allow any man-in-the-middle to connect to both
your VMs and execute arbitrary commands.

Git clone whole project on both machines. Public machine will have private code
to use client API (ie. get_data), but it will not use server callbacks.

Start private iex on server that has public IP.

    /private# iex --name private@kyon.pl --cookie OUSXEQHLTDKZGXXTAKHZ -S mix
    Erlang/OTP 18 [erts-7.0] [source] [64-bit] [async-threads:10] [kernel-poll:false]


    10:28:36.924 [info]  SecretService started
    Interactive Elixir (1.1.0) - press Ctrl+C to exit (type h() ENTER for help)
    iex(private@kyon.pl)1>

Start public iex in local console.

    public$ iex --name public@NEWBORN --cookie OUSXEQHLTDKZGXXTAKHZ -S mix                                                                                                   
    Erlang/OTP 18 [erts-7.1] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]

    Interactive Elixir (1.1.0) - press Ctrl+C to exit (type h() ENTER for help)
    iex(public@NEWBORN)1> Node.connect :"private@kyon.pl"
    true

    iex(public@NEWBORN)2> Private.SecretService.get_data :"private@kyon.pl"
    "secret data"
