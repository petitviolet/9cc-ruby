require 'rstructural'
require_relative './node'

class Generator
  # @param statements [Array<Array<Node>>]
  # @param outputs [Array]
  # @return [Array<String>]
  def self.run(statements, outputs: [], verbose: false)
    generator = new(outputs, verbose: verbose)
    generator.run(statements)
  end

  def initialize(outputs, verbose: false)
    @outputs = outputs
    @lvar_count = 1
    @verbose = verbose
  end

  def run(statements)
    statements.each do |nodes|
      @outputs << "  # statement: #{Node.show(nodes)}" if @verbose
      is_return = self.run_statement(nodes)
      @outputs << "  # ^^^ statement: #{Node.show(nodes)}" if @verbose
      @outputs << "  pop rax"
      break if is_return
    end

    @outputs = @outputs + epilogue
    @outputs = prologue + @outputs
    @outputs = headers + @outputs
    @outputs
  end

  private

    # @return [Boolean] if a statement finishes with `return`
    def run_statement(nodes)
      case Array(nodes).flatten
      in []
        return false
      in [Node::Ret[node], *rest]
        @outputs << "  # return!" if @verbose
        if node.nil?
          return true
        else
          run_statement(node)
          return true
        end
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
      in [Node::If[cond, then_side, else_side]]
        label_number = next_label_number
        run_statement(cond)
        @outputs << "  pop rax"
        @outputs << "  cmp rax, 0"
        @outputs << "  je .Lelse#{label_number}"
        run_statement(then_side)
        @outputs << "  jmp .Lend#{label_number}"
        @outputs << ".Lelse#{label_number}:"
        run_statement(else_side)
        @outputs << ".Lend#{label_number}:"
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
      false
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
      if @verbose
        arr << "  push rbp"
        arr << "  mov rbp, rsp"
        arr << "  sub rsp, #{(@lvar_count - 1) * 8}"
      else
        arr << "  push rbp"
        arr << "  mov rbp, rsp"
        arr << "  sub rsp, #{(@lvar_count - 1) * 8}"
      end
      arr
    end

    def epilogue
      arr = []
      if @verbose
        arr << "  mov rsp, rbp # epilogue"
        arr << "  pop rbp"
        arr << "  ret # ^^^ epilogue"
      else
        arr << "  mov rsp, rbp"
        arr << "  pop rbp"
        arr << "  ret"
      end
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
      if @verbose
        @outputs << "  mov rax, rbp"
        @outputs << "  sub rax, #{offset} # #{node.name}"
        @outputs << "  push rax"
      else
        @outputs << "  mov rax, rbp"
        @outputs << "  sub rax, #{offset}"
        @outputs << "  push rax"
      end
    end

    def next_label_number
      @label_cnt ||= 0
      @label_cnt += 1
      return @label_cnt
    end
end

