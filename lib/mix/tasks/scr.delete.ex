defmodule Mix.Tasks.Scr.Delete do
  @moduledoc """
  Removes an existing secret in specified environment and under specified
  name.

  It uses configuration of current application to retrieve keys and
  so on.

  ## Usage
      mix scr.delete prod database_url
  """

  @shortdoc "Delete an existing secret"

  use Mix.Task

  alias SecretVault.{CLI, Config}

  @impl true
  def run(args)

  def run([environment, name | rest]) do
    otp_app = Mix.Project.config()[:app]
    prefix = CLI.find_option(rest, "p", "prefix") || "default"

    config_opts =
      Config.available_options()
      |> Enum.map(&{&1, CLI.find_option(rest, nil, "#{&1}")})
      |> Enum.reject(fn {_, value} -> is_nil(value) end)

    with {:ok, config} <-
           Config.fetch_from_env(otp_app, environment, prefix, config_opts),
         :ok <- ensure_secret_exists(config, name) do
      SecretVault.delete(config, name)
    else
      {:error, :secret_does_not_exist} ->
        Mix.shell().error("Secret with name #{name} does not exist")

      {:error, {:no_configuration_for_prefix, prefix}} ->
        message = "No configuration for prefix #{inspect(prefix)} found"
        Mix.shell().error(message)

      {:error, {:no_configuration_for_app, otp_app}} ->
        Mix.shell().error("No configuration for otp_app #{otp_app} found")
    end
  end

  def run(_args) do
    msg = "Invalid number of arguments. Use `mix help scr.delete`."
    Mix.shell().error(msg)
  end

  defp ensure_secret_exists(config, name) do
    if SecretVault.exists?(config, name) do
      :ok
    else
      {:error, :secret_does_not_exist}
    end
  end
end
