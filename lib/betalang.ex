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

  def parse_code do
    # many(skip_many(spaces()) |> s_expression |> skip_many(spaces())) |> eof()
    many(skip(spaces()) |> s_expression) # |> eof()
    # many(skip_many(spaces()) |> s_expression |> skip_many(spaces())) # |> eof()
  end

  def s_expression(prev) do
    IO.puts "s-expression"
    IO.puts Kernel.inspect(prev)
    prev
    |> lazy(fn -> result = choice([
      symbol(nil),
      if_form(prev),
      lambda_form(nil),
      apply_form(nil)
    ]); result end)
  end

  def symbol(prev) do
    IO.puts "symbol"
    IO.puts Kernel.inspect(prev)
    prev
    |> pipe([letter(), many(alphanumeric())],
    fn charlist -> {:symbol, Enum.join(List.flatten(charlist)) } end)
  end

  # normal form
  def apply_form(prev) do
    IO.puts "apply form"
    IO.puts Kernel.inspect(prev)
    prev
    |> pipe([ignore(string("("))
            |> many1(skip_many(spaces()) |> s_expression)
            |> ignore(string(")"))],
    fn charlist -> {:apply, charlist} end)
  end

  # special form: if expression
  def if_form(prev) do
    IO.puts "if form"
    IO.puts Kernel.inspect(prev)
    prev
    |> pipe([
      ignore(string("("))
      |> ignore(skip_many(spaces())) |> ignore(string("if"))
      |> ignore(skip_many(spaces())) |> s_expression
      |> ignore(skip_many(spaces())) |> s_expression
      |> ignore(skip_many(spaces())) |> s_expression
      |> ignore(skip_many(spaces())) |> ignore(string(")"))],
    fn symsexp -> { :if, symsexp } end)
  end

  # special form: lambda abstraction
  def lambda_form(prev) do
    IO.puts "lambda form"
    IO.puts Kernel.inspect(prev)
    prev
    |> pipe([
      ignore(string("("))
      |> skip_many(spaces()) |> ignore(string("lambda"))
      |> skip_many(spaces()) |> ignore(string("("))
      |> many(skip_many(spaces()) |> symbol |> skip_many(spaces())) |> ignore(string(")"))
      |> skip_many(spaces()) |> s_expression
      |> skip_many(spaces()) |> ignore(string(")"))],
      fn symsexp -> { :lambda, symsexp } end)
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
