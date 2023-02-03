require Logger

defmodule Mix.Tasks.Cabueta do
  @moduledoc """
  Runs cabueta to distill json reports to markdown
  """
  use Mix.Task

  def run(args) do
    in_files = args |> Enum.filter(fn x -> !String.starts_with?(x, "-") end)

    {parsed, _args, _invalid} = OptionParser.parse(args, strict: [json: :boolean])

    if length(in_files) == 0 do
      IO.puts("No files given!")
      Main.test_tools()
    end

    reports =
      in_files
      |> Enum.map(&Main.read_report(&1))
      |> Enum.filter(&(!is_nil(&1)))
      |> Main.assemble()

    # JSON file to store in DB
    Main.store_report(reports)

    if parsed[:json]  do
      IO.puts(reports |> Main.json_report())
    else
      IO.puts(reports.markdown)
    end

    # The cabueta's report itself
  end
end

defmodule Tool do
  @doc """
  Operations common to processing reports from tools.

  In the future we want to generate github actions steps from these tools.
  We'll also need:
    - jq commands to process the json
    - the parameterized command to run the tool
  """
  @callback to_markdown([Map.t()]) :: String.t()
  @callback process_report(String.t()) :: [Map.t()]
  @callback test_report() :: String.t()
  @callback id() :: Atom.t()
  @callback command(Cabueta.Config.t()) :: String.t()
end

defmodule Markdown do
  def list(title, list, depth \\ 0) do
    sep0 = String.duplicate("\t", depth)
    sep1 = String.duplicate("\t", depth + 1)

    first = ~s(#{sep0}- #{title})

    lines = list |> Enum.map(fn x -> ~s(#{sep1}- #{x}) end)

    [first | lines] |> Enum.join("\n")
  end

  def list0(list, depth \\ 0) do
    sep1 = String.duplicate("\t", depth + 1)

    list |> Enum.map(fn x -> ~s(#{sep1}- #{x}) end) |> Enum.join("\n")
  end

  def toggle(description, body) do
    "<details>\n<summary><b> #{description} </b></summary>\n\n#{body}\n\n</details>"
  end

  def toggle_stats(description, n, body) do
    something = ":heavy_exclamation_mark: #{n}"
    nothing = ":white_check_mark: Nothing found in "

    if n > 0 do
      "<details>\n<summary><b> #{something} #{description} </b></summary>\n\n#{body}\n\n</details>"
    else
      "\n#### #{nothing} #{description}\n\n"
    end
  end

  def file_reflink(path, line) do
    "[#{path}:#{line}](#{Main.repo_url()}/#{path}#L#{line})"
  end
end

defmodule Main do
  @tools [Semgrep, DepCheck, Gitleaks, Semgrep, Nuclei, OsvScanner]

  @header_text "## 🪬 Cabueta's Report"

  @goal_text "This workflow's goal is to look for vulnerabilities in the source
  code and in the running web application, and then display it's findings."

  @status_text "**Disclaimer**: 403 status codes discloses useful information
  to potential attackers. The server software section was built only with
  information available to external agents."
  def status_text, do: @status_text

  @sast_text "The first set of scans will search the source code for credentials and potential dangerous practices."

  @dast_text "The second set of scans will test the running application in the URL that was provided."

  def repo_url() do
    base_url = System.get_env("GITHUB_SERVER_URL", "")
    repo = System.get_env("GITHUB_REPOSITORY", "")
    branch = System.get_env("GITHUB_REF", "main")

    "#{base_url}/#{repo}/blob/#{branch}"
  end

  def test_tools() do
    _reports =
      Enum.map(@tools, fn tool ->
        # Logger.info("Testing #{tool}")
        tool.test_report()
      end)
      |> List.flatten()
      # |> dbg
      |> Enum.map(&read_report(&1))
      |> Enum.filter(&(!is_nil(&1)))
      |> assemble

    # |> dbg()

    # IO.puts(reports.markdown)
  end

  def read_json_file(file) do
    safe_read = fn x ->
      case File.read(x) do
        {:ok, data} -> data
        _ -> "{}"
      end
    end

    # Logger.info("Decoding #{file}")

    %{
      path: file,
      json:
        safe_read.(file)
        |> Jason.decode()
        |> then(fn
          {:ok, data} -> data
          _err -> nil
        end)
    }
  end

  def get_module(file) do
    module =
      cond do
        String.contains?(file, "semgrep") ->
          Semgrep

        String.contains?(file, "gitleaks") ->
          Gitleaks

        String.contains?(file, "nuclei") ->
          Nuclei

        String.contains?(file, "osv-scan") ->
          OsvScanner

        true ->
          nil
      end

    case module do
      nil -> {:error, "No tool implemented for #{file}"}
      x -> {:ok, x}
    end
  end

  def read_report(file) do
    case get_module(file) do
      {:ok, mod} ->
        report = mod.process_report(file)
        md = mod.to_markdown(report)

        %{id: mod.id(), markdown: md, report: report}

      {:error, _} ->
        # Logger.info("Ignoring #{file}")
        nil
    end
  end

  def assemble(rep_list) do
    reports = rep_list |> List.foldl(%{}, fn report, acc -> Map.put(acc, report.id, report) end)

    get_md =
      &case get_in(&1, &2) do
        nil -> ""
        x -> x
      end

    pieces = [
      @header_text,
      "> " <> @goal_text,
      @sast_text,
      get_md.(reports, [:osv_scanner, :markdown]),
      get_md.(reports, [:gitleaks, :markdown]),
      get_md.(reports, [:semgrep, :markdown]),
      "\n> " <> @dast_text,
      get_md.(reports, [:nuclei, :markdown])
    ]

    %{
      markdown: pieces |> Enum.join("\n"),
      reports: reports,
      repository: System.get_env("GITHUB_REPOSITORY", ""),
      time: DateTime.utc_now() |> Calendar.strftime("%Y-%m-%d-%H-%M-%S"),
      url: repo_url()
    }
  end

  def serialize_report(_report) do
  end

  def report_id() do
    repo = System.get_env("GITHUB_REPOSITORY", "") |> String.replace("\/", "#")
    branch = System.get_env("GITHUB_REF", "main") |> String.replace("\/", "#")
    time = DateTime.utc_now() |> Calendar.strftime("%Y-%m-%d-%H-%M-%S")

    "#{repo}@#{branch}@#{time}-cabueta-report-v0.json"
    "#{repo}@#{branch}@#{time}-cabueta-report-v0.json"
  end

  def json_report(report) do
    # TODO: Recursively remove markdown
    report |> Map.delete(:markdown) |> Jason.encode!()
  end

  def store_report(report) do
    data = report |> json_report()

    case Main.report_id() |> File.open([:write]) do
      {:ok, file} ->
        IO.binwrite(file, data)
        File.close(file)

      {:error, _err} ->
        {}
    end
  end
end
