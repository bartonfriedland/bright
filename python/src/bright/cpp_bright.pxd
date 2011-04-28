"""C++ wrapper for isoname library."""
from libcpp.map cimport map
from libcpp.set cimport set
from libcpp.vector cimport vector

cimport std
cimport cpp_mass_stream
cimport mass_stream

cdef extern from "../../../cpp/bright.h" namespace "bright":
    std.string BRIGHT_DATA

    void bright_start()


cdef extern from "../../../cpp/FCComps.h" namespace "FCComps":
    set[int] track_isos
    vector[int] track_isos_order

    void load_track_isos_hdf5(std.string, std.string, bint)
    void load_track_isos_text(std.string, bint)

    void sort_track_isos()

    int verbosity
    bint write_hdf5
    bint write_text

    std.string output_filename


cdef extern from "../../../cpp/FCComp.h":
    cdef cppclass FCComp:
        # Constructors
        FCComp()
        FCComp(std.string)
        FCComp(set[std.string], std.string)

        # Attributes
        std.string name 
        std.string natural_name

        cpp_mass_stream.MassStream ms_feed
        cpp_mass_stream.MassStream ms_prod

        map[std.string, double] params_prior_calc
        map[std.string, double] params_after_calc

        int pass_num
        set[std.string] track_params

        # Methods
        void calc_params()
        void write_ms_pass()
        void write_params_pass()
        void write_text()
        void write_hdf5()
        void write()
        cpp_mass_stream.MassStream calc()


cdef extern from "../../../cpp/Enrichment.h":

    cdef cppclass EnrichmentParameters:
        # Constructors
        EnrichmentParameters()

        # Attributes
        double alpha_0
        double Mstar_0

        int j
        int k

        double N0
        double M0

        double xP_j
        double xW_j

    EnrichmentParameters fillUraniumEnrichmentDefaults()

    cdef cppclass Enrichment(FCComp): 
        # Constructors
        Enrichment()
        Enrichment(std.string)
        Enrichment(EnrichmentParameters, std.string)

        # Attributes
        double alpha_0
        double Mstar_0
        double Mstar
        cpp_mass_stream.MassStream ms_tail

        int j
        int k
        double xP_j
        double xW_j

        double N
        double M
        double N0
        double M0

        double TotalPerFeed
        double SWUperFeed
        double SWUperProduct

        # Methods
        void initialize(EnrichmentParameters)
        void calc_params ()
        cpp_mass_stream.MassStream calc ()
        cpp_mass_stream.MassStream calc (map[int, double])
        cpp_mass_stream.MassStream calc (cpp_mass_stream.MassStream)

        double PoverF (double, double, double)
        double WoverF (double, double, double)

        # The following are methods I am too lazy to expose to Python
        # FIXME
        #double get_alphastar_i (double)

        #double get_Ei (double)
        #double get_Si (double)
        #void FindNM()

        #double xP_i(int)
        #double xW_i(int)
        #void SolveNM()
        #void Comp2UnitySecant()
        #void Comp2UnityOther()
        #double deltaU_i_OverG(int)
        #void LoverF()
        #void MstarOptimize()



cdef extern from "../../../cpp/Reprocess.h":

    cdef cppclass Reprocess(FCComp):
        # Constructors
        Reprocess()
        Reprocess(map[int, double], std.string)

        # Attributes
        map[int, double] sepeff

        # Methods
        void initialize(map[int, double])
        void calc_params()
        cpp_mass_stream.MassStream calc()
        cpp_mass_stream.MassStream calc(map[int, double])
        cpp_mass_stream.MassStream calc(cpp_mass_stream.MassStream)


cdef extern from "../../../cpp/Storage.h":

    cdef cppclass Storage(FCComp):
        # Constructors
        Storage()
        Storage(std.string)

        # Attributes
        double decay_time

        # Methods
        void calc_params()
        cpp_mass_stream.MassStream calc()
        cpp_mass_stream.MassStream calc(map[int, double])
        cpp_mass_stream.MassStream calc(cpp_mass_stream.MassStream)
        cpp_mass_stream.MassStream calc(double)
        cpp_mass_stream.MassStream calc(map[int, double], double)
        cpp_mass_stream.MassStream calc(cpp_mass_stream.MassStream, double)



cdef extern from "../FluencePoint.h":

    cdef cppclass FluencePoint:
        # Constructors        
        FluencePoint()

        # Attributes
        int f
        double F
        double m


cdef extern from "../../../cpp/ReactorParameters.h":

    cdef cppclass ReactorParameters:
        # Constructors        
        ReactorParameters()

        # Attributes
        int batches
        double flux

        map[std.string, double] fuel_form
        map[std.string, double] coolant_form

        double fuel_density
        double cladding_density
        double coolant_density

        double pnl
        double BUt
        double specific_power
        int burn_regions
        vector[double] burn_times

        bint use_disadvantage_factor
        std.string lattice_type
        bint rescale_hydrogen

        double fuel_radius
        double void_radius
        double clad_radius
        double unit_cell_pitch

        double open_slots
        double total_slots

    ReactorParameters fill_lwr_defaults()

    ReactorParameters fill_fr_defaults()


cdef extern from "../../../cpp/Reactor1G.h":

    cdef cppclass Reactor1G(FCComp):
        # Constructors        
        Reactor1G()
        Reactor1G(std.string)
        Reactor1G(set[std.string], std.string)
        Reactor1G(ReactorParameters, std.string)
        Reactor1G(ReactorParameters, set[std.string], std.string)

        # Attributes
        int B
        double phi
        map[std.string, double] fuel_chemical_form
        map[std.string, double] coolant_chemical_form
        double rhoF
        double rhoC
        double P_NL
        double target_BU
        bint use_zeta
        std.string lattice_flag
        bint rescale_hydrogen_xs

        double r
        double l
        double S_O
        double S_T
        double VF
        double VC

        std.string libfile
        vector[double] F
        map[int, vector[double]] BUi_F_
        map[int, vector[double]] pi_F_
        map[int, vector[double]] di_F_
        map[int, map[int, vector[double]]] Tij_F_

        double A_IHM
        double MWF
        double MWC
        map[int, double] niF
        map[int, double] niC
        map[int, double] miF
        map[int, double] miC
        map[int, double] NiF
        map[int, double] NiC

        vector[double] dF_F_
        vector[double] dC_F_
        vector[double] BU_F_
        vector[double] P_F_
        vector[double] D_F_
        vector[double] k_F_
        map[int, vector[double]] Mj_F_
        vector[double] zeta_F_

        int fd
        double Fd
        double BUd
        double k

        cpp_mass_stream.MassStream ms_feed_u
        cpp_mass_stream.MassStream ms_feed_tru
        cpp_mass_stream.MassStream ms_feed_lan
        cpp_mass_stream.MassStream ms_feed_act
        cpp_mass_stream.MassStream ms_prod_u
        cpp_mass_stream.MassStream ms_prod_tru
        cpp_mass_stream.MassStream ms_prod_lan
        cpp_mass_stream.MassStream ms_prod_act

        double deltaR
        double tru_cr

        vector[double] SigmaFa_F_
        vector[double] SigmaFtr_F_
        vector[double] kappaF_F_

        vector[double] SigmaCa_F_
        vector[double] SigmaCtr_F_
        vector[double] kappaC_F_

        vector[double] lattice_E_F_
        vector[double] lattice_F_F_

        # Methods
        void initialize(ReactorParameters)
        void loadlib(std.string)
        void fold_mass_weights()

        void calc_Mj_F_()
        void calc_Mj_Fd_()

        void calc_ms_prod()
        void calcSubStreams()
        double calc_tru_cr()

        double calc_deltaR()
        double calc_deltaR(map[int, double])
        double calc_deltaR(cpp_mass_stream.MassStream)

        FluencePoint fluence_at_BU(double)
        double batch_average(double, std.string)
        double batch_average_k(double)
        void BUd_bisection_method()
        void run_P_NL(double)
        void calibrate_P_NL_to_BUd()

        cpp_mass_stream.MassStream calc()
        cpp_mass_stream.MassStream calc(map[int, double])
        cpp_mass_stream.MassStream calc(cpp_mass_stream.MassStream)

        void lattice_E_planar(double, double)
        void lattice_F_planar(double, double)
        void lattice_E_spherical(double, double)
        void lattice_F_spherical(double, double)
        void lattice_E_cylindrical(double, double)
        void lattice_F_cylindrical(double, double)

        void calc_zeta()
        void calc_zeta_planar()
        void calc_zeta_spherical()
        void calc_zeta_cylindrical()




cdef extern from "../../../cpp/LightWaterReactor1G.h":

    cdef cppclass LightWaterReactor1G(Reactor1G):
        # Constructors        
        LightWaterReactor1G()
        LightWaterReactor1G(std.string, std.string)
        LightWaterReactor1G(ReactorParameters, std.string)
        LightWaterReactor1G(std.string, ReactorParameters, std.string)

        # Methods
        void calc_params()




cdef extern from "../../../cpp/FastReactor1G.h":

    cdef cppclass FastReactor1G(Reactor1G):
        # Constructors        
        FastReactor1G()
        FastReactor1G(std.string, std.string)
        FastReactor1G(ReactorParameters, std.string)
        FastReactor1G(std.string, ReactorParameters, std.string)

        # Methods
        void calc_params()



cdef extern from "../../../cpp/FuelFabrication.h":

    cdef cppclass FuelFabrication(FCComp):
        # Constructors        
        FuelFabrication()
        FuelFabrication(std.string)
        FuelFabrication(set[std.string], std.string)
        FuelFabrication(map[std.string, mass_stream.msp], map[std.string, double], Reactor1G, std.string)
        FuelFabrication(map[std.string, mass_stream.msp], map[std.string, double], Reactor1G, set[std.string], std.string)

        # Attributes
        map[std.string, mass_stream.msp] mass_streams
        map[std.string, double] mass_weights_in
        map[std.string, double] mass_weights_out
        map[std.string, double] deltaRs

        Reactor1G reactor

        # Methods
        void initialize(map[std.string, mass_stream.msp], map[std.string, double], Reactor1G)
        void calc_params()

        void calc_deltaRs()
        cpp_mass_stream.MassStream calc_core_input()
        void calc_mass_ratios()

        cpp_mass_stream.MassStream calc()
        cpp_mass_stream.MassStream calc(map[std.string, mass_stream.msp], map[std.string, double], Reactor1G)



cdef extern from "../../../cpp/ReactorMG.h":

    cdef cppclass ReactorMG(FCComp):
        # Constructors        
        ReactorMG()
        ReactorMG(std.string)
        ReactorMG(set[std.string], std.string)
        ReactorMG(ReactorParameters, std.string)
        ReactorMG(ReactorParameters, set[std.string], std.string)

        # Attributes
        int B
        double flux

        map[std.string, double] chemical_form_fuel
        map[std.string, double] chemical_form_clad
        map[std.string, double] chemical_form_cool

        double rho_fuel
        double rho_clad
        double rho_cool

        double P_NL
        double target_BU
        double specific_power
        int burn_regions
        int S
        double burn_time
        int bt_s
        vector[double] burn_times

        bint use_zeta
        std.string lattice_flag
        bint rescale_hydrogen_xs

        double r_fuel
        double r_void
        double r_clad
        double pitch

        double S_O
        double S_T
        double V_fuel
        double V_clad
        double V_cool

        std.string libfile

        set[int] I
        set[int] J
        vector[int] J_order
        map[int, int] J_index


        # Perturbation table goes here
        int nperturbations
        map[std.string, vector[double]] perturbed_fields

        int G
        vector[double] E_g
        vector[vector[double]] phi_g
        vector[double] phi
        vector[double] Phi
        vector[double] time0
        vector[double] BU0

        map[int, vector[double]] Ti0
        map[int, vector[vector[double]]] sigma_t_pg
        map[int, vector[vector[double]]] nubar_sigma_f_pg
        map[int, vector[vector[double]]] chi_pg
        map[int, vector[vector[vector[double]]]] sigma_s_pgh
        map[int, vector[vector[double]]] sigma_f_pg
        map[int, vector[vector[double]]] sigma_gamma_pg
        map[int, vector[vector[double]]] sigma_2n_pg
        map[int, vector[vector[double]]] sigma_3n_pg
        map[int, vector[vector[double]]] sigma_alpha_pg
        map[int, vector[vector[double]]] sigma_proton_pg
        map[int, vector[vector[double]]] sigma_gamma_x_pg
        map[int, vector[vector[double]]] sigma_2n_x_pg

        vector[double] A_HM_t
        vector[double] MW_fuel_t
        vector[double] MW_clad_t
        vector[double] MW_cool_t
        map[int, vector[double]] n_fuel_it
        map[int, vector[double]] n_clad_it
        map[int, vector[double]] n_cool_it
        map[int, vector[double]] m_fuel_it
        map[int, vector[double]] m_clad_it
        map[int, vector[double]] m_cool_it
        map[int, vector[double]] N_fuel_it
        map[int, vector[double]] N_clad_it
        map[int, vector[double]] N_cool_it

        vector[vector[double]] phi_tg
        vector[double] phi_t
        vector[double] Phi_t
        vector[double] BU_t

        map[int, vector[double]] T_it
        map[int, vector[vector[double]]] sigma_t_itg
        map[int, vector[vector[double]]] nubar_sigma_f_itg
        map[int, vector[vector[double]]] chi_itg
        map[int, vector[vector[vector[double]]]] sigma_s_itgh
        map[int, vector[vector[double]]] sigma_f_itg
        map[int, vector[vector[double]]] sigma_gamma_itg
        map[int, vector[vector[double]]] sigma_2n_itg
        map[int, vector[vector[double]]] sigma_3n_itg
        map[int, vector[vector[double]]] sigma_alpha_itg
        map[int, vector[vector[double]]] sigma_proton_itg
        map[int, vector[vector[double]]] sigma_gamma_x_itg
        map[int, vector[vector[double]]] sigma_2n_x_itg

        vector[vector[double]] Sigma_t_tg
        vector[vector[double]] nubar_Sigma_f_tg
        vector[vector[double]] chi_tg
        vector[vector[vector[double]]] Sigma_s_tgh
        vector[vector[double]] Sigma_f_tg
        vector[vector[double]] Sigma_gamma_tg
        vector[vector[double]] Sigma_2n_tg
        vector[vector[double]] Sigma_3n_tg
        vector[vector[double]] Sigma_alpha_tg
        vector[vector[double]] Sigma_proton_tg
        vector[vector[double]] Sigma_gamma_x_tg
        vector[vector[double]] Sigma_2n_x_tg

        vector[int] nearest_neighbors

        vector[double] k_t

        int td_n
        double td
        double BUd
        double Phid
        double k

        cpp_mass_stream.MassStream ms_feed_u
        cpp_mass_stream.MassStream ms_feed_tru
        cpp_mass_stream.MassStream ms_feed_lan
        cpp_mass_stream.MassStream ms_feed_act
        cpp_mass_stream.MassStream ms_prod_u
        cpp_mass_stream.MassStream ms_prod_tru
        cpp_mass_stream.MassStream ms_prod_lan
        cpp_mass_stream.MassStream ms_prod_act

        double deltaR
        double tru_cr

        # Methods
        void initialize(ReactorParameters)
        void loadlib(std.string)
        void interpolate_cross_sections()
        void calc_mass_weights()
        void fold_mass_weights()
        void assemble_multigroup_matrices()
        void calc_criticality()

        void burnup_core()

        void calc_nearest_neighbors()

        void calc_T_itd()

        void calc_ms_prod()
        void calcSubStreams()
        double calc_tru_cr()

        FluencePoint fluence_at_BU(double)
        double batch_average_k(double)
        void BUd_bisection_method()
        void run_P_NL(double)
        void calibrate_P_NL_to_BUd()

        cpp_mass_stream.MassStream calc()
        cpp_mass_stream.MassStream calc(map[int, double])
        cpp_mass_stream.MassStream calc(cpp_mass_stream.MassStream)
