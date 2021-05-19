defmodule EdgeDB.Protocol.Message do
  defmacro __using__(_opts \\ []) do
    quote do
      import Record

      import EdgeDB.Protocol.Converters

      import unquote(__MODULE__)
    end
  end

  defmacro defmessage(opts) do
    {:ok, mtype} = Keyword.fetch(opts, :mtype)
    {:ok, record_name} = Keyword.fetch(opts, :name)

    record_fields = Keyword.get(opts, :fields, [])
    has_fields? = length(record_fields) != 0
    field_names = Keyword.keys(record_fields)

    declare_client? = Keyword.get(opts, :client, false)
    declare_server? = Keyword.get(opts, :server, false)

    quote do
      defrecord unquote(record_name), unquote(field_names)

      @type t() :: record(unquote(record_name), unquote(record_fields))

      @spec mtype() :: unquote(mtype)
      def mtype do
        unquote(mtype)
      end

      @spec record_name() :: unquote(record_name)
      def record_name do
        unquote(record_name)
      end

      if unquote(declare_client?) do
        @spec encode(t()) :: bitstring()
      end

      if unquote(declare_server?) do
        @spec decode(bitstring()) ::
                {:ok, {t(), bitstring()}} | {:error, {:not_enough_size, integer()}}
      end

      if unquote(declare_client?) do
        def encode(unquote(record_name)() = message) do
          message_payload = encode_message(message)

          [
            EdgeDB.Protocol.DataTypes.UInt8.encode(unquote(mtype)),
            EdgeDB.Protocol.DataTypes.UInt32.encode(IO.iodata_length(message_payload) + 4)
            | message_payload
          ]
        end

        if not unquote(has_fields?) do
          defp encode_message(unquote(record_name)()) do
            []
          end
        end
      end

      if unquote(declare_server?) do
        def decode(<<rest::binary>>) when byte_size(rest) < 5 do
          {:error, {:not_enough_size, 0}}
        end

        def decode(<<unquote(mtype)::uint8, message_length::uint32, rest::binary>>) do
          payload_length = message_length - 4

          case rest do
            <<message_payload::binary(payload_length), rest::binary>> ->
              {:ok, {decode_message(message_payload), rest}}

            _ ->
              {:error, {:not_enough_size, payload_length - byte_size(rest)}}
          end
        end
      end
    end
  end
end
