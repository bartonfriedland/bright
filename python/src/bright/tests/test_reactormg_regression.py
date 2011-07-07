import os

import numpy as np
import tables as tb

from bright import *
import isoname
from mass_stream import MassStream

import serpent
import matplotlib.pyplot as plt
from matplotlib import rc

rc('text', usetex=True)
rc('font', family='roman')

from char.m2py import convert_res, convert_dep
from metasci.graph import StairStepEnergy

# Hack to use origen as burnup calculator
from origen_reactormg import OrigenReactorMG
ReactorMG = OrigenReactorMG

def run_serpent():
    #bu_file = 'serp_bu_10'
    #xs_file = 'serp_xs_10'

    bu_file = 'serp_bu_19'
    xs_file = 'serp_xs_19'

    if (not os.path.exists(bu_file + '_res.py')) or (not os.path.exists(bu_file + '_dep.py')):
        serpent.main(bu_file)
        convert_res(bu_file + '_res.m')
        convert_dep(bu_file + '_dep.m')

    if (not os.path.exists(xs_file + '_res.py')):
        serpent.main(xs_file)
        convert_res(xs_file + '_res.m')

    res_bu = {}
    execfile(bu_file + '_res.py', {}, res_bu)

    dep_bu = {}
    execfile(bu_file + '_dep.py', {}, dep_bu)

    res_xs = {}
    execfile(xs_file + '_res.py', {}, res_xs)

    #
    # Renomralize Mass
    #
    mw_conversion = 270.0 / (237.0 * dep_bu['TOT_VOLUME'] * 10.7)
    mw = dep_bu['TOT_MASS'] * mw_conversion

    iso_LL = {}
    iso_index = {}
    for iso_zz in dep_bu['ZAI']:
        # Find valid isotope indeces
        try:
            iso_LL[iso_zz] = isoname.mixed_2_LLAAAM(int(iso_zz))
        except:
            continue
        iso_index[iso_zz] = dep_bu['i{0}'.format(iso_zz)] - 1

    # Caclulate actual mass of isotopes present
    mass = mw[iso_index.values()].sum(axis=0)
    mass = mass / mass[0]

    dep_bu['mw'] = mw
    dep_bu['mass'] = mass
    dep_bu['iso_index'] = iso_index

    return res_bu, dep_bu, res_xs


def run_reactormg():
    # Init bright
    libfile = os.getenv("BRIGHT_DATA") + 'lwr_mg.h5'
    load_track_isos_hdf5(libfile)
    bright_config.write_text = False
    bright_config.write_hdf5 = False
    bright_config.verbosity = 100

    # Init reactor paramters
    rp = lwr_defaults()
    rp.batches = 3
    rp.flux = 4*(10**14)

    rp.fuel_form = {"IHM": 1.0, "O16": 2.0}
    rp.cladding_form = {"ZR93": 0.5, "ZR95": 0.5}
    rp.coolant_form = {"H1": 2.0, "O16": 1.0}

    rp.fuel_density = 10.7
    rp.cladding_density = 5.87
    rp.coolant_density = 0.73

    #rp.pnl = 0.98
    rp.pnl = 0.95
    rp.BUt = 50.0
    rp.use_disadvantage_factor = True
    rp.lattice_type = 'Spherical'
    rp.lattice_type = 'Planar'
    rp.rescale_hydrogen = True
    rp.burnup_via_constant = 'power'

    rp.fuel_radius = 0.412
    rp.void_radius = 0.4205
    rp.clad_radius = 0.475
    rp.unit_cell_pitch = 1.33

    rp.open_slots = 25
    rp.total_slots = 289

    bt = list(np.linspace(0.0, 365.0, 10))
    #bt.insert(1, 1.0)
    bt.insert(1, 4.0)
    bt = np.array(bt)
    rp.burn_times = bt

    # Init mass stream
    leu = MassStream({922340: 0.01, 922350: 0.05, 922380: 0.94})

    # Init ReactorMG
    rmg = ReactorMG(reactor_parameters=rp, name="rmg")
    rmg.loadlib(libfile)

    # Run the reactor
    #rmg.calc(leu)
    rmg.ms_feed = leu
    rmg.burnup_core()
    return rmg


def test_regression():
    res_bu, dep_bu, res_xs = run_serpent()
    rmg = run_reactormg()
    return rmg, res_bu, dep_bu, res_xs


def make_graphs(r, s, diff, serr=None, name=""):
    global burn_times
    plt.clf()

    # make the compare plot
    if serr is None:
        plt.plot(burn_times, s, 'k-', label="Serpent")
    else:
        plt.errorbar(burn_times, s, serr, color='k', label="Serpent")
    
    plt.errorbar(burn_times, r, diff*r, color='r', label="RMG")

    plt.xlabel("burn time [days]")
    plt.ylabel(name)
    plt.legend(loc=0)
    plt.savefig(name.split('[')[0].replace(' ', '_') + '.png')
    plt.savefig(name.split('[')[0].replace(' ', '_') + '.eps')
    plt.clf()

    plt.hist(burn_times, weights=diff, align='mid', color='g', rwidth=0.95)
    plt.xlabel("burn time [days]")
    plt.ylabel(name + " Relative Error")
    plt.savefig(name.split('[')[0].replace(' ', '_') + '_rel_err.png')
    plt.savefig(name.split('[')[0].replace(' ', '_') + '_rel_err.eps')
    plt.clf()


def make_flux_graphs(r, s, diff, serr=None, name=""):
    global E_g
    plt.clf()

    u_g = np.log(E_g[0] / E_g)
    u_diff = u_g[1:] - u_g[:-1]
    u_norm = u_diff[0] / u_diff

    # make the compare plot
    gkw = {'datalabel': "Serpent",
           'colorline': 'k-',
           'scale': 'log',
           'ylabel': name,
           'write': False, 
           'show': False, 
           'ymin': 0.0,
           'ymax': 0.25,
           }
    StairStepEnergy((s * u_norm)[::-1], E_g[::-1], **gkw)

    gkw['datalabel'] = "RMG"
    gkw['colorline'] = 'r-'
    gkw['write'] = True 
    gkw['name'] = name.split('[')[0].replace(' ', '_')
    StairStepEnergy((r * u_norm)[::-1], E_g[::-1], **gkw)    

    """plt.hist(-1 * (E_g[1:] - E_g[:-1])[::-1], weights=diff[::-1], align='mid', color='g', rwidth=0.95)
    plt.xscale('log')
    plt.xlabel("Energy [MeV]")
    plt.ylabel(name + " Relative Error")
    plt.savefig(name.split('[')[0].replace(' ', '_') + '_rel_err.png')
    plt.savefig(name.split('[')[0].replace(' ', '_') + '_rel_err.eps')
    plt.clf()

    plt.hist(-1 * (E_g[1:] - E_g[:-1])[::-1], weights=diff[::-1] * r[::-1], align='mid', color='g', rwidth=0.95)
    plt.xscale('log')
    plt.xlabel("Energy [MeV]")
    plt.ylabel(name + " Flux Weighted Relative Error")
    plt.savefig(name.split('[')[0].replace(' ', '_') + '_fw_rel_err.png')
    plt.savefig(name.split('[')[0].replace(' ', '_') + '_fw_rel_err.eps')
    plt.clf()"""


def calc_diff(r, s, serr=None, name=""):
    print "Summary for {0}:".format(name)
    print "Reactor: "
    print repr(r)
    print "Serpent: "
    print repr(s)
    print "Fractional Diff: "
    diff = r / s - 1.0
    diff[np.isnan(diff)] = 0.0
    print repr(diff)
    print

    try:
        make_graphs(r, s, diff, serr, name)
    except Exception as e:
        print e

    return r, s, diff

def compare_1g_xs(rmg):
    f = tb.openFile('benchmark_xs.h5', 'r')

    isos_LL = f.root.transmute_isos_LL.read()
    isos_zz = f.root.transmute_isos_zz.read()
    isos = zip(isos_LL, isos_zz)

    r_norm_phi = rmg.phi_tg / rmg.phi_t[:, np.newaxis]

    reactions = ['sigma_t', 'sigma_f', 'sigma_gamma', 'sigma_2n', 'sigma_a', #'sigma_s', 
                 'sigma_alpha', 'sigma_gamma_x', 'sigma_2n_x']

    sig = {}
    for rx in reactions:
        r_sig = getattr(rmg, rx + '_itg')
        s_sig = getattr(f.root, rx)

        for iso_LL, iso_zz in isos:
            r_xs = (r_sig[iso_zz] * r_norm_phi).sum(axis=1)
            s_xs = (getattr(s_sig, iso_LL) * r_norm_phi).sum(axis=1)
            diff = r_xs / s_xs - 1.0
            diff[np.isnan(diff)] = 0.0
            sig[rx, iso_LL] = (r_xs, s_xs, diff)

    f.close()

    return sig

def sort_sig(sig):
    key_func = lambda x: abs(x[1][2]).max()
    s = sorted(sig.items(), key=key_func, reverse=True)
    return s

    
if __name__ == "__main__":
    rmg, res_bu, dep_bu, res_xs = test_regression()

    burn_times = rmg.burn_times
    time_range = [0] + range(2, len(burn_times))
    burn_times = burn_times[time_range]

    E_g = rmg.E_g

    r_k, s_k, diff_k = calc_diff(rmg.k_t[1:], res_bu['SIX_FF_KEFF'][1:, 0], res_bu['SIX_FF_KEFF'][1:, 1], "k")

    r_norm_phi = rmg.phi_tg / rmg.phi_t[:, np.newaxis]
    s_norm_phi = res_bu['FLUX'][:, 2::2] / res_bu['FLUX'][:, np.newaxis, 0]
    serr_phi = res_bu['FLUX'][:, 3::2] / res_bu['FLUX'][:, np.newaxis, 0]
    r_phi, s_phi, diff_phi = calc_diff(r_norm_phi[1:], s_norm_phi[1:], "Normalized Flux")

    for t in range(len(burn_times)):
        print "Making flux figure for time t = {0}".format(t)
        make_flux_graphs(r_phi[t], s_phi[t], diff_phi[t], serr=serr_phi[t], name="Normalized Flux at {0} days".format(int(burn_times[t])))


    r_total, s_total, diff_total = calc_diff(rmg.Sigma_t_fuel_tg[0], res_xs['TOTXS'][0, 2::2], res_xs['TOTXS'][0, 3::2], name="Total XS")
    make_flux_graphs(r_total, s_total, diff_total, name="Total XS")

    r_fiss, s_fiss, diff_fiss = calc_diff(rmg.Sigma_f_fuel_tg[0], res_xs['FISSXS'][0, 2::2], res_xs['FISSXS'][0, 3::2], "Fission XS")
    make_flux_graphs(r_fiss, s_fiss, diff_fiss, name="Fission XS")

    r_abs, s_abs, diff_abs = calc_diff(rmg.Sigma_a_fuel_tg[0], res_xs['ABSXS'][0, 2::2], res_xs['ABSXS'][0, 3::2],"Absorption XS")
    make_flux_graphs(r_abs, s_abs, diff_abs, name="Absorption XS")

    r_gamma, s_gamma, diff_gamma = calc_diff(rmg.Sigma_gamma_fuel_tg[0], res_xs['CAPTXS'][0, 2::2], res_xs['CAPTXS'][0, 3::2], "Capture XS")
    make_flux_graphs(r_gamma, s_gamma, diff_gamma, name="Capture XS")

    T_it = rmg.T_it

    bu_mass_norm = np.array([sum([dep_bu['mw'][dep_bu['iso_index'][key]][n] for key in dep_bu['iso_index'].keys() if 860000 < key]) for n in range(dep_bu['mw'].shape[1])])
    dep_bu['mw'] = dep_bu['mw'] / bu_mass_norm[0]
    bu_mass_norm = bu_mass_norm / bu_mass_norm[0]

    # Patch known isos
    dep_bu['mw'][dep_bu['iso_index'][922340]] *= (0.01 / dep_bu['mw'][dep_bu['iso_index'][922340]][0])
    dep_bu['mw'][dep_bu['iso_index'][922380]] *= (0.94 / dep_bu['mw'][dep_bu['iso_index'][922380]][0])

    nuclides = ['U234',  'U235',  'U236',  'U238',  'NP237', 'PU238', 'PU239', 'PU240', 'PU241', 'PU242', 
                'AM241', 'AM242', 'AM243', 'CM242', 'CM243', 'CM244', 'CM245', 'CM246', 'KR81',  'KR85',  
                'SR90',  'ZR90',  'ZR93',  'TC99',  'I129',  'PD107', 'CS134', 'CS135', 'CS137']


    for nuc_LL in nuclides:
        nuc_zz = isoname.LLAAAM_2_zzaaam(nuc_LL)
        nuc_ind = dep_bu['iso_index'][nuc_zz]
        r_i, s_i, diff_i = calc_diff(T_it[nuc_zz][time_range], dep_bu['mw'][nuc_ind][time_range], name=nuc_LL + " Mass Fraction [kg/kgIHM]")

    mss = [MassStream({i: T_it[i][t] for i in T_it.keys()}) for t in time_range]
    r_mass, s_mass, diff_mass = calc_diff(np.array([ms.mass for ms in mss]), bu_mass_norm, name="Mass")

    sig = compare_1g_xs(rmg)
    u = sort_sig(sig)
    
    print "Max fractional deviations"
    for key, value in u[:20]:
        rx, iso = key
        r, s, diff = value
        print iso, rx, max(abs(diff))
