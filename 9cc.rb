require 'byebug'

module Token
  class << self
    # @param user_inputs [String]
    # @return [TokenKind]
    def tokenize(user_inputs)
      tokens = []
      user_inputs.split(' ').each.with_index do |char, i|
        case char
        in ' '
          next
        in '+' | '-'
          tokens << Token::Reserved.new(char)
        in num if num =~ /\A[1-9]*[0-9]+\z/
          tokens << Token::Num.new(num.to_i)
        else
          error_at(user_inputs, i, "Failed to tokenize. input = #{char}")
        end
      end
      tokens << Token::Eof.new
      tokens
    end

    def error_at(inputs, index, message)
      msg = <<~EOF

      #{inputs}
       #{" " * index} ^ #{message}
      EOF
      raise ArgumentError.new(msg)
    end
  end

  module TokenKind
  end
  # Sign
  class Reserved < Struct.new(:char)
    include(TokenKind)
  end
  # Number
  class Num < Struct.new(:value)
    include(TokenKind)
  end
  # End of file
  class Eof
    include(TokenKind)
  end
end

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
