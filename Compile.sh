#!/bin/bash
set -e

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

if command -v module >/dev/null 2>&1; then
  module load intel-oneapi/2023.1 || true
fi

mkdir -p RohanResults
rm -f RohanResults/fort.*
rm -f TestCase.o

if command -v ifort >/dev/null 2>&1; then
  FC=ifort
  FFLAGS="-O3 -xHost -liomp5"
  LIBS="-qmkl=parallel"
elif command -v ifx >/dev/null 2>&1; then
  FC=ifx
  FFLAGS="-O3 -xHost -liomp5"
  LIBS="-qmkl=parallel"
elif command -v gfortran >/dev/null 2>&1; then
  FC=gfortran
  FFLAGS="-O3 -march=native -fopenmp"
  if command -v xcrun >/dev/null 2>&1; then
    SDKROOT=$(xcrun --show-sdk-path)
    FFLAGS="$FFLAGS -Wl,-syslibroot,${SDKROOT}"
  fi
  if command -v brew >/dev/null 2>&1 && brew list --versions openblas >/dev/null 2>&1 && brew list --versions lapack >/dev/null 2>&1; then
    OPENBLAS_PREFIX=$(brew --prefix openblas)
    LAPACK_PREFIX=$(brew --prefix lapack)
    LIBS="-L${LAPACK_PREFIX}/lib -L${OPENBLAS_PREFIX}/lib -Wl,-rpath,${LAPACK_PREFIX}/lib -Wl,-rpath,${OPENBLAS_PREFIX}/lib -llapack -lopenblas"
  else
    LIBS="-llapack -lblas"
  fi
else
  echo "No Fortran compiler found. Install Intel oneAPI or run: brew install gcc openblas lapack"
  exit 1
fi

echo "Using compiler: $FC"
$FC $FFLAGS matinv.f90 TestCase.f90 -o TestCase.o $LIBS

for i in 4 8 12 24
do
  echo "Iteration $i"
  export OMP_NUM_THREADS=$i
  export MKL_NUM_THREADS=$i
  ./TestCase.o $i
done
