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
!! $Id: casida_inc.F90 7619 2011-03-26 03:03:40Z xavier $


! ---------------------------------------------------------
function X(ks_matrix_elements) (cas, st, mesh, dv) result(xx)
  type(casida_t), intent(in) :: cas
  type(states_t), intent(in) :: st
  type(mesh_t),   intent(in) :: mesh
  FLOAT, intent(in)   :: dv(:)
  FLOAT :: xx(cas%n_pairs)

  R_TYPE, allocatable :: ff(:)
  integer :: ip, ia, sigma, idim

  PUSH_SUB(X(ks_matrix_elements))

  SAFE_ALLOCATE(ff(1:mesh%np))
  do ia = 1, cas%n_pairs
    sigma = cas%pair(ia)%sigma
    do ip = 1, mesh%np
      do idim = 1, st%d%dim
        ff(ip) = dv(ip) * R_CONJ(st%X(psi) (ip, idim, cas%pair(ia)%i, sigma)) &
                               * st%X(psi) (ip, idim, cas%pair(ia)%a, sigma)
      end do
    end do
    xx(ia) = X(mf_integrate)(mesh, ff)
  end do

  SAFE_DEALLOCATE_A(ff)
  POP_SUB(X(ks_matrix_elements))
end function X(ks_matrix_elements)

! ---------------------------------------------------------
R_TYPE function X(transition_matrix_element) (cas, ia, xx) result(zz)
  type(casida_t), intent(in) :: cas
  integer,        intent(in) :: ia
  R_TYPE,         intent(in) :: xx(:)

  integer :: jb

  PUSH_SUB(X(transition_matrix_element))

  zz = R_TOTYPE(M_ZERO)
  if(cas%w(ia) > M_ZERO) then
    do jb = 1, cas%n_pairs
      zz = zz + xx(jb) * (M_ONE/sqrt(cas%s(jb))) * cas%mat(jb, ia)
    end do
    zz = (M_ONE/sqrt(cas%w(ia))) * zz
  end if

  POP_SUB(X(transition_matrix_element))
end function X(transition_matrix_element)

! ---------------------------------------------------------
subroutine X(transition_density) (cas, st, mesh, ia, n0I)
  type(casida_t), intent(in)  :: cas
  type(states_t), intent(in)  :: st
  type(mesh_t),   intent(in)  :: mesh
  integer,        intent(in)  :: ia
  R_TYPE,         intent(out) :: n0I(:)

  integer :: ip, jb, idim
  R_TYPE, allocatable :: xx(:)

  PUSH_SUB(X(transition_density))

  SAFE_ALLOCATE(xx(1:cas%n_pairs))

  do ip = 1, mesh%np
    do jb = 1, cas%n_pairs
      do idim = 1, st%d%dim
        xx(jb) = R_CONJ(st%X(psi)(ip, idim, cas%pair(jb)%i, cas%pair(jb)%sigma)) * &
             st%X(psi)(ip, idim, cas%pair(jb)%a, cas%pair(jb)%sigma)
      end do
    end do
    n0I(ip) = X(transition_matrix_element) (cas, ia, xx)
  end do

  SAFE_DEALLOCATE_A(xx)
  POP_SUB(X(transition_density))
end subroutine X(transition_density)

! ---------------------------------------------------------
subroutine X(get_transition_densities) (cas, sys, trandens)
  type(casida_t),    intent(in) :: cas
  type(system_t),    intent(in) :: sys
  character(len=80), intent(in) :: trandens

  integer :: ia, ierr
  character(len=5) :: intstr
  character(len=130) :: filename
  R_TYPE, allocatable :: n0I(:)
  type(unit_t) :: fn_unit

  PUSH_SUB(X(get_transition_densities))

  SAFE_ALLOCATE(n0I(1:sys%gr%mesh%np))
  n0I = M_ZERO
  fn_unit = units_out%length**(-sys%gr%sb%dim)

  do ia = 1, cas%n_pairs
    if(loct_isinstringlist(ia, trandens)) then
      call X(transition_density) (cas, sys%st, sys%gr%mesh, ia, n0I)
      write(intstr,'(i5)') ia
      write(intstr,'(i1)') len(trim(adjustl(intstr)))
      write(filename,'(a,i'//trim(intstr)//')') 'n0',ia
      call X(io_function_output)(sys%outp%how, CASIDA_DIR, trim(filename), &
                              sys%gr%mesh, n0I, fn_unit, ierr, geo = sys%geo)
    end if
  end do

  SAFE_DEALLOCATE_A(n0I)
  POP_SUB(X(get_transition_densities))
end subroutine X(get_transition_densities)

!! Local Variables:
!! mode: f90
!! coding: utf-8
!! End:
