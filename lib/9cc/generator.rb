require 'rstructural'
require_relative './node'

class Generator
  ARG_REGS = %w[rdi rsi rdx rcx r8 r9]
  # @param statements [Array<Array<Node>>]
  # @param outputs [Array]
  # @return [Array<String>]
  def self.run(statements, outputs: [], verbose: false)
    generator = new(outputs, verbose: verbose)
    generator.run(statements)
  end

  def initialize(outputs, verbose: false)
    @outputs = outputs
    @functions = []
    @lvar_count = 1
    @verbose = verbose
  end

  def run(statements)
    statements.each do |nodes|
      @outputs << "  # statement: #{Node.show(nodes)}" if @verbose
      is_return = self.run_statement(nodes, @outputs)
      @outputs << "  # ^^^ statement: #{Node.show(nodes)}" if @verbose
      @outputs << "  pop rax"
      break if is_return
    end

    @functions += generate_add
    headers + prologue((@lvar_count - 1) * 8) + @outputs + epilogue + @functions
  end

  private

    # @return [Boolean] if a statement finishes with `return`
    def run_statement(nodes, acc)
      case Array(nodes).flatten
      in []
        return false
      in [Node::Ret[node], *rest]
        acc << "  # return!" if @verbose
        if node.nil?
          return true
        else
          run_statement(node, acc)
          return true
        end
      in [Node::Fcall[func_name, func_args] => fcall, *rest]
        # run_statement(args, acc) unless args.nil?
        acc << "  # function #{fcall.show}" if @verbose
        func_args.each do |func_arg|
          run_statement(func_arg.node, acc)
        end
        func_args.each do |func_arg|
          acc << "  pop #{ARG_REGS[func_arg.idx]}"
        end

        acc << "  mov rax, 0"
        acc << "  call #{func_name}"
        acc << "  push rax"
        acc << "  # ^^^ function #{fcall.show}" if @verbose

        return run_statement(rest, acc)
      in [Node::Num[value], *rest]
        acc << "  push #{value}"
        return run_statement(rest, acc)
      in [Node::Lvar => node, *rest]
        generate_lvar(node)
        acc << "  pop rax"
        acc << "  mov rax, [rax]"
        acc << "  push rax"
        return run_statement(rest, acc)
      in [Node::Assign[left, right], *rest]
        generate_lvar(left)
        run_statement(right, acc)
        acc << "  pop rdi"
        acc << "  pop rax"
        acc << "  mov [rax], rdi"
        acc << "  push rdi"
        return run_statement(rest, acc)
      in [Node::If[cond, then_side, else_side]]
        label_number = next_label_number
        run_statement(cond, acc)
        acc << "  pop rax"
        acc << "  cmp rax, 0"
        acc << "  je .Lelse#{label_number}"
        run_statement(then_side, acc)
        acc << "  jmp .Lend#{label_number}"
        acc << ".Lelse#{label_number}:"
        run_statement(else_side, acc)
        acc << ".Lend#{label_number}:"
        return run_statement(rest, acc)
      else
        run_left_and_right = ->(left, right, rest, &block) do
          run_statement(left, acc)
          run_statement(right, acc)
          acc << "  pop rdi"
          acc << "  pop rax"
          block.call
          run_statement(rest, acc)
        end

        case Array(nodes).flatten
        in [Node::Eq[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            acc << "  cmp rax, rdi"
            acc << "  sete al"
            acc << "  movzb rax, al"
          end
        in [Node::Neq[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            acc << "  cmp rax, rdi"
            acc << "  setne al"
            acc << "  movzb rax, al"
          end
        in [Node::Lt[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            acc << "  cmp rax, rdi"
            acc << "  setl al"
            acc << "  movzb rax, al"
          end
        in [Node::Lte[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            acc << "  cmp rax, rdi"
            acc << "  setle al"
            acc << "  movzb rax, al"
          end
        in [Node::Add[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            acc << "  add rax, rdi"
          end
        in [Node::Sub[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            acc << "  sub rax, rdi"
          end
        in [Node::Mul[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            acc << "  imul rax, rdi"
          end
        in [Node::Div[left, right], *rest]
          run_left_and_right.call(left, right, rest) do
            acc << "  cqo"
            acc << "  idiv rdi"
          end
        end
      end

      acc << "  push rax"
      false
    end

    def headers
      arr = []
      arr << ".intel_syntax noprefix # headers"
      arr << ".global main"
      arr << "main:"
      arr
    end

    def prologue(offset)
      arr = []
      if @verbose
        arr << "  push r14 # prologue"
        arr << "  push r15"
        arr << "  push rbp"
        arr << "  mov rbp, rsp"
        # arr << "  sub rsp, #{offset} # ^^^ prologue"
      else
        arr << "  push r14"
        arr << "  push r15"
        arr << "  push rbp"
        arr << "  mov rbp, rsp"
        # arr << "  sub rsp, #{offset}"
      end
      arr
    end

    def epilogue
      arr = []
      if @verbose
        arr << "  mov rsp, rbp # epilogue"
        arr << "  pop rbp"
        arr << "  pop r15"
        arr << "  pop r14"
        arr << "  ret # ^^^ epilogue"
      else
        arr << "  mov rsp, rbp"
        arr << "  pop rbp"
        arr << "  pop r15"
        arr << "  pop r14"
        arr << "  ret"
      end
      arr
    end

    def println
      arr = []
      arr << ""
      arr << "println:"
      arr << "  push    rax"
      arr << "  mov     rax, 4"
      arr << "  mov     rbx, 1"
      arr << "  mov     rcx, rsp"
      arr << "  mov     rdx, 1"
      arr << "  int     0x80"
      arr << "  mov     rax, 0x0a"
      arr << "  pop     rax"
      arr << "  ret"
      arr
    end

    def generate_add
      arr = []
      arr << ""
      arr << ".text"
      arr << ".global add"
      arr << "add:"
      arr += prologue(16)
      arr << "  add #{ARG_REGS[0]}, #{ARG_REGS[1]}"
      arr << "  mov rax, #{ARG_REGS[0]}"
      arr += epilogue
      arr
    end

    def generate_function(name, *args)

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

