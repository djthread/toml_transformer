defmodule TomlTransformer do
  @moduledoc """
  Builds a Toml.Transform module
  """

  defmacro __using__(app_env_var: app_env_var) do
    quote do
      use Toml.Transform

      @doc "Apply custom config filters"
      def transform(key, val) do
        TomlTransformer.transform(unquote(app_env_var), key, val)
      end
    end
  end

  @doc "Apply custom config filters"
  def transform(app_env_var, _key, config) when is_map(config) do
    app_env_var
    |> System.get_env()
    |> overrides_and_listify(config)
    |> remove_extra_stuff()
  end

  def transform(_, _key, str) when is_binary(str) do
    resolve_sys_env_vars(str)
  end

  def transform(_, _k, val) do
    val
  end

  # Hoist up the env-specific configs based on the env var
  defp overrides_and_listify("test", %{:__test__ => overrides} = config),
    do: config |> Enum.into([]) |> Keyword.merge(overrides)

  defp overrides_and_listify("beta", %{:__beta__ => overrides} = config),
    do: config |> Enum.into([]) |> Keyword.merge(overrides)

  defp overrides_and_listify("prod", %{:__prod__ => overrides} = config),
    do: config |> Enum.into([]) |> Keyword.merge(overrides)

  defp overrides_and_listify(_, config),
    do: config |> Enum.into([])

  # Remove the env-specific configs after they've been used
  defp remove_extra_stuff(config) when is_list(config),
    do:
      config
      |> Keyword.delete(:__beta__)
      |> Keyword.delete(:__prod__)
      |> Keyword.delete(:__test__)

  defp remove_extra_stuff(config), do: config

  # Convert "${VAR_NAME}" to the value of the so-called system environment var
  defp resolve_sys_env_vars(str) do
    Regex.replace(~r/\${(?:([A-Z0-9_]+)(.*))}/, str, fn _, v, filter_opts ->
      filters = ~r/\s*\|\s*/ |> Regex.split(filter_opts) |> tl()
      filter(System.get_env(v) || "", filters)
    end)
  end

  # defp filter(value, ["int" | tail]) do
  #   case Integer.parse(value) do
  #     {int, ""} -> filter(int, tail)
  #     _ -> filter(0, tail)
  #   end
  # end

  defp filter(value, ["default:" <> default | tail]) do
    val = if value == "", do: String.trim(default), else: value
    filter(val, tail)
  end

  defp filter(value, []), do: value
end
