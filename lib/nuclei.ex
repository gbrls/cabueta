require Logger

defmodule Nuclei do
  @behaviour Tool

  @severity [info: "🔵", low: "🟢", medium: "🟡", high: "🟠", critical: "🔴"]

  def to_markdown(findings) do
    n = length(findings)

    body =
      findings
      |> Enum.map(fn x ->
        title = "#{@severity[x.severity]} #{x.name}"

        if Map.has_key?(x, :description) do
          Markdown.list(title, [x.description])
        else
          "- #{title}\n"
        end
      end)
      |> Enum.join("\n")
      |> dbg

    Markdown.toggle_stats("Web Application Active Scan", n, body)
  end

  def read_finding(%{
        "info" => %{"name" => name, "severity" => severity, "description" => description}
      }) do
    %{name: name, severity: String.to_atom(severity), description: description}
  end

  def read_finding(%{"info" => %{"name" => name, "severity" => severity}}) do
    %{name: name, severity: String.to_atom(severity)}
  end

  def process_report(report) do
    report
    |> Main.read_json_file()
    |> then(fn %{json: data} -> Enum.map(data, &read_finding/1) end)
    |> Enum.sort_by(& &1["severity"])
    |> Enum.uniq()

    # |> dbg
  end

  def test_report() do
    ["./example-reports/nuclei-report.json"]
  end

  def id() do
    :nuclei
  end
end
