require 'rstructural'
require_relative './node'

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

