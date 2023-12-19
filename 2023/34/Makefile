TARGET := keepwarm

FILE_SAMPLE := sample
FILE_INPUT  := input

.PHONY: solution test clean

#CXX=clang++

$(TARGET): $(TARGET).cpp Makefile
#	$(CXX) -o $@ -stdlib=libc++ -fsanitize=address,undefined -std=c++20 -Wall -W -Wextra -O2 -pipe -march=native $<
	$(CXX) -o $@ -std=c++20 -Wall -W -Wextra -O3 -pipe -march=native $<

test: $(TARGET) $(FILE_SAMPLE)
	@./$(TARGET) $(FILE_SAMPLE)

solution: $(TARGET) $(FILE_INPUT)
	@./$(TARGET) $(FILE_INPUT)

clean:
	@rm -f $(TARGET)
