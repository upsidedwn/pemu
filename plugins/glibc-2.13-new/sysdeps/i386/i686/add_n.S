/* Add two limb vectors of the same length > 0 and store sum in a third
   limb vector.
   Copyright (C) 1992,94,95,97,98,2000,2005 Free Software Foundation, Inc.
   This file is part of the GNU MP Library.

   The GNU MP Library is free software; you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License as published by
   the Free Software Foundation; either version 2.1 of the License, or (at your
   option) any later version.

   The GNU MP Library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
   License for more details.

   You should have received a copy of the GNU Lesser General Public License
   along with the GNU MP Library; see the file COPYING.LIB.  If not, write to
   the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
   MA 02111-1307, USA. */

#include "sysdep.h"
#include "asm-syntax.h"
#include "bp-sym.h"
#include "bp-asm.h"

#define PARMS	LINKAGE+8		/* space for 2 saved regs */
#define RES	PARMS
#define S1	RES+PTR_SIZE
#define S2	S1+PTR_SIZE
#define SIZE	S2+PTR_SIZE

	.text
#ifdef PIC
L(1):	addl    (%esp), %eax
	ret
#endif
ENTRY (BP_SYM (__mpn_add_n))
	ENTER

	pushl %edi
	cfi_adjust_cfa_offset (4)
	pushl %esi
	cfi_adjust_cfa_offset (4)

	movl	RES(%esp),%edi
	cfi_rel_offset (edi, 4)
	movl	S1(%esp),%esi
	cfi_rel_offset (esi, 0)
	movl	S2(%esp),%edx
	movl	SIZE(%esp),%ecx
#if __BOUNDED_POINTERS__
	shll	$2, %ecx	/* convert limbs to bytes */
	CHECK_BOUNDS_BOTH_WIDE (%edi, RES(%esp), %ecx)
	CHECK_BOUNDS_BOTH_WIDE (%esi, S1(%esp), %ecx)
	CHECK_BOUNDS_BOTH_WIDE (%edx, S2(%esp), %ecx)
	shrl	$2, %ecx
#endif
	movl	%ecx,%eax
	shrl	$3,%ecx			/* compute count for unrolled loop */
	negl	%eax
	andl	$7,%eax			/* get index where to start loop */
	jz	L(oop)			/* necessary special case for 0 */
	incl	%ecx			/* adjust loop count */
	shll	$2,%eax			/* adjustment for pointers... */
	subl	%eax,%edi		/* ... since they are offset ... */
	subl	%eax,%esi		/* ... by a constant when we ... */
	subl	%eax,%edx		/* ... enter the loop */
	shrl	$2,%eax			/* restore previous value */
#ifdef PIC
/* Calculate start address in loop for PIC.  */
	leal	(L(oop)-L(0)-3)(%eax,%eax,8),%eax
	call	L(1)
L(0):
#else
/* Calculate start address in loop for non-PIC.  */
 	leal	(L(oop) - 3)(%eax,%eax,8),%eax
#endif
	jmp	*%eax			/* jump into loop */
	ALIGN (3)
L(oop):	movl	(%esi),%eax
	adcl	(%edx),%eax
	movl	%eax,(%edi)
	movl	4(%esi),%eax
	adcl	4(%edx),%eax
	movl	%eax,4(%edi)
	movl	8(%esi),%eax
	adcl	8(%edx),%eax
	movl	%eax,8(%edi)
	movl	12(%esi),%eax
	adcl	12(%edx),%eax
	movl	%eax,12(%edi)
	movl	16(%esi),%eax
	adcl	16(%edx),%eax
	movl	%eax,16(%edi)
	movl	20(%esi),%eax
	adcl	20(%edx),%eax
	movl	%eax,20(%edi)
	movl	24(%esi),%eax
	adcl	24(%edx),%eax
	movl	%eax,24(%edi)
	movl	28(%esi),%eax
	adcl	28(%edx),%eax
	movl	%eax,28(%edi)
	leal	32(%edi),%edi
	leal	32(%esi),%esi
	leal	32(%edx),%edx
	decl	%ecx
	jnz	L(oop)

	sbbl	%eax,%eax
	negl	%eax

	popl %esi
	cfi_adjust_cfa_offset (-4)
	cfi_restore (esi)
	popl %edi
	cfi_adjust_cfa_offset (-4)
	cfi_restore (edi)

	LEAVE
	ret
END (BP_SYM (__mpn_add_n))
