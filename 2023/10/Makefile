TARGET := locations

FILE_SAMPLE := ../09/sample
FILE_INPUT  := ../09/input

.PHONY: location test clean

$(TARGET): $(TARGET).cpp Makefile
	$(CXX) -o $@ -fsanitize=address,undefined -std=c++20 -Wall -W -Wextra -O2 -pipe -march=native $<

test: $(TARGET) $(FILE_SAMPLE)
	@./$(TARGET) $(FILE_SAMPLE)

location: $(TARGET) $(FILE_INPUT)
	@./$(TARGET) $(FILE_INPUT)

clean:
	@rm -f $(TARGET)
