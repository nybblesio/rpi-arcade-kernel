.PHONY: all clean kernel lumberjacks

all: kernel lumberjacks
clean:
	rm -f *.img

kernel8.img: kernel/kernel8.s
	fasmarm $<

lumberjacks.img: lumberjacks/game.s
	fasmarm $<

kernel: kernel8.img

lumberjacks: lumberjacks.img
