require 'byebug'
require_relative '9cc/token'
require_relative '9cc/node'
require 'pp'

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
        return run(rest, assemblies)
      else

        case Array(nodes)
        in [Node::Add[left, right], *rest]
          run(left, assemblies)
          run(right, assemblies)
          assemblies << "  pop rdi"
          assemblies << "  pop rax"
          assemblies << "  add rax, rdi"
          run(rest, assemblies)
        in [Node::Sub[left, right], *rest]
          run(left, assemblies)
          run(right, assemblies)
          assemblies << "  pop rdi"
          assemblies << "  pop rax"
          assemblies << "  sub rax, rdi"
          run(rest, assemblies)
        in [Node::Mul[left, right], *rest]
          run(left, assemblies)
          run(right, assemblies)
          assemblies << "  pop rdi"
          assemblies << "  pop rax"
          assemblies << "  imul rax, rdi"
          run(rest, assemblies)
        in [Node::Div[left, right], *rest]
          run(left, assemblies)
          run(right, assemblies)
          assemblies << "  pop rdi"
          assemblies << "  pop rax"
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
    nodes = Node::Parser.new(tokens).run
    # PP.pp(tokens, $stderr)
    # PP.pp(nodes, $stderr)
    outputs = []

    # Headers of assembly
    outputs << ".intel_syntax noprefix"
    outputs << ".global main"
    outputs << "main:"
    Generator.run(nodes, outputs)

    outputs << "  pop rax"
    outputs << "  ret"
    puts outputs.join("\n")
  end

end

Program.new(ARGV.first).run
