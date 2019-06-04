!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! This file is part of NSCouette, a HPC code for DNS of Taylor-Couette flow !
!                                                                           !
! Copyright (C) 2016 Marc Avila, Bjoern Hof, Jose Manuel Lopez,             !
!                    Markus Rampp, Liang Shi                                !
!                                                                           !
! NSCouette is free software: you can redistribute it and/or modify         !
! it under the terms of the GNU General Public License as published by      !
! the Free Software Foundation, either version 3 of the License, or         !
! (at your option) any later version.                                       !
!                                                                           !
! NSCouette is distributed in the hope that it will be useful,              !
! but WITHOUT ANY WARRANTY; without even the implied warranty of            !
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             !
! GNU General Public License for more details.                              !
!                                                                           !
! You should have received a copy of the GNU General Public License         !
! along with NSCouette.  If not, see <http://www.gnu.org/licenses/>.        !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!=============================================
!
!  Define all global parameters
!     th,z-directions : Fourier
!     r-direction     : Finite Difference
!
!=============================================

MODULE mod_params
  
  IMPLICIT NONE
  SAVE

  !------------------------------------Mathematics constants
  REAL(KIND=8)   ,PARAMETER :: epsilon = 1D-10      ! numbers below it = 0
  REAL(KIND=8)   ,PARAMETER :: PI = ACOS(-1d0)    ! pi = 3.1415926...
  COMPLEX(KIND=8),PARAMETER :: ii = DCMPLX(0,1)    ! Complex i = sqrt(-1)

  !------------------------------------Spectral parametres
  INTEGER(KIND=4) :: m_r         ! Maximum spectral mode (> n_s-1)
  INTEGER(KIND=4) :: m_th    
  INTEGER(KIND=4) :: m_z0    

  INTEGER(KIND=4) :: m_z   
  INTEGER(KIND=4) :: m_f   
  REAL(KIND=8)    :: k_th0 
  REAL(KIND=8)    :: k_z0  

  !--------------------------Physical parameters
  INTEGER(KIND=4) :: n_r  
  INTEGER(KIND=4) :: n_th 
  INTEGER(KIND=4) :: n_z  

  INTEGER(KIND=4) :: n_f    
  REAL(KIND=8)    :: len_r  
  REAL(KIND=8)    :: len_th 
  REAL(KIND=8)    :: len_z  

  REAL(KIND=8)    :: eta
  REAL(KIND=8)    :: r_i
  REAL(KIND=8)    :: r_o
  
  
  REAL(KIND=8), allocatable :: r(:),th(:),z(:)


  REAL(KIND=8)    :: gap = 0.d0
  REAL(KIND=8)    :: gra = 0.d0
  REAL(KIND=8)    :: nu  = 0.d0

  !------------------------------------MPI & FFTW parameters
  
  INTEGER(KIND=4) :: mp_r  ! Radial points at each proc
  INTEGER(KIND=4) :: mp_f  ! Fourier points per proc
  INTEGER(KIND=4) :: mp_fmax  ! global max of Fourier points over all procs
  INTEGER(KIND=4),allocatable :: mp_f_arr(:) ! array of Fourier points over all procs
  INTEGER(KIND=4),PARAMETER :: root = 0            ! Root processor
 
  INTEGER(KIND=4),PARAMETER :: fftw_nthreads = 1
  LOGICAL        ,PARAMETER :: ifpad = .TRUE.      ! If apply '3/2' dealiasing
  
!-------------------------------------Miscellaneus-------------------

  REAL(KIND=8), PARAMETER :: d_implicit = 0.51d0 !implicitness
  REAL(KIND=8), PARAMETER   :: tolerance_dterr = 5d-5

  !----------------------defaults for runtime parameters (can be set in input file)
  REAL(KIND=8)   :: Courant = 0.25d0
  INTEGER(KIND=4) :: print_time_screen = 250
  LOGICAL        :: variable_dt= .true.
  REAL(kind=8) :: maxdt = 0.01d0



  !------------------------------------Finite Difference parameters

  INTEGER(KIND=4),PARAMETER :: n_s = 9             ! Leading length of stencil

  !----------------------defaults for runtime parameters (can be set in input file)  

  REAL(KIND=8)    :: init_dt = 1.0d-4    ! Time step (default value)
  INTEGER(KIND=4) :: dn_coeff = 1000000  ! coeff per dn_coeff steps (default value)
  INTEGER(KIND=4) :: dn_ke = 50          ! energy per dn_ke steps (default value)
  INTEGER(KIND=4) :: dn_vel = 50         ! velocity per dn_vel steps (default value)
  INTEGER(KIND=4) :: dn_Nu = 50          ! Nusselt per dn_Nu steps (default value)
  INTEGER(KIND=4) :: dn_hdf5 = 1000000   ! HDF5 output per dn_hdf5 steps (default value)
  INTEGER(KIND=4) :: numsteps = 10000    ! Number of steps  (default value)

  ! time series output at several probe locations
  integer(kind=4), parameter :: prl_n = 6 ! number of probe locations, hard coded for now
  integer(kind=4) :: dn_prbs = 10         ! time series output interval per
  real(kind=8), dimension(prl_n) :: prl_r  = (/ 0.1d0, 0.2d0, 0.3d0, 0.5d0, 0.7d0, 0.9d0 /) ! radial probe locations
  real(kind=8), dimension(prl_n) :: prl_th = (/ 0.0d0, 0.0d0, 0.0d0, 0.0d0, 0.0d0, 0.0d0 /) ! azimuthal probe locations
  real(kind=8), dimension(prl_n) :: prl_z  = (/ 0.0d0, 0.0d0, 0.0d0, 0.0d0, 0.0d0, 0.0d0 /) ! axial probe

  !----------------------------------- code revision identifier. automatically set by Makefile (PPFLAGS)
#ifndef GIT_REV
#define GIT_REV 'undef'
#endif
  CHARACTER(*), PARAMETER :: git_id = GIT_REV

  !----------------------------------- architecture used. automatically set by Makefile (PPFLAGS)
#ifndef ARCH_ID
#define ARCH_ID 'undef'
#endif
  CHARACTER(*), PARAMETER :: arch_id = ARCH_ID

  !----------------------------------- compiler flags used. automatically set by Makefile (PPFLAGS)
#ifndef CMP_OPTS
#define CMP_OPTS 'undef'
#endif
  CHARACTER(*), PARAMETER :: cmp_flgs = CMP_OPTS


contains

subroutine init_grid

  implicit none

  integer :: ir

  m_z = 2*m_z0
  m_f  = (m_th+1)*m_z ! Number of fouriers modes

  n_r  = m_r          ! Number of grid points
  n_th = 2*m_th
  n_z  = m_z

  n_f  = n_th*n_z     ! points in fourier dirs
  len_r  = 1d0        ! Physical domain size
  len_th = 2*PI/k_th0
  len_z  = 2*PI/k_z0

  r_i = eta/(1-eta)   ! inner radius
  r_o = 1/(1-eta)     ! outer radius


  allocate(r(n_r),th(n_th),z(n_z))

  r(1:n_r) = (/(((r_i+r_o)/2 - COS(PI*ir/(n_r-1))/2), ir=0,(n_r-1))/)   ! Chebyshev-distributed nodes
  th(1:n_th) = (/(ir*len_th/n_th,ir=0,n_th-1)/)
  z(1:n_z) = (/(ir*len_z/n_z,ir=0,n_z-1)/)

end subroutine init_grid

END MODULE mod_params
