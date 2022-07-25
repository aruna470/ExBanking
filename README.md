# ExBanking

**This an Elixir application developed to cater the functionality of ExBank**

## How to run the application

Go to root folder and type <br /> <br />
iex -S mix <br />
ExBanking.Supervisor.start_link([])

## Following methods can be executed
ExBanking.create_user("Jhon") <br />
ExBanking.deposit("Jhon", 10, "USD") <br />
ExBanking.withdraw("Jhon", 5, "USD") <br />
ExBanking.get_balance("Jhon", "USD") <br />
ExBanking.send("Jhon", "Anne", 10, "USD") <br />
