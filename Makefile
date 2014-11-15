CC = gcc

ifdef CCOMP
  CC = ${CCOMP}
endif

# ifndef SOLARIS
#   threadsflag = -pthread 
# else
  threadsflag = -lpthread
# endif

buildparams = 
# CFLAGS = -g -O3 -falign-functions -Wall $(buildparams)
CFLAGS = -g -O3 -Wall $(buildparams)
LDLIBS = $(threadsflag)
examples = fib stress loop2 mm1 mm2 mm3 mm4 memstress mm5 mm6 mm7 skew \
           cholesky_r_opt ssf_r uts multisort nqueens inst_uts
MAX_ARITY = 10

cholesky_r_opt : LDLIBS += -lm
uts            : LDLIBS += -lm
inst_uts       : LDLIBS += -lm

ifdef TASK_PAYLOAD
  buildparams += -DTASK_PAYLOAD=$(TASK_PAYLOAD)
endif

ifdef FINEST_GRAIN
  buildparams += -DFINEST_GRAIN=$(FINEST_GRAIN)
endif

ifdef COUNT_EVENTS
  buildparams += -DCOUNT_EVENTS=$(COUNT_EVENTS)
endif

ifdef WOOL_PIE_TIMES
  buildparams += -DWOOL_PIE_TIMES=$(WOOL_PIE_TIMES)
endif

ifdef LOG_EVENTS
  buildparams += -DLOG_EVENTS=$(LOG_EVENTS)
  LDFLAGS += -lrt
endif

ifdef WOOL_MEASURE_SPAN
  buildparams += -DWOOL_MEASURE_SPAN=$(WOOL_MEASURE_SPAN)
  LDFLAGS += -lrt
endif

all : $(examples)

fib    : fib.o wool.o wool-main.o
mm1    : mm1.o wool.o wool-main.o
mm2    : mm2.o wool.o wool-main.o
mm3    : mm3.o wool.o wool-main.o
mm4    : mm4.o wool.o wool-main.o
mm5    : mm5.o wool.o wool-main.o
mm6    : mm6.o wool.o wool-main.o
mm7    : mm7.o wool.o wool-main.o
stress : stress.o wool.o loop.o wool-main.o
skew   : skew.o wool.o loop.o wool-main.o
loop2  : loop2.o wool.o loop.o wool-main.o
memstress : memstress.o wool.o reads.o wool-main.o
cholesky_r_opt : cholesky_r_opt.o getoptions.o wool.o wool-main.o
ssf_r   : ssf_r.o wool.o wool-main.o
uts    : uts.o rng/brg_sha1.o uts_wool.o wool.o wool-main.o
inst_uts : uts.o rng/brg_sha1.o inst_uts_wool.o wool.o wool-main.o
	${CC} -o inst_uts uts.o rng/brg_sha1.o inst_uts_wool.o wool.o wool-main.o ${LDLIBS}
multisort : multisort.o wool.o wool-main.o
nqueens : nqueens.o wool.o wool-main.o

loop.o : loop.c
	${CC} -c -O loop.c
reads.o : reads.c
	gcc -O -c reads.c

wool.h : wool-gen.sh
	./wool-gen.sh $(MAX_ARITY) > wool.h
wool.h : wool-common.h

wool.o : wool.h
wool-main.o : wool.h

fib.o    : wool.h
mm1.o    : wool.h 
mm2.o    : wool.h 
mm3.o    : wool.h 
mm4.o    : wool.h 
mm5.o    : wool.h
mm6.o    : wool.h 
mm7.o    : wool.h 
stress.o : wool.h 
skew.o   : wool.h 
loop2.o  : wool.h 
memstress.o : wool.h
cholesky_r_opt.o : wool.h getoptions.h
ssf_r.o : wool.h
uts_wool.o : wool.h uts.h
inst_uts_wool.o : wool.h uts.h
uts.o          : uts.h rng/rng.h
rng/brg_sha1.o : rng/brg_sha1.h rng/brg_endian.h
multisort.o : wool.h
nqueens.o : wool.h

clean : 
	rm -f wool.h *.o $(examples) rng/*.o

