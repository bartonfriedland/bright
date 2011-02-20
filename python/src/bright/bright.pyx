"""Python wrapper for isoname library."""
# Cython imports
from libcpp.map cimport map as cpp_map
from libcpp.set cimport set as cpp_set
from cython cimport pointer
from cython.operator cimport dereference as deref
from cython.operator cimport preincrement as inc
from libc.stdlib cimport free

cimport numpy as np
import numpy as np

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

import bright_data

######################################
### bright Configuration namespace ###
######################################

# Specifiy the BRIGHT_DATA directory
cpdef PyBrightStart():
    if "BRIGHT_DATA" not in os.environ:
        bd = os.path.split(bright_data.__file__)
        os.environ['BRIGHT_DATA'] = os.path.join(*(bd[0], ''))


# Expose the C-code start up routine
def BrightStart():
    cpp_bright.BrightStart()


# Run the appropriate start-up routines
PyBrightStart()
BrightStart()


#######################################
### FCComps Configuration namespace ###
#######################################

cdef class BrightConfig:

    # From bright namespace

    property BRIGHT_DATA:
        def __get__(self):
            cdef std.string value = cpp_bright.BRIGHT_DATA
            return value.c_str()

        def __set__(self, char * value):
            cpp_bright.BRIGHT_DATA = std.string(value)
        

    # From FCComps namespace

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

    #cdef cpp_bright.FCComp * fccomp_pointer

    def __cinit__(self, params=None, char * name="", *args, **kwargs):
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

        If bright.write_hdf5 is set, then writeHDF5() is called.

        If bright.write_text is set, then writeText() is called.

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

    #cdef cpp_bright.EnrichmentParameters * ep_pointer

    def __cinit__(self):
        self.ep_pointer = new cpp_bright.EnrichmentParameters()

    def __dealloc__(self):
        del self.ep_pointer


    #
    # Class Attributes
    #

    property alpha_0:
        def __get__(self):
            return self.ep_pointer.alpha_0

        def __set__(self, value):
            self.ep_pointer.alpha_0 = <double> value


    property Mstar_0:
        def __get__(self):
            return self.ep_pointer.Mstar_0

        def __set__(self, value):
            self.ep_pointer.Mstar_0 = <double> value


    property j:
        def __get__(self):
            return self.ep_pointer.j

        def __set__(self, value):
            self.ep_pointer.j = <int> value


    property k:
        def __get__(self):
            return self.ep_pointer.k

        def __set__(self, value):
            self.ep_pointer.k = <int> value


    property N0:
        def __get__(self):
            return self.ep_pointer.N0

        def __set__(self, value):
            self.ep_pointer.N0 = <double> value


    property M0:
        def __get__(self):
            return self.ep_pointer.M0

        def __set__(self, value):
            self.ep_pointer.M0 = <double> value


    property xP_j:
        def __get__(self):
            return self.ep_pointer.xP_j

        def __set__(self, value):
            self.ep_pointer.xP_j = <double> value


    property xW_j:
        def __get__(self):
            return self.ep_pointer.xW_j

        def __set__(self, value):
            self.ep_pointer.xW_j = <double> value



def UraniumEnrichmentDefaults():
    cdef cpp_bright.EnrichmentParameters cpp_ued = cpp_bright.fillUraniumEnrichmentDefaults()
    cdef EnrichmentParameters ued = EnrichmentParameters()
    ued.ep_pointer[0] = cpp_ued
    return ued



cdef class Enrichment(FCComp):
    """Enrichment Fuel Cycle Component Class.  Daughter of bright.FCComp class.

    Args:
        * enrich_params (EnrichmentParameters): This specifies how the enrichment 
          cascade should be set up.  It is a EnrichmentParameters
          helper object.  If enrich_params is not specified, then the cascade 
          is initialized with UraniumEnrichmentDefaults.
        * name (str): The name of the enrichment fuel cycle component instance.

    Note that this automatically calls the public initialize() C function.
    """

    #cdef cpp_bright.Enrichment * e_pointer

    def __cinit__(self, enrich_params=None, char * name=""):
        cdef EnrichmentParameters enr_par

        if enrich_params is None:
            self.e_pointer = new cpp_bright.Enrichment(std.string(name))
        elif isinstance(enrich_params, EnrichmentParameters):
            enr_par = enrich_params
            self.e_pointer = new cpp_bright.Enrichment(<cpp_bright.EnrichmentParameters> enr_par.ep_pointer[0], std.string(name))

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
        cdef EnrichmentParameters enr_par = enrich_params
        self.e_pointer.initialize(<cpp_bright.EnrichmentParameters> enr_par.ep_pointer[0])


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



#######################
### Reprocess Class ###
#######################


cdef class Reprocess(FCComp):
    """Reprocess Fuel Cycle Component Class.  Daughter of bright.FCComp class.

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

    #cdef cpp_bright.Reprocess * r_pointer

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

    def __cinit__(self, dict sepeff={}, char * name=""):
        sepeff = self._cpp_sepeff(sepeff)
        self.r_pointer = new cpp_bright.Reprocess(conv.dict_to_map_int_dbl(sepeff), std.string(name))

    def __dealloc__(self):
        del self.r_pointer


    #
    # Class Attributes
    #

    # Reprocess attributes

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
        must have only zzaaam keys that match exactly the isotopes in bright.isos2track.

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



#####################
### Storage Class ###
#####################


cdef class Storage(FCComp):
    """Storage Fuel Cycle Component Class.  Daughter of bright.FCComp class.

    Args:
        * name (str): The name of the storage fuel cycle component instance.
    """

    #cdef cpp_bright.Storage * s_pointer

    def __cinit__(self, char * name=""):
        self.s_pointer = new cpp_bright.Storage(std.string(name))

    def __dealloc__(self):
        del self.s_pointer


    #
    # Class Attributes
    #

    # Stroage attributes

    property decay_time:
        def __get__(self):
            return self.s_pointer.decay_time

        def __set__(self, value):
            self.s_pointer.decay_time = <double> value


    # FCComps inherited attributes

    property name:
        def __get__(self):
            cdef std.string n = self.s_pointer.name
            return n.c_str()

        def __set__(self, char * n):
            self.s_pointer.name = std.string(n)


    property natural_name:
        def __get__(self):
            cdef std.string n = self.s_pointer.natural_name
            return n.c_str()

        def __set__(self, char * n):
            self.s_pointer.natural_name = std.string(n)


    property IsosIn:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.s_pointer.IsosIn
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.s_pointer.IsosIn = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property IsosOut:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.s_pointer.IsosOut
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.s_pointer.IsosOut = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property ParamsIn:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.s_pointer.ParamsIn)

        def __set__(self, dict pi):
            self.s_pointer.ParamsIn = conv.dict_to_map_str_dbl(pi)


    property ParamsOut:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.s_pointer.ParamsOut)

        def __set__(self, dict po):
            self.s_pointer.ParamsOut = conv.dict_to_map_str_dbl(po)


    property PassNum:
        def __get__(self):
            return self.s_pointer.PassNum

        def __set__(self, int pn):
            self.s_pointer.PassNum = pn


    property params2track:
        def __get__(self):
            return conv.cpp_to_py_set_str(self.s_pointer.params2track)

        def __set__(self, set p2t):
            self.s_pointer.params2track = conv.py_to_cpp_set_str(p2t)


    #
    # Class Methods
    # 

    def setParams(self):
        """Here the parameters for Storage are set.  For storage, this amounts to just
        a "Mass" parameter::

            self.ParamsIn["Mass"]  = self.IsosIn.mass
            self.ParamsOut["Mass"] = self.IsosOut.mass
        """
        (<cpp_bright.FCComp *> self.s_pointer).setParams()


    def doCalc(self, input=None, decay_time=None):
        """As usual, doCalc sets up the Storage component's input stream and calculates the corresponding 
        output MassStream.  Here, this amounts to calling bateman() for every nuclide in 
        IsosIn, for each chain that ends with a nuclide in isos2track.

        This method is public and accessible from Python.

        Args:
            * input (dict or MassStream): If input is present, it set as the component's 
              IsosIn.  If input is a isotopic dictionary (zzaaam keys, float values), this
              dictionary is first converted into a MassStream before being set as IsosIn.
            * decay_time (float): decay_time is set to the time value here prior to any other calculations.  This
              time has units of seconds.

        Returns:
            * output (MassStream): IsosOut.
        """
        cdef mass_stream.MassStream in_ms 
        cdef mass_stream.MassStream output = mass_stream.MassStream()

        if decay_time is None:
            if input is None:
                output.ms_pointer[0] = (<cpp_bright.FCComp *> self.s_pointer).doCalc()
            elif isinstance(input, dict):
                output.ms_pointer[0] = self.s_pointer.doCalc(conv.dict_to_map_int_dbl(input))
            elif isinstance(input, mass_stream.MassStream):
                in_ms = input
                output.ms_pointer[0] = self.s_pointer.doCalc(<cpp_mass_stream.MassStream> in_ms.ms_pointer[0])
            else:
                raise TypeError("'input' must be a MassStream, dict, or None.")
        else:
            if input is None:
                output.ms_pointer[0] = self.s_pointer.doCalc(<double> decay_time)
            elif isinstance(input, dict):
                output.ms_pointer[0] = self.s_pointer.doCalc(conv.dict_to_map_int_dbl(input), <double> decay_time)
            elif isinstance(input, mass_stream.MassStream):
                in_ms = input
                output.ms_pointer[0] = self.s_pointer.doCalc(<cpp_mass_stream.MassStream> in_ms.ms_pointer[0], <double> decay_time)
            else:
                raise TypeError("'input' must be a MassStream, dict, or None.")

        return output



#######################
### Reactor1G Class ###
#######################


cdef class FluencePoint:
    """This class holds three simple data points that represent a fluence point.

    Attributes:
        * f (int): Index of Reactor1G.F immediately lower than the value of F (int).
        * F (float): Fluence value itself (float). In units of [n/kb] or [neutrons/kilobarn].
        * m (float): The slope dBU/dF between points f and f+1 (float). 
          Has the odd units of [MWd kb / kgIHM n].
    """

    #cdef cpp_bright.FluencePoint * fp_pointer

    def __cinit__(self):
        self.fp_pointer = new cpp_bright.FluencePoint()

    def __dealloc__(self):
        del self.fp_pointer


    #
    # Class Attributes
    #

    property f:
        def __get__(self):
            return self.fp_pointer.f

        def __set__(self, int value):
            self.fp_pointer.f = value


    property F:
        def __get__(self):
            return self.fp_pointer.F

        def __set__(self, double value):
            self.fp_pointer.F = value


    property m:
        def __get__(self):
            return self.fp_pointer.m

        def __set__(self, double value):
            self.fp_pointer.m = value



cdef class ReactorParameters:
    """This data structure is a set of physical reactor parameters. It may be used to instantiate new reactor objects **OR**
    to define default settings for a reactor type.  The data stored in this class is copied over to 
    a reactor instance in the :meth:`Reactor1G.initialize` method.  However, the attributes of this objects 
    take on more natural names than their :class:`Reactor1G` analogies.  This is because it is this 
    object that Bright users will more often be interacting with. 

    Attributes:
        * batches (int): This is the total number of batches in the fuel management scheme. 
          This is typically indexed by b.
        * flux (float): The nominal flux value that the library for this reactor 
          type was generated with.  Used to correctly weight batch-specific fluxes.
        * FuelForm (dict): This is the chemical form of fuel as dictionary.  Keys are 
          strings that represent isotopes (mixed form) while values represent the 
          corresponding mass weights.  The heavy metal concentration by the key "IHM".  
          This will automatically fill in the nuclides in IsosIn for the "IHM" weight.  
          For example, LWRs typically use a UOX fuel form::

            ReactorParameters.FuelForm = {"IHM": 1.0, "O16": 2.0}

        * CoolantForm (dict): This is the chemical form of coolant as dictionary.  
          This uses the same notation as FuelForm except that "IHM" is no longer 
          a valid key.  The term 'coolant' is used in preference over the term 
          'moderator' because not all reactors moderate neutrons.  For example, 
          LWRs often cool the reactor core with borated water::

            ReactorParamters.CoolantForm = {}

            ReactorParamters.CoolantForm["H1"]  = 2.0
            ReactorParamters.CoolantForm["O16"] = 1.0
            ReactorParamters.CoolantForm["B10"] = 0.199 * 550 * 10.0**-6
            ReactorParamters.CoolantForm["B11"] = 0.801 * 550 * 10.0**-6

        * FuelDensity (float): The fuel region density.  A float in units of [g/cm^3].
        * CoolantDensity (float): The coolant region density.  A float in units of [g/cm^3].
        * pnl (float): The reactor's non-leakage probability.  This is often 
          used as a calibration parameter.
        * BUt (float): The reactor's target discharge burnup.  This is given 
          in units of [MWd/kgIHM].  Often the actual discharge burnup BUd does not 
          quite hit this value, but comes acceptably close.
        * useDisadvantage (bool): Determines whether the thermal disadvantage 
          factor is employed or not.  LWRs typically set this as True while FRs 
          have a False value.
        * LatticeType (str): A flag that represents what lattice type the fuel 
          assemblies are arranged in.  Currently accepted values are "Planar", 
          "Spherical", and "Cylindrical".
        * HydrogenRescale (bool): This determines whether the reactor should 
          rescale the Hydrogen-1 destruction rate in the coolant as a
          function of fluence.  The scaling factor is calculated via the 
          following equation

            .. math:: f(F) = 1.36927 - 0.01119 \cdot BU(F)

          This is typically not done for fast reactors but is a useful correction 
          for LWRs.
        * Radius (float): The radius of the fuel region.  In units of [cm].
        * Length (float): The pitch or length of the unit fuel pin cell.  In units of [cm].
        * open_slots (float): The number of slots in a fuel assembly that are open.  
          Thus this is the number of slots that do not contain a fuel pin and are instead 
          filled in by coolant. 
        * total_slots (float): The total number of fuel pin slots in a fuel assembly.  
          For a 17x17 bundle, S_T is 289.0. 
    """

    #cdef cpp_bright.ReactorParameters * rp_pointer

    def __cinit__(self):
        self.rp_pointer = new cpp_bright.ReactorParameters()

    def __dealloc__(self):
        del self.rp_pointer


    #
    # Class Attributes
    #

    property batches:
        def __get__(self):
            return self.rp_pointer.batches

        def __set__(self, int value):
            self.rp_pointer.batches = value


    property flux:
        def __get__(self):
            return self.rp_pointer.flux

        def __set__(self, double value):
            self.rp_pointer.flux = value


    property FuelForm:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.rp_pointer.FuelForm)

        def __set__(self, dict value):
            self.rp_pointer.FuelForm = conv.dict_to_map_str_dbl(value)


    property CoolantForm:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.rp_pointer.CoolantForm)

        def __set__(self, dict value):
            self.rp_pointer.CoolantForm = conv.dict_to_map_str_dbl(value)


    property FuelDensity:
        def __get__(self):
            return self.rp_pointer.FuelDensity

        def __set__(self, double value):
            self.rp_pointer.FuelDensity = value


    property CoolantDensity:
        def __get__(self):
            return self.rp_pointer.CoolantDensity

        def __set__(self, double value):
            self.rp_pointer.CoolantDensity = value


    property pnl:
        def __get__(self):
            return self.rp_pointer.pnl

        def __set__(self, double value):
            self.rp_pointer.pnl = value


    property BUt:
        def __get__(self):
            return self.rp_pointer.BUt

        def __set__(self, double value):
            self.rp_pointer.BUt = value


    property useDisadvantage:
        def __get__(self):
            return self.rp_pointer.useDisadvantage

        def __set__(self, bint value):
            self.rp_pointer.useDisadvantage = value


    property LatticeType:
        def __get__(self):
            cdef std.string value = self.rp_pointer.LatticeType
            return value.c_str()

        def __set__(self, char * value):
            self.rp_pointer.LatticeType = std.string(value)


    property HydrogenRescale:
        def __get__(self):
            return self.rp_pointer.HydrogenRescale

        def __set__(self, bint value):
            self.rp_pointer.HydrogenRescale = value


    property Radius:
        def __get__(self):
            return self.rp_pointer.Radius

        def __set__(self, double value):
            self.rp_pointer.Radius = value


    property Length:
        def __get__(self):
            return self.rp_pointer.Length

        def __set__(self, double value):
            self.rp_pointer.Length = value


    property open_slots:
        def __get__(self):
            return self.rp_pointer.open_slots

        def __set__(self, double value):
            self.rp_pointer.open_slots = value


    property total_slots:
        def __get__(self):
            return self.rp_pointer.total_slots

        def __set__(self, double value):
            self.rp_pointer.total_slots = value




cdef class Reactor1G(FCComp):
    """One-Group Reactor Fuel Cycle Component Class.  Daughter of bright.FCComp class.

    Args:
        * reactor_parameters (ReactorParameters): A special data structure that contains information
          on how to setup and run the reactor.
        * params2track (string set): A set of strings that represents what parameter data the reactor should 
          store and set.  Different reactor types may have different characteristic parameters that are of interest.
        * name (str): The name of the reactor fuel cycle component instance.

    Note that this automatically calls the public initialize() C function.

    .. note:: 

        Some data members and functions have names that end in '_F_'.  This indicates that these are a 
        function of fluence, the time integral of the flux.  The '_Fd_' suffix implies that the data is 
        evaluated at the discharge fluence.
    """

    #cdef cpp_bright.Reactor1G * r1g_pointer

    def __cinit__(self, reactor_parameters=None, params2track=None, char * name="", *args, **kwargs):
        cdef ReactorParameters rp
        cdef std.string cpp_name = std.string(name)

        if (reactor_parameters is None) and (params2track is None):
            self.r1g_pointer = new cpp_bright.Reactor1G(cpp_name)

        elif (reactor_parameters is None) and isinstance(params2track, set):
            self.r1g_pointer = new cpp_bright.Reactor1G(conv.py_to_cpp_set_str(params2track), cpp_name)

        elif isinstance(reactor_parameters, ReactorParameters) and (params2track is None):
            rp = reactor_parameters
            self.r1g_pointer = new cpp_bright.Reactor1G(<cpp_bright.ReactorParameters> rp.rp_pointer[0], cpp_name)

        elif isinstance(reactor_parameters, ReactorParameters) and isinstance(params2track, set):
            rp = reactor_parameters
            self.r1g_pointer = new cpp_bright.Reactor1G(<cpp_bright.ReactorParameters> rp.rp_pointer[0], conv.py_to_cpp_set_str(params2track), cpp_name)

        else:
            if reactor_parameters is not None:
                raise TypeError("The reactor_parameters keyword must be an instance of the ReactorParameters class or None.  Got " + str(type(reactor_parameters)))

            if params2track is not None:
                raise TypeError("The params2track keyword must be a set of strings or None.  Got " + str(type(params2track)))

    def __dealloc__(self):
        del self.r1g_pointer


    #
    # Class Attributes
    #

    # Reactor1G attributes

    property B:
        def __get__(self):
            return self.r1g_pointer.B

        def __set__(self, int value):
            self.r1g_pointer.B = value


    property phi:
        def __get__(self):
            return self.r1g_pointer.phi

        def __set__(self, double value):
            self.r1g_pointer.phi = value


    property FuelChemicalForm:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.r1g_pointer.FuelChemicalForm)

        def __set__(self, dict value):
            self.r1g_pointer.FuelChemicalForm = conv.dict_to_map_str_dbl(value)


    property CoolantChemicalForm:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.r1g_pointer.CoolantChemicalForm)

        def __set__(self, dict value):
            self.r1g_pointer.CoolantChemicalForm = conv.dict_to_map_str_dbl(value)


    property rhoF:
        def __get__(self):
            return self.r1g_pointer.rhoF

        def __set__(self, double value):
            self.r1g_pointer.rhoF = value


    property rhoC:
        def __get__(self):
            return self.r1g_pointer.rhoC

        def __set__(self, double value):
            self.r1g_pointer.rhoC = value


    property P_NL:
        def __get__(self):
            return self.r1g_pointer.P_NL

        def __set__(self, double value):
            self.r1g_pointer.P_NL = value


    property TargetBU:
        def __get__(self):
            return self.r1g_pointer.TargetBU

        def __set__(self, double value):
            self.r1g_pointer.TargetBU = value


    property useZeta:
        def __get__(self):
            return self.r1g_pointer.useZeta

        def __set__(self, bint value):
            self.r1g_pointer.useZeta = value


    property Lattice:
        def __get__(self):
            cdef std.string value = self.r1g_pointer.Lattice
            return value.c_str()

        def __set__(self, char * value):
            self.r1g_pointer.Lattice = std.string(value)


    property H_XS_Rescale:
        def __get__(self):
            return self.r1g_pointer.H_XS_Rescale

        def __set__(self, bint value):
            self.r1g_pointer.H_XS_Rescale = value





    property r:
        def __get__(self):
            return self.r1g_pointer.r

        def __set__(self, double value):
            self.r1g_pointer.r = value


    property l:
        def __get__(self):
            return self.r1g_pointer.l

        def __set__(self, double value):
            self.r1g_pointer.l = value


    property S_O:
        def __get__(self):
            return self.r1g_pointer.S_O

        def __set__(self, double value):
            self.r1g_pointer.S_O = value


    property S_T:
        def __get__(self):
            return self.r1g_pointer.S_T

        def __set__(self, double value):
            self.r1g_pointer.S_T = value


    property VF:
        def __get__(self):
            return self.r1g_pointer.VF

        def __set__(self, double value):
            self.r1g_pointer.VF = value


    property VC:
        def __get__(self):
            return self.r1g_pointer.VC

        def __set__(self, double value):
            self.r1g_pointer.VC = value





    property libfile:
        def __get__(self):
            cdef std.string value = self.r1g_pointer.libfile
            return value.c_str()

        def __set__(self, char * value):
            self.r1g_pointer.libfile = std.string(value)


    property F:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.F)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.F = conv.array_to_vector_1d_dbl(value)


    property BUi_F_:
        def __get__(self):
            return conv.map_to_dict_int_array_to_vector_1d_dbl(self.r1g_pointer.BUi_F_)

        def __set__(self, dict value):
            self.r1g_pointer.BUi_F_ = conv.dict_to_map_int_vector_to_array_1d_dbl(value)


    property pi_F_:
        def __get__(self):
            return conv.map_to_dict_int_array_to_vector_1d_dbl(self.r1g_pointer.pi_F_)

        def __set__(self, dict value):
            self.r1g_pointer.pi_F_ = conv.dict_to_map_int_vector_to_array_1d_dbl(value)


    property di_F_:
        def __get__(self):
            return conv.map_to_dict_int_array_to_vector_1d_dbl(self.r1g_pointer.di_F_)

        def __set__(self, dict value):
            self.r1g_pointer.di_F_ = conv.dict_to_map_int_vector_to_array_1d_dbl(value)


    property Tij_F_:
        def __get__(self):
            return conv.map_to_dict_int_int_array_to_vector_1d_dbl(self.r1g_pointer.Tij_F_)

        def __set__(self, dict value):
            self.r1g_pointer.Tij_F_ = conv.dict_to_map_int_int_vector_to_array_1d_dbl(value)





    property A_IHM:
        def __get__(self):
            return self.r1g_pointer.A_IHM

        def __set__(self, double value):
            self.r1g_pointer.A_IHM = value


    property MWF:
        def __get__(self):
            return self.r1g_pointer.MWF

        def __set__(self, double value):
            self.r1g_pointer.MWF = value


    property MWC:
        def __get__(self):
            return self.r1g_pointer.MWC

        def __set__(self, double value):
            self.r1g_pointer.MWC = value

    
    property niF:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.r1g_pointer.niF)

        def __set__(self, dict value):
            self.r1g_pointer.niF = conv.dict_to_map_int_dbl(value)

    
    property niC:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.r1g_pointer.niC)

        def __set__(self, dict value):
            self.r1g_pointer.niC = conv.dict_to_map_int_dbl(value)

    
    property miF:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.r1g_pointer.miF)

        def __set__(self, dict value):
            self.r1g_pointer.miF = conv.dict_to_map_int_dbl(value)

    
    property miC:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.r1g_pointer.miC)

        def __set__(self, dict value):
            self.r1g_pointer.miC = conv.dict_to_map_int_dbl(value)

    
    property NiF:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.r1g_pointer.NiF)

        def __set__(self, dict value):
            self.r1g_pointer.NiF = conv.dict_to_map_int_dbl(value)

    
    property NiC:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.r1g_pointer.NiC)

        def __set__(self, dict value):
            self.r1g_pointer.NiC = conv.dict_to_map_int_dbl(value)





    property dF_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.dF_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.dF_F_ = conv.array_to_vector_1d_dbl(value)


    property dC_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.dC_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.dC_F_ = conv.array_to_vector_1d_dbl(value)


    property BU_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.BU_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.BU_F_ = conv.array_to_vector_1d_dbl(value)


    property P_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.P_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.P_F_ = conv.array_to_vector_1d_dbl(value)


    property D_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.D_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.D_F_ = conv.array_to_vector_1d_dbl(value)


    property k_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.k_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.k_F_ = conv.array_to_vector_1d_dbl(value)


    property Mj_F_:
        def __get__(self):
            return conv.map_to_dict_int_array_to_vector_1d_dbl(self.r1g_pointer.Mj_F_)

        def __set__(self, dict value):
            self.r1g_pointer.Mj_F_ = conv.dict_to_map_int_vector_to_array_1d_dbl(value)


    property zeta_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.zeta_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.zeta_F_ = conv.array_to_vector_1d_dbl(value)





    property fd:
        def __get__(self):
            return self.r1g_pointer.fd

        def __set__(self, int value):
            self.r1g_pointer.fd = value


    property Fd:
        def __get__(self):
            return self.r1g_pointer.Fd

        def __set__(self, double value):
            self.r1g_pointer.Fd = value


    property BUd:
        def __get__(self):
            return self.r1g_pointer.BUd

        def __set__(self, double value):
            self.r1g_pointer.BUd = value


    property k:
        def __get__(self):
            return self.r1g_pointer.k

        def __set__(self, double value):
            self.r1g_pointer.k = value





    property InU:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.r1g_pointer.InU
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.r1g_pointer.InU = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property InTRU:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.r1g_pointer.InTRU
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.r1g_pointer.InTRU = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property InLAN:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.r1g_pointer.InLAN
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.r1g_pointer.InLAN = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property InACT:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.r1g_pointer.InACT
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.r1g_pointer.InACT = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property OutU:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.r1g_pointer.OutU
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.r1g_pointer.OutU = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property OutTRU:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.r1g_pointer.OutTRU
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.r1g_pointer.OutTRU = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property OutLAN:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.r1g_pointer.OutLAN
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.r1g_pointer.OutLAN = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property OutACT:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.r1g_pointer.OutACT
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.r1g_pointer.OutACT = <cpp_mass_stream.MassStream> ms.ms_pointer[0]




    property deltaR:
        def __get__(self):
            return self.r1g_pointer.deltaR

        def __set__(self, double value):
            self.r1g_pointer.deltaR = value


    property TruCR:
        def __get__(self):
            return self.r1g_pointer.TruCR

        def __set__(self, double value):
            self.r1g_pointer.TruCR = value





    property SigmaFa_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.SigmaFa_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.SigmaFa_F_ = conv.array_to_vector_1d_dbl(value)


    property SigmaFtr_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.SigmaFtr_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.SigmaFtr_F_ = conv.array_to_vector_1d_dbl(value)


    property kappaF_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.kappaF_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.kappaF_F_ = conv.array_to_vector_1d_dbl(value)





    property SigmaCa_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.SigmaCa_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.SigmaCa_F_ = conv.array_to_vector_1d_dbl(value)


    property SigmaCtr_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.SigmaCtr_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.SigmaCtr_F_ = conv.array_to_vector_1d_dbl(value)


    property kappaC_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.kappaC_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.kappaC_F_ = conv.array_to_vector_1d_dbl(value)





    property LatticeE_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.LatticeE_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.LatticeE_F_ = conv.array_to_vector_1d_dbl(value)


    property LatticeF_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.r1g_pointer.LatticeF_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.r1g_pointer.LatticeF_F_ = conv.array_to_vector_1d_dbl(value)



    # FCComps inherited attributes

    property name:
        def __get__(self):
            cdef std.string n = self.r1g_pointer.name
            return n.c_str()

        def __set__(self, char * n):
            self.r1g_pointer.name = std.string(n)


    property natural_name:
        def __get__(self):
            cdef std.string n = self.r1g_pointer.natural_name
            return n.c_str()

        def __set__(self, char * n):
            self.r1g_pointer.natural_name = std.string(n)


    property IsosIn:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.r1g_pointer.IsosIn
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.r1g_pointer.IsosIn = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property IsosOut:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.r1g_pointer.IsosOut
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.r1g_pointer.IsosOut = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property ParamsIn:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.r1g_pointer.ParamsIn)

        def __set__(self, dict pi):
            self.r1g_pointer.ParamsIn = conv.dict_to_map_str_dbl(pi)


    property ParamsOut:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.r1g_pointer.ParamsOut)

        def __set__(self, dict po):
            self.r1g_pointer.ParamsOut = conv.dict_to_map_str_dbl(po)


    property PassNum:
        def __get__(self):
            return self.r1g_pointer.PassNum

        def __set__(self, int pn):
            self.r1g_pointer.PassNum = pn


    property params2track:
        def __get__(self):
            return conv.cpp_to_py_set_str(self.r1g_pointer.params2track)

        def __set__(self, set p2t):
            self.r1g_pointer.params2track = conv.py_to_cpp_set_str(p2t)


    #
    # Class Methods
    # 

    def initialize(self, ReactorParameters reactor_parameters):
        """The initialize() method for reactors copies all of the reactor specific parameters to this instance.
        Additionally, it calculates and sets the volumes VF and VC.

        Args:
            * reactor_parameters (ReactorParameters): A special data structure that contains information
              on how to setup and run the reactor.
        """
        cdef ReactorParameters rp = reactor_parameters
        self.r1g_pointer.initialize(<cpp_bright.ReactorParameters> rp.rp_pointer[0])


    def loadLib(self, char * libfile="reactor.h5"):
        """This method finds the HDF5 library for this reactor and extracts the necessary information from it.
        This method is typically called by the constructor of the child reactor type object.  It must be 
        called before attempting to do any real computation.

        Args: 
            * libfile (str): Path to the reactor library.
        """
        self.r1g_pointer.loadLib(std.string(libfile))


    def foldMassWeights(self):
        """This method performs the all-important task of doing the isotopically-weighted linear combination of raw data. 
        In a very real sense this is what makes this reactor *this specific reactor*.  The weights are taken 
        as the values of IsosIn.  The raw data must have previously been read in from loadLib().  

        .. warning::

            Anytime any reactor parameter whatsoever (IsosIn, P_NL, *etc*) is altered in any way, 
            the foldMassWeights() function must be called to reset all of the resultant data.
            If you are unsure, please call this function anyway to be safe.  There is little 
            harm in calling it twice by accident.
        """
        self.r1g_pointer.foldMassWeights()





    def mkMj_F_(self):
        """This function calculates and sets the Mj_F_ attribute from IsosIn and the 
        raw reactor data Tij_F_.
        """
        self.r1g_pointer.mkMj_F_()


    def mkMj_Fd_(self):
        """This function evaluates Mj_F_ calculated from mkMj_F_() at the discharge fluence Fd.
        The resultant isotopic dictionary is then converted into the IsosOut mass stream
        for this pass through the reactor.  Thus if ever you need to calculate IsosOut
        without going through doCalc(), use this function.
        """
        self.r1g_pointer.mkMj_Fd_()





    def calcOutIso(self):
        """This is a convenience function that wraps the transmutation matrix methods.  
        It is equivalent to::

            #Wrapper to calculate discharge isotopics.
            mkMj_F_()
            mkMj_Fd_()

        """
        self.r1g_pointer.calcOutIso()

    def calcSubStreams(self):
        """This sets possibly relevant reactor input and output substreams.  Specifically, it calculates the 
        attributes:

            * InU
            * InTRU
            * InLAN
            * InACT
            * OutU
            * OutTRU
            * OutLAN
            * OutACT

        """
        self.r1g_pointer.calcSubStreams()


    def calcTruCR(self):
        """This calculates and sets the transuranic conversion ratio TruCR through the equation:

        .. math:: \mbox{TruCR} = \frac{\mbox{InTRU.mass} - \mbox{OutTRU.mass}}{\frac{\mbox{BUd}}{935.0}}

        Returns:
            * TruCR (float): The value of the transuranic conversion ratio just calculated.
        """
        return self.r1g_pointer.calcTruCR()





    def calc_deltaR(self, input=None):
        """Calculates and sets the deltaR value of the reactor.  
        This is equal to the production rate minus the destruction rate at the target burnup::

            deltaR = batchAve(TargetBU, "P") - batchAve(TargetBU, "D")

        Args:
            * input (dict or MassStream): If input is present, it set as the component's 
              IsosIn.  If input is a isotopic dictionary (zzaaam keys, float values), this
              dictionary is first converted into a MassStream before being set as IsosIn.

        Returns:
            * deltaR (float): deltaR.
        """
        cdef mass_stream.MassStream in_ms 
        cdef double deltaR 

        if input is None:
            deltaR = self.r1g_pointer.calc_deltaR()
        elif isinstance(input, dict):
            deltaR = self.r1g_pointer.calc_deltaR(conv.dict_to_map_int_dbl(input))
        elif isinstance(input, mass_stream.MassStream):
            in_ms = input
            deltaR = self.r1g_pointer.calc_deltaR(<cpp_mass_stream.MassStream> in_ms.ms_pointer[0])

        return deltaR





    def FluenceAtBU(self, double burnup):
        """This function takes a burnup value  and returns a special fluence point object.  
        The fluence point is an amalgamation of data where the at which the burnup occurs.
        This object instance FP contains three pieces of information::
    
            FP.f    #Index immediately lower than where BU achieved (int)
            FP.F    #Fluence value itself (float)
            FP.m    #Slope dBU/dF between points f and f+1 (double)

        Args:
            * burnup (float): Burnup [MWd/kgIHM] at which to calculate the corresponding fluence.

        Returns:
            * fp (FluencePoint): A class containing fluence information.
        """
        cdef FluencePoint fp = FluencePoint()
        fp.fp_pointer[0] = self.r1g_pointer.FluenceAtBU(burnup)
        return fp


    def batchAve(self, double BUd, char * PDk_flag="K"):
        """Finds the batch-averaged P(F), D(F), or k(F) when at discharge burnup BUd.
        This function is typically iterated over until a BUd is found such that k(F) = 1.0 + err.

        Args:
            * BUd (float): The discharge burnup [MWd/kgIHM] to obtain a batch-averaged value for.

        Keyword Args:
            * PDk_flag (string): Flag that determines whether the neutron production rate "P" [n/s], 
              the neutron destruction rate "D" [n/s], or the multiplication factor "K" is reported in the output.

        Returns:
            * PDk (float): the batch averaged neutron production rate,
        """
        cdef double PDk = self.r1g_pointer.batchAve(BUd, std.string(PDk_flag))
        return PDk


    def batchAveK(self, double BUd):
        """Convenience function that calls batchAve(BUd, "K").

        Args:
            * BUd (float): The discharge burnup [MWd/kgIHM] to obtain a batch-averaged value for.

        Returns:
            * k (float): the batch averaged multiplication factor.
        """
        cdef double PDk = self.r1g_pointer.batchAveK(BUd)
        return PDk


    def BUd_BisectionMethod(self):
        """Calculates the maximum discharge burnup via the Bisection Method for a given IsosIn
        in this reactor.  This iterates over values of BUd to find a batch averaged multiplication factor 
        that is closest to 1.0.

        Other root finding methods for determining maximum discharge burnup are certainly possible.
        """
        self.r1g_pointer.BUd_BisectionMethod()


    def Run_PNL(self, double pnl):
        """Performs a reactor run for a specific non-leakage probability value.
        This requires that IsosIn be (meaningfully) set and is for use with Calibrate_PNL_2_BUd().

        This function amounts to the following code::

            self.P_NL = pnl
            self.foldMassWeights()
            self.BUd_BisectionMethod()

        Args:
            * pnl (float): The new non-leakage probability for the reactor.
        """
        self.r1g_pointer.Run_PNL(pnl)
    

    def Calibrate_PNL_2_BUd(self):
        """Often times the non-leakage probability of a reactor is not known, though the input isotopics 
        and the target discharge burnup are.  This function handles that situation by
        calibrating the non-leakage probability of this reactor P_NL to hit its target burnup TargetBU.
        Such a calibration proceeds by bisection method as well.  This function is extremely useful for 
        benchmarking calculations.
        """
        self.r1g_pointer.Calibrate_PNL_2_BUd()




    def doCalc(self, input=None):
        """Since many other methods provide the computational heavy-lifting of reactor calculations, 
        the doCalc() method is relatively simple::

            self.IsosIn = input
            self.foldMassWeights()
            self.BUd_BisectionMethod()
            self.calcOutIso()
            return self.IsosOut

        As you can see, all this function does is set burn an input stream to its maximum 
        discharge burnup and then reports on the output isotopics.

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
            output.ms_pointer[0] = (<cpp_bright.FCComp *> self.r1g_pointer).doCalc()
        elif isinstance(input, dict):
            output.ms_pointer[0] = self.r1g_pointer.doCalc(conv.dict_to_map_int_dbl(input))
        elif isinstance(input, mass_stream.MassStream):
            in_ms = input
            output.ms_pointer[0] = self.r1g_pointer.doCalc(<cpp_mass_stream.MassStream> in_ms.ms_pointer[0])

        return output






    def LatticeEPlanar(self, double a, double b):
        """Calculates the lattice function E(F) for planar geometry.  Sets value as LatticeE_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        self.r1g_pointer.LatticeEPlanar(a, b)


    def LatticeFPlanar(self, double a, double b):
        """Calculates the lattice function F(F) for planar geometry.  Sets value as LatticeF_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        self.r1g_pointer.LatticeFPlanar(a, b)


    def LatticeESpherical(self, double a, double b):
        """Calculates the lattice function E(F) for spherical geometry.  Sets value as LatticeE_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        self.r1g_pointer.LatticeESpherical(a, b)


    def LatticeFSpherical(self, double a, double b):
        """Calculates the lattice function F(F) for spherical geometry.  Sets value as LatticeF_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        self.r1g_pointer.LatticeFSpherical(a, b)


    def LatticeECylindrical(self, double a, double b):
        """Calculates the lattice function E(F) for cylindrical geometry.  Sets value as LatticeE_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        self.r1g_pointer.LatticeECylindrical(a, b)


    def LatticeFCylindrical(self, double a, double b):
        """Calculates the lattice function F(F) for cylindrical geometry.  Sets value as LatticeF_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        self.r1g_pointer.LatticeFCylindrical(a, b)





    def calcZeta(self):
        """This calculates the thermal disadvantage factor for the geometry specified by Lattice.  The results
        are set to zeta_F_.
        """
        self.r1g_pointer.calcZeta()


    def calcZetaPlanar(self):
        """This calculates the thermal disadvantage factor for a planar geometry.  The results
        are set to zeta_F_.
        """
        self.r1g_pointer.calcZetaPlanar()


    def calcZetaSpherical(self):
        """This calculates the thermal disadvantage factor for a spherical geometry.  The results
        are set to zeta_F_.
        """
        self.r1g_pointer.calcZetaSpherical()


    def calcZetaCylindrical(self):
        """This calculates the thermal disadvantage factor for a clyindrical geometry.  The results
        are set to zeta_F_.
        """
        self.r1g_pointer.calcZetaCylindrical()





##############################
### Light Water Reactor 1G ###
##############################


def LWRDefaults():
    cdef cpp_bright.ReactorParameters cpp_lwrd = cpp_bright.fillLWRDefaults()
    cdef ReactorParameters lwrd = ReactorParameters()
    lwrd.rp_pointer[0] = cpp_lwrd
    return lwrd


cdef class LightWaterReactor1G(Reactor1G):
    """A One-Group Light Water Reactor Fuel Cycle Component.  This is a daughter class of Reactor1G and 
    a granddaughter of FCComp.

    Keyword Args:
        * libfile (string): The path the the LWR HDF5 data library.  This value is set to 
          Reactor1G.libfile and used by Reactor1G.loadLib.
        * reactor_parameters (ReactorParameters): The physical reactor parameter data to initialize this
          LWR instance with.  If this argument is not provided, default values are taken.
        * name (string): The name of this LWR instance.
    """

    #cdef cpp_bright.LightWaterReactor1G * lwr1g_pointer

    def __cinit__(self, libfile=None, reactor_parameters=None, char * name=""):
        cdef ReactorParameters rp
        cdef std.string cpp_name = std.string(name)

        if (libfile is None) and (reactor_parameters is None):
            self.lwr1g_pointer = new cpp_bright.LightWaterReactor1G()
            self.lwr1g_pointer.name = cpp_name

        elif isinstance(libfile, basestring) and (reactor_parameters is None):
            self.lwr1g_pointer = new cpp_bright.LightWaterReactor1G(std.string(libfile), cpp_name)

        elif (libfile is None) and isinstance(reactor_parameters, ReactorParameters):
            rp = reactor_parameters
            self.lwr1g_pointer = new cpp_bright.LightWaterReactor1G(<cpp_bright.ReactorParameters> rp.rp_pointer[0], cpp_name)

        elif isinstance(libfile, basestring) and isinstance(reactor_parameters, ReactorParameters):
            rp = reactor_parameters
            self.lwr1g_pointer = new cpp_bright.LightWaterReactor1G(std.string(libfile), <cpp_bright.ReactorParameters> rp.rp_pointer[0], cpp_name)

        else:
            if libfile is not None:
                raise TypeError("The libfile keyword must be a string or None.  Got " + str(type(libfile)))

            if reactor_parameters is not None:
                raise TypeError("The reactor_parameters keyword must be an instance of the ReactorParameters class or None.  Got " + str(type(reactor_parameters)))

    def __dealloc__(self):
        del self.lwr1g_pointer


    #
    # Class Attributes
    #

    # Light water reactor attributes

    # Reactor1G attributes

    property B:
        def __get__(self):
            return self.lwr1g_pointer.B

        def __set__(self, int value):
            self.lwr1g_pointer.B = value


    property phi:
        def __get__(self):
            return self.lwr1g_pointer.phi

        def __set__(self, double value):
            self.lwr1g_pointer.phi = value


    property FuelChemicalForm:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.lwr1g_pointer.FuelChemicalForm)

        def __set__(self, dict value):
            self.lwr1g_pointer.FuelChemicalForm = conv.dict_to_map_str_dbl(value)


    property CoolantChemicalForm:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.lwr1g_pointer.CoolantChemicalForm)

        def __set__(self, dict value):
            self.lwr1g_pointer.CoolantChemicalForm = conv.dict_to_map_str_dbl(value)


    property rhoF:
        def __get__(self):
            return self.lwr1g_pointer.rhoF

        def __set__(self, double value):
            self.lwr1g_pointer.rhoF = value


    property rhoC:
        def __get__(self):
            return self.lwr1g_pointer.rhoC

        def __set__(self, double value):
            self.lwr1g_pointer.rhoC = value


    property P_NL:
        def __get__(self):
            return self.lwr1g_pointer.P_NL

        def __set__(self, double value):
            self.lwr1g_pointer.P_NL = value


    property TargetBU:
        def __get__(self):
            return self.lwr1g_pointer.TargetBU

        def __set__(self, double value):
            self.lwr1g_pointer.TargetBU = value


    property useZeta:
        def __get__(self):
            return self.lwr1g_pointer.useZeta

        def __set__(self, bint value):
            self.lwr1g_pointer.useZeta = value


    property Lattice:
        def __get__(self):
            cdef std.string value = self.lwr1g_pointer.Lattice
            return value.c_str()

        def __set__(self, char * value):
            self.lwr1g_pointer.Lattice = std.string(value)


    property H_XS_Rescale:
        def __get__(self):
            return self.lwr1g_pointer.H_XS_Rescale

        def __set__(self, bint value):
            self.lwr1g_pointer.H_XS_Rescale = value





    property r:
        def __get__(self):
            return self.lwr1g_pointer.r

        def __set__(self, double value):
            self.lwr1g_pointer.r = value


    property l:
        def __get__(self):
            return self.lwr1g_pointer.l

        def __set__(self, double value):
            self.lwr1g_pointer.l = value


    property S_O:
        def __get__(self):
            return self.lwr1g_pointer.S_O

        def __set__(self, double value):
            self.lwr1g_pointer.S_O = value


    property S_T:
        def __get__(self):
            return self.lwr1g_pointer.S_T

        def __set__(self, double value):
            self.lwr1g_pointer.S_T = value


    property VF:
        def __get__(self):
            return self.lwr1g_pointer.VF

        def __set__(self, double value):
            self.lwr1g_pointer.VF = value


    property VC:
        def __get__(self):
            return self.lwr1g_pointer.VC

        def __set__(self, double value):
            self.lwr1g_pointer.VC = value





    property libfile:
        def __get__(self):
            cdef std.string value = self.lwr1g_pointer.libfile
            return value.c_str()

        def __set__(self, char * value):
            self.lwr1g_pointer.libfile = std.string(value)


    property F:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.F)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.F = conv.array_to_vector_1d_dbl(value)


    property BUi_F_:
        def __get__(self):
            return conv.map_to_dict_int_array_to_vector_1d_dbl(self.lwr1g_pointer.BUi_F_)

        def __set__(self, dict value):
            self.lwr1g_pointer.BUi_F_ = conv.dict_to_map_int_vector_to_array_1d_dbl(value)


    property pi_F_:
        def __get__(self):
            return conv.map_to_dict_int_array_to_vector_1d_dbl(self.lwr1g_pointer.pi_F_)

        def __set__(self, dict value):
            self.lwr1g_pointer.pi_F_ = conv.dict_to_map_int_vector_to_array_1d_dbl(value)


    property di_F_:
        def __get__(self):
            return conv.map_to_dict_int_array_to_vector_1d_dbl(self.lwr1g_pointer.di_F_)

        def __set__(self, dict value):
            self.lwr1g_pointer.di_F_ = conv.dict_to_map_int_vector_to_array_1d_dbl(value)


    property Tij_F_:
        def __get__(self):
            return conv.map_to_dict_int_int_array_to_vector_1d_dbl(self.lwr1g_pointer.Tij_F_)

        def __set__(self, dict value):
            self.lwr1g_pointer.Tij_F_ = conv.dict_to_map_int_int_vector_to_array_1d_dbl(value)





    property A_IHM:
        def __get__(self):
            return self.lwr1g_pointer.A_IHM

        def __set__(self, double value):
            self.lwr1g_pointer.A_IHM = value


    property MWF:
        def __get__(self):
            return self.lwr1g_pointer.MWF

        def __set__(self, double value):
            self.lwr1g_pointer.MWF = value


    property MWC:
        def __get__(self):
            return self.lwr1g_pointer.MWC

        def __set__(self, double value):
            self.lwr1g_pointer.MWC = value

    
    property niF:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.lwr1g_pointer.niF)

        def __set__(self, dict value):
            self.lwr1g_pointer.niF = conv.dict_to_map_int_dbl(value)

    
    property niC:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.lwr1g_pointer.niC)

        def __set__(self, dict value):
            self.lwr1g_pointer.niC = conv.dict_to_map_int_dbl(value)

    
    property miF:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.lwr1g_pointer.miF)

        def __set__(self, dict value):
            self.lwr1g_pointer.miF = conv.dict_to_map_int_dbl(value)

    
    property miC:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.lwr1g_pointer.miC)

        def __set__(self, dict value):
            self.lwr1g_pointer.miC = conv.dict_to_map_int_dbl(value)

    
    property NiF:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.lwr1g_pointer.NiF)

        def __set__(self, dict value):
            self.lwr1g_pointer.NiF = conv.dict_to_map_int_dbl(value)

    
    property NiC:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.lwr1g_pointer.NiC)

        def __set__(self, dict value):
            self.lwr1g_pointer.NiC = conv.dict_to_map_int_dbl(value)





    property dF_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.dF_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.dF_F_ = conv.array_to_vector_1d_dbl(value)


    property dC_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.dC_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.dC_F_ = conv.array_to_vector_1d_dbl(value)


    property BU_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.BU_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.BU_F_ = conv.array_to_vector_1d_dbl(value)


    property P_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.P_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.P_F_ = conv.array_to_vector_1d_dbl(value)


    property D_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.D_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.D_F_ = conv.array_to_vector_1d_dbl(value)


    property k_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.k_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.k_F_ = conv.array_to_vector_1d_dbl(value)


    property Mj_F_:
        def __get__(self):
            return conv.map_to_dict_int_array_to_vector_1d_dbl(self.lwr1g_pointer.Mj_F_)

        def __set__(self, dict value):
            self.lwr1g_pointer.Mj_F_ = conv.dict_to_map_int_vector_to_array_1d_dbl(value)


    property zeta_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.zeta_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.zeta_F_ = conv.array_to_vector_1d_dbl(value)





    property fd:
        def __get__(self):
            return self.lwr1g_pointer.fd

        def __set__(self, int value):
            self.lwr1g_pointer.fd = value


    property Fd:
        def __get__(self):
            return self.lwr1g_pointer.Fd

        def __set__(self, double value):
            self.lwr1g_pointer.Fd = value


    property BUd:
        def __get__(self):
            return self.lwr1g_pointer.BUd

        def __set__(self, double value):
            self.lwr1g_pointer.BUd = value


    property k:
        def __get__(self):
            return self.lwr1g_pointer.k

        def __set__(self, double value):
            self.lwr1g_pointer.k = value





    property InU:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.lwr1g_pointer.InU
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.lwr1g_pointer.InU = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property InTRU:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.lwr1g_pointer.InTRU
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.lwr1g_pointer.InTRU = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property InLAN:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.lwr1g_pointer.InLAN
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.lwr1g_pointer.InLAN = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property InACT:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.lwr1g_pointer.InACT
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.lwr1g_pointer.InACT = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property OutU:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.lwr1g_pointer.OutU
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.lwr1g_pointer.OutU = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property OutTRU:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.lwr1g_pointer.OutTRU
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.lwr1g_pointer.OutTRU = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property OutLAN:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.lwr1g_pointer.OutLAN
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.lwr1g_pointer.OutLAN = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property OutACT:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.lwr1g_pointer.OutACT
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.lwr1g_pointer.OutACT = <cpp_mass_stream.MassStream> ms.ms_pointer[0]




    property deltaR:
        def __get__(self):
            return self.lwr1g_pointer.deltaR

        def __set__(self, double value):
            self.lwr1g_pointer.deltaR = value


    property TruCR:
        def __get__(self):
            return self.lwr1g_pointer.TruCR

        def __set__(self, double value):
            self.lwr1g_pointer.TruCR = value





    property SigmaFa_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.SigmaFa_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.SigmaFa_F_ = conv.array_to_vector_1d_dbl(value)


    property SigmaFtr_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.SigmaFtr_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.SigmaFtr_F_ = conv.array_to_vector_1d_dbl(value)


    property kappaF_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.kappaF_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.kappaF_F_ = conv.array_to_vector_1d_dbl(value)





    property SigmaCa_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.SigmaCa_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.SigmaCa_F_ = conv.array_to_vector_1d_dbl(value)


    property SigmaCtr_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.SigmaCtr_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.SigmaCtr_F_ = conv.array_to_vector_1d_dbl(value)


    property kappaC_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.kappaC_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.kappaC_F_ = conv.array_to_vector_1d_dbl(value)





    property LatticeE_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.LatticeE_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.LatticeE_F_ = conv.array_to_vector_1d_dbl(value)


    property LatticeF_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.lwr1g_pointer.LatticeF_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.lwr1g_pointer.LatticeF_F_ = conv.array_to_vector_1d_dbl(value)



    # FCComps inherited attributes

    property name:
        def __get__(self):
            cdef std.string n = self.lwr1g_pointer.name
            return n.c_str()

        def __set__(self, char * n):
            self.lwr1g_pointer.name = std.string(n)


    property natural_name:
        def __get__(self):
            cdef std.string n = self.lwr1g_pointer.natural_name
            return n.c_str()

        def __set__(self, char * n):
            self.lwr1g_pointer.natural_name = std.string(n)


    property IsosIn:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.lwr1g_pointer.IsosIn
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.lwr1g_pointer.IsosIn = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property IsosOut:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.lwr1g_pointer.IsosOut
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.lwr1g_pointer.IsosOut = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property ParamsIn:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.lwr1g_pointer.ParamsIn)

        def __set__(self, dict pi):
            self.lwr1g_pointer.ParamsIn = conv.dict_to_map_str_dbl(pi)


    property ParamsOut:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.lwr1g_pointer.ParamsOut)

        def __set__(self, dict po):
            self.lwr1g_pointer.ParamsOut = conv.dict_to_map_str_dbl(po)


    property PassNum:
        def __get__(self):
            return self.lwr1g_pointer.PassNum

        def __set__(self, int pn):
            self.lwr1g_pointer.PassNum = pn


    property params2track:
        def __get__(self):
            return conv.cpp_to_py_set_str(self.lwr1g_pointer.params2track)

        def __set__(self, set p2t):
            self.lwr1g_pointer.params2track = conv.py_to_cpp_set_str(p2t)



    #
    # Class Methods
    # 

    # LWR1G Methods

    def setParams(self):
        """Along with its own parameter set to track, the LWR model implements its own function to set these
        parameters.  This function is equivalent to the following::

            self.ParamsIn["BUd"]  = 0.0
            self.ParamsOut["BUd"] = self.BUd

            self.ParamsIn["U"]  = self.InU.mass
            self.ParamsOut["U"] = self.OutU.mass

            self.ParamsIn["TRU"]  = self.InTRU.mass
            self.ParamsOut["TRU"] = self.OutTRU.mass

            self.ParamsIn["ACT"]  = self.InACT.mass
            self.ParamsOut["ACT"] = self.OutACT.mass

            self.ParamsIn["LAN"]  = self.InLAN.mass
            self.ParamsOut["LAN"] = self.OutLAN.mass

            self.ParamsIn["FP"]  = 1.0 - self.InACT.mass  - self.InLAN.mass

        """
        (<cpp_bright.FCComp *> self.lwr1g_pointer).setParams()


    # Reactor1G Methods

    def initialize(self, ReactorParameters reactor_parameters):
        """The initialize() method for reactors copies all of the reactor specific parameters to this instance.
        Additionally, it calculates and sets the volumes VF and VC.

        Args:
            * reactor_parameters (ReactorParameters): A special data structure that contains information
              on how to setup and run the reactor.
        """
        cdef ReactorParameters rp = reactor_parameters
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).initialize(<cpp_bright.ReactorParameters> rp.rp_pointer[0])


    def loadLib(self, char * libfile="reactor.h5"):
        """This method finds the HDF5 library for this reactor and extracts the necessary information from it.
        This method is typically called by the constructor of the child reactor type object.  It must be 
        called before attempting to do any real computation.

        Args: 
            * libfile (str): Path to the reactor library.
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).loadLib(std.string(libfile))


    def foldMassWeights(self):
        """This method performs the all-important task of doing the isotopically-weighted linear combination of raw data. 
        In a very real sense this is what makes this reactor *this specific reactor*.  The weights are taken 
        as the values of IsosIn.  The raw data must have previously been read in from loadLib().  

        .. warning::

            Anytime any reactor parameter whatsoever (IsosIn, P_NL, *etc*) is altered in any way, 
            the foldMassWeights() function must be called to reset all of the resultant data.
            If you are unsure, please call this function anyway to be safe.  There is little 
            harm in calling it twice by accident.
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).foldMassWeights()





    def mkMj_F_(self):
        """This function calculates and sets the Mj_F_ attribute from IsosIn and the 
        raw reactor data Tij_F_.
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).mkMj_F_()


    def mkMj_Fd_(self):
        """This function evaluates Mj_F_ calculated from mkMj_F_() at the discharge fluence Fd.
        The resultant isotopic dictionary is then converted into the IsosOut mass stream
        for this pass through the reactor.  Thus if ever you need to calculate IsosOut
        without going through doCalc(), use this function.
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).mkMj_Fd_()





    def calcOutIso(self):
        """This is a convenience function that wraps the transmutation matrix methods.  
        It is equivalent to::

            #Wrapper to calculate discharge isotopics.
            mkMj_F_()
            mkMj_Fd_()

        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).calcOutIso()

    def calcSubStreams(self):
        """This sets possibly relevant reactor input and output substreams.  Specifically, it calculates the 
        attributes:

            * InU
            * InTRU
            * InLAN
            * InACT
            * OutU
            * OutTRU
            * OutLAN
            * OutACT

        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).calcSubStreams()


    def calcTruCR(self):
        """This calculates and sets the transuranic conversion ratio TruCR through the equation:

        .. math:: \mbox{TruCR} = \frac{\mbox{InTRU.mass} - \mbox{OutTRU.mass}}{\frac{\mbox{BUd}}{935.0}}

        Returns:
            * TruCR (float): The value of the transuranic conversion ratio just calculated.
        """
        return (<cpp_bright.Reactor1G *> self.lwr1g_pointer).calcTruCR()





    def calc_deltaR(self, input=None):
        """Calculates and sets the deltaR value of the reactor.  
        This is equal to the production rate minus the destruction rate at the target burnup::

            deltaR = batchAve(TargetBU, "P") - batchAve(TargetBU, "D")

        Args:
            * input (dict or MassStream): If input is present, it set as the component's 
              IsosIn.  If input is a isotopic dictionary (zzaaam keys, float values), this
              dictionary is first converted into a MassStream before being set as IsosIn.

        Returns:
            * deltaR (float): deltaR.
        """
        cdef mass_stream.MassStream in_ms 
        cdef double deltaR 

        if input is None:
            deltaR = (<cpp_bright.Reactor1G *> self.lwr1g_pointer).calc_deltaR()
        elif isinstance(input, dict):
            deltaR = (<cpp_bright.Reactor1G *> self.lwr1g_pointer).calc_deltaR(conv.dict_to_map_int_dbl(input))
        elif isinstance(input, mass_stream.MassStream):
            in_ms = input
            deltaR = (<cpp_bright.Reactor1G *> self.lwr1g_pointer).calc_deltaR(<cpp_mass_stream.MassStream> in_ms.ms_pointer[0])

        return deltaR





    def FluenceAtBU(self, double burnup):
        """This function takes a burnup value  and returns a special fluence point object.  
        The fluence point is an amalgamation of data where the at which the burnup occurs.
        This object instance FP contains three pieces of information::
    
            FP.f    #Index immediately lower than where BU achieved (int)
            FP.F    #Fluence value itself (float)
            FP.m    #Slope dBU/dF between points f and f+1 (double)

        Args:
            * burnup (float): Burnup [MWd/kgIHM] at which to calculate the corresponding fluence.

        Returns:
            * fp (FluencePoint): A class containing fluence information.
        """
        cdef FluencePoint fp = FluencePoint()
        fp.fp_pointer[0] = (<cpp_bright.Reactor1G *> self.lwr1g_pointer).FluenceAtBU(burnup)
        return fp


    def batchAve(self, double BUd, char * PDk_flag="K"):
        """Finds the batch-averaged P(F), D(F), or k(F) when at discharge burnup BUd.
        This function is typically iterated over until a BUd is found such that k(F) = 1.0 + err.

        Args:
            * BUd (float): The discharge burnup [MWd/kgIHM] to obtain a batch-averaged value for.

        Keyword Args:
            * PDk_flag (string): Flag that determines whether the neutron production rate "P" [n/s], 
              the neutron destruction rate "D" [n/s], or the multiplication factor "K" is reported in the output.

        Returns:
            * PDk (float): the batch averaged neutron production rate,
        """
        cdef double PDk = (<cpp_bright.Reactor1G *> self.lwr1g_pointer).batchAve(BUd, std.string(PDk_flag))
        return PDk


    def batchAveK(self, double BUd):
        """Convenience function that calls batchAve(BUd, "K").

        Args:
            * BUd (float): The discharge burnup [MWd/kgIHM] to obtain a batch-averaged value for.

        Returns:
            * k (float): the batch averaged multiplication factor.
        """
        cdef double PDk = (<cpp_bright.Reactor1G *> self.lwr1g_pointer).batchAveK(BUd)
        return PDk


    def BUd_BisectionMethod(self):
        """Calculates the maximum discharge burnup via the Bisection Method for a given IsosIn
        in this reactor.  This iterates over values of BUd to find a batch averaged multiplication factor 
        that is closest to 1.0.

        Other root finding methods for determining maximum discharge burnup are certainly possible.
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).BUd_BisectionMethod()


    def Run_PNL(self, double pnl):
        """Performs a reactor run for a specific non-leakage probability value.
        This requires that IsosIn be (meaningfully) set and is for use with Calibrate_PNL_2_BUd().

        This function amounts to the following code::

            self.P_NL = pnl
            self.foldMassWeights()
            self.BUd_BisectionMethod()

        Args:
            * pnl (float): The new non-leakage probability for the reactor.
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).Run_PNL(pnl)
    

    def Calibrate_PNL_2_BUd(self):
        """Often times the non-leakage probability of a reactor is not known, though the input isotopics 
        and the target discharge burnup are.  This function handles that situation by
        calibrating the non-leakage probability of this reactor P_NL to hit its target burnup TargetBU.
        Such a calibration proceeds by bisection method as well.  This function is extremely useful for 
        benchmarking calculations.
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).Calibrate_PNL_2_BUd()




    def doCalc(self, input=None):
        """Since many other methods provide the computational heavy-lifting of reactor calculations, 
        the doCalc() method is relatively simple::

            self.IsosIn = input
            self.foldMassWeights()
            self.BUd_BisectionMethod()
            self.calcOutIso()
            return self.IsosOut

        As you can see, all this function does is set burn an input stream to its maximum 
        discharge burnup and then reports on the output isotopics.

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
            output.ms_pointer[0] = (<cpp_bright.FCComp *> self.lwr1g_pointer).doCalc()
        elif isinstance(input, dict):
            output.ms_pointer[0] = (<cpp_bright.Reactor1G *> self.lwr1g_pointer).doCalc(conv.dict_to_map_int_dbl(input))
        elif isinstance(input, mass_stream.MassStream):
            in_ms = input
            output.ms_pointer[0] = (<cpp_bright.Reactor1G *> self.lwr1g_pointer).doCalc(<cpp_mass_stream.MassStream> in_ms.ms_pointer[0])

        return output






    def LatticeEPlanar(self, double a, double b):
        """Calculates the lattice function E(F) for planar geometry.  Sets value as LatticeE_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).LatticeEPlanar(a, b)


    def LatticeFPlanar(self, double a, double b):
        """Calculates the lattice function F(F) for planar geometry.  Sets value as LatticeF_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).LatticeFPlanar(a, b)


    def LatticeESpherical(self, double a, double b):
        """Calculates the lattice function E(F) for spherical geometry.  Sets value as LatticeE_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).LatticeESpherical(a, b)


    def LatticeFSpherical(self, double a, double b):
        """Calculates the lattice function F(F) for spherical geometry.  Sets value as LatticeF_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).LatticeFSpherical(a, b)


    def LatticeECylindrical(self, double a, double b):
        """Calculates the lattice function E(F) for cylindrical geometry.  Sets value as LatticeE_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).LatticeECylindrical(a, b)


    def LatticeFCylindrical(self, double a, double b):
        """Calculates the lattice function F(F) for cylindrical geometry.  Sets value as LatticeF_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).LatticeFCylindrical(a, b)





    def calcZeta(self):
        """This calculates the thermal disadvantage factor for the geometry specified by Lattice.  The results
        are set to zeta_F_.
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).calcZeta()


    def calcZetaPlanar(self):
        """This calculates the thermal disadvantage factor for a planar geometry.  The results
        are set to zeta_F_.
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).calcZetaPlanar()


    def calcZetaSpherical(self):
        """This calculates the thermal disadvantage factor for a spherical geometry.  The results
        are set to zeta_F_.
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).calcZetaSpherical()


    def calcZetaCylindrical(self):
        """This calculates the thermal disadvantage factor for a clyindrical geometry.  The results
        are set to zeta_F_.
        """
        (<cpp_bright.Reactor1G *> self.lwr1g_pointer).calcZetaCylindrical()





#######################
### Fast Reactor 1G ###
#######################


def FRDefaults():
    cdef cpp_bright.ReactorParameters cpp_frd = cpp_bright.fillFRDefaults()
    cdef ReactorParameters frd = ReactorParameters()
    frd.rp_pointer[0] = cpp_frd
    return frd


cdef class FastReactor1G(Reactor1G):
    """A One-Group Fast Reactor Fuel Cycle Component.  This is a daughter class of Reactor1G and 
    a granddaughter of FCComp.

    Keyword Args:
        * libfile (string): The path the the FR HDF5 data library.  This value is set to 
          Reactor1G.libfile and used by Reactor1G.loadLib.
        * reactor_parameters (ReactorParameters): The physical reactor parameter data to initialize this
          LWR instance with.  If this argument is not provided, default values are taken.
        * name (string): The name of this FR instance.
    """

    #cdef cpp_bright.FastReactor1G * fr1g_pointer

    def __cinit__(self, libfile=None, reactor_parameters=None, char * name=""):
        cdef ReactorParameters rp
        cdef std.string cpp_name = std.string(name)

        if (libfile is None) and (reactor_parameters is None):
            self.fr1g_pointer = new cpp_bright.FastReactor1G()
            self.fr1g_pointer.name = cpp_name

        elif isinstance(libfile, basestring) and (reactor_parameters is None):
            self.fr1g_pointer = new cpp_bright.FastReactor1G(std.string(libfile), cpp_name)

        elif (libfile is None) and isinstance(reactor_parameters, ReactorParameters):
            rp = reactor_parameters
            self.fr1g_pointer = new cpp_bright.FastReactor1G(<cpp_bright.ReactorParameters> rp.rp_pointer[0], cpp_name)

        elif isinstance(libfile, basestring) and isinstance(reactor_parameters, ReactorParameters):
            rp = reactor_parameters
            self.fr1g_pointer = new cpp_bright.FastReactor1G(std.string(libfile), <cpp_bright.ReactorParameters> rp.rp_pointer[0], cpp_name)

        else:
            if libfile is not None:
                raise TypeError("The libfile keyword must be a string or None.  Got " + str(type(libfile)))

            if reactor_parameters is not None:
                raise TypeError("The reactor_parameters keyword must be an instance of the ReactorParameters class or None.  Got " + str(type(reactor_parameters)))

    def __dealloc__(self):
        del self.fr1g_pointer


    #
    # Class Attributes
    #

    # Fast reactor attributes

    # Reactor1G attributes

    property B:
        def __get__(self):
            return self.fr1g_pointer.B

        def __set__(self, int value):
            self.fr1g_pointer.B = value


    property phi:
        def __get__(self):
            return self.fr1g_pointer.phi

        def __set__(self, double value):
            self.fr1g_pointer.phi = value


    property FuelChemicalForm:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.fr1g_pointer.FuelChemicalForm)

        def __set__(self, dict value):
            self.fr1g_pointer.FuelChemicalForm = conv.dict_to_map_str_dbl(value)


    property CoolantChemicalForm:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.fr1g_pointer.CoolantChemicalForm)

        def __set__(self, dict value):
            self.fr1g_pointer.CoolantChemicalForm = conv.dict_to_map_str_dbl(value)


    property rhoF:
        def __get__(self):
            return self.fr1g_pointer.rhoF

        def __set__(self, double value):
            self.fr1g_pointer.rhoF = value


    property rhoC:
        def __get__(self):
            return self.fr1g_pointer.rhoC

        def __set__(self, double value):
            self.fr1g_pointer.rhoC = value


    property P_NL:
        def __get__(self):
            return self.fr1g_pointer.P_NL

        def __set__(self, double value):
            self.fr1g_pointer.P_NL = value


    property TargetBU:
        def __get__(self):
            return self.fr1g_pointer.TargetBU

        def __set__(self, double value):
            self.fr1g_pointer.TargetBU = value


    property useZeta:
        def __get__(self):
            return self.fr1g_pointer.useZeta

        def __set__(self, bint value):
            self.fr1g_pointer.useZeta = value


    property Lattice:
        def __get__(self):
            cdef std.string value = self.fr1g_pointer.Lattice
            return value.c_str()

        def __set__(self, char * value):
            self.fr1g_pointer.Lattice = std.string(value)


    property H_XS_Rescale:
        def __get__(self):
            return self.fr1g_pointer.H_XS_Rescale

        def __set__(self, bint value):
            self.fr1g_pointer.H_XS_Rescale = value





    property r:
        def __get__(self):
            return self.fr1g_pointer.r

        def __set__(self, double value):
            self.fr1g_pointer.r = value


    property l:
        def __get__(self):
            return self.fr1g_pointer.l

        def __set__(self, double value):
            self.fr1g_pointer.l = value


    property S_O:
        def __get__(self):
            return self.fr1g_pointer.S_O

        def __set__(self, double value):
            self.fr1g_pointer.S_O = value


    property S_T:
        def __get__(self):
            return self.fr1g_pointer.S_T

        def __set__(self, double value):
            self.fr1g_pointer.S_T = value


    property VF:
        def __get__(self):
            return self.fr1g_pointer.VF

        def __set__(self, double value):
            self.fr1g_pointer.VF = value


    property VC:
        def __get__(self):
            return self.fr1g_pointer.VC

        def __set__(self, double value):
            self.fr1g_pointer.VC = value





    property libfile:
        def __get__(self):
            cdef std.string value = self.fr1g_pointer.libfile
            return value.c_str()

        def __set__(self, char * value):
            self.fr1g_pointer.libfile = std.string(value)


    property F:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.F)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.F = conv.array_to_vector_1d_dbl(value)


    property BUi_F_:
        def __get__(self):
            return conv.map_to_dict_int_array_to_vector_1d_dbl(self.fr1g_pointer.BUi_F_)

        def __set__(self, dict value):
            self.fr1g_pointer.BUi_F_ = conv.dict_to_map_int_vector_to_array_1d_dbl(value)


    property pi_F_:
        def __get__(self):
            return conv.map_to_dict_int_array_to_vector_1d_dbl(self.fr1g_pointer.pi_F_)

        def __set__(self, dict value):
            self.fr1g_pointer.pi_F_ = conv.dict_to_map_int_vector_to_array_1d_dbl(value)


    property di_F_:
        def __get__(self):
            return conv.map_to_dict_int_array_to_vector_1d_dbl(self.fr1g_pointer.di_F_)

        def __set__(self, dict value):
            self.fr1g_pointer.di_F_ = conv.dict_to_map_int_vector_to_array_1d_dbl(value)


    property Tij_F_:
        def __get__(self):
            return conv.map_to_dict_int_int_array_to_vector_1d_dbl(self.fr1g_pointer.Tij_F_)

        def __set__(self, dict value):
            self.fr1g_pointer.Tij_F_ = conv.dict_to_map_int_int_vector_to_array_1d_dbl(value)





    property A_IHM:
        def __get__(self):
            return self.fr1g_pointer.A_IHM

        def __set__(self, double value):
            self.fr1g_pointer.A_IHM = value


    property MWF:
        def __get__(self):
            return self.fr1g_pointer.MWF

        def __set__(self, double value):
            self.fr1g_pointer.MWF = value


    property MWC:
        def __get__(self):
            return self.fr1g_pointer.MWC

        def __set__(self, double value):
            self.fr1g_pointer.MWC = value

    
    property niF:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.fr1g_pointer.niF)

        def __set__(self, dict value):
            self.fr1g_pointer.niF = conv.dict_to_map_int_dbl(value)

    
    property niC:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.fr1g_pointer.niC)

        def __set__(self, dict value):
            self.fr1g_pointer.niC = conv.dict_to_map_int_dbl(value)

    
    property miF:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.fr1g_pointer.miF)

        def __set__(self, dict value):
            self.fr1g_pointer.miF = conv.dict_to_map_int_dbl(value)

    
    property miC:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.fr1g_pointer.miC)

        def __set__(self, dict value):
            self.fr1g_pointer.miC = conv.dict_to_map_int_dbl(value)

    
    property NiF:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.fr1g_pointer.NiF)

        def __set__(self, dict value):
            self.fr1g_pointer.NiF = conv.dict_to_map_int_dbl(value)

    
    property NiC:
        def __get__(self):
            return conv.map_to_dict_int_dbl(self.fr1g_pointer.NiC)

        def __set__(self, dict value):
            self.fr1g_pointer.NiC = conv.dict_to_map_int_dbl(value)





    property dF_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.dF_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.dF_F_ = conv.array_to_vector_1d_dbl(value)


    property dC_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.dC_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.dC_F_ = conv.array_to_vector_1d_dbl(value)


    property BU_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.BU_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.BU_F_ = conv.array_to_vector_1d_dbl(value)


    property P_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.P_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.P_F_ = conv.array_to_vector_1d_dbl(value)


    property D_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.D_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.D_F_ = conv.array_to_vector_1d_dbl(value)


    property k_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.k_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.k_F_ = conv.array_to_vector_1d_dbl(value)


    property Mj_F_:
        def __get__(self):
            return conv.map_to_dict_int_array_to_vector_1d_dbl(self.fr1g_pointer.Mj_F_)

        def __set__(self, dict value):
            self.fr1g_pointer.Mj_F_ = conv.dict_to_map_int_vector_to_array_1d_dbl(value)


    property zeta_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.zeta_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.zeta_F_ = conv.array_to_vector_1d_dbl(value)





    property fd:
        def __get__(self):
            return self.fr1g_pointer.fd

        def __set__(self, int value):
            self.fr1g_pointer.fd = value


    property Fd:
        def __get__(self):
            return self.fr1g_pointer.Fd

        def __set__(self, double value):
            self.fr1g_pointer.Fd = value


    property BUd:
        def __get__(self):
            return self.fr1g_pointer.BUd

        def __set__(self, double value):
            self.fr1g_pointer.BUd = value


    property k:
        def __get__(self):
            return self.fr1g_pointer.k

        def __set__(self, double value):
            self.fr1g_pointer.k = value





    property InU:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.fr1g_pointer.InU
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.fr1g_pointer.InU = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property InTRU:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.fr1g_pointer.InTRU
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.fr1g_pointer.InTRU = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property InLAN:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.fr1g_pointer.InLAN
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.fr1g_pointer.InLAN = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property InACT:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.fr1g_pointer.InACT
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.fr1g_pointer.InACT = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property OutU:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.fr1g_pointer.OutU
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.fr1g_pointer.OutU = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property OutTRU:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.fr1g_pointer.OutTRU
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.fr1g_pointer.OutTRU = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property OutLAN:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.fr1g_pointer.OutLAN
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.fr1g_pointer.OutLAN = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property OutACT:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.fr1g_pointer.OutACT
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.fr1g_pointer.OutACT = <cpp_mass_stream.MassStream> ms.ms_pointer[0]




    property deltaR:
        def __get__(self):
            return self.fr1g_pointer.deltaR

        def __set__(self, double value):
            self.fr1g_pointer.deltaR = value


    property TruCR:
        def __get__(self):
            return self.fr1g_pointer.TruCR

        def __set__(self, double value):
            self.fr1g_pointer.TruCR = value





    property SigmaFa_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.SigmaFa_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.SigmaFa_F_ = conv.array_to_vector_1d_dbl(value)


    property SigmaFtr_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.SigmaFtr_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.SigmaFtr_F_ = conv.array_to_vector_1d_dbl(value)


    property kappaF_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.kappaF_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.kappaF_F_ = conv.array_to_vector_1d_dbl(value)





    property SigmaCa_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.SigmaCa_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.SigmaCa_F_ = conv.array_to_vector_1d_dbl(value)


    property SigmaCtr_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.SigmaCtr_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.SigmaCtr_F_ = conv.array_to_vector_1d_dbl(value)


    property kappaC_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.kappaC_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.kappaC_F_ = conv.array_to_vector_1d_dbl(value)





    property LatticeE_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.LatticeE_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.LatticeE_F_ = conv.array_to_vector_1d_dbl(value)


    property LatticeF_F_:
        def __get__(self):
            return conv.vector_to_array_1d_dbl(self.fr1g_pointer.LatticeF_F_)

        def __set__(self, np.ndarray[np.float64_t, ndim=1] value):
            self.fr1g_pointer.LatticeF_F_ = conv.array_to_vector_1d_dbl(value)



    # FCComps inherited attributes

    property name:
        def __get__(self):
            cdef std.string n = self.fr1g_pointer.name
            return n.c_str()

        def __set__(self, char * n):
            self.fr1g_pointer.name = std.string(n)


    property natural_name:
        def __get__(self):
            cdef std.string n = self.fr1g_pointer.natural_name
            return n.c_str()

        def __set__(self, char * n):
            self.fr1g_pointer.natural_name = std.string(n)


    property IsosIn:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.fr1g_pointer.IsosIn
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.fr1g_pointer.IsosIn = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property IsosOut:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.fr1g_pointer.IsosOut
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.fr1g_pointer.IsosOut = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property ParamsIn:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.fr1g_pointer.ParamsIn)

        def __set__(self, dict pi):
            self.fr1g_pointer.ParamsIn = conv.dict_to_map_str_dbl(pi)


    property ParamsOut:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.fr1g_pointer.ParamsOut)

        def __set__(self, dict po):
            self.fr1g_pointer.ParamsOut = conv.dict_to_map_str_dbl(po)


    property PassNum:
        def __get__(self):
            return self.fr1g_pointer.PassNum

        def __set__(self, int pn):
            self.fr1g_pointer.PassNum = pn


    property params2track:
        def __get__(self):
            return conv.cpp_to_py_set_str(self.fr1g_pointer.params2track)

        def __set__(self, set p2t):
            self.fr1g_pointer.params2track = conv.py_to_cpp_set_str(p2t)



    #
    # Class Methods
    # 

    # FastReactor1G Methods

    def setParams(self):
        """Along with its own parameter set to track, the FR model implements its own function to set these
        parameters.  This function is equivalent to the following::

            self.ParamsIn["BUd"]  = 0.0
            self.ParamsOut["BUd"] = self.BUd

            self.ParamsIn["TRUCR"]  = 0.0
            self.ParamsOut["TRUCR"] = self.calcTruCR()

            self.ParamsIn["P_NL"]  = 0.0
            self.ParamsOut["P_NL"] = self.P_NL

            self.ParamsIn["U"]  = self.InU.mass
            self.ParamsOut["U"] = self.OutU.mass

            self.ParamsIn["TRU"]  = self.InTRU.mass
            self.ParamsOut["TRU"] = self.OutTRU.mass

            self.ParamsIn["ACT"]  = self.InACT.mass
            self.ParamsOut["ACT"] = self.OutACT.mass

            self.ParamsIn["LAN"]  = self.InLAN.mass
            self.ParamsOut["LAN"] = self.OutLAN.mass

            self.ParamsIn["FP"]  = 1.0 - self.InACT.mass  - self.InLAN.mass
            self.ParamsOut["FP"] = 1.0 - self.OutACT.mass - self.OutLAN.mass

        """
        (<cpp_bright.FCComp *> self.fr1g_pointer).setParams()


    # Reactor1G Methods

    def initialize(self, ReactorParameters reactor_parameters):
        """The initialize() method for reactors copies all of the reactor specific parameters to this instance.
        Additionally, it calculates and sets the volumes VF and VC.

        Args:
            * reactor_parameters (ReactorParameters): A special data structure that contains information
              on how to setup and run the reactor.
        """
        cdef ReactorParameters rp = reactor_parameters
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).initialize(<cpp_bright.ReactorParameters> rp.rp_pointer[0])


    def loadLib(self, char * libfile="reactor.h5"):
        """This method finds the HDF5 library for this reactor and extracts the necessary information from it.
        This method is typically called by the constructor of the child reactor type object.  It must be 
        called before attempting to do any real computation.

        Args: 
            * libfile (str): Path to the reactor library.
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).loadLib(std.string(libfile))


    def foldMassWeights(self):
        """This method performs the all-important task of doing the isotopically-weighted linear combination of raw data. 
        In a very real sense this is what makes this reactor *this specific reactor*.  The weights are taken 
        as the values of IsosIn.  The raw data must have previously been read in from loadLib().  

        .. warning::

            Anytime any reactor parameter whatsoever (IsosIn, P_NL, *etc*) is altered in any way, 
            the foldMassWeights() function must be called to reset all of the resultant data.
            If you are unsure, please call this function anyway to be safe.  There is little 
            harm in calling it twice by accident.
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).foldMassWeights()





    def mkMj_F_(self):
        """This function calculates and sets the Mj_F_ attribute from IsosIn and the 
        raw reactor data Tij_F_.
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).mkMj_F_()


    def mkMj_Fd_(self):
        """This function evaluates Mj_F_ calculated from mkMj_F_() at the discharge fluence Fd.
        The resultant isotopic dictionary is then converted into the IsosOut mass stream
        for this pass through the reactor.  Thus if ever you need to calculate IsosOut
        without going through doCalc(), use this function.
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).mkMj_Fd_()





    def calcOutIso(self):
        """This is a convenience function that wraps the transmutation matrix methods.  
        It is equivalent to::

            #Wrapper to calculate discharge isotopics.
            mkMj_F_()
            mkMj_Fd_()

        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).calcOutIso()

    def calcSubStreams(self):
        """This sets possibly relevant reactor input and output substreams.  Specifically, it calculates the 
        attributes:

            * InU
            * InTRU
            * InLAN
            * InACT
            * OutU
            * OutTRU
            * OutLAN
            * OutACT

        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).calcSubStreams()


    def calcTruCR(self):
        """This calculates and sets the transuranic conversion ratio TruCR through the equation:

        .. math:: \mbox{TruCR} = \frac{\mbox{InTRU.mass} - \mbox{OutTRU.mass}}{\frac{\mbox{BUd}}{935.0}}

        Returns:
            * TruCR (float): The value of the transuranic conversion ratio just calculated.
        """
        return (<cpp_bright.Reactor1G *> self.fr1g_pointer).calcTruCR()





    def calc_deltaR(self, input=None):
        """Calculates and sets the deltaR value of the reactor.  
        This is equal to the production rate minus the destruction rate at the target burnup::

            deltaR = batchAve(TargetBU, "P") - batchAve(TargetBU, "D")

        Args:
            * input (dict or MassStream): If input is present, it set as the component's 
              IsosIn.  If input is a isotopic dictionary (zzaaam keys, float values), this
              dictionary is first converted into a MassStream before being set as IsosIn.

        Returns:
            * deltaR (float): deltaR.
        """
        cdef mass_stream.MassStream in_ms 
        cdef double deltaR 

        if input is None:
            deltaR = (<cpp_bright.Reactor1G *> self.fr1g_pointer).calc_deltaR()
        elif isinstance(input, dict):
            deltaR = (<cpp_bright.Reactor1G *> self.fr1g_pointer).calc_deltaR(conv.dict_to_map_int_dbl(input))
        elif isinstance(input, mass_stream.MassStream):
            in_ms = input
            deltaR = (<cpp_bright.Reactor1G *> self.fr1g_pointer).calc_deltaR(<cpp_mass_stream.MassStream> in_ms.ms_pointer[0])

        return deltaR





    def FluenceAtBU(self, double burnup):
        """This function takes a burnup value  and returns a special fluence point object.  
        The fluence point is an amalgamation of data where the at which the burnup occurs.
        This object instance FP contains three pieces of information::
    
            FP.f    #Index immediately lower than where BU achieved (int)
            FP.F    #Fluence value itself (float)
            FP.m    #Slope dBU/dF between points f and f+1 (double)

        Args:
            * burnup (float): Burnup [MWd/kgIHM] at which to calculate the corresponding fluence.

        Returns:
            * fp (FluencePoint): A class containing fluence information.
        """
        cdef FluencePoint fp = FluencePoint()
        fp.fp_pointer[0] = (<cpp_bright.Reactor1G *> self.fr1g_pointer).FluenceAtBU(burnup)
        return fp


    def batchAve(self, double BUd, char * PDk_flag="K"):
        """Finds the batch-averaged P(F), D(F), or k(F) when at discharge burnup BUd.
        This function is typically iterated over until a BUd is found such that k(F) = 1.0 + err.

        Args:
            * BUd (float): The discharge burnup [MWd/kgIHM] to obtain a batch-averaged value for.

        Keyword Args:
            * PDk_flag (string): Flag that determines whether the neutron production rate "P" [n/s], 
              the neutron destruction rate "D" [n/s], or the multiplication factor "K" is reported in the output.

        Returns:
            * PDk (float): the batch averaged neutron production rate,
        """
        cdef double PDk = (<cpp_bright.Reactor1G *> self.fr1g_pointer).batchAve(BUd, std.string(PDk_flag))
        return PDk


    def batchAveK(self, double BUd):
        """Convenience function that calls batchAve(BUd, "K").

        Args:
            * BUd (float): The discharge burnup [MWd/kgIHM] to obtain a batch-averaged value for.

        Returns:
            * k (float): the batch averaged multiplication factor.
        """
        cdef double PDk = (<cpp_bright.Reactor1G *> self.fr1g_pointer).batchAveK(BUd)
        return PDk


    def BUd_BisectionMethod(self):
        """Calculates the maximum discharge burnup via the Bisection Method for a given IsosIn
        in this reactor.  This iterates over values of BUd to find a batch averaged multiplication factor 
        that is closest to 1.0.

        Other root finding methods for determining maximum discharge burnup are certainly possible.
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).BUd_BisectionMethod()


    def Run_PNL(self, double pnl):
        """Performs a reactor run for a specific non-leakage probability value.
        This requires that IsosIn be (meaningfully) set and is for use with Calibrate_PNL_2_BUd().

        This function amounts to the following code::

            self.P_NL = pnl
            self.foldMassWeights()
            self.BUd_BisectionMethod()

        Args:
            * pnl (float): The new non-leakage probability for the reactor.
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).Run_PNL(pnl)
    

    def Calibrate_PNL_2_BUd(self):
        """Often times the non-leakage probability of a reactor is not known, though the input isotopics 
        and the target discharge burnup are.  This function handles that situation by
        calibrating the non-leakage probability of this reactor P_NL to hit its target burnup TargetBU.
        Such a calibration proceeds by bisection method as well.  This function is extremely useful for 
        benchmarking calculations.
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).Calibrate_PNL_2_BUd()




    def doCalc(self, input=None):
        """Since many other methods provide the computational heavy-lifting of reactor calculations, 
        the doCalc() method is relatively simple::

            self.IsosIn = input
            self.foldMassWeights()
            self.BUd_BisectionMethod()
            self.calcOutIso()
            return self.IsosOut

        As you can see, all this function does is set burn an input stream to its maximum 
        discharge burnup and then reports on the output isotopics.

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
            output.ms_pointer[0] = (<cpp_bright.FCComp *> self.fr1g_pointer).doCalc()
        elif isinstance(input, dict):
            output.ms_pointer[0] = (<cpp_bright.Reactor1G *> self.fr1g_pointer).doCalc(conv.dict_to_map_int_dbl(input))
        elif isinstance(input, mass_stream.MassStream):
            in_ms = input
            output.ms_pointer[0] = (<cpp_bright.Reactor1G *> self.fr1g_pointer).doCalc(<cpp_mass_stream.MassStream> in_ms.ms_pointer[0])

        return output






    def LatticeEPlanar(self, double a, double b):
        """Calculates the lattice function E(F) for planar geometry.  Sets value as LatticeE_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).LatticeEPlanar(a, b)


    def LatticeFPlanar(self, double a, double b):
        """Calculates the lattice function F(F) for planar geometry.  Sets value as LatticeF_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).LatticeFPlanar(a, b)


    def LatticeESpherical(self, double a, double b):
        """Calculates the lattice function E(F) for spherical geometry.  Sets value as LatticeE_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).LatticeESpherical(a, b)


    def LatticeFSpherical(self, double a, double b):
        """Calculates the lattice function F(F) for spherical geometry.  Sets value as LatticeF_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).LatticeFSpherical(a, b)


    def LatticeECylindrical(self, double a, double b):
        """Calculates the lattice function E(F) for cylindrical geometry.  Sets value as LatticeE_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).LatticeECylindrical(a, b)


    def LatticeFCylindrical(self, double a, double b):
        """Calculates the lattice function F(F) for cylindrical geometry.  Sets value as LatticeF_F_

        Args:
            * a (float): Fuel region radius equivalent [cm].
            * b (float): Unit fuel cell pitch length equivalent [cm].
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).LatticeFCylindrical(a, b)





    def calcZeta(self):
        """This calculates the thermal disadvantage factor for the geometry specified by Lattice.  The results
        are set to zeta_F_.
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).calcZeta()


    def calcZetaPlanar(self):
        """This calculates the thermal disadvantage factor for a planar geometry.  The results
        are set to zeta_F_.
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).calcZetaPlanar()


    def calcZetaSpherical(self):
        """This calculates the thermal disadvantage factor for a spherical geometry.  The results
        are set to zeta_F_.
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).calcZetaSpherical()


    def calcZetaCylindrical(self):
        """This calculates the thermal disadvantage factor for a clyindrical geometry.  The results
        are set to zeta_F_.
        """
        (<cpp_bright.Reactor1G *> self.fr1g_pointer).calcZetaCylindrical()





#############################
### FuelFabrication Class ###
#############################


cdef class FuelFabrication(FCComp):
    """Fuel Fabrication Fuel Cycle Component Class.  Daughter of bright.FCComp class.

    Keyword Args:
        * mass_streams (dict): A dictionary whose keys are string labels (eg, "U-235", 
          "TRU", "My Fuel") and whose values are mass streams.  For example::

            mass_streams = {
                "U235": MassStream({922350: 1.0}, 1.0, "U-235"),
                "U236": MassStream({922360: 1.0}, 1.0, "U-236"),
                "U238": MassStream({922380: 1.0}, 1.0, "U-238"),
                }

          would be valid for a light water reactor.
        * mass_weights_in (dict): A dictionary whose keys are the same as for mass_streams
          and whose values are the associated weight (float) for that stream.  If a stream
          should be allowed to vary (optimized over), specify its weight as a negative number.
          For instance::

            mass_weights_in = {
                "U235": -1.0,
                "U236": 0.005,
                "U238": -1.0,        
                }

          would be valid for a light water reactor with half a percent of U-236 always present.
        * reactor (Reactor1G): An instance of a Reactor1G class to fabricate fuel for.
        * params2track (list of str): Additional parameters to track, if any.        
        * name (str): The name of the fuel fabrication fuel cycle component instance.

    Note that this automatically calls the public initialize() C function.
    """

    #cdef cpp_bright.FuelFabrication * ff_pointer

    def __cinit__(self, mass_streams=None, mass_weights_in=None, reactor=None, params2track=None, char * name=""):
        cdef std.string cpp_name = std.string(name)
        cdef Reactor1G r1g 

        if (mass_streams is None) and (mass_weights_in is None) and (reactor is None) and (params2track is None):
            self.ff_pointer = new cpp_bright.FuelFabrication(std.string(name))

        elif (mass_streams is None) and (mass_weights_in is None) and (reactor is None) and isinstance(params2track, set):
            self.ff_pointer = new cpp_bright.FuelFabrication(conv.py_to_cpp_set_str(params2track), cpp_name)

        elif isinstance(mass_streams, dict) and isinstance(mass_weights_in, dict) and isinstance(reactor, Reactor1G) and (params2track is None):
            r1g = reactor
            self.ff_pointer = new cpp_bright.FuelFabrication(
                                mass_stream.dict_to_map_str_msp(mass_streams), 
                                conv.dict_to_map_str_dbl(mass_weights_in), 
                                r1g.r1g_pointer[0], 
                                std.string(name))

        elif isinstance(mass_streams, dict) and isinstance(mass_weights_in, dict) and isinstance(reactor, Reactor1G) and isinstance(params2track, set):
            r1g = reactor
            self.ff_pointer = new cpp_bright.FuelFabrication(
                                mass_stream.dict_to_map_str_msp(mass_streams), 
                                conv.dict_to_map_str_dbl(mass_weights_in), 
                                r1g.r1g_pointer[0], 
                                conv.py_to_cpp_set_str(params2track),
                                std.string(name))

        else:
            if mass_streams is not None:
                raise TypeError("The mass_streams keyword must be a dictionary of (string, MassStream) items or None.  Got " + str(type(mass_streams)))

            if mass_weights_in is not None:
                raise TypeError("The mass_weights_in keyword must be a dictionary of (string, float) items or None.  Got " + str(type(mass_weights_in)))

            if reactor is not None:
                raise TypeError("The reactor keyword must be a Reactor1G instance or None.  Got " + str(type(reactor)))

            if params2track is not None:
                raise TypeError("The params2track keyword must be a set of strings or None.  Got " + str(type(params2track)))


    def __dealloc__(self):
        del self.ff_pointer


    #
    # Class Attributes
    #

    # FuelFabrication attributes

    property mass_streams:
        def __get__(self):
            return mass_stream.map_to_dict_str_msp(self.ff_pointer.mass_streams)

        def __set__(self, dict value):
            self.ff_pointer.mass_streams = mass_stream.dict_to_map_str_msp(value)


    property mass_weights_in:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.ff_pointer.mass_weights_in)

        def __set__(self, dict value):
            self.ff_pointer.mass_weights_in = conv.dict_to_map_str_dbl(value)


    property mass_weights_out:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.ff_pointer.mass_weights_out)

        def __set__(self, dict value):
            self.ff_pointer.mass_weights_out = conv.dict_to_map_str_dbl(value)


    property deltaRs:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.ff_pointer.deltaRs)

        def __set__(self, dict value):
            self.ff_pointer.deltaRs = conv.dict_to_map_str_dbl(value)


    property reactor:
        def __get__(self):
            cdef Reactor1G value = Reactor1G()
            value.r1g_pointer[0] = self.ff_pointer.reactor
            return value

        def __set__(self, Reactor1G value):
            self.ff_pointer.reactor = <cpp_bright.Reactor1G> value.r1g_pointer[0]


    # FCComps inherited attributes

    property name:
        def __get__(self):
            cdef std.string n = self.ff_pointer.name
            return n.c_str()

        def __set__(self, char * n):
            self.ff_pointer.name = std.string(n)


    property natural_name:
        def __get__(self):
            cdef std.string n = self.ff_pointer.natural_name
            return n.c_str()

        def __set__(self, char * n):
            self.ff_pointer.natural_name = std.string(n)


    property IsosIn:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.ff_pointer.IsosIn
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.ff_pointer.IsosIn = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property IsosOut:
        def __get__(self):
            cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
            py_ms.ms_pointer[0] = self.ff_pointer.IsosOut
            return py_ms

        def __set__(self, mass_stream.MassStream ms):
            self.ff_pointer.IsosOut = <cpp_mass_stream.MassStream> ms.ms_pointer[0]


    property ParamsIn:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.ff_pointer.ParamsIn)

        def __set__(self, dict pi):
            self.ff_pointer.ParamsIn = conv.dict_to_map_str_dbl(pi)


    property ParamsOut:
        def __get__(self):
            return conv.map_to_dict_str_dbl(self.ff_pointer.ParamsOut)

        def __set__(self, dict po):
            self.ff_pointer.ParamsOut = conv.dict_to_map_str_dbl(po)


    property PassNum:
        def __get__(self):
            return self.ff_pointer.PassNum

        def __set__(self, int pn):
            self.ff_pointer.PassNum = pn


    property params2track:
        def __get__(self):
            return conv.cpp_to_py_set_str(self.ff_pointer.params2track)

        def __set__(self, set p2t):
            self.ff_pointer.params2track = conv.py_to_cpp_set_str(p2t)



    #
    # Class Methods
    # 

    def initialize(self, dict mass_streams, dict mass_weights_in, Reactor1G reactor):
        """The initialize() method takes the appropriate mass streams, input mass weights,
        a reactor objects and resets the current FuelFabrication instance.

        Args:
            * mass_streams (dict): A dictionary whose keys are string labels and whose values are mass streams.  
            * mass_weights_in (dict): A dictionary whose keys are the same as for mass_streams
              and whose values are the associated weight (float) for that stream.
            * reactor (Reactor1G): An instance of a Reactor1G class to fabricate fuel for.
        """
        cdef Reactor1G r1g = reactor
        self.ff_pointer.initialize(mass_stream.dict_to_map_str_msp(mass_streams), 
                                   conv.dict_to_map_str_dbl(mass_weights_in), 
                                   r1g.r1g_pointer[0])


    def setParams(self):
        """Here the parameters for FuelFabrication are set.  For example::

            self.ParamsIn["Weight_U235"]  = self.mass_weights_in["U235"]
            self.Paramsout["Weight_U235"] = self.mass_weights_out["U235"]

            self.ParamsIn["deltaR_U235"]  = self.deltaRs["U235"]
            self.Paramsout["deltaR_U235"] = self.deltaRs["U235"]

            self.ParamsIn["Weight_U238"]  = self.mass_weights_in["U238"]
            self.Paramsout["Weight_U238"] = self.mass_weights_out["U238"]

            self.ParamsIn["deltaR_U238"]  = self.deltaRs["U238"]
            self.Paramsout["deltaR_U238"] = self.deltaRs["U238"]
        """
        (<cpp_bright.FCComp *> self.ff_pointer).setParams()





    def calc_deltaRs(self):
        """Computes deltaRs for each mass stream."""
        self.ff_pointer.calc_deltaRs()


    def calc_core_input(self):
        """Computes the core input mass stream that becomes IsosOut based on mass_streams and 
        mass_weights_out.

        Returns:
            * core_input (MassStream): IsosOut.
        """
        cdef mass_stream.MassStream py_ms = mass_stream.MassStream()
        py_ms.ms_pointer[0] = self.ff_pointer.calc_core_input()
        return py_ms


    def calc_mass_ratios(self):
        """Calculates mass_weights_out by varying the values of the two parameter which had 
        negative values in mass_weights_in.  Therefore, this is the portion of the code that 
        performs the optimization calculation.
        """
        self.ff_pointer.calc_mass_ratios()





    def doCalc(self, mass_streams=None, mass_weights_in=None, reactor=None):
        """This method performs an optimization calculation on all input mass streams to determine
        the mass ratios that generate the correct fuel form for the reactor.  It then compiles 
        the fuel and returns the resultant MassStream. 

        Args:
            * mass_streams (dict): A dictionary whose keys are string labels and whose values are mass streams.  
            * mass_weights_in (dict): A dictionary whose keys are the same as for mass_streams
              and whose values are the associated weight (float) for that stream.
            * reactor (Reactor1G): An instance of a Reactor1G class to fabricate fuel for.

        Returns:
            * core_input (MassStream): IsosOut.
        """
        cdef Reactor1G r1g 
        cdef mass_stream.MassStream core_input = mass_stream.MassStream()

        if (mass_streams is None) and (mass_weights_in is None) and (reactor is None):
            core_input.ms_pointer[0] = (<cpp_bright.FCComp *> self.ff_pointer).doCalc()

        elif isinstance(mass_streams, dict) and isinstance(mass_weights_in, dict) and isinstance(reactor, Reactor1G):
            r1g = reactor
            core_input.ms_pointer[0] = self.ff_pointer.doCalc(
                                                            mass_stream.dict_to_map_str_msp(mass_streams), 
                                                            conv.dict_to_map_str_dbl(mass_weights_in), 
                                                            r1g.r1g_pointer[0])

        else:
            if mass_streams is not None:
                raise TypeError("The mass_streams keyword must be a dictionary of (string, MassStream) items or None.  Got " + str(type(mass_streams)))

            if mass_weights_in is not None:
                raise TypeError("The mass_weights_in keyword must be a dictionary of (string, float) items or None.  Got " + str(type(mass_weights_in)))

            if reactor is not None:
                raise TypeError("The reactor keyword must be a Reactor1G instance or None.  Got " + str(type(reactor)))

        return core_input
