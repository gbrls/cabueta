defmodule DepCheck do
  @behaviour Tool

  def read_reports(reports) do
    reports |> Main.read_json_file()
  end

  def format_report(%{json: report}) do
    ids =
      report
      |> Enum.map(fn x -> Map.get(x, "vulnerableSoftware") end)
      |> Enum.filter(fn x -> x != nil end)
      |> Enum.flat_map(fn x -> x |> Enum.map(fn %{"software" => %{"id" => id}} -> id end) end)

    description = report |> Enum.map(fn x -> Map.get(x, "description") end)

    # Enum.zip(ids, description)
    Enum.zip_with([ids, description], & &1)
  end

  def to_markdown(reports) do

    details =
      reports
      |> Enum.map(fn [id, desc] -> Markdown.list("Software: `#{id}`", [desc]) end)
      |> Enum.join("\n")

    Markdown.toggle_stats("Vulnerable Dependencies", length(reports), details)
  end

  def process_report(report) do
    report
    |> Main.read_json_file()
    |> format_report()
  end

  def test_report() do
    ["./example-reports/dependency-check-report.json"]
  end

  def id do
    :dependency_check
  end
end
