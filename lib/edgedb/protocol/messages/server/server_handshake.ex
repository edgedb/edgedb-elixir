defmodule EdgeDB.Protocol.Messages.Server.ServerHandshake do
  @moduledoc false

  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Types
  }

  defmessage(
    server: true,
    mtype: 0x76,
    fields: [
      major_ver: Datatypes.UInt16.t(),
      minor_ver: Datatypes.UInt16.t(),
      extensions: list(Types.ProtocolExtension.t())
    ]
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(
        <<major_ver::uint16, minor_ver::uint16, num_extensions::uint16, rest::binary>>
      ) do
    {extensions, <<>>} = Types.ProtocolExtension.decode(num_extensions, rest)

    %__MODULE__{
      major_ver: major_ver,
      minor_ver: minor_ver,
      extensions: extensions
    }
  end
end
