defmodule ExBanking.Bank do
    @moduledoc """
        This module handles all the banking functionalities such as
        account creation, deposit, withdraw, transfer etc..
    """
    
    alias ExBanking.Constants

    # ETS table name to store user data
    @table_name Constants.table_name


    @doc """
    Create new account for the user

    Returns: :ok|{:error, :user_already_exists}|{:error, :wrong_arguments}

    ## Parameters

        - name: string Name of the user

    """
    def create_account(name) do
        case validate_attributes(%{name: name}, :account_create) do
            :ok ->
              account = find_account_by_name(name)
              if account != [] do
                {:error, :user_already_exists}
              else
                :ets.insert(@table_name, {name, %{balance: 0.00}})
                :ok
              end
            _ ->
              {:error, :wrong_arguments}
          end
    end

    @doc """
    Deposit amount to users account

    Returns: {:ok, cur_bal}|{:error, :user_does_not_exist}|{:error, :wrong_arguments}

    ## Parameters

        - name: string Name of the user
        - amount: number Amount to be deposited
        - currency: string Currency type. Ex: USD, AUD

    """
    def deposit(name, amount, currency) do
        case validate_attributes(%{name: name, amount: amount, currency: currency}, :deposit) do
            :ok ->
                account = find_account_by_name(name)
                if account == [] do
                    {:error, :user_does_not_exist}
                else
                    [{name, balance_data}] = account
                    balance = balance_data.balance
                    balance_list = case find_balance(balance, currency) do
                        {:no_existing_balances} ->
                            [%{amount: amount, currency: currency}]
                        {:ok, existing_balance} ->
                            if existing_balance == nil do
                                [%{amount: amount, currency: currency} | balance]
                            else
                                update_balance(balance, currency, amount)
                            end
                    end

                    :ets.insert(@table_name, {name, %{balance: balance_list}})
                    cur_bal = get_cur_balance(balance_list, currency)
    
                    {:ok, cur_bal}
                end
            _ ->
                {:error, :wrong_arguments}
        end
    end

    @doc """
    Withdraw amount from users account

    Returns: {:ok, new_balance}|{:error, :user_does_not_exist}|{:error, :wrong_arguments}

    ## Parameters

        - name: string Name of the user
        - amount: number Amount to be deposited
        - currency: string Currency type. Ex: USD, AUD

    """
    def withdraw(name, amount, currency) do
        case validate_attributes(%{name: name, amount: amount, currency: currency}, :withdraw) do
            :ok ->
                account = find_account_by_name(name)
                if account == [] do
                    {:error, :user_does_not_exist}
                else
                    [{name, balance_data}] = account
                    balance = balance_data.balance
                    cur_bal = get_cur_balance(balance, currency)

                    if cur_bal < amount do
                        {:error, :not_enough_money}
                    else
                        new_balance = cur_bal - amount
                        balance_list = set_balance(balance, new_balance, currency)

                        :ets.insert(@table_name, {name, %{balance: balance_list}})

                        {:ok, new_balance}
                    end
                end
            _ ->
                {:error, :wrong_arguments}
        end
    end

    @doc """
    Transfer funds from one account to another
    This function reuses the existing withdraw and deposit functions

    Returns: {:ok, from_acc_bal, to_acc_bal}|{:error, :sender_does_not_exist}|{:error, :not_enough_money}|
        {:error, :wrong_arguments}|{:error, :receiver_does_not_exist}

    ## Parameters

        - name: string Name of the user
        - amount: number Amount to be deposited
        - currency: string Currency type. Ex: USD, AUD

    """
    def transfer(from_name, to_name, currency, amount) do
        case withdraw(from_name, amount, currency) do
            {:error, :user_does_not_exist} ->
                {:error, :sender_does_not_exist}
            {:error, :not_enough_money} ->
                {:error, :not_enough_money}
            {:error, :wrong_arguments} ->
                {:error, :wrong_arguments}
            {:ok, from_acc_bal} ->
                case deposit(to_name, amount, currency) do
                    {:error, :user_does_not_exist} ->
                        {:error, :receiver_does_not_exist}
                    {:error, :wrong_arguments} ->
                        {:error, :wrong_arguments}
                    {:ok, to_acc_bal} ->
                        {:ok, from_acc_bal, to_acc_bal}
                end
        end
    end

    @doc """
    Retrieve current balance of the user for given currency

    Returns: {:ok, cur_bal, to_acc_bal}|{:error, :sender_does_not_exist}|{:error, :wrong_arguments}

    ## Parameters

        - name: string Name of the user
        - currency: string Currency type. Ex: USD, AUD

    """
    def get_balance(name, currency) do
        case validate_attributes(%{name: name, currency: currency}, :get_balance) do
            :ok ->
                account = find_account_by_name(name)
                if account == [] do
                    {:error, :user_does_not_exist}
                else
                    [{_name, balance_data}] = account
                    balance = balance_data.balance

                    cur_bal = get_cur_balance(balance, currency)

                    {:ok, cur_bal}
                end
            _ ->
                {:error, :wrong_arguments}
        end
    end

    
    # Lookup ETS table for given account name
    # Returns: []|User
    #
    # ## Parameters
    #     - name: string Name of the user
    defp find_account_by_name(name) do
        :ets.lookup(@table_name, name)
    end

    defp update_balance(balance_list, currency, amount) do
        Enum.map(balance_list, fn(balance) -> 
            if balance.currency == currency do 
                Map.put(balance, :amount, balance.amount + amount)
            else 
                balance 
            end 
        end)
    end


    # Find balance for given currency type
    # Returns: {:no_existing_balances}|{:ok, existing_balance}
    #
    # ## Parameters
    #     - balances: list List of balances in user's account
    #     - currency: string Currency type. Ex: USD, AUD
    defp find_balance(balances, currency) do
        if balances == 0.00 do
            {:no_existing_balances}
        else
            existing_balance = Enum.find(balances, fn balance -> balance.currency == currency end)
            {:ok, existing_balance}
        end
    end


    # Find current balance of user's account
    # Returns: balance amount
    #
    # ## Parameters
    #     - balances: list List of balances in user's account
    #     - currency: string Currency type. Ex: USD, AUD
    defp get_cur_balance(balances, currency) do
        if balances == 0.00 do
            0.00
        else
            existing_balance = Enum.find(balances, fn balance -> balance.currency == currency end)
            if existing_balance == nil do
                0.00
            else
                existing_balance.amount
            end
        end
    end

    # Set balance for given currency type in user's currency list
    # Returns: list Updated currency list
    #
    # ## Parameters
    #     - balances: list List of balances in user's account
    #     - currency: string Currency type. Ex: USD, AUD
    #     - amount: number Amount to be set
    defp set_balance(balances, amount, currency) do
        Enum.map(balances, fn(bal) -> 
            if bal.currency == currency do 
              Map.put(bal, :amount, amount)
            else 
              bal 
            end 
        end)
    end


    # Perform input parameter validations for different scenarios
    # Returns: :ok|specific error
    #
    # ## Parameters
    #     - balances: map Attributes set to be validated
    #     - scenario: atom Validation scenario. :account_create, :deposit, :withdraw, :get_balance, :transfer
    defp validate_attributes(attribute_set, scenario) do
        case scenario do
            :account_create ->
                is_valid_name(attribute_set.name)
            :deposit ->
                with :ok <- is_valid_name(attribute_set.name),
                    :ok <- is_valid_currency(attribute_set.currency),
                    :ok <- is_valid_amount(attribute_set.amount),
                do: :ok
            :withdraw ->
                with :ok <- is_valid_name(attribute_set.name),
                    :ok <- is_valid_currency(attribute_set.currency),
                    :ok <- is_valid_amount(attribute_set.amount),
                do: :ok
            :get_balance ->
                with :ok <- is_valid_name(attribute_set.name),
                    :ok <- is_valid_currency(attribute_set.currency),
                do: :ok
            :transfer ->
                with :ok <- is_valid_name(attribute_set.from_name),
                    :ok <- is_valid_name(attribute_set.to_name),
                    :ok <- is_valid_currency(attribute_set.currency),
                    :ok <- is_valid_amount(attribute_set.amount),
                do: :ok
        end
    end


    # Validate name. Name should be any set of letters with ' and space
    # Returns: :ok|:invalid_name
    #
    # ## Parameters
    #     - name: string Name of the user
    defp is_valid_name(name) do
        try do
            case String.match?(name, ~r/^[A-Z,a-z,' ]+$/) do
                true ->
                    :ok
                _ ->
                    :invalid_name
            end
        rescue
            _e ->
                :invalid_name
        end
    end

    # Validate currency. Currency should be any set of letters
    # Returns: :ok|:invalid_currency_code

    # ## Parameters
    #     - currency: string Name of the currency
    defp is_valid_currency(currency) do
        try do
            case String.match?(currency, ~r/^[A-Z,a-z]+$/) do
                true ->
                    :ok
                _ ->
                    :invalid_currency_code
            end
        rescue
            _e ->
                :invalid_currency_code
        end
    end

    # Validate amount. Amount should be a number
    # Returns: :ok|:invalid_amount

    # ## Parameters
    #     - amount: number Amount
    defp is_valid_amount(amount) do
        try do
            if is_number(amount) do
                case String.match?(Kernel.inspect(amount), ~r/^[0-9]{0,6}(\.[0-9]{1,2})?$/) do
                    true ->
                        :ok
                    _ ->
                        :invalid_amount
                end
            else
                :invalid_amount
            end
        rescue
            _e ->
                :invalid_amount
        end
    end
end