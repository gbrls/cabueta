defmodule Cabueta.Config do
  defstruct [:dast, :dast_url, :upload_url, upload_logs: false, output_path: "."]
end
