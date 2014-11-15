#include "wool.h"

TASK_DECL_2( int, main, int, char ** );

int main( int argc, char **argv )
{
  int result;

  argc = wool_init( argc, argv );
  result = CALL( main, argc, argv );
  wool_fini( );
  return result;

}
