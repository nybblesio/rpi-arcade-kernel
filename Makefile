.PHONY: all clean

all: kernel8.img game.img
clean:
	rm kernel/kernel8.img
	rm lumberjacks/game.img

kernel8.img: kernel/kernel8.s
	fasmarm $<

game.img: lumberjacks/game.s
	fasmarm $<
