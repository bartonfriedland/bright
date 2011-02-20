// Reactor1G.h
// Header for general One Group Reactor Model

#if !defined(_Bright_Reactor1G_)
#define _Bright_Reactor1G_

//C++ stdlib
#include <map>
#include <set>
#include <vector>
#include <string>
#include <exception>
#include <iostream>

//HDF5
#include "hdf5.h"
#include "hdf5_hl.h"

//Boost
#include <boost/math/special_functions/bessel.hpp>

//Bright Libs
#include "FCComp.h"
#include "MassStream.h"
#include "isoname.h"

/***********************************************/
/*** Reactor1G Component Class and Functions ***/
/***********************************************/

typedef std::map<int, std::vector<double> > IsoFluenceDict;
typedef IsoFluenceDict::iterator IsoFluenceIter;

typedef std::vector<double> Data_F_;

typedef std::set<int> IsoSet;
typedef IsoSet::iterator IsoIter;

class FluencePoint
{
public:
    // Constructors
    FluencePoint();
    ~FluencePoint();

    // Attributes
    int f;
    double F;
    double m;
};


//struct ReactorParameters
class ReactorParameters
{
public:
    // Constructors
    ReactorParameters();
    ~ReactorParameters();

    // Attributes
    int batches;
    double flux;
    std::map<std::string, double> FuelForm;
    std::map<std::string, double> CoolantForm;
    double FuelDensity;
    double CoolantDensity;
    double pnl;
    double BUt;
    bool useDisadvantage;
    std::string LatticeType;
    bool HydrogenRescale;
    double Radius;
    double Length;
    double open_slots;
    double total_slots;

};


class Reactor1G : public FCComp
{
/** Reactor class
 *  Basic One-Group Reactor Model.  Computes one Burnup Calculationn with the option of computing output isotopics.
 *  Specific reactor types inherit this class and change base parameters.
 */
protected:
    //Protected data
    IsoSet I;						//Set of isotopes that may be in ms_feed.
    IsoSet J;						//Set of isotopes that may be in ms_prod.

    //Thermal XS data is read in from static KAERI Data
    //Only read in if the disadvantage factor will be used.
    std::map<int, double> sigma_a_therm;			//Microscopic Thermal Absorption XS 
    std::map<int, double> sigma_s_therm;			//Microscopic Thermal Scattering XS 

public:
    //Reactor1G Constructors
    Reactor1G ();
    Reactor1G (std::string);
    Reactor1G (std::set<std::string>, std::string = "");
    Reactor1G (ReactorParameters, std::string = "");
    Reactor1G (ReactorParameters, std::set<std::string>, std::string = "");
    ~Reactor1G ();
    
    //Public data
    int B; 								//Total number of fuel loading batches
    double phi;							//Flux used for Fluence
    std::map<std::string, double> fuel_chemical_form;			//Chemical form of Fuel as Dictionary.  Keys are elements or isotopes while values represent mass weights.  Denote heavy metal by key "IHM".
    std::map<std::string, double> coolant_chemical_form;		//Same a fuel chemical form but for coolant.  Should not have "IHM"
    double rhoF;							//Fuel Density
    double rhoC; 							//Coolant Density
    double P_NL; 							//Non-Leakage Probability
    double target_BU; 						//Target Discharge Burnup, only used for graphing inside of this component
    bool use_zeta; 							//Boolean value on whether or not the disadvantage factor should be used
    std::string lattice_flag;						//lattice_flag Type (Planar || Spherical || Cylindrical)
    bool rescale_hydrogen_xs;						//Rescale the Hydrogen-1 XS?

    double r; 							//Fuel region radius
    double l; 							//Unit cell side length
    double S_O; 							//Number of open slots in fuel assembly
    double S_T; 							//Total number of Fuel assembly slots.
    double VF; 							//Fuel Volume
    double VC;							//Coolant Volume

    std::string libfile;						//Path where the reactor's HDF5 library
    std::vector<double> F;   					//Fluence in [n/kb]
    IsoFluenceDict BUi_F_;						//Burnup [MWd/kgIHM]
    IsoFluenceDict pi_F_; 						//Production rate [n/s]
    IsoFluenceDict di_F_;		      	   			//Destruction rate [n/s]
    std::map<int, IsoFluenceDict> Tij_F_;				//Transformation Matrix [kg_i/kgIHM]

    double A_IHM;							//Atomic weight of IHM
    double MWF;							//Fuel Molecular Weight
    double MWC;							//Coolant Molecular Weight
    CompDict niF;							//Fuel Atom Number Weight
    CompDict niC;							//Coolant Atom Number Weight
    CompDict miF;							//Fuel Mass Weight
    CompDict miC;							//Coolant Mass Weight
    CompDict NiF;							//Fuel Number Density
    CompDict NiC;							//Coolant Number Density

    Data_F_ dF_F_;							//Fuel Destuction Rate d^F(F)
    Data_F_ dC_F_;							//Coolant Destuction Rate d^C(F)
    Data_F_ BU_F_;							//Burnup BU(F)
    Data_F_ P_F_;							//Production Rate P(F)
    Data_F_ D_F_;							//Destruction Rate P(F)
    Data_F_ k_F_;							//k(F) -- almost meaningless
    std::map<int, Data_F_ > Mj_F_;					//Transmuted to Matrix Mj(F)
    Data_F_ zeta_F_;						//Disadvantage Factor zeta(F)

    int fd;								//Lower index of discharge fluence
    double Fd;							//Discharge Fluence
    double BUd;							//Discharge Burnup
    double k;							//Multiplication factor 

    MassStream InU; 						//Input Uranium MassStream
    MassStream InTRU; 						//Input Transuranic MassStream
    MassStream InLAN; 						//Input Lanthinide MassStream
    MassStream InACT; 						//Input Actinide MassStream
    MassStream OutU; 						//Output Uranium MassStream
    MassStream OutTRU; 						//Output Transuranic MassStream
    MassStream OutLAN; 						//Output Lanthinide MassStream
    MassStream OutACT; 						//Output Actinide MassStream

    double deltaR;                          // The production rate subtracted by the destruction rate at target_BU
    double TruCR;							//Transuranic Conversion Ratio

    Data_F_ SigmaFa_F_;						//Fuel Macro Absorption XS, Sigma^F_a(F)
    Data_F_ SigmaFtr_F_;						//Fuel Macro Transport XS, Sigma^F_tr(F)
    Data_F_ kappaF_F_;						//Fuel kappa, kappa^F(F)

    Data_F_ SigmaCa_F_;						//Coolant Macro Absorption XS, Sigma^C_a(F)
    Data_F_ SigmaCtr_F_;						//Coolant Macro Transport XS, Sigma^C_tr(F)
    Data_F_ kappaC_F_;						//Coolant kappa, kappa^C(F)

    Data_F_ LatticeE_F_;						//Values for lattice function E(F)
    Data_F_ LatticeF_F_;						//Values for lattice function F(F)


    //Public access functions
    void         initialize(ReactorParameters);
    void         loadLib(std::string libfile = "Reactor.h5");
    void         foldMassWeights();

    void         mkMj_F_();
    void         mkMj_Fd_();

    void         calcOutIso();
    void         calcSubStreams();
    double       calcTruCR();

    double       calc_deltaR();
    double       calc_deltaR(CompDict);
    double       calc_deltaR(MassStream);

    FluencePoint FluenceAtBU(double);
    double       batchAve(double, std::string = "K");
    double       batchAveK(double);
    void         BUd_BisectionMethod();
    void         Run_PNL(double);
    void         Calibrate_PNL_2_BUd();

    MassStream   calc ();
    MassStream   calc (CompDict);
    MassStream   calc (MassStream);	

    void LatticeEPlanar(double, double);
    void LatticeFPlanar(double, double);
    void LatticeESpherical(double, double);
    void LatticeFSpherical(double, double);
    void LatticeECylindrical(double, double);
    void LatticeFCylindrical(double, double);

    void         calcZeta();
    void         calcZetaPlanar();
    void         calcZetaSpherical();
    void         calcZetaCylindrical();
};

/******************/
/*** Exceptions ***/
/******************/

class BadFuelForm : public std::exception
{
//Exception for valid fuel form.
public:
    BadFuelForm () {};
    ~BadFuelForm () throw () {};

    static char * name ()
    {
        return (char *) "BadFuelForm";
    };

    virtual const char* what() const throw()
    {
        if (1 < FCComps::verbosity)
        {
            std::cout << "\n";
            std::cout << "***********************************************\n";
            std::cout << "* WARNING: FUEL COMPOSITION NOT COMPUTABLE!!! *\n";
            std::cout << "***********************************************\n";
            std::cout << "\n";
        };
        std::string BFFstr ("FUEL COMPOSITION NOT COMPUTABLE!");
        return (const char *) BFFstr.c_str();
    };
};

class BisectionMethodNotPerformed : public std::exception
{
//Exception for when the bisection method is not calculated.
public:
    BisectionMethodNotPerformed ()
    {
        errstr = "Bisection method was not performed.";
    };
    BisectionMethodNotPerformed (std::string calctype)
    {
        errstr = "Bisection method durring " + calctype + " calculation was not performed.";
    };
    ~BisectionMethodNotPerformed () throw () {};

    static char * name ()
    {
        return (char *) "BisectionMethodNotPerformed";
    };

    virtual const char* what() const throw()
    {
        if (1 < FCComps::verbosity)
        {
            std::cout << "\n";
            std::cout << "**************\n";
            std::cout << "* WARNING!!! *\n";
            std::cout << "**************\n";
            std::cout << "\n";
            std::cout << errstr << "\n";
            std::cout << "\n";
        };
        return (const char *) errstr.c_str();
    };
private:
    std::string errstr;
};

#endif
