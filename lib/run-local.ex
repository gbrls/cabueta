defmodule Mix.Tasks.RunTools do
  use Mix.Task

  def run(_args) do
    RunLocal.available_tools() |> IO.inspect()
  end
end

defmodule RunLocal do
  def in_path?(str) do
    {path, _b} = System.cmd("which", [str], stderr_to_stdout: true)

    String.length(path) > 0
  end

  def available_tools() do
    programs =
      enabled_modules(%Cabueta.Config{dast: true}) |> Enum.map(fn mod -> mod.command() end)

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
end
