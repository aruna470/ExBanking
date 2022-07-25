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

## How to execute unit tests

Execute following command on command line<br /><br />

mix test --trace<br /><br />

Test result<br /><br />

  * test Withdraw with wrong arguments (5.8ms) [L#56]<br />
  * test Withdraw insufficient amount (5.8ms) [L#50]<br />
  * test Withdraw from non existing user (0.1ms) [L#44]<br />
  * test Too many balance requests for user (0.5ms) [L#127]<br />
  * test Withdraw from user (0.2ms) [L#38]<br />
  * test Deposit amount to non existing user (0.00ms) [L#30]<br />
  * test Transfer from insufficient balance account (0.2ms) [L#96]<br />
  * test Transfer to an account (0.2ms) [L#72]<br />
  * test Too many requests to sender in transfer (0.6ms) [L#138]<br />
  * test Transfer from non existing sender (0.2ms) [L#82]<br />
  * test Deposit amount to user (0.1ms) [L#25]<br />
  * test Create user with correct name (0.00ms) [L#12]<br />
  * test Transfer to non existing receiver (0.1ms) [L#89]<br />
  * test Too many deposit requests for user (1.8ms) [L#106]<br />
  * test Create user with invalid name (0.1ms) [L#16]<br />
  * test Too many withdraw requests for user (0.4ms) [L#116]<br />
  * test Check balance for non existing user (0.1ms) [L#66]<br />
  * test Deposit with wrong arguments (0.00ms) [L#34]<br />
  * test Check balance (0.1ms) [L#60]<br />
  * test Create user existing name (0.1ms) [L#20]<br />
<br /><br />

Finished in 0.09 seconds (0.09s async, 0.00s sync)<br />
20 tests, 0 failures<br />

Randomized with seed 634617<br />