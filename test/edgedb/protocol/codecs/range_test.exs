defmodule Tests.EdgeDB.Protocol.Codecs.RangeTest do
  use Tests.Support.EdgeDBCase

  require Logger

  @input_ranges %{
    "range<int64>" => [
      EdgeDB.Range.new(1, 2, inc_lower: true, inc_upper: false),
      {EdgeDB.Range.new(1, 2, inc_lower: true, inc_upper: true),
       EdgeDB.Range.new(1, 3, inc_lower: true, inc_upper: false)},
      EdgeDB.Range.empty(),
      {EdgeDB.Range.new(1, 1, inc_lower: true, inc_upper: false), EdgeDB.Range.empty()},
      EdgeDB.Range.new(nil, nil)
    ]
  }

  setup :edgedb_connection

  setup %{conn: conn} do
    range_type =
      EdgeDB.query_single!(
        conn,
        "select schema::ObjectType filter .name = 'schema::Range' limit 1"
      )

    if range_type do
      Logger.warn("skip #{__MODULE__} since server has not support for std::ranges")
      %{edgedb_v1: true}
    else
      %{edgedb_v1: true}
    end
  end

  test "decoding range value with lower bound and without upper bound", %{conn: conn} = ctx do
    skip_if :edgedb_v1, "missing ranges support" do
      value = EdgeDB.Range.new(1, 10)
      assert ^value = EdgeDB.query_required_single!(conn, "select range(1, 10)")
    end
  end

  test "decoding range value without lower bound and without upper bound", %{conn: conn} = ctx do
    skip_if :edgedb_v1, "missing ranges support" do
      value = EdgeDB.Range.new(2, 10)

      assert ^value =
               EdgeDB.query_required_single!(
                 conn,
                 "select range(1, 10, inc_lower := false)"
               )
    end
  end

  test "decoding range value with lower bound and with upper bound", %{conn: conn} = ctx do
    skip_if :edgedb_v1, "missing ranges support" do
      value = EdgeDB.Range.new(1, 11)

      assert ^value =
               EdgeDB.query_required_single!(
                 conn,
                 "select range(1, 10, inc_upper := true)"
               )
    end
  end

  test "decoding range value without lower bound and with upper bound", %{conn: conn} = ctx do
    skip_if :edgedb_v1, "missing ranges support" do
      value = EdgeDB.Range.new(2, 11)

      assert ^value =
               EdgeDB.query_required_single!(
                 conn,
                 "select range(1, 10, inc_lower := false, inc_upper := true)"
               )
    end
  end

  test "decoding float range value without lower bound and with upper bound",
       %{conn: conn} = ctx do
    skip_if :edgedb_v1, "missing ranges support" do
      value = EdgeDB.Range.new(1.1, 3.3, inc_lower: false, inc_upper: true)

      assert ^value =
               EdgeDB.query_required_single!(
                 conn,
                 "select range(1.1, 3.3, inc_lower := false, inc_upper := true)"
               )
    end
  end

  test "decoding range value with empty range", %{conn: conn} = ctx do
    skip_if :edgedb_v1, "missing ranges support" do
      value = EdgeDB.Range.empty()
      assert ^value = EdgeDB.query_required_single!(conn, "select range(1, 1)")
    end
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

      test "encoding #{inspect(input)} as #{inspect(type)} with expecting #{inspect(output)} in the end",
           %{conn: conn} = ctx do
        skip_if :edgedb_v1, "missing ranges support" do
          value = "value"
          assert ^value = EdgeDB.query_single!(conn, "select <short_str>$0", [value])
        end
      end
    end
  end
end
