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
    def self.new(attribute = nil)
      if attribute
        Class.new do
          def initialize(value)
            @value = value
          end

          define_method(attribute.to_s) do
            @value
          end

          def inspect
            "#{self.class.name}(#{@value})"
          end

          alias :to_s :inspect

          def deconstruct
            [@value]
          end
        end
      else
        Class.new do
          def initialize

          end

          def inspect
            "#{self.class.name}"
          end

          alias :to_s :inspect

          def deconstruct
            []
          end
        end
      end
    end
  end
  # Sign
  class Reserved < TokenKind.new(:char)
    def initialize(value)
      @value = value
    end
  end
  # Number
  class Num < TokenKind.new(:value)
    def initialize(value)
      @value = value
    end
  end
  # End of file
  class Eof < TokenKind.new
  end
end
