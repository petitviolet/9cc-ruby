require 'byebug'
require_relative '9cc/token'
require_relative '9cc/node'

class Program
  # @param user_input [String] Given program
  def initialize(user_input)
    @user_input = user_input
  end

  class Generator
    def self.run(nodes, assemblies = [])
      case Array(nodes)
      in []
        return []
      in [Node::Num[value], *rest]
        assemblies << "  push #{value}"
        run(rest, assemblies)
      else
        assemblies << "  pop rdi"
        assemblies << "  pop rax"

        case Array(nodes)
        in [Node::Add[left, right], *rest]
          run(left, assemblies)
          run(right, assemblies)
          assemblies << "  add rax, rdi"
          run(rest, assemblies)
        in [Node::Sub[left, right], *rest]
          run(left, assemblies)
          run(right, assemblies)
          assemblies << "  sub rax, rdi"
          run(rest, assemblies)
        in [Node::Mul[left, right], *rest]
          run(left, assemblies)
          run(right, assemblies)
          assemblies << "  imul rax, rdi"
          run(rest, assemblies)
        in [Node::Div[left, right], *rest]
          run(left, assemblies)
          run(right, assemblies)
          assemblies << "  cqo"
          assemblies << "  idiv rdi"
           run(rest, assemblies)
        end
      end

      assemblies << "  push rax"
    end
  end

  def run
    tokens = Token.tokenize(@user_input)
    pp tokens
    nodes = Node::Parser.new(tokens).run
    pp nodes
    outputs = []

    # Headers of assembly
    outputs << ".intel_syntax noprefix"
    outputs << ".global main"
    outputs << "main:"
    #Generator.run(nodes, outputs)
    case tokens
    in [Token::Num => num, *rest]
      # The first token must be a number
      outputs << "  mov rax, #{num.value}"
      tokens = rest
      while true
        case tokens
        in [Token::Reserved['+'], Token::Num => num, *rest]
          outputs << "  add rax, #{num.value}"
          tokens = rest
        in [Token::Reserved['-'], Token::Num => num, *rest]
          outputs << "  sub rax, #{num.value}"
          tokens = rest
        in [Token::Eof]
          outputs << "  ret"
          break
        end
      end
    else
      Token.error_at(@user_input, 0, "is not a number")
    end

    puts outputs.join("\n")
  end

end

Program.new(ARGV.first).run
