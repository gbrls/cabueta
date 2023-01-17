defmodule Mix.Tasks.Workflow do
  @moduledoc """
  This module builds a yaml github workflow file to be used by github actions
  """

  use Mix.Task

  def run(args) do
    args |> IO.inspect()
  end
end
