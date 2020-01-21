require 'rstructural'
require_relative './node'

class Generator
  def self.run(statements, outputs)
    generator = new(outputs)

    outputs << "  push rbp"
    outputs << "  mov rbp, rsp"
    outputs << "  sub rsp, 208"
    statements.each do |nodes|
      generator.run(nodes)
      outputs << "  pop rax"
    end
    outputs << "  mov rsp, rbp"
    outputs << "  pop rbp"
    outputs << "  ret"

    outputs
  end

  def initialize(outputs)
    @outputs = outputs
    @lvar_counter = 1
  end

  # @param node [Node::Lvar]
  def generate_lvar(node)
    @lvars ||= {}
    offset = @lvars[node.name]
    if offset.nil?
      offset = @lvar_counter * 8
      @lvar_counter += 1
      @lvars[node.name] = offset
    end
    @outputs << "  mov rax, rbp"
    @outputs << "  sub rax, #{offset} # #{node.name}"
    @outputs << "  push rax"
  end

  def run(nodes)
    case Array(nodes).flatten
    in []
      return []
    in [Node::Num[value], *rest]
      @outputs << "  push #{value}"
      return run(rest)
    in [Node::Lvar => node, *rest]
      generate_lvar(node)
      @outputs << "  pop rax"
      @outputs << "  mov rax, [rax]"
      @outputs << "  push rax"
      return run(rest)
    in [Node::Assign[left, right], *rest]
      generate_lvar(left)
      run(right)
      @outputs << "  pop rdi"
      @outputs << "  pop rax"
      @outputs << "  mov [rax], rdi"
      @outputs << "  push rdi"
      return run(rest)
    else
      run_left_and_right = ->(left, right, rest, &block) do
        run(left)
        run(right)
        @outputs << "  pop rdi"
        @outputs << "  pop rax"
        block.call
        run(rest)
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
end

