defmodule Cabueta.Config do
  defstruct [:dast_url, :upload_url, upload_logs: false, output_path: ".", dast: false, base_dir: "."]
end
