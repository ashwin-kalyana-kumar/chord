defmodule ChordNode do
  use GenServer

  @doc """

  """

  def start_link(id) do
    state = %NodeStruct{id: id, keys: []}
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, state}
  end

  def print_keys(pid) do
    :ok = GenServer.call(pid, :print_keys)
  end

  def get_node(id) do
    pid = NodeSuper.get_an_active_child_id()

    new_pid =
      if(pid == id) do
        get_node(id)
      else
        pid
      end

    new_pid
  end

  def join(new_pid) do
    id = GenServer.call(new_pid, :get_id)
    # IO.puts("new node joined")
    # IO.inspect(new_pid)
    node = get_node(new_pid)
    # IO.puts("asking:")
    # IO.inspect(node)

    # RISKKKYYYYYYYY
    suc_pid = GenServer.call(node, {:get_successor, id})
    # IO.puts("got!!")
    # IO.inspect(suc_pid)
    # REALLYYYYYY????
    GenServer.call(new_pid, {:new_successor, suc_pid})
    # IO.puts("created successfully!!")
    # REALLYY REQUIREDDDD?
    #    GenServer.cast(new_pid, :stablize)
  end

  def create(new_pid, num_keys) do
    # id = GenServer.call(new_pid, :get_id)
    keys = Enum.to_list(1..num_keys)
    # IO.puts("Created!!")
    # IO.inspect(new_pid)
    # REQUIRED??
    :ok = GenServer.call(new_pid, {:initial_values, new_pid, new_pid, keys})
    # GenServer.cast(new_pid, :stablize)
  end

  defp find_succ(_id, list, prev_pid) when list == [] do
    prev_pid
  end

  defp find_succ(id, list, _prev_pid) do
    [{head_id, head_pid} | tail] = list

    if(head_id > id) do
      head_pid
    else
      find_succ(id, tail, head_pid)
    end
  end

  def handle_cast({:yo_im_ur_new_predecessor, pid, id}, state) do
    GenServer.cast(state.successor, {:delete_these_keys, state.keys})

    new_state =
      unless state.predecessor == nil do
        # REALLLYY? TRY storing the predecessor and successor ID in your state
        pred_id = GenServer.call(state.predecessor, :get_id)

        new_pred =
          cond do
            pred_id < id and pred_id < state.id -> pid
            pred_id > id and pred_id > state.id -> pid
            pred_id == state.id -> pid
            true -> state.predecessor
          end

        state |> Map.update!(:predecessor, fn _ -> new_pred end)
      else
        state |> Map.update!(:predecessor, fn _ -> pid end)
      end

    {:noreply, new_state}
  end

  def handle_cast(:stablize, state) do
    # IO.puts("stablizing #{state.id}")
    # IO.inspect(self())
    suc_pid = state.successor

    pid =
      unless suc_pid == self() do
        # RISKYYYYYYY!! But I guess, a call here makes sense
        GenServer.call(suc_pid, :yo_give_me_your_predecessor)
      else
        state.predecessor
      end

    suc_pid =
      cond do
        pid == nil and suc_pid != self() ->
          GenServer.cast(suc_pid, {:yo_im_ur_new_predecessor, self(), state.id})
          suc_pid

        pid != self() ->
          GenServer.cast(pid, {:yo_im_ur_new_predecessor, self(), state.id})
          pid

        true ->
          suc_pid
      end

    # IO.puts("My new succ piD for #{state.id}")
    # IO.inspect(suc_pid)
    state = state |> Map.update!(:successor, fn _ -> suc_pid end)

    # IO.puts("done stablizing #{state.id}")
    {:noreply, state}
  end

  def handle_cast(:stablize_old, state) do
    # IO.puts("stablizing #{state.id}")
    # IO.inspect(self())
    suc_pid = state.successor

    new_state =
      unless suc_pid == self() do
        pid = GenServer.call(suc_pid, :yo_give_me_your_predecessor)
        # IO.puts("#{state.id} successor")
        # IO.inspect(suc_pid)

        suc_pid =
          cond do
            pid == nil ->
              GenServer.call(suc_pid, {:yo_im_ur_new_predecessor, self(), state.id})
              suc_pid

            pid != self() ->
              GenServer.call(pid, {:yo_im_ur_new_predecessor, self(), state.id})
              pid

            true ->
              suc_pid
          end

        state |> Map.update!(:successor, fn _ -> suc_pid end)
      else
        state
      end

    # IO.puts("done stablizing #{state.id}")
    {:noreply, new_state}
  end

  def handle_cast({:delete_these_keys, keys_to_remove}, state) do
    state_keys = state.keys

    # state_keys |> Enum.each(fn x ->  ifEnum.member(keys_to_remove,x))
    {_rem, new_keys} = state_keys |> Enum.split_with(fn x -> Enum.member?(keys_to_remove, x) end)
    state = state |> Map.update!(:keys, fn _x -> new_keys end)

    {:noreply, state}
  end

  def handle_cast({:new_predecessor, pred_pid}, state) do
    pred = state.predecessor

    state = state |> Map.update!(:predecessor, fn _ -> pred_pid end)

    # IO.puts("Stablizing on")
    ## IO.inspect(pred)

    unless state.successor == self() do
      GenServer.cast(state.successor, {:delete_these_keys, state.keys})
    end

    GenServer.cast(pred, :stablize)

    {:noreply, state}
  end

  def handle_call({:new_predecessor, pred_pid}, _from, state) do
    pred = state.predecessor

    #    if pred == nil do
    #  #IO.puts("OMGOMGGMOGMOGMMGOGMOMGOGMGOMGMOGMGOGMOGMOGMOGMGO")
    #      #IO.inspect(self())
    #    end

    state = state |> Map.update!(:predecessor, fn _ -> pred_pid end)

    #    new_succ =
    #      if(state.successor == self()) do
    #        pred_pid
    #      else
    #        state.successor
    #      end
    #
    #    state = state |> Map.update!(:successor, fn _ -> new_succ end)

    #    unless pred == self() do
    # IO.puts("Stablizing on")
    # IO.inspect(pred)
    GenServer.cast(self(), :stablize)
    #    end

    {:reply, :ok, state}
  end

  def handle_call({:new_successor, suc_pid}, _from, state) do
    state = state |> Map.update!(:successor, fn _ -> suc_pid end)
    GenServer.cast(suc_pid, {:new_predecessor, self()})
    # IO.puts("notified successor")
    # RISKY, but makes sense here too!
    keys = GenServer.call(suc_pid, {:give_me_keys, state.id})
    # IO.puts("got the keys!!")
    # IO.inspect(keys)
    state = state |> Map.update!(:keys, fn _ -> keys end)
    {:reply, :ok, state}
  end

  def handle_call({:yo_im_ur_new_predecessor_old, pid, id}, _from, state) do
    GenServer.cast(state.successor, {:delete_these_keys, state.keys})

    new_state =
      unless state.predecessor == nil do
        pred_id = GenServer.call(state.predecessor, :get_id)

        new_pred =
          cond do
            pred_id < id and pred_id < state.id -> pid
            pred_id > id and pred_id > state.id -> pid
            pred_id == state.id -> pid
            true -> state.predecessor
          end

        state |> Map.update!(:predecessor, fn _ -> new_pred end)
      else
        state |> Map.update!(:predecessor, fn _ -> pid end)
      end

    {:reply, :ok, new_state}
  end

  def handle_call(:yo_give_me_your_predecessor, _from, state) do
    {:reply, state.predecessor, state}
  end

  def handle_call({:give_me_keys, id}, _from, state) do
    keys = state.keys
    keys = Enum.sort(keys)
    {mine, not_mine} = Enum.split_while(keys, fn x -> x <= state.id end)

    {not_mine2, _mine2} =
      if(state.id > id) do
        {a, b} = Enum.split_while(mine, fn x -> x <= id end)
        {a ++ not_mine, b}
      else
        {a, b} = Enum.split_while(not_mine, fn x -> x <= id end)
        {a, b ++ mine}
      end

    # state = state |> Map.update!(:keys, fn _ -> mine2 end)

    {:reply, not_mine2, state}
  end

  def handle_call({:get_successor, id}, _from, state) do
    # IO.puts("want successor for #{id}")
    # IO.inspect(state.keys)

    if(Enum.member?(state.keys, id)) do
      {:reply, self(), state}
    else
      # succ = find_succ(id, State.finger_table, nil)
      succ = state.successor
      # IO.puts("asking")
      # IO.inspect(succ)
      # RISKIEST of ALL calls. This one causes deadlocks!!
      pid = GenServer.call(succ, {:get_successor, id})
      {:reply, pid, state}
    end
  end

  def handle_call(:get_id, _from, state) do
    {:reply, state.id, state}
  end

  def handle_call({:initial_values, suc_pid, pred_pid, keys}, _from, state) do
    state =
      state
      |> Map.update!(:successor, fn _x -> suc_pid end)
      |> Map.update!(:predecessor, fn _x -> pred_pid end)
      |> Map.update!(:keys, fn _x -> keys end)

    {:reply, :ok, state}
  end

  def handle_call(:print_keys, _from, state) do
    id = state.id
    IO.puts("Printing #{id}")
    IO.inspect(self())
    IO.inspect(state.successor)
    IO.inspect(state.predecessor)
    IO.inspect(state.keys)
    {:reply, :ok, state}
  end
end
