defmodule Tests.EdgeDB.Protocol.Codecs.RangeTest do
  use Tests.Support.EdgeDBCase

  skip_before(version: 2, scope: :module)

  @input_ranges %{
    "range<int32>" => [
      EdgeDB.Range.new(1, 2),
      {EdgeDB.Range.new(1, 2, inc_upper: true), EdgeDB.Range.new(1, 3)},
      EdgeDB.Range.empty(),
      {EdgeDB.Range.new(1, 1), EdgeDB.Range.empty()},
      EdgeDB.Range.new(nil, nil)
    ],
    "range<int64>" => [
      EdgeDB.Range.new(1, 2),
      {EdgeDB.Range.new(1, 2, inc_upper: true), EdgeDB.Range.new(1, 3)},
      EdgeDB.Range.empty(),
      {EdgeDB.Range.new(1, 1), EdgeDB.Range.empty()},
      EdgeDB.Range.new(nil, nil)
    ],
    "range<float32>" => [
      EdgeDB.Range.new(1.5, 2.5),
      {EdgeDB.Range.new(1.5, 2.5, inc_upper: true), EdgeDB.Range.new(1.5, 2.5, inc_upper: true)},
      EdgeDB.Range.empty(),
      {EdgeDB.Range.new(1.5, 1.5), EdgeDB.Range.empty()},
      EdgeDB.Range.new(nil, nil)
    ],
    "range<float64>" => [
      EdgeDB.Range.new(1.5, 2.5),
      {EdgeDB.Range.new(1.5, 2.5, inc_upper: true), EdgeDB.Range.new(1.5, 2.5, inc_upper: true)},
      EdgeDB.Range.empty(),
      {EdgeDB.Range.new(1.5, 1.5), EdgeDB.Range.empty()},
      EdgeDB.Range.new(nil, nil)
    ],
    "range<decimal>" => [
      EdgeDB.Range.new(Decimal.new(1), Decimal.new(2)),
      {EdgeDB.Range.new(Decimal.new(1), Decimal.new(2), inc_upper: true),
       EdgeDB.Range.new(Decimal.new(1), Decimal.new(2), inc_upper: true)},
      EdgeDB.Range.empty(),
      {EdgeDB.Range.new(Decimal.new(1), Decimal.new(1)), EdgeDB.Range.empty()},
      EdgeDB.Range.new(nil, nil)
    ],
    "range<datetime>" => [
      EdgeDB.Range.new(~U[2022-07-01 00:00:00Z], ~U[2022-12-01 00:00:00Z]),
      {EdgeDB.Range.new(~U[2022-07-01 00:00:00Z], ~U[2022-12-01 00:00:00Z], inc_upper: true),
       EdgeDB.Range.new(~U[2022-07-01 00:00:00Z], ~U[2022-12-01 00:00:00Z], inc_upper: true)},
      EdgeDB.Range.empty(),
      {EdgeDB.Range.new(~U[2022-07-01 00:00:00Z], ~U[2022-07-01 00:00:00Z]),
       EdgeDB.Range.empty()},
      EdgeDB.Range.new(nil, nil)
    ],
    "range<cal::local_datetime>" => [
      EdgeDB.Range.new(~N[2022-07-01 00:00:00Z], ~N[2022-12-01 00:00:00Z]),
      {EdgeDB.Range.new(~N[2022-07-01 00:00:00Z], ~N[2022-12-01 00:00:00Z], inc_upper: true),
       EdgeDB.Range.new(~N[2022-07-01 00:00:00Z], ~N[2022-12-01 00:00:00Z], inc_upper: true)},
      EdgeDB.Range.empty(),
      {EdgeDB.Range.new(~N[2022-07-01 00:00:00Z], ~N[2022-07-01 00:00:00Z]),
       EdgeDB.Range.empty()},
      EdgeDB.Range.new(nil, nil)
    ],
    "range<cal::local_date>" => [
      EdgeDB.Range.new(~D[2022-07-01], ~D[2022-12-01]),
      {EdgeDB.Range.new(~D[2022-07-01], ~D[2022-12-01], inc_upper: true),
       EdgeDB.Range.new(~D[2022-07-01], ~D[2022-12-02])},
      EdgeDB.Range.empty(),
      {EdgeDB.Range.new(~D[2022-07-01], ~D[2022-07-01]), EdgeDB.Range.empty()},
      EdgeDB.Range.new(nil, nil)
    ]
  }

  setup :edgedb_client

  test "decoding range value with lower bound and without upper bound", %{client: client} do
    value = EdgeDB.Range.new(1, 10)
    assert ^value = EdgeDB.query_required_single!(client, "select range(1, 10)")
  end

  test "decoding range value without lower bound and without upper bound", %{client: client} do
    value = EdgeDB.Range.new(2, 10)

    assert ^value =
             EdgeDB.query_required_single!(client, """
               select range(1, 10, inc_lower := false)
             """)
  end

  test "decoding range value with lower bound and with upper bound", %{client: client} do
    value = EdgeDB.Range.new(1, 11)

    assert ^value =
             EdgeDB.query_required_single!(client, """
               select range(1, 10, inc_upper := true)
             """)
  end

  test "decoding range value without lower bound and with upper bound", %{client: client} do
    value = EdgeDB.Range.new(2, 11)

    assert ^value =
             EdgeDB.query_required_single!(client, """
               select range(1, 10, inc_lower := false, inc_upper := true)
             """)
  end

  test "decoding float range value without lower bound and with upper bound", %{client: client} do
    value = EdgeDB.Range.new(1.1, 3.3, inc_lower: false, inc_upper: true)

    assert ^value =
             EdgeDB.query_required_single!(client, """
               select range(1.1, 3.3, inc_lower := false, inc_upper := true)
             """)
  end

  test "decoding range value with empty range", %{client: client} do
    value = EdgeDB.Range.empty()
    assert ^value = EdgeDB.query_required_single!(client, "select range(1, 1)")
  end

  for {type, values} <- @input_ranges do
    for value <- values do
      {input, output} =
        case value do
          {input, output} ->
            {input, output}

          value ->
            {value, value}
        end

      test "encoding #{inspect(input)} as #{inspect(type)} with expecting #{inspect(output)} as the result",
           %{client: client} do
        type = unquote(type)
        input = unquote(Macro.escape(input))
        output = unquote(Macro.escape(output))
        assert ^output = EdgeDB.query_single!(client, "select <#{type}>$0", [input])
      end
    end
  end
end
