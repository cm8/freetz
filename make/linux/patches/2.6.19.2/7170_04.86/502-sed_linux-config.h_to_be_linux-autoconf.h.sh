#!/bin/sh

. tools/freetz_functions

D="$1/linux-2.6.19"

{
  for f in hw_mcdma.h
  do echo "include/asm-mips/mach-ohio/$f"
  done

  for f in ohio_clk.c ohio_gpio.c ohio_int.c ohio_irq_cpu.c \
           ohio_irq_stub.S ohio_power.c ohio_reset.c ohio_setup.c \
           ohio_sio.c ohio_ssi.c ohio_trace.c ohio_vlynq_init.c \
           ohio_vlynq_irq.c
  do echo "arch/mips/mips-boards/ohio/$f"
  done

  for f in ohio-flash.c
  do echo "drivers/mtd/maps/$f"
  done

} | \
while read f
do
  sed -i -e '/#include *.linux.config.h/ s,config.h,autoconf.h,' "$D/$f"
  echo2 "patched ${D##*/}/$f with sed to include autoconf.h"
done

sep2
