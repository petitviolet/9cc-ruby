require 'rstructural'

module Token
  extend ADT

  # Sign
  Reserved = data :char
  # Identifier
  Ident = data :name
  # Number
  Num = data :value
  # Return
  Ret = const
  # End of file
  Eof = const

  class << self
    PUNCTUATIONS = Regexp.union(%w|== != >= <= > < = ! + - * / ( ) ;|)
    NUM_REGEX = Regexp.compile(/\d+/)
    IDENT_REGEX = Regexp.compile(/[A-Za-z]+/)
    SPACE_REGEX = Regexp.compile(/\S+/)
    TOKENIZE_REGEX = Regexp.union(IDENT_REGEX, NUM_REGEX, PUNCTUATIONS, SPACE_REGEX)

    # @param [String] user_inputs
    # @return [TokenKind]
    def tokenize(user_inputs)
      acc = []
      user_inputs.scan(TOKENIZE_REGEX) do |match|
        idx = Regexp.last_match.offset(0).first
        case match
        in "return"
          acc << Token::Ret
        in ident if IDENT_REGEX.match?(ident)
          acc << Token::Ident.new(ident)
        in num if NUM_REGEX.match?(num)
          acc << Token::Num.new(num.to_i)
        in sign if PUNCTUATIONS.match?(sign)
          acc << Token::Reserved.new(sign)
        else
          error_at(user_inputs, idx, "Failed to tokenize. input = #{match}")
        end
      end
      acc << Token::Eof
      acc
    end

    def error_at(inputs, index, message)
      msg = <<~EOF

        #{inputs}
        #{" " * index}^ #{message}
      EOF
      raise ArgumentError.new(msg)
    end
  end
end
