defmodule Project do
  @moduledoc """
  Process the input
  """

  # batch size for each project
  @batchSize 5000

  @doc """
  Processes the input and produces output
  """
  def process(minimum \\ 1, [maximum, length]) do
    with batchedRanges = returnBatchedRanges(minimum, maximum, length) do
      for ranges <- batchedRanges do
        spawn(Logic, :checkForPerfectSquare, [[ranges], self()])
      end
    end

    receiver(maximum)
  end

  # if size is greater than batch size divide the range into the batch size
  def returnBatchedRanges(batchedRanges \\ [], minimum, maximum, length)

  def returnBatchedRanges(batchedRanges, minimum, maximum, length)
      when maximum - minimum > @batchSize do
    # convert range into list of range (like [1..2,2..3],[3..4,4..5]...)
    upperBound = minimum + @batchSize - 1

    ranges =
      List.insert_at(
        batchedRanges,
        length(batchedRanges),
        Enum.into(minimum..upperBound, [], &(&1..(&1 + length - 1)))
      )

    returnBatchedRanges(ranges, minimum + @batchSize, maximum, length)
  end

  def returnBatchedRanges(batchedRanges, minimum, maximum, length) do
    # convert range into list of range (like 1..24,2..25...)
    List.insert_at(
      batchedRanges,
      length(batchedRanges),
      Enum.into(minimum..maximum, [], &(&1..(&1 + length - 1)))
    )
  end

  # stops program after recieve is complete
  def receiver(0) do
    cond do
      :undefined == :global.whereis_name("client") -> nil
      pid = :global.whereis_name("client") -> send(pid, {:complete})
    end
  end

  def receiver(counter) when counter > 0 do
    receive do
      {true, startPoint} ->
        cond do
          :undefined == :global.whereis_name("client") -> nil
          pid = :global.whereis_name("client") -> send(pid, {:startPoint, startPoint})
        end

        IO.puts(startPoint)
        # prints the start point of perfect square equation
        receiver(counter - 1)

      {false, _} ->
        receiver(counter - 1)
    end
  end
end

defmodule Logic do
  @moduledoc """
  All the computational logic is done here
  """

  def checkForPerfectSquare([ranges], sender) do
    for range <- ranges do
      startPoint.._ = range

      isInteger =
        range
        # square the elements
        |> Enum.map(&(&1 * &1))
        # sum of all the elements
        |> Enum.sum()
        # root of aggregate sum -> returns float value
        |> :math.sqrt()
        # check for integer -> returns true/false
        |> isInteger

      case isInteger do
        true -> send(sender, {true, startPoint})
        false -> send(sender, {false, startPoint})
      end
    end
  end

  @doc """
     returns true if the number has 0 in decimal place like 3.0, 5.0, 6.0, else false
  """
  def isInteger(number) do
    # takes float value and check if integer
    decimal = number - Float.floor(number)

    case decimal do
      0.0 -> true
      _ -> false
    end
  end
end
