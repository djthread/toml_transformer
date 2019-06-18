defmodule TestTransformer do
  use TomlTransformer, app_env_var: "FOO_ENV"
end

defmodule TomlTransformerTest do
  @doc """
  Tests the Config Transformer logic.

  Because we depend on environment variables, we'll turn off async and wrap
  our assertions in `&sandbox/1,2,3` which will set environment variables,
  run the given function, and then delete them.
  """
  use ExUnit.Case, async: false

  @fixture """
  [foo]

  chicken = "hmm"
  __test__.chicken = "yummy"
  api_key = "${API_KEY}"
  a_number = 4
  a_dynamic_number = "${SOME_NUMBER | default:4 }"
  a_dynamic_number2 = "${SOME_NUMBER}"
  string_with_default = "${SOME_STRING | default: HELLO}"
  a_truthy_thing = "(bool)true"
  a_falsy_thing = "(bool)false"
  an_atom_thing = "(atom)hello_world"
  """

  test "basic" do
    sandbox(fn conf ->
      assert "hmm" == get_in(conf, [:foo, :chicken])
      assert "" == get_in(conf, [:foo, :api_key])
      assert 4 == get_in(conf, [:foo, :a_number])
      assert "4" == get_in(conf, [:foo, :a_dynamic_number])
      assert "" == get_in(conf, [:foo, :a_dynamic_number2])
      assert "HELLO" == get_in(conf, [:foo, :string_with_default])
    end)
  end

  test "app env var" do
    sandbox(%{"FOO_ENV" => "test"}, fn conf ->
      assert "yummy" == get_in(conf, [:foo, :chicken])
    end)
  end

  test "env var value" do
    sandbox(%{"API_KEY" => "abc123"}, fn conf ->
      assert "abc123" == get_in(conf, [:foo, :api_key])
    end)
  end

  test "env var type coersion" do
    sandbox(%{"SOME_NUMBER" => "8", "SOME_STRING" => "HAHA"}, fn conf ->
      assert "8" == get_in(conf, [:foo, :a_dynamic_number])
      assert "8" == get_in(conf, [:foo, :a_dynamic_number2])
      assert "HAHA" == get_in(conf, [:foo, :string_with_default])
      assert true == get_in(conf, [:foo, :a_truthy_thing])
      assert false == get_in(conf, [:foo, :a_falsy_thing])
      assert :hello_world == get_in(conf, [:foo, :an_atom_thing])
    end)
  end

  defp sandbox(fun) when is_function(fun) do
    sandbox(@fixture, %{}, fun)
  end

  defp sandbox(env_vars, fun) when is_map(env_vars) and is_function(fun) do
    sandbox(@fixture, env_vars, fun)
  end

  defp sandbox(fixture, env_vars, fun)
       when is_binary(fixture) and is_map(env_vars) and is_function(fun) do
    Enum.each(env_vars, fn {k, v} -> System.put_env(k, v) end)
    config = Toml.decode!(fixture, keys: :atoms, transforms: [TestTransformer])
    fun.(config)
    Enum.each(env_vars, fn {k, _v} -> System.delete_env(k) end)
  end
end
