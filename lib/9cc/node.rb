require 'rstructural'
require_relative './token'

module Node
  extend ADT

  Add = data :lhs, :rhs
  Sub = data :lhs, :rhs
  Mul = data :lhs, :rhs
  Div = data :lhs, :rhs
  Num = data :value

  class Parser

    # @param [Array<Token>] tokens
    def initialize(tokens)
      @tokens = tokens
    end

    def run
      case expr(@tokens)
      in [nodes, [Token::Eof]]
        return nodes
      in [nodes, rest] # else
          raise RuntimeError, <<~MSG
          tokens must be empty after run `expr`.
            inputs: #{@tokens}
            nodes: #{nodes}
            tokens: #{rest}
          MSG
      end
    end

    private

      # primary = num | "(" expr ")"
      def primary(tokens)
        case tokens
        in [Token::Num[value], *rest]
          [Node::Num.new(value), rest]
        in [Token::Reserved['('], *rest]
          case expr(rest)
          in [node, [Token::Reserved[')'], *rest]]
            return [node, rest]
          end
        end
      end

      # mul     = primary ("*" primary | "/" primary)*
      def mul(tokens)
        left, tokens = primary(tokens)
        nodes = [left]
        while true do
          case tokens
          in [Token::Reserved['*'], *tokens]
            right, tokens = primary(tokens)
            nodes << Node::Mul.new(left, right)
          in [Token::Reserved['/'], *tokens]
            right, tokens = primary(tokens)
            nodes << Node::Div.new(left, right)
          else
            break
          end
        end
        [nodes, tokens]
      end

      # expr    = mul ("+" mul | "-" mul)*
      def expr(tokens)
        left, tokens = mul(tokens)
        nodes = [left]
        while true do
          case tokens
          in [Token::Reserved['+'], *tokens]
            right, tokens = mul(tokens)
            nodes << Node::Add.new(left, right)
          in [Token::Reserved['-'], *tokens]
            right, tokens = mul(tokens)
            nodes << Node::Sub.new(left, right)
          else
            break
          end
        end
        [nodes, tokens]
      end
  end
end

