defmodule Client do
  @moduledoc """
    to connect client node with server
  """
  def contact_server(ipAddress, maximum, length) do
    id = :rand.uniform(100)
    clientNode = String.to_atom("client_node" <> to_string(id) <> "@127.0.0.1")
    _ = System.cmd("epmd", ["-daemon"])

    {:ok, _} = Node.start(clientNode)
    :global.register_name("client", self())

    isConnected = Node.connect(String.to_atom("server_node@" <> ipAddress))

    if isConnected do
      :global.sync()
      :global.registered_names()
      Client.request_work(maximum, length)
      true
    else
      IO.puts("Unable to connect to server node")
      false
    end
  end

  def request_work(maximum, length) do
    pid = :global.whereis_name("server")
    send(pid, {:process_request, maximum, length, Node.self()})
    receiver()
  end

  def receiver do
    receive do
      {:startPoint, startPoint} ->
        IO.puts(startPoint)
        receiver()

      {:complete} ->
        :ok
    end
  end
end

defmodule Server do
  @moduledoc """
  takes up the arguments from the command line and process the input
  ---Valid local input: ./project1 n k---Valid server input: ./project1 IPAddress n k---Valid client input: ./project1 IPAddress
  """
  @errorString "Error: Invalid input \nValid local input: ./project1 n k \nValid server input: ./project1 ServerIPAddress \nValid client input: ./project1 ServerIPAddress n k\nNote: n and k are integers"
  def main(args) do
    with parsedArgs = args |> parse_args() do
      cond do
        length(parsedArgs) == 2 -> Project.process(parsedArgs)
        length(parsedArgs) == 3 -> contactClient(parsedArgs)
        length(parsedArgs) == 1 -> startServer(parsedArgs)
      end
    end
  end

  @doc """
  Parse the arguments into the required form
  """
  def parse_args(args) when length(args) > 3 or length(args) < 1 do
    IO.puts(@errorString)

    # stop the program from running
    System.halt(0)
  end

  def parse_args(args) do
    args
    |> args_to_internal_representation()
  end

  def contactClient([ipAddress, maximum, length]) do
    if isValidAddress(ipAddress) do
      Client.contact_server(ipAddress, maximum, length)
    else
      IO.puts(@errorString)
    end
  end

  def startServer([ipAddress]) do
    if isValidAddress(ipAddress) do
      IO.puts("Starting server...")

      _ = System.cmd("epmd", ["-daemon"])
      isStarted = Node.start(String.to_atom("server_node@" <> ipAddress))

      case isStarted do
        {:ok, _} ->
          IO.puts("Server started.")
          :global.register_name("server", self())
          receiver()
        {_, _} -> IO.puts("Failed to start server.")
      end

    else
      IO.puts(@errorString)
    end
  end

  defp args_to_internal_representation([ipAddress, maximum, length]) do
    [ipAddress, toInteger(maximum), toInteger(length)]
  end

  defp args_to_internal_representation([maximum, length]) do
    [toInteger(maximum), toInteger(length)]
  end

  defp args_to_internal_representation([ipAddress]) do
    [ipAddress]
  end

  def isValidAddress(ipAddress) do
    parts = String.split(ipAddress, ".")
    if length(parts) == 4, do: true, else: false
  end

  def toInteger(number) do

    if match?({_, ""}, Integer.parse(number)) do
      value = String.to_integer(number)
      value
    else
      IO.puts(@errorString)
      System.halt(0)
    end
  end

  def receiver() do
    receive do
      {:process_request, maximum, length, client_node} -> #divide processes between server and client machine
        maxHalf = maximum / 2
        Node.spawn(client_node, Project, :process, [[trunc(maxHalf), length]])
        Node.spawn(Node.self(), Project, :process, [trunc(maxHalf + 1), [maximum, length]])
        receiver()
    end
  end
end
