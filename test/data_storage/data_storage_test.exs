defmodule AuctoritasTest.DataStorageTest do
  use ExUnit.Case

  alias Auctoritas.AuthenticationManager.DataStorage
  alias Auctoritas.AuthenticationManager.DataStorage.Data
  alias Auctoritas.AuthenticationSupervisor
  alias Auctoritas.Config

  @config Config.read()
  @default_supervisor AuthenticationSupervisor.start_link(@config)
  @default_name "auctoritas_default"
  @default_expiration 8000

  test "insert data into data_storage" do
    assert DataStorage.insert_token(@default_name, @default_expiration, "sample_token", %{sample: "data"}, %{sample: "metadata"}) == {:ok, true}
    {:ok, token_data} = DataStorage.get_token_data(@default_name, "sample_token")
    assert token_data.data == %{sample: "data"}
    assert token_data.metadata.sample == "metadata"
    assert DataStorage.get_tokens(@default_name, 0, 1) == {:ok, ["sample_token"]}
  end
end
