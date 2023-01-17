defmodule Ferox do
  @behaviour Tool

  def read_reports(reports) do
    reports |> Main.read_json_file()
  end

  def group_endpoints(%{json: endpoints}) do
    fn_path = fn %{"path" => p} -> p end

    servers =
      endpoints
      |> Enum.filter(fn mp -> Map.has_key?(mp, "server") end)
      |> Enum.map(fn %{"server" => s} -> s end)
      |> Enum.sort()
      |> Enum.dedup()

    ends =
      endpoints
      |> Enum.group_by(fn_path, fn %{"status" => s} -> s end)
      |> Enum.map(fn {path, slist} -> {path, slist |> Enum.sort() |> Enum.dedup()} end)
      |> Enum.dedup()
      |> Enum.sort_by(fn {path, statuses} -> {statuses, path} end)

    %{endpoints: ends, server_info: servers}
  end

  def to_markdown(%{endpoints: endpoints, server_info: servers}) do
    header = ":unlock: Open paths"

    footer = Main.status_text()

    svmd = Markdown.list0(servers |> Enum.map(fn x -> ~s(`#{x}`) end), -1)
    server_md = ~s(## Server software\n\n#{svmd}\n)

    list =
      endpoints
      |> Enum.map(fn {path, slist} ->
        Markdown.list(
          ~s(`#{path}`),
          slist
          |> Enum.map(fn x -> ~s(`#{x}`) end)
        )
      end)
      |> Enum.join("\n")

    Markdown.toggle(header, "#{list}\n#{server_md}\n\n#{footer}\n")
  end

  def process_report(reports) do
    reports
    |> Main.read_json_file()
    |> group_endpoints()
  end

  def test_report() do
    [
      "./example-reports/feroxbuster-report-new-2.json",
      "./example-reports/-report-new-2.json"
    ]
  end

  def id do
    :feroxbuster
  end
end
