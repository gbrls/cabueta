defmodule Mix.Tasks.RunTools do
  use Mix.Task

  def run(args) do
    cfgfile = args |> Enum.at(0)
    IO.inspect(cfgfile)

    RunLocal.available_tools(cfgfile) |> IO.inspect()
  end
end

defmodule RunLocal do
  require Logger

  def in_path?(str) do
    {path, _b} = System.cmd("which", [str], stderr_to_stdout: true)

    String.length(path) > 0
  end

  def available_tools(cfgfile) do
    cfg =
      case config_from_yml(cfgfile) do
        %Cabueta.Config{} = x -> x
        _any -> %Cabueta.Config{dast: true}
      end

    IO.inspect(cfg)

    programs = enabled_modules(cfg) |> Enum.map(fn mod -> mod.command(cfg) end)

    programs
    |> Enum.map(fn t ->
      IO.puts("#{t}...#{in_path?(t)}")
      {t, in_path?(t)}
    end)
  end

  def enabled_modules(%Cabueta.Config{} = cfg) do
    default = [Semgrep, Gitleaks, OsvScanner]

    if cfg.dast do
      [Nuclei | default]
    else
      default
    end
  end

  def config_from_yml(p) do
    mp =
      case YamlElixir.read_all_from_file(p) do
        {:ok, mp} ->
          mp |> parse_config |> IO.inspect()

        err ->
          Logger.error("Error reading yaml #{err}")
          nil
      end

    case mp do
      nil ->
        %Cabueta.Config{}

      mp ->
        keys = [
          {"dast-check", :dast},
          {"target-url", :dast_url},
          {"upload-url", :upload_url},
          {"upload-logs", :upload_logs},
          {"output-path", :output_path},
        ]

        base_cfg = %Cabueta.Config{}

        Enum.reduce(keys, base_cfg, fn {str, k}, acc ->
          if Map.has_key?(mp, str) do
            Map.put(acc, k, Map.get(mp, str))
          else
            acc
          end
        end)
    end
  end

  defp parse_config(x) do
    cond do
      is_map(x) ->
        if Map.has_key?(x, "uses") and
             x |> Map.get("uses") |> String.contains?("/cabueta/.github/workflows/cabueta.yml") do
          x |> Map.get("with")
        else
          x |> Enum.map(fn {_k, v} -> parse_config(v) end) |> Enum.find(&(!is_nil(&1)))
        end

      is_list(x) ->
        x |> Enum.map(&parse_config/1) |> Enum.find(&(!is_nil(&1)))

      true ->
        nil
    end
  end
end
