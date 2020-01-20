require 'rstructural'

module Token

  class << self
    PUNCTUATIONS = Regexp.union(%w|== != > >= <= < = ! + - * / ( )|)
    TOKENIZE_REGEX = Regexp.union(/[A-Za-z]+/, /\d+/, PUNCTUATIONS, /\S/)

    # @param [String] user_inputs
    # @return [TokenKind]
    def tokenize(user_inputs)
      acc = []
      user_inputs.scan(TOKENIZE_REGEX) do |match|
        case match
        in num if num =~ /\d+/
          acc << Token::Num.new(num.to_i)
        in sign if PUNCTUATIONS.match?(sign)
          acc << Token::Reserved.new(sign)
        else
          idx = Regexp.last_match.offset(0).first
          error_at(user_inputs, idx, "Failed to tokenize. input = #{match}")
        end
      end
      acc << Token::Eof
      acc
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
