################################################
#                 WARNING!                     #
# This file has been auto-generated by xdress. #
# Do not modify!!!                             #
#                                              #
#                                              #
#                    Come on, guys. I mean it! #
################################################
"""Python wrapper for LWR1G.
"""
cimport fccomp
cimport reactor1g
cimport reactor_parameters
from bright cimport cpp_fccomp
from bright cimport cpp_reactor1g
from bright cimport cpp_reactor_parameters
from libcpp.string cimport string as std_string

import fccomp
import reactor1g
import reactor_parameters



cdef class LightWaterReactor1G(reactor1g.Reactor1G):
    """A One-Group Light Water Reactor Fuel Cycle Component.  This is a daughter 
    class of Reactor1G and a granddaughter of FCComp.
    
    Parameters
    ----------
    lib : str, optional
        The path the the LWR HDF5 data library.  This value is set to 
        Reactor1G.libfile and used by Reactor1G.loadlib().
    rp : ReactorParameters, optional
        The physical reactor parameter data to initialize this LWR instance with.  
        If this argument is not provided, default values are taken.
    n : str, optional
        The name of this LWR instance.
    
    """



    # constuctors
    def __cinit__(self, *args, **kwargs):
        self._inst = NULL
        self._free_inst = True

        # cached property defaults


    def _lightwaterreactor1g_lightwaterreactor1g_0(self):
        """LightWaterReactor1G(self)
        """
        self._inst = new cpp_light_water_reactor1g.LightWaterReactor1G()
    
    
    def _lightwaterreactor1g_lightwaterreactor1g_1(self, lib, n=""):
        """LightWaterReactor1G(self, lib, n="")
        """
        cdef char * lib_proxy
        cdef char * n_proxy
        lib_bytes = lib.encode()
        n_bytes = n.encode()
        self._inst = new cpp_light_water_reactor1g.LightWaterReactor1G(std_string(<char *> lib_bytes), std_string(<char *> n_bytes))
    
    
    def _lightwaterreactor1g_lightwaterreactor1g_2(self, lib, rp, n=""):
        """LightWaterReactor1G(self, lib, rp, n="")
        """
        cdef char * lib_proxy
        cdef reactor_parameters.ReactorParameters rp_proxy
        cdef char * n_proxy
        lib_bytes = lib.encode()
        rp_proxy = <reactor_parameters.ReactorParameters> rp
        n_bytes = n.encode()
        self._inst = new cpp_light_water_reactor1g.LightWaterReactor1G(std_string(<char *> lib_bytes), (<cpp_reactor_parameters.ReactorParameters *> rp_proxy._inst)[0], std_string(<char *> n_bytes))
    
    
    def _lightwaterreactor1g_lightwaterreactor1g_3(self, rp, n=""):
        """LightWaterReactor1G(self, rp, n="")
        """
        cdef reactor_parameters.ReactorParameters rp_proxy
        cdef char * n_proxy
        rp_proxy = <reactor_parameters.ReactorParameters> rp
        n_bytes = n.encode()
        self._inst = new cpp_light_water_reactor1g.LightWaterReactor1G((<cpp_reactor_parameters.ReactorParameters *> rp_proxy._inst)[0], std_string(<char *> n_bytes))
    
    
    _lightwaterreactor1g_lightwaterreactor1g_0_argtypes = frozenset()
    _lightwaterreactor1g_lightwaterreactor1g_1_argtypes = frozenset(((0, str), (1, str), ("lib", str), ("n", str)))
    _lightwaterreactor1g_lightwaterreactor1g_2_argtypes = frozenset(((0, str), (1, reactor_parameters.ReactorParameters), (2, str), ("lib", str), ("rp", reactor_parameters.ReactorParameters), ("n", str)))
    _lightwaterreactor1g_lightwaterreactor1g_3_argtypes = frozenset(((0, reactor_parameters.ReactorParameters), (1, str), ("rp", reactor_parameters.ReactorParameters), ("n", str)))
    
    def __init__(self, *args, **kwargs):
        """LightWaterReactor1G(self, rp, n="")
        """
        types = set([(i, type(a)) for i, a in enumerate(args)])
        types.update([(k, type(v)) for k, v in kwargs.items()])
        # vtable-like dispatch for exactly matching types
        if types <= self._lightwaterreactor1g_lightwaterreactor1g_0_argtypes:
            self._lightwaterreactor1g_lightwaterreactor1g_0(*args, **kwargs)
            return
        if types <= self._lightwaterreactor1g_lightwaterreactor1g_1_argtypes:
            self._lightwaterreactor1g_lightwaterreactor1g_1(*args, **kwargs)
            return
        if types <= self._lightwaterreactor1g_lightwaterreactor1g_3_argtypes:
            self._lightwaterreactor1g_lightwaterreactor1g_3(*args, **kwargs)
            return
        if types <= self._lightwaterreactor1g_lightwaterreactor1g_2_argtypes:
            self._lightwaterreactor1g_lightwaterreactor1g_2(*args, **kwargs)
            return
        # duck-typed dispatch based on whatever works!
        try:
            self._lightwaterreactor1g_lightwaterreactor1g_0(*args, **kwargs)
            return
        except (RuntimeError, TypeError, NameError):
            pass
        try:
            self._lightwaterreactor1g_lightwaterreactor1g_1(*args, **kwargs)
            return
        except (RuntimeError, TypeError, NameError):
            pass
        try:
            self._lightwaterreactor1g_lightwaterreactor1g_3(*args, **kwargs)
            return
        except (RuntimeError, TypeError, NameError):
            pass
        try:
            self._lightwaterreactor1g_lightwaterreactor1g_2(*args, **kwargs)
            return
        except (RuntimeError, TypeError, NameError):
            pass
        raise RuntimeError('method __init__() could not be dispatched')
    

    # attributes

    # methods
    def calc_params(self):
        """calc_params(self)
        Along with its own parameter set to track, the LWR model implements its own 
        function to set these parameters.  This function is equivalent to the following::
        
            self.params_prior_calc["BUd"]  = 0.0
            self.params_after_calc["BUd"] = self.BUd
        
            self.params_prior_calc["U"]  = self.mat_feed_u.mass
            self.params_after_calc["U"] = self.mat_prod_u.mass
        
            self.params_prior_calc["TRU"]  = self.mat_feed_tru.mass
            self.params_after_calc["TRU"] = self.mat_prod_tru.mass
        
            self.params_prior_calc["ACT"]  = self.mat_feed_act.mass
            self.params_after_calc["ACT"] = self.mat_prod_act.mass
        
            self.params_prior_calc["LAN"]  = self.mat_feed_lan.mass
            self.params_after_calc["LAN"] = self.mat_prod_lan.mass
        
            self.params_prior_calc["FP"]  = 1.0 - self.mat_feed_act.mass  - self.mat_feed_lan.mass
        
        """
        (<cpp_fccomp.FCComp *> self._inst).calc_params()
    
    

    pass





