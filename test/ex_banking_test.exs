defmodule ExBankingTest do
  use ExUnit.Case, async: true
  doctest ExBanking

  import ExBanking

  setup do
    start_supervised!(ExBanking)
    :ok
  end

  test "Create user with correct name" do
    assert create_user("Aruna") == :ok
  end

  test "Create user with invalid name" do
    assert create_user("Aruna1") == {:error, :wrong_arguments}
  end

  test "Create user existing name" do
    create_user("Aruna")
    assert create_user("Aruna") == {:error, :user_already_exists}
  end

  test "Deposit amount to user" do
    create_user("Aruna")
    assert deposit("Aruna", 10.0, "USD") == {:ok, 10.0}
  end

  test "Deposit amount to non existing user" do
    assert deposit("Aruna", 10.0, "USD") == {:error, :user_does_not_exist}
  end

  test "Deposit with wrong arguments" do
    assert deposit("Aruna", "qw", "USD") == {:error, :wrong_arguments}
  end

  test "Withdraw from user" do
    create_user("Aruna")
    deposit("Aruna", 10.0, "USD")
    assert withdraw("Aruna", 5.0, "USD") == {:ok, 5.0}
  end

  test "Withdraw from non existing user" do
    create_user("Aruna")
    deposit("Aruna", 10.0, "USD")
    assert withdraw("Esandu", 5.0, "USD") == {:error, :user_does_not_exist}
  end

  test "Withdraw insufficient amount" do
    create_user("Aruna")
    deposit("Aruna", 10.0, "USD")
    assert withdraw("Aruna", 50.0, "USD") == {:error, :not_enough_money}
  end

  test "Withdraw with wrong arguments" do
    assert deposit("Aruna", "qw", "USD") == {:error, :wrong_arguments}
  end

  test "Check balance" do
    create_user("Aruna")
    deposit("Aruna", 10.0, "USD")
    assert get_balance("Aruna", "USD") == {:ok, 10.0}
  end

  test "Check balance for non existing user" do
    create_user("Aruna")
    deposit("Aruna", 10.0, "USD")
    assert get_balance("Esandu", "USD") == {:error, :user_does_not_exist}
  end

  test "Transfer to an account" do
    create_user("Aruna")
    deposit("Aruna", 20.0, "USD")

    create_user("Esandu")
    deposit("Esandu", 10.0, "USD")

    assert send("Aruna", "Esandu", 10.0, "USD") == {:ok, 10.0, 20.0}
  end

  test "Transfer from non existing sender" do
    create_user("Esandu")
    deposit("Esandu", 10.0, "USD")

    assert send("Aruna", "Esandu", 10.0, "USD") == {:error, :sender_does_not_exist}
  end

  test "Transfer to non existing receiver" do
    create_user("Aruna")
    deposit("Aruna", 20.0, "USD")

    assert send("Aruna", "Esandu", 10.0, "USD") == {:error, :receiver_does_not_exist}
  end

  test "Transfer from insufficient balance account" do
    create_user("Aruna")
    deposit("Aruna", 20.0, "USD")

    create_user("Esandu")
    deposit("Esandu", 10.0, "USD")

    assert send("Aruna", "Esandu", 100.0, "USD") == {:error, :not_enough_money}
  end

  test "Too many deposit requests for user" do
    create_user("Aruna")

    response_list =
    Enum.map(1..20, fn _ -> Task.async(fn -> deposit("Aruna", 100, "USD") end) end)
    |> Enum.map(&Task.await/1)

    assert Enum.member?(response_list, {:error, :too_many_requests_to_user}) == true
  end

  test "Too many withdraw requests for user" do
    create_user("Aruna")
    deposit("Aruna", 20.0, "USD")

    response_list =
    Enum.map(1..20, fn _ -> Task.async(fn -> withdraw("Aruna", 1, "USD") end) end)
    |> Enum.map(&Task.await/1)

    assert Enum.member?(response_list, {:error, :too_many_requests_to_user}) == true
  end

  test "Too many balance requests for user" do
    create_user("Aruna")
    deposit("Aruna", 20.0, "USD")

    response_list =
    Enum.map(1..20, fn _ -> Task.async(fn -> get_balance("Aruna", "USD") end) end)
    |> Enum.map(&Task.await/1)

    assert Enum.member?(response_list, {:error, :too_many_requests_to_user}) == true
  end

  test "Too many requests to sender in transfer" do
    create_user("Aruna")
    deposit("Aruna", 100.0, "USD")

    create_user("Esandu")
    deposit("Esandu", 20.0, "USD")

    response_list =
    Enum.map(1..20, fn _ -> Task.async(fn -> send("Aruna", "Esandu", 1.0, "USD") end) end)
    |> Enum.map(&Task.await/1)

    assert Enum.member?(response_list, {:error, :too_many_requests_to_sender}) == true
  end

  # test "Too many requests to receiver in transfer" do
  #   create_user("Aruna")
  #   deposit("Aruna", 100.0, "USD")

  #   create_user("Esandu")
  #   deposit("Esandu", 20.0, "USD")

  #   response_list =
  #   Enum.map(1..20, fn _ -> Task.async(fn -> send("Aruna", "Esandu", 1.0, "USD") end) end)
  #   |> Enum.map(&Task.await/1)

  #   assert Enum.member?(response_list, {:error, :too_many_requests_to_receiver}) == true
  # end
  
end
