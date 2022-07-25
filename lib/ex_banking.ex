defmodule ExBanking do
  @moduledoc """
    This module handles ExBanking callbacks and client functions
  """

  use GenServer

  alias ExBanking.Bank
  alias ExBanking.Throttler
  alias ExBanking.Constants

  @table_name Constants.table_name
  @throttle_table_name Constants.throttle_table_name


  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @spec create_user(user :: String.t) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    GenServer.call(__MODULE__, {:create_account, user})
  end

  @spec deposit(user :: String.t, amount :: number, currency :: String.t) :: 
  {:ok, new_balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency) do
    GenServer.call(__MODULE__, {:deposit, user, amount, currency})
  end

  @spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: 
  {:ok, new_balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :not_enough_money | :too_many_requests_to_user}
  def withdraw(user, amount, currency) do
    GenServer.call(__MODULE__, {:withdraw, user, amount, currency})
  end

  @spec get_balance(user :: String.t, currency :: String.t) :: 
  {:ok, balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) do
    GenServer.call(__MODULE__, {:get_balance, user, currency})
  end

  @spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) :: 
  {:ok, from_user_balance :: number, to_user_balance :: number} | {:error, :wrong_arguments | :not_enough_money | 
  :sender_does_not_exist | :receiver_does_not_exist | :too_many_requests_to_sender | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency) do
    GenServer.call(__MODULE__, {:transfer, from_user, to_user, amount, currency})
  end



  # Server
 
  def init(state) do
    :ets.new(@table_name, [:set, :public, :named_table])
    :ets.new(@throttle_table_name, [:set, :public, :named_table])
    {:ok, state}
  end

  def handle_call({:create_account, name}, from, state) do
    spawn_link(fn ->
      response = Bank.create_account(name)
      Throttler.decrease_counter(name)
      case response do
        :ok ->
          GenServer.reply(from, :ok)
        _ ->
          GenServer.reply(from, response)
      end
    end)

    {:noreply, state}
  end

  def handle_call({:deposit, name, amount, currency}, from, state) do
    case Throttler.is_throttled(name) do
      :yes ->
        {:reply, {:error, :too_many_requests_to_user}, state}
      :no ->
        Throttler.increment_counter(name)
        spawn_link(fn ->
          response = Bank.deposit(name, amount, currency)
          Throttler.decrease_counter(name)
          case response do
            {:ok, cur_bal} ->
              GenServer.reply(from, {:ok, cur_bal})
            _ ->
              GenServer.reply(from, response)
          end
        end)

        {:noreply, state}
    end
  end

  def handle_call({:withdraw, name, amount, currency}, from, state) do
    case Throttler.is_throttled(name) do
      :yes ->
        {:reply, {:error, :too_many_requests_to_user}, state}
      :no ->
        Throttler.increment_counter(name)
        spawn_link(fn ->
          response = Bank.withdraw(name, amount, currency)
          Throttler.decrease_counter(name)
          case response do
            {:ok, new_balance} ->
              GenServer.reply(from, {:ok, new_balance})
            _ ->
              GenServer.reply(from, response)
          end
        end)

        {:noreply, state}
    end
  end

  def handle_call({:get_balance, name, currency}, from, state) do
    case Throttler.is_throttled(name) do
      :yes ->
        {:reply, {:error, :too_many_requests_to_user}, state}
      :no ->
        Throttler.increment_counter(name)
        spawn_link(fn ->
          response = Bank.get_balance(name, currency)
          Throttler.decrease_counter(name)
          case response do
            {:ok, cur_bal} ->
              GenServer.reply(from, {:ok, cur_bal})
            _ ->
              GenServer.reply(from, response)
          end
        end)

        {:noreply, state}
    end
  end

  def handle_call({:transfer, from_name, to_name, amount, currency}, from, state) do
    case Throttler.is_throttled(from_name) do
      :yes ->
        {:reply, {:error, :too_many_requests_to_sender}, state}
      :no ->
        case Throttler.is_throttled(to_name) do
          :yes ->
            {:reply, {:error, :too_many_requests_to_receiver}, state}
          :no ->
            Throttler.increment_counter(from_name)
            Throttler.increment_counter(to_name)
            spawn_link(fn ->
              response = Bank.transfer(from_name, to_name, currency, amount)
              Throttler.decrease_counter(from_name)
              Throttler.decrease_counter(to_name)
              case response do
                {:ok, from_acc_new_bal, to_acc_new_bal} ->
                  GenServer.reply(from, {:ok, from_acc_new_bal, to_acc_new_bal})
                _ ->
                  GenServer.reply(from, response)
              end
            end)
    
            {:noreply, state}
        end
    end
  end

end
