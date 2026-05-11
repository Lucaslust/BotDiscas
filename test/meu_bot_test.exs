defmodule MeuBotTest do
  use ExUnit.Case
  doctest MeuBot

  test "greets the world" do
    assert MeuBot.hello() == :world
  end
end
