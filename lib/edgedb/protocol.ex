defmodule EdgeDB.Protocol do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.Messages.{
    Client,
    Server
  }

  @client_modules [
    Client.AuthenticationSASLInitialResponse,
    Client.AuthenticationSASLInitialResponse,
    Client.AuthenticationSASLResponse,
    Client.ClientHandshake,
    Client.DescribeStatement,
    Client.Dump,
    Client.ExecuteScript,
    Client.Execute,
    Client.Flush,
    Client.OptimisticExecute,
    Client.Prepare,
    Client.RestoreBlock,
    Client.RestoreEOF,
    Client.Restore,
    Client.Sync,
    Client.Terminate
  ]

  @server_modules [
    Server.Authentication,
    Server.CommandComplete,
    Server.CommandDataDescription,
    Server.Data,
    Server.DumpBlock,
    Server.DumpHeader,
    Server.ErrorResponse,
    Server.LogMessage,
    Server.ParameterStatus,
    Server.PrepareComplete,
    Server.ReadyForCommand,
    Server.RestoreReady,
    Server.ServerHandshake,
    Server.ServerKeyData
  ]

  @spec encode(term()) :: binary()

  for client_module <- @client_modules do
    def encode(record) when elem(record, 0) == unquote(client_module.record_name()) do
      unquote(client_module).encode(record)
    end
  end

  @spec decode(binary()) ::
          {:ok, {term(), pos_integer()}} | {:error, {:not_enough_size, pos_integer()}}

  def decode(data) when byte_size(data) < 5 do
    {:error, {:not_enough_size, 0}}
  end

  for server_module <- @server_modules do
    def decode(<<unquote(server_module.mtype())::uint8, _rest::binary>> = data) do
      unquote(server_module).decode(data)
    end
  end
end
