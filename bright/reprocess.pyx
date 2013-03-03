################################################
#                 WARNING!                     #
# This file has been auto-generated by Bright. #
# Do not modify!!!                             #
#                                              #
#                                              #
#                    Come on, guys. I mean it! #
################################################
"""Python wrapper for Reprocess.
"""
cimport fccomp
from bright cimport cpp_fccomp
from libcpp.map cimport map as cpp_map
from libcpp.string cimport string as std_string
from pyne cimport cpp_material
from pyne cimport material
from pyne cimport stlconverters as conv

from pyne import material
from pyne import stlconverters as conv
import fccomp

cdef class Reprocess(fccomp.FCComp):
    """Reprocess Fuel Cycle Component Class.  Daughter of FCComp class.
    
    Parameters
    ----------
    sepeff : dict or map or None, optional 
        A dictionary containing the separation efficiencies (float) to initialize
        the instance with.  The keys of this dictionary may be strings or ints::
    
        # ssed = string dictionary of separation efficiencies.  
        # Of form {zz: 0.99}, eg 
        ssed = {92: 0.999, "94": 0.99} 
        # of form {LL: 0.99}, eg 
        ssed = {"U": 0.999, "PU": 0.99} 
        # or of form {mixed: 0.99}, eg 
        ssed = {"U235": 0.9, 922350: 0.999, "94239": 0.99}
    
    name : str, optional
        The name of the reprocessing fuel cycle component instance.
    
    """

    # constuctors
    def __cinit__(self, *args, **kwargs):
        self._inst = NULL
        self._free_inst = True

        # cached property defaults
        self._sepeff = None

    def _reprocess_reprocess_0(self, *args, **kwargs):
        """"""
        self._inst = new cpp_reprocess.Reprocess()
    
    
    def _reprocess_reprocess_1(self, sed, n="", *args, **kwargs):
        """"""
        cdef conv._MapIntDouble sed_proxy
        sed_proxy = conv.MapIntDouble(sed, not isinstance(sed, conv._MapIntDouble))
        self._inst = new cpp_reprocess.Reprocess(sed_proxy.map_ptr[0], std_string(<char *> n))
    
    
    def _reprocess_reprocess_2(self, ssed, n="", *args, **kwargs):
        """"""
        cdef conv._MapStrDouble ssed_proxy
        ssed_proxy = conv.MapStrDouble(ssed, not isinstance(ssed, conv._MapStrDouble))
        self._inst = new cpp_reprocess.Reprocess(ssed_proxy.map_ptr[0], std_string(<char *> n))
    
    
    _reprocess_reprocess_0_argtypes = frozenset()
    _reprocess_reprocess_1_argtypes = frozenset(((0, conv.MapIntDouble), (1, str), ("sed", conv.MapIntDouble), ("n", str)))
    _reprocess_reprocess_2_argtypes = frozenset(((0, conv.MapStrDouble), (1, str), ("ssed", conv.MapStrDouble), ("n", str)))
    
    def __init__(self, *args, **kwargs):
        """"""
        types = set([(i, type(a)) for i, a in enumerate(args)])
        types.update([(k, type(v)) for k, v in kwargs.iteritems()])
        # vtable-like dispatch for exactly matching types
        if types <= self._reprocess_reprocess_0_argtypes:
            self._reprocess_reprocess_0(*args, **kwargs)
            return
        if types <= self._reprocess_reprocess_1_argtypes:
            self._reprocess_reprocess_1(*args, **kwargs)
            return
        if types <= self._reprocess_reprocess_2_argtypes:
            self._reprocess_reprocess_2(*args, **kwargs)
            return
        # duck-typed dispatch based on whatever works!
        try:
            self._reprocess_reprocess_0(*args, **kwargs)
            return
        except (RuntimeError, TypeError, NameError):
            pass
        try:
            self._reprocess_reprocess_1(*args, **kwargs)
            return
        except (RuntimeError, TypeError, NameError):
            pass
        try:
            self._reprocess_reprocess_2(*args, **kwargs)
            return
        except (RuntimeError, TypeError, NameError):
            pass
        raise RuntimeError('method __init__() could not be dispatched')
    
    

    # attributes
    property sepeff:
        """no docstring for sepeff, please file a bug report!"""
        def __get__(self):
            cdef conv._MapIntDouble sepeff_proxy
            if self._sepeff is None:
                sepeff_proxy = conv.MapIntDouble(False, False)
                sepeff_proxy.map_ptr = &(<cpp_reprocess.Reprocess *> self._inst).sepeff
                self._sepeff = sepeff_proxy
            return self._sepeff
    
        def __set__(self, value):
            cdef conv._MapIntDouble value_proxy
            value_proxy = conv.MapIntDouble(value, not isinstance(value, conv._MapIntDouble))
            (<cpp_reprocess.Reprocess *> self._inst).sepeff = value_proxy.map_ptr[0]
    
    
    # methods
    def _reprocess_calc_0(self):
        """calc(input=None)
        This method performs the relatively simply task of multiplying the current 
        input stream by the SE to form a new output stream::
        
            incomp  = self.mat_feed.mult_by_mass()
            outcomp = {}
            for iso in incomp.keys():
                outcomp[iso] = incomp[iso] * sepeff[iso]
            self.mat_prod = Material(outcomp)
            return self.mat_prod
        
        Parameters
        ----------
        input : dict or Material or None, optional 
            If input is present, it set as the component's mat_feed.  If input is a 
            isotopic dictionary (zzaaam keys, float values), this dictionary is first 
            converted into a Material before being set as mat_feed.
        
        Returns
        -------
        output : Material
            mat_prod
        
        """
        cdef cpp_material.Material rtnval
        cdef material._Material rtnval_proxy
        rtnval = (<cpp_fccomp.FCComp *> self._inst).calc()
        rtnval_proxy = material.Material()
        rtnval_proxy.mat_pointer = &rtnval
        return rtnval_proxy
    
    
    def _reprocess_calc_1(self, incomp):
        """calc(input=None)
        This method performs the relatively simply task of multiplying the current 
        input stream by the SE to form a new output stream::
        
            incomp  = self.mat_feed.mult_by_mass()
            outcomp = {}
            for iso in incomp.keys():
                outcomp[iso] = incomp[iso] * sepeff[iso]
            self.mat_prod = Material(outcomp)
            return self.mat_prod
        
        Parameters
        ----------
        input : dict or Material or None, optional 
            If input is present, it set as the component's mat_feed.  If input is a 
            isotopic dictionary (zzaaam keys, float values), this dictionary is first 
            converted into a Material before being set as mat_feed.
        
        Returns
        -------
        output : Material
            mat_prod
        
        """
        cdef conv._MapIntDouble incomp_proxy
        cdef cpp_material.Material rtnval
        cdef material._Material rtnval_proxy
        incomp_proxy = conv.MapIntDouble(incomp, not isinstance(incomp, conv._MapIntDouble))
        rtnval = (<cpp_reprocess.Reprocess *> self._inst).calc(incomp_proxy.map_ptr[0])
        rtnval_proxy = material.Material()
        rtnval_proxy.mat_pointer = &rtnval
        return rtnval_proxy
    
    
    def _reprocess_calc_2(self, instream):
        """calc(input=None)
        This method performs the relatively simply task of multiplying the current 
        input stream by the SE to form a new output stream::
        
            incomp  = self.mat_feed.mult_by_mass()
            outcomp = {}
            for iso in incomp.keys():
                outcomp[iso] = incomp[iso] * sepeff[iso]
            self.mat_prod = Material(outcomp)
            return self.mat_prod
        
        Parameters
        ----------
        input : dict or Material or None, optional 
            If input is present, it set as the component's mat_feed.  If input is a 
            isotopic dictionary (zzaaam keys, float values), this dictionary is first 
            converted into a Material before being set as mat_feed.
        
        Returns
        -------
        output : Material
            mat_prod
        
        """
        cdef material._Material instream_proxy
        cdef cpp_material.Material rtnval
        cdef material._Material rtnval_proxy
        instream_proxy = material.Material(instream, not isinstance(instream, material._Material))
        rtnval = (<cpp_reprocess.Reprocess *> self._inst).calc(instream_proxy.mat_pointer[0])
        rtnval_proxy = material.Material()
        rtnval_proxy.mat_pointer = &rtnval
        return rtnval_proxy
    
    
    _reprocess_calc_0_argtypes = frozenset()
    _reprocess_calc_1_argtypes = frozenset(((0, conv.MapIntDouble), ("incomp", conv.MapIntDouble)))
    _reprocess_calc_2_argtypes = frozenset(((0, material.Material), ("instream", material.Material)))
    
    def calc(self, *args, **kwargs):
        """calc(input=None)
        This method performs the relatively simply task of multiplying the current 
        input stream by the SE to form a new output stream::
        
            incomp  = self.mat_feed.mult_by_mass()
            outcomp = {}
            for iso in incomp.keys():
                outcomp[iso] = incomp[iso] * sepeff[iso]
            self.mat_prod = Material(outcomp)
            return self.mat_prod
        
        Parameters
        ----------
        input : dict or Material or None, optional 
            If input is present, it set as the component's mat_feed.  If input is a 
            isotopic dictionary (zzaaam keys, float values), this dictionary is first 
            converted into a Material before being set as mat_feed.
        
        Returns
        -------
        output : Material
            mat_prod
        
        """
        types = set([(i, type(a)) for i, a in enumerate(args)])
        types.update([(k, type(v)) for k, v in kwargs.iteritems()])
        # vtable-like dispatch for exactly matching types
        if types <= self._reprocess_calc_0_argtypes:
            return self._reprocess_calc_0(*args, **kwargs)
        if types <= self._reprocess_calc_1_argtypes:
            return self._reprocess_calc_1(*args, **kwargs)
        if types <= self._reprocess_calc_2_argtypes:
            return self._reprocess_calc_2(*args, **kwargs)
        # duck-typed dispatch based on whatever works!
        try:
            return self._reprocess_calc_0(*args, **kwargs)
        except (RuntimeError, TypeError, NameError):
            pass
        try:
            return self._reprocess_calc_1(*args, **kwargs)
        except (RuntimeError, TypeError, NameError):
            pass
        try:
            return self._reprocess_calc_2(*args, **kwargs)
        except (RuntimeError, TypeError, NameError):
            pass
        raise RuntimeError('method calc() could not be dispatched')
    
    
    def calc_params(self):
        """calc_params()
        Here the parameters for Reprocess are set.  For reprocessing, this amounts 
        to just a "Mass" parameter::
        
            self.params_prior_calc["Mass"] = self.mat_feed.mass
            self.params_after_calc["Mass"] = self.mat_prod.mass
        
        """
        (<cpp_fccomp.FCComp *> self._inst).calc_params()
    
    
    def initialize(self, sed):
        """initialize(sepeff)
        The initialize() function calculates the sepeff from an integer-keyed 
        dictionary of separation efficiencies.  The difference is that sepdict 
        may contain either elemental or isotopic keys and need not contain every 
        isotope tracked.  On the other hand, sepeff must have only zzaaam keys 
        that match exactly the isotopes in bright.track_nucs.
        
        Parameters
        ----------
        sepeff : dict or other mappping
            Integer valued dictionary of SE to be converted to sepeff.
                
        """
        cdef conv._MapIntDouble sed_proxy
        sed_proxy = conv.MapIntDouble(sed, not isinstance(sed, conv._MapIntDouble))
        (<cpp_reprocess.Reprocess *> self._inst).initialize(sed_proxy.map_ptr[0])
    
    
