require 'byebug'
require_relative '9cc/token'
require_relative '9cc/node'
require_relative '9cc/generator'
require 'pp'
require 'optionparser'

class Program
  # @param user_input [String] Given program
  def initialize(user_input, opts)
    @user_input = user_input
    @options = opts
  end

  def pp(obj)
    PP.pp(obj, $stderr) if @options[:verbose]
  end

  def run
    tokens = Token.tokenize(@user_input)
    pp tokens
    nodes = Node::Parser.new(tokens).run
    pp nodes

    outputs = Generator.run(nodes, outputs: [])

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
