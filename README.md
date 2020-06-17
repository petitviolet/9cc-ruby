# A tiny language compiler written in Ruby

https://www.sigbus.info/compilerbook

## What language looks like

See [test.sh](./test.sh).

## How to run

Docker image for this repository is available on [petitviolet:9cc-ruby](https://hub.docker.com/r/petitviolet/9cc-ruby) in docker hub.

```console
# Run all test
$ make docker/test

# Run oneshot test. ARG: [expected program]
$ make docker/try ARG="3 'def add(i, j) { i + j }; add(1, 2)'"
$ make docker/try ARG="3 'def add(i, j) { i + j }; add(1, 2)' -v" # verbose option
```

```console
$ make docker/try ARG="16 '1 + 2 + 3'"
docker run --rm -v $PWD:/9cc -w /9cc petitviolet/9cc-ruby:latest sh -c "./test.sh 16 '1 + 2 + 3'"
[2020-06-17 12:57:46.045 UTC]NG! 1 + 2 + 3 => 16 expected, but got 6
make: *** [docker/try] Error 1

$ make docker/try ARG="16 '1 + 2 + 3' -v"
docker run --rm -v $PWD:/9cc -w /9cc petitviolet/9cc-ruby:latest sh -c "./test.sh 16 '1 + 2 + 3' -v"
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
  push r14 # prologue
  push r15
  push rbp
  mov rbp, rsp
  sub rsp, 0 # ^^^ prologue
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
  pop r15
  pop r14
  ret # ^^^ epilogue
===
[2020-06-17 12:57:51.881 UTC]NG! 1 + 2 + 3 => 16 expected, but got 6
make: *** [docker/try] Error 1
```
