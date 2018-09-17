defmodule Betalang do
  use Combine
  import Combine.Helpers
  import Combine.ParserState
  import Combine.Parsers.Base
  import Combine.Parsers.Text

  alias Combine.ParserState

  defparser lazy(%ParserState{status: :ok} = state, generator) do
    (generator.()).(state)
  end


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

  def ignore_ignores(ls) do
    Enum.filter(ls, fn(x) -> x != :__ignore end)
  end

  def parse_code do
    many(skip(spaces()) |> s_expression) |> eof()
  end

  def s_expression(prev) do
    prev
    |> lazy(fn -> result = choice([
      symbol(nil),
      literal(nil),
      if_form(nil),
      lambda_form(nil),
      apply_form(nil)
    ]); result end)
  end

  # symbol
  def symbol(prev) do
    prev
    |> pipe([letter(), many(alphanumeric())],
    fn charlist -> {:symbol, Enum.join(List.flatten(charlist)) } end)
  end

  # literal
  def literal(prev) do
    prev
    |> pipe([many1(alphanumeric())],
    fn charlist -> {:literal, Integer.parse(Enum.join(List.flatten(charlist))) } end)
  end

  # normal form
  def apply_form(prev) do
    prev
    |> pipe([ignore(string("("))
            |> many1(skip_many(spaces()) |> s_expression)
            |> ignore(string(")"))],
    fn sexps -> {:apply, ignore_ignores(sexps)} end)
  end

  # special form: if expression
  def if_form(prev) do
    prev
    |> pipe([
      ignore(string("("))
      |> ignore(skip_many(spaces())) |> ignore(string("if"))
      |> ignore(skip_many(spaces())) |> s_expression
      |> ignore(skip_many(spaces())) |> s_expression
      |> ignore(skip_many(spaces())) |> s_expression
      |> ignore(skip_many(spaces())) |> ignore(string(")"))],
    fn symsexp -> { :if, ignore_ignores(symsexp) } end)
  end

  # special form: lambda abstraction
  def lambda_form(prev) do
    prev
    |> pipe([
      ignore(string("("))
      |> skip_many(spaces()) |> ignore(string("lambda"))
      |> skip_many(spaces()) |> ignore(string("("))
      |> many1(skip_many(spaces()) |> symbol) |> ignore(string(")"))
      |> skip_many(spaces()) |> s_expression
      |> skip_many(spaces()) |> ignore(string(")"))],
      fn sexps -> { :lambda, ignore_ignores(sexps) } end)
  end

  # 引数側のパース処理
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
    IO.puts ("sourcecode: " <> List.first(sourcecode))
    IO.puts Kernel.inspect(Combine.parse((List.first(sourcecode)), parse_code()))
  end
end
