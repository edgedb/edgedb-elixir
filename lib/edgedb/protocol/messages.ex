defmodule EdgeDB.Protocol.Messages do
  defmacro __using__(_opts \\ []) do
    quote do
      # types
      import EdgeDB.Protocol.Types.ConnectionParam
      import EdgeDB.Protocol.Types.Header
      import EdgeDB.Protocol.Types.DataElement

      # messages

      # client
      import EdgeDB.Protocol.Messages.Client.AuthenticationSASLInitialResponse
      import EdgeDB.Protocol.Messages.Client.AuthenticationSASLResponse
      import EdgeDB.Protocol.Messages.Client.ClientHandshake
      import EdgeDB.Protocol.Messages.Client.DescribeStatement
      import EdgeDB.Protocol.Messages.Client.Dump
      import EdgeDB.Protocol.Messages.Client.ExecuteScript
      import EdgeDB.Protocol.Messages.Client.Execute
      import EdgeDB.Protocol.Messages.Client.Flush
      import EdgeDB.Protocol.Messages.Client.OptimisticExecute
      import EdgeDB.Protocol.Messages.Client.Prepare
      import EdgeDB.Protocol.Messages.Client.RestoreBlock
      import EdgeDB.Protocol.Messages.Client.RestoreEOF
      import EdgeDB.Protocol.Messages.Client.Restore
      import EdgeDB.Protocol.Messages.Client.Sync
      import EdgeDB.Protocol.Messages.Client.Terminate

      # server
      import EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationOK
      import EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationSASL
      import EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationSASLContinue
      import EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationSASLFinal
      import EdgeDB.Protocol.Messages.Server.CommandComplete
      import EdgeDB.Protocol.Messages.Server.CommandDataDescription
      import EdgeDB.Protocol.Messages.Server.Data
      import EdgeDB.Protocol.Messages.Server.DumpBlock
      import EdgeDB.Protocol.Messages.Server.DumpHeader
      import EdgeDB.Protocol.Messages.Server.ErrorResponse
      import EdgeDB.Protocol.Messages.Server.LogMessage
      import EdgeDB.Protocol.Messages.Server.ParameterStatus
      import EdgeDB.Protocol.Messages.Server.PrepareComplete
      import EdgeDB.Protocol.Messages.Server.ReadyForCommand
      import EdgeDB.Protocol.Messages.Server.RestoreReady
      import EdgeDB.Protocol.Messages.Server.ServerHandshake
      import EdgeDB.Protocol.Messages.Server.ServerKeyData
    end
  end
end
