# Custom codecs for EdgeDB scalars

`EdgeDB.Protocol.Codec` is a codec that knows how to encode or decode Elixir types into EdgeDB types
  and vice versa using the EdgeDB binary format.

Custom codecs can be useful when your EdgeDB scalars need their own processing.

> #### NOTE {: .warning}
>
> Although most of the driver API is complete, some internal parts may be changed in the future.
>   The implementation of the binary protocol (including the definition of custom codecs) is on the list of possible changes.

In most cases you can use already defined codecs to work with the EdgeDB binary protocol. Otherwise,
  you will need to check to the EdgeDB [binary protocol documentation](https://www.edgedb.com/docs/reference/protocol).

To implement custom codec it will be required to implement `EdgeDB.Protocol.CustomCodec` behaviour
  and implement `EdgeDB.Protocol.Codec` protocol.

As an example, let's create a custom codec for a scalar that extends the standard `std::json` type.

```edgeql
module default {
    scalar type JSONPayload extending json;

    type User {
        required property name -> str {
            constraint exclusive;
        };

        required property payload -> JSONPayload;
    }
};
```

We will convert the following structure to `default::JSONPayload`:

```elixir
defmodule MyApp.Users.Payload do
  defstruct [
    :public_id,
    :first_name,
    :last_name
  ]

  @type t() :: %__MODULE__{
          public_id: integer(),
          first_name: String.t(),
          last_name: String.t()
        }
end
```

The implementation of the codec itself:

```elixir
defmodule MyApp.EdgeDB.Codecs.JSONPayload do
  @behviour EdgeDB.Protocol.CustomCodec

  defstruct []

  @impl EdgeDB.Protocol.CustomCodec
  def new do
    %__MODULE__{}
  end

  @impl EdgeDB.Protocol.CustomCodec
  def name do
    "default::JSONPayload"
  end
end

defimpl EdgeDB.Protocol.Codec, for: MyApp.EdgeDB.Codecs.JSONPayload do
  alias EdgeDB.Protocol.{
    Codec,
    CodecStorage
  }

  alias MyApp.EdgeDB.Codecs.JSONPayload
  alias MyApp.Users.Payload

  @impl Codec
  def encode(_codec, %Payload{} = payload, codec_storage) do
    json_codec = CodecStorage.get_by_name(codec_storage, "std::json")
    Codec.encode(json_codec, Map.from_struct(payload), codec_storage)
  end

  @impl Codec
  def encode(_codec, value, codec_storage) do
    raise EdgeDB.Error.interface_error(
            "unexpected value to encode as #{inspect(JSONPayload.name())}: #{inspect(value)}"
          )
  end

  @impl Codec
  def decode(_codec, data, codec_storage) do
    json_codec = CodecStorage.get_by_name(codec_storage, "std::json")
    payload = Codec.decode(json_codec, data, codec_storage)
    %Payload{
      public_id: payload["public_id"]
      first_name: payload["first_name"]
      last_name: payload["last_name"]
    }
  end
end
```

Now let's test this codec:

```elixir
iex(1)> {:ok, pid} = EdgeDB.start_link(codecs: [MyApp.EdgeDB.Codecs.JSONPayload])
iex(1)> payload = %MyApp.Users.Payload{public_id: 1, first_name: "Harry", last_name: "Potter"}
iex(2)> EdgeDB.query!(pid, "INSERT User { name := <str>$username, payload := <JSONPayload>$payload }", username: "user", payload: payload)
iex(3) EdgeDB.Object{} = EdgeDB.query_required_single!(pid, "SELECT User {name, payload} FILTER .name = 'user' LIMIT 1")
#EdgeDB.Object<name := "user", payload := %MyApp.Users.Payload{
  first_name: "Harry",
  last_name: "Potter",
  public_id: 1
}>
```
