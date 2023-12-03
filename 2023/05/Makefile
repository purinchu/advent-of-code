.PHONY: sum test

engine-parts: engine-parts.cpp
	$(CXX) -o $@ -std=c++20 -Wall -W -Wextra -O2 -pipe -march=native $<

test: engine-parts sample
	@./engine-parts sample
	@echo "Result should be 4361"

# 537066 is apparently too low
sum: engine-parts input
	@./engine-parts input
