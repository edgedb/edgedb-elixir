defmodule EdgeDB.Protocol.Codec do
  defstruct [
    :type_id,
    :type_name,
    :encoder,
    :decoder,
    :module,
    parent: nil,
    scalar?: false
  ]

  defmacro __using__(_opts \\ []) do
    quote do
      import EdgeDB.Protocol.Converters

      import unquote(__MODULE__)

      alias EdgeDB.Protocol.DataTypes.UUID
      alias EdgeDB.Protocol.Codec
    end
  end

  defmacro defcodec(opts \\ []) do
    calculate_size? = Keyword.get(opts, :calculate_size?, true)

    quote do
      @type t() :: unquote(Keyword.fetch!(opts, :type))

      def create_encoder(main_encoder) do
        fn instance ->
          encoded_data = main_encoder.(instance)

          if unquote(calculate_size?) do
            instance_size = IO.iodata_length(encoded_data)

            [
              EdgeDB.Protocol.DataTypes.UInt32.encode(instance_size)
              | encoded_data
            ]
          else
            encoded_data
          end
        end
      end

      def create_decoder(main_decoder) do
        if unquote(calculate_size?) do
          fn <<size::uint32, data::binary(size)>> ->
            main_decoder.(data)
          end
        else
          fn <<data::binary>> ->
            main_decoder.(data)
          end
        end
      end
    end
  end

  defmacro defbasescalarcodec(opts \\ []) do
    calculate_size? = Keyword.get(opts, :calculate_size?, true)

    quote do
      @type t() :: unquote(Keyword.fetch!(opts, :type))

      def new() do
        %unquote(__MODULE__){
          type_id: unquote(Keyword.get(opts, :type_id)),
          type_name: unquote(Keyword.get(opts, :type_name)),
          encoder: &encode/1,
          decoder: &decode/1,
          module: __MODULE__,
          scalar?: true
        }
      end

      def encode(instance) do
        encoded_data = encode_instance(instance)

        encoded_data =
          if unquote(calculate_size?) do
            instance_size = IO.iodata_length(encoded_data)

            [
              EdgeDB.Protocol.DataTypes.UInt32.encode(instance_size)
              | encoded_data
            ]
          else
            encoded_data
          end
      rescue
        _exc in FunctionClauseError ->
          raise EdgeDB.Protocol.Errors.InvalidArgumentError, "unable to encode: #{instance}"
      end

      if unquote(calculate_size?) do
        def decode(<<instance_size::uint32, data::binary(instance_size)>>) do
          decode_instance(data)
        rescue
          _exc in FunctionClauseError ->
            raise EdgeDB.Protocol.Errors.InputDataError, message: "unable to decode instance"
        end
      else
        def decode(data) when is_bitstring(data) do
          decode_instance(data)
        rescue
          _exc in FunctionClauseError ->
            raise EdgeDB.Protocol.Errors.InputDataError, message: "unable to decode instance"
        end
      end
    end
  end
end
