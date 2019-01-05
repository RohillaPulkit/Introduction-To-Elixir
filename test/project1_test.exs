defmodule ProjectTest do
  use ExUnit.Case
  doctest Project

  test "batching" do
    assert Project.returnBatchedRanges(3, 2) == [[1..2, 2..3, 3..4]]
  end

  test "is integer" do
    assert Logic.isInteger(3.0) == true
    assert Logic.isInteger(5.0) == true
    assert Logic.isInteger(5.5) == false
    assert Logic.isInteger(7.0) == true
    assert Logic.isInteger(1.0) == true
  end

  test "main logic" do
    assert Logic.checkForPerfectSquare([[1..2, 2..3, 3..4]], self()) == [
             false: 1,
             false: 2,
             true: 3
           ]
  end
end
