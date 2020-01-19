require 'rstructural'

module Token

  class << self
    PUNCTUATIONS = %w|+ - * / ( )|

    # @param [String] user_inputs
    # @return [TokenKind]
    def tokenize(user_inputs)
      # need rafactoring...
      num_ch = ''
      user_inputs.each_char.with_index.reduce([]) do |acc, (char, i)|
        case char
        in num if num =~ /[0-9]/
          num_ch = "#{num_ch}#{num}"
        else
          if num == '0'
            error_at(user_inputs, i, 'Number must not start with 0')
          end

          unless num_ch.empty?
            acc << Token::Num.new(num_ch.to_i) # cleanup num_ch == '00001' -> 1
            num_ch = ''
          end
          case char
          in ' '
            # skip
          in char if PUNCTUATIONS.include?(char)
            acc << Token::Reserved.new(char)
          else
            error_at(user_inputs, i, "Failed to tokenize. input = #{char}")
          end
        end
        acc
      end.tap do |acc|
        unless num_ch.empty?
          acc << Token::Num.new(num_ch.to_i)
        end
        acc << Token::Eof
      end
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
