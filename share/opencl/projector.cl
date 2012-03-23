/*
 Copyright (C) 2010 X. Andrade

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2, or (at your option)
 any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 02111-1307, USA.

 $Id: projector.cl 2146 2006-05-23 17:36:00Z xavier $
*/

#ifdef EXT_KHR_FP64
#pragma OPENCL EXTENSION cl_khr_fp64 : enable
#elif EXT_AMD_FP64
#pragma OPENCL EXTENSION cl_amd_fp64 : enable
#endif

__kernel void projector_bra(const int nmat,
			    const __global int * sizes,
			    const __global int * offsets,
			    __global const double * matrix,
			    __global const int * map,
			    __global const double * scal,
			    __global const double * psi, const int ldpsi,
			    __global double * projection, const int ldprojection
			    ){
  
  const int ist = get_global_id(0);
  const int ipj = get_global_id(1);
  const int imat = get_global_id(2);

  const int npoints = sizes[2*imat    ];
  const int nprojs  = sizes[2*imat + 1];  
  const int matrix_offset = offsets[4*imat    ];
  const int map_offset    = offsets[4*imat + 1];
  const int scal_offset   = offsets[4*imat + 2];

  const int nppj = npoints*ipj;

  if(ipj >= nprojs || imat >= nmat) return;

  double aa = 0.0;
  for(int ip = 0; ip < npoints; ip++){
    aa += matrix[matrix_offset + ip + nppj]*psi[((map[map_offset + ip] - 1)<<ldpsi) + ist];
  }
  projection[ist + ((scal_offset + ipj)<<ldprojection)] = scal[scal_offset + ipj]*aa;

}

__kernel void projector_ket(const int nmat,
			    const __global int * sizes,
			    const __global int * offsets,
			    __global const double * matrix,
			    __global const int * map,
			    __global const double * projection, const int ldprojection,
			    __global double * lpsi, const int ldlpsi
			    ){
  
  const int ist = get_global_id(0);
  const int ip = get_global_id(1);
  const int imat = get_global_id(2);

  const int npoints = sizes[2*imat    ];
  const int nprojs  = sizes[2*imat + 1];
  const int matrix_offset = offsets[4*imat    ];
  const int map_offset    = offsets[4*imat + 1];
  const int scal_offset   = offsets[4*imat + 2];

  if(ip >= npoints) return;

  double aa = 0.0;
  for(int ipj = 0; ipj < nprojs; ipj++){
    aa += matrix[matrix_offset + ip + npoints*ipj]*projection[ist + ((scal_offset + ipj)<<ldprojection)];
  }

  lpsi[((map_offset + ip)<<ldlpsi) + ist] = aa;
}

__kernel void projector_ket_copy(const int np,
				 const __global int * pos,
				 const __global int * invmap,
				 const __global double * lpsi, const int ldlpsi,
				 __global double * psi, const int ldpsi
				 ){
  const int ist = get_global_id(0);
  const int ip = get_global_id(1);

  if(ip >= np) return;

  double aa = 0.0;

  for(int ii = pos[ip]; ii < pos[ip + 1]; ii++){
    aa += lpsi[(invmap[ii]<<ldpsi) + ist];
  }

  psi[(ip<<ldpsi) + ist] += aa;
  
}

/*
 Local Variables:
 mode: c
 coding: utf-8
 End:
*/

