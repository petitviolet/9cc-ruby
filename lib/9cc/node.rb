require 'rstructural'
require_relative './token'
require_relative './node/parser'

module Node
  extend ADT

  def self.show(node)
    if node.is_a?(Enumerable)
      node.map { |s| show(s) }.join("; ")
    else
      node.show
    end
  end

  If = data :cond, :then_side, :else_side do
    def show
      "if (#{Node.show(cond)}) { #{Node.show(then_side)} } else { #{Node.show(else_side)} }"
    end
  end

  Add = data :lhs, :rhs do
    def show
      "#{Node.show(lhs)} + #{Node.show(rhs)}"
    end
  end
  Sub = data :lhs, :rhs do
    def show
      "#{Node.show(lhs)} - #{Node.show(rhs)}"
    end
  end
  Mul = data :lhs, :rhs do
    def show
      "#{Node.show(lhs)} * #{Node.show(rhs)}"
    end
  end
  Div = data :lhs, :rhs do
    def show
      "#{Node.show(lhs)} / #{Node.show(rhs)}"
    end
  end
  Lte = data :lhs, :rhs do # less-than-equal
    def show
      "#{Node.show(lhs)} <= #{Node.show(rhs)}"
    end
  end
  Lt = data :lhs, :rhs do # less-than
    def show
      "#{Node.show(lhs)} < #{Node.show(rhs)}"
    end
  end
  Eq = data :lhs, :rhs do # Equal
    def show
      "#{Node.show(lhs)} == #{Node.show(rhs)}"
    end
  end
  Neq = data :lhs, :rhs do # NotEqual
    def show
      "#{Node.show(lhs)} != #{Node.show(rhs)}"
    end
  end
  Num = data :value do # number
    def show
      value.to_s
    end
  end
  Lvar = data :name do # local variable
    def show
      name.to_s
    end
  end
  Assign = data :lhs, :rhs do
    def show
      "#{Node.show(lhs)} = #{Node.show(rhs)}"
    end
  end
  Ret = data :node do # return
    def show
      "return #{Node.show(node)}"
    end
  end
end

