/**********************************************************************************************/
/*  This program is part of the Barcelona OpenMP Tasks Suite                                  */
/*  Copyright (C) 2009 Barcelona Supercomputing Center - Centro Nacional de Supercomputacion  */
/*  Copyright (C) 2009 Universitat Politecnica de Catalunya                                   */
/*                                                                                            */
/*  This program is free software; you can redistribute it and/or modify                      */
/*  it under the terms of the GNU General Public License as published by                      */
/*  the Free Software Foundation; either version 2 of the License, or                         */
/*  (at your option) any later version.                                                       */
/*                                                                                            */
/*  This program is distributed in the hope that it will be useful,                           */
/*  but WITHOUT ANY WARRANTY; without even the implied warranty of                            */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                             */
/*  GNU General Public License for more details.                                              */
/*                                                                                            */
/*  You should have received a copy of the GNU General Public License                         */
/*  along with this program; if not, write to the Free Software                               */
/*  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA            */
/**********************************************************************************************/

/*
 * Original code from the Cilk project (by Keith Randall)
 * 
 * Copyright (c) 2000 Massachusetts Institute of Technology
 * Copyright (c) 2000 Matteo Frigo
 */

/*---:::[[[]]]:::---
  Changed to Cilk++ to fit multi-model BOTS
  Artur Podobas
  Royal Institute of Technology
  2010
  ---:::[[[]]]:::---*/

#include <stdlib.h>
#include <stdio.h>
#include <memory.h>
#include <alloca.h>
#include "bots.h"
//#Include <Omp.h>
//#include <cilk.h>
#include "../wool-lib/wool.h"

/* Checking information */

static int solutions[] = {
        1,
        0,
        0,
        2,
        10, /* 5 */
        4,
        40,
        92,
        352,
        724, /* 10 */
        2680,
        14200,
        73712,
        365596,
};
#define MAX_SOLUTIONS sizeof(solutions)/sizeof(int)

int mycount=0;
//#pragma omp threadprivate(mycount)

int total_count = 0;


/*
 * <a> contains array of <n> queen positions.  Returns 1
 * if none of the queens conflict, and returns 0 otherwise.
 */
int ok(int n, char *a)
{
     int i, j;
     char p, q;

     for (i = 0; i < n; i++) {
	  p = a[i];

	  for (j = i + 1; j < n; j++) {
	       q = a[j];
	       if (q == p || q == p - (j - i) || q == p + (j - i))
		    return 0;
	  }
     }
     return 1;
}

void nqueens_ser (int n, int j, char *a, int *solutions)
{
	int i,res;

	if (n == j) {
		/* good solution, count it */

		*solutions = 1;
		return;
	}

	*solutions = 0;



     	/* try each possible position for queen <j> */
	for (i = 0; i < n; i++) {
		{
	  		/* allocate a temporary array and copy <a> into it */
	  		a[j] = i;
	  		if (ok(j + 1, a)) {
	       			nqueens_ser(n, j + 1, a,&res);

				*solutions += res;

			}
		}
	}
}



//Pre-declare it
//void nqueens_cilk( int n , int j , char *a, int *csols , int depth , int i);
//VOID_TASK_6 (nqueens_wool, int , n , int , j , char* , a , int* , csols , int , depth , int , i);
static inline __attribute__((__always_inline__))void nqueens_wool_CALL_DSP( Worker *, Task *, int , int, int , char*, int* , int , int  );



#if defined(MANUAL_CUTOFF)

LOOP_BODY_5 (iteration , 10000 , int , i , int , n , int , j , char*, a , int*, csols , int , depth)
{
  //  if (depth < bots_cutoff_value) {
     CALL(nqueens_wool , n , j , a , csols , depth, i );
     /*  } else {
  			a[j] = i;
  			if (ok(j + 1, a))
       				nqueens_ser(n, j + 1, a,&csols[i]);
		}
     */
}





VOID_TASK_5 (nqueens , int , n , int , j , char* , a , int* , solutions , int , depth)
{
	int i;
	int *csols;

	if (n == j) {
		/* good solution, count it */

		*solutions = 1;
		return;
	}

	*solutions = 0;
	csols = (int * ) alloca(n*sizeof(int));
	memset(csols,0,n*sizeof(int));

#if defined(FOR_VERSION)
	if (depth<bots_cutoff_value) 
	FOR(iteration , 0 , n , n , j , a , csols , depth);
	else 
	  for (i=0;i<n;i++)
	    {
	                a[j] = i;
  			if (ok(j + 1, a))
     				nqueens_ser(n, j + 1, a,&csols[i]);
	    };
#else
     	/* try each possible position for queen <j> */
	for (i = 0; i < n; i++) {
	if ( depth < bots_cutoff_value ) {
                  SPAWN (nqueens_wool , n , j , a , csols , depth , i);
		} else {
  			a[j] = i;
  			if (ok(j + 1, a))
     				nqueens_ser(n, j + 1, a,&csols[i]);
		}

	}

              if (depth < bots_cutoff_value) for (i=0;i<n;i++) SYNC(nqueens_wool);
#endif
              for ( i = 0; i < n; i++) *solutions += csols[i];
}



#else 

//void nqueens(int n, int j, char *a, int *solutions, int depth)
  VOID_TASK_5 (nqueens , int , n , int , j , char* , a , int* , solutions , int , depth)
{
	int i;
	int *csols;

	if (n == j) {


		*solutions = 1;
		return;
	}

	*solutions = 0;
	csols = (int*) alloca(n*sizeof(int));
	memset(csols,0,n*sizeof(int));

 
	for (i = 0; i < n; i++) {
	  SPAWN(nqueens_wool, n , j ,a , csols , depth , i);
	}


        for (i=0;i<n;i++) SYNC(nqueens_wool);
	for ( i = 0; i < n; i++) *solutions += csols[i];

}

#endif


//To be used with CILK/WOOL
//void nqueens_cilk( int n , int j , char *a, int *csols , int depth , int i)
VOID_TASK_6 (nqueens_wool, int , n , int , j , char* , a , int* , csols , int , depth , int , i)
{


                                char *b = (char *) alloca((j + 1) * sizeof(char));
	  			memcpy(b, a, j * sizeof(char));
	  			b[j] = i;
	  			if (ok(j + 1, b))
				  CALL( nqueens,n, j + 1, b,&csols[i],depth+1);			

}

void find_queens (int size)
{
	total_count=0;

        bots_message("Computing N-Queens algorithm (n=%d) ", size);
        char *a = (char *)  malloc(size * sizeof(char));

	CALL(nqueens,size, 0, a, &total_count,0);
        //cilk_spawn nqueens(size, 0, a, &total_count,0);
	//	cilk_sync;

	bots_message(" completed!\n");
	printf("Solutions: %d vs %d\n",total_count,solutions[size-1]);
        if (total_count == solutions[size-1]) printf("SUCESS!\n");else printf("FAIL!\n");
}


int verify_queens (int size)
{
	if ( size > MAX_SOLUTIONS ) return BOTS_RESULT_NA;
	if ( total_count == solutions[size-1]) return BOTS_RESULT_SUCCESSFUL;
	return BOTS_RESULT_UNSUCCESSFUL;
}
