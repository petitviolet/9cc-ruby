require 'byebug'
require_relative '9cc/token'

class Program
  # @param user_input [String] Given program
  def initialize(user_input)
    @user_input = user_input
  end

  def run
    tokens = Token.tokenize(@user_input)
    pp tokens
    outputs = []

    # Headers of assembly
    outputs << ".intel_syntax noprefix"
    outputs << ".global main"
    outputs << "main:"

    case tokens
    in [Token::Num => num, *rest]
      # The first token must be a number
      outputs << "  mov rax, #{num.value}"
      tokens = rest
      while true
        case tokens
        in [Token::Reserved['+'], Token::Num => num, *rest]
          outputs << "  add rax, #{num.value}"
          tokens = rest
        in [Token::Reserved['-'], Token::Num => num, *rest]
          outputs << "  sub rax, #{num.value}"
          tokens = rest
        in [Token::Eof]
          outputs << "  ret"
          break
        end
      end
    else
      Token.error_at(@user_input, 0, "is not a number")
    end

    puts outputs.join("\n")
  end
end

Program.new(ARGV.first).run
