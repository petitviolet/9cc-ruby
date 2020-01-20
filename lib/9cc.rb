require 'byebug'
require_relative '9cc/token'
require_relative '9cc/node'
require 'pp'
require 'optionparser'

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

  def run(options)
    tokens = Token.tokenize(@user_input)
    nodes = Node::Parser.new(tokens).run
    if options[:verbose]
      PP.pp(tokens, $stderr)
      PP.pp(nodes, $stderr)
    end
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
    args = parser.parse(@argv)
    expression = args.shift

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

Program.new(args[:expression]).run(opts)
