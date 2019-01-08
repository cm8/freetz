#!/bin/sh

. tools/freetz_functions

D="$1/linux-2.6.19"
S="source/kernel/ref-ohio-04.87/linux-2.6.13"

mymv() {
  mkdir -p "$D/$1"
  if [ -n "$2" ]
  then cp -a "$S/$1/$2" "$D/$1/$2" && echo2 "copied file ${D##*/}/$1/$2 from ${S##*/}"
  else cp -a "$S/$1/"* "$D/$1" && echo2 "copied directory ${D##*/}/$1 from ${S##*/}"
  fi
}

make 1>/dev/null 2>/dev/null \
FREETZ_AVM_SOURCE_ID="04.87" \
FREETZ_DL_KERNEL_SOURCE_ID="7170_04.87" \
FREETZ_DL_KERNEL_SOURCE="7170_04.87-release_kernel.tar.xz" \
FREETZ_DL_KERNEL_SOURCE_MD5="a673a5facbaf1fe8dce9144a05dfaf88" \
FREETZ_KERNEL_VERSION_MAJOR="2.6.13" \
FREETZ_KERNEL_VERSION="2.6.13.1" \
FREETZ_SYSTEM_TYPE="ohio" \
kernel-unpacked

for f in Makefile ohio_clk.c ohio_gpio.c ohio_int.c ohio_irq_cpu.c \
         ohio_irq_stub.S ohio_power.c ohio_reset.c ohio_setup.c \
         ohio_sio.c ohio_ssi.c ohio_trace.c ohio_vlynq_init.c \
         ohio_vlynq_irq.c
do mymv "arch/mips/mips-boards/ohio" "$f"
done

for f in hw_bbif.h hw_boot.h hw_clock.h hw_emif.h hw_gpio.h hw_i2c.h \
         hw_irq.h hw_mcdma.h hw_mdio.h hw_reset.h hw_stack.h hw_timer.h \
         hw_uart.h hw_usb.h hw_vlynq.h led_config.h led_hal.h led_ioctl.h \
         wdtimer.h
do mymv "include/asm-mips/mach-ohio" "$f"
done

for f in ohio_clk.h ohio_gpio.h ohio.h ohioint.h ohio_power.h ohio_reset.h \
         ohio_ssi.h ohio_vlynq.h
do mymv "include/asm-mips/mips-boards" "$f"
done

for f in ohio-flash.c
do mymv "drivers/mtd/maps" "$f"
done

mymv "drivers/dsl/ur8"

rm -rf "${S%/linux-2.6.13}"

sep2
