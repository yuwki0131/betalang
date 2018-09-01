defmodule Betalang do
  import Combine.Parsers.Base
  import Combine.Parsers.Text

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

  defp parse_code do
    many(s_expression())
  end

  defp s_expression do
    choice([symbol(), lambda_form(), apply_form(), if_form()])
  end

  defp symbol do
    letter() |> many(alphanumeric())
  end

  defp lambda_form do
    ignore(string("("))
    |> skip(spaces()) |> string("lambda")
    |> skip(spaces()) |> ignore(string("("))
    |> many(skip(spaces()) |> string("symbol") |> skip(spaces()))
    |> ignore(string(")"))
    |> skip(spaces()) |> many1(s_expression())
    |> skip(spaces()) |> ignore(string(")"))
  end

  defp apply_form do
    ignore(string("("))
    |> skip(spaces()) |> many1(s_expression())
    |> skip(spaces()) |> ignore(string(")"))
  end

  defp if_form do
    ignore(string("("))
    |> skip(spaces()) |> string("if")
    |> skip(spaces()) |> choice([s_expression()])
    |> skip(spaces()) |> choice([s_expression()])
    |> skip(spaces()) |> choice([s_expression()])
    |> skip(spaces()) |> ignore(string(")"))
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
    IO.puts Combine.parse(sourcecode, parse_code())
  end
end
