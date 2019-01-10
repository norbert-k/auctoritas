defmodule AuctoritasTest.DataStorageTest do
  use ExUnit.Case

  alias Auctoritas.AuthenticationManager.DataStorage
  alias Auctoritas.AuthenticationSupervisor
  alias Auctoritas.Config

  @config Config.read()
  @default_supervisor AuthenticationSupervisor.start_link(@config)

  test "insert data into data_storage" do
    assert DataStorage.insert_token("sample_token", "sample_data") == {:ok, true}
    assert DataStorage.get_token_data("sample_token") == {:ok, "sample_data"}
    assert DataStorage.get_tokens(0, 1) == {:ok, ["sample_token"]}
  end
end
