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
  try 0 0
  try 42 42
  try 47 '5+6*7'
  try 15 '5*(9-6)'
  try 4 '(3+5)/2'
  try 23 '(1 + (2 + 3) * (4 + 5)) / 2'
  try 10 '-10+20'
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
  try 5 'a = 2; b = 3; a + b'
  logging "OK"
}

if [ $# -eq 0 ]; then
  run_test
else
  try $1 $2
fi

