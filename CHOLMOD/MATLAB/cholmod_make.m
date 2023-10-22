function cholmod_make
%CHOLMOD_MAKE compiles the CHOLMOD mexFunctions
%
% Example:
%   cholmod_make
%
% CHOLMOD relies on AMD and COLAMD, and optionally CCOLAMD, CAMD, and METIS.
% You must type the cholmod_make command while in the CHOLMOD/MATLAB directory.
%
% See also analyze, bisect, chol2, cholmod2, etree2, lchol, ldlchol, ldlsolve,
%   ldlupdate, metis, spsym, nesdis, septree, resymbol, sdmult, sparse2,
%   symbfact2, mread, mwrite, ldlrowmod

% Copyright 2006-2022, Timothy A. Davis, All Rights Reserved.
% SPDX-License-Identifier: GPL-2.0+

details = 0 ;	    % 1 if details of each command are to be printed

v = version ;
try
    % ispc does not appear in MATLAB 5.3
    pc = ispc ;
    mac = ismac ;
catch                                                                       %#ok
    % if ispc fails, assume we are on a Windows PC if it's not unix
    pc = ~isunix ;
    mac = 0 ;
end

flags = '' ;
is64 = ~isempty (strfind (computer, '64')) ;
if (is64)
    % 64-bit MATLAB
    flags = '-largeArrayDims' ;
else
    error ('32-bit version no longer supported') ;
end

% MATLAB 8.3.0 now has a -silent option to keep 'mex' from burbling too much
if (~verLessThan ('matlab', '8.3.0'))
    flags = ['-silent ' flags] ;
end

include = '-I. -I.. -I../../AMD/Include -I../../COLAMD/Include -I../../CCOLAMD/Include -I../../CAMD/Include -I../Include -I../../SuiteSparse_config' ;

if (verLessThan ('matlab', '7.0'))
    % do not attempt to compile CHOLMOD with large file support
    include = [include ' -DNLARGEFILE'] ;
elseif (~pc)
    % Linux/Unix require these flags for large file support
    include = [include ' -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE'] ;
end

if (verLessThan ('matlab', '6.5'))
    % logical class does not exist in MATLAB 6.1 or earlier
    include = [include ' -DMATLAB6p1_OR_EARLIER'] ;
end

% Determine if METIS is available
have_metis = exist ('../SuiteSparse_metis', 'dir') ;

if (have_metis)
    fprintf ('Compiling CHOLMOD with METIS for MATLAB Version %s\n', v) ;
    include = [include ' -I../SuiteSparse_metis/include'] ;
    include = [include ' -I../SuiteSparse_metis/GKlib'] ;
    include = [include ' -I../SuiteSparse_metis/libmetis'] ;
else
    fprintf ('Compiling CHOLMOD without METIS for MATLAB Version %s\n', v) ;
    include = ['-DNPARTITION ' include] ;
end

 %---------------------------------------------------------------------------
 % BLAS option
 %---------------------------------------------------------------------------

 % This is exceedingly ugly.  The MATLAB mex command needs to be told where to
 % find the LAPACK and BLAS libraries, which is a real portability nightmare.

if (pc)
    % BLAS/LAPACK functions have no underscore on Windows
    flags = [flags ' -DBLAS_NO_UNDERSCORE'] ;
    if (verLessThan ('matlab', '7.5'))
        lapack = 'libmwlapack.lib' ;
    elseif (verLessThan ('matlab', '9.5'))
        lapack = 'libmwlapack.lib libmwblas.lib' ;
    else
        lapack = '-lmwlapack -lmwblas' ;
    end
else
    % BLAS/LAPACK functions have an underscore suffix
    flags = [flags ' -DBLAS_UNDERSCORE'] ;
    if (verLessThan ('matlab', '7.5'))
        lapack = '-lmwlapack' ;
    else
        lapack = '-lmwlapack -lmwblas' ;
    end
end

if (~verLessThan ('matlab', '7.8'))
    % versions 7.8 and later on 64-bit platforms use a 64-bit BLAS
    fprintf ('with 64-bit BLAS\n') ;
    flags = [flags ' -DBLAS64'] ;
end

if (~(pc || mac))
    % for POSIX timing routine
    lapack = [lapack ' -lrt'] ;
end

 %-------------------------------------------------------------------------------

config_src = { '../../SuiteSparse_config/SuiteSparse_config' } ;

ordering_src = { ...
    '../../AMD/Source/amd_l1', ...
    '../../AMD/Source/amd_l2', ...
    '../../AMD/Source/amd_l_aat', ...
    '../../AMD/Source/amd_l_control', ...
    '../../AMD/Source/amd_l_defaults', ...
    '../../AMD/Source/amd_l_dump', ...
    '../../AMD/Source/amd_l_info', ...
    '../../AMD/Source/amd_l_order', ...
    '../../AMD/Source/amd_l_postorder', ...
    '../../AMD/Source/amd_l_post_tree', ...
    '../../AMD/Source/amd_l_preprocess', ...
    '../../AMD/Source/amd_l_valid', ...
    '../../CAMD/Source/camd_l1', ...
    '../../CAMD/Source/camd_l2', ...
    '../../CAMD/Source/camd_l_aat', ...
    '../../CAMD/Source/camd_l_control', ...
    '../../CAMD/Source/camd_l_defaults', ...
    '../../CAMD/Source/camd_l_dump', ...
    '../../CAMD/Source/camd_l_info', ...
    '../../CAMD/Source/camd_l_order', ...
    '../../CAMD/Source/camd_l_postorder', ...
    '../../CAMD/Source/camd_l_preprocess', ...
    '../../CAMD/Source/camd_l_valid', ...
    '../../COLAMD/Source/colamd_l', ...
    '../../CCOLAMD/Source/ccolamd_l' } ;

cholmod_matlab = { 'cholmod_matlab' } ;

cholmod_src = {
    '../Utility/cholmod_l_aat', ...
    '../Utility/cholmod_l_add', ...
    '../Utility/cholmod_l_add_size_t', ...
    '../Utility/cholmod_l_allocate_dense', ...
    '../Utility/cholmod_l_allocate_factor', ...
    '../Utility/cholmod_l_allocate_sparse', ...
    '../Utility/cholmod_l_allocate_triplet', ...
    '../Utility/cholmod_l_allocate_work', ...
    '../Utility/cholmod_l_alloc_factor', ...
    '../Utility/cholmod_l_alloc_work', ...
    '../Utility/cholmod_l_band', ...
    '../Utility/cholmod_l_band_nnz', ...
    '../Utility/cholmod_l_calloc', ...
    '../Utility/cholmod_l_change_factor', ...
    '../Utility/cholmod_l_clear_flag', ...
    '../Utility/cholmod_l_copy', ...
    '../Utility/cholmod_l_copy_dense2', ...
    '../Utility/cholmod_l_copy_dense', ...
    '../Utility/cholmod_l_copy_factor', ...
    '../Utility/cholmod_l_copy_sparse', ...
    '../Utility/cholmod_l_copy_triplet', ...
    '../Utility/cholmod_l_cumsum', ...
    '../Utility/cholmod_l_dbound', ...
    '../Utility/cholmod_l_defaults', ...
    '../Utility/cholmod_l_dense_nnz', ...
    '../Utility/cholmod_l_dense_to_sparse', ...
    '../Utility/cholmod_l_divcomplex', ...
    '../Utility/cholmod_l_ensure_dense', ...
    '../Utility/cholmod_l_error', ...
    '../Utility/cholmod_l_eye', ...
    '../Utility/cholmod_l_factor_to_sparse', ...
    '../Utility/cholmod_l_finish', ...
    '../Utility/cholmod_l_free', ...
    '../Utility/cholmod_l_free_dense', ...
    '../Utility/cholmod_l_free_factor', ...
    '../Utility/cholmod_l_free_sparse', ...
    '../Utility/cholmod_l_free_triplet', ...
    '../Utility/cholmod_l_free_work', ...
    '../Utility/cholmod_l_hypot', ...
    '../Utility/cholmod_l_malloc', ...
    '../Utility/cholmod_l_maxrank', ...
    '../Utility/cholmod_l_mult_size_t', ...
    '../Utility/cholmod_l_nnz', ...
    '../Utility/cholmod_l_ones', ...
    '../Utility/cholmod_l_pack_factor', ...
    '../Utility/cholmod_l_ptranspose', ...
    '../Utility/cholmod_l_reallocate_column', ...
    '../Utility/cholmod_l_reallocate_factor', ...
    '../Utility/cholmod_l_reallocate_sparse', ...
    '../Utility/cholmod_l_reallocate_triplet', ...
    '../Utility/cholmod_l_realloc', ...
    '../Utility/cholmod_l_realloc_multiple', ...
    '../Utility/cholmod_l_sbound', ...
    '../Utility/cholmod_l_score_comp', ...
    '../Utility/cholmod_l_set_empty', ...
    '../Utility/cholmod_l_sort', ...
    '../Utility/cholmod_l_sparse_to_dense', ...
    '../Utility/cholmod_l_sparse_to_triplet', ...
    '../Utility/cholmod_l_speye', ...
    '../Utility/cholmod_l_spzeros', ...
    '../Utility/cholmod_l_start', ...
    '../Utility/cholmod_l_transpose', ...
    '../Utility/cholmod_l_transpose_sym', ...
    '../Utility/cholmod_l_transpose_unsym', ...
    '../Utility/cholmod_l_triplet_to_sparse', ...
    '../Utility/cholmod_l_version', ...
    '../Utility/cholmod_l_xtype', ...
    '../Utility/cholmod_l_zeros', ...
    '../Utility/cholmod_mult_uint64_t', ...
    '../Utility/cholmod_memdebug', ...
    '../Check/cholmod_l_check', ...
    '../Check/cholmod_l_read', ...
    '../Check/cholmod_l_write', ...
    '../Cholesky/cholmod_l_amd', ...
    '../Cholesky/cholmod_l_analyze', ...
    '../Cholesky/cholmod_l_colamd', ...
    '../Cholesky/cholmod_l_etree', ...
    '../Cholesky/cholmod_l_factorize', ...
    '../Cholesky/cholmod_l_postorder', ...
    '../Cholesky/cholmod_l_rcond', ...
    '../Cholesky/cholmod_l_resymbol', ...
    '../Cholesky/cholmod_l_rowcolcounts', ...
    '../Cholesky/cholmod_l_rowfac', ...
    '../Cholesky/cholmod_l_solve', ...
    '../Cholesky/cholmod_l_spsolve', ...
    '../MatrixOps/cholmod_l_drop', ...
    '../MatrixOps/cholmod_l_horzcat', ...
    '../MatrixOps/cholmod_l_norm', ...
    '../MatrixOps/cholmod_l_scale', ...
    '../MatrixOps/cholmod_l_sdmult', ...
    '../MatrixOps/cholmod_l_ssmult', ...
    '../MatrixOps/cholmod_l_submatrix', ...
    '../MatrixOps/cholmod_l_vertcat', ...
    '../MatrixOps/cholmod_l_symmetry', ...
    '../Modify/cholmod_l_rowadd', ...
    '../Modify/cholmod_l_rowdel', ...
    '../Modify/cholmod_l_updown', ...
    '../Supernodal/cholmod_l_super_numeric', ...
    '../Supernodal/cholmod_l_super_solve', ...
    '../Supernodal/cholmod_l_super_symbolic', ...
    '../Partition/cholmod_metis_wrapper', ...
    '../Partition/cholmod_l_ccolamd', ...
    '../Partition/cholmod_l_csymamd', ...
    '../Partition/cholmod_l_camd', ...
    '../Partition/cholmod_l_metis', ...
    '../Partition/cholmod_l_nesdis' } ;

cholmod_mex_src = { ...
    'analyze', ...
    'bisect', ...
    'chol2', ...
    'cholmod2', ...
    'etree2', ...
    'lchol', ...
    'ldlchol', ...
    'ldlsolve', ...
    'ldlupdate', ...
    'ldlrowmod', ...
    'metis', ...
    'spsym', ...
    'nesdis', ...
    'septree', ...
    'resymbol', ...
    'sdmult', ...
    'sparse2', ...
    'symbfact2', ...
    'mread', ...
    'mwrite', ...
    'lxbpattern', 'lsubsolve' } ;   % <=== these 2 are just for testing

if (pc)
    obj_extension = '.obj' ;
else
    obj_extension = '.o' ;
end

 % compile each library source file
obj = '' ;

source = [ordering_src config_src cholmod_src cholmod_matlab] ;

kk = 0 ;

for f = source
    ff = f {1} ;
    slash = strfind (ff, '/') ;
    if (isempty (slash))
        slash = 1 ;
    else
        slash = slash (end) + 1 ;
    end
    o = ff (slash:end) ;
    % fprintf ('%s\n', o) ;
    o = [o obj_extension] ;
    obj = [obj  ' ' o] ;					            %#ok
    s = sprintf ('mex %s -O %s -c %s.c', flags, include, ff) ;
    kk = do_cmd (s, kk, details) ;
end

 % compile each mexFunction
for f = cholmod_mex_src
    s = sprintf ('mex %s -O %s %s.c', flags, include, f{1}) ;
    s = [s obj ' ' lapack] ;						    %#ok
    kk = do_cmd (s, kk, details) ;
end

 % clean up
s = ['delete ' obj] ;
do_cmd (s, kk, details) ;
fprintf ('\nCHOLMOD successfully compiled\n') ;

 %------------------------------------------------------------------------------
function kk = do_cmd (s, kk, details)
 %DO_CMD: evaluate a command, and either print it or print a "."
if (details)
    fprintf ('%s\n', s) ;
else
    if (mod (kk, 60) == 0)
	fprintf ('\n') ;
    end
    kk = kk + 1 ;
    fprintf ('.') ;
end
eval (s) ;
