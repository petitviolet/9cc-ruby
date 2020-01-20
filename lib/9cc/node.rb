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
        nodes
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
        in [Token::Num[value], *tokens]
          [Node::Num.new(value), tokens]
        in [Token::Reserved['('], *tokens]
          case expr(tokens)
          in [node, [Token::Reserved[')'], *tokens]]
            return [node, tokens]
          else
            raise ArgumentError.new("next token must be ')'. tokens: #{tokens}, expr: #{expr(tokens)}")
          end
        else
          raise ArgumentError.new("invalid input. tokens: #{tokens}")
        end
      end

      # unary   = ("+" | "-")? primary
      def unary(tokens)
        case tokens
        in [Token::Reserved['+'], *rest]
          primary(rest)
        in [Token::Reserved['-'], *rest]
          value, rest = primary(rest)
          [Node::Sub.new(Node::Num.new(0), value), rest]
        in [*rest]
          primary(rest)
        end
      end

      # mul     = unary ("*" unary | "/" unary)*
      def mul(tokens)
        left, tokens = unary(tokens)
        nodes = []
        while true do
          case tokens
          in [Token::Reserved['*'], *tokens]
            right, tokens = unary(tokens)
            node = Node::Mul.new(left, right)
            nodes << node
            left = node
          in [Token::Reserved['/'], *tokens]
            right, tokens = unary(tokens)
            node = Node::Div.new(left, right)
            nodes << node
            left = node
          else
            if nodes.empty?
              nodes << left
            end
            break
          end
        end
        [nodes, tokens]
      end

      # expr    = mul ("+" mul | "-" mul)*
      def expr(tokens)
        left, tokens = mul(tokens)
        node = nil
        nodes = []
        while true do
          case tokens
          in [Token::Reserved['+'], *tokens]
            right, tokens = mul(tokens)
            node = Node::Add.new(left, right)
            nodes << node
            left = node
          in [Token::Reserved['-'], *tokens]
            right, tokens = mul(tokens)
            node = Node::Sub.new(left, right)
            nodes << node
            left = node
          in [Token::Eof]
            return [Array(left).first, [Token::Eof]]
          else
            if nodes.empty?
              nodes << left
            end
            break
          end
        end
        [nodes, tokens]
      end
  end
end

