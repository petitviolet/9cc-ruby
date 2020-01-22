CFLAGS=-std=c11 -g -static
ARG=

9cc: 9cc.c

test: 9cc
	./test.sh

docker/test:
	docker run --rm -v $$PWD:/9cc -w /9cc petitviolet/9cc-ruby:latest ./test.sh

# make docker/try ARG='5 "return ( 1 + 4 ); 3" -v'
docker/try:
	docker exec -it 9cc sh -c './test.sh $(ARG)'

# make run ARG="1 + 2 + 3 - 4"
run:
	ruby -W0 lib/9cc.rb $(ARG)

clean:
	rm -f 9cc *.o *~ tmp*

.PHONY: test clean
