# ExBanking

**This is a Elixir application developed to cater the functionality of ExBank**

## How to run the application

Go to root folder and type <br /> <br />
iex -S mix <br />
ExBanking.Supervisor.start_link([])

## Following methods can be executed
```elixir
ExBanking.create_user("Jhon")
ExBanking.deposit("Jhon", 10, "USD")
ExBanking.withdraw("Jhon", 5, "USD")
ExBanking.get_balance("Jhon", "USD")
ExBanking.send("Jhon", "Anne", 10, "USD")
```