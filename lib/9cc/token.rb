require_relative './rstruct'

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

  # Sign
  Reserved = Rstruct.new(:char)
  # Number
  Num = Rstruct.new(:value)
  # End of file
  Eof = Rstruct.new
end
