!! Copyright (C) 2002-2006 M. Marques, A. Castro, A. Rubio, G. Bertsch
!!
!! This program is free software; you can redistribute it and/or modify
!! it under the terms of the GNU General Public License as published by
!! the Free Software Foundation; either version 2, or (at your option)
!! any later version.
!!
!! This program is distributed in the hope that it will be useful,
!! but WITHOUT ANY WARRANTY; without even the implied warranty of
!! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!! GNU General Public License for more details.
!!
!! You should have received a copy of the GNU General Public License
!! along with this program; if not, write to the Free Software
!! Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
!! 02111-1307, USA.
!!
!! $Id: solver_1d_inc.F90 6950 2010-08-19 22:19:34Z dstrubbe $


!-----------------------------------------------------------------
subroutine poisson1d_init(this)
  type(poisson_t), intent(inout) :: this

  PUSH_SUB(poisson1d_init)

  call parse_float(datasets_check('Poisson1DSoftCoulombParam'), &
    M_ONE, this%poisson_soft_coulomb_param)

  select case(this%method)
  case(POISSON_FFT_SPH)
    call poisson_fft_build_1d_0d(this%der%mesh, this%poisson_soft_coulomb_param)
  case(POISSON_FFT_NOCUT)
    call poisson_fft_build_1d_1d(this%der%mesh, this%poisson_soft_coulomb_param)
  end select

  POP_SUB(poisson1d_init)
end subroutine poisson1d_init

!-----------------------------------------------------------------

subroutine poisson1D_solve(this, pot, rho)
  type(poisson_t), intent(in)  :: this
  FLOAT,           intent(out) :: pot(:)
  FLOAT,           intent(in)  :: rho(:)

  integer  :: ip, jp
  FLOAT    :: xx, yy
#ifdef HAVE_MPI
  FLOAT    :: tmp, xg(1:MAX_DIM)
  FLOAT, allocatable :: pvec(:)
#endif

  ASSERT(this%method == -1)

  PUSH_SUB(poisson1D_solve)

#ifdef HAVE_MPI
  if(this%der%mesh%parallel_in_domains) then
    SAFE_ALLOCATE(pvec(1:this%der%mesh%np))

    pot = M_ZERO
    do ip = 1, this%der%mesh%np_global
      xg = mesh_x_global(this%der%mesh, ip)
      xx = xg(1)
      do jp = 1, this%der%mesh%np
        yy = this%der%mesh%x(jp, 1)
        pvec(jp) = rho(jp)/sqrt(this%poisson_soft_coulomb_param**2 + (xx-yy)**2)
      end do
      tmp = dmf_integrate(this%der%mesh, pvec)
      if (this%der%mesh%vp%part(ip).eq.this%der%mesh%vp%partno) then
        pot(vec_global2local(this%der%mesh%vp, ip, this%der%mesh%vp%partno)) = tmp
      end if
    end do

    SAFE_DEALLOCATE_A(pvec)

  else  ! running in serial
#endif
    pot = M_ZERO
    do ip = 1, this%der%mesh%np
      xx = this%der%mesh%x(ip, 1)
      do jp = 1, this%der%mesh%np
        yy = this%der%mesh%x(jp, 1)
        pot(ip) = pot(ip) + rho(jp)/sqrt(this%poisson_soft_coulomb_param**2 + &
	         (xx-yy)**2)*this%der%mesh%vol_pp(1)
      end do
    end do
#ifdef HAVE_MPI
  end if
#endif

  POP_SUB(poisson1D_solve)
end subroutine poisson1D_solve
!-----------------------------------------------------------------


!! Local Variables:
!! mode: f90
!! coding: utf-8
!! End:
