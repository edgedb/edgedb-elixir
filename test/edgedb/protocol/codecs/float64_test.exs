defmodule Tests.EdgeDB.Protocol.Codecs.Flaot64Test do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  test "decoding std::float64 number", %{client: client} do
    value = 0.5
    assert ^value = EdgeDB.query_single!(client, "select <float64>0.5")
  end

  test "decoding NaN as std::float64 number", %{client: client} do
    value = :nan
    assert ^value = EdgeDB.query_single!(client, "select <float64>'NaN'")
  end

  test "decoding infinity as std::float64 number", %{client: client} do
    value = :infinity
    assert ^value = EdgeDB.query_single!(client, "select <float64>'inf'")
  end

  test "decoding -infinity as std::float64 number", %{client: client} do
    value = :negative_infinity
    assert ^value = EdgeDB.query_single!(client, "select <float64>'-inf'")
  end

  test "encoding std::float64 argument", %{client: client} do
    value = 1.0
    assert ^value = EdgeDB.query_single!(client, "select <float64>$0", [value])
  end

  test "encoding NaN as std::float64 argument", %{client: client} do
    value = :nan
    assert ^value = EdgeDB.query_single!(client, "select <float64>$0", [value])
  end

  test "encoding infinity as std::float64 argument", %{client: client} do
    value = :infinity
    assert ^value = EdgeDB.query_single!(client, "select <float64>$0", [value])
  end

  test "encoding -infinity as std::float64 argument", %{client: client} do
    value = :negative_infinity
    assert ^value = EdgeDB.query_single!(client, "select <float64>$0", [value])
  end

  test "error when passing non-number as std::float64 argument", %{client: client} do
    value = "something"

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(client, "select <float64>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new("value can not be encoded as std::float64: #{inspect(value)}")
  end
end
