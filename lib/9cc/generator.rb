require 'rstructural'
require_relative './node'

class Generator
  # @param statements [Array<Array<Node>>]
  # @param outputs [Array]
  # @return [Array<String>]
  def self.run(statements, outputs: [])
    generator = new(outputs)
    generator.run(statements)
  end

  def initialize(outputs)
    @outputs = outputs
    @lvar_count = 1
  end

  def run(statements)
    statements.each do |nodes|
      self.run_statement(nodes)
      @outputs << "  pop rax"
    end

    @outputs = @outputs + epilogue
    @outputs = prologue + @outputs
    @outputs = headers + @outputs
    @outputs
  end

  private

    def run_statement(nodes)
      case Array(nodes).flatten
      in []
        return []
      in [Node::Num[value], *rest]
        @outputs << "  push #{value}"
        return run_statement(rest)
      in [Node::Lvar => node, *rest]
        generate_lvar(node)
        @outputs << "  pop rax"
        @outputs << "  mov rax, [rax]"
        @outputs << "  push rax"
        return run_statement(rest)
      in [Node::Assign[left, right], *rest]
        generate_lvar(left)
        run_statement(right)
        @outputs << "  pop rdi"
        @outputs << "  pop rax"
        @outputs << "  mov [rax], rdi"
        @outputs << "  push rdi"
        return run_statement(rest)
      else
        run_left_and_right = ->(left, right, rest, &block) do
          run_statement(left)
          run_statement(right)
          @outputs << "  pop rdi"
          @outputs << "  pop rax"
          block.call
          run_statement(rest)
        end

        case Array(nodes).flatten
        in [Node::Eq[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            @outputs << "  cmp rax, rdi"
            @outputs << "  sete al"
            @outputs << "  movzb rax, al"
          end
        in [Node::Neq[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            @outputs << "  cmp rax, rdi"
            @outputs << "  setne al"
            @outputs << "  movzb rax, al"
          end
        in [Node::Lt[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            @outputs << "  cmp rax, rdi"
            @outputs << "  setl al"
            @outputs << "  movzb rax, al"
          end
        in [Node::Lte[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            @outputs << "  cmp rax, rdi"
            @outputs << "  setle al"
            @outputs << "  movzb rax, al"
          end
        in [Node::Add[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            @outputs << "  add rax, rdi"
          end
        in [Node::Sub[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            @outputs << "  sub rax, rdi"
          end
        in [Node::Mul[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            @outputs << "  imul rax, rdi"
          end
        in [Node::Div[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            @outputs << "  cqo"
            @outputs << "  idiv rdi"
          end
        end
      end

      @outputs << "  push rax"
    end

    def headers
      arr = []
      arr << ".intel_syntax noprefix # headers"
      arr << ".global main"
      arr << "main:"
      arr
    end

    def prologue
      arr = []
      arr << "  push rbp # headers"
      arr << "  mov rbp, rsp"
      arr << "  sub rsp, #{(@lvar_count - 1) * 8} # ^^^ headers"
      arr
    end

    def epilogue
      arr = []
      arr << "  mov rsp, rbp # epilogue"
      arr << "  pop rbp"
      arr << "  ret # ^^^ epilogue"
    end

    # @param node [Node::Lvar]
    def generate_lvar(node)
      @lvars ||= {}
      offset = @lvars[node.name]
      if offset.nil?
        offset = @lvar_count * 8
        @lvar_count += 1
        @lvars[node.name] = offset
      end
      @outputs << "  mov rax, rbp"
      @outputs << "  sub rax, #{offset} # #{node.name}"
      @outputs << "  push rax"
    end
end

