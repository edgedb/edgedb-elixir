defmodule EdgeDB.Protocol.Messages do
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

  @type client_message() ::
          Client.AuthenticationSASLInitialResponse.t()
          | Client.AuthenticationSASLInitialResponse.t()
          | Client.AuthenticationSASLResponse.t()
          | Client.ClientHandshake.t()
          | Client.DescribeStatement.t()
          | Client.Dump.t()
          | Client.ExecuteScript.t()
          | Client.Execute.t()
          | Client.Flush.t()
          | Client.OptimisticExecute.t()
          | Client.Prepare.t()
          | Client.RestoreBlock.t()
          | Client.RestoreEOF.t()
          | Client.Restore.t()
          | Client.Sync.t()
          | Client.Terminate.t()

  @type server_message() ::
          Server.Authentication.t()
          | Server.CommandComplete.t()
          | Server.CommandDataDescription.t()
          | Server.Data.t()
          | Server.DumpBlock.t()
          | Server.DumpHeader.t()
          | Server.ErrorResponse.t()
          | Server.LogMessage.t()
          | Server.ParameterStatus.t()
          | Server.PrepareComplete.t()
          | Server.ReadyForCommand.t()
          | Server.RestoreReady.t()
          | Server.ServerHandshake.t()
          | Server.ServerKeyData.t()

  @type message() :: client_message() | server_message()

  defmacro __using__(_opts \\ []) do
    quote do
      # types
      import EdgeDB.Protocol.Types.{
        ConnectionParam,
        Header,
        DataElement
      }

      # messages

      # client
      import EdgeDB.Protocol.Messages.Client.{
        AuthenticationSASLInitialResponse,
        AuthenticationSASLResponse,
        ClientHandshake,
        DescribeStatement,
        Dump,
        ExecuteScript,
        Execute,
        Flush,
        OptimisticExecute,
        Prepare,
        RestoreBlock,
        RestoreEOF,
        Restore,
        Sync,
        Terminate
      }

      # server
      import EdgeDB.Protocol.Messages.Server.Authentication.{
        AuthenticationOK,
        AuthenticationSASL,
        AuthenticationSASLContinue,
        AuthenticationSASLFinal
      }

      import EdgeDB.Protocol.Messages.Server.{
        CommandComplete,
        CommandDataDescription,
        Data,
        DumpBlock,
        DumpHeader,
        ErrorResponse,
        LogMessage,
        ParameterStatus,
        PrepareComplete,
        ReadyForCommand,
        RestoreReady,
        ServerHandshake,
        ServerKeyData
      }
    end
  end

  @spec encode_message(client_message()) :: iodata()

  for client_module <- @client_modules do
    def encode_message(record) when elem(record, 0) == unquote(client_module.record_name()) do
      unquote(client_module).encode(record)
    end
  end

  @spec decode_message(bitstring()) ::
          {:ok, {server_message(), bitstring()}} | {:error, {:not_enough_size, 0}}

  def decode_message(data) when byte_size(data) < 5 do
    {:error, {:not_enough_size, 0}}
  end

  for server_module <- @server_modules do
    def decode_message(<<unquote(server_module.mtype())::uint8, _rest::binary>> = data) do
      unquote(server_module).decode(data)
    end
  end
end
