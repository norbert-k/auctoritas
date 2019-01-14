defmodule AuctoritasTest.ConfigTest do
  use ExUnit.Case, async: true
  doctest Auctoritas.Config

  alias Auctoritas.Config

  test "generate default config" do
    assert Config.new() == %Config{
             name: "auctoritas_default",
             data_storage: Auctoritas.AuthenticationManager.CachexDataStorage,
             token_manager: Auctoritas.AuthenticationManager.DefaultTokenManager,
             token_type: :sliding,
             expiration: 60 * 60 * 24, # 1 day
             refresh_token_expiration: 60 * 60 * 24 * 3 # 3 days
           }
  end

  test "generate config with custom parameter" do
    config_with_custom_name = Config.new(name: "custom_name")

    assert config_with_custom_name == %Config{
             name: "custom_name",
             data_storage: Auctoritas.AuthenticationManager.CachexDataStorage,
             token_manager: Auctoritas.AuthenticationManager.DefaultTokenManager,
             token_type: :sliding,
             expiration: 60 * 60 * 24, # 1 day
             refresh_token_expiration: 60 * 60 * 24 * 3 # 3 days
           }
  end
end
