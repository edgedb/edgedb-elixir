defmodule EdgeDB.Protocol.Converters do
  defmacro binary(size), do: quote(do: binary - size(unquote(size)))

  defmacro int8, do: quote(do: signed - 8)
  defmacro int16, do: quote(do: signed - 16)
  defmacro int32, do: quote(do: signed - 32)
  defmacro int64, do: quote(do: signed - 64)

  defmacro uint8, do: quote(do: unsigned - 8)
  defmacro uint16, do: quote(do: unsigned - 16)
  defmacro uint32, do: quote(do: unsigned - 32)
  defmacro uint64, do: quote(do: unsigned - 64)

  defmacro float32, do: quote(do: float - 32)
  defmacro float64, do: quote(do: float - 64)

  defmacro uuid, do: quote(do: unsigned - 128)
end
