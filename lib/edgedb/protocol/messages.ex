defmodule EdgeDB.Protocol.Messages do
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
end
