defmodule Gitleaks do
  @behaviour Tool

  def extract_data(%{json: reports}) do
    reports
    |> Enum.map(fn %{"File" => f, "StartLine" => line, "Description" => desc, "Match" => match} ->
      %{file: f, line: line, description: desc, match: match}
    end)
  end

  def ignore_custom_rule(reports) do
    reports
    |> Enum.filter(&(not String.equivalent?(Map.get(&1, :description), "VTEX's Custom Rule 01")))
  end

  def to_markdown(reports) do
    ncreds = length(reports)

    body =
      reports
      |> Enum.map(fn x ->
        Markdown.list("#{Markdown.file_reflink(x.file, x.line)}", [
          "#{x.description}: `#{x.match}`"
        ])
      end)
      |> Enum.join("\n")

    Markdown.toggle_stats("Leaked Credentials", ncreds, body)
  end

  def process_report(report) do
    report
    |> Main.read_json_file()
    |> Gitleaks.extract_data()
    |> Gitleaks.ignore_custom_rule()
  end

  def test_report do
    ["./example-reports/gitleaks-report.json"]
  end

  def id do
    :gitleaks
  end
end
