defmodule EdgeDB.RelativeDuration do
  @moduledoc """
  An immutable value represeting an EdgeDB `cal::relative_duration` value.

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> EdgeDB.query_required_single!(pid, "select <cal::relative_duration>'45.6 seconds'")
  #EdgeDB.RelativeDuration<"PT45.6S">
  ```
  """

  defstruct months: 0,
            days: 0,
            microseconds: 0

  @typedoc """
  An immutable value represeting an EdgeDB `cal::relative_duration` value.

  Fields:

    * `:months` - number of months.
    * `:days` - number of days.
    * `:microseconds` - number of microseconds.
  """
  @type t() :: %__MODULE__{
          months: pos_integer(),
          days: pos_integer(),
          microseconds: pos_integer()
        }
end

defimpl Inspect, for: EdgeDB.RelativeDuration do
  import Inspect.Algebra

  @months_per_year 12
  @usecs_per_hour 3_600_000_000
  @usecs_per_minute 60_000_000
  @usecs_per_sec 1_000_000

  @impl Inspect
  def inspect(%EdgeDB.RelativeDuration{months: 0, days: 0, microseconds: 0}, _opts) do
    concat(["#EdgeDB.RelativeDuration<\"", "PT0S", "\">"])
  end

  @impl Inspect
  def inspect(%EdgeDB.RelativeDuration{} = duration, _opts) do
    duration_repr =
      "P"
      |> format_date(duration)
      |> format_time(duration)

    concat(["#EdgeDB.RelativeDuration<\"", duration_repr, "\">"])
  end

  defp format_date(formatted_repr, %EdgeDB.RelativeDuration{} = duration) do
    formatted_repr
    |> maybe_add_time_part(div(duration.months, @months_per_year), "Y")
    |> maybe_add_time_part(rem(duration.months, @months_per_year), "M")
    |> maybe_add_time_part(duration.days, "D")
  end

  defp format_time(formatted_repr, %EdgeDB.RelativeDuration{microseconds: 0}) do
    formatted_repr
  end

  defp format_time(formatted_repr, %EdgeDB.RelativeDuration{microseconds: time}) do
    formatted_repr = "#{formatted_repr}T"

    tfrac = div(time, @usecs_per_hour)
    time = time - tfrac * @usecs_per_hour
    hour = tfrac

    tfrac = div(time, @usecs_per_minute)
    time = time - tfrac * @usecs_per_minute
    min = tfrac

    formatted_repr =
      formatted_repr
      |> maybe_add_time_part(hour, "H")
      |> maybe_add_time_part(min, "M")

    sec = div(time, @usecs_per_sec)
    fsec = time - sec * @usecs_per_sec

    sign =
      if min < 0 or fsec < 0 do
        "-"
      else
        ""
      end

    if sec != 0 or fsec != 0 do
      formatted_repr = "#{formatted_repr}#{sign}#{abs(sec)}"

      formatted_repr =
        if fsec != 0 do
          fsec = String.trim_trailing("#{abs(fsec)}", "0")
          "#{formatted_repr}.#{fsec}"
        else
          formatted_repr
        end

      "#{formatted_repr}S"
    else
      formatted_repr
    end
  end

  defp maybe_add_time_part(formatted_repr, 0, _letter) do
    formatted_repr
  end

  defp maybe_add_time_part(formatted_repr, value, letter) do
    "#{formatted_repr}#{value}#{letter}"
  end
end
