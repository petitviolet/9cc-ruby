require 'rstructural'
require_relative './node'

class Generator
  def self.run(nodes, outputs)
    new(outputs).run(nodes)
  end

  def initialize(outputs)
    @outputs = outputs
  end

  def run(nodes)
    case Array(nodes).flatten
    in []
      return []
    in [Node::Num[value], *rest]
      @outputs << "  push #{value}"
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

