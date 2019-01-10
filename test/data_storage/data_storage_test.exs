defmodule AuctoritasTest.DataStorageTest do
  use ExUnit.Case

  alias Auctoritas.AuthenticationManager.DataStorage
  alias Auctoritas.AuthenticationSupervisor
  alias Auctoritas.Config

  @config Config.read()
  @default_supervisor AuthenticationSupervisor.start_link(@config)
  @default_name "auctoritas_default"

  test "insert data into data_storage" do
    assert DataStorage.insert_token(@default_name, "sample_token", "sample_data") == {:ok, true}
    assert DataStorage.get_token_data(@default_name, "sample_token") == {:ok, "sample_data"}
    assert DataStorage.get_tokens(@default_name, 0, 1) == {:ok, ["sample_token"]}
  end
end
