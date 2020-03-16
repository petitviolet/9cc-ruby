# A tiny language compiler written in Ruby

https://www.sigbus.info/compilerbook

## The language looks like

See [test.sh](./test.sh).

## How to run

Docker image for this repository is [petitviolet:9cc-ruby](https://hub.docker.com/r/petitviolet/9cc-ruby) on docker hub.

```console
$ docker run --rm -v $PWD:/9cc -w /9cc petitviolet/9cc-ruby sh -c "./test.sh 8 'if (2 > 1) 16 else 8'"
$ docker run --rm -v $PWD:/9cc -w /9cc petitviolet/9cc-ruby sh -c "./test.sh"
```

```console
$ docker run -tid -v $PWD:/9cc -w /9cc --name 9cc petitviolet/9cc-ruby bash
$ docker exec -it 9cc sh -c "./test.sh 16 '1 + 2 + 3' -v"

[Token::Num(value: 1),
 Token::Reserved(char: +),
 Token::Num(value: 2),
 Token::Reserved(char: +),
 Token::Num(value: 3),
 Token::Eof]
[[Node::Add(lhs: Node::Add(lhs: Node::Num(value: 1), rhs: Node::Num(value: 2)), rhs: Node::Num(value: 3))]]
==='-v'
.intel_syntax noprefix # headers
.global main
main:
  push rbp
  mov rbp, rsp
  sub rsp, 0
  # statement: 1 + 2 + 3
  push 1
  push 2
  pop rdi
  pop rax
  add rax, rdi
  push rax
  push 3
  pop rdi
  pop rax
  add rax, rdi
  push rax
  # ^^^ statement: 1 + 2 + 3
  pop rax
  mov rsp, rbp # epilogue
  pop rbp
  ret # ^^^ epilogue
===
[2020-03-15 14:01:13.942 UTC]NG! 1 + 2 + 3 => 16 expected, but got 6
```
