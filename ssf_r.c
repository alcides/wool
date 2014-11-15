/*
    Copyright 2005-2009 Intel Corporation.  All Rights Reserved.

    The source code contained or described herein and all documents related
    to the source code ("Material") are owned by Intel Corporation or its
    suppliers or licensors.  Title to the Material remains with Intel
    Corporation or its suppliers and licensors.  The Material is protected
    by worldwide copyright laws and treaty provisions.  No part of the
    Material may be used, copied, reproduced, modified, published, uploaded,
    posted, transmitted, distributed, or disclosed in any way without
    Intel's prior express written permission.

    No license under any patent, copyright, trade secret or other
    intellectual property right is granted to or conferred upon you by
    disclosure or delivery of the Materials, either expressly, by
    implication, inducement, estoppel or otherwise.  Any license under such
    intellectual property rights must be express and approved by Intel in
    writing.
*/

#include "wool.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

LOOP_BODY_4( ssf, LARGE_BODY, size_t, i, size_t, n, char *, str, size_t*, max_array, size_t*, pos_array )
{
  size_t max_size = 0, max_pos = 0;
  size_t j,k;

  for ( j = 0; j < n; ++j) 
    if (j != i) {
      size_t limit = n-( i > j ? i : j );
      for (k = 0; k < limit; ++k) {
        if (str[i + k] != str[j + k]) break;
        if (k > max_size) {
          max_size = k;
          max_pos = j;
        }
      }
    }
  max_array[i] = max_size;
  pos_array[i] = max_pos;
}


TASK_2( int, main, int, argc, char**, argv ) 
{

  size_t N, *len, *pos, *max;
  int i,r;
  char **str;
  char *outfilename;
  FILE *outfile;

  if( argc < 3 ) {
    exit(1);
  }
  N = atoi( argv[1] );
  r = atoi( argv[2] );
  if( argc >= 4 ) {
    outfilename = argv[3];
  } else {
    outfilename = NULL;
  }

  str = (char **)  malloc( N * sizeof(char *) );
  len = (size_t *) malloc( N * sizeof(size_t) );
  str[0] = "a"; len[0] = 1;
  str[1] = "b"; len[1] = 1;
  for (i = 2; i < N; ++i) {
    len[i] = len[i-1] + len[i-2];
    str[i] = (char *) malloc( len[i] * sizeof(char) + 1 );
    strcpy( str[i], str[i-1] );
    strcpy( str[i]+len[i-1], str[i-2] );
  }
  char *to_scan = str[N-1];
  size_t n = len[N-1]; 

  max = (size_t *) malloc( n * sizeof(size_t) );
  pos = (size_t *) malloc( n * sizeof(size_t) );

 for( i = 0; i < r; i++ ) {
   FOR( ssf, 0, n, n, to_scan, max, pos );
 }

 if( outfilename != NULL ) {
   outfile = fopen( outfilename, "w" );
 } else {
   outfile = stdout;
 }

 for (i = 0; i < n; ++i) {
   fprintf( outfile, " %d(%d)\n", (int)max[i], (int)pos[i] );
 }

 if( outfilename != NULL ) {
   fclose( outfile );
 }
 free( max );
 free( pos );
 return 0;
}

