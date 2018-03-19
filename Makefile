.PHONY: all clean

all: kernel/kernel8.img lumberjacks/game.hex
clean:
	rm kernel/kernel8.img	
	rm lumberjacks/game.img
	rm lumberjacks/game.hex

DEPS=command.s console.s constants.s dma.s font.s \
	interrupt.s joy.s kernel_abi.s macros.s mailbox.s \
	pool.s string.s terminal.s timer.s uart.s util.s video.s

kernel/kernel8.img: kernel/kernel8.s $(DEPS)
	fasmarm $<

lumberjacks/game.img: lumberjacks/game.s $(DEPS)
	fasmarm $<

lumberjacks/game.hex: lumberjacks/game.img
	arm-none-eabi-objcopy -I binary --output-target=ihex lumberjacks/game.img lumberjacks/game.hex
	dos2unix lumberjacks/game.hex
	cat lumberjacks/game.hex | xclip -selection c
