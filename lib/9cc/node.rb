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
        until tokens.empty? do
          case tokens
          in [Token::Reserved['*'], *tokens]
            right, tokens = unary(tokens)
            left = Node::Mul.new(left, right)
          in [Token::Reserved['/'], *tokens]
            right, tokens = unary(tokens)
            left = Node::Div.new(left, right)
          else
            break
          end
        end
        [left, tokens]
      end

      # add        = mul ("+" mul | "-" mul)*
      def add(tokens)
        left, tokens = mul(tokens)
        until tokens.empty? do
          case tokens
          in [Token::Reserved['+'], *tokens]
            right, tokens = mul(tokens)
            left = Node::Add.new(left, right)
          in [Token::Reserved['-'], *tokens]
            right, tokens = mul(tokens)
            left = Node::Sub.new(left, right)
          else
            break
          end
        end
        [left, tokens]
      end

      # relational = add ("<" add | "<=" add | ">" add | ">=" add)*
      def relational(tokens)
        left, tokens = add(tokens)
        nodes = []
        until tokens.empty? do
          case tokens
          in [Token::Reserved['<'], *tokens]
            right, tokens = add(tokens)
            left = Node::Lt.new(left, right)
          in [Token::Reserved['<='], *tokens]
            right, tokens = add(tokens)
            left = Node::Lte.new(left, right)
          in [Token::Reserved['>'], *tokens]
            right, tokens = add(tokens)
            left = Node::Lt.new(right, left)
          in [Token::Reserved['>='], *tokens]
            right, tokens = add(tokens)
            left = Node::Lte.new(right, left)
          else
            break
          end
        end
        [left, tokens]
      end

      # equality   = relational ("==" relational | "!=" relational)*
      def equality(tokens)
        left, tokens = relational(tokens)
        until tokens.empty? do
          case tokens
          in [Token::Reserved['=='], *tokens]
            right, tokens = add(tokens)
            left = Node::Eq.new(left, right)
          in [Token::Reserved['!='], *tokens]
            right, tokens = add(tokens)
            left = Node::Neq.new(left, right)
          else
            break
          end
        end
        [left, tokens]
      end

      # assign     = equality ("=" assign)?
      def assign(tokens)
        left, tokens = equality(tokens)
        case tokens
        in [Token::Reserved['='], *tokens]
          right, tokens = assign(tokens)
          case left
          in Node::Lvar => lvar
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
        in [Token::Ret] | [Token::Ret, Token::Eof]
          [Node::Ret.new(nil), [Token::Eof]]
        in [Token::Ret, *rest]
          node, tokens = primary(rest)
          [Node::Ret.new(node), [Token::Eof]]
        else
          assign(tokens)
        end
      end

      # statement  = expr ";"?
      def statement(tokens)
        statements = []
        rest = tokens
        until rest.empty?
          expression = []

          loop do
            case rest.shift
            in Token::Reserved[';'] | Token::Eof
              break
            in t
              expression << t
            end
          end
          node, t = expr(expression)
          case [node, t]
          in [node, [Token::Eof]]
            statements << node
            return [statements, [Token::Eof]]
          else
            statements << node
          end
        end
        [statements, tokens]
      end

      # program    = stmt*
      def program(tokens)
        node, tokens = statement(tokens)
        nodes = [node]
        return [nodes, [Token::Eof]] if tokens.empty?
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

