#!/bin/bash

try() {
  expected="$1"
  input="$2"
  option="$3"

  rm -f tmp tmp.s
  rbenv exec ruby -W0 lib/9cc.rb "$input" $option > tmp.s
  # ./9cc "$input" > tmp.s
  gcc -o tmp tmp.s
  if [ -n "$option" ]; then
    echo "==='$option'"
    cat ./tmp.s
    echo "==="
  fi
  ./tmp
  actual="$?"

  if [ "$actual" = "$expected" ]; then
    logging "OK! $input => $actual"
  else
    logging "NG! $input => $expected expected, but got $actual"
    exit 1
  fi
}

logging() {
  echo "[$(now)]$1"
}

now() {
  date +"%Y-%m-%d %H:%M:%S.%3N %Z"
}

run_test() {
  rbenv exec ruby -v

  logging "start"

  logging 'integer ==='
  try 0 '0'
  try 42 '42'
  logging 'basic calculation ==='
  try 2 '0 + 2'
  try 47 '5+6*7'
  try 15 '5*(9-6)'
  try 15 '5 * ( 9 - 6 )'
  try 4 '(3+5)/2'
  try 23 '(1 + (2 + 3) * (4 + 5)) / 2'
  try 10 '-10+20'
  logging 'comparison ==='
  try 1 '1 <= 2'
  try 1 '2 <= 2'
  try 1 '1 < 2'
  try 0 '1 > 2'
  try 0 '1 >= 2'
  try 1 '2 >= 2'
  try 1 '1 != 2'
  try 0 '2 != 2'
  try 0 '1 == 2'
  try 1 '2 == 2'
  logging 'local vars ==='
  try 5 'a = 5; a'
  try 5 'a = 2; a + 3'
  try 5 'a = 2; b = 7; b - a'
  try 8 'hoge = 2; foo = 3; bar = 4; (foo * bar / 2) + hoge'
  try 16 'hoge = 2; foo = 3; bar = 4; baz = (foo * bar / 2) + hoge; baz + baz'
  logging 'return ==='
  try 5 'return 5'
  try 5 'return 5; return 10'
  try 5 '5; return'
  try 6 'return (1 + 2 + 3)'
  try 6 '1 + 2 + 3; return'
  try 6 '1 + 2; return (1 + 2 + 3); 7 + 8;'
  try 3 '1 + 2; return; 7 + 8;'
  logging 'if - else ==='
  try 5 'if (1 > 0) 5 else 3'
  try 3 'if (1 < 0) 5 else 3'
  try 5 'if (1 + 2 + 3 == 6) 5 else 3'
  logging 'block ==='
  try 3 '{ 1 + 2 }'
  try 21 '{ a = 1 + 2; b = 3 + 4; a * b }'
  try 21 'a = { 1 + 2 }; b = { 3 + 4 }; a * b'
  logging 'function def & call ==='
  try 5 'def add(i, j) { i + j }; add(2, 3)'
  try 6 'def mul(i, j) { i * j }; mul(2, 3)'
  try 6 'def mul(i, j) { i * j }; a = 2; b = { 1 + 2 };  mul(a, b)'

  logging "OK"
}

if [ $# -eq 0 ]; then
  run_test
else
  try "$@"
fi

