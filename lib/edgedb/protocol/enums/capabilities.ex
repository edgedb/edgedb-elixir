defmodule EdgeDB.Protocol.Enums.Capabilities do
  @moduledoc """
  Query capabilities.

  Values:

    * `:readonly` - query is read-only.
    * `:modifications` - query is not read-only.
    * `:session_config` - query contains session config change.
    * `:transaction` - query contains start/commit/rollback of transaction or savepoint manipulation.
    * `:ddl` - query contains DDL.
    * `:persistent_config` - server or database config change.
    * `:all` - all possible capabilities.
    * `:execute` - capabilities to execute query.
  """

  use EdgeDB.Protocol.Enum

  alias Bitwise

  alias EdgeDB.Protocol.Datatypes

  @codes_to_decode [
    0x0,
    0x1,
    0x2,
    0x4,
    0x8,
    0x10
  ]

  defenum(
    values: [
      readonly: 0x0,
      modifications: 0x1,
      session_config: 0x2,
      transaction: 0x4,
      ddl: 0x8,
      persistent_config: 0x10,
      all: 0xFFFF_FFFF_FFFF_FFFF,
      execute: 0xFFFF_FFFF_FFFF_FFFB
    ],
    union: true,
    datatype: Datatypes.UInt64
  )

  @impl EdgeDB.Protocol.Enum
  def encode(capabilities) do
    capabilities
    |> List.wrap()
    |> Enum.map(&to_code(&1))
    |> Enum.reduce(0, &Bitwise.bor(&1, &2))
    |> super()
  end

  @impl EdgeDB.Protocol.Enum
  def decode(capabilities) do
    {capabilities, rest} = enum_codec().decode(capabilities)

    capabilities =
      @codes_to_decode
      |> Enum.map(fn code ->
        if Bitwise.band(capabilities, code) != 0 do
          to_atom(code)
        else
          nil
        end
      end)
      |> Enum.reject(&is_nil(&1))

    # if after processing we get an empty list then capabilities is 0
    # which corresonds to :readonly capability
    capabilities =
      case capabilities do
        [] ->
          [:readonly]

        capabilities ->
          capabilities
      end

    {capabilities, rest}
  end

  @doc false
  # this is special case for usage in headers processing
  # when we process headers we are sure that there won't
  # be any additional data after decoding datatype
  # or if there is, then it's an error in driver's protocol
  @spec exhaustive_decode(bitstring()) :: t()
  def exhaustive_decode(capabilities) do
    {capabilities, <<>>} = decode(capabilities)
    capabilities
  end
end
