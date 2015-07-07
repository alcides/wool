#include "wool.h"
#include <stdio.h>
#include <stdlib.h>


int sfib(int n) {
	if (n < 2) return n;
	return sfib(n-1) + sfib(n-2);
}


TASK_1( int, pfib, int, n )
{
   if( n < 2 ) {
      return n;
   } else if (CUTOFF_MECHANISM) {
      return sfib(n-1);
   } else {
      int m,k;
      SPAWN( pfib, n-1 );
      k = CALL( pfib, n-2 );
      m = SYNC( pfib );
      return m+k;
   }
}

TASK_2( int, main, int, argc, char **, argv )
{
   int n,m;

   if( argc < 2 ) {
      fprintf( stderr, "Usage: fib <woolopt>... <arg>\n" ),
      exit( 2 );
   }

   n = atoi( argv[ 1 ] );

   m = CALL( pfib, n );

   printf( "%d\n", m );
   return 0;
}

