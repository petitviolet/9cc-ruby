require 'byebug'
require_relative '9cc/token'
require_relative '9cc/node'
require 'pp'
require 'optionparser'

class Program
  # @param user_input [String] Given program
  def initialize(user_input, opts)
    @user_input = user_input
    @options = opts
  end

  class Generator
    def self.run(nodes, assemblies = [])
      case Array(nodes).flatten
      in []
        return []
      in [Node::Num[value], *rest]
        assemblies << "  push #{value}"
        return run(rest, assemblies)
      else
        run_left_and_right = ->(left, right, rest, &block) do
          run(left, assemblies)
          run(right, assemblies)
          assemblies << "  pop rdi"
          assemblies << "  pop rax"
          block.call
          run(rest, assemblies)
        end

        case Array(nodes).flatten
        in [Node::Eq[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            assemblies << "  cmp rax, rdi"
            assemblies << "  sete al"
            assemblies << "  movzb rax, al"
          end
        in [Node::Neq[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            assemblies << "  cmp rax, rdi"
            assemblies << "  setne al"
            assemblies << "  movzb rax, al"
          end
        in [Node::Lt[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            assemblies << "  cmp rax, rdi"
            assemblies << "  setl al"
            assemblies << "  movzb rax, al"
          end
        in [Node::Lte[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            assemblies << "  cmp rax, rdi"
            assemblies << "  setle al"
            assemblies << "  movzb rax, al"
          end
        in [Node::Add[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            assemblies << "  add rax, rdi"
          end
        in [Node::Sub[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            assemblies << "  sub rax, rdi"
          end
        in [Node::Mul[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            assemblies << "  imul rax, rdi"
          end
        in [Node::Div[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            assemblies << "  cqo"
            assemblies << "  idiv rdi"
          end
        end
      end

      assemblies << "  push rax"
    end
  end

  def pp(obj)
    PP.pp(obj, $stderr) if @options[:verbose]
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
    Generator.run(nodes, outputs)

    outputs << "  pop rax"
    outputs << "  ret"
    puts outputs.join("\n")
  end

end


class CLI
  def initialize(argv = ARGV)
    @argv = argv
    @opts = {
      verbose: false,
    }
  end

  def inputs
    expression = @argv.shift
    parser.parse(@argv)

    show_usage if expression.empty?

    [{expression: expression}, @opts]
  rescue => e
    show_usage(e)
  end

  private

    def parser
      return @parser if @parser

      opt = OptionParser.new
      opt.banner = "Usage: #{__FILE__} <expression> [options]"
      opt.on_head(
        "arguments:",
        "#{opt.summary_indent}expression: whatever you want to generate assembly",
        )
      opt.separator('options:')
      opt.on('-h', '--help', 'show this help') { |_| show_usage }
      opt.on('-v', '--[no-]verbose', 'show debug logs') { |v| @opts[:verbose] = v }
      @parser = opt
    end

    def show_usage(error = nil)
      puts "error: #{error.message}\n" if error
      puts <<~EOF
        #{parser.to_s}
      EOF
      exit 1
    end
end

args, opts = CLI.new.inputs

Program.new(args[:expression], opts).run
