defmodule NodeStruct do
  @doc """
  The basic struct for the node GenServer.
  """
  defstruct [:id, :successor, :predecessor, :keys, :finger_table]
end
