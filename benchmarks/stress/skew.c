#include "wool.h"
#include <stdio.h>
#include <stdlib.h>

int loop( int );

TASK_3( int, tree, int, d, int, s, int, n )
{
  if( d>0 ) {
    int r = 1, l = 1, a, b;
    if( s<0 ) {
      r = -s;
    } else {
      l = s;
    }
    SPAWN( tree, d-r, s, n );
    a = CALL( tree, d-l, s, n);
    b = SYNC( tree );
    return a+b;
  } else {
    loop( n );
    return 1;
  }
}

TASK_2( int, main, int, argc, char **, argv )
{
  int i, d, n, m, s, r = 0;

  if( argc < 5 ) {
    fprintf( stderr, "Usage: stress [<wool opts>] <grain> <depth> <skew> <reps>\n" );
    return 1;
  }

  n  = atoi( argv[1] );
  d  = atoi( argv[2] );
  s  = atoi( argv[3] );
  m  = atoi( argv[4] );

  for( i=0; i<m; i++) {
    r = CALL( tree, d, s, n );
  }
  printf( "DONE, %d leaves per rep\n", r );

  return 0;
}
