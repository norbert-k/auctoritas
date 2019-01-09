defmodule AuctoritasTest.ConfigTest do
  use ExUnit.Case, async: true

  alias Auctoritas.Config

  alias Auctoritas.AuthenticationManager.DataStorage
  alias Auctoritas.AuthenticationManager.TokenManager

  defmodule DummyDataStorage do
  end

  defmodule DummyTokenManager do
  end

  test "generate default config" do
    assert Config.new() == %Config{
             name: "auctoritas_default",
             data_storage: DataStorage,
             token_manager: TokenManager
           }
  end

  test "generate config with custom parameters" do
    config_with_custom_name = Config.new(name: "custom_name")
    config_with_custom_data_storage = Config.new(data_storage: DummyDataStorage)
    config_with_custom_token_manager = Config.new(token_manager: DummyTokenManager)

    assert config_with_custom_name == %Config{
             name: "custom_name",
             data_storage: DataStorage,
             token_manager: TokenManager
           }

    assert config_with_custom_data_storage == %Config{
             name: "auctoritas_default",
             data_storage: DummyDataStorage,
             token_manager: TokenManager
           }

    assert config_with_custom_token_manager == %Config{
             name: "auctoritas_default",
             data_storage: DataStorage,
             token_manager: DummyTokenManager
           }
  end

  test "read config from test.exs config file" do
    assert Config.read() == %Config{
             name: "test_name",
             data_storage: DataStorage,
             token_manager: TokenManager
           }
  end
end
