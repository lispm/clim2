/*				-[Tue Apr 17 14:44:45 2007 by layer]-
 *
 * copyright (c) 1992-2002 Franz Inc, Berkeley, CA  All rights reserved.
 * copyright (c) 2002-2007 Franz Inc, Oakland, CA - All rights reserved.
 *
 * The software, data and information contained herein are proprietary
 * to, and comprise valuable trade secrets of, Franz, Inc.  They are
 * given in confidence by Franz, Inc. pursuant to a written license
 * agreement, and may be stored and used only in accordance with the terms
 * of such license.
 *
 * Restricted Rights Legend
 * ------------------------
 * Use, duplication, and disclosure of the software, data and information
 * contained herein by any agency, department or entity of the U.S.
 * Government are subject to restrictions of Restricted Rights for
 * Commercial Software developed at private expense as specified in 
 * DOD FAR Supplement 52.227-7013 (c) (1) (ii), as applicable.
 *
 * $Header: /repo/cvs.copy/clim2/misc/MyDrawingAP.h,v 2.6 2007/04/17 21:45:51 layer Exp $
 */

#ifndef _XmMyDrawingAreaP_h
#define _XmMyDrawingAreaP_h

#include <Xm/DrawingAP.h>
#include "MyDrawingA.h"

#ifdef __cplusplus
extern "C" {
#endif

/*  New fields for the MyDrawingArea widget class record  */

typedef struct
{
   int mumble;   /* No new procedures */
} XmMyDrawingAreaClassPart;


/* Full class record declaration */

typedef struct _XmMyDrawingAreaClassRec
{
	CoreClassPart		 core_class;
	CompositeClassPart	 composite_class;
	ConstraintClassPart	 constraint_class;
	XmManagerClassPart	 manager_class;
	XmDrawingAreaClassPart	 drawing_area_class;
	XmMyDrawingAreaClassPart my_drawing_area_class;
} XmMyDrawingAreaClassRec;


externalref XmMyDrawingAreaClassRec xmMyDrawingAreaClassRec;


/* New fields for the MyDrawingArea widget record */

typedef struct
{
    int dummy;			/* Don't really need any at this point. */
} XmMyDrawingAreaPart;


/* Full instance record declaration */

typedef struct _XmMyDrawingAreaRec
{
	CorePart		core;
	CompositePart		composite;
	ConstraintPart		constraint;
	XmManagerPart		manager;
	XmDrawingAreaPart	drawing_area;
	XmMyDrawingAreaPart	my_drawing_area;
} XmMyDrawingAreaRec;


#ifdef __cplusplus
}  /* Close scope of 'extern "C"' declaration which encloses file. */
#endif

#endif /* _XmMyDrawingAreaP_h */
/* DON'T ADD ANYTHING AFTER THIS #endif */
