# Custom codecs for EdgeDB scalars

`EdgeDB.Protocol.Codec` is a structure that knows how to encode or decode Elixir types into EdgeDB types
  and vice versa using the EdgeDB binary format.

Custom codecs can be useful when your EdgeDB scalars need their own processing.

You can use the `EdgeDB.Protocol.Codec.defscalarcodec/1` macros to define a custom codec.
  It will generate code with `EdgeDB.Protocol.Codec` behavior, which will require
  implementing `c:EdgeDB.Protocol.Codec.encode_instance/1` and `c:EdgeDB.Protocol.Codec.decode_instance/1` callbacks.

In most cases you can use already defined codecs to work with the EdgeDB binary protocol. Otherwise,
  you will need to check to the EdgeDB [binary protocol documentation](https://www.edgedb.com/docs/reference/protocol).

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
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Codecs

  alias MyApp.Users.Payload

  defscalarcodec(
    type_name: "default::JSONPayload",
    type: Payload.t(),
    calculate_size: false  # we need that because the JSON codec calculates its own size and we rely on JSON codec
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(%Payload{} = payload) do
    payload
    |> Map.from_struct()
    |> Codecs.Builtin.JSON.encode_instance()
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(binary_data) do
    %{
      "public_id" => public_id,
      "first_name" => first_name,
      "last_name" => last_name
    } = Codecs.Builtin.JSON.decode_instance(binary_data)

    %Payload{
      public_id: public_id,
      first_name: first_name,
      last_name: last_name
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
