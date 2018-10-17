defmodule Chord do
  @moduledoc """
  Documentation for Chord.
  """

  def start_nodes(list) when list == [] do
    :ok
  end

  def start_nodes(list) do
    [head | tail] = list
    child = NodeSuper.start_child(head)
    ChordNode.join(child)
    # :timer.sleep(1)
    # NodeSuper.stablize_all_children()
    # IO.gets("")
    #  NodeSuper.check_all_children()
    # IO.gets("")

    start_nodes(tail)
  end

  def main(n) do
    NodeSuper.start_link()
    list = Enum.to_list(1..n |> Enum.shuffle())
    IO.puts("adding nodes in the order")
    IO.inspect(list)
    [head | tail] = list
    child = NodeSuper.start_child(head)
    ChordNode.create(child, n)
    # Node.spawn_link(Node.self(), NodeSuper.stablize_all_children())
    start_nodes(tail)
    NodeSuper.check_all_children()
  end
end
