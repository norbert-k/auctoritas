defmodule AuctoritasTest.ConfigTest do
  use ExUnit.Case, async: true
  doctest Auctoritas

  alias Auctoritas.Config

  alias Auctoritas.AuthenticationManager.DataStorage
  alias Auctoritas.AuthenticationManager.TokenManager

  defmodule DummyDataStorage do
  end

  defmodule DummyTokenManager do
  end

  @default_secret_key "super_secret_key"

  test "generate default config" do
    assert Config.new(secret_key:  @default_secret_key) == %Config{name: "auctoritas_default", secret_key: @default_secret_key, data_storage: DataStorage, token_manager: TokenManager}
  end

  test "generate config with custom parameters" do
    config_with_custom_name = Config.new(name: "custom_name", secret_key: @default_secret_key)
    config_with_custom_data_storage = Config.new(secret_key: @default_secret_key, data_storage: DummyDataStorage)
    config_with_custom_token_manager = Config.new(secret_key: @default_secret_key, token_manager: DummyTokenManager)

    assert config_with_custom_name == %Config{name: "custom_name", secret_key: @default_secret_key, data_storage: DataStorage, token_manager: TokenManager}
    assert config_with_custom_data_storage == %Config{name: "auctoritas_default", secret_key: @default_secret_key, data_storage: DummyDataStorage, token_manager: TokenManager}
    assert config_with_custom_token_manager == %Config{name: "auctoritas_default", secret_key: @default_secret_key, data_storage: DataStorage, token_manager: DummyTokenManager}
  end

  test "generate config with invalid parameters" do

  end
end