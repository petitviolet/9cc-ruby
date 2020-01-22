require 'rstructural'
require_relative './token'

module Node
  extend ADT

  def self.show(node)
    if node.is_a?(Enumerable)
      node.map { |s| show(s) }.join(" ")
    else
      node.show
    end
  end

  Add = data :lhs, :rhs do
    def show
      "#{Node.show(lhs)} + #{Node.show(rhs)}"
    end
  end
  Sub = data :lhs, :rhs do
    def show
      "#{Node.show(lhs)} - #{Node.show(rhs)}"
    end
  end
  Mul = data :lhs, :rhs do
    def show
      "#{Node.show(lhs)} * #{Node.show(rhs)}"
    end
  end
  Div = data :lhs, :rhs do
    def show
      "#{Node.show(lhs)} / #{Node.show(rhs)}"
    end
  end
  Lte = data :lhs, :rhs do # less-than-equal
    def show
      "#{Node.show(lhs)} <= #{Node.show(rhs)}"
    end
  end
  Lt = data :lhs, :rhs do # less-than
    def show
      "#{Node.show(lhs)} < #{Node.show(rhs)}"
    end
  end
  Eq = data :lhs, :rhs do # Equal
    def show
      "#{Node.show(lhs)} == #{Node.show(rhs)}"
    end
  end
  Neq = data :lhs, :rhs do # NotEqual
    def show
      "#{Node.show(lhs)} != #{Node.show(rhs)}"
    end
  end
  Num = data :value do # number
    def show
      value.to_s
    end
  end
  Lvar = data :name do # local variable
    def show
      name.to_str
    end
  end
  Assign = data :lhs, :rhs do
    def show
      "#{Node.show(lhs)} = #{Node.show(rhs)}"
    end
  end
  Ret = data :node do # return
    def show
      "return #{Node.show(node)}"
    end
  end

  class Parser

    # @param [Array<Token>] tokens
    def initialize(tokens)
      @tokens = tokens
    end

    def run
      case program(@tokens)
      in [nodes, [Token::Eof]]
        nodes
      in [nodes, rest] # else
        raise RuntimeError, <<~MSG
          tokens must be empty after run `program`.
            inputs: #{@tokens}
            nodes: #{nodes}
            tokens: #{rest}
        MSG
      end
    end

    private

      # primary    = num | ident | "(" expr ")"
      def primary(tokens)
        case tokens
        in [Token::Num[value], *tokens]
          [Node::Num.new(value), tokens]
        in [Token::Ident[name], *tokens]
          [Node::Lvar.new(name), tokens]
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

      # unary      = ("+" | "-")? primary
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

      # mul        = unary ("*" unary | "/" unary)*
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
        [nodes.flatten, tokens]
      end

      # add        = mul ("+" mul | "-" mul)*
      def add(tokens)
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
          else
            if nodes.empty?
              nodes << left
            end
            break
          end
        end
        [nodes.flatten, tokens]
      end

      # relational = add ("<" add | "<=" add | ">" add | ">=" add)*
      def relational(tokens)
        left, tokens = add(tokens)
        node = nil
        nodes = []
        while true do
          case tokens
          in [Token::Reserved['<'], *tokens]
            right, tokens = add(tokens)
            node = Node::Lt.new(left, right)
            nodes << node
            left = node
          in [Token::Reserved['<='], *tokens]
            right, tokens = add(tokens)
            node = Node::Lte.new(left, right)
            nodes << node
            left = node
          in [Token::Reserved['>'], *tokens]
            right, tokens = add(tokens)
            node = Node::Lt.new(right, left)
            nodes << node
            left = node
          in [Token::Reserved['>='], *tokens]
            right, tokens = add(tokens)
            node = Node::Lte.new(right, left)
            nodes << node
            left = node
          else
            if nodes.empty?
              nodes << left
            end
            break
          end
        end
        [nodes.flatten, tokens]
      end

      # equality   = relational ("==" relational | "!=" relational)*
      def equality(tokens)
        left, tokens = relational(tokens)
        node = nil
        nodes = []
        while true do
          case tokens
          in [Token::Reserved['=='], *tokens]
            right, tokens = add(tokens)
            node = Node::Eq.new(left, right)
            nodes << node
            left = node
          in [Token::Reserved['!='], *tokens]
            right, tokens = add(tokens)
            node = Node::Neq.new(left, right)
            nodes << node
            left = node
          else
            if nodes.empty?
              nodes << left
            end
            break
          end
        end
        [nodes.flatten, tokens]
      end

      # assign     = equality ("=" assign)?
      def assign(tokens)
        left, tokens = equality(tokens)
        case tokens
        in [Token::Reserved['='], *tokens]
          right, tokens = assign(tokens)
          case left.flatten
          in [Node::Lvar => lvar]
            node = Node::Assign.new(lvar, right)
            [node, tokens]
          else
            raise ArgumentError.new("invalid input. left tree of assignment must be Node::Lvar, but #{left}")
          end
        else
          [left, tokens]
        end
      end

      # expr       = return (primary)? | assign
      def expr(tokens)
        case tokens
        in [Token::Ret]
          [Node::Ret.new(nil), tokens]
        in [Token::Ret, *rest]
          node, tokens = primary(rest)
          [Node::Ret.new(node), tokens]
        else
          assign(tokens)
        end
      end

      # statement  = expr ";"?
      def statement(tokens)
        node, tokens = expr(tokens)
        case tokens
        in [Token::Reserved[';'], *tokens]
          [node, tokens]
        in [Token::Eof]
          [node, tokens]
        end
      end

      # program    = stmt*
      def program(tokens)
        node, tokens = statement(tokens)
        nodes = [node]
        until tokens.empty? do
          case tokens
          in [Token::Eof]
            return [nodes, [Token::Eof]]
          else
            node, tokens = statement(tokens)
            nodes << node
          end
        end
      end
  end
end

