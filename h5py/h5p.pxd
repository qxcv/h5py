#+
# 
# This file is part of h5py, a low-level Python interface to the HDF5 library.
# 
# Copyright (C) 2008 Andrew Collette
# http://h5py.alfven.org
# License: BSD  (See LICENSE.txt for full license)
# 
# $Date$
# 
#-

# This file is based on code from the PyTables project.  The complete PyTables
# license is available at licenses/pytables.txt, in the distribution root
# directory.

include "std_defs.pxi"
from h5 cimport class ObjectID

cdef class PropID(ObjectID):
    """ Base class for all property lists """
    pass

cdef class PropClassID(PropID):
    """ Represents an HDF5 property list class.  These can be either (locked)
        library-defined classes or user-created classes.
    """
    pass

cdef class PropInstanceID(PropID):
    """ Represents an instance of a property list class (i.e. an actual list
        which can be passed on to other API functions).
    """
    pass

cdef class PropDCID(PropInstanceID):
    """ Dataset creation property list """
    pass

cdef class PropDXID(PropInstanceID):
    """ Dataset transfer property list """
    pass

cdef class PropFCID(PropInstanceID):
    """ File creation property list """
    pass

cdef class PropFAID(PropInstanceID):
    """ File access property list """
    pass

cdef hid_t pdefault(PropID pid)
cdef object propwrap(hid_t id_in)

cdef extern from "hdf5.h":

  int H5P_DEFAULT

  ctypedef int H5Z_filter_t

  # HDF5 layouts
  ctypedef enum H5D_layout_t:
    H5D_LAYOUT_ERROR    = -1,
    H5D_COMPACT         = 0,    # raw data is very small
    H5D_CONTIGUOUS      = 1,    # the default
    H5D_CHUNKED         = 2,    # slow and fancy
    H5D_NLAYOUTS        = 3     # this one must be last!

  ctypedef enum H5D_alloc_time_t:
    H5D_ALLOC_TIME_ERROR	=-1,
    H5D_ALLOC_TIME_DEFAULT  =0,
    H5D_ALLOC_TIME_EARLY	=1,
    H5D_ALLOC_TIME_LATE	    =2,
    H5D_ALLOC_TIME_INCR	    =3

  ctypedef enum H5D_space_status_t:
    H5D_SPACE_STATUS_ERROR	        =-1,
    H5D_SPACE_STATUS_NOT_ALLOCATED	=0,
    H5D_SPACE_STATUS_PART_ALLOCATED	=1,
    H5D_SPACE_STATUS_ALLOCATED		=2

  ctypedef enum H5D_fill_time_t:
    H5D_FILL_TIME_ERROR	=-1,
    H5D_FILL_TIME_ALLOC =0,
    H5D_FILL_TIME_NEVER	=1,
    H5D_FILL_TIME_IFSET	=2

  ctypedef enum H5D_fill_value_t:
    H5D_FILL_VALUE_ERROR        =-1,
    H5D_FILL_VALUE_UNDEFINED    =0,
    H5D_FILL_VALUE_DEFAULT      =1,
    H5D_FILL_VALUE_USER_DEFINED =2

  cdef enum H5Z_EDC_t:
    H5Z_ERROR_EDC       = -1,
    H5Z_DISABLE_EDC     = 0,
    H5Z_ENABLE_EDC      = 1,
    H5Z_NO_EDC          = 2 

  cdef enum H5F_close_degree_t:
    H5F_CLOSE_WEAK  = 0,
    H5F_CLOSE_SEMI  = 1,
    H5F_CLOSE_STRONG = 2,
    H5F_CLOSE_DEFAULT = 3

  ctypedef enum H5FD_mem_t:
    H5FD_MEM_NOLIST	= -1,
    H5FD_MEM_DEFAULT	= 0,
    H5FD_MEM_SUPER      = 1,
    H5FD_MEM_BTREE      = 2,
    H5FD_MEM_DRAW       = 3,
    H5FD_MEM_GHEAP      = 4,
    H5FD_MEM_LHEAP      = 5,
    H5FD_MEM_OHDR       = 6,
    H5FD_MEM_NTYPES

  # Property list classes
  hid_t H5P_NO_CLASS
  hid_t H5P_FILE_CREATE 
  hid_t H5P_FILE_ACCESS 
  hid_t H5P_DATASET_CREATE 
  hid_t H5P_DATASET_XFER 

  # --- Property list operations ----------------------------------------------
  # General operations
  hid_t  H5Pcreate(hid_t plist_id) except *
  hid_t  H5Pcopy(hid_t plist_id) except *
  int    H5Pget_class(hid_t plist_id) except *
  herr_t H5Pclose(hid_t plist_id) except *
  htri_t H5Pequal( hid_t id1, hid_t id2  ) except *
  herr_t H5Pclose_class(hid_t id) except *

  # File creation properties
  herr_t H5Pget_version(hid_t plist, unsigned int *super_, unsigned int* freelist, 
                        unsigned int *stab, unsigned int *shhdr) except *
  herr_t H5Pset_userblock(hid_t plist, hsize_t size) except *
  herr_t H5Pget_userblock(hid_t plist, hsize_t * size) except *
  herr_t H5Pset_sizes(hid_t plist, size_t sizeof_addr, size_t sizeof_size) except *
  herr_t H5Pget_sizes(hid_t plist, size_t *sizeof_addr, size_t *sizeof_size) except *
  herr_t H5Pset_sym_k(hid_t plist, unsigned int ik, unsigned int lk) except *
  herr_t H5Pget_sym_k(hid_t plist, unsigned int *ik, unsigned int *lk) except *
  herr_t H5Pset_istore_k(hid_t plist, unsigned int ik) except *
  herr_t H5Pget_istore_k(hid_t plist, unsigned int *ik) except *

  # File access
  herr_t    H5Pset_fclose_degree(hid_t fapl_id, H5F_close_degree_t fc_degree) except *
  herr_t    H5Pget_fclose_degree(hid_t fapl_id, H5F_close_degree_t *fc_degree) except *
  herr_t    H5Pset_fapl_core( hid_t fapl_id, size_t increment, hbool_t backing_store) except *
  herr_t    H5Pget_fapl_core( hid_t fapl_id, size_t *increment, hbool_t *backing_store) except *
  herr_t    H5Pset_fapl_family ( hid_t fapl_id,  hsize_t memb_size, hid_t memb_fapl_id  ) except *
  herr_t    H5Pget_fapl_family ( hid_t fapl_id, hsize_t *memb_size, hid_t *memb_fapl_id  ) except *
  herr_t    H5Pset_family_offset ( hid_t fapl_id, hsize_t offset) except *
  herr_t    H5Pget_family_offset ( hid_t fapl_id, hsize_t *offset) except *
  herr_t    H5Pset_fapl_log(hid_t fapl_id, char *logfile, unsigned int flags, size_t buf_size) except *
  herr_t    H5Pset_fapl_multi(hid_t fapl_id, H5FD_mem_t *memb_map, hid_t *memb_fapl,
                char **memb_name, haddr_t *memb_addr, hbool_t relax) 

  # Dataset creation properties
  herr_t        H5Pset_layout(hid_t plist, int layout) except *
  H5D_layout_t  H5Pget_layout(hid_t plist) except *
  herr_t        H5Pset_chunk(hid_t plist, int ndims, hsize_t * dim) except *
  int           H5Pget_chunk(hid_t plist, int max_ndims, hsize_t * dims  ) except *
  herr_t        H5Pset_deflate( hid_t plist, int level) except *
  herr_t        H5Pset_fill_value(hid_t plist_id, hid_t type_id, void *value  ) except *
  herr_t        H5Pget_fill_value(hid_t plist_id, hid_t type_id, void *value  ) except *
  herr_t        H5Pfill_value_defined(hid_t plist_id, H5D_fill_value_t *status  ) except *
  herr_t        H5Pset_fill_time(hid_t plist_id, H5D_fill_time_t fill_time  ) except *
  herr_t        H5Pget_fill_time(hid_t plist_id, H5D_fill_time_t *fill_time  ) except *
  herr_t        H5Pset_alloc_time(hid_t plist_id, H5D_alloc_time_t alloc_time  ) except *
  herr_t        H5Pget_alloc_time(hid_t plist_id, H5D_alloc_time_t *alloc_time  ) except *
  herr_t        H5Pset_filter(hid_t plist, H5Z_filter_t filter, unsigned int flags,
                              size_t cd_nelmts, unsigned int cd_values[]  ) except *
  htri_t        H5Pall_filters_avail(hid_t dcpl_id) except *
  int           H5Pget_nfilters(hid_t plist) except *
  H5Z_filter_t  H5Pget_filter(hid_t plist, unsigned int filter_number, 
                              unsigned int *flags, size_t *cd_nelmts, 
                              unsigned int *cd_values, size_t namelen, char name[]  ) except *
  herr_t        H5Pget_filter_by_id( hid_t plist_id, H5Z_filter_t filter, 
                                     unsigned int *flags, size_t *cd_nelmts, 
                                     unsigned int cd_values[], size_t namelen, char name[]) except *
  herr_t        H5Pmodify_filter(hid_t plist, H5Z_filter_t filter, unsigned int flags,
                                 size_t cd_nelmts, unsigned int cd_values[]  ) except *
  herr_t        H5Premove_filter(hid_t plist, H5Z_filter_t filter  ) except *
  herr_t        H5Pset_fletcher32(hid_t plist) except *
  herr_t        H5Pset_shuffle(hid_t plist_id) except *
  herr_t        H5Pset_szip(hid_t plist, unsigned int options_mask, unsigned int pixels_per_block) except *


  # Transfer properties
  herr_t    H5Pset_edc_check(hid_t plist, H5Z_EDC_t check) except *
  H5Z_EDC_t H5Pget_edc_check(hid_t plist) except *

  # Other properties
  herr_t H5Pset_cache(hid_t plist_id, int mdc_nelmts, int rdcc_nelmts,
                      size_t rdcc_nbytes, double rdcc_w0) except *
  herr_t H5Pset_sieve_buf_size(hid_t fapl_id, hsize_t size) except *
  herr_t H5Pset_fapl_log(hid_t fapl_id, char *logfile,
                         unsigned int flags, size_t buf_size) except *


