defmodule Uadebate.ICal do
  @moduledoc "The public calendar as an iCalendar feed (RFC 5545), all-day events."

  alias Uadebate.Events.Event

  def feed(events, host) do
    lines =
      ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//uadebate//calendar//EN", "CALSCALE:GREGORIAN"] ++
        Enum.flat_map(events, &event(&1, host)) ++ ["END:VCALENDAR"]

    Enum.map_join(lines, "", &(fold(&1) <> "\r\n"))
  end

  defp event(%Event{} = e, host) do
    last = e.ends_on || e.starts_on

    [
      "BEGIN:VEVENT",
      "UID:event-#{e.id}@#{host}",
      "DTSTAMP:" <> stamp(e.updated_at),
      "DTSTART;VALUE=DATE:" <> day(e.starts_on),
      "DTEND;VALUE=DATE:" <> day(Date.add(last, 1)),
      "SUMMARY:" <> escape(e.title)
    ] ++
      if(e.city, do: ["LOCATION:" <> escape(e.city)], else: []) ++
      if(e.details, do: ["DESCRIPTION:" <> escape(e.details)], else: []) ++
      if(e.link, do: ["URL:" <> e.link], else: []) ++ ["END:VEVENT"]
  end

  defp day(date), do: Calendar.strftime(date, "%Y%m%d")

  defp stamp(nil), do: stamp(DateTime.utc_now())
  defp stamp(at), do: Calendar.strftime(at, "%Y%m%dT%H%M%SZ")

  defp escape(text) do
    text
    |> String.replace("\\", "\\\\")
    |> String.replace(";", "\;")
    |> String.replace(",", "\\,")
    |> String.replace(~r/\r?\n/, "\\n")
  end

  # lines longer than 75 octets continue on the next line after a space
  defp fold(line) when byte_size(line) <= 75, do: line

  defp fold(line) do
    {head, rest} = split_at_octets(line, 75)
    head <> "\r\n " <> fold(rest)
  end

  defp split_at_octets(line, n) do
    chars = String.graphemes(line)

    {head, rest, _} =
      Enum.reduce(chars, {"", "", 0}, fn ch, {h, r, size} ->
        if r == "" and size + byte_size(ch) <= n,
          do: {h <> ch, r, size + byte_size(ch)},
          else: {h, r <> ch, size}
      end)

    {head, rest}
  end
end
