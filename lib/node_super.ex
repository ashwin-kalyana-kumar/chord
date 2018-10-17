defmodule NodeSuper do
  def start_link() do
    DynamicSupervisor.start_link(strategy: :one_for_one, name: :i_am_super)
  end

  # def init(strategy) do
  #    DynamicSupervisor.init(strategy)
  #  end

  def start_child(id) do
    spec = %{id: id, start: {ChordNode, :start_link, [id]}}
    IO.inspect(spec)
    {:ok, child} = DynamicSupervisor.start_child(:i_am_super, spec)
    child
  end

  def get_an_active_child_id() do
    list = DynamicSupervisor.which_children(:i_am_super)
    {_, pid, _, _} = list |> Enum.random()
    pid
  end

  def stablize_all_children() do
    list = DynamicSupervisor.which_children(:i_am_super)

    list
    |> Enum.each(fn item ->
      {_, pid, _, _} = item
      GenServer.cast(pid, :stablize)
      :timer.sleep(100)
    end)

    # stablize_all_children()
  end

  def check_all_children() do
    list = DynamicSupervisor.which_children(:i_am_super)
    IO.puts("OHHHHHHHHH YEAHHHHHHHHHHHHH")

    list
    |> Enum.each(fn item ->
      {_, pid, _, _} = item
      :ok = ChordNode.print_keys(pid)
    end)
  end
end
