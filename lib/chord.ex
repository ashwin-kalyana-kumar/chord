defmodule Chord do
  @moduledoc """
  Documentation for Chord.
  """

  def receive_messages(total, count) do
    receive do
      {:hop_count, hop_count} -> receive_messages(total + 1, count + hop_count)
    after
      10_000 -> IO.puts("Average number of hops: #{count / total}")
    end
  end

  def start_nodes(list, _n, _count) when list == [] do
    :ok
  end

  def start_nodes(list, n, count) do
    [head | tail] = list
    child = NodeSuper.start_child(head, n, self())
    ChordNode.join(head, child)
    :timer.sleep(5)
    # NodeSuper.stablize_all_children()
    # IO.gets("")
    #  NodeSuper.check_all_children()
    # IO.gets("")
    #    IO.puts(count)
    start_nodes(tail, n, count - 1)
  end

  def main(n, mess) do
    NodeSuper.start_link()
    list = Enum.to_list(1..n |> Enum.shuffle())
    IO.puts("adding nodes in the order")
    IO.inspect(list)
    [head | tail] = list
    child = NodeSuper.start_child(head, n, self())
    ChordNode.create(child, n)
    # Node.spawn_link(Node.self(), NodeSuper.stablize_all_children())
    start_nodes(tail, n, n)
    IO.puts("started!!")
    NodeSuper.fix_all_fingers()
    IO.puts("fixed!!")
    :timer.sleep(2000)
    #  NodeSuper.check_all_children()
    NodeSuper.send_messages(mess, n)
    receive_messages(0, 0)
  end
end
