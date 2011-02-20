# Cython imports
from libcpp.map cimport map as cpp_map
from libcpp.set cimport set as cpp_set
from libcpp.vector cimport vector as cpp_vector
from cython.operator cimport dereference as deref
from cython.operator cimport preincrement as inc

cimport numpy as np
import numpy as np

# Local imports
cimport std


#
# Map conversions
#

# <int, double> conversions
cdef cpp_map[int, double] dict_to_map_int_dbl(dict)
cdef dict map_to_dict_int_dbl(cpp_map[int, double])

# <string, int> conversions
cdef cpp_map[std.string, int] dict_to_map_str_int(dict)
cdef dict map_to_dict_str_int(cpp_map[std.string, int])

# <int, string> conversions
cdef cpp_map[int, std.string] dict_to_map_int_str(dict)
cdef dict map_to_dict_int_str(cpp_map[int, std.string])

# <string, double> conversions
cdef cpp_map[std.string, double] dict_to_map_str_dbl(dict)
cdef dict map_to_dict_str_dbl(cpp_map[std.string, double])


#
# Set conversions
#

# Integer sets
cdef cpp_set[int] py_to_cpp_set_int(set)
cdef set cpp_to_py_set_int(cpp_set[int])

# String sets
cdef cpp_set[std.string] py_to_cpp_set_str(set)
cdef set cpp_to_py_set_str(cpp_set[std.string])


#
# Vector conversions
#

# 1D Float arrays
cdef cpp_vector[double] array_to_vector_1d_dbl(np.ndarray[np.float64_t, ndim=1])
cdef np.ndarray[np.float64_t, ndim=1] vector_to_array_1d_dbl(cpp_vector[double])



#
# Map-Vector Conversions
#

# {int: np.array()} 
cdef cpp_map[int, cpp_vector[double]] dict_to_map_int_vector_to_array_1d_dbl(dict)
cdef dict map_to_dict_int_array_to_vector_1d_dbl(cpp_map[int, cpp_vector[double]])



#
# Map-Vector Conversions
#

# {int: {int: np.array()}}
cdef cpp_map[int, cpp_map[int, cpp_vector[double]]] dict_to_map_int_int_vector_to_array_1d_dbl(dict)
cdef dict map_to_dict_int_int_array_to_vector_1d_dbl(cpp_map[int, cpp_map[int, cpp_vector[double]]])