################################################
#                 WARNING!                     #
# This file has been auto-generated by xdress. #
# Do not modify!!!                             #
#                                              #
#                                              #
#                    Come on, guys. I mean it! #
################################################


from pyne cimport cpp_nucname

cdef extern from "enrichment_parameters.h" namespace "bright":

    cdef cppclass EnrichmentParameters:
        # constructors
        EnrichmentParameters() except +

        # attributes
        double M0
        double Mstar_0
        double N0
        double alpha_0
        int j
        int k
        double xP_j
        double xW_j

        # methods

        pass

    EnrichmentParameters fillUraniumEnrichmentDefaults() except +


