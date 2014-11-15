#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "wool.h"

#include "uts.h"

typedef unsigned long counter_t;


/***********************************************************
 *  Global state                                           *
 ***********************************************************/
counter_t nNodes  = 0;
counter_t nLeaves = 0;
counter_t maxTreeDepth = 0;


/***********************************************************
 *  UTS Implementation Hooks                               *ool
 ***********************************************************/

// The name of this implementation
char * impl_getName() {
  return "Wool Parallel Recursive Search";
}

int  impl_paramsToStr(char *strBuf, int ind) { 
  ind += sprintf(strBuf+ind, "Execution strategy:  %s\n", impl_getName());
  return ind;
}

// Not using UTS command line params, return non-success
int  impl_parseParam(char *param, char *value) { return 1; }

void impl_helpMessage() {
  printf("   none.\n");
}

void impl_abort(int err) {
  exit(err);
}


/***********************************************************
 * Recursive depth-first implementation                    *
 ***********************************************************/

typedef struct {
  counter_t maxdepth, size, leaves;
} Result;


TASK_4( counter_t, parTreeSearch, 
        int, depth, Node *, parent, int, childNum, int, rangeSize )
{
  counter_t r = 1; // We count this node and possibly more

  Node n, *nodePtr;
  int j, numChildren;

  // the following recursion implements the loop over the number of children
  if( rangeSize > 1 ) {
    int leftRS = rangeSize/2, rightRS = rangeSize-leftRS;
    int left,right;

    SPAWN( parTreeSearch, depth, parent, childNum+leftRS, rightRS );
    left = CALL( parTreeSearch, depth, parent, childNum, leftRS );
    right = SYNC( parTreeSearch );
    return left+right;
  }
  // we get here, so we know that we only deal with one child

  if (depth == 0)    // root node is its own parent, init'ed in advance
  {
     nodePtr = parent;
  }
  else
  {
     nodePtr = &n;
     n.type = uts_childType(parent);
     n.height = parent->height + 1;
     n.numChildren = -1;    // not yet determined
     for (j = 0; j < computeGranularity; j++) {
        rng_spawn(parent->state.state, nodePtr->state.state, childNum);
     }
  }

  numChildren = uts_numChildren(nodePtr);

  // record number of children in parent
  nodePtr->numChildren = numChildren;
  
  // Recurse on the children, implemented by a range of numChildren 
  if (numChildren > 0) {
    r += CALL( parTreeSearch, depth+1, nodePtr, 0, numChildren );
  }
  return r;
}

TASK_2( int, main, int, argc, char**, argv )
{
  Node root;
  double t1, t2;

  uts_parseParams(argc, argv);

  uts_printParams();
  uts_initRoot(&root, type);

  t1 = uts_wctime();

  nNodes = CALL( parTreeSearch, 0, &root, 0, 1 );

  t2 = uts_wctime();

  maxTreeDepth = 0;
  nLeaves = 0; 

  uts_showStats(0, 0, t2-t1, nNodes, nLeaves, maxTreeDepth);

  return 0;
}
