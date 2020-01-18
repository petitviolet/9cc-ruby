require 'rstructural'

module Token
  class << self
    # @param user_inputs [String]
    # @return [TokenKind]
    def tokenize(user_inputs)
      user_inputs.split(' ').each_with_index.reduce([]) do |acc, (char, i)|
        case char
        in ' '
        in '+' | '-'
          acc << Token::Reserved.new(char)
        in num if num =~ /\A[1-9]*[0-9]+\z/
          acc << Token::Num.new(num.to_i)
        else
          error_at(user_inputs, i, "Failed to tokenize. input = #{char}")
        end
        acc
      end.tap { |acc| acc << Token::Eof }
    end

    def error_at(inputs, index, message)
      msg = <<~EOF

        #{inputs}
         #{" " * index} ^ #{message}
      EOF
      raise ArgumentError.new(msg)
    end
  end

  extend ADT

  # Sign
  Reserved = data :char
  # Number
  Num = data :value
  # End of file
  Eof = const
end
