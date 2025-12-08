#CXXFLAGS := -std=c++23 -Og -ggdb -Wall -W -Wextra -fsanitize=address,undefined -pipe -march=native
CXXFLAGS := -std=c++23 -static -O3 -Wall -W -Wextra -pipe -march=native -fuse-ld=mold

TARGET := tachyon

all: $(TARGET)

$(TARGET): $(TARGET).cpp

clean:
	rm -f $(TARGET)

.PHONY: all
