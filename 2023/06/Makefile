.PHONY: sum test clean

engine-parts: engine-parts.cpp
	$(CXX) -o $@ -fsanitize=address,undefined -std=c++20 -Wall -W -Wextra -O2 -pipe -march=native $<

test: engine-parts ../05/sample
	@./engine-parts ../05/sample
	@echo "Result should be 467835"

sum: engine-parts ../05/input
	@./engine-parts ../05/input

clean:
	@rm -f engine-parts
