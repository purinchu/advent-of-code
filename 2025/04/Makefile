CXXFLAGS := -std=c++23 -O2 -Wall -W -Wextra -fsanitize=address,undefined -pipe -march=native

TARGET := id

all: $(TARGET)

$(TARGET): $(TARGET).cpp

clean:
	rm -f $(TARGET)

.PHONY: all
