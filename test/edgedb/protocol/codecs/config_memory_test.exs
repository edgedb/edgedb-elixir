defmodule Tests.EdgeDB.Protocol.Codecs.ConfigMemoryTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  test "decoding cfg::memory value", %{client: client} do
    value = 42 * 1024 * 1024

    assert %EdgeDB.ConfigMemory{bytes: ^value} =
             EdgeDB.query_single!(client, "select <cfg::memory>'42MiB'")
  end

  test "encoding integer as cfg::memory value", %{client: client} do
    value = 42

    assert %EdgeDB.ConfigMemory{bytes: ^value} =
             EdgeDB.query_single!(client, "select <cfg::memory>$0", [value])
  end

  test "encoding EdgeDB.ConfigMemory as cfg::memory value", %{client: client} do
    value = %EdgeDB.ConfigMemory{bytes: 42 * 1024}

    assert true ==
             EdgeDB.query_single!(client, "select <cfg::memory>$0 = <cfg::memory>'42KiB'", [value])
  end

  test "error when passing too large number as cfg::memory argument", %{client: client} do
    value = 0x8000000000000000

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(client, "select <cfg::memory>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new(
               "value can not be encoded as cfg::memory: #{inspect(value)}"
             )
  end

  test "error when passing invalid entity as cfg::memory argument", %{client: client} do
    value = "42KiB"

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(client, "select <cfg::memory>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new(
               "value can not be encoded as cfg::memory: #{inspect(value)}"
             )
  end
end
