program random_large_matrix
    use omp_lib
    implicit none

    ! Parameters
    integer :: n 

    ! Variables
    real(8),allocatable,dimension(:,:) :: matrix, matrix_work
    integer :: i, j
    real(8) :: StartTime1, StopTime1,  StartTime2, StopTime2, TimeTaken1, TimeTaken2, TimeTaken3, TimeTaken4
    integer,allocatable,dimension(:)::isuppz
    integer::INFO,LWORK,LIWORK
    !real(kind=dp),allocatable,dimension(:)::WORK
    real(8),allocatable,dimension(:)::WORK
    character(len=2) :: ValuePassed
    character(len=64) :: ResultFile
    integer::ierr, ValuePassedInt, ResultUnit

    ! Read the integer from the command-line argument
    call get_command_argument(1, value=ValuePassed)
    
    
    write(*,*) "This works.", ValuePassed
    read(ValuePassed, *, iostat=ierr) ValuePassedInt
    ResultUnit = 100 + ValuePassedInt
    write(ResultFile,'(A,I0)') "RohanResults/fort.", ValuePassedInt
    open(unit=ResultUnit, file=trim(ResultFile), status='replace', action='write', iostat=ierr)
    if (ierr /= 0) then
        write(*,*) "Unable to open results file: ", trim(ResultFile)
        stop 1
    end if
    
    
    do n = 1000,15000,500
        LWORK=64*n
       

        allocate(matrix(n,n))
        allocate(matrix_work(n,n))
        allocate(isuppz(2*n))
        allocate(WORK(LWORK))

        ! Seed the random number generator
        call random_seed()

        ! Initialize the random matrix

        StartTime1 = OMP_GET_WTIME()
        !$OMP PARALLEL DO PRIVATE (i,j) SCHEDULE(STATIC)
        do i = 1, n
            do j = 1, i
                call random_number(matrix(j, i))
                matrix(i,j) = matrix(j,i)
            end do
        end do

        !$OMP END PARALLEL DO
        StopTime1 = OMP_GET_WTIME()
        write(*,'(A,F7.4)') "Initialization time: ", StopTime1 - StartTime1

        matrix_work = matrix
        StartTime1 = OMP_GET_WTIME()
        call dgetrf(n,n,matrix_work,n,isuppz,info)
        if (info == 0) then
            call dgetri(n,matrix_work,n,isuppz,work,lwork,info)
        end if
        StopTime1 = OMP_GET_WTIME()
        TimeTaken1 = StopTime1-StartTime1
        if (info /= 0) then
            write(*,*) "dgetrf/dgetri failed with info:", info
            TimeTaken1 = -1.0d0
        end if

        write(*,'(A,I6,A,3F6.3)') "Method dgetrf", n," is: ", TimeTaken1

        !StartTime1 = OMP_GET_WTIME()
        !call matinvNew(matrix, n)
        !StopTime1 = OMP_GET_WTIME()
        !TimeTaken1 = StopTime1-StartTime1
        !write(*,'(A,I5,A,F7.4,F7.4)') "Method 1 New", n," is: ", TimeTaken1
        
        
        matrix_work = matrix
        StartTime1 = OMP_GET_WTIME()
        call matinv(matrix_work, n)
        StopTime1 = OMP_GET_WTIME()
        TimeTaken2 = StopTime1-StartTime1
        write(*,'(A,I5,A,F7.4,F6.3)') "MatInv", n," is: ",TimeTaken2

        
       

        !!iStartTime1 = OMP_GET_WTIME()
        !!call mkl_dgetrfnp('U',n,matrix,n,isuppz,work,lwork,info)
        !!StopTime1 = OMP_GET_WTIME()
        !!TimeTaken1 = StopTime1 - StartTime1

        !!StartTime2 = OMP_GET_WTIME()    
        !!call dsytri('U',n,matrix,n,isuppz,work,info)
        !!StopTime2 = OMP_GET_WTIME() 
        !!TimeTaken2 = StopTime2 - StartTime2

        !!write(*,'(A,I5,A,F6.3,3F6.3)') "Method dsytrf", n," is: ", TimeTaken1, TimeTaken2, TimeTaken1+TimeTaken2


        matrix_work = matrix
        StartTime1 = OMP_GET_WTIME()
        call dsytrf('U',n,matrix_work,n,isuppz,work,lwork,info)
        if (info == 0) then
            call dsytri('U',n,matrix_work,n,isuppz,work,info)
        end if
        StopTime1 = OMP_GET_WTIME()
        TimeTaken3 = StopTime1 - StartTime1
        if (info /= 0) then
            write(*,*) "dsytrf/dsytri failed with info:", info
            TimeTaken3 = -1.0d0
        end if
        write(*,*) "For dsystr? ", TimeTaken3

        matrix_work = matrix
        call dpotrf('U', n, matrix_work, n, info)
        if (info == 0) then
            matrix_work = matrix
            StartTime1 = OMP_GET_WTIME()
            write(*,*) "Performing Cholesky Decomposition"
            call dpotrf('U', n, matrix_work, n, info)
            if (info == 0) then
                call dpotri('U', n, matrix_work, n, info)
            end if
            StopTime1 = OMP_GET_WTIME()
            TimeTaken4 = StopTime1-StartTime1
            if (info /= 0) then
                write(*,*) "dpotrf/dpotri failed with info:", info
                TimeTaken4 = -1.0d0
            end if
        else
            write(*,*) "Skipping Cholesky: matrix is not SPD. dpotrf info:", info
            TimeTaken4 = -1.0d0
        end if

        write(*,*) "Time taken in Cholesky Decomposition n:",n," --", TimeTaken4
        write(*,'(I6,A,4F7.4)')  n, "     :",  TimeTaken1, TimeTaken2, TimeTaken3, TimeTaken4



        write(ResultUnit,'(I6,4F15.6)')  n, TimeTaken1, TimeTaken2, TimeTaken3, TimeTaken4
        flush(ResultUnit)
        
        

        deallocate(matrix)
        deallocate(matrix_work)
        deallocate(isuppz)
        deallocate(WORK)
        write(*,*) "   "


    end do

    close(ResultUnit)

end program random_large_matrix
