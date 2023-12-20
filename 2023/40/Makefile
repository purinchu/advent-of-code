.PHONY: all clean
TARGETS := graph.png sample2.png sample3.png

all: $(TARGETS)

%.png: %.dot Makefile
	@echo "[DOT   ] $<"
	@dot -Tpng -o$@ $< 2>/dev/null || true # eat asan error

clean:
	@rm -f $(TARGETS)
