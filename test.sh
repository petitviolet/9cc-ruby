#!/bin/bash
try() {
  expected="$1"
  input="$2"

  rbenv exec ruby -W0 lib/9cc.rb "$input" > tmp.s
  # ./9cc "$input" > tmp.s
  gcc -o tmp tmp.s
  ./tmp
  actual="$?"

  if [ "$actual" = "$expected" ]; then
    echo "$input => $actual"
  else
    echo "$input => $expected expected, but got $actual"
    exit 1
  fi
}

run_test() {
  try 0 0
  try 42 42
  echo OK
}

if [ $# -eq 0 ]; then
  run_test
else
  try $1 $2
fi

