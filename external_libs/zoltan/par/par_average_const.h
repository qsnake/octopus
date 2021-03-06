/*****************************************************************************
 * Zoltan Library for Parallel Applications                                  *
 * Copyright (c) 2000,2001,2002, Sandia National Laboratories.               *
 * For more info, see the README file in the top-level Zoltan directory.     *  
 *****************************************************************************/
/*****************************************************************************
 * CVS File Information :
 *    $RCSfile: par_average_const.h,v $
 *    $Author: lafisk $
 *    $Date: 2004/12/03 15:39:21 $
 *    Revision: 1.3 $
 ****************************************************************************/


#ifndef __PAR_AVERAGE_CONST_H
#define __PAR_AVERAGE_CONST_H

#include <mpi.h>

#ifdef __cplusplus
/* if C++, define the rest of this header file as extern C */
extern "C" {
#endif

double Zoltan_RB_Average_Cut(int, double *, int *, int, int, int, int,
  MPI_Comm, double);

#ifdef __cplusplus
} /* closing bracket for extern "C" */
#endif

#endif
