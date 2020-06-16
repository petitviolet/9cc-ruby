module Node
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

    def expect_next_token!(tokens, expected)
      next_token = tokens.shift
      if next_token != expected
        raise ArgumentError.new("next token must be '#{expected}', but '#{next_token}'. tokens = #{[next_token] + tokens}")
      end
    end

    def tokens_until(tokens, *expected_tokens)
      arr = []
      loop do
        t = tokens.shift
        break if expected_tokens.include?(t) || t.nil?
        arr << t
      end
      return arr
    end

    # primary    = num | ident ("(" unary (, unary)* ")")? | "(" expr ")"
    def primary(tokens)
      case tokens
        in [Token::Num[value], *tokens]
          [Node::Num.new(value), tokens]
        in [Token::Ident[name], *tokens]
          fcall_args = []
          case tokens
            in [Token::Reserved['('], Token::Reserved[')'], *tokens]
                [Node::Fcall.new(name, fcall_args), tokens]
            in [Token::Reserved['('], *tokens]
                loop do
                  case unary(tokens)
                    in [arg, [Token::Reserved[','], *tokens]]
                      fcall_args << Node::Farg.new(arg, fcall_args.size)
                    in [arg, [Token::Reserved[')'], *tokens]]
                      fcall_args << Node::Farg.new(arg, fcall_args.size)
                      return [Node::Fcall.new(name, fcall_args), tokens]
                    else
                      raise ArgumentError.new("next token must be ')'. tokens: #{tokens}, primary: #{primary(tokens)}")
                  end
                end
            else
              [Node::Lvar.new(name), tokens]
            end
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

    # assign     = equality ("="  (assign | "{" statement* "}"))?
    def assign(tokens)
      left, tokens = equality(tokens)
      case tokens
        in [Token::Reserved['='], *tokens]
          case tokens
            in [Token::Reserved['{'], *tokens]
              tokens = tokens_until(tokens, Token::Reserved.new('}'))
              right, tokens = statement(tokens)
            else
              right, tokens = assign(tokens)
          end
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

    # "if" "(" expr ")" statement ("else" statement)?
    def if_statement(tokens)
      expect_next_token!(tokens, Token::Reserved.new('if'))
      expect_next_token!(tokens, Token::Reserved.new('('))
      cond_tokens = tokens_until(tokens, Token::Reserved.new(')'))
      cond, _ = expr(cond_tokens)
      then_side_tokens = tokens_until(tokens, Token::Reserved.new('else'))
      then_side, _ = statement(then_side_tokens)
      else_side, t = statement(tokens)
      node = If.new(cond, then_side, else_side)
      return [node, t]
    end

    # block = "{" expr* "}"
    def block(tokens)
      expect_next_token!(tokens, Token::Reserved.new('{'))
      block_tokens = tokens_until(tokens, Token::Reserved.new('}'))
      nodes, _ = statement(block_tokens)
      node = Node::Block.new(nodes)
      [node, tokens]
    end

    # function = def ident "(" ident? ("," ident)* ")" block
    def function(tokens)
      expect_next_token!(tokens, Token::Reserved.new('def'))
      case tokens
        in [Token::Ident[name], *tokens]
          expect_next_token!(tokens, Token::Reserved.new('('))
          arg_tokens = tokens_until(tokens, Token::Reserved.new(')'))
          args = []
          loop do
            case arg_tokens
              in [Token::Ident[arg], *arg_tokens]
                args << arg
                case arg_tokens
                  in [Token::Reserved[','], *arg_tokens]
                    next
                  else
                    break
                end
              else
                raise ArgumentError.new("next token must be ')'. tokens: #{tokens}")
            end
          end
          body, rest_tokens = block(tokens)
          [Node::Fdef.new(name, args, body), rest_tokens]
        else
          raise ArgumentError.new("next token must be Ident. tokens: #{tokens}")
      end
    end

    # statement  = expr ";"?
    #              | block
    #              | function
    #              | "if" "(" expr ")" statement ("else" statement)?
    def statement(tokens)
      statements = []
      until tokens.empty?
        node = nil
        rest_tokens = nil

        case tokens
          in [Token::Reserved['if'], *]
            node, rest_tokens = if_statement(tokens)
          in [Token::Reserved['{'], *]
            node, rest_tokens = block(tokens)
          in [Token::Reserved['def'], *]
            node, rest_tokens = function(tokens)
          else
            expression_tokens = tokens_until(tokens, Token::Reserved.new(';'), Token::Eof, nil)
            node, rest_tokens = expr(expression_tokens)
        end

        case [node, rest_tokens]
          in [node, [Token::Eof]]
            statements << node
          return [statements, [Token::Eof]]
        else
          statements << node
        end
      end
      [statements, tokens]
    end

    # program    = statement*
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
