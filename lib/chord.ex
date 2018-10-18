defmodule Chord do
  @moduledoc """
  Documentation for Chord.
  """

  def start_nodes(list, _n) when list == [] do
    :ok
  end

  def start_nodes(list, n) do
    [head | tail] = list
    child = NodeSuper.start_child(head, n)
    ChordNode.join(head, child)
    # :timer.sleep(1)
    # NodeSuper.stablize_all_children()
    # IO.gets("")
    #  NodeSuper.check_all_children()
    # IO.gets("")

    start_nodes(tail, n)
  end

  def main(n, mess) do
    NodeSuper.start_link()
    list = Enum.to_list(1..n |> Enum.shuffle())
    IO.puts("adding nodes in the order")
    IO.inspect(list)
    [head | tail] = list
    child = NodeSuper.start_child(head, n)
    ChordNode.create(child, n)
    # Node.spawn_link(Node.self(), NodeSuper.stablize_all_children())
    start_nodes(tail, n)
    NodeSuper.fix_all_fingers()
    NodeSuper.send_messages(mess, n)
    #  NodeSuper.check_all_children()
  end
end
