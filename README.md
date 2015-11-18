# PubKeys

This mix project uses an Elixir script to manage public keys from a git server. It can add and remove public keys from all targetted servers.

Once installed on the git server, users will have to ssh into the git server in order to use the tool: ssh USERNAME@YOUR_MACHINE. Your public key needs to be on the git server to access the server.

## Documentation

[PubKeys Docs](http://hardhatdigital.github.io/pub_keys/PubKeys.Helper.html)

## How to set config file

- copy `dev_example.exs` to `dev.exs` inside the config directory
- Set your config variable by Replacing "CHANGE ME" with your settings

## To build the escript file

- This mix project generates an escript executable file, which is generated from the elixir script found at lib/pub_keys.
- To build the escript file run: `mix escript.build`. This will build with `:dev` environment by default.
- Once compiled, this executable does not require Elixir to run. It's only dependancy is Erlang.

## How to use it

From anywhere on the git server:

- `pub_keys --help` to get help
- `pub_keys --add "key here"` to add key to all servers
- `pub_keys --remove "key here"` to remove key from all servers
- `pub_keys --deploy-all` to push out auth_keys files to all servers (if you want to add a key to files manually, for example)

## How it works

- A master set of auth_keys files exist at: USERNAME@YOUR_MACHINE:/YOURPATH
- Each file is named with the IP of a targetted server
- Each file contains the public_keys that should exists on that server
- The Elixir script allows you to add/remove keys to each file, and then it scp-s those files to the correct server
- If want to add a key to one or more servers (rather than to *all* servers), add the key manually to the file, and push all auth_keys files out using the script.

## ToDo
- Don't add/remove key from the YOUR_TARGETTED_MACHINE/.ssh_keys files, if SCP fails

##Contributors
[@dtcristo](https://github.com/dtcristo)

[@froesecom](https://github.com/froesecom)

[@buntine](https://github.com/buntine)

