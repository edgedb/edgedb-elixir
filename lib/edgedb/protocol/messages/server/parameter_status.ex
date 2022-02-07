defmodule EdgeDB.Protocol.Messages.Server.ParameterStatus do
  @moduledoc false

  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Datatypes

  defmessage(
    server: true,
    mtype: 0x53,
    fields: [
      name: Datatypes.Bytes.t(),
      value: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<data::binary>>) do
    {name, rest} = Datatypes.Bytes.decode(data)
    {value, <<>>} = Datatypes.Bytes.decode(rest)

    %__MODULE__{
      name: name,
      value: value
    }
  end
end
