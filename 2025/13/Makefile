#CXXFLAGS := -std=c++23 -Og -ggdb -Wall -W -Wextra -fsanitize=address,undefined -pipe -march=native
CXXFLAGS := -std=c++23 -O3 -Wall -W -Wextra -fsanitize=address,undefined -pipe -march=native

TARGET := tachyon

all: $(TARGET)

$(TARGET): $(TARGET).cpp

clean:
	rm -f $(TARGET)

.PHONY: all
