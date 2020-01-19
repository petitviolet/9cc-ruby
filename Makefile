CFLAGS=-std=c11 -g -static

9cc: 9cc.c

test: 9cc
	./test.sh

docker/test:
	docker run --rm -v $$PWD:/9cc -w /9cc petitviolet/9cc-ruby:latest ./test.sh

clean:
	rm -f 9cc *.o *~ tmp*

.PHONY: test clean
