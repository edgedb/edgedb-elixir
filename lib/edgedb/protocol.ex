defmodule EdgeDB.Protocol do
  import EdgeDB.Protocol.Converters

  @client_modules [
    EdgeDB.Protocol.Messages.Client.AuthenticationSASLInitialResponse,
    EdgeDB.Protocol.Messages.Client.AuthenticationSASLInitialResponse,
    EdgeDB.Protocol.Messages.Client.AuthenticationSASLResponse,
    EdgeDB.Protocol.Messages.Client.ClientHandshake,
    EdgeDB.Protocol.Messages.Client.DescribeStatement,
    EdgeDB.Protocol.Messages.Client.Dump,
    EdgeDB.Protocol.Messages.Client.ExecuteScript,
    EdgeDB.Protocol.Messages.Client.Execute,
    EdgeDB.Protocol.Messages.Client.Flush,
    EdgeDB.Protocol.Messages.Client.OptimisticExecute,
    EdgeDB.Protocol.Messages.Client.Prepare,
    EdgeDB.Protocol.Messages.Client.RestoreBlock,
    EdgeDB.Protocol.Messages.Client.RestoreEOF,
    EdgeDB.Protocol.Messages.Client.Restore,
    EdgeDB.Protocol.Messages.Client.Sync,
    EdgeDB.Protocol.Messages.Client.Terminate
  ]

  @server_modules [
    EdgeDB.Protocol.Messages.Server.Authentication,
    EdgeDB.Protocol.Messages.Server.CommandComplete,
    EdgeDB.Protocol.Messages.Server.CommandDataDescription,
    EdgeDB.Protocol.Messages.Server.Data,
    EdgeDB.Protocol.Messages.Server.DumpBlock,
    EdgeDB.Protocol.Messages.Server.DumpHeader,
    EdgeDB.Protocol.Messages.Server.ErrorResponse,
    EdgeDB.Protocol.Messages.Server.LogMessage,
    EdgeDB.Protocol.Messages.Server.ParameterStatus,
    EdgeDB.Protocol.Messages.Server.PrepareComplete,
    EdgeDB.Protocol.Messages.Server.ReadyForCommand,
    EdgeDB.Protocol.Messages.Server.RestoreReady,
    EdgeDB.Protocol.Messages.Server.ServerHandshake,
    EdgeDB.Protocol.Messages.Server.ServerKeyData
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
