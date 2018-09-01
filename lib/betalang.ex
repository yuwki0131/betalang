defmodule Betalang do
  @moduledoc """
  Betalang.
  is yet another simple lisp processor
  """

  @doc """
  run app from here
  """
  def main(argv) do
    parse_args(argv)
    |> process
  end

  # 引数をパースする処理
  def parse_args(argv) do
    parse = OptionParser.parse(argv,
      switches: [ help: :boolean],
      aliases: [h: :help])

    case parse do
      { [ help: true ], _, _}
        -> :help
      { _, sourcecode, _}
        -> sourcecode
      _ -> :help
    end
  end

  def process(:help) do
    IO.puts """
    usage: betalang "(a 1)"
    """
    System.halt(0)
  end

  def process(sourcecode) do
    IO.puts sourcecode
  end
end
