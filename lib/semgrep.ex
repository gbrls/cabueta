defmodule Semgrep do
  @behaviour Tool

  @rules %{
    ignore: %{
      check_id: [],
      severity: []
    }
  }

  def rules, do: @rules

  def extract_data(%{:json => contents}) do
    contents["results"]
    |> Enum.map(fn x ->
      case x do
        %{
          "path" => path,
          "start" => %{"line" => start_line},
          "check_id" => check_id,
          "extra" => %{
            "message" => message,
            "severity" => severity
          }
        } ->
          %{
            path: path,
            line: start_line,
            severity: severity,
            check_id: check_id,
            message: message
          }

        _ ->
          {:error, "Didn't match", x} |> IO.inspect()
      end
    end)
  end

  def extract_data(_pass) do
  end

  def filter_rules(report, rules) do
    ans =
      rules
      |> Enum.map(fn {k, v} -> matches_rule(Map.fetch(report, k), v) end)
      |> Enum.any?()

    not ans
  end

  def filter_ignored(reports) do
    reports |> Enum.filter(&Semgrep.filter_rules(&1, Semgrep.rules().ignore))
  end

  def matches_rule({:ok, val}, rule) do
    Enum.member?(rule, val)
  end

  def matches_rule(_any, _rule) do
    false
  end

  def remove_details(reports) do
    reports |> Enum.map(fn {freq, k, _lines} -> {freq, k} end)
  end

  def group_reports(reports) do
    report_key = fn x -> %{severity: x.severity, id: x.check_id, message: x.message} end
    report_value = fn x -> %{path: x.path, line: x.line} end

    reports
    |> Enum.group_by(report_key, report_value)
    |> Enum.map(fn {k, v} -> %{freq: length(v), meta: k, data: v} end)
    |> Enum.sort()
    |> Enum.reverse()
  end

  def to_csv(reports) do
    reports
    |> Enum.map(fn {freq, {type, id, message}} -> [freq, type, id, message] end)
    |> CSV.encode()
    |> Enum.to_list()
  end

  def render_list(title, list, depth \\ 0) do
    sep0 = String.duplicate("\t", depth)
    sep1 = String.duplicate("\t", depth + 1)

    first = ~s(#{sep0}- #{title})

    lines =
      list
      |> Enum.map(fn %{path: path, line: line} ->
        ~s(#{sep1}- #{Markdown.file_reflink(path, line)})
      end)

    [first | lines] |> Enum.join("\n")
  end

  def to_markdown(reports) do
    critical =
      reports
      |> Enum.filter(fn %{freq: _freq, meta: %{severity: severity}, data: _findings} ->
        severity == "ERROR"
      end)

    warnings =
      reports
      |> Enum.filter(fn %{freq: _freq, meta: %{severity: severity}, data: _findings} ->
        severity != "ERROR"
      end)

    call_render = fn %{freq: _freq, meta: %{message: msg}, data: findings} ->
      render_list(msg, findings)
    end

    critical_list = critical |> Enum.map(&call_render.(&1))
    critical_rendered = critical_list |> Enum.join("\n")
    warns_list = warnings |> Enum.map(&call_render.(&1)) |> Enum.join("\n")
    warns_rendered = Markdown.toggle(":raised_eyebrow: Other findings", warns_list)

    Markdown.toggle_stats(
      "Critical Findings",
      length(critical_list),
      critical_rendered <> "\n---\n" <> warns_rendered
    )
  end

  def read_report(report) do
    report
    |> Main.read_json_file()
    |> Semgrep.extract_data()
  end

  def process_report(file) do
    file
    |> read_report()
    |> filter_ignored()
    |> group_reports()
  end

  def test_report() do
    ["./example-reports/semgrep-report.json"]
  end

  def id do
    :semgrep
  end
end
