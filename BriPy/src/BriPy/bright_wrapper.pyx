"""Python wrapper for isoname library."""
# Cython imports
from libcpp.map cimport map as cpp_map
from libcpp.set cimport set as cpp_set
from cython cimport pointer
from cython.operator cimport dereference as deref
from cython.operator cimport preincrement as inc

# local imports 
cimport std

import isoname

cimport cpp_mass_stream
cimport cpp_bright
cimport stlconverters as conv

#from MassStream import MassStream
#cimport MassStream
#import MassStream

cimport mass_stream
import mass_stream

import os

#######################################
### FCComps Configuration namespace ###
#######################################

cdef class BrightConfig:

    property isos2track:
        def __get__(self):
            return conv.cpp_to_py_set_int(cpp_bright.isos2track)

        def __set__(self, value):
            s = set([isoname.mixed_2_zzaaam(v) for v in value])
            cpp_bright.isos2track = conv.py_to_cpp_set_int(s)


    property verbosity:
        def __get__(self):
            return cpp_bright.verbosity

        def __set__(self, int value):
            cpp_bright.verbosity = value


    property write_hdf5:
        def __get__(self):
            return cpp_bright.write_hdf5

        def __set__(self, bint value):
            cpp_bright.write_hdf5 = value


    property write_text:
        def __get__(self):
            return cpp_bright.write_text

        def __set__(self, bint value):
            cpp_bright.write_text = value


    property output_filename:
        def __get__(self):
            cdef std.string value = cpp_bright.output_filename
            return value.c_str()

        def __set__(self, char * value):
            cpp_bright.output_filename = std.string(value)


# Make a singleton of the Bright config object
bright_config = BrightConfig()


# Load isos2track from file functions
def load_isos2track_hdf5(char * filename, char * datasetname="", bint clear=False):
    """This convience function tries to load the isos2track set from a dataset 
    in an HDF5 file.  The dataset *must* be of integer type.  String-based
    nuclide names are currently not supported. 

    Args:
        * filename (str): Path to the data library.
        * dataset (str):  Dataset name to grab nuclides from.
        * clear (bool):   Flag that if set removes the currrent entries
          from isos2track prior to loading in new values.

    If the dataset argument is not provided or empty, the function tries to 
    load from various default datasets in the following order::

        "/isos2track"  
        "/Isos2Track"
        "/isostrack"   
        "/IsosTrack"
        "/isotrack"   
        "/IsoTrack"    
        "/ToIso"
        "/ToIsos"
        "/ToIso_zz"
        "/ToIso_MCNP"
        "/FromIso"  
        "/FromIsos"  
        "/FromIso_zz" 
        "/FromIso_MCNP"
    """
    cpp_bright.load_isos2track_hdf5(std.string(filename), std.string(datasetname), clear)


def load_isos2track_text(char * filename, bint clear=False):
    """This convience function tries to load the isos2track set from a text
    file.  The nuclide names may use any naming convention.  Mixing different
    conventions in the same file is allowed.  Whitespace is required between
    isotopic names.

    Args:
        * filename (str): Path to the data library.
        * clear (bool):   Flag that if set removes the currrent entries
          from isos2track prior to loading in new values.
    """
    cpp_bright.load_isos2track_text(std.string(filename), clear)



####################
### FCComp Class ###
####################

cdef class FCComp:
    """Base Fuel Cycle Component Class.

    Args:
        * paramlist (sequence of str): A set of parameter names (str) that the component will track.
        * name (str): The name of the fuel cycle component instance.

    Note that this automatically calls the protected :meth:`initialize` C function.
    """

    cdef cpp_bright.FCComp * fccomp_pointer

    def __cinit__(self, params=None, char * name="", *args, **kwargs):
#    def __init__(self, params=None, char * name="", *args, **kwargs):
        cdef cpp_set[std.string] param_set

        if params is None:
            self.fccomp_pointer = new cpp_bright.FCComp(std.string(name))
        else:
            param_set = conv.py_to_cpp_set_str(params)
            self.fccomp_pointer = new cpp_bright.FCComp(param_set, std.string(name))


    def __dealloc__(self):
        del self.fccomp_pointer


    #
    # Class Attributes
    #

    property name:
        def __get__(self):
            cdef std.string n = self.fccomp_pointer.name
            return n.c_str()

        def __set__(self, char * n):
            self.fccomp_pointer.name = std.string(n)


    property natural_name:
        def __get__(self):
            cdef std.string n = self.fccomp_pointer.natural_name
            return n.c_str()

        def __set__(self, char * n):
            self.fccomp_pointer.natural_name = std.string(n)


    property IsosIn:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.fccomp_pointer.IsosIn
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.fccomp_pointer.IsosIn = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property IsosOut:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.fccomp_pointer.IsosOut
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.fccomp_pointer.IsosOut = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property ParamsIn:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.fccomp_pointer.ParamsIn)

        def __set__(self, dict pi):
            self.fccomp_pointer.ParamsIn = conv.dict_to_map_str_dbl(pi)


    property ParamsOut:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.fccomp_pointer.ParamsOut)

        def __set__(self, dict po):
            self.fccomp_pointer.ParamsOut = conv.dict_to_map_str_dbl(po)


    property PassNum:
        def __get__(self):
            return self.fccomp_pointer.PassNum

        def __set__(self, int pn):
            self.fccomp_pointer.PassNum = pn


    property params2track:
        def __get__(self):
            return conv.cpp_to_py_set_str(self.fccomp_pointer.params2track)

        def __set__(self, set p2t):
            self.fccomp_pointer.params2track = conv.py_to_cpp_set_str(p2t)

    #
    # Class Methods
    #

    def writeIsoPass(self):
        """This method is responsible for adding a new pass to the output text file 
        "{FCComp.name}Isos.txt" for this component.  Further calculations should
        not be performed after :meth:`writeIsoPass` has been called.

        This function has one very important subtlety: it does not write out mass streams data.
        Rather, input columns are given as normalized isotopic vectors.
        As weight fractions, input columns are in units of [kgInIso/kgIsosIn.mass].
        Moreover, the output columns are given in terms relative to the mass of the input mass, 
        [kgOutIso/kgIsosIn.mass].  These are calculated via the following expressions.

        .. math::

            \mbox{inpcol[iso]} = \mbox{IsosIn.comp[iso]}

            \mbox{outcol[iso]} = \mbox{IsosOut.comp[iso]} \times \frac{\mbox{IsosOut.mass}}{\mbox{IsosIn.mass}}

        Because of the units of these two columns, total mass flow data may often only be recovered via the 
        a "Mass" parameter in the "{FCComp.name}Params.txt" file.  Here is a sample LWRIsos.txt file for a
        light water reactor for the first pass::

            Isotope 1in             1out    
            H1      0.000000E+00    0.000000E+00
            H3      0.000000E+00    8.568522E-08
            HE4     0.000000E+00    4.421615E-07
            B10     0.000000E+00    0.000000E+00
            B11     0.000000E+00    0.000000E+00
            C14     0.000000E+00    4.015091E-11
            O16     0.000000E+00    0.000000E+00
            SR90    0.000000E+00    8.221283E-04
            TC99    0.000000E+00    1.112580E-03
            CS137   0.000000E+00    1.821226E-03
            U234    0.000000E+00    2.807466E-06
            U235    4.773292E-02    8.951725E-03
            U236    0.000000E+00    6.155297E-03
            U237    0.000000E+00    1.719458E-05
            U238    9.522671E-01    9.211956E-01
            U239    0.000000E+00    6.953862E-07
            NP237   0.000000E+00    8.057270E-04
            PU238   0.000000E+00    2.842232E-04
            PU239   0.000000E+00    5.353362E-03
            PU240   0.000000E+00    2.114728E-03

        """
        self.fccomp_pointer.writeIsoPass()


    def writeParamPass(self):
        """What writeIsoPass() does for a component's input and output isotopics, 
        this function does for the components parameters.  To ensure that meaningful 
        data is available, writeParamPass() first must have setParams()
        called elsewhere in the program.  Note that to get the pass numbering correct, 
        PassNum should always be incremented prior to this method.  The 
        following is an example of "{FCComp.name}Params.txt" for a light water 
        reactor spent fuel reprocessing facility::

            Param   1in             1out    
            Mass    9.985828E-01    9.975915E-01

        """
        self.fccomp_pointer.writeParamPass()
        

    def writeText(self):
        """This method calls writeIsoPass() and then, if available, calls 
        writeParamPass().  This is convience function for producing 
        text-based output.  However, using writeout() is recommended.
        """
        self.fccomp_pointer.writeText()


    def writeHDF5(self):
        """This method writes out the isotopic pass data to an HDF5 file. 
        Then, if available, it also writes parameter data as well.  
        Using writeout() instead is recommended.
        """
        self.fccomp_pointer.writeHDF5()


    def writeout(self):
        """This is a convenience function that first increments up PassNum.
        Then, it checks to see if there are any parameters for this component.
        If there are, it sets the current values using :meth:`setParams`.

        If BriPy.write_hdf5 is set, then writeHDF5() is called.

        If BriPy.write_text is set, then writeText() is called.

        This is what is most often used to write Bright output.  Therefore it is
        seen as the last step for every component in each pass.
        """
        self.fccomp_pointer.writeout()


    # Virtual methods

    def setParams(self):
        """By calling this method, all parameter values are calculated and set for the fuel cycle component.
        This should be done following a doCalc() calculation but before data is written out.
        If a component has important parameters associated with it, this function must be overridden and called.

        Note that this is called first thing when writeParamPass() is called.  For example, reprocessing only 
        has a "Mass" parameter.  Translated into Python, setParams() here looks like the following::

            def setParams(self):
                self.ParamsIn["Mass"]  = self.IsosIn.mass
                self.ParamsOut["Mass"] = self.IsosOut.mass
                return
        """
        self.fccomp_pointer.setParams()


    def doCalc(self):
        """This method is used to determine a component's output isotopics from its input isotopics.
        Therefore, this is typically where the bulk of a fuel cycle component's algorithm lies.
        As each component type has a distinct methodology, the doCalc() method  needs 
        to be overridden child classes.

        This method should return IsosOut so that component calculations may be easily 
        daisy-chained together.

        Args:
            * input (dict or MassStream): If input is present, it set as the component's 
              IsosIn.  If input is a isotopic dictionary (zzaaam keys, float values), this
              dictionary is first converted into a MassStream before being set as IsosIn.

        Returns:
            * output (MassStream): IsosOut.

        """
        cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
        py_ms.ms_pointer[0] = self.fccomp_pointer.doCalc()
        return py_ms



########################
### Enrichment Class ###
########################


cdef class EnrichmentParameters:
    """This class is a collection of values that mirror the attributes in 
    Enrichment that are required for the cascade model to run.
    In C-code this a simple `struct.  Like ReactorParameters, this class 
    takes no arguments on initialization.  An empty ErichmentParameters
    instance has all values (weakly) set to zero.
    """

    cdef cpp_bright.EnrichmentParameters ep

    def __cinit__(self):
        self.ep = cpp_bright.EnrichmentParameters()


    #
    # Class Attributes
    #

    property alpha_0:
        def __get__(self):
            return self.ep.alpha_0

        def __set__(self, value):
            self.ep.alpha_0 = <double> value


    property Mstar_0:
        def __get__(self):
            return self.ep.Mstar_0

        def __set__(self, value):
            self.ep.Mstar_0 = <double> value


    property j:
        def __get__(self):
            return self.ep.j

        def __set__(self, value):
            self.ep.j = <int> value


    property k:
        def __get__(self):
            return self.ep.k

        def __set__(self, value):
            self.ep.k = <int> value


    property N0:
        def __get__(self):
            return self.ep.N0

        def __set__(self, value):
            self.ep.N0 = <double> value


    property M0:
        def __get__(self):
            return self.ep.M0

        def __set__(self, value):
            self.ep.M0 = <double> value


    property xP_j:
        def __get__(self):
            return self.ep.xP_j

        def __set__(self, value):
            self.ep.xP_j = <double> value


    property xW_j:
        def __get__(self):
            return self.ep.xW_j

        def __set__(self, value):
            self.ep.xW_j = <double> value



def UraniumEnrichmentDefaults():
    cdef cpp_bright.EnrichmentParameters cpp_ued = cpp_bright.fillUraniumEnrichmentDefaults()
    cdef EnrichmentParameters ued = EnrichmentParameters()
    ued.ep = cpp_ued
    return ued



cdef class Enrichment(FCComp):
    """Enrichment Fuel Cycle Component Class.  Daughter of BriPy.FCComp class.

    Args:
        * enrich_params (EnrichmentParameters): This specifies how the enrichment 
          cascade should be set up.  It is a EnrichmentParameters
          helper object.  If enrich_params is not specified, then the cascade 
          is initialized with UraniumEnrichmentDefaults.
        * name (str): The name of the enrichment fuel cycle component instance.

    Note that this automatically calls the public initialize() C function.
    """

    cdef cpp_bright.Enrichment * e_pointer

    def __cinit__(self, enrich_params=None, char * name="", *args, **kwargs):
        cdef EnrichmentParameters enr_par

        if enrich_params is None:
            self.e_pointer = new cpp_bright.Enrichment(std.string(name))
        elif isinstance(enrich_params, EnrichmentParameters):
            enr_par = enrich_params
            self.e_pointer = new cpp_bright.Enrichment(<cpp_bright.EnrichmentParameters> enr_par.ep, std.string(name))

        # Set the base class pointer to this new instance 
        #so that inheritied attributes are picked up
#        self.fccomp_pointer[0] = self.e_pointer[0]
        #self.fccomp_pointer[0] = deref(self.e_pointer)

    def __dealloc__(self):
        del self.e_pointer


    #
    # Class Attributes
    #

    # Enrichment Attributes

    property alpha_0:
        def __get__(self):
            return self.e_pointer.alpha_0

        def __set__(self, value):
            self.e_pointer.alpha_0 = <double> value


    property Mstar_0:
        def __get__(self):
            return self.e_pointer.Mstar_0

        def __set__(self, value):
            self.e_pointer.Mstar_0 = <double> value


    property Mstar:
        def __get__(self):
            return self.e_pointer.Mstar

        def __set__(self, value):
            self.e_pointer.Mstar = <double> value


    property IsosTail:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.e_pointer.IsosTail
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.e_pointer.IsosTail = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property j:
        def __get__(self):
            return self.e_pointer.j

        def __set__(self, value):
            self.e_pointer.j = <int> value


    property k:
        def __get__(self):
            return self.e_pointer.k

        def __set__(self, value):
            self.e_pointer.k = <int> value


    property xP_j:
        def __get__(self):
            return self.e_pointer.xP_j

        def __set__(self, value):
            self.e_pointer.xP_j = <double> value


    property xW_j:
        def __get__(self):
            return self.e_pointer.xW_j

        def __set__(self, value):
            self.e_pointer.xW_j = <double> value


    property N:
        def __get__(self):
            return self.e_pointer.N

        def __set__(self, value):
            self.e_pointer.N = <double> value


    property M:
        def __get__(self):
            return self.e_pointer.M

        def __set__(self, value):
            self.e_pointer.M = <double> value


    property N0:
        def __get__(self):
            return self.e_pointer.N0

        def __set__(self, value):
            self.e_pointer.N0 = <double> value


    property M0:
        def __get__(self):
            return self.e_pointer.M0

        def __set__(self, value):
            self.e_pointer.M0 = <double> value


    property TotalPerFeed:
        def __get__(self):
            return self.e_pointer.TotalPerFeed

        def __set__(self, value):
            self.e_pointer.TotalPerFeed = <double> value


    property SWUperFeed:
        def __get__(self):
            return self.e_pointer.SWUperFeed

        def __set__(self, value):
            self.e_pointer.SWUperFeed = <double> value


    property SWUperProduct:
        def __get__(self):
            return self.e_pointer.SWUperProduct

        def __set__(self, value):
            self.e_pointer.SWUperProduct = <double> value


    # FCComps inherited attributes

    property name:
        def __get__(self):
            cdef std.string n = self.e_pointer.name
            return n.c_str()

        def __set__(self, char * n):
            self.e_pointer.name = std.string(n)


    property natural_name:
        def __get__(self):
            cdef std.string n = self.e_pointer.natural_name
            return n.c_str()

        def __set__(self, char * n):
            self.e_pointer.natural_name = std.string(n)


    property IsosIn:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.e_pointer.IsosIn
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.e_pointer.IsosIn = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property IsosOut:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.e_pointer.IsosOut
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.e_pointer.IsosOut = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property ParamsIn:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.e_pointer.ParamsIn)

        def __set__(self, dict pi):
            self.e_pointer.ParamsIn = conv.dict_to_map_str_dbl(pi)


    property ParamsOut:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.e_pointer.ParamsOut)

        def __set__(self, dict po):
            self.e_pointer.ParamsOut = conv.dict_to_map_str_dbl(po)


    property PassNum:
        def __get__(self):
            return self.e_pointer.PassNum

        def __set__(self, int pn):
            self.e_pointer.PassNum = pn


    property params2track:
        def __get__(self):
            return conv.cpp_to_py_set_str(self.e_pointer.params2track)

        def __set__(self, set p2t):
            self.e_pointer.params2track = conv.py_to_cpp_set_str(p2t)



    #
    # Class Methods
    # 

    def initialize(self, EnrichmentParameters enrich_params):
        """The initialize function takes an enrichment parameter object and sets
        the corresponding Enrichment attributes to the same value.

        Args:
            * enrich_params (EnrichmentParameters): A class containing the values to
              (re-)initialize an Enrichment cascade with.
        """
        self.e_pointer.initialize(<cpp_bright.EnrichmentParameters> enrich_params.ep)


    def setParams(self):
        """Here the parameters for Enrichment are set::

            self.ParamsIn["MassFeed"]  = self.IsosIn.mass
            self.ParamsOut["MassFeed"] = 0.0

            self.ParamsIn["MassProduct"]  = 0.0
            self.ParamsOut["MassProduct"] = self.IsosOut.mass

            self.ParamsIn["MassTails"]  = 0.0
            self.ParamsOut["MassTails"] = self.IsosTail.mass

            self.ParamsIn["N"]  = self.N
            self.ParamsOut["N"] = self.N

            self.ParamsIn["M"]  = self.M
            self.ParamsOut["M"] = self.M

            self.ParamsIn["Mstar"]  = self.Mstar
            self.ParamsOut["Mstar"] = self.Mstar

            self.ParamsIn["TotalPerFeed"]  = self.TotalPerFeed
            self.ParamsOut["TotalPerFeed"] = self.TotalPerFeed

            self.ParamsIn["SWUperFeed"]  = self.SWUperFeed
            self.ParamsOut["SWUperFeed"] = 0.0

            self.ParamsIn["SWUperProduct"]  = 0.0
            self.ParamsOut["SWUperProduct"] = self.SWUperProduct

        """
        (<cpp_bright.FCComp *> self.e_pointer).setParams()


    def doCalc(self, input=None):
        """This method performs an optimization calculation on M* and solves for 
        appropriate values for all Enrichment attributes.  This includes the 
        product and waste streams flowing out of the the cascade as well.

        Args:
            * input (dict or MassStream or None): If input is present, it is set as the component's 
            IsosIn.  If input is a isotopic dictionary (zzaaam keys, float values), this dictionary 
            is first converted into a MassStream before being set as IsosIn.

        Returns:
            * output (MassStream): IsosOut.

        """
        cdef mass_stream.MassStream in_ms 
        cdef mass_stream.MassStream output = mass_stream.MassStream()

        if input is None:
            output.ms_pointer[0] = (<cpp_bright.FCComp *> self.e_pointer).doCalc()
        elif isinstance(input, dict):
            output.ms_pointer[0] = self.e_pointer.doCalc(conv.dict_to_map_int_dbl(input))
        elif isinstance(input, mass_stream.MassStream):
            in_ms = input
            output.ms_pointer[0] = self.e_pointer.doCalc(<cpp_mass_stream.MassStream> in_ms.ms_pointer[0])

        return output


    def PoverF(self, double x_F, double x_P, double x_W):
        """Solves for the product over feed enrichment ratio.

        .. math::

            \\frac{p}{f} = \\frac{(x_F - x_W)}{(x_P - x_W)}

        Args:
            * x_F (float): Feed enrichment.
            * x_P (float): Product enrichment.
            * x_W (float): Waste enrichment.

        Returns:
            * pfratio (float): As calculated above.
        """
        return self.e_pointer.PoverF(x_F, x_P, x_W)


    def WoverF(self, double x_F, double x_P, double x_W):
        """Solves for the waste over feed enrichment ratio.

        .. math::

            \\frac{p}{f} = \\frac{(x_F - x_P)}{(x_W - x_P)}

        Args:
            * x_F (float): Feed enrichment.
            * x_P (float): Product enrichment.
            * x_W (float): Waste enrichment.

        Returns:
            * wfratio (float): As calculated above.
        """
        return self.e_pointer.WoverF(x_F, x_P, x_W)


cdef class Reprocess(FCComp):
    """Reprocess Fuel Cycle Component Class.  Daughter of BriPy.FCComp class.

    Args:
        * sepeff (dict): A dictionary containing the separation efficiencies (float) to initialize
          the instance with.  The keys of this dictionary must be strings.  However, the strings may 
          represent either elements or isotopes or both::

                #ssed = string dictionary of separation efficiencies.  
                #Of form {zz: 0.99}, eg 
                ssed = {"92": 0.999, "94": 0.99} 
                #of form {LL: 0.99}, eg 
                ssed = {"U": 0.999, "PU": 0.99} 
                #or of form {mixed: 0.99}, eg 
                ssed = {"U235": 0.9, "922350": 0.999, "94239": 0.99}

        * name (str): The name of the reprocessing fuel cycle component instance.

    Note that this automatically calls the public initialize C function.

    .. note::
       The C++ version of the code also allows you to initialize from an int-keyed dictionary (map).
       However, due to a from_python C++ signature ambiguity, you cannot do use this directly in Python.
       Separation efficiencies must therefore be automatically initialized through string dictionaries.
       If you need to initialize via an int dictionary in python, you can always init with an empty
       string dictionary and then manually initialize with an int one.  For example::

            R = Reprocess({}, name)
            R.initialize( {92: 0.99, 942390: 0.9} )

    """

    cdef cpp_bright.Reprocess * r_pointer

    def _cpp_sepeff(self, dict d):
        sepeff = {}

        for key, value in d.items():
            value = float(value) 

            if isinstance(key, int):
                sepeff[key] = value
            elif isinstance(key, basestring):
                if key in isoname.LLzz:
                    sepeff[isoname.LLzz[key]] = value
                else:
                    sepeff[isoname.mixed_2_zzaaam(key)] = value
            else:
                raise TypeError("Separation keys must be strings or integers.")

        return sepeff

    def __cinit__(self, dict sepeff={}, char * name="", *args, **kwargs):
        sepeff = self._cpp_sepeff(sepeff)
        self.r_pointer = new cpp_bright.Reprocess(conv.dict_to_map_int_dbl(sepeff), std.string(name))

    def __dealloc__(self):
        del self.r_pointer


    #
    # Class Attributes
    #

    property sepeff:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.r_pointer.sepeff)

        def __set__(self, dict value):
            value = self._cpp_sepeff(value)
            self.r_pointer.sepeff = conv.dict_to_map_int_dbl(value)


    # FCComps inherited attributes

    property name:
        def __get__(self):
            cdef std.string n = self.r_pointer.name
            return n.c_str()

        def __set__(self, char * n):
            self.r_pointer.name = std.string(n)


    property natural_name:
        def __get__(self):
            cdef std.string n = self.r_pointer.natural_name
            return n.c_str()

        def __set__(self, char * n):
            self.r_pointer.natural_name = std.string(n)


    property IsosIn:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.r_pointer.IsosIn
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.r_pointer.IsosIn = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property IsosOut:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.r_pointer.IsosOut
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.r_pointer.IsosOut = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property ParamsIn:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.r_pointer.ParamsIn)

        def __set__(self, dict pi):
            self.r_pointer.ParamsIn = conv.dict_to_map_str_dbl(pi)


    property ParamsOut:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.r_pointer.ParamsOut)

        def __set__(self, dict po):
            self.r_pointer.ParamsOut = conv.dict_to_map_str_dbl(po)


    property PassNum:
        def __get__(self):
            return self.r_pointer.PassNum

        def __set__(self, int pn):
            self.r_pointer.PassNum = pn


    property params2track:
        def __get__(self):
            return conv.cpp_to_py_set_str(self.r_pointer.params2track)

        def __set__(self, set p2t):
            self.r_pointer.params2track = conv.py_to_cpp_set_str(p2t)



    #
    # Class Methods
    # 

    def initialize(self, dict sepdict):
        """The initialize() function calculates the sepeff from an integer-keyed dictionary
        of separation efficiencies.  The difference is that sepdict may contain either elemental or
        isotopic keys and need not contain every isotope tracked.  On the other hand, sepeff
        must have only zzaaam keys that match exactly the isotopes in BriPy.isos2track.

        Args:
            * sepdict (dict): Integer valued dictionary of SE to be converted to sepeff.
        """
        sepdict = self._cpp_sepeff(sepdict)
        self.r_pointer.initialize(conv.dict_to_map_int_dbl(sepdict))


    def setParams(self):
        """Here the parameters for Reprocess are set.  For reprocessing, this amounts to just
        a "Mass" parameter::

            self.ParamsIn["Mass"]  = self.IsosIn.mass
            self.ParamsOut["Mass"] = self.IsosOut.mass

        """
        (<cpp_bright.FCComp *> self.r_pointer).setParams()


    def doCalc(self, input=None):
        """This method performs the relatively simply task of multiplying the current input stream by 
        the SE to form a new output stream::

            incomp  = self.IsosIn.multByMass()
            outcomp = {}
            for iso in incomp.keys():
                outcomp[iso] = incomp[iso] * sepeff[iso]
            self.IsosOut = MassStream(outcomp)
            return self.IsosOut

        Args:
            * input (dict or MassStream): If input is present, it set as the component's 
              IsosIn.  If input is a isotopic dictionary (zzaaam keys, float values), this
              dictionary is first converted into a MassStream before being set as IsosIn.

        Returns:
            * output (MassStream): IsosOut.
        """
        cdef mass_stream.MassStream in_ms 
        cdef mass_stream.MassStream output = mass_stream.MassStream()

        if input is None:
            output.ms_pointer[0] = (<cpp_bright.FCComp *> self.r_pointer).doCalc()
        elif isinstance(input, dict):
            output.ms_pointer[0] = self.r_pointer.doCalc(conv.dict_to_map_int_dbl(input))
        elif isinstance(input, mass_stream.MassStream):
            in_ms = input
            output.ms_pointer[0] = self.r_pointer.doCalc(<cpp_mass_stream.MassStream> in_ms.ms_pointer[0])

        return output
