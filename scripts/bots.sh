OPTS="-of 2 -c -v 0 -r 30"

./bin/bots_alignment $OPTS -f bots/inputs/alignment/prot.100.aa -z # Only in first
./bin/bots_fib $OPTS -n 53 
./bin/bots_fft $OPTS -n 268435456
./bin/bots_floorplan $OPTS -f bots/inputs/floorplan/input.20
./bin/bots_health $OPTS -f bots/inputs/health/large.input
./bin/bots_nqueens $OPTS -n 16
./bin/bots_sort $OPTS -n 536870912
./bin/bots_sparselu $OPTS -n 100x100
./bin/bots_strassen $OPTS -n 8192
./bin/bots_uts $OPTS -f bots/inputs/uts/large.input