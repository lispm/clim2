/*
 * $Id: bcopy.c,v 2.4 2003/12/15 18:35:18 layer Exp $
 */
/*
 * Copyright Kyoto University Research Institute for Mathematical Sciences
 *                 1987, 1988, 1989, 1990, 1991
 * Copyright OMRON Corporation. 1987, 1988, 1989, 1990, 1991
 * Copyright ASTEC, Inc. 1987, 1988, 1989, 1990, 1991
 *
 * Permission to use, copy, modify, distribute, and sell this software
 * and its documentation for any purpose is hereby granted without fee,
 * provided that all of the following conditions are satisfied:
 *
 * 1) The above copyright notices appear in all copies
 * 2) Both those copyright notices and this permission notice appear
 *    in supporting documentation
 * 3) The name of "Wnn" isn't changed unless substantial modifications
 *    are made, or
 * 3') Following words followed by the above copyright notices appear
 *    in all supporting documentation of software based on "Wnn":
 *
 *   "This software is based on the original version of Wnn developed by
 *    Kyoto University Research Institute for Mathematical Sciences (KURIMS),
 *    OMRON Corporation and ASTEC Inc."
 *
 * 4) The names KURIMS, OMRON and ASTEC not be used in advertising or
 *    publicity pertaining to distribution of the software without
 *    specific, written prior permission
 *
 * KURIMS, OMRON and ASTEC make no representations about the suitability
 * of this software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 *
 * Wnn consortium is one of distributors of the official Wnn source code
 * release.  Wnn consortium also makes no representations about the
 * suitability of this software for any purpose.  It is provided "as is"
 * without express or implied warranty.
 *
 * KURIMS, OMRON, ASTEC AND WNN CONSORTIUM DISCLAIM ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL KURIMS, OMRON, ASTEC OR
 * WNN CONSORTIUM BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL
 * DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
 * PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
 * TORTUOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 *
 */
/*	Version 4.0
*/
#include "commonhd.h"

#if defined(SYSVR2) && !defined(linux) && !defined(DGUX) && !defined(uniosu)

void
bcopy (b1, b2, length)
register unsigned char *b1, *b2;
register length;
{
    if (length <= 0)
	return;
    if (b1 < b2 && b1 + length > b2) {
	b2 += length;
	b1 += length;
	while (length--) {
	    *--b2 = *--b1;
	}
    } else {
	memcpy(b2, b1, length);
    }
}
 
void
bzero (b, length)
register unsigned char *b;
register length;
{
    memset (b, 0, length);
}

int
bcmp (b1, b2, length)
register unsigned char *b1;
register unsigned char *b2;
register length;
{
    if (length == 0)
	return 0;
    return memcmp (b1, b2, length);
}
#endif	/* SYSVR2 */
