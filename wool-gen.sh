#! /bin/bash

# Copyright notice:
echo "
   This file is part of Wool, a library for fine-grained independent 
   task parallelism

   Copyright (C) 2009- Karl-Filip Faxen
      kff@sics.se

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Pwool, Suite 330, Boston, MA
   02111-1307, USA.
" > /dev/null

echo '
#ifndef WOOL_H
#define WOOL_H

#include "wool-common.h"
'

#
# Second part, once for each arity
#

ARGS_MAX_ALIGN="1"

for(( r = 0; r <= $1; r++ )) do

# Naming various argument lists

if ((r)); then
  MACRO_ARGS="$MACRO_ARGS, ATYPE_$r, ARG_$r"
  MACRO_a_ARGS="$MACRO_a_ARGS, ATYPE_$r, a$r"
  MACRO_DECL_ARGS="$MACRO_DECL_ARGS, ATYPE_$r"
  WRK_FORMALS="$WRK_FORMALS, ATYPE_$r ARG_$r"
  FUN_a_FORMALS="$FUN_a_FORMALS, ATYPE_$r a$r"
  CALL_a_ARGS="$CALL_a_ARGS, a$r"
  ARG_TYPES="$ARG_TYPES, ATYPE_$r"
  ARGS_MAX_ALIGN="_WOOL_(max)( __alignof__(ATYPE_$r), $ARGS_MAX_ALIGN )"
fi

OFFSET_SUM="0"
TASK_a_INIT_p=""
TASK_GET_FROM_p=""
for(( i = 1; i <= r; i++ )) do
  OFFSET_SUM="$OFFSET_SUM + _WOOL_OFFCON(A, ATYPE_$i, (K)>$i)"
  TASK_a_INIT_p="$TASK_a_INIT_p  *(ATYPE_$i *)( _WOOL_(p) + _WOOL_OFFSET_$r($i, __alignof__(ATYPE_$i)$ARG_TYPES) ) = a$i;
"
  TASK_GET_FROM_p="$TASK_GET_FROM_p,  *(ATYPE_$i *)( _WOOL_(p) + _WOOL_OFFSET_$r($i, __alignof__(ATYPE_$i)$ARG_TYPES) )"
done
  

echo
echo "// Task definition for arity $r"
echo
if ((r)); then

echo "
#define _WOOL_OFFSET_$r(K, A$ARG_TYPES) ($OFFSET_SUM)

"

for isvoid in 0 1; do

if (( isvoid==0 )); then
  DEF_MACRO_LHS="#define TASK_$r(RTYPE, NAME$MACRO_ARGS )"
  DCL_MACRO_LHS="#define TASK_DECL_$r(RTYPE, NAME$MACRO_DECL_ARGS)"
  IMP_MACRO_LHS="#define TASK_IMPL_$r(RTYPE, NAME$MACRO_ARGS )"
  DEF_MACRO_RHS="TASK_DECL_$r(RTYPE, NAME$MACRO_DECL_ARGS)
TASK_IMPL_$r(RTYPE, NAME$MACRO_ARGS)"
  RTYPE="RTYPE"
  RES_FIELD="$RTYPE res;
"
  SAVE_RVAL="t->d.res ="
  RETURN_RES_dq_top="( (NAME##_TD *) *__dq_top )->d.res"
  ASSIGN_RES="res = "
  RES_VAR="res"
else
  DEF_MACRO_LHS="#define VOID_TASK_$r(NAME$MACRO_ARGS )"
  DCL_MACRO_LHS="#define VOID_TASK_DECL_$r(NAME$MACRO_DECL_ARGS)"
  IMP_MACRO_LHS="#define VOID_TASK_IMPL_$r(NAME$MACRO_ARGS )"
  DEF_MACRO_RHS="VOID_TASK_DECL_$r(NAME$MACRO_DECL_ARGS)
VOID_TASK_IMPL_$r(NAME$MACRO_ARGS)"
  RTYPE="void"
  RES_FIELD=""
  SAVE_RVAL=""
  RETURN_RES_dq_top=""
  ASSIGN_RES=""
  RES_VAR=""
fi

(\
echo "$DCL_MACRO_LHS

typedef struct _##NAME##_TD {
  TASK_COMMON_FIELDS( struct _##NAME##_TD * )
  union {
    $RES_FIELD
  } d;
} NAME##_TD;


/** SPAWN related functions **/

void NAME##_WRAP(Worker *__self, Task *__dq_top, NAME##_TD *t);

static inline __attribute__((__always_inline__))
void NAME##_SPAWN(Worker *__self, Task **__dq_top_p$FUN_a_FORMALS)
{
  const unsigned long _WOOL_max_align = $ARGS_MAX_ALIGN;
  const unsigned long _WOOL_(sss) = sizeof( __wool_task_common ) + _WOOL_max_align - 1;
  char *_WOOL_(p) = ((char *) *__dq_top_p) + _WOOL_(sss) - _WOOL_(sss) % _WOOL_max_align;

$TASK_a_INIT_p

  COMPILER_FENCE;

  _WOOL_(fast_spawn)( __self, __dq_top_p, (wrapper_t) &NAME##_WRAP );

}

static inline __attribute__((__always_inline__))
void NAME##_SPAWN_DSP(Worker *__self, Task **__dq_top_p, int _WOOL_(fs_in_task)$FUN_a_FORMALS)
{
  if( _WOOL_(fs_in_task) ) {
    NAME##_SPAWN( __self, __dq_top_p$CALL_a_ARGS );
  } else {
    Task *_WOOL_(ersatz_top);

    __self = _WOOL_(slow_get_self)( );
    _WOOL_(ersatz_top) = _WOOL_(slow_get_top)( __self );

    NAME##_SPAWN( __self, &_WOOL_(ersatz_top)$CALL_a_ARGS );
  }
}

/** CALL related functions **/

$RTYPE NAME##_CALL(Worker *_WOOL_(self), Task *_WOOL_(top)$FUN_a_FORMALS);

static inline __attribute__((__always_inline__))
$RTYPE NAME##_CALL_DSP( Worker *_WOOL_(self), Task *_WOOL_(top), int _WOOL_(fs_in_task)$FUN_a_FORMALS )
{
  if( _WOOL_(fs_in_task) ) {
    return NAME##_CALL( _WOOL_(self), _WOOL_(top)$CALL_a_ARGS );
  } else {
    _WOOL_(self) = _WOOL_(slow_get_self)( );
    return NAME##_CALL( _WOOL_(self), _WOOL_(slow_get_top)( _WOOL_(self) )$CALL_a_ARGS );
  }
}

/** SYNC related functions **/

/* This implementation has the PUB function only in the implementation file, so uses from other
   compilation units call it.
*/
Task *NAME##_PUB(Worker *self, Task *top, Task *jfp );

static inline __attribute__((__always_inline__)) 
$RTYPE NAME##_SYNC(Worker *__self, Task **__dq_top)
{
  WOOL_WHEN_MSPAN( hrtime_t e_span; )
  Task *jfp = __self->join_first_private;
  
  if( MAKE_TRACE || 
      ( LOG_EVENTS && 
      __self->curr_block_fidx + ( (*__dq_top) - __self->curr_block_base ) <= __self->n_public ) )
  {
    logEvent( __self, 6 );
  }

  if( __builtin_expect( jfp < *__dq_top, 1 ) ) {
    Task *t = --(*__dq_top);
    const unsigned long _WOOL_max_align = $ARGS_MAX_ALIGN;
    const unsigned long _WOOL_(sss) = sizeof( __wool_task_common ) + _WOOL_max_align - 1;
    char *_WOOL_(p) = ((char *) t) + _WOOL_(sss) - _WOOL_(sss) % _WOOL_max_align;
    $RES_FIELD

    __self->pr_top = *__dq_top;
    PR_INC( __self, CTR_inlined );

    WOOL_MSPAN_BEFORE_INLINE( e_span, t );

    $ASSIGN_RES NAME##_CALL( __self, (*__dq_top)$TASK_GET_FROM_p );
    WOOL_MSPAN_AFTER_INLINE( e_span, t );
    if( MAKE_TRACE ) {
      logEvent( __self, 8 );
    }
    return $RES_VAR;
  } else {
    *__dq_top = NAME##_PUB( __self, *__dq_top, jfp );
    return $RETURN_RES_dq_top;
  }
}

static inline __attribute__((__always_inline__)) 
$RTYPE NAME##_SYNC_DSP( Worker *__self, Task **__dq_top, int _WOOL_(fs_in_task) )
{
  if( _WOOL_(fs_in_task) ) {
    return NAME##_SYNC( __self, __dq_top );
  } else {
    Task *_WOOL_(ersatz_top);

    __self = _WOOL_(slow_get_self)( );
    _WOOL_(ersatz_top) = _WOOL_(slow_get_top)( __self );

    return NAME##_SYNC( __self, &_WOOL_(ersatz_top) );
  }
}" \

) | awk '{printf "%-70s\\\n", $0 }'

echo " "

(\
echo "$IMP_MACRO_LHS

$RTYPE NAME##_CALL(Worker *_WOOL_(self), Task *_WOOL_(top)$FUN_a_FORMALS);

/** SPAWN related functions **/

void NAME##_WRAP(Worker *__self, Task *__dq_top, NAME##_TD *t)
{
  const unsigned long _WOOL_max_align = $ARGS_MAX_ALIGN;
  const unsigned long _WOOL_(sss) = sizeof( __wool_task_common ) + _WOOL_max_align - 1;
  char *_WOOL_(p) = ((char *) t) + _WOOL_(sss) - _WOOL_(sss) % _WOOL_max_align;

  $SAVE_RVAL NAME##_CALL( __self, __dq_top$TASK_GET_FROM_p );
}

/** SYNC related functions **/

Task *NAME##_PUB(Worker *self, Task *top, Task *jfp )
{
  unsigned long ps = self->public_size;

  WOOL_WHEN_AS( int us; )

  grab_res_t res = WOOL_FAST_EXC ? TF_EXC : TF_OCC;

  if( 
        ( WOOL_WHEN_AS_C( us = self->unstolen_stealable )
         __builtin_expect( (unsigned long) jfp - (unsigned long) top < ps, 1 ) )
         && __builtin_expect( WOOL_LS_TEST(us), 1 ) 
         && (res = _WOOL_(grab_in_sync)( self, (top)-1 ),
             (
               WOOL_WHEN_AS_C( self->unstolen_stealable = us-1 )
               __builtin_expect( res != TF_OCC, 1 ) ) ) 
   ) {
    /* Semi fast case */
    NAME##_TD *t = (NAME##_TD *) --top;
    const unsigned long _WOOL_max_align = $ARGS_MAX_ALIGN;
    const unsigned long _WOOL_(sss) = sizeof( __wool_task_common ) + _WOOL_max_align - 1;
    char *_WOOL_(p) = ((char *) t) + _WOOL_(sss) - _WOOL_(sss) % _WOOL_max_align;

    self->pr_top = top;
    PR_INC( self, CTR_inlined );
    $SAVE_RVAL NAME##_CALL( self, (top)$TASK_GET_FROM_p );
    return top;
  } else {
      /* An exceptional case */
      top = _WOOL_(new_slow_sync)( self, top, res );
      return top;
  }

}

/** CALL related functions **/

static inline __attribute__((__always_inline__))
$RTYPE NAME##_WRK(Worker *, Task *__dq_top, int _WOOL_(in_task)$WRK_FORMALS);

$RTYPE NAME##_CALL(Worker *_WOOL_(self), Task *_WOOL_(top)$FUN_a_FORMALS)
{
  return NAME##_WRK( _WOOL_(self), _WOOL_(top), 1 $CALL_a_ARGS );
}

static inline __attribute__((__always_inline__))
$RTYPE NAME##_WRK(Worker *__self, Task *__dq_top, int _WOOL_(in_task)$WRK_FORMALS)"\

) | awk '{printf "%-70s\\\n", $0 }'

echo " "

echo "$DEF_MACRO_LHS
$DEF_MACRO_RHS
" | awk '{printf "%-70s\\\n", $0 }'

echo " "
done
fi

if ((r < $1-1)); then
(\
echo "\
#define LOOP_BODY_$r(NAME, COST, IXTY, IXNAME$MACRO_ARGS)

static unsigned long const NAME##__min_iters__ 
   = COST > FINEST_GRAIN ? 1 : FINEST_GRAIN / ( COST ? COST : 20 );

static inline void NAME##_LOOP(Worker *__self, Task *__dq_top, IXTY IXNAME$WRK_FORMALS);

VOID_TASK_$((r+2))(NAME##_TREE, IXTY, __from, IXTY, __to$MACRO_a_ARGS)
{
  if( __to - __from <= NAME##__min_iters__ ) {
    IXTY __i;
    for( __i = __from; __i < __to; __i++ ) {
      NAME##_LOOP( __self, __dq_top, __i$CALL_a_ARGS );
    }
  } else {
    IXTY __mid = (__from + __to) / 2;
    SPAWN( NAME##_TREE, __mid, __to$CALL_a_ARGS );
    CALL( NAME##_TREE, __from, __mid$CALL_a_ARGS );
    SYNC( NAME##_TREE );
  }
}

static inline void NAME##_LOOP(Worker *__self, Task *__dq_top, IXTY IXNAME$WRK_FORMALS)"\
) | awk '{printf "%-70s\\\n", $0 }'

fi

done

echo '
#endif'

