# 2 node demo

Example of connecting two Elixir nodes throu SSH tunnel.

Basic idea:

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

UPDATE: Public machine will not have private code after release. Please check
step 5.

We are no longer using `--sname private`, which is short name of node. Since now
we are on two servers, we use `--name private@kyon.pl`.

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

How do we test insecurity of this step?
Start tcpdump on public server and retry whole step.

    /public$ sudo tcpdump dst kyon.pl -w k.dump

Open `k.dump` file. You will see binary data with plain text modules and
method names. It does not prove cookie is unencrypted (because it's not
plaintext), but it shows connection is not encrypted.

## Step 4 - two servers, two vms, IPsec

(untested)

Using [this tutorial](http://7u83.cauwersin.com/2014-04-06-creating-ipsec-transport-between-freebsd-and-linux)
we set-up secure connection between both nodes. Elixir does not change here.

## Step 5 - using releases

Release private/

    /private$ MIX_ENV=prod mix release

Copy `/private/rel/private/releases/0.0.1/private.tar.gz` to remote server, unpack, start with console

    cd remote/private/
    tar xvzf private.tar.gz
    /private# bin/private console
    iex(private@127.0.0.1)1> Node.get_cookie
    :private

As we see, neither name of node nor cookie is defined. Edit `releases/0.0.1/vm.args`.

    ## Name of the node
    -name private@kyon.pl

    ## Cookie for distributed erlang
    -setcookie OUSXEQHLTDKZGXXTAKHZ

Start private, again with console.

    iex(private@kyon.pl)1> Node.get_cookie
    :OUSXEQHLTDKZGXXTAKHZ

It works now, but every release we will need to change it in `vm.args`. We have
to configure it before release, but I don't know where.

Application works in console, so we can start it properly.

    /private# bin/private start

And connect using remote_console

    iex(private@kyon.pl)1> Private.SecretService.  
    get_data/0      get_data/1      start_link/1    
    iex(private@kyon.pl)1> Private.SecretService.get_data
    "secret data"
    iex(private@kyon.pl)2> Private.SecretService.get_data :"private@kyon.pl"
    "secret data"

Now repeat all steps for public.

    iex(public@NEWBORN)1> Node.get_cookie
    :OUSXEQHLTDKZGXXTAKHZ
    iex(public@NEWBORN)2> Node.connect :"private@kyon.pl"
    true
    iex(public@NEWBORN)3> Private.SecretService.get_data
    ** (UndefinedFunctionError) undefined function: Private.SecretService.get_data/0 (module Private.SecretService is not available)
        Private.SecretService.get_data()

Cookie is correct, nodes connect to each other, but module Private.SecretService
is not loaded here:

    def application do
      [applications: [:logger]]
    end

But if we add :private, it will start local private service. What to do? We either
add configuration that allow us not to start private, or we create client API in
:public. We will do the second way.

    iex(public@NEWBORN)1> Public.PrivateAPI.get_data
    "secret data"

## Summary

Final structure:

![
    node Public {
      package ErlangVM1 {
        component IEx
        component PublicService
        interface PrivateAPI
        IEx -- PublicService
        PublicService -- PrivateAPI
      }
    }
    node Private {
      package ErlangVM2 {
        component SecretService
      }
      database Secret
      SecretService -- Secret
    }
    PrivateAPI ..> SecretService : IPsec\n tunnel
](http://plantuml.com:80/plantuml/png/TK-z2eCm4DvzYdi1XNRiKEZWaA4W29swdETLGkqfCKgX-EwrHc8LpN21x-_kaofdIDgir0IV0CPN8psnO8XDYLBShWVF053rgYjXiQ3YzmRgeb8sdIRsl1RBve4qh3AwGykNH7bo288mt74kq56s3kY3UShOnYbswnmtwwHCXkroVJ_zELhCiE59DA4Bn--qFzOvvriXYiuhmmbKqZ3T1MmhmkKN)
