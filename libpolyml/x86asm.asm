;#
;#  Title:  Assembly code routines for the poly system.
;#  Author:    David Matthews
;#  Copyright (c) Cambridge University Technical Services Limited 2000
;#  Further development David C. J. Matthews 2000-2015
;#
;#  This library is free software; you can redistribute it and/or
;#  modify it under the terms of the GNU Lesser General Public
;#  License version 2.1 as published by the Free Software Foundation.
;#  
;#  This library is distributed in the hope that it will be useful,
;#  but WITHOUT ANY WARRANTY; without even the implied warranty of
;#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;#  Lesser General Public License for more details.
;#  
;#  You should have received a copy of the GNU Lesser General Public
;#  License along with this library; if not, write to the Free Software
;#  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
;#
;#
;#
;#
;# *********************************************************************
;# * IMPORTANT                                                         *
;# * This file is used directly by MASM but is also converted          *
;# * for use by gas on Unix.  For reasons best known to the respective *
;# * developers the assembly language accepted by gas is different     *
;# * from that used by MASM.  This file uses a sort of half-way house  *
;# * between the two versions in that the gas instruction ordering is  *
;# * used i.e. the first argument is the source and the second the     *
;# * destination, but the MASM format of addresses is used.            * 
;# * After making any changes to this file ensure that it can be       *
;# * successfully converted and compiled under both MASM and gas.      *
;# * DCJM January 2000                                                 *
;# *********************************************************************

;#
;# Registers used :-
;#
;#  %Reax: First argument to function.  Result of function call.
;#  %Rebx: Second argument to function.
;#  %Recx: General register
;#  %Redx: Closure pointer in call.
;#  %Rebp: Points to memory used for extra registers
;#  %Resi: General register.
;#  %Redi: General register.
;#  %Resp: Stack pointer.
;#  X86_64 Additional registers
;#  %R8:   Third argument to function
;#  %R9:   Fourth argument to function
;#  %R10:  Fifth argument to function
;#  %R11:  General register
;#  %R12:  General register
;#  %R13:  General register
;#  %R14:  General register
;#  %R15:  Memory allocation pointer

IFDEF WINDOWS
IFNDEF HOSTARCHITECTURE_X86_64
.486

    .model  flat,c
ENDIF

;# No name munging needed in MASM
EXTNAME     TEXTEQU <>

;# CALLMACRO is used to indicate to the converter that we have a macro
;# since macros have to be converted into C preprocessor macros.
CALLMACRO       TEXTEQU <>

IFNDEF HOSTARCHITECTURE_X86_64
Reax        TEXTEQU <eax>
Rebx        TEXTEQU <ebx>
Recx        TEXTEQU <ecx>
Redx        TEXTEQU <edx>
Resi        TEXTEQU <esi>
Redi        TEXTEQU <edi>
Resp        TEXTEQU <esp>
Rebp        TEXTEQU <ebp>
ELSE
Reax        TEXTEQU <rax>
Rebx        TEXTEQU <rbx>
Recx        TEXTEQU <rcx>
Redx        TEXTEQU <rdx>
Resi        TEXTEQU <rsi>
Redi        TEXTEQU <rdi>
Resp        TEXTEQU <rsp>
Rebp        TEXTEQU <rbp>
ENDIF
R_cl        TEXTEQU <cl>
R_bl        TEXTEQU <bl>
R_al        TEXTEQU <al>
R_ax        TEXTEQU <ax>

CONST       TEXTEQU <>

;#  gas-style instructions
;#  These are the reverse order from MASM.
MOVL        MACRO   f,t
            mov     t,f
            ENDM

MOVB        MACRO   f,t
            mov     t,f
            ENDM

ADDL        MACRO   f,t
            add     t,f
            ENDM

SUBL        MACRO   f,t
            sub     t,f
            ENDM

XORL        MACRO   f,t
            xor     t,f
            ENDM

ORL         MACRO   f,t
            or      t,f
            ENDM

ANDL        MACRO   f,t
            and     t,f
            ENDM

CMPL        MACRO   f,t
            cmp     t,f
            ENDM

CMPB        MACRO   f,t
            cmp     t,f
            ENDM

LEAL        MACRO   f,t
            lea     t,f
            ENDM

SHRL        MACRO   f,t
            shr     t,f
            ENDM

SARL        MACRO   f,t
            sar     t,f
            ENDM

SHLL        MACRO   f,t
            shl     t,f
            ENDM

TESTL       MACRO   f,t
            test    t,f
            ENDM

IMULL       MACRO   f,t
            imul    t,f
            ENDM

LOCKXADDL   MACRO   f,t
            lock xadd t,f
            ENDM

MULL         TEXTEQU <mul>

NEGL         TEXTEQU <neg>
PUSHL        TEXTEQU <push>
POPL         TEXTEQU <pop>

IFDEF HOSTARCHITECTURE_X86_64
POPFL        TEXTEQU <popfq>
PUSHFL       TEXTEQU <pushfq>
PUSHAL       TEXTEQU <pushaq>
POPAL        TEXTEQU <popaq>
FULLWORD     TEXTEQU <qword>

;#  Return instructions - all in registers in x86-64
RET0         TEXTEQU <ret>
RET1         TEXTEQU <ret>
RET2         TEXTEQU <ret>
RET3         TEXTEQU <ret>
RET4         TEXTEQU <ret>
RET5         TEXTEQU <ret>
ELSE
POPFL        TEXTEQU <popfd>
PUSHFL       TEXTEQU <pushfd>
PUSHAL       TEXTEQU <pushad>
POPAL        TEXTEQU <popad>
FULLWORD     TEXTEQU <dword>

;# Return instructions - First two values in registers, remainder on the stack
RET0         TEXTEQU <ret>
RET1         TEXTEQU <ret>
RET2         TEXTEQU <ret>
RET3         TEXTEQU <ret 4>
RET4         TEXTEQU <ret 8>
RET5         TEXTEQU <ret 12>
ENDIF
INCL         TEXTEQU <inc>

ELSE
#include "config.h"
#if defined __MINGW64__
#  if defined POLY_LINKAGE_PREFIX
#    define EXTNAME(x) POLY_LINKAGE_PREFIX ## x
#  else
#    define EXTNAME(x) x
#  endif    
;# External names in older versions of FreeBSD have a leading underscore.
#elif ! defined(__ELF__)
#define EXTNAME(x)  _##x
#else
#define EXTNAME(x)  x
#endif

IFNDEF HOSTARCHITECTURE_X86_64
#define Reax        %eax
#define Rebx        %ebx
#define Recx        %ecx
#define Redx        %edx
#define Resi        %esi
#define Redi        %edi
#define Resp        %esp
#define Rebp        %ebp
ELSE
#define Reax        %rax
#define Rebx        %rbx
#define Recx        %rcx
#define Redx        %rdx
#define Resi        %rsi
#define Redi        %rdi
#define Resp        %rsp
#define Rebp        %rbp
ENDIF
#define R_al        %al
#define R_cl        %cl
#define R_bl        %bl
#define R_ax        %ax
IFDEF HOSTARCHITECTURE_X86_64
#define R8          %r8
#define R9          %r9
#define R10         %r10
#define R11         %r11
#define R12         %r12
#define R13         %r13
#define R14         %r14
#define R15         %r15
ENDIF

#define CONST       $

#define END

IFDEF HOSTARCHITECTURE_X86_64
#define MOVL         movq
#define MOVB         movb
#define ADDL         addq
#define SUBL         subq
#define XORL         xorq
#define ORL          orq
#define ANDL         andq
#define CMPL         cmpq
#define CMPB         cmpb
#define LEAL         leaq
#define SHRL         shrq
#define SARL         sarq
#define SHLL         shlq
#define TESTL        testq
#define IMULL        imulq
#define MULL         mulq
#define DIVL         divl
#define NEGL         negq
#define PUSHL        pushq
#define POPL         popq
#define POPFL        popfq
#define PUSHFL       pushfq
#define PUSHAL       pushaq
#define POPAL        popaq
#define LOCKXADDL    lock xaddq

;# Return instructions for n arguments.  All these are in registers
#define RET0         ret
#define RET1         ret
#define RET2         ret
#define RET3         ret
#define RET4         ret
#define RET5         ret

ELSE
#define MOVL         movl
#define MOVB         movb
#define ADDL         addl
#define SUBL         subl
#define XORL         xorl
#define ORL          orl
#define ANDL         andl
#define CMPL         cmpl
#define CMPB         cmpb
#define LEAL         leal
#define SHRL         shrl
#define SARL         sarl
#define SHLL         shll
#define TESTL        testl
#define IMULL        imull
#define MULL         mull
#define DIVL         divl
#define NEGL         negl
#define PUSHL        pushl
#define POPL         popl
#define POPFL        popfl
#define PUSHFL       pushfl
#define PUSHAL       pushal
#define POPAL        popal
;# Older versions of GCC require a semicolon here.
#define LOCKXADDL    lock; xaddl

;# Return instructions for n arguments.
#define RET0         ret
#define RET1         ret
#define RET2         ret
#define RET3         ret $4
#define RET4         ret $8
#define RET5         ret $12

ENDIF

ENDIF

;# Register mask entries - must match coding used in I386CODECONS.ML
IFDEF WINDOWS
M_Reax      EQU     000001H
M_Recx      EQU     000002H
M_Redx      EQU     000004H
M_Rebx      EQU     000008H
M_Resi      EQU     000010H
M_Redi      EQU     000020H

IFDEF HOSTARCHITECTURE_X86_64
M_R8        EQU     64
M_R9        EQU     128
M_R10       EQU     256
M_R11       EQU     512
M_R12       EQU     1024
M_R13       EQU     2048
M_R14       EQU     4096
ENDIF

M_FP0       EQU     002000H
M_FP1       EQU     004000H
M_FP2       EQU     008000H
M_FP3       EQU     010000H
M_FP4       EQU     020000H
M_FP5       EQU     040000H
M_FP6       EQU     080000H
M_FP7       EQU     100000H

Mask_all    EQU     1FFFFFH

;# Set the register mask entry
RegMask     MACRO   name,mask
Mname       TEXTEQU <Mask_&name&>
%Mname      EQU     mask
            ENDM

ELSE
;# Register mask entries - must match coding used in I386CODECONS.ML
#define     M_Reax  0x000001
#define     M_Recx  0x000002
#define     M_Redx  0x000004
#define     M_Rebx  0x000008
#define     M_Resi  0x000010
#define     M_Redi  0x000020

IFDEF HOSTARCHITECTURE_X86_64
#define     M_R8         64
#define     M_R9        128
#define     M_R10       256
#define     M_R11       512
#define     M_R12      1024
#define     M_R13      2048
#define     M_R14      4096
ENDIF
            ;# Floating point registers.
#define     M_FP0   0x002000
#define     M_FP1   0x004000
#define     M_FP2   0x008000
#define     M_FP3   0x010000
#define     M_FP4   0x020000
#define     M_FP5   0x040000
#define     M_FP6   0x080000
#define     M_FP7   0x100000

#define     Mask_all 0x1FFFFF

#define     RegMask(name,mask) \
.set        Mask_##name,    mask

#define     OR  |

ENDIF

;#
;# Macro to begin the hand-coded functions
;#
IFDEF WINDOWS
INLINE_ROUTINE  MACRO   id
PUBLIC  id
id:
ENDM

ELSE

IFDEF MACOSX
#define GLOBAL .globl
ELSE
#define GLOBAL .global
ENDIF

#define INLINE_ROUTINE(id) \
GLOBAL EXTNAME(id); \
EXTNAME(id):

ENDIF


IFDEF WINDOWS

;#
;# Tagged values.   A few operations, such as shift assume that the tag bit
;# is the bottom bit.
;#


TAG         EQU 1
TAGSHIFT    EQU 1
TAGMULT     EQU 2

TAGGED      MACRO   i
            LOCAL   t
            t   TEXTEQU <i*2+1>
            EXITM   %t
ENDM

MAKETAGGED  MACRO   f,t
            lea     t,1[f*2]
ENDM

IFDEF HOSTARCHITECTURE_X86_64
POLYWORDSIZE    EQU 8
ELSE
POLYWORDSIZE    EQU 4
ENDIF

ELSE

.set    TAG,        1
.set    TAGSHIFT,   1
.set    TAGMULT,    (1 << TAGSHIFT)

#define TAGGED(i) ((i << TAGSHIFT) | TAG)
#define MAKETAGGED(from,to)     LEAL    TAG(,from,2),to


IFDEF HOSTARCHITECTURE_X86_64
.set    POLYWORDSIZE,   8
ELSE
.set    POLYWORDSIZE,   4
ENDIF

ENDIF


IFDEF WINDOWS

NIL         TEXTEQU     TAGGED(0)
UNIT        TEXTEQU     TAGGED(0)
ZERO        TEXTEQU     TAGGED(0)
FALSE       TEXTEQU     TAGGED(0)
TRUE        TEXTEQU     TAGGED(1)
MINUS1      TEXTEQU     TAGGED(0-1)
B_bytes     EQU         01h
B_mutablebytes  EQU     41h
B_mutable   EQU         40h
IFNDEF HOSTARCHITECTURE_X86_64
Max_Length  EQU         00ffffffh
ELSE
Max_Length  EQU         00ffffffffffffffh
ENDIF

ELSE

.set    NIL,        TAGGED(0)
.set    UNIT,       TAGGED(0)
.set    ZERO,       TAGGED(0)
.set    FALSE,      TAGGED(0)
.set    TRUE,       TAGGED(1)
.set    MINUS1,     TAGGED(0-1)
.set    B_bytes,    0x01
.set    B_mutable,  0x40
.set    B_mutablebytes, 0x41
IFNDEF HOSTARCHITECTURE_X86_64
.set    Max_Length, 0x00ffffff
ELSE
.set    Max_Length, 0x00ffffffffffffff
ENDIF

ENDIF

;# The "memory registers" are pointed to by Rebp within the ML code
;# The first few offsets are built into the compiled code.
;# All the offsets are built into x86_dep.c .

IFDEF WINDOWS
LocalMpointer       EQU     0

IFNDEF HOSTARCHITECTURE_X86_64
HandlerRegister     EQU     4
LocalMbottom        EQU     8
RequestCode         EQU     20  ;# Byte: Io function to call.
InRTS               EQU     21  ;# Byte: Set when in the RTS
ReturnReason        EQU     22  ;# Byte: Reason for returning from ML.
FullRestore         EQU     23  ;# Byte: Full/partial restore
PolyStack           EQU     24  ;# Current stack base
SavedSp             EQU     28  ;# Saved stack pointer
IOEntryPoint        EQU     48  ;# IO call
RaiseDiv            EQU     52  ;# Call to raise the Div exception
ArbEmulation        EQU     56  ;# Arbitrary precision emulation
ThreadId            EQU     60  ;# My thread id
RealTemp            EQU     64 ;# Space for int-real conversions

ELSE
HandlerRegister     EQU     8
LocalMbottom        EQU     16
StackLimit          EQU     24  ;# Lower limit of stack
RequestCode         EQU     40  ;# Byte: Io function to call.
InRTS               EQU     41  ;# Byte: Set when in the RTS
ReturnReason        EQU     42  ;# Byte: Reason for returning from ML.
FullRestore         EQU     43  ;# Byte: Full/partial restore
PolyStack           EQU     48  ;# Current stack base
SavedSp             EQU     56  ;# Saved stack pointer
HeapOverflow        EQU     64  ;# Heap overflow code
StackOverflow       EQU     72  ;# Stack overflow code
StackOverflowEx     EQU     80  ;# Stack overflow code (for EDI)
RaiseExEntry        EQU     88  ;# Raise exception
IOEntryPoint        EQU     96  ;# IO call
RaiseDiv            EQU     104  ;# Exception trace
ArbEmulation        EQU     112  ;# Arbitrary precision emulation
ThreadId            EQU     120 ;# My thread id
RealTemp            EQU     128 ;# Space for int-real conversions
ENDIF

ELSE
.set    LocalMpointer,0
IFNDEF HOSTARCHITECTURE_X86_64
.set    HandlerRegister,4
.set    LocalMbottom,8
.set    RequestCode,20
.set    InRTS,21
.set    ReturnReason,22
.set    FullRestore,23
.set    PolyStack,24
.set    SavedSp,28
.set    IOEntryPoint,48
.set    RaiseDiv,52
.set    ArbEmulation,56
.set    ThreadId,60
.set    RealTemp,64
ELSE
.set    HandlerRegister,8
.set    LocalMbottom,16
.set    StackLimit,24
.set    RequestCode,40
.set    InRTS,41
.set    ReturnReason,42
.set    FullRestore,43
.set    PolyStack,48
.set    SavedSp,56
.set    HeapOverflow,64
.set    StackOverflow,72
.set    StackOverflowEx,80
.set    RaiseExEntry,88
.set    IOEntryPoint,96
.set    RaiseDiv,104
.set    ArbEmulation,112
.set    ThreadId,120
.set    RealTemp,128
ENDIF

ENDIF

;# IO function numbers.  These are functions that are called
;# to handle special cases in this code

IFDEF WINDOWS
POLY_SYS_exit                EQU 1
POLY_SYS_chdir               EQU 9
POLY_SYS_alloc_store         EQU 11
POLY_SYS_get_flags           EQU 17
POLY_SYS_exception_trace_fn  EQU 32
POLY_SYS_give_ex_trace_fn    EQU 33
POLY_SYS_network             EQU 51
POLY_SYS_os_specific         EQU 52
POLY_SYS_io_dispatch         EQU 61
POLY_SYS_signal_handler      EQU 62
POLY_SYS_thread_dispatch     EQU 73
POLY_SYS_plus_longword       EQU 74
POLY_SYS_minus_longword      EQU 75
POLY_SYS_mul_longword        EQU 76
POLY_SYS_div_longword        EQU 77
POLY_SYS_mod_longword        EQU 78
POLY_SYS_andb_longword       EQU 79
POLY_SYS_orb_longword        EQU 80
POLY_SYS_xorb_longword       EQU 81
POLY_SYS_kill_self           EQU 84
POLY_SYS_shift_left_longword        EQU  85
POLY_SYS_shift_right_longword       EQU 86
POLY_SYS_shift_right_arith_longword EQU 87
POLY_SYS_profiler            EQU 88
POLY_SYS_signed_to_longword   EQU 90
POLY_SYS_unsigned_to_longword EQU 91
POLY_SYS_full_gc             EQU 92
POLY_SYS_stack_trace         EQU 93
POLY_SYS_timing_dispatch     EQU 94
POLY_SYS_objsize             EQU 99
POLY_SYS_showsize            EQU 100
POLY_SYS_quotrem             EQU 104
POLY_SYS_aplus               EQU 106
POLY_SYS_aminus              EQU 107
POLY_SYS_amul                EQU 108
POLY_SYS_adiv                EQU 109
POLY_SYS_amod                EQU 110
POLY_SYS_aneg                EQU 111
POLY_SYS_xora                EQU 112
POLY_SYS_equala              EQU 113
POLY_SYS_ora                 EQU 114
POLY_SYS_anda                EQU 115
POLY_SYS_Real_str            EQU 117
POLY_SYS_Real_geq            EQU 118
POLY_SYS_Real_leq            EQU 119
POLY_SYS_Real_gtr            EQU 120
POLY_SYS_Real_lss            EQU 121
POLY_SYS_Real_eq             EQU 122
POLY_SYS_Real_neq            EQU 123
POLY_SYS_Real_Dispatch       EQU 124
POLY_SYS_Add_real            EQU 125
POLY_SYS_Sub_real            EQU 126
POLY_SYS_Mul_real            EQU 127
POLY_SYS_Div_real            EQU 128
POLY_SYS_Abs_real            EQU 129
POLY_SYS_Neg_real            EQU 130
POLY_SYS_conv_real           EQU 133
POLY_SYS_real_to_int         EQU 134
POLY_SYS_int_to_real         EQU 135
POLY_SYS_sqrt_real           EQU 136
POLY_SYS_sin_real            EQU 137
POLY_SYS_cos_real            EQU 138
POLY_SYS_arctan_real         EQU 139
POLY_SYS_exp_real            EQU 140
POLY_SYS_ln_real             EQU 141
POLY_SYS_process_env         EQU 150
POLY_SYS_poly_specific       EQU 153
;# Define these for the moment.
POLY_SYS_cmem_load_32        EQU 162
POLY_SYS_cmem_load_64        EQU 163
POLY_SYS_cmem_load_float     EQU 164
POLY_SYS_cmem_load_double    EQU 165
POLY_SYS_cmem_store_32       EQU 168
POLY_SYS_cmem_store_64       EQU 169
POLY_SYS_cmem_store_float    EQU 170
POLY_SYS_cmem_store_double   EQU 171
POLY_SYS_io_operation        EQU 189
POLY_SYS_ffi                 EQU 190
POLY_SYS_set_code_constant   EQU 194
POLY_SYS_code_flags          EQU 200
POLY_SYS_shrink_stack        EQU 201
POLY_SYS_callcode_tupled     EQU 204
POLY_SYS_foreign_dispatch    EQU 205
POLY_SYS_XWindows            EQU 209
POLY_SYS_int_geq             EQU 231
POLY_SYS_int_leq             EQU 232
POLY_SYS_int_gtr             EQU 233
POLY_SYS_int_lss             EQU 234


RETURN_HEAP_OVERFLOW        EQU 1
RETURN_STACK_OVERFLOW       EQU 2
RETURN_STACK_OVERFLOWEX     EQU 3
RETURN_RAISE_DIV            EQU 4
RETURN_ARB_EMULATION        EQU 5
RETURN_CALLBACK_RETURN      EQU 6
RETURN_CALLBACK_EXCEPTION   EQU 7

ELSE
#include "sys.h"

#define RETURN_HEAP_OVERFLOW        1
#define RETURN_STACK_OVERFLOW       2
#define RETURN_STACK_OVERFLOWEX     3
#define RETURN_RAISE_DIV            4
#define RETURN_ARB_EMULATION        5
#define RETURN_CALLBACK_RETURN      6
#define RETURN_CALLBACK_EXCEPTION   7


ENDIF

;#
;# Stack format from objects.h is:
;#  typedef struct
;#  {                byte offset of start
;#    word  p_space ;            0 -- Now unused - remove
;#    byte *p_pc ;               4
;#    word *p_sp ;               8 -- Now unused - remove
;#    word *p_hr ;              12
;#    word  p_nreg ;            16  -- Now unused - remove
;#    word  p_reg[1] ;          20
;#  } StackObject ;
;#
 
;#
;# Starting offsets

IFDEF WINDOWS

IFNDEF HOSTARCHITECTURE_X86_64
PC_OFF      EQU     4
SP_OFF      EQU     8
EAX_OFF     EQU     20
EBX_OFF     EQU     24
ECX_OFF     EQU     28
EDX_OFF     EQU     32
ESI_OFF     EQU     36
EDI_OFF     EQU     40
FLAGS_OFF   EQU     48
FPREGS_OFF  EQU     52
ELSE
PC_OFF      EQU     8
SP_OFF      EQU     16
EAX_OFF     EQU     40
EBX_OFF     EQU     48
ECX_OFF     EQU     56
EDX_OFF     EQU     64
ESI_OFF     EQU     72
EDI_OFF     EQU     80
R8_OFF      EQU     88
R9_OFF      EQU     96
R10_OFF     EQU     104
R11_OFF     EQU     112
R12_OFF     EQU     120
R13_OFF     EQU     128
R14_OFF     EQU     136
FLAGS_OFF   EQU     152
FPREGS_OFF  EQU     160
ENDIF

ELSE

;#.set    SPACE_OFF,  0
IFNDEF HOSTARCHITECTURE_X86_64
.set    PC_OFF,     4
.set    SP_OFF,     8
.set    EAX_OFF,    20
.set    EBX_OFF,    24
.set    ECX_OFF,    28
.set    EDX_OFF,    32
.set    ESI_OFF,    36
.set    EDI_OFF,    40
.set    FLAGS_OFF,  48
.set    FPREGS_OFF, 52
ELSE
.set    PC_OFF,     8
.set    SP_OFF,     16
;# 32 is the count of the number of checked registers
.set    EAX_OFF,    40
.set    EBX_OFF,    48
.set    ECX_OFF,    56
.set    EDX_OFF,    64
.set    ESI_OFF,    72
.set    EDI_OFF,    80
.set    R8_OFF,     88
.set    R9_OFF,     96
.set    R10_OFF,    104
.set    R11_OFF,    112
.set    R12_OFF,    120
.set    R13_OFF,    128
.set    R14_OFF,    136
;# 144 is the count of the number of unchecked registers
.set    FLAGS_OFF,  152
.set    FPREGS_OFF, 160
ENDIF

ENDIF

;# Mark the stack as non-executable when compiling for Linux
IFDEF __linux__
IFDEF __ELF__
.section .note.GNU-stack, "", @progbits
ENDIF
ENDIF

;#
;# CODE STARTS HERE
;#
IFDEF WINDOWS
    .CODE
ELSE
    .text
ENDIF

;# Define standard call macro. CALL_IO ioCallNo  where ioCallNo is the io function to call.
;# We need to include M_Redx in the register sets.  MD_set_for_retry may modify it
;# if the function was called directly and not via the closure register.

IFDEF WINDOWS

CALL_IO    MACRO   index
        mov     byte ptr [RequestCode+Rebp],index
        jmp     SaveStateAndReturnLocal
ENDM

CALL_EXTRA  MACRO   index
    mov     byte ptr [ReturnReason+Rebp],index
    jmp     SaveFullState
    ENDM

ELSE

#define CALL_IO(index) \
        MOVB  $index,RequestCode[Rebp]; \
        jmp   SaveStateAndReturnLocal;

#define CALL_EXTRA(index) \
        MOVB  $index,ReturnReason[Rebp]; \
        jmp   SaveFullState;
ENDIF

;# Load the registers from the ML stack and jump to the code.
;# This is used to start ML code.
;# The argument is the address of the MemRegisters struct and goes into %rbp.
CALLMACRO INLINE_ROUTINE X86AsmSwitchToPoly
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    4[Resp],Recx                    ;# Argument - address of MemRegisters - goes into Rebp
    PUSHAL                                  ;# Save all the registers just to be safe
    MOVL    Resp,SavedSp[Recx]              ;# savedSp:=%Resp - Save the system stack pointer.

    MOVL    Recx,Rebp                       ;# Put address of MemRegisters where it belongs
ELSE
IFDEF WINDOWS
;# The argument to the function is passed in Recx
    
ELSE
IFDEF _WIN32
;# The argument to the function is passed in Recx
ELSE
;# The argument to the function is passed in Redi
    MOVL    Redi,Recx
ENDIF
ENDIF
    PUSHL   Rebp                             ;# Save callee--save registers
    PUSHL   Rebx
    PUSHL   R12
    PUSHL   R13
    PUSHL   R14
    PUSHL   R15
    PUSHL   Redi                            ;# Callee save in Windows
    PUSHL   Resi
    MOVL    Resp,SavedSp[Recx]              ;# savedSp:=%Resp - Save the system stack pointer.
    MOVL    Recx,Rebp                       ;# Put address of MemRegisters where it belongs
ENDIF
    MOVL    PolyStack[Rebp],Reax
IFDEF HOSTARCHITECTURE_X86_64
    MOVL    LocalMpointer[Rebp],R15         ;# Set the heap pointer register
ENDIF
    MOVL    SP_OFF[Reax],Resp               ;# Set the new stack ptr
    PUSHL   PC_OFF[Reax]                    ;# Push the code address
IFDEF WINDOWS
    test    byte ptr [Rebp+FullRestore],1   ;# Should we restore or clear the regs?
ELSE
    testb   CONST 1,FullRestore[Rebp]       ;# Should we restore or clear the regs?
ENDIF
    jnz     sw2polyfull
;# We're returning from an RTS call.  We need to clear the registers we're
;# not restoring so that they are valid if we GC.  We restore EDX and the
;# argument regs because this may have been CallCode
    MOVL    EBX_OFF[Reax],Rebx
    MOVL    CONST ZERO,Recx
    MOVL    EDX_OFF[Reax],Redx
    MOVL    CONST ZERO,Resi
    MOVL    CONST ZERO,Redi
IFDEF HOSTARCHITECTURE_X86_64
    MOVL    R8_OFF[Reax],R8
    MOVL    R9_OFF[Reax],R9
    MOVL    R10_OFF[Reax],R10
    MOVL    CONST ZERO,R11
    MOVL    CONST ZERO,R12
    MOVL    CONST ZERO,R13
    MOVL    CONST ZERO,R14
ENDIF
    MOVL    EAX_OFF[Reax],Reax
    cld                                     ;# Clear this just in case

IFDEF WINDOWS
    mov     byte ptr [InRTS+Rebp],0
ELSE
    MOVB    CONST 0,InRTS[Rebp]             ;# inRTS:=0 (stack now kosher)
ENDIF
    ret                                     ;# Jump to code address

sw2polyfull:
    PUSHL   FLAGS_OFF[Reax]                 ;# Push the flags
    FRSTOR  FPREGS_OFF[Reax]
    MOVL    EBX_OFF[Reax],Rebx              ;# Load the registers
    MOVL    ECX_OFF[Reax],Recx
    MOVL    EDX_OFF[Reax],Redx
    MOVL    ESI_OFF[Reax],Resi
    MOVL    EDI_OFF[Reax],Redi
IFDEF HOSTARCHITECTURE_X86_64
    MOVL    R8_OFF[Reax],R8
    MOVL    R9_OFF[Reax],R9
    MOVL    R10_OFF[Reax],R10
    MOVL    R11_OFF[Reax],R11
    MOVL    R12_OFF[Reax],R12
    MOVL    R13_OFF[Reax],R13
    MOVL    R14_OFF[Reax],R14
ENDIF
    cld                                     ;# Clear this just in case
    MOVL    EAX_OFF[Reax],Reax
    POPFL                                   ;# reset flags
IFDEF WINDOWS
    mov     byte ptr [InRTS+Rebp],0
ELSE
    MOVB    CONST 0,InRTS[Rebp]             ;# inRTS:=0 (stack now kosher)
ENDIF
    ret                                     ;# Jump to code address


;# Code to save the state and switch to C
;# This saves the full register state.
SaveFullState:
    PUSHFL                      ;# Save flags
    PUSHL   Reax                ;# Save eax
    MOVL    PolyStack[Rebp],Reax
    MOVL    Rebx,EBX_OFF[Reax]
    MOVL    Recx,ECX_OFF[Reax]
    MOVL    Redx,EDX_OFF[Reax]
    MOVL    Resi,ESI_OFF[Reax]
    MOVL    Redi,EDI_OFF[Reax]
    FNSAVE  FPREGS_OFF[Reax]          ;# Save FP state.  Also resets the state so...
    FLDCW   FPREGS_OFF[Reax]          ;# ...load because we need the same rounding mode in the RTS
IFDEF HOSTARCHITECTURE_X86_64
    MOVL    R8,R8_OFF[Reax]
    MOVL    R9,R9_OFF[Reax]
    MOVL    R10,R10_OFF[Reax]
    MOVL    R11,R11_OFF[Reax]
    MOVL    R12,R12_OFF[Reax]
    MOVL    R13,R13_OFF[Reax]
    MOVL    R14,R14_OFF[Reax]
    MOVL    R15,LocalMpointer[Rebp]  ;# Save the heap pointer
ENDIF
    POPL    Rebx                ;# Get old eax value
    MOVL    Rebx,EAX_OFF[Reax]
    POPL    Rebx
    MOVL    Rebx,FLAGS_OFF[Reax]
    MOVL    Resp,SP_OFF[Reax]
IFDEF WINDOWS
    mov     byte ptr [InRTS+Rebp],1
ELSE
    MOVB    CONST 1,InRTS[Rebp]             ;# inRTS:=0 (stack now kosher)
ENDIF
    MOVL    SavedSp[Rebp],Resp
IFNDEF HOSTARCHITECTURE_X86_64
    POPAL
ELSE
    POPL    Resi
    POPL    Redi
    POPL    R15                            ;# Restore callee-save registers
    POPL    R14
    POPL    R13
    POPL    R12
    POPL    Rebx
    POPL    Rebp
ENDIF
    ret

;# As X86AsmSaveFullState but only save what is necessary for an RTS call.
CALLMACRO INLINE_ROUTINE X86AsmSaveStateAndReturn
SaveStateAndReturnLocal: ;# This is necessary so that the jmps use a PC-relative address

    PUSHL   Reax                ;# Save eax
    MOVL    PolyStack[Rebp],Reax
    MOVL    Rebx,EBX_OFF[Reax]
    MOVL    Redx,EDX_OFF[Reax]
    FSTCW   FPREGS_OFF[Reax]
    FNINIT                     ;# Reset the FP state.
    FLDCW   FPREGS_OFF[Reax]   ;# But reload the rounding mode
IFDEF HOSTARCHITECTURE_X86_64
    MOVL    R8,R8_OFF[Reax]
    MOVL    R9,R9_OFF[Reax]
    MOVL    R10,R10_OFF[Reax]
    MOVL    R15,LocalMpointer[Rebp]  ;# Save the heap pointer
ENDIF
    POPL    Rebx                ;# Get old eax value
    MOVL    Rebx,EAX_OFF[Reax]
    MOVL    Resp,SP_OFF[Reax]
IFDEF WINDOWS
    mov     byte ptr [InRTS+Rebp],1
ELSE
    MOVB    CONST 1,InRTS[Rebp]             ;# inRTS:=0 (stack now kosher)
ENDIF
    MOVL    SavedSp[Rebp],Resp
IFNDEF HOSTARCHITECTURE_X86_64
    POPAL
ELSE
    POPL    Resi
    POPL    Redi
    POPL    R15                            ;# Restore callee-save registers
    POPL    R14
    POPL    R13
    POPL    R12
    POPL    Rebx
    POPL    Rebp
ENDIF
    ret

;#
;# A number of functions implemented in Assembly for efficiency reasons
;#

int_to_word:
 ;# Extract the low order bits from a word.
    TESTL   CONST TAG,Reax
    jz      get_first_long_word_a1
    ret                 ;# Return the argument
CALLMACRO   RegMask int_to_word,(M_Reax)

 ;# This is now used in conjunction with isShort in Word.fromInt.
get_first_long_word_a1:
get_first_long_word_a:
IFDEF WINDOWS
    test    byte ptr [Reax-1],CONST 16  ;# 16 is the "negative" bit
ELSE
    testb   CONST 16,(-1)[Reax]     ;# 16 is the "negative" bit
ENDIF
    MOVL    [Reax],Reax     ;# Extract the word which is already little-endian
    jz      gfw1
    NEGL    Reax            ;# We can ignore overflow
gfw1:
CALLMACRO   MAKETAGGED  Reax,Reax
    ret
CALLMACRO   RegMask get_first_long_word,(M_Reax)



move_bytes:
 ;# Move a segment of memory from one location to another.
 ;# Must deal with the case of overlapping segments correctly.
 ;# (source, sourc_offset, destination, dest_offset, length)

 ;# Assume that the offsets and length are all short integers.
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    12[Resp],Redi               ;# Destination address
    MOVL    8[Resp],Recx                ;# Destination offset, untagged
ELSE
    MOVL    R8,Redi               ;# Destination address
    MOVL    R9,Recx                ;# Destination offset, untagged
ENDIF
    SHRL    CONST TAGSHIFT,Recx
    ADDL    Recx,Redi
    MOVL    Reax,Resi                   ;# Source address
    SHRL    CONST TAGSHIFT,Rebx
    ADDL    Rebx,Resi
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    4[Resp],Recx                ;# Get the length to move
ELSE
    MOVL    R10,Recx                ;# Get the length to move
ENDIF
    SHRL    CONST TAGSHIFT,Recx
    cld                             ;# Default to increment Redi,Resi
    CMPL    Redi,Resi                   ;# Check for potential overlap
 ;# If dest > src then use decrementing moves else
 ;# use incrementing moves.
    ja      mvb1
    std                             ;# Decrement Redi,Resi
    LEAL    (-1)[Resi+Recx],Resi
    LEAL    (-1)[Redi+Recx],Redi
mvb1:
IFDEF WINDOWS
    rep movsb                       ;# Copy the bytes
ELSE
    rep
    movsb                           ;# Copy the bytes
ENDIF
    MOVL    CONST UNIT,Reax             ;# The function returns unit
    MOVL    Reax,Rebx               ;# Clobber bad value in %rbx
    MOVL    Reax,Recx               ;# and %Recx
    MOVL    Reax,Redi
    MOVL    Reax,Resi
 ;# Visual Studio 5 C++ seems to assume that the direction flag
 ;# is cleared.  I think that`s a bug but we have to go along with it.
    cld
IFNDEF HOSTARCHITECTURE_X86_64
    ret     CONST 12
ELSE
    ret
ENDIF

CALLMACRO   RegMask move_bytes,Mask_all


move_words:
 ;# Move a segment of memory from one location to another.
 ;# Must deal with the case of overlapping segments correctly.
 ;# (source, source_offset, destination, dest_offset, length)
 ;# Assume that the offsets and length are all short integers.
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    12[Resp],Redi               ;# Destination address
    MOVL    8[Resp],Recx                ;# Destination offset
    LEAL    (-2)[Redi+Recx*2],Redi      ;# Destination address plus offset
    LEAL    (-2)[Reax+Rebx*2],Resi      ;# Source address plus offset
    MOVL    4[Resp],Recx                ;# Get the length to move (words)
ELSE
    MOVL    R8,Redi               ;# Destination address
    MOVL    R9,Recx                ;# Destination offset
    LEAL    (-4)[Redi+Recx*4],Redi      ;# Destination address plus offset
    LEAL    (-4)[Reax+Rebx*4],Resi      ;# Source address plus offset
    MOVL    R10,Recx                ;# Get the length to move (words)
ENDIF
    SHRL    CONST TAGSHIFT,Recx
    cld                             ;# Default to increment Redi,Resi
    CMPL    Redi,Resi                   ;# Check for potential overlap
 ;# If dest > src then use decrementing moves else
 ;# use incrementing moves.
    ja      mvw1
    std                             ;# Decrement Redi,Resi

    LEAL    (-POLYWORDSIZE)[Resi+Recx*POLYWORDSIZE],Resi
    LEAL    (-POLYWORDSIZE)[Redi+Recx*POLYWORDSIZE],Redi

mvw1:
IFDEF WINDOWS
IFNDEF HOSTARCHITECTURE_X86_64
    rep movsd                       ;# Copy the words
ELSE
    rep movsq                       ;# Copy the words
ENDIF
ELSE
    rep
IFNDEF HOSTARCHITECTURE_X86_64
    movsl                           ;# Copy the words
ELSE
    movsq                           ;# Copy the words
ENDIF
ENDIF
    MOVL    CONST UNIT,Reax             ;# The function returns unit
    MOVL    Reax,Recx               ;# Clobber bad values
    MOVL    Reax,Redi
    MOVL    Reax,Resi
 ;# Visual Studio 5 C++ seems to assume that the direction flag
 ;# is cleared.  I think that`s a bug but we have to go along with it.
    cld
IFNDEF HOSTARCHITECTURE_X86_64
    ret     CONST 12
ELSE
    ret
ENDIF

CALLMACRO   RegMask move_words,Mask_all
;#

RetFalse:
    MOVL    CONST FALSE,Reax
    ret

RetTrue:
    MOVL    CONST TRUE,Reax
    ret

not_bool:
    XORL    CONST (TRUE-TAG),Reax   ;# Change the value but leave the tag
    ret
CALLMACRO   RegMask not_bool,(M_Reax)

 ;# or, and, xor shift etc. assume the values are tagged integers
or_word:
    ORL     Rebx,Reax
    ret
CALLMACRO   RegMask or_word,(M_Reax)

and_word:
    ANDL    Rebx,Reax
    ret
CALLMACRO   RegMask and_word,(M_Reax)

xor_word:
    XORL    Rebx,Reax
    ORL     CONST TAG,Reax  ;# restore the tag
    ret
CALLMACRO   RegMask xor_word,(M_Reax)

shift_left_word:
 ;# Assume that both args are tagged integers
 ;# Word.<<(a,b) is defined to return 0 if b > Word.wordSize
IFNDEF HOSTARCHITECTURE_X86_64
    CMPL    CONST TAGGED(31),Rebx
ELSE
    CMPL    CONST TAGGED(63),Rebx
ENDIF
    jb      slw1
    MOVL    CONST ZERO,Reax
    ret
slw1:
    MOVL    Rebx,Recx
    SHRL    CONST TAGSHIFT,Recx ;# remove tag
    SUBL    CONST TAG,Reax
    SHLL    R_cl,Reax
    ORL     CONST TAG,Reax  ;# restore the tag
    MOVL    Reax,Recx       ;# clobber %Recx
    ret
CALLMACRO   RegMask shift_left_word,(M_Reax OR M_Recx)

shift_right_word:
 ;# Word.>>(a,b) is defined to return 0 if b > Word.wordSize
IFNDEF HOSTARCHITECTURE_X86_64
    CMPL    CONST TAGGED(31),Rebx
ELSE
    CMPL    CONST TAGGED(63),Rebx
ENDIF
    jb      srw1
    MOVL    CONST ZERO,Reax
    ret
srw1:
    MOVL    Rebx,Recx
    SHRL    CONST TAGSHIFT,Recx ;# remove tag
    SHRL    R_cl,Reax
    ORL     CONST TAG,Reax  ;# restore the tag
    MOVL    Reax,Recx       ;# clobber %Recx
    ret
CALLMACRO   RegMask shift_right_word,(M_Reax OR M_Recx)

shift_right_arith_word:
 ;# Word.~>>(a,b) is defined to return 0 or ~1 if b > Word.wordSize
 ;# The easiest way to do that is to set the shift to 31.
IFNDEF HOSTARCHITECTURE_X86_64
    CMPL    CONST TAGGED(31),Rebx
ELSE
    CMPL    CONST TAGGED(63),Rebx
ENDIF
    jb      sra1
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    CONST TAGGED(31),Rebx
ELSE
    MOVL    CONST TAGGED(63),Rebx
ENDIF
sra1:
    MOVL    Rebx,Recx
    SHRL    CONST TAGSHIFT,Recx ;# remove tag
    SARL    R_cl,Reax
    ORL     CONST TAG,Reax  ;# restore the tag
    MOVL    Reax,Recx       ;# clobber %Recx
    ret
CALLMACRO   RegMask shift_right_arith_word,(M_Reax OR M_Recx)

;# Clears the "mutable" bit on a segment
locksega:
IFDEF WINDOWS
    and     byte ptr    [Reax-1],CONST(0ffh-B_mutable)
ELSE
    andb    CONST(0xff-B_mutable),-1[Reax]
ENDIF
    MOVL     CONST TAGGED(0),Reax   ;# Return Unit,
    ret
CALLMACRO   RegMask lockseg,M_Reax

get_length_a:
    MOVL    (-POLYWORDSIZE)[Reax],Reax
    SHLL    CONST 8,Reax            ;# Clear top byte
    SHRL    CONST(8-TAGSHIFT),Reax  ;# Make it a tagged integer
    ORL CONST TAG,Reax
    ret
CALLMACRO   RegMask get_length,(M_Reax)


is_shorta:
;# Returns true if the argument is tagged
    ANDL    CONST TAG,Reax
    jz      RetFalse
    jmp     RetTrue
CALLMACRO   RegMask is_short,(M_Reax)

string_length:
    TESTL   CONST TAG,Reax  ;# Single char strings are represented by the
    jnz     RetOne      ;# character.
    MOVL    [Reax],Reax ;# Get length field
CALLMACRO   MAKETAGGED  Reax,Reax
    ret
RetOne: MOVL    CONST TAGGED(1),Reax
    ret
CALLMACRO   RegMask string_length,(M_Reax)

 ;# Store the length of a string in the first word.
set_string_length_a:
    SHRL    CONST TAGSHIFT,Rebx ;# Untag the length
    MOVL    Rebx,[Reax]
    MOVL    CONST UNIT,Reax     ;# Return unit
    MOVL    Reax,Rebx           ;# Clobber untagged value
    ret
CALLMACRO   RegMask set_string_length,(M_Reax OR M_Rebx)

;# raisex (formerly raisexn) is used by compiled code.
raisex:
    MOVL    HandlerRegister[Rebp],Recx    ;# Get next handler into %rcx

IFDEF WINDOWS
    jmp     FULLWORD ptr [Recx]
ELSE
    jmp     *[Recx]
ENDIF

load_byte:
    MOVL    Rebx,Redi
    SHRL    CONST TAGSHIFT,Redi
IFDEF WINDOWS
    movzx   Redi, byte ptr [Reax][Redi]
ELSE
IFNDEF HOSTARCHITECTURE_X86_64
    movzbl  (Reax,Redi,1),Redi
ELSE
    movzbq  (Reax,Redi,1),Redi
ENDIF
ENDIF
CALLMACRO   MAKETAGGED  Redi,Reax
    MOVL    Reax,Redi       ;# Clobber bad value in %Redi
    ret
CALLMACRO   RegMask load_byte,(M_Reax OR M_Redi)

load_word:
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    (-2)[Reax+Rebx*2],Reax
ELSE
    MOVL    (-4)[Reax+Rebx*4],Reax
ENDIF
    MOVL    Reax,Rebx
    ret
CALLMACRO   RegMask load_word,(M_Reax)

assign_byte:
;# We can assume that the data value will not overflow 30 bits (it is only 1 byte!)
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    4[Resp],Recx
ELSE
    MOVL    R8,Recx
ENDIF
    SHRL    CONST TAGSHIFT,Recx       ;# Remove tags from data value

;# We can assume that the index will not overflow 30 bits i.e. it is a tagged short
    SHRL    CONST TAGSHIFT,Rebx     ;# Remove tags from offset
    MOVB    R_cl,[Reax+Rebx]

    MOVL    CONST UNIT,Reax             ;# The function returns unit
    MOVL    Reax,Rebx                   ;# Clobber bad value in %Rebx
    MOVL    Reax,Recx                   ;# and %Recx
IFNDEF HOSTARCHITECTURE_X86_64
    ret     CONST 4
ELSE
    ret
ENDIF
CALLMACRO   RegMask assign_byte,(M_Reax OR M_Rebx OR M_Recx)


assign_word:
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    4[Resp],Recx
    MOVL    Recx,(-2)[Reax+Rebx*2]
ELSE
    MOVL    R8,(-4)[Reax+Rebx*4]      ;# The offset is tagged already
ENDIF
    MOVL    CONST UNIT,Reax           ;# The function returns unit
IFNDEF HOSTARCHITECTURE_X86_64
    ret     CONST 4
CALLMACRO   RegMask assign_word,(M_Reax OR M_Recx)
ELSE
    ret
CALLMACRO   RegMask assign_word,(M_Reax)
ENDIF

;# Allocate a piece of memory that does not need to be initialised.
;# We can't actually risk leaving word objects uninitialised so for the
;# moment we always initialise.
alloc_uninit:
IFDEF HOSTARCHITECTURE_X86_64
    MOVL    CONST ZERO,R8
ELSE
    POP     Recx         ;# Get the return address
    PUSHL   CONST ZERO   ;# Push the initial value - zero
    PUSHL   Recx         ;# Restore the return address
ENDIF
;# Drop through into alloc_store

IFNDEF HOSTARCHITECTURE_X86_64
CALLMACRO   RegMask alloc_uninit,Mask_all ;# All, because we may call RTS
ELSE
CALLMACRO   RegMask alloc_uninit,Mask_all ;# All, because we may call RTS
ENDIF

;# alloc(size, flags, initial).  Allocates a segment of a given size and
;# initialises it.
;#
;# This is primarily used for arrays and for strings.  Refs are
;# allocated using inline code.
alloc_store:
allsts:
 ;# alloc(size, flags, initial).  Allocates a segment of a given size and
 ;# initialises it.
 ;# First check that the length is acceptable
    TESTL   CONST TAG,Reax
    jz      alloc_in_rts            ;# Get the RTS to raise an exception
    MOVL    Reax,Redi
    SHRL    CONST TAGSHIFT,Redi     ;# Remove tag
    jnz     allst0                  ;# (test for 0) Make zero sized objects 1
    MOVL    CONST 1,Redi            ;# because they mess up the g.c.
    jmp     alloc_in_rts
allst0:
IFNDEF HOSTARCHITECTURE_X86_64
    CMPL    CONST Max_Length,Redi   ;# Length field must fit in 24 bits
ELSE
    MOVL    CONST Max_Length,Redx   ;# Length field must fit in 56 bits
    CMPL    Redx,Redi
ENDIF
    ja      alloc_in_rts            ;# Get the RTS to raise an exception
IFNDEF HOSTARCHITECTURE_X86_64
    INCL    Redi                    ;# Add 1 word
    SHLL    CONST 2,Redi            ;# Get length in bytes
    MOVL    LocalMpointer[Rebp],Redx
ELSE
    ADDL    CONST 1,Redi            ;# Add 1 word
    SHLL    CONST 3,Redi            ;# Get length in bytes
    MOVL    R15,Redx
ENDIF
    SUBL    Redi,Redx               ;# Allocate the space
    MOVL    Reax,Redi               ;# Clobber bad value in Redi
    CMPL    LocalMbottom[Rebp],Redx            ;# Check for free space
    jb      alloc_in_rts
;# Normally the above test is sufficient but if LocalMpointer is near the bottom of
;# memory and the store requested is very large the value in Redx can be negative
;# which is greater, unsigned, than LocalMbottom.  We have to check it is less
;# than, unsigned, the allocation pointer.
IFNDEF HOSTARCHITECTURE_X86_64
    CMPL    LocalMpointer[Rebp],Redx
    jnb     alloc_in_rts
    MOVL    Redx,LocalMpointer[Rebp]             ;# Put back in the heap ptr
ELSE
    CMPL    R15,Redx
    jnb     alloc_in_rts
    MOVL    Redx,R15                 ;# Put back in the heap ptr
ENDIF
    SHRL    CONST TAGSHIFT,Reax
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    Reax,(-4)[Redx]         ;# Put in length
ELSE
    MOVL    Reax,(-8)[Redx]         ;# Put in length
ENDIF
    SHRL    CONST TAGSHIFT,Rebx     ;# remove tag from flag
    ORL     CONST B_mutable,Rebx    ;# set mutable bit
    MOVB    R_bl,(-1)[Redx]         ;# and put it in.
 ;# Initialise the store.
    MOVL    Reax,Recx               ;# Get back the no. of words.
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    4[Resp],Reax            ;# Get initial value.
ELSE
    MOVL    R8,Reax                 ;# Get initial value.
ENDIF
    CMPL    CONST B_mutablebytes,Rebx
    jne     allst2

 ;# If this is a byte seg
    SHRL    CONST TAGSHIFT,Reax ;# untag the initialiser
IFNDEF HOSTARCHITECTURE_X86_64
    SHLL    CONST 2,Recx        ;# Convert to bytes
ELSE
    SHLL    CONST 3,Recx        ;# Convert to bytes
ENDIF
    MOVL    Redx,Redi
IFDEF WINDOWS
    rep stosb
ELSE
    rep
    stosb
ENDIF
    jmp     allst3

 ;# If this is a word segment
allst2:
    MOVL    Redx,Redi
IFDEF WINDOWS
IFNDEF HOSTARCHITECTURE_X86_64
    rep stosd
ELSE
    rep stosq
ENDIF
ELSE
    rep
IFNDEF HOSTARCHITECTURE_X86_64
    stosl
ELSE
    stosq
ENDIF
ENDIF

allst3:
    MOVL    Redx,Reax

    MOVL    Reax,Recx       ;# Clobber these
    MOVL    Reax,Redx
    MOVL    Reax,Rebx
    MOVL    Reax,Redi
IFNDEF HOSTARCHITECTURE_X86_64
    ret     CONST 4
ELSE
    ret
ENDIF
CALLMACRO   RegMask alloc_store,Mask_all ;# All, because we may use RTS call

;# This is used if we have reached the store limit and need to garbage-collect.
alloc_in_rts:
    MOVL    Reax,Redx       ;# Clobber these first
    MOVL    Reax,Redi
CALLMACRO   CALL_IO    POLY_SYS_alloc_store

touch_final:
;# This is really a pseudo-op
    MOVL    CONST UNIT,Reax
CALLMACRO   RegMask touch_final,(M_Reax)

add_long:
    MOVL    Reax,Redi
    ANDL    Rebx,Redi
    ANDL    CONST TAG,Redi
    jz      add_really_long
    LEAL    (-TAG)[Reax],Redi
    ADDL    Rebx,Redi
    jo      add_really_long
    MOVL    Redi,Reax
    ret
add_really_long:
    MOVL    Reax,Redi
CALLMACRO   CALL_IO    POLY_SYS_aplus
CALLMACRO   RegMask aplus,(M_Reax OR M_Redi OR Mask_all)

sub_long:
    MOVL    Reax,Redi
    ANDL    Rebx,Redi
    ANDL    CONST TAG,Redi
    jz      sub_really_long
    MOVL    Reax,Redi
    SUBL    Rebx,Redi
    jo      sub_really_long
    LEAL    TAG[Redi],Reax      ;# Put back the tag
    MOVL    Reax,Redi
    ret
sub_really_long:
    MOVL    Reax,Redi
CALLMACRO   CALL_IO    POLY_SYS_aminus
CALLMACRO   RegMask aminus,(M_Reax OR M_Redi OR Mask_all)

mult_long:
    MOVL    Reax,Redi
    ANDL    Rebx,Redi
    ANDL    CONST TAG,Redi
    jz      mul_really_long
    MOVL    Rebx,Redi
    SARL    CONST TAGSHIFT,Redi ;# Shift multiplicand
    MOVL    Reax,Resi
    SUBL    CONST TAG,Resi          ;# Just subtract off the tag off multiplier
    IMULL   Redi,Resi
    jo      mul_really_long
    ADDL    CONST TAG,Resi
    MOVL    Resi,Reax
    MOVL    Reax,Redi
    ret
mul_really_long:
    MOVL    Reax,Resi       ;# Clobber this
    MOVL    Reax,Redi
CALLMACRO   CALL_IO    POLY_SYS_amul
CALLMACRO   RegMask amul,(M_Reax OR M_Redi OR M_Resi OR Mask_all)

div_long:
    MOVL    Reax,Redi
    ANDL    Rebx,Redi
    ANDL    CONST TAG,Redi          ;# %Redi now contains $0 or $1 (both legal!)
    jz      div_really_long
    CMPL    CONST TAGGED(0),Rebx    ;# Check that it's non-zero
    jz      div_really_long         ;# We don't want a trap.
 ;# The only case of overflow is dividing the smallest negative number by -1
    CMPL    CONST TAGGED((-1)),Rebx
    jz      div_really_long
    SARL    CONST TAGSHIFT,Reax
    MOVL    Rebx,Redi
    SARL    CONST TAGSHIFT,Redi
IFNDEF HOSTARCHITECTURE_X86_64
    cdq
ELSE
    cqo
ENDIF
    idiv    Redi
CALLMACRO   MAKETAGGED  Reax,Reax
    MOVL    Reax,Redx
    MOVL    Reax,Redi
    ret
div_really_long:
    MOVL    Reax,Redi
CALLMACRO   CALL_IO    POLY_SYS_adiv
CALLMACRO   RegMask adiv,(M_Reax OR M_Redi OR M_Redx OR Mask_all)

rem_long:
    MOVL    Reax,Redi
    ANDL    Rebx,Redi
    ANDL    CONST TAG,Redi      ;# %Redi now contains $0 or $1 (both legal!
    jz      rem_really_long
    CMPL    CONST TAGGED(0),Rebx    ;# Check that it's non-zero
    jz      rem_really_long         ;# We don't want a trap.
 ;# The only case of overflow is dividing the smallest negative number by -1
    CMPL    CONST TAGGED((-1)),Rebx
    jz      rem_really_long
    SARL    CONST TAGSHIFT,Reax
    MOVL    Rebx,Redi
    SARL    CONST TAGSHIFT,Redi
IFNDEF HOSTARCHITECTURE_X86_64
    cdq
ELSE
    cqo
ENDIF
    idiv    Redi
CALLMACRO   MAKETAGGED  Redx,Reax
    MOVL    Reax,Redx
    MOVL    Reax,Redi
    ret
rem_really_long:
    MOVL    Reax,Redi
CALLMACRO   CALL_IO    POLY_SYS_amod
CALLMACRO   RegMask amod,(M_Reax OR M_Redi OR M_Redx OR Mask_all)

 ;# Combined quotient and remainder.  We have to use the long form
 ;# if the arguments are long or there's an overflow.  The first two
 ;# arguments are the values to be divided.  The third argument is the
 ;# address where the results should be placed. 
quotrem_long:
    MOVL    Reax,Redi
    ANDL    Rebx,Redi
    ANDL    CONST TAG,Redi
    jz      quotrem_really_long
    CMPL    CONST TAGGED(0),Rebx
    jz      quotrem_really_long
 ;# The only case of overflow is dividing the smallest negative number by -1
    CMPL    CONST TAGGED((-1)),Rebx
    jz      quotrem_really_long

 ;# Get the address for the result.
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    4[Resp],Recx
ELSE
    MOVL    R8,Recx
ENDIF
;# Do the division
    SARL    CONST TAGSHIFT,Reax
    MOVL    Rebx,Redi
    SARL    CONST TAGSHIFT,Redi
IFNDEF HOSTARCHITECTURE_X86_64
    cdq
ELSE
    cqo
ENDIF
    idiv    Redi
CALLMACRO   MAKETAGGED  Reax,Reax
CALLMACRO   MAKETAGGED  Redx,Redx
    MOVL    Reax,Redi
    MOVL    Reax,[Recx]
    MOVL    Redx,POLYWORDSIZE[Recx]
    MOVL    Recx,Reax
IFNDEF HOSTARCHITECTURE_X86_64
    ret     CONST 4
ELSE
    ret
ENDIF

mem_for_remquot1:  ;# Not enough store: clobber bad value in ecx.
    MOVL   CONST 1,Recx

quotrem_really_long:
    MOVL    Reax,Redi
CALLMACRO   CALL_IO    POLY_SYS_quotrem
CALLMACRO   RegMask quotrem,(M_Reax OR M_Redi OR M_Redx OR Mask_all)

equal_long:
    CMPL    Reax,Rebx
    je      RetTrue
    MOVL    Reax,Recx   ;# If either is short
    ORL     Rebx,Reax   ;# the result is false
    ANDL    CONST TAG,Reax
    jnz     RetFalse
    MOVL    Recx,Reax
CALLMACRO   CALL_IO    POLY_SYS_equala
CALLMACRO   RegMask equala,(M_Reax OR M_Recx OR Mask_all)


or_long:
IFDEF NOTATTHEMOMENT
    MOVL    Reax,Redi
    ANDL    Rebx,Redi
    ANDL    CONST TAG,Redi
    jz      or_really_long
    ORL     Rebx,Reax
    MOVL    Reax,Redi
    ret
or_really_long:
ENDIF
CALLMACRO   CALL_IO    POLY_SYS_ora
CALLMACRO   RegMask ora,(M_Reax OR M_Redi OR Mask_all)

xor_long:
IFDEF NOTATTHEMOMENT
    MOVL    Reax,Redi
    ANDL    Rebx,Redi
    ANDL    CONST TAG,Redi
    jz      xor_really_long
    XORL    Rebx,Reax
    ORL     CONST TAG,Reax  ;# restore the tag
    MOVL    Reax,Redi
    ret
xor_really_long:
ENDIF
CALLMACRO   CALL_IO    POLY_SYS_xora
CALLMACRO   RegMask xora,(M_Reax OR M_Redi OR Mask_all)

and_long:
IFDEF NOTATTHEMOMENT
    MOVL    Reax,Redi
    ANDL    Rebx,Redi
    ANDL    CONST TAG,Redi
    jz      and_really_long
    ANDL    Rebx,Reax
    MOVL    Reax,Redi
    ret
and_really_long:
ENDIF
CALLMACRO   CALL_IO    POLY_SYS_anda
CALLMACRO   RegMask anda,(M_Reax OR M_Redi OR Mask_all)

neg_long:
    TESTL   CONST TAG,Reax
    jz      neg_really_long
    MOVL    CONST (TAGGED(0)+TAG),Redi
    SUBL    Reax,Redi
    jo      neg_really_long
    MOVL    Redi,Reax
    ret
neg_really_long:
    MOVL    Reax,Redi
CALLMACRO   CALL_IO    POLY_SYS_aneg
CALLMACRO   RegMask aneg,(M_Reax OR M_Redi OR Mask_all)

int_geq:
    TESTL   CONST TAG,Reax ;# Is first arg short?
    jz      igeq2
    TESTL   CONST TAG,Rebx ;# Is second arg short?
    jz      igeq1
    CMPL    Rebx,Reax
    jge     RetTrue
    jmp     RetFalse
igeq1:
 ;# First arg is short, second isn't
IFDEF WINDOWS
    test    byte ptr [Rebx-1],CONST 16  ;# 16 is the "negative" bit
ELSE
    testb   CONST 16,(-1)[Rebx]     ;# 16 is the "negative" bit
ENDIF
    jnz     RetTrue     ;# Negative - always less
    jmp     RetFalse

igeq2:
 ;# First arg is long
    TESTL   CONST TAG,Rebx ;# Is second arg short?
    jz      igeq3
 ;# First arg is long, second is short
IFDEF WINDOWS
    test    byte ptr [Reax-1],CONST 16  ;# 16 is the "negative" bit
ELSE
    testb   CONST 16,(-1)[Reax]     ;# 16 is the "negative" bit
ENDIF
    jz      RetTrue    ;# Positive - always greater
    jmp     RetFalse

igeq3:
 ;# Both long
CALLMACRO   CALL_IO    POLY_SYS_int_geq
CALLMACRO   RegMask int_geq,(M_Reax OR Mask_all)


int_leq:
    TESTL   CONST TAG,Reax ;# Is first arg short?
    jz      ileq2
    TESTL   CONST TAG,Rebx ;# Is second arg short?
    jz      ileq1
    CMPL    Rebx,Reax
    jle     RetTrue
    jmp     RetFalse
ileq1:
 ;# First arg is short, second isn't
IFDEF WINDOWS
    test    byte ptr [Rebx-1],CONST 16  ;# 16 is the "negative" bit
ELSE
    testb   CONST 16,(-1)[Rebx]     ;# 16 is the "negative" bit
ENDIF
    jz      RetTrue     ;# Negative - always less
    jmp     RetFalse

ileq2:
 ;# First arg is long
    TESTL   CONST TAG,Rebx ;# Is second arg short?
    jz      ileq3
 ;# First arg is long, second is short
IFDEF WINDOWS
    test    byte ptr [Reax-1],CONST 16  ;# 16 is the "negative" bit
ELSE
    testb   CONST 16,(-1)[Reax]     ;# 16 is the "negative" bit
ENDIF
    jnz     RetTrue    ;# Positive - always greater
    jmp     RetFalse

ileq3:
CALLMACRO   CALL_IO    POLY_SYS_int_leq
CALLMACRO   RegMask int_leq,(M_Reax OR M_Recx OR Mask_all)


int_gtr:
    TESTL   CONST TAG,Reax ;# Is first arg short?
    jz      igtr2
    TESTL   CONST TAG,Rebx ;# Is second arg short?
    jz      igtr1
    CMPL    Rebx,Reax
    jg      RetTrue
    jmp     RetFalse
igtr1:
 ;# First arg is short, second isn't
IFDEF WINDOWS
    test    byte ptr [Rebx-1],CONST 16  ;# 16 is the "negative" bit
ELSE
    testb   CONST 16,(-1)[Rebx]     ;# 16 is the "negative" bit
ENDIF
    jnz     RetTrue     ;# Negative - always less
    jmp     RetFalse

igtr2:
 ;# First arg is long
    TESTL   CONST TAG,Rebx ;# Is second arg short?
    jz      igtr3
 ;# First arg is long, second is short
IFDEF WINDOWS
    test    byte ptr [Reax-1],CONST 16  ;# 16 is the "negative" bit
ELSE
    testb   CONST 16,(-1)[Reax]     ;# 16 is the "negative" bit
ENDIF
    jz      RetTrue    ;# Positive - always greater
    jmp     RetFalse

igtr3:
CALLMACRO   CALL_IO    POLY_SYS_int_gtr
CALLMACRO   RegMask int_gtr,(M_Reax OR M_Recx OR Mask_all)


int_lss:
    TESTL   CONST TAG,Reax ;# Is first arg short?
    jz      ilss2
    TESTL   CONST TAG,Rebx ;# Is second arg short?
    jz      ilss1
    CMPL    Rebx,Reax
    jl      RetTrue
    jmp     RetFalse
ilss1:
 ;# First arg is short, second isn't
IFDEF WINDOWS
    test    byte ptr [Rebx-1],CONST 16  ;# 16 is the "negative" bit
ELSE
    testb   CONST 16,(-1)[Rebx]     ;# 16 is the "negative" bit
ENDIF
    jz      RetTrue     ;# Negative - always less
    jmp     RetFalse

ilss2:
 ;# First arg is long
    TESTL   CONST TAG,Rebx ;# Is second arg short?
    jz      ilss3
 ;# First arg is long, second is short
IFDEF WINDOWS
    test    byte ptr [Reax-1],CONST 16  ;# 16 is the "negative" bit
ELSE
    testb   CONST 16,(-1)[Reax]     ;# 16 is the "negative" bit
ENDIF
    jnz     RetTrue    ;# Positive - always greater
    jmp     RetFalse

ilss3:
CALLMACRO   CALL_IO    POLY_SYS_int_lss
CALLMACRO   RegMask int_lss,(M_Reax OR M_Recx OR Mask_all)

offset_address:
 ;# This is needed in the code generator, but is a very risky thing to do.
    SHRL    CONST TAGSHIFT,Rebx     ;# Untag
    ADDL    Rebx,Reax       ;# and add in
    MOVL    Reax,Rebx
    ret
CALLMACRO   RegMask offset_address,(M_Reax OR M_Rebx)

;# General test routine.  Returns with the condition codes set
;# appropriately.

teststr:
    TESTL   CONST TAG,Reax     ;# Is arg1 short
    jz      tststr1
    TESTL   CONST TAG,Rebx     ;# Yes: is arg2 also short?
    jz      tststr0a
    ;# Both are short - just compare the characters
    CMPL    Rebx,Reax
    ret

tststr0a:
    MOVL    CONST 1,Redi        ;# Is arg2 the null string ?
    CMPL    [Rebx],Redi
    jg      tststr4            ;# Return with "gtr" set if it is
    SHRL    CONST TAGSHIFT,Reax
    CMPB    POLYWORDSIZE[Rebx],R_al
    jne     tststr4            ;# If they're not equal that's the result
    CMPL    CONST 256,Reax     ;# But if they're equal set "less" because A is less than B
    jmp     tststr4

tststr1: ;# arg2 is not short.  Is arg1 ?
    TESTL   CONST TAG,Rebx
    jz      tststr2
    MOVL    [Reax],Redi        ;# Is arg1 the null string
    CMPL    CONST 1,Redi
    jl      tststr4            ;# Return with "less" set if it is
    SHRL    CONST TAGSHIFT,Rebx
    MOVB    POLYWORDSIZE[Reax],R_cl
    CMPB    R_bl,R_cl
    jne     tststr4            ;# If they're not equal that's the result
    CMPL    CONST 0,Redi      ;# But if they're equal set "greater" because A is greater than B
    jmp     tststr4

tststr2:
    MOVL    [Reax],Redi     ;# Get length.
    MOVL    [Rebx],Recx     ;# 
    CMPL    Recx,Redi       ;# Find shorter length
    jge     tststr3
    MOVL    Redi,Recx
tststr3:
    LEAL    POLYWORDSIZE[Reax],Resi    ;# Load ptrs for cmpsb
    LEAL    POLYWORDSIZE[Rebx],Redi
    cld                 ;# Make sure we increment
    CMPL    Reax,Reax       ;# Set the Zero bit
IFDEF WINDOWS
    repe cmpsb          ;# Compare while equal and Recx > 0
ELSE
    repe    
IFNDEF HOSTARCHITECTURE_X86_64
    cmpsb           ;# Compare while equal and %ecx > 0
ELSE
    cmpsb           ;# Compare while equal and %rcx > 0
ENDIF
ENDIF
    jnz     tststr4
 ;# Strings are equal as far as the shorter of the two.  Have to compare
 ;# the lengths.
    MOVL    [Reax],Redi
    CMPL    [Rebx],Redi
tststr4:
    MOVL    CONST 1,Reax      ;# Clobber these
    MOVL    Reax,Rebx       
    MOVL    Reax,Recx       
    MOVL    Reax,Resi
    MOVL    Reax,Redi
    ret

 ;# These functions compare strings for lexical ordering.  This version, at
 ;# any rate, assumes that they are UNSIGNED bytes.

str_compare:
    call    teststr
    ja      RetTrue         ;# Return TAGGED(1) if it's greater
    je      RetFalse        ;# Return TAGGED(0) if it's equal
    MOVL    CONST MINUS1,Reax   ;# Return TAGGED(-1) if it's less.
    ret
CALLMACRO   RegMask str_compare,(M_Reax OR M_Recx OR M_Redi OR M_Resi)


teststrgeq:
    call    teststr
    jnb     RetTrue
    jmp     RetFalse
CALLMACRO   RegMask teststrgeq,(M_Reax OR M_Recx OR M_Redi OR M_Resi)

teststrleq:
    call    teststr
    jna     RetTrue
    jmp     RetFalse
CALLMACRO   RegMask teststrleq,(M_Reax OR M_Recx OR M_Redi OR M_Resi)

teststrlss:
    call    teststr
    jb      RetTrue
    jmp     RetFalse
CALLMACRO   RegMask teststrlss,(M_Reax OR M_Recx OR M_Redi OR M_Resi)

teststrgtr:
    call    teststr
    ja      RetTrue
    jmp     RetFalse
CALLMACRO   RegMask teststrgtr,(M_Reax OR M_Recx OR M_Redi OR M_Resi)


bytevec_eq:
 ;# Compare arrays of bytes.  The arguments are the same as move_bytes.
 ;# (source, sourc_offset, destination, dest_offset, length)

 ;# Assume that the offsets and length are all short integers.
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    12[Resp],Redi               ;# Destination address
    MOVL    8[Resp],Recx                ;# Destination offset, untagged
ELSE
    MOVL    R8,Redi                     ;# Destination address
    MOVL    R9,Recx                     ;# Destination offset, untagged
ENDIF
    SHRL    CONST TAGSHIFT,Recx
    ADDL    Recx,Redi
    MOVL    Reax,Resi                   ;# Source address
    SHRL    CONST TAGSHIFT,Rebx
    ADDL    Rebx,Resi
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    4[Resp],Recx                ;# Get the length to move
ELSE
    MOVL    R10,Recx                    ;# Get the length to move
ENDIF
    SHRL    CONST TAGSHIFT,Recx

    cld                     ;# Make sure we increment
    CMPL    Reax,Reax       ;# Set the Zero bit
IFDEF WINDOWS
    repe    cmpsb
ELSE
    repe    
    cmpsb
ENDIF
    MOVL    Reax,Resi       ;# Make these valid
    MOVL    Reax,Recx
    MOVL    Reax,Redi
    jz      bvTrue
    MOVL    CONST FALSE,Reax
    jmp     bvRet
bvTrue:
    MOVL    CONST TRUE,Reax
bvRet:
IFNDEF HOSTARCHITECTURE_X86_64
    ret     CONST 12
ELSE
    ret
ENDIF
CALLMACRO   RegMask bytevec_eq,(M_Reax OR M_Recx OR M_Redi OR M_Resi)


is_big_endian:
    jmp     RetFalse    ;# I386/486 is little-endian
CALLMACRO   RegMask is_big_endian,(M_Reax)

bytes_per_word:
    MOVL    CONST TAGGED(POLYWORDSIZE),Reax  ;# 4/8 bytes per word
    ret
CALLMACRO   RegMask bytes_per_word,(M_Reax)

 ;# Word functions.  These are all unsigned and do not raise Overflow
 
mul_word:
    SHRL    CONST TAGSHIFT,Rebx ;# Untag the multiplier
    SUBL    CONST TAG,Reax      ;# Remove the tag from the multiplicand
    MULL    Rebx                ;# unsigned multiplication
    ADDL    CONST TAG,Reax      ;# Add back the tag, but don`t shift
    MOVL    Reax,Redx           ;# clobber this which has the high-end result
    MOVL    Reax,Rebx           ;# and the other bad result.
    ret
CALLMACRO   RegMask mul_word,(M_Reax OR M_Rebx OR M_Redx)

plus_word:
    LEAL    (-TAG)[Reax+Rebx],Reax  ;# Add the values and subtract a tag
    ret
CALLMACRO   RegMask plus_word,(M_Reax)

minus_word:
    SUBL    Rebx,Reax
    ADDL    CONST TAG,Reax          ;# Put back the tag
    ret
CALLMACRO   RegMask minus_word,(M_Reax)

div_word:
    SHRL    CONST TAGSHIFT,Rebx
    jz      raise_div_ex
    SHRL    CONST TAGSHIFT,Reax
    MOVL    CONST 0,Redx
    div     Rebx
CALLMACRO   MAKETAGGED  Reax,Reax
    MOVL    Reax,Redx
    MOVL    Reax,Rebx
    ret
CALLMACRO   RegMask div_word,(M_Reax OR M_Rebx OR M_Redx)

mod_word:
    SHRL    CONST TAGSHIFT,Rebx
    jz      raise_div_ex
    SHRL    CONST TAGSHIFT,Reax
    MOVL    CONST 0,Redx
    div     Rebx
CALLMACRO   MAKETAGGED  Redx,Reax
    MOVL    Reax,Redx
    MOVL    Reax,Rebx
    ret
CALLMACRO   RegMask mod_word,(M_Reax OR M_Rebx OR M_Redx)

raise_div_ex:
IFDEF WINDOWS
    jmp     FULLWORD ptr [RaiseDiv+Rebp]
ELSE
    jmp     *RaiseDiv[Rebp]
ENDIF

word_eq:
    CMPL    Rebx,Reax
    jz      RetTrue         ;# True if they are equal.
    jmp     RetFalse
CALLMACRO   RegMask word_eq,(M_Reax)

word_neq:
    CMPL    Rebx,Reax
    jz      RetFalse
    jmp     RetTrue
CALLMACRO   RegMask word_neq,(M_Reax)

word_geq:
    CMPL    Rebx,Reax
    jnb     RetTrue
    jmp     RetFalse
CALLMACRO   RegMask word_geq,(M_Reax)

word_leq:
    CMPL    Rebx,Reax
    jna     RetTrue
    jmp     RetFalse
CALLMACRO   RegMask word_leq,(M_Reax)

word_gtr:
    CMPL    Rebx,Reax
    ja      RetTrue
    jmp     RetFalse
CALLMACRO   RegMask word_gtr,(M_Reax)

 word_lss:
    CMPL    Rebx,Reax
    jb      RetTrue
    jmp     RetFalse
CALLMACRO   RegMask word_lss,(M_Reax)

;# Atomically increment the value at the address of the arg and return the
;# updated value.  Since the xadd instruction returns the original value
;# we have to increment it.
atomic_increment:
atomic_incr:                    ;# Internal name in case "atomic_increment" is munged.
    MOVL    CONST 2,Rebx
    LOCKXADDL Rebx,[Reax]
    ADDL    CONST 2,Rebx
    MOVL    Rebx,Reax
    ret

CALLMACRO   RegMask atomic_incr,(M_Reax OR M_Rebx)

;# Atomically decrement the value at the address of the arg and return the
;# updated value.  Since the xadd instruction returns the original value
;# we have to decrement it.
atomic_decrement:
atomic_decr:
    MOVL    CONST -2,Rebx
    LOCKXADDL Rebx,[Reax]
    MOVL    Rebx,Reax
    SUBL    CONST 2,Reax
    ret

CALLMACRO   RegMask atomic_decr,(M_Reax OR M_Rebx)

;# Reset a mutex to (tagged) one.  Because the increment and decrements
;# are atomic this doesn't have to do anything special.
atomic_reset:
IFDEF WINDOWS
    mov     FULLWORD ptr [Reax],3 
ELSE
    MOVL    CONST 3,[Reax]
ENDIF
    MOVL    CONST UNIT,Reax  ;# The function returns unit
    ret

CALLMACRO   RegMask atomic_reset,M_Reax

;# Return the thread id object for the current thread
thread_self:
    MOVL    ThreadId[Rebp],Reax
    ret
CALLMACRO   RegMask thread_self,(M_Reax)



;# Memory for LargeWord.word values.  This is the same as mem_for_real on
;# 64-bits but only a single word on 32-bits.
mem_for_largeword:
IFNDEF HOSTARCHITECTURE_X86_64
        MOVL    LocalMpointer[Rebp],Recx
        SUBL    CONST 8,Recx        ;# Length word (4 bytes) + 4 bytes
IFDEF TEST_ALLOC
;# Test case - this will always force a call into RTS.
        CMPL    LocalMpointer[Rebp],Recx
ELSE
        CMPL    LocalMbottom[Rebp],Recx
ENDIF
        jb      mem_for_real1
        MOVL    Recx,LocalMpointer[Rebp] ;# Updated allocation pointer
IFDEF WINDOWS
        mov     FULLWORD ptr (-4)[Recx],01000001h  ;# Length word:
ELSE
        MOVL    CONST 0x01000001,(-4)[Recx]     ;# Length word
ENDIF
        ret
ENDIF
;# Else if it is 64-bits just drop through

;# FLOATING POINT
;# If we have insufficient space for the result we call in to
;# main RTS to do the work.  The reason for this is that it is
;# not safe to make a call into memory allocator and then
;# continue with the rest of the floating point operation
;# because that would produce a return address pointing into the
;# assembly code itself.  It's possible that this is no longer
;# a problem.

mem_for_real:
;# Allocate memory for the result.
IFNDEF HOSTARCHITECTURE_X86_64
        MOVL    LocalMpointer[Rebp],Recx
        SUBL    CONST 12,Recx        ;# Length word (4 bytes) + 8 bytes
ELSE
        MOVL    R15,Recx
        SUBL    CONST 16,Recx        ;# Length word (8 bytes) + 8 bytes
ENDIF
IFDEF TEST_ALLOC
;# Test case - this will always force a call into RTS.
        CMPL    LocalMpointer[Rebp],Recx
ELSE
        CMPL    LocalMbottom[Rebp],Recx
ENDIF
        jb      mem_for_real1
IFNDEF HOSTARCHITECTURE_X86_64
        MOVL    Recx,LocalMpointer[Rebp] ;# Updated allocation pointer
IFDEF WINDOWS
        mov     FULLWORD ptr (-4)[Recx],01000002h  ;# Length word:
ELSE
        MOVL    CONST 0x01000002,(-4)[Recx]     ;# Two words plus tag
ENDIF
ELSE
        MOVL    Recx,R15                        ;# Updated allocation pointer
IFDEF WINDOWS
        mov    qword ptr (-8)[Recx],1   ;# One word
        mov    byte ptr (-1)[Recx],B_bytes  ;# Set the byte flag.
ELSE
        MOVL    CONST 1,(-8)[Recx]      ;# One word
        MOVB    CONST B_bytes,(-1)[Recx]    ;# Set the byte flag.
ENDIF
ENDIF
        ret
mem_for_real1:  ;# Not enough store: clobber bad value in ecx.
        MOVL   CONST 1,Recx
    ret


real_add:
        call    mem_for_real
    jb      real_add_1     ;# Not enough space - call RTS.
;# Do the operation and put the result in the allocated
;# space.
IFDEF WINDOWS
    FLD     qword ptr [Reax]
    FADD    qword ptr [Rebx]
    FSTP    qword ptr [Recx]
ELSE
    FLDL    [Reax]
    FADDL   [Rebx]
    FSTPL   [Recx]
ENDIF
    MOVL    Recx,Reax
    ret

real_add_1:
    CALLMACRO   CALL_IO    POLY_SYS_Add_real
;# The mask includes FP7 rather than FP0 because this pushes a value which
;# overwrites the bottom of the stack.
CALLMACRO   RegMask real_add,(M_Reax OR M_Recx OR M_Redx OR M_FP7 OR Mask_all)



real_sub:
        call    mem_for_real
    jb      real_sub_1     ;# Not enough space - call RTS.
;# Do the operation and put the result in the allocated
;# space.
IFDEF WINDOWS
    FLD     qword ptr [Reax]
    FSUB    qword ptr [Rebx]
    FSTP    qword ptr [Recx]
ELSE
    FLDL    [Reax]
    FSUBL   [Rebx]
    FSTPL   [Recx]
ENDIF
    MOVL    Recx,Reax
    ret

real_sub_1:
    CALLMACRO   CALL_IO    POLY_SYS_Sub_real

CALLMACRO   RegMask real_sub,(M_Reax OR M_Recx OR M_Redx OR M_FP7 OR Mask_all)


real_mul:
        call    mem_for_real
    jb      real_mul_1     ;# Not enough space - call RTS.
;# Do the operation and put the result in the allocated
;# space.
IFDEF WINDOWS
    FLD     qword ptr [Reax]
    FMUL    qword ptr [Rebx]
    FSTP    qword ptr [Recx]
ELSE
    FLDL    [Reax]
    FMULL   [Rebx]
    FSTPL   [Recx]
ENDIF
    MOVL    Recx,Reax
    ret

real_mul_1:
    CALLMACRO   CALL_IO    POLY_SYS_Mul_real

CALLMACRO   RegMask real_mul,(M_Reax OR M_Recx OR M_Redx OR M_FP7 OR Mask_all)


real_div:
        call    mem_for_real
    jb      real_div_1     ;# Not enough space - call RTS.
;# Do the operation and put the result in the allocated
;# space.
IFDEF WINDOWS
    FLD     qword ptr [Reax]
    FDIV    qword ptr [Rebx]
    FSTP    qword ptr [Recx]
ELSE
    FLDL    [Reax]
    FDIVL   [Rebx]
    FSTPL   [Recx]
ENDIF
    MOVL    Recx,Reax
    ret

real_div_1:
    CALLMACRO   CALL_IO    POLY_SYS_Div_real

CALLMACRO   RegMask real_div,(M_Reax OR M_Recx OR M_Redx OR M_FP7 OR Mask_all)


;# For all values except NaN it's possible to do this by a test such as
;# "if x < 0.0 then ~ x else x" but the test always fails for NaNs

real_abs:
    call    mem_for_real
    jb      real_abs_1     ;# Not enough space - call RTS.
;# Do the operation and put the result in the allocated
;# space.
;# N.B. Real.~ X is not the same as 0.0 - X.  Real.~ 0.0 is ~0.0;
IFDEF WINDOWS
    FLD     qword ptr [Reax]
    FABS
    FSTP    qword ptr [Recx]
ELSE
    FLDL    [Reax]
    FABS
    FSTPL   [Recx]
ENDIF
    MOVL    Recx,Reax
    ret

real_abs_1:
    CALLMACRO   CALL_IO    POLY_SYS_Abs_real

CALLMACRO   RegMask real_abs,(M_Reax OR M_Recx OR M_Redx OR M_FP7 OR Mask_all)


real_neg:
        call    mem_for_real
    jb      real_neg_1     ;# Not enough space - call RTS.
;# Do the operation and put the result in the allocated
;# space.
;# N.B. Real.~ X is not the same as 0.0 - X.  Real.~ 0.0 is ~0.0;
IFDEF WINDOWS
    FLD     qword ptr [Reax]
    FCHS
    FSTP    qword ptr [Recx]
ELSE
    FLDL    [Reax]
    FCHS
    FSTPL   [Recx]
ENDIF
    MOVL    Recx,Reax
    ret

real_neg_1:
    CALLMACRO   CALL_IO    POLY_SYS_Neg_real

CALLMACRO   RegMask real_neg,(M_Reax OR M_Recx OR M_Redx OR M_FP7 OR Mask_all)



real_eq:
IFDEF WINDOWS
    FLD     qword ptr [Reax]
    FCOMP   qword ptr [Rebx]
ELSE
    FLDL    [Reax]
    FCOMPL  [Rebx]
ENDIF
        FNSTSW  R_ax
;# Not all 64-bit processors support SAHF.
;# The result is true if the zero flag is set and parity flag clear.  
        ANDL    CONST 17408,Reax ;# 0x4400
        CMPL    CONST 16384,Reax ;# 0x4000
    je      RetTrue
    jmp     RetFalse
CALLMACRO   RegMask real_eq,(M_Reax OR M_FP7)


real_neq:
IFDEF WINDOWS
    FLD     qword ptr [Reax]
    FCOMP   qword ptr [Rebx]
ELSE
    FLDL    [Reax]
    FCOMPL  [Rebx]
ENDIF
        FNSTSW  R_ax
        ANDL    CONST 17408,Reax ;# 0x4400
        CMPL    CONST 16384,Reax ;# 0x4000
    jne     RetTrue
    jmp     RetFalse

CALLMACRO   RegMask real_neq,(M_Reax OR M_FP7)


real_lss:
;# Compare Rebx > Reax
IFDEF WINDOWS
    FLD     qword ptr [Rebx]
    FCOMP   qword ptr [Reax]
ELSE
    FLDL    [Rebx]
    FCOMPL  [Reax]
ENDIF
        FNSTSW  R_ax

;# True if the carry flag (C0), zero flag (C3) and parity (C2) are all clear
        ANDL    CONST 17664,Reax ;# 0x4500

    je      RetTrue
    jmp     RetFalse

CALLMACRO   RegMask real_lss,(M_Reax OR M_FP7)


real_gtr:
IFDEF WINDOWS
    FLD     qword ptr [Reax]
    FCOMP   qword ptr [Rebx]
ELSE
    FLDL    [Reax]
    FCOMPL  [Rebx]
ENDIF
        FNSTSW  R_ax

;# True if the carry flag (C0), zero flag (C3) and parity (C2) are all clear
        ANDL    CONST 17664,Reax ;# 0x4500

    je      RetTrue
    jmp     RetFalse

CALLMACRO   RegMask real_gtr,(M_Reax OR M_FP7)


real_leq:
;# Compare Rebx > Reax
IFDEF WINDOWS
    FLD     qword ptr [Rebx]
    FCOMP   qword ptr [Reax]
ELSE
    FLDL    [Rebx]
    FCOMPL  [Reax]
ENDIF
        FNSTSW  R_ax
;# True if the carry flag (C0) and parity (C2) are both clear
        ANDL    CONST 1280,Reax ;# 0x500

    je      RetTrue
    jmp     RetFalse

CALLMACRO   RegMask real_leq,(M_Reax OR M_FP7)


real_geq:
IFDEF WINDOWS
    FLD     qword ptr [Reax]
    FCOMP   qword ptr [Rebx]
ELSE
    FLDL    [Reax]
    FCOMPL  [Rebx]
ENDIF
        FNSTSW  R_ax
;# True if the carry flag (C0) and parity (C2) are both clear
        ANDL    CONST 1280,Reax ;# 0x500

    je      RetTrue
    jmp     RetFalse

CALLMACRO   RegMask real_geq,(M_Reax OR M_FP7)

real_from_int:
    TESTL   CONST TAG,Reax   ;# Is it long ?
    jz      real_float_1
    call    mem_for_real
    jb      real_float_1     ;# Not enough space - call RTS.
    SARL    CONST TAGSHIFT,Reax ;# Untag the value
    MOVL    Reax,RealTemp[Rebp] ;# Save it in a temporary (N.B. It's now untagged)
IFDEF WINDOWS
    FILD    FULLWORD ptr RealTemp[Rebp]
    FSTP    qword ptr [Recx]
ELSE
IFDEF HOSTARCHITECTURE_X86_64
    FILDQ   RealTemp[Rebp]
ELSE
    FILDL   RealTemp[Rebp]
ENDIF
    FSTPL   [Recx]
ENDIF
    MOVL    Recx,Reax
    ret

real_float_1:
    CALLMACRO   CALL_IO    POLY_SYS_int_to_real

CALLMACRO   RegMask real_from_int,(M_Reax OR M_Recx OR M_Redx OR M_FP7 OR Mask_all)

;# Additional assembly code routines

;# This template code is copied into a newly allocated piece of memory which
;# is set up to look like an ML function.
;# The code itself is called if a function set up with exception_trace
;# returns normally.  It removes the handler.
CALLMACRO INLINE_ROUTINE X86AsmRestoreHandlerAfterExceptionTraceTemplate
    ADDL    CONST POLYWORDSIZE,Resp       ;# Remove handler
    POPL    HandlerRegister[Rebp]
    RET
    NOP                         ;# Add an extra byte so we have 8 bytes on both X86 and X86_64

;# This is template code and must be position independent.
;# The length of this code (9 bytes) is built into X86Dependent::BuildExceptionTrace.
CALLMACRO INLINE_ROUTINE X86AsmGiveExceptionTraceFnTemplate
    NOP                                 ;# Two NOPs - for alignment
    NOP
    ;# The exception packet is the first argument.
IFDEF WINDOWS
        mov     byte ptr [RequestCode+Rebp],POLY_SYS_give_ex_trace_fn
        jmp     FULLWORD ptr [IOEntryPoint+Rebp]
ELSE
        MOVB    CONST POLY_SYS_give_ex_trace_fn,RequestCode[Rebp]
        jmp     *IOEntryPoint[Rebp]
ENDIF

;# This is template code for an RTS call to kill the current thread. 
CALLMACRO INLINE_ROUTINE X86AsmKillSelfTemplate
IFDEF WINDOWS
        mov     byte ptr [RequestCode+Rebp],POLY_SYS_kill_self
        jmp     FULLWORD ptr [IOEntryPoint+Rebp]
ELSE
        MOVB    CONST POLY_SYS_kill_self,RequestCode[Rebp]
        jmp     *IOEntryPoint[Rebp]
ENDIF

CALLMACRO INLINE_ROUTINE X86AsmCallbackReturnTemplate
IFDEF WINDOWS
        mov     byte ptr [ReturnReason+Rebp],RETURN_CALLBACK_RETURN
        jmp     FULLWORD ptr [IOEntryPoint+Rebp]
ELSE
        MOVB    CONST RETURN_CALLBACK_RETURN,ReturnReason[Rebp]
        jmp     *IOEntryPoint[Rebp]
ENDIF

CALLMACRO INLINE_ROUTINE X86AsmCallbackExceptionTemplate
IFDEF WINDOWS
        mov     byte ptr [ReturnReason+Rebp],RETURN_CALLBACK_EXCEPTION
        jmp     FULLWORD ptr [IOEntryPoint+Rebp]
ELSE
        MOVB    CONST RETURN_CALLBACK_EXCEPTION,ReturnReason[Rebp]
        jmp     *IOEntryPoint[Rebp]
ENDIF

;# This implements atomic addition in the same way as atomic_increment
CALLMACRO INLINE_ROUTINE X86AsmAtomicIncrement
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    4[Resp],Reax
ELSE
IFDEF WINDOWS
    MOVL    Recx,Reax   ;# The argument to the function is passed in Recx
ELSE
IFDEF _WIN32
    MOVL    Recx,Reax   ;# The argument to the function is passed in Recx
ELSE
    MOVL    Redi,Reax   ;# On X86_64 the argument is passed in Redi
ENDIF
ENDIF
ENDIF
;# Use Recx and Reax because they are volatile (unlike Rebx on X86/64/Unix)
    MOVL    CONST 2,Recx
    LOCKXADDL Recx,[Reax]
    ADDL    CONST 2,Recx
    MOVL    Recx,Reax
    ret


;# This implements atomic subtraction in the same way as atomic_decrement
CALLMACRO INLINE_ROUTINE X86AsmAtomicDecrement
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    4[Resp],Reax
ELSE
    MOVL    Redi,Reax            ;# On X86_64 the argument is passed in Redi
ENDIF
    MOVL    CONST -2,Recx
    LOCKXADDL Recx,[Reax]
    MOVL    Recx,Reax
    SUBL    CONST 2,Reax
    ret

;# LargeWord.word operations.  These are 32 or 64-bit values in a single-word byte
;# memory cell.
eq_longword:
    MOVL    [Reax],Reax
    CMPL    [Rebx],Reax
    jz      RetTrue         ;# True if they are equal.
    jmp     RetFalse
CALLMACRO   RegMask eq_longword,(M_Reax)

neq_longword:
    MOVL    [Reax],Reax
    CMPL    [Rebx],Reax
    jz      RetFalse
    jmp     RetTrue
CALLMACRO   RegMask neq_longword,(M_Reax)

geq_longword:
    MOVL    [Reax],Reax
    CMPL    [Rebx],Reax
    jnb     RetTrue
    jmp     RetFalse
CALLMACRO   RegMask geq_longword,(M_Reax)

leq_longword:
    MOVL    [Reax],Reax
    CMPL    [Rebx],Reax
    jna     RetTrue
    jmp     RetFalse
CALLMACRO   RegMask leq_longword,(M_Reax)

gt_longword:
    MOVL    [Reax],Reax
    CMPL    [Rebx],Reax
    ja      RetTrue
    jmp     RetFalse
CALLMACRO   RegMask gt_longword,(M_Reax)

lt_longword:
    MOVL    [Reax],Reax
    CMPL    [Rebx],Reax
    jb      RetTrue
    jmp     RetFalse
CALLMACRO   RegMask lt_longword,(M_Reax)

longword_to_tagged:
;# Load the value and tag it, discarding the top bit
    MOVL    [Reax],Reax
    CALLMACRO   MAKETAGGED  Reax,Reax
    ret
CALLMACRO   RegMask longword_to_tagged,(M_Reax)

signed_to_longword:
;# Shift the value to remove the tag and store it.
    call    mem_for_largeword
    jb      signed_to_longword1
    SARL    CONST TAGSHIFT,Reax         ;# Arithmetic shift, preserve sign
    MOVL    Reax,[Recx]
    MOVL    Recx,Reax
    ret
signed_to_longword1:
    CALLMACRO   CALL_IO POLY_SYS_signed_to_longword
CALLMACRO   RegMask signed_to_longword,(M_Reax OR M_Recx OR Mask_all)

unsigned_to_longword:
;# Shift the value to remove the tag and store it.
    call    mem_for_largeword
    jb      unsigned_to_longword1
    SHRL    CONST TAGSHIFT,Reax         ;# Logical shift, zero top bit
    MOVL    Reax,[Recx]
    MOVL    Recx,Reax
    ret
unsigned_to_longword1:
    CALLMACRO   CALL_IO POLY_SYS_unsigned_to_longword
CALLMACRO   RegMask unsigned_to_longword,(M_Reax OR M_Recx OR Mask_all)

plus_longword:
    call    mem_for_largeword
    jb      plus_longword1
    MOVL    [Reax],Reax
    ADDL    [Rebx],Reax
    MOVL    Reax,[Recx]
    MOVL    Recx,Reax
    ret
plus_longword1:
    CALLMACRO   CALL_IO POLY_SYS_plus_longword
CALLMACRO   RegMask plus_longword,(M_Reax OR M_Recx OR Mask_all)

minus_longword:
    call    mem_for_largeword
    jb      minus_longword1
    MOVL    [Reax],Reax
    SUBL    [Rebx],Reax
    MOVL    Reax,[Recx]
    MOVL    Recx,Reax
    ret
minus_longword1:
    CALLMACRO   CALL_IO POLY_SYS_minus_longword
CALLMACRO   RegMask minus_longword,(M_Reax OR M_Recx OR Mask_all)

mul_longword:
    call    mem_for_largeword
    jb      mul_longword1
    MOVL    [Reax],Reax
IFDEF WINDOWS
    mul     FULLWORD ptr [Rebx]
ELSE
    MULL    [Rebx]
ENDIF
    MOVL    Reax,[Recx]
    MOVL    Recx,Reax
    MOVL    Reax,Redx           ;# clobber this which has the high-end result
    ret
mul_longword1:
    CALLMACRO   CALL_IO POLY_SYS_mul_longword
CALLMACRO   RegMask mul_longword,(M_Reax OR M_Recx OR M_Redx OR Mask_all)

div_longword:
IFDEF WINDOWS
    cmp     FULLWORD ptr [Rebx],0
ELSE
    CMPL    CONST 0,[Rebx]
ENDIF
    jz      raise_div_ex
    call    mem_for_largeword
    jb      div_longword1
    MOVL    [Reax],Reax
    MOVL    CONST 0,Redx
IFDEF WINDOWS
    div     FULLWORD ptr [Rebx]
ELSE
    DIVL    [Rebx]
ENDIF
    MOVL    Reax,[Recx]         ;# Store the quotient
    MOVL    Recx,Reax
    MOVL    Reax,Redx           ;# clobber this which has the remainder
    ret
div_longword1:
    CALLMACRO   CALL_IO POLY_SYS_div_longword
CALLMACRO   RegMask div_longword,(M_Reax OR M_Recx OR M_Redx OR Mask_all)

mod_longword:
IFDEF WINDOWS
    cmp     FULLWORD ptr [Rebx],0
ELSE
    CMPL    CONST 0,[Rebx]
ENDIF
    jz      raise_div_ex
    call    mem_for_largeword
    jb      mod_longword1
    MOVL    [Reax],Reax
    MOVL    CONST 0,Redx
IFDEF WINDOWS
    div     FULLWORD ptr [Rebx]
ELSE
    DIVL    [Rebx]
ENDIF
    MOVL    Redx,[Recx]         ;# Store the remainder
    MOVL    Recx,Reax
    MOVL    Reax,Redx           ;# clobber this which has the remainder
    ret
mod_longword1:
    CALLMACRO   CALL_IO POLY_SYS_mod_longword
CALLMACRO   RegMask mod_longword,(M_Reax OR M_Recx OR M_Redx OR Mask_all)

andb_longword:
    call    mem_for_largeword
    jb      andb_longword1
    MOVL    [Reax],Reax
    ANDL    [Rebx],Reax
    MOVL    Reax,[Recx]
    MOVL    Recx,Reax
    ret
andb_longword1:
    CALLMACRO   CALL_IO POLY_SYS_andb_longword
CALLMACRO   RegMask andb_longword,(M_Reax OR M_Recx OR Mask_all)

orb_longword:
    call    mem_for_largeword
    jb      orb_longword1
    MOVL    [Reax],Reax
    ORL     [Rebx],Reax
    MOVL    Reax,[Recx]
    MOVL    Recx,Reax
    ret
orb_longword1:
    CALLMACRO   CALL_IO POLY_SYS_orb_longword
CALLMACRO   RegMask orb_longword,(M_Reax OR M_Recx OR Mask_all)

xorb_longword:
    call    mem_for_largeword
    jb      xorb_longword1
    MOVL    [Reax],Reax
    XORL    [Rebx],Reax
    MOVL    Reax,[Recx]
    MOVL    Recx,Reax
    ret
xorb_longword1:
    CALLMACRO   CALL_IO POLY_SYS_xorb_longword
CALLMACRO   RegMask xorb_longword,(M_Reax OR M_Recx OR Mask_all)

shift_left_longword:
    call    mem_for_largeword
    jb      shift_left_longword1
    MOVL    Recx,Redx           ;# We need Recx for the shift
 ;# The shift value is always a Word.word value i.e. tagged
 ;# LargeWord.<<(a,b) is defined to return 0 if b > LargeWord.wordSize
IFNDEF HOSTARCHITECTURE_X86_64
    CMPL    CONST TAGGED(32),Rebx
ELSE
    CMPL    CONST TAGGED(64),Rebx
ENDIF
    jb      sllw1
    MOVL    CONST 0,Reax
    jmp     sllw2
sllw1:
    MOVL    Rebx,Recx
    SHRL    CONST TAGSHIFT,Recx ;# remove tag
    MOVL    [Reax],Reax
    SHLL    R_cl,Reax
sllw2:
    MOVL    Reax,[Redx]
    MOVL    Redx,Reax
    MOVL    Reax,Recx           ;# Clobber Recx
    ret
shift_left_longword1:
    CALLMACRO   CALL_IO POLY_SYS_shift_left_longword
CALLMACRO   RegMask shift_left_longword,(M_Reax OR M_Recx OR M_Redx OR Mask_all)

shift_right_longword:
    call    mem_for_largeword
    jb      shift_right_longword1
    MOVL    Recx,Redx           ;# We need Recx for the shift
 ;# The shift value is always a Word.word value i.e. tagged
 ;# LargeWord.>>(a,b) is defined to return 0 if b > LargeWord.wordSize
IFNDEF HOSTARCHITECTURE_X86_64
    CMPL    CONST TAGGED(32),Rebx
ELSE
    CMPL    CONST TAGGED(64),Rebx
ENDIF
    jb      srlw1
    MOVL    CONST 0,Reax
    jmp     srlw2
srlw1:
    MOVL    Rebx,Recx
    SHRL    CONST TAGSHIFT,Recx ;# remove tag
    MOVL    [Reax],Reax
    SHRL    R_cl,Reax
srlw2:
    MOVL    Reax,[Redx]
    MOVL    Redx,Reax
    MOVL    Reax,Recx           ;# Clobber Recx
    ret
shift_right_longword1:
    CALLMACRO   CALL_IO POLY_SYS_shift_right_longword
CALLMACRO   RegMask shift_right_longword,(M_Reax OR M_Recx OR M_Redx OR Mask_all)

shift_right_arith_longword:
    call    mem_for_largeword
    jb      shift_right_arith_longword1
    MOVL    Recx,Redx           ;# We need Recx for the shift
 ;# The shift value is always a Word.word value i.e. tagged
 ;# LargeWord.~>>(a,b) is defined to return 0 or ~1 if b > LargeWord.wordSize
IFNDEF HOSTARCHITECTURE_X86_64
    CMPL    CONST TAGGED(32),Rebx
ELSE
    CMPL    CONST TAGGED(64),Rebx
ENDIF
    jb      sralw1
    ;# Setting the shift to 31/63 propagates the sign bit
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    CONST TAGGED(31),Rebx
ELSE
    MOVL    CONST TAGGED(63),Rebx
ENDIF
sralw1:
    MOVL    Rebx,Recx
    SHRL    CONST TAGSHIFT,Recx ;# remove tag
    MOVL    [Reax],Reax
    SARL    R_cl,Reax
    MOVL    Reax,[Redx]
    MOVL    Redx,Reax
    MOVL    Reax,Recx           ;# Clobber Recx
    ret
shift_right_arith_longword1:
    CALLMACRO   CALL_IO POLY_SYS_shift_right_arith_longword
CALLMACRO   RegMask shift_right_arith_longword,(M_Reax OR M_Rebx OR M_Recx OR M_Redx OR Mask_all)

;# C-memory operations.
cmem_load_8:
    MOVL    [Reax],Reax             ;# The address is boxed.
    SARL    CONST TAGSHIFT,Rebx     ;# The offset is a signed tagged value
    ADDL    Rebx,Reax               ;# Add it in
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    4[Resp],Rebx            ;# Get the index.
ELSE
    MOVL    R8,Rebx                 ;# Get the index.
ENDIF
    SARL    CONST TAGSHIFT,Rebx     ;# That's also tagged
IFDEF WINDOWS
    movzx   Reax, byte ptr [Reax][Rebx]
ELSE
IFNDEF HOSTARCHITECTURE_X86_64
    movzbl  (Reax,Rebx,1),Reax
ELSE
    movzbq  (Reax,Rebx,1),Reax
ENDIF
ENDIF
CALLMACRO   MAKETAGGED  Reax,Reax
    MOVL    Reax,Rebx       ;# Clobber bad value in %Rebx
    RET3
CALLMACRO   RegMask cmem_load_8,(M_Reax OR M_Rebx)

cmem_load_16:
    MOVL    [Reax],Reax             ;# The address is boxed.
    SARL    CONST TAGSHIFT,Rebx     ;# The offset is a signed tagged value
    ADDL    Rebx,Reax               ;# Add it in
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    4[Resp],Rebx            ;# Get the index.
ELSE
    MOVL    R8,Rebx                 ;# Get the index.
ENDIF
    ;# The index is tagged but since we want to multiply by two we don't need anything here.
IFDEF WINDOWS
    movzx   Reax, word ptr [Reax-1][Rebx]
ELSE
IFNDEF HOSTARCHITECTURE_X86_64
    movzwl  -1(Reax,Rebx,1),Reax
ELSE
    movzwq  -1(Reax,Rebx,1),Reax
ENDIF
ENDIF
CALLMACRO   MAKETAGGED  Reax,Reax
    RET3
CALLMACRO   RegMask cmem_load_16,(M_Reax OR M_Rebx)

cmem_load_32:
IFDEF HOSTARCHITECTURE_X86_64
;# 64-bit mode - the result is tagged
    MOVL    [Reax],Reax             ;# The address is boxed.
    SARL    CONST TAGSHIFT,Rebx     ;# The offset is a signed tagged value
    ADDL    Rebx,Reax               ;# Add it in
IFDEF WINDOWS
    mov     eax, dword ptr [Reax-2][R8*2]
ELSE
    movl    -2(Reax,R8,2),%eax
ENDIF
CALLMACRO   MAKETAGGED  Reax,Reax
    MOVL    Reax,Rebx       ;# Clobber bad value in %Rebx
    RET3

CALLMACRO   RegMask cmem_load_32,(M_Reax OR M_Rebx)

ELSE
;# 32-bit mode - the result is boxed
    call    mem_for_largeword
    jb      cmem_load_32_1
    MOVL    [Reax],Reax             ;# The address is boxed.
    SARL    CONST TAGSHIFT,Rebx     ;# The offset is a signed tagged value
    ADDL    Rebx,Reax               ;# Add it in
    MOVL    4[Resp],Rebx            ;# Get the index.
    MOVL    (-2)[Reax+Rebx*2],Reax
    MOVL    Reax,[Recx]             ;# Save in the new memory
    MOVL    Recx,Reax               ;# Copy the result address
    RET3

cmem_load_32_1:
    CALLMACRO   CALL_IO POLY_SYS_cmem_load_32
CALLMACRO   RegMask cmem_load_32,(M_Reax OR M_Rebx OR M_Recx OR Mask_all)
ENDIF

cmem_load_64: ;# The result is boxed in 64-bit mode. Not implemented in 32-bit mode
IFDEF HOSTARCHITECTURE_X86_64
    call    mem_for_largeword
    jb      cmem_load_64_1
    MOVL    [Reax],Reax             ;# The address is boxed.
    SARL    CONST TAGSHIFT,Rebx     ;# The offset is a signed tagged value
    ADDL    Rebx,Reax               ;# Add it in
    MOVL    (-4)[Reax+R8*4],Reax
    MOVL    Reax,[Recx]             ;# Save in the new memory
    MOVL    Recx,Reax               ;# Copy the result address
    MOVL    Reax,Rebx               ;# Clobber bad value
    RET3

cmem_load_64_1:
    CALLMACRO   CALL_IO POLY_SYS_cmem_load_64
CALLMACRO   RegMask cmem_load_64,(M_Reax OR M_Rebx OR M_Recx OR Mask_all)
ENDIF

cmem_load_float:
    call    mem_for_real
    jb      cmem_load_float1
    MOVL    [Reax],Reax             ;# The address is boxed.
    SARL    CONST TAGSHIFT,Rebx     ;# The offset is a signed tagged value
    ADDL    Rebx,Reax               ;# Add it in
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    4[Resp],Rebx            ;# Get the index.
ELSE
    MOVL    R8,Rebx                 ;# Get the index.
ENDIF
IFDEF WINDOWS
    FLD     dword ptr [Reax-2][Rebx*2]
    FSTP    qword ptr [Recx]
ELSE
    FLDS    -2(Reax,Rebx,2)
    FSTPL   [Recx]
ENDIF
    MOVL    Recx,Reax
    RET3
cmem_load_float1:
     CALLMACRO   CALL_IO POLY_SYS_cmem_load_float
CALLMACRO   RegMask cmem_load_float,(M_Reax OR M_Rebx OR M_Recx OR M_FP7 OR Mask_all)

cmem_load_double:
    call    mem_for_real
    jb      cmem_load_double1
    MOVL    [Reax],Reax             ;# The address is boxed.
    SARL    CONST TAGSHIFT,Rebx     ;# The offset is a signed tagged value
    ADDL    Rebx,Reax               ;# Add it in
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    4[Resp],Rebx            ;# Get the index.
ELSE
    MOVL    R8,Rebx                 ;# Get the index.
ENDIF
IFDEF WINDOWS
    FLD     qword ptr [Reax-4][Rebx*4]
    FSTP    qword ptr [Recx]
ELSE
    FLDL    -4(Reax,Rebx,4)
    FSTPL   [Recx]
ENDIF
    MOVL    Recx,Reax
    RET3

cmem_load_double1:
     CALLMACRO   CALL_IO POLY_SYS_cmem_load_double
CALLMACRO   RegMask cmem_load_double,(M_Reax OR M_Rebx OR M_Recx OR M_FP7 OR Mask_all)
   
cmem_store_8:
    MOVL    [Reax],Reax             ;# The address is boxed.
    SARL    CONST TAGSHIFT,Rebx     ;# The offset is a signed tagged value
    ADDL    Rebx,Reax               ;# Add it in
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    8[Resp],Rebx            ;# Get the index.
    MOVL    4[Resp],Recx            ;# Get the value to store
ELSE
    MOVL    R8,Rebx                 ;# Get the index.
    MOVL    R9,Recx
ENDIF
    SARL    CONST TAGSHIFT,Rebx     ;# That's also tagged
    SARL    CONST TAGSHIFT,Recx
    MOVB    R_cl,[Reax+Rebx]
    MOVL    CONST UNIT,Reax             ;# The function returns unit
    MOVL    Reax,Rebx                   ;# Clobber bad value in %Rebx
    MOVL    Reax,Recx                   ;# and %Recx
    RET4
CALLMACRO   RegMask cmem_store_8,(M_Reax OR M_Rebx OR M_Recx)

cmem_store_16:
    MOVL    [Reax],Reax             ;# The address is boxed.
    SARL    CONST TAGSHIFT,Rebx     ;# The offset is a signed tagged value
    ADDL    Rebx,Reax               ;# Add it in
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    8[Resp],Rebx            ;# Get the index.
    MOVL    4[Resp],Recx            ;# Get the value to store
ELSE
    MOVL    R8,Rebx                 ;# Get the index.
    MOVL    R9,Recx
ENDIF
    SARL    CONST TAGSHIFT,Recx     ;# Untag the value to store
IFDEF WINDOWS
    mov     word ptr [Reax-1][Rebx],cx
ELSE
    movw    %cx,-1(Reax,Rebx,1)
ENDIF
    MOVL    CONST UNIT,Reax             ;# The function returns unit
    MOVL    Reax,Recx                   ;# Bad value in %Recx
    RET4
CALLMACRO   RegMask cmem_store_16,(M_Reax OR M_Rebx OR M_Recx)

cmem_store_32:
    MOVL    [Reax],Reax             ;# The address is boxed.
    SARL    CONST TAGSHIFT,Rebx     ;# The offset is a signed tagged value
    ADDL    Rebx,Reax               ;# Add it in
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    8[Resp],Rebx            ;# Get the index.
    MOVL    4[Resp],Recx            ;# Get the value to store
    MOVL    [Recx],Recx
ELSE
    MOVL    R8,Rebx                 ;# Get the index.
    MOVL    R9,Recx
    SARL    CONST TAGSHIFT,Recx     ;# Untag the value to store
ENDIF
IFDEF WINDOWS
    mov     dword ptr [Reax-2][Rebx*2],ecx
ELSE
    movl    %ecx,-2(Reax,Rebx,2)
ENDIF
    MOVL    CONST UNIT,Reax             ;# The function returns unit
    MOVL    Reax,Recx                   ;# Bad value in %Recx
    RET4
CALLMACRO   RegMask cmem_store_32,(M_Reax OR M_Rebx OR M_Recx)

cmem_store_64: ;# The value is boxed in 64-bit mode. Not implemented in 32-bit mode
IFDEF HOSTARCHITECTURE_X86_64
    MOVL    [Reax],Reax             ;# The address is boxed.
    SARL    CONST TAGSHIFT,Rebx     ;# The offset is a signed tagged value
    ADDL    Rebx,Reax               ;# Add it in
    MOVL    [R9],Rebx               ;# Value to store
    MOVL    Rebx,(-4)[Reax+R8*4]    ;# Store it
    MOVL    CONST UNIT,Reax         ;# The function returns unit
    MOVL    Reax,Rebx               ;# Bad value in %Rebx
    RET4

CALLMACRO   RegMask cmem_store_64,(M_Reax OR M_Rebx OR M_Recx)
ENDIF

cmem_store_float:
    MOVL    [Reax],Reax             ;# The address is boxed.
    SARL    CONST TAGSHIFT,Rebx     ;# The offset is a signed tagged value
    ADDL    Rebx,Reax               ;# Add it in
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    8[Resp],Rebx            ;# Get the index.
    MOVL    4[Resp],Recx            ;# Get the address of the real
ELSE
    MOVL    R8,Rebx                 ;# Get the index.
    MOVL    R9,Recx
ENDIF
IFDEF WINDOWS
    FLD     qword ptr [Recx] 
    FSTP    dword ptr [Reax-2][Rebx*2]
ELSE
    FLDL    [Recx]
    FSTPS    -2(Reax,Rebx,2)
ENDIF
    MOVL    CONST UNIT,Reax         ;# The function returns unit
    MOVL    Reax,Rebx               ;# Bad value in %Rebx
    RET4
CALLMACRO   RegMask cmem_store_float,(M_Reax OR M_Rebx OR M_Recx OR M_FP7)

cmem_store_double:
    MOVL    [Reax],Reax             ;# The address is boxed.
    SARL    CONST TAGSHIFT,Rebx     ;# The offset is a signed tagged value
    ADDL    Rebx,Reax               ;# Add it in
IFNDEF HOSTARCHITECTURE_X86_64
    MOVL    8[Resp],Rebx            ;# Get the index.
    MOVL    4[Resp],Recx            ;# Get the address of the real
ELSE
    MOVL    R8,Rebx                 ;# Get the index.
    MOVL    R9,Recx
ENDIF
IFDEF WINDOWS
    FLD     qword ptr [Recx] 
    FSTP    qword ptr [Reax-4][Rebx*4]
ELSE
    FLDL    [Recx]
    FSTPL    -4(Reax,Rebx,4)
ENDIF
    MOVL    CONST UNIT,Reax         ;# The function returns unit
    MOVL    Reax,Rebx               ;# Bad value in %Rebx
    RET4
CALLMACRO   RegMask cmem_store_double,(M_Reax OR M_Rebx OR M_Recx OR M_FP7)


IFDEF WINDOWS

CREATE_IO_CALL  MACRO index
Call&index&:
    CALL_IO index
    ENDM

CREATE_EXTRA_CALL MACRO index
    INLINE_ROUTINE  X86AsmCallExtra&index&
    CALL_EXTRA index
    ENDM

ELSE

#define CREATE_IO_CALL(index) \
Call##index##: \
    CALL_IO(index)

#define CREATE_EXTRA_CALL(index) \
    INLINE_ROUTINE(X86AsmCallExtra##index##) \
    CALL_EXTRA(index)

ENDIF

CALLMACRO CREATE_IO_CALL  POLY_SYS_exit
CALLMACRO CREATE_IO_CALL  POLY_SYS_chdir
CALLMACRO CREATE_IO_CALL  POLY_SYS_get_flags
CALLMACRO CREATE_IO_CALL  POLY_SYS_exception_trace_fn
CALLMACRO CREATE_IO_CALL  POLY_SYS_profiler
CALLMACRO CREATE_IO_CALL  POLY_SYS_Real_str
CALLMACRO CREATE_IO_CALL  POLY_SYS_Real_Dispatch
CALLMACRO CREATE_IO_CALL  POLY_SYS_conv_real
CALLMACRO CREATE_IO_CALL  POLY_SYS_real_to_int
CALLMACRO CREATE_IO_CALL  POLY_SYS_sqrt_real
CALLMACRO CREATE_IO_CALL  POLY_SYS_sin_real
CALLMACRO CREATE_IO_CALL  POLY_SYS_signal_handler
CALLMACRO CREATE_IO_CALL  POLY_SYS_os_specific
CALLMACRO CREATE_IO_CALL  POLY_SYS_network
CALLMACRO CREATE_IO_CALL  POLY_SYS_io_dispatch
CALLMACRO CREATE_IO_CALL  POLY_SYS_poly_specific
CALLMACRO CREATE_IO_CALL  POLY_SYS_set_code_constant
CALLMACRO CREATE_IO_CALL  POLY_SYS_code_flags
CALLMACRO CREATE_IO_CALL  POLY_SYS_shrink_stack
CALLMACRO CREATE_IO_CALL  POLY_SYS_process_env
CALLMACRO CREATE_IO_CALL  POLY_SYS_callcode_tupled
CALLMACRO CREATE_IO_CALL  POLY_SYS_foreign_dispatch
CALLMACRO CREATE_IO_CALL  POLY_SYS_ffi
CALLMACRO CREATE_IO_CALL  POLY_SYS_stack_trace
CALLMACRO CREATE_IO_CALL  POLY_SYS_full_gc
CALLMACRO CREATE_IO_CALL  POLY_SYS_XWindows
CALLMACRO CREATE_IO_CALL  POLY_SYS_timing_dispatch
CALLMACRO CREATE_IO_CALL  POLY_SYS_showsize
CALLMACRO CREATE_IO_CALL  POLY_SYS_objsize
CALLMACRO CREATE_IO_CALL  POLY_SYS_kill_self
CALLMACRO CREATE_IO_CALL  POLY_SYS_thread_dispatch
CALLMACRO CREATE_IO_CALL  POLY_SYS_io_operation
CALLMACRO CREATE_IO_CALL  POLY_SYS_ln_real
CALLMACRO CREATE_IO_CALL  POLY_SYS_exp_real
CALLMACRO CREATE_IO_CALL  POLY_SYS_arctan_real
CALLMACRO CREATE_IO_CALL  POLY_SYS_cos_real

CALLMACRO CREATE_EXTRA_CALL RETURN_HEAP_OVERFLOW
CALLMACRO CREATE_EXTRA_CALL RETURN_STACK_OVERFLOW
CALLMACRO CREATE_EXTRA_CALL RETURN_STACK_OVERFLOWEX
CALLMACRO CREATE_EXTRA_CALL RETURN_RAISE_DIV
CALLMACRO CREATE_EXTRA_CALL RETURN_ARB_EMULATION


;# Entry point vector.  These are copied into the io_vector during initialisation.
IFDEF WINDOWS
IFDEF HOSTARCHITECTURE_X86_64
DDQ    TEXTEQU <dq>
ELSE
DDQ    TEXTEQU <dd>
ENDIF
    align 4
    PUBLIC entryPointVector
entryPointVector DDQ 0                   ;# 0 is unused
ELSE
IFDEF HOSTARCHITECTURE_X86_64
#define DDQ .quad
ELSE
#define DDQ .long
ENDIF
        GLOBAL EXTNAME(entryPointVector)
EXTNAME(entryPointVector):
    DDQ 0                               ;# 0 is unused
ENDIF
    DDQ  CallPOLY_SYS_exit              ;# 1
    DDQ  0                              ;# 2 is unused
    DDQ  0                              ;# 3 is unused
    DDQ  0                              ;# 4 is unused
    DDQ  0                              ;# 5 is unused
    DDQ  0                              ;# 6 is unused
    DDQ  0                              ;# 7 is unused
    DDQ  0                              ;# 8 is unused
    DDQ  CallPOLY_SYS_chdir             ;# 9
    DDQ  0                              ;# 10 is unused
    DDQ  alloc_store                    ;# 11
    DDQ  alloc_uninit                   ;# 12
    DDQ  0                              ;# 13 is unused
    DDQ  raisex                         ;# raisex = 14
    DDQ  get_length_a                   ;# 15
    DDQ  0                              ;# 16 is unused
    DDQ  CallPOLY_SYS_get_flags         ;# 17
    DDQ  0                              ;# 18 is no longer used
    DDQ  0                              ;# 19 is no longer used
    DDQ  0                              ;# 20 is no longer used
    DDQ  0                              ;# 21 is unused
    DDQ  0                              ;# 22 is unused
    DDQ  str_compare                    ;# 23
    DDQ  0                              ;# 24 is unused
    DDQ  0                              ;# 25 is unused
    DDQ  teststrgtr                     ;# 26
    DDQ  teststrlss                     ;# 27
    DDQ  teststrgeq                     ;# 28
    DDQ  teststrleq                     ;# 29
    DDQ  0                              ;# 30
    DDQ  0                              ;# 31 is no longer used
    DDQ  CallPOLY_SYS_exception_trace_fn ;# 32
    DDQ  0                              ;# 33 - exception trace
    DDQ  0                              ;# 34 is no longer used
    DDQ  0                              ;# 35 is no longer used
    DDQ  0                              ;# 36 is no longer used
    DDQ  0                              ;# 37 is unused
    DDQ  0                              ;# 38 is unused
    DDQ  0                              ;# 39 is unused
    DDQ  0                              ;# 40 is unused
    DDQ  0                              ;# 41 is unused
    DDQ  0                              ;# 42
    DDQ  0                              ;# 43
    DDQ  0                              ;# 44 is no longer used
    DDQ  0                              ;# 45 is no longer used
    DDQ  0                              ;# 46
    DDQ  locksega                       ;# 47
    DDQ  0                              ;# nullorzero = 48
    DDQ  0                              ;# 49 is no longer used
    DDQ  0                              ;# 50 is no longer used
    DDQ  CallPOLY_SYS_network           ;# 51
    DDQ  CallPOLY_SYS_os_specific       ;# 52
    DDQ  eq_longword                    ;# 53
    DDQ  neq_longword                   ;# 54
    DDQ  geq_longword                   ;# 55
    DDQ  leq_longword                   ;# 56
    DDQ  gt_longword                    ;# 57
    DDQ  lt_longword                    ;# 58
    DDQ  0                              ;# 59 is unused
    DDQ  0                              ;# 60 is unused
    DDQ  CallPOLY_SYS_io_dispatch       ;# 61
    DDQ  CallPOLY_SYS_signal_handler    ;# 62
    DDQ  0                              ;# 63 is unused
    DDQ  0                              ;# 64 is unused
    DDQ  0                              ;# 65 is unused
    DDQ  0                              ;# 66 is unused
    DDQ  0                              ;# 67 is unused
    DDQ  0                              ;# 68 is unused
    DDQ  atomic_reset                   ;# 69
    DDQ  atomic_incr                    ;# 70
    DDQ  atomic_decr                    ;# 71
    DDQ  thread_self                    ;# 72
    DDQ  CallPOLY_SYS_thread_dispatch   ;# 73
    DDQ  plus_longword                  ;# 74
    DDQ  minus_longword                 ;# 75
    DDQ  mul_longword                   ;# 76
    DDQ  div_longword                   ;# 77
    DDQ  mod_longword                   ;# 78
    DDQ  andb_longword                  ;# 79
    DDQ  orb_longword                   ;# 80
    DDQ  xorb_longword                  ;# 81
    DDQ  0                              ;# 82 is unused
    DDQ  0                              ;# 83 is now unused
    DDQ  CallPOLY_SYS_kill_self         ;# 84
    DDQ  shift_left_longword            ;# 85
    DDQ  shift_right_longword           ;# 86
    DDQ  shift_right_arith_longword     ;# 87
    DDQ  CallPOLY_SYS_profiler          ;# 88
    DDQ  longword_to_tagged             ;# 89
    DDQ  signed_to_longword             ;# 90
    DDQ  unsigned_to_longword           ;# 91
    DDQ  CallPOLY_SYS_full_gc           ;# 92
    DDQ  CallPOLY_SYS_stack_trace       ;# 93
    DDQ  CallPOLY_SYS_timing_dispatch   ;# 94
    DDQ  0                              ;# 95 is unused
    DDQ  0                              ;# 96 is unused
    DDQ  0                              ;# 97 is unused
    DDQ  0                              ;# 98 is unused
    DDQ  CallPOLY_SYS_objsize           ;# 99
    DDQ  CallPOLY_SYS_showsize          ;# 100
    DDQ  0                              ;# 101 is unused
    DDQ  0                              ;# 102 is unused
    DDQ  0                              ;# 103 is unused
    DDQ  quotrem_long                   ;# 104
    DDQ  is_shorta                      ;# 105
    DDQ  add_long                       ;# 106
    DDQ  sub_long                       ;# 107
    DDQ  mult_long                      ;# 108
    DDQ  div_long                       ;# 109
    DDQ  rem_long                       ;# 110
    DDQ  neg_long                       ;# 111
    DDQ  xor_long                       ;# 112
    DDQ  equal_long                     ;# 113
    DDQ  or_long                        ;# 114
    DDQ  and_long                       ;# 115
    DDQ  0                              ;# 116 is unused
    DDQ  CallPOLY_SYS_Real_str          ;# 117
    DDQ  real_geq                       ;# 118
    DDQ  real_leq                       ;# 119
    DDQ  real_gtr                       ;# 120
    DDQ  real_lss                       ;# 121
    DDQ  real_eq                        ;# 122
    DDQ  real_neq                       ;# 123
    DDQ  CallPOLY_SYS_Real_Dispatch     ;# 124
    DDQ  real_add                       ;# 125
    DDQ  real_sub                       ;# 126
    DDQ  real_mul                       ;# 127
    DDQ  real_div                       ;# 128
    DDQ  real_abs                       ;# 129
    DDQ  real_neg                       ;# 130
    DDQ  0                              ;# 131 is unused
    DDQ  0                              ;# 132 is no longer used
    DDQ  CallPOLY_SYS_conv_real         ;# 133
    DDQ  CallPOLY_SYS_real_to_int       ;# 134
    DDQ  real_from_int                  ;# 135
    DDQ  CallPOLY_SYS_sqrt_real         ;# 136
    DDQ  CallPOLY_SYS_sin_real          ;# 137
    DDQ  CallPOLY_SYS_cos_real          ;# 138
    DDQ  CallPOLY_SYS_arctan_real       ;# 139
    DDQ  CallPOLY_SYS_exp_real          ;# 140
    DDQ  CallPOLY_SYS_ln_real           ;# 141
    DDQ  0                              ;# 142 is no longer used
    DDQ  0                              ;# 143 is unused
    DDQ  0                              ;# 144 is unused
    DDQ  0                              ;# 145 is unused
    DDQ  0                              ;# 146 is unused
    DDQ  0                              ;# 147 is unused
    DDQ  0                              ;# stdin = 148
    DDQ  0                              ;# stdout= 149
    DDQ  CallPOLY_SYS_process_env       ;# 150
    DDQ  set_string_length_a            ;# 151
    DDQ  get_first_long_word_a          ;# 152
    DDQ  CallPOLY_SYS_poly_specific     ;# 153
    DDQ  bytevec_eq                     ;# 154
    DDQ  0                              ;# 155 is unused
    DDQ  0                              ;# 156 is unused
    DDQ  0                              ;# 157 is unused
    DDQ  0                              ;# 158 is unused
    DDQ  0                              ;# 159 is unused
    DDQ  cmem_load_8                    ;# 160
    DDQ  cmem_load_16                   ;# 161
    DDQ  cmem_load_32                   ;# 162
IFDEF HOSTARCHITECTURE_X86_64
    DDQ  cmem_load_64                   ;# 163
ELSE
    DDQ  0                              ;# 163
ENDIF
    DDQ  cmem_load_float                ;# 164
    DDQ  cmem_load_double               ;# 165
    DDQ  cmem_store_8                   ;# 166
    DDQ  cmem_store_16                  ;# 167
    DDQ  cmem_store_32                  ;# 168
IFDEF HOSTARCHITECTURE_X86_64
    DDQ  cmem_store_64                  ;# 169
ELSE
    DDQ  0                              ;# 169
ENDIF
    DDQ  cmem_store_float               ;# 170
    DDQ  cmem_store_double              ;# 171
    DDQ  0                              ;# 172 is unused
    DDQ  0                              ;# 173 is unused
    DDQ  0                              ;# 174 is unused
    DDQ  0                              ;# 175 is unused
    DDQ  0                              ;# 176 is unused
    DDQ  0                              ;# 177 is unused
    DDQ  0                              ;# 178 is unused
    DDQ  0                              ;# 179 is unused
    DDQ  0                              ;# 180 is unused
    DDQ  0                              ;# 181 is unused
    DDQ  0                              ;# 182 is unused
    DDQ  0                              ;# 183 is unused
    DDQ  0                              ;# 184 is unused
    DDQ  0                              ;# 185 is unused
    DDQ  0                              ;# 186 is unused
    DDQ  0                              ;# 187 is unused
    DDQ  0                              ;# 188 is unused
    DDQ  CallPOLY_SYS_io_operation      ;# 189
    DDQ  CallPOLY_SYS_ffi               ;# 190
    DDQ  0                              ;# 191 is no longer used
    DDQ  0                              ;# 192 is unused
    DDQ  move_words                     ;# move_words_overlap = 193
    DDQ  CallPOLY_SYS_set_code_constant ;# 194
    DDQ  move_words                     ;# 195
    DDQ  shift_right_arith_word         ;# 196
    DDQ  int_to_word                    ;# 197
    DDQ  move_bytes                     ;# 198
    DDQ  move_bytes                     ;# move_bytes_overlap = 199
    DDQ  CallPOLY_SYS_code_flags        ;# 200
    DDQ  CallPOLY_SYS_shrink_stack      ;# 201
    DDQ  0                              ;# stderr = 202
    DDQ  0                              ;# 203 now unused
    DDQ  CallPOLY_SYS_callcode_tupled   ;# 204
    DDQ  CallPOLY_SYS_foreign_dispatch  ;# 205
    DDQ  0                              ;# 206 - foreign null
    DDQ  0                              ;# 207 is unused
    DDQ  0                              ;# 208 now unused
    DDQ  CallPOLY_SYS_XWindows          ;# 209
    DDQ  0                              ;# 210 is unused
    DDQ  0                              ;# 211 is unused
    DDQ  0                              ;# 212 is unused
    DDQ  is_big_endian                  ;# 213
    DDQ  bytes_per_word                 ;# 214
    DDQ  offset_address                 ;# 215
    DDQ  shift_right_word               ;# 216
    DDQ  word_neq                       ;# 217
    DDQ  not_bool                       ;# 218
    DDQ  0                              ;# 219 is unused
    DDQ  0                              ;# 220 is unused
    DDQ  0                              ;# 221 is unused
    DDQ  0                              ;# 222 is unused
    DDQ  string_length                  ;# 223
    DDQ  0                              ;# 224 is unused
    DDQ  0                              ;# 225 is unused
    DDQ  0                              ;# 226 is unused
    DDQ  0                              ;# 227 is unused
    DDQ  touch_final                    ;# 228
    DDQ  0                              ;# 229 is no longer used
    DDQ  0                              ;# 230 is no longer used
    DDQ  int_geq                        ;# 231
    DDQ  int_leq                        ;# 232
    DDQ  int_gtr                        ;# 233
    DDQ  int_lss                        ;# 234
    DDQ  load_byte                      ;# load_byte_immut = 235
    DDQ  load_word                      ;# load_word_immut = 236
    DDQ  0                              ;# 237 is unused
    DDQ  mul_word                       ;# 238
    DDQ  plus_word                      ;# 239
    DDQ  minus_word                     ;# 240
    DDQ  div_word                       ;# 241
    DDQ  or_word                        ;# 242
    DDQ  and_word                       ;# 243
    DDQ  xor_word                       ;# 244
    DDQ  shift_left_word                ;# 245
    DDQ  mod_word                       ;# 246
    DDQ  word_geq                       ;# 247
    DDQ  word_leq                       ;# 248
    DDQ  word_gtr                       ;# 249
    DDQ  word_lss                       ;# 250
    DDQ  word_eq                        ;# 251
    DDQ  load_byte                      ;# 252
    DDQ  load_word                      ;# 253
    DDQ  assign_byte                    ;# 254
    DDQ  assign_word                    ;# 255


;# Register mask vector. - extern int registerMaskVector[];
;# Each entry in this vector is a set of the registers modified
;# by the function.  It is an untagged bitmap with the registers
;# encoded in the same way as the 
IFDEF WINDOWS
    align   4
    PUBLIC  registerMaskVector
registerMaskVector  dd  Mask_all                ;# 0 is unused
ELSE
        GLOBAL EXTNAME(registerMaskVector)
EXTNAME(registerMaskVector):
#define dd  .long
    dd  Mask_all                ;# 0 is unused
ENDIF
    dd  Mask_all                 ;# 1
    dd  Mask_all                 ;# 2
    dd  Mask_all                 ;# 3 is unused
    dd  Mask_all                 ;# 4 is unused
    dd  Mask_all                 ;# 5 is unused
    dd  Mask_all                 ;# 6
    dd  Mask_all                 ;# 7 is unused
    dd  Mask_all                 ;# 8 is unused
    dd  Mask_all                 ;# 9
    dd  Mask_all                 ;# 10 is unused
    dd  Mask_alloc_store         ;# 11
    dd  Mask_alloc_uninit        ;# 12
    dd  Mask_all                 ;# return = 13
    dd  Mask_all                 ;# raisex = 14
    dd  Mask_get_length          ;# 15
    dd  Mask_all                 ;# 16 is unused
    dd  Mask_all                 ;# 17
    dd  Mask_all                 ;# 18 is no longer used
    dd  Mask_all                 ;# 19 is no longer used
    dd  Mask_all                 ;# 20 is no longer used
    dd  Mask_all                 ;# 21 is unused
    dd  Mask_all                 ;# 22 is unused
    dd  Mask_str_compare         ;# 23
    dd  Mask_all                 ;# 24 is unused
    dd  Mask_all                 ;# 25 is unused
    dd  Mask_teststrgtr          ;# 26
    dd  Mask_teststrlss          ;# 27
    dd  Mask_teststrgeq          ;# 28
    dd  Mask_teststrleq          ;# 29
    dd  Mask_all                 ;# 30
    dd  Mask_all                 ;# 31 is no longer used
    dd  Mask_all                 ;# exception_trace_fn 32
    dd  Mask_all                 ;# 33 is no longer used
    dd  Mask_all                 ;# 34 is no longer used
    dd  Mask_all                 ;# 35 is no longer used
    dd  Mask_all                 ;# 36 is no longer used
    dd  Mask_all                 ;# 37 is unused
    dd  Mask_all                 ;# 38 is unused
    dd  Mask_all                 ;# 39 is unused
    dd  Mask_all                 ;# 40
    dd  Mask_all                 ;# 41 is unused
    dd  Mask_all                 ;# 42
    dd  Mask_all                 ;# 43
    dd  Mask_all                 ;# 44 is no longer used
    dd  Mask_all                 ;# 45 is no longer used
    dd  Mask_all                 ;# 46
    dd  Mask_lockseg             ;# 47
    dd  Mask_all                 ;# nullorzero = 48
    dd  Mask_all                 ;# 49 is no longer used
    dd  Mask_all                 ;# 50 is no longer used
    dd  Mask_all                 ;# 51
    dd  Mask_all                 ;# 52
    dd  Mask_eq_longword         ;# 53
    dd  Mask_neq_longword        ;# 54
    dd  Mask_geq_longword        ;# 55
    dd  Mask_leq_longword        ;# 56
    dd  Mask_gt_longword         ;# 57
    dd  Mask_lt_longword         ;# 58
    dd  Mask_all                 ;# 59 is unused
    dd  Mask_all                 ;# 60 is unused
    dd  Mask_all                 ;# 61
    dd  Mask_all                 ;# 62
    dd  Mask_all                 ;# 63 is unused
    dd  Mask_all                 ;# 64 is unused
    dd  Mask_all                 ;# 65 is unused
    dd  Mask_all                 ;# 66 is unused
    dd  Mask_all                 ;# 67 is unused
    dd  Mask_all                 ;# 68 is unused
    dd  Mask_atomic_reset        ;# 69
    dd  Mask_atomic_incr         ;# 70
    dd  Mask_atomic_decr         ;# 71
    dd  Mask_thread_self         ;# 72
    dd  Mask_all                 ;# 73
    dd  Mask_plus_longword       ;# 74
    dd  Mask_minus_longword      ;# 75
    dd  Mask_mul_longword        ;# 76
    dd  Mask_div_longword        ;# 77
    dd  Mask_mod_longword        ;# 78
    dd  Mask_andb_longword       ;# 79
    dd  Mask_orb_longword        ;# 80
    dd  Mask_xorb_longword       ;# 81
    dd  Mask_all                 ;# 82 is unused
    dd  Mask_all                 ;# 83 is now unused
    dd  Mask_all                 ;# 84
    dd  Mask_shift_left_longword ;# 85
    dd  Mask_shift_right_longword ;# 86
    dd  Mask_shift_right_arith_longword ;# 87
    dd  Mask_all                 ;# 88
    dd  Mask_longword_to_tagged  ;# 89
    dd  Mask_signed_to_longword  ;# 90
    dd  Mask_unsigned_to_longword ;# 91
    dd  Mask_all                 ;# 92
    dd  Mask_all                 ;# 93
    dd  Mask_all                 ;# 94
    dd  Mask_all                 ;# 95 is unused
    dd  Mask_all                 ;# 96 is unused
    dd  Mask_all                 ;# 97 is unused
    dd  Mask_all                 ;# 98
    dd  Mask_all                 ;# 99
    dd  Mask_all                 ;# 100
    dd  Mask_all                 ;# 101 is unused
    dd  Mask_all                 ;# 102 is unused
    dd  Mask_all                 ;# 103
    dd  Mask_quotrem             ;# 104
    dd  Mask_is_short            ;# 105
    dd  Mask_aplus               ;# 106
    dd  Mask_aminus              ;# 107
    dd  Mask_amul                ;# 108
    dd  Mask_adiv                ;# 109
    dd  Mask_amod                ;# 110
    dd  Mask_aneg                ;# 111
    dd  Mask_xora                ;# 112
    dd  Mask_equala              ;# 113
    dd  Mask_ora                 ;# 114
    dd  Mask_anda                ;# 115
    dd  Mask_all                 ;# 116 is unused
    dd  Mask_all                 ;# 117
    dd  Mask_real_geq            ;# 118
    dd  Mask_real_leq            ;# 119
    dd  Mask_real_gtr            ;# 120
    dd  Mask_real_lss            ;# 121
    dd  Mask_real_eq             ;# 122
    dd  Mask_real_neq            ;# 123
    dd  Mask_all                 ;# 124
    dd  Mask_real_add            ;# 125
    dd  Mask_real_sub            ;# 126
    dd  Mask_real_mul            ;# 127
    dd  Mask_real_div            ;# 128
    dd  Mask_real_abs            ;# 129
    dd  Mask_real_neg            ;# 130
    dd  Mask_all                 ;# 131 is unused
    dd  Mask_all                 ;# 132
    dd  Mask_all                 ;# 133
    dd  Mask_all                 ;# 134
    dd  Mask_real_from_int       ;# 135
    dd  Mask_all                 ;# 136
    dd  Mask_all                 ;# 137
    dd  Mask_all                 ;# 138
    dd  Mask_all                 ;# 139
    dd  Mask_all                 ;# 140
    dd  Mask_all                 ;# 141
    dd  Mask_all                 ;# 142 is no longer used
    dd  Mask_all                 ;# 143 is unused
    dd  Mask_all                 ;# 144 is unused
    dd  Mask_all                 ;# 145 is unused
    dd  Mask_all                 ;# 146 is unused
    dd  Mask_all                 ;# 147 is unused
    dd  Mask_all                 ;# stdin = 148
    dd  Mask_all                 ;# stdout= 149
    dd  Mask_all                 ;# 150
    dd  Mask_set_string_length   ;# 151
    dd  Mask_get_first_long_word ;# 152
    dd  Mask_all                 ;# poly_specific = 153
    dd  Mask_bytevec_eq          ;# 154
    dd  Mask_all                 ;# 155 is unused
    dd  Mask_all                 ;# 156 is unused
    dd  Mask_all                 ;# 157 is unused
    dd  Mask_all                 ;# 158 is unused
    dd  Mask_all                 ;# 159 is unused
    dd  Mask_cmem_load_8         ;# 160
    dd  Mask_cmem_load_16        ;# 161
    dd  Mask_cmem_load_32        ;# 162
IFDEF HOSTARCHITECTURE_X86_64
    dd  Mask_cmem_load_64        ;# 163
ELSE
    dd  Mask_all                 ;# 169
ENDIF
    dd  Mask_cmem_load_float     ;# 164
    dd  Mask_cmem_load_double    ;# 165
    dd  Mask_cmem_store_8        ;# 166
    dd  Mask_cmem_store_16       ;# 167
    dd  Mask_cmem_store_32       ;# 168
IFDEF HOSTARCHITECTURE_X86_64
    dd  Mask_cmem_store_64       ;# 169
ELSE
    dd  Mask_all                 ;# 169
ENDIF
    dd  Mask_cmem_store_float    ;# 170
    dd  Mask_cmem_store_double   ;# 171
    dd  Mask_all                 ;# 172 is unused
    dd  Mask_all                 ;# 173 is unused
    dd  Mask_all                 ;# 174 is unused
    dd  Mask_all                 ;# 175 is unused
    dd  Mask_all                 ;# 176 is unused
    dd  Mask_all                 ;# 177 is unused
    dd  Mask_all                 ;# 178 is unused
    dd  Mask_all                 ;# 179 is unused
    dd  Mask_all                 ;# 180 is unused
    dd  Mask_all                 ;# 181 is unused
    dd  Mask_all                 ;# 182 is unused
    dd  Mask_all                 ;# 183 is unused
    dd  Mask_all                 ;# 184 is unused
    dd  Mask_all                 ;# 185 is unused
    dd  Mask_all                 ;# 186 is unused
    dd  Mask_all                 ;# 187 is unused
    dd  Mask_all                 ;# 188 is unused
    dd  Mask_all                 ;# 189
    dd  Mask_all                 ;# 190
    dd  Mask_all                 ;# 191 is no longer used
    dd  Mask_all                 ;# 192 is unused
    dd  Mask_move_words          ;# 193
    dd  Mask_all                 ;# 194
    dd  Mask_move_words          ;# 195
    dd  Mask_shift_right_arith_word  ;# 196
    dd  Mask_int_to_word         ;# 197
    dd  Mask_move_bytes          ;# 198
    dd  Mask_move_bytes          ;# 199
    dd  Mask_all                 ;# 200
    dd  Mask_all                 ;# 201
    dd  Mask_all                 ;# stderr = 202
    dd  Mask_all                 ;# 203 now unused
    dd  Mask_all                 ;# 204
    dd  Mask_all                 ;# 205
    dd  Mask_all                 ;# 206
    dd  Mask_all                 ;# 207 is unused
    dd  Mask_all                 ;# 208 now unused
    dd  Mask_all                 ;# 209
    dd  Mask_all                 ;# 210 is unused
    dd  Mask_all                 ;# 211 is unused
    dd  Mask_all                 ;# 212 is unused
    dd  Mask_is_big_endian       ;# 213
    dd  Mask_bytes_per_word      ;# 214
    dd  Mask_offset_address      ;# 215
    dd  Mask_shift_right_word    ;# 216
    dd  Mask_word_neq            ;# 217
    dd  Mask_not_bool            ;# 218
    dd  Mask_all                 ;# 219 is unused
    dd  Mask_all                 ;# 220 is unused
    dd  Mask_all                 ;# 221 is unused
    dd  Mask_all                 ;# 222 is unused
    dd  Mask_string_length       ;# 223
    dd  Mask_all                 ;# 224 is unused
    dd  Mask_all                 ;# 225 is unused
    dd  Mask_all                 ;# 226 is unused
    dd  Mask_all                 ;# 227 is unused
    dd  Mask_touch_final         ;# 228
    dd  Mask_all                 ;# 229 - no longer used
    dd  Mask_all                 ;# 230 - no longer used
    dd  Mask_int_geq             ;# 231
    dd  Mask_int_leq             ;# 232
    dd  Mask_int_gtr             ;# 233
    dd  Mask_int_lss             ;# 234
    dd  Mask_load_byte           ;# load_byte_immut = 235
    dd  Mask_load_word           ;# load_word_immut = 236
    dd  Mask_all                 ;# 237 is unused
    dd  Mask_mul_word            ;# 238
    dd  Mask_plus_word           ;# 239
    dd  Mask_minus_word          ;# 240
    dd  Mask_div_word            ;# 241
    dd  Mask_or_word             ;# 242
    dd  Mask_and_word            ;# 243
    dd  Mask_xor_word            ;# 244
    dd  Mask_shift_left_word     ;# 245
    dd  Mask_mod_word            ;# 246
    dd  Mask_word_geq            ;# 247
    dd  Mask_word_leq            ;# 248
    dd  Mask_word_gtr            ;# 249
    dd  Mask_word_lss            ;# 250
    dd  Mask_word_eq             ;# 251
    dd  Mask_load_byte           ;# 252
    dd  Mask_load_word           ;# 253
    dd  Mask_assign_byte         ;# 254
    dd  Mask_assign_word         ;# 255

END
