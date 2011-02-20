"""LightWaterReactor1G Component tests"""

from unittest import TestCase
import nose 

from nose.tools import assert_equal, assert_not_equal, assert_raises, raises, \
    assert_almost_equal, assert_true, assert_false

import os
import warnings
import tables as tb
import numpy as np

import bright
import mass_stream


LightWaterReactor1G = bright.LightWaterReactor1G
MassStream = mass_stream.MassStream
bright_config = bright.bright_config

def general_teardown():
    for f in os.listdir('.'):
        if "Isos.txt" in f:
            os.remove(f)
        elif "Params.txt" in f:
            os.remove(f)
        elif f in [".h5", "lwr.h5"]:
            os.remove(f)

class TestLightWaterReactorConstructors(TestCase):
    """Tests that the storage component constructors work."""

    @classmethod
    def teardown_class(cls):
        general_teardown()

    def test_lwr_defaults(self):
        lwrd = bright.lwr_defaults()
        assert_equal(lwrd.batches, 3)
        assert_equal(lwrd.flux, 4.0*(10.0**14))
        assert_equal(lwrd.fuel_form["IHM"], 1.0)
        assert_equal(lwrd.fuel_form["O16"], 2.0)
        assert_equal(lwrd.coolant_form["O16"], 1.0)
        assert_equal(lwrd.coolant_form["H1"], 2.0)
        assert_equal(lwrd.coolant_form["B10"], 0.199 * 550 * (10.0**-6))
        assert_equal(lwrd.coolant_form["B11"], 0.801 * 550 * (10.0**-6))
        assert_equal(lwrd.fuel_density, 10.7)
        assert_equal(lwrd.coolant_density, 0.73)
        assert_equal(lwrd.pnl, 0.98)
        assert_equal(lwrd.BUt, 0.0)
        assert_true(lwrd.use_disadvantage_factor)
        assert_equal(lwrd.lattice_type, "Cylindrical")
        assert_true(lwrd.rescale_hydrogen)
        assert_equal(lwrd.radius, 0.412)
        assert_equal(lwrd.pitch, 1.33)
        assert_equal(lwrd.open_slots, 25.0)
        assert_equal(lwrd.total_slots, 289.0)

    def test_LightWaterReactor1G_1(self):
        lwr = LightWaterReactor1G()
        assert_equal(lwr.name, '')
        assert_equal(lwr.track_params, set(["ACT", "BUd", "FP", "LAN", "TRU", "U"]))
        assert_equal(lwr.B, 3)
        assert_equal(lwr.phi, 4.0*(10.0**14))
        assert_equal(lwr.fuel_chemical_form["IHM"], 1.0)
        assert_equal(lwr.fuel_chemical_form["O16"], 2.0)
        assert_equal(lwr.coolant_chemical_form["O16"], 1.0)
        assert_equal(lwr.coolant_chemical_form["H1"], 2.0)
        assert_equal(lwr.coolant_chemical_form["B10"], 0.199 * 550 * (10.0**-6))
        assert_equal(lwr.coolant_chemical_form["B11"], 0.801 * 550 * (10.0**-6))
        assert_equal(lwr.rhoF, 10.7)
        assert_equal(lwr.rhoC, 0.73)
        assert_equal(lwr.P_NL, 0.98)
        assert_equal(lwr.target_BU, 0.0)
        assert_true(lwr.use_zeta)
        assert_equal(lwr.lattice_flag, "Cylindrical")
        assert_true(lwr.rescale_hydrogen_xs)
        assert_equal(lwr.r, 0.412)
        assert_equal(lwr.l, 1.33)
        assert_equal(lwr.S_O, 25.0)
        assert_equal(lwr.S_T, 289.0)

    def test_LightWaterReactor1G_2(self):
        lf = os.getenv("BRIGHT_DATA") + "/LWR.h5"
        lwr = LightWaterReactor1G(libfile=lf)
        assert_equal(lwr.libfile, lf)
        assert_equal(lwr.name, '')
        assert_equal(lwr.track_params, set(["ACT", "BUd", "FP", "LAN", "TRU", "U"]))
        assert_equal(lwr.B, 3)
        assert_equal(lwr.phi, 4.0*(10.0**14))
        assert_equal(lwr.fuel_chemical_form["IHM"], 1.0)
        assert_equal(lwr.fuel_chemical_form["O16"], 2.0)
        assert_equal(lwr.coolant_chemical_form["O16"], 1.0)
        assert_equal(lwr.coolant_chemical_form["H1"], 2.0)
        assert_equal(lwr.coolant_chemical_form["B10"], 0.199 * 550 * (10.0**-6))
        assert_equal(lwr.coolant_chemical_form["B11"], 0.801 * 550 * (10.0**-6))
        assert_equal(lwr.rhoF, 10.7)
        assert_equal(lwr.rhoC, 0.73)
        assert_equal(lwr.P_NL, 0.98)
        assert_equal(lwr.target_BU, 0.0)
        assert_true(lwr.use_zeta)
        assert_equal(lwr.lattice_flag, "Cylindrical")
        assert_true(lwr.rescale_hydrogen_xs)
        assert_equal(lwr.r, 0.412)
        assert_equal(lwr.l, 1.33)
        assert_equal(lwr.S_O, 25.0)
        assert_equal(lwr.S_T, 289.0)

    def test_LightWaterReactor1G_3(self):
        lf = os.getenv("BRIGHT_DATA") + "/LWR.h5"
        lwr = LightWaterReactor1G(libfile=lf, name="lwr")
        assert_equal(lwr.libfile, lf)
        assert_equal(lwr.name, 'lwr')
        assert_equal(lwr.track_params, set(["ACT", "BUd", "FP", "LAN", "TRU", "U"]))
        assert_equal(lwr.B, 3)
        assert_equal(lwr.phi, 4.0*(10.0**14))
        assert_equal(lwr.fuel_chemical_form["IHM"], 1.0)
        assert_equal(lwr.fuel_chemical_form["O16"], 2.0)
        assert_equal(lwr.coolant_chemical_form["O16"], 1.0)
        assert_equal(lwr.coolant_chemical_form["H1"], 2.0)
        assert_equal(lwr.coolant_chemical_form["B10"], 0.199 * 550 * (10.0**-6))
        assert_equal(lwr.coolant_chemical_form["B11"], 0.801 * 550 * (10.0**-6))
        assert_equal(lwr.rhoF, 10.7)
        assert_equal(lwr.rhoC, 0.73)
        assert_equal(lwr.P_NL, 0.98)
        assert_equal(lwr.target_BU, 0.0)
        assert_true(lwr.use_zeta)
        assert_equal(lwr.lattice_flag, "Cylindrical")
        assert_true(lwr.rescale_hydrogen_xs)
        assert_equal(lwr.r, 0.412)
        assert_equal(lwr.l, 1.33)
        assert_equal(lwr.S_O, 25.0)
        assert_equal(lwr.S_T, 289.0)

    def test_LightWaterReactor1G_4(self):
        rp = bright.lwr_defaults()
        rp.BUt = 50.0
        lwr = LightWaterReactor1G(reactor_parameters=rp)
        assert_equal(lwr.name, '')
        assert_equal(lwr.track_params, set(["ACT", "BUd", "FP", "LAN", "TRU", "U"]))
        assert_equal(lwr.B, 3)
        assert_equal(lwr.phi, 4.0*(10.0**14))
        assert_equal(lwr.fuel_chemical_form["IHM"], 1.0)
        assert_equal(lwr.fuel_chemical_form["O16"], 2.0)
        assert_equal(lwr.coolant_chemical_form["O16"], 1.0)
        assert_equal(lwr.coolant_chemical_form["H1"], 2.0)
        assert_equal(lwr.coolant_chemical_form["B10"], 0.199 * 550 * (10.0**-6))
        assert_equal(lwr.coolant_chemical_form["B11"], 0.801 * 550 * (10.0**-6))
        assert_equal(lwr.rhoF, 10.7)
        assert_equal(lwr.rhoC, 0.73)
        assert_equal(lwr.P_NL, 0.98)
        assert_equal(lwr.target_BU, 50.0)
        assert_true(lwr.use_zeta)
        assert_equal(lwr.lattice_flag, "Cylindrical")
        assert_true(lwr.rescale_hydrogen_xs)
        assert_equal(lwr.r, 0.412)
        assert_equal(lwr.l, 1.33)
        assert_equal(lwr.S_O, 25.0)
        assert_equal(lwr.S_T, 289.0)

    def test_LightWaterReactor1G_5(self):
        rp = bright.lwr_defaults()
        rp.BUt = 50.0
        lwr = LightWaterReactor1G(reactor_parameters=rp, name='lwr')
        assert_equal(lwr.name, 'lwr')
        assert_equal(lwr.track_params, set(["ACT", "BUd", "FP", "LAN", "TRU", "U"]))
        assert_equal(lwr.B, 3)
        assert_equal(lwr.phi, 4.0*(10.0**14))
        assert_equal(lwr.fuel_chemical_form["IHM"], 1.0)
        assert_equal(lwr.fuel_chemical_form["O16"], 2.0)
        assert_equal(lwr.coolant_chemical_form["O16"], 1.0)
        assert_equal(lwr.coolant_chemical_form["H1"], 2.0)
        assert_equal(lwr.coolant_chemical_form["B10"], 0.199 * 550 * (10.0**-6))
        assert_equal(lwr.coolant_chemical_form["B11"], 0.801 * 550 * (10.0**-6))
        assert_equal(lwr.rhoF, 10.7)
        assert_equal(lwr.rhoC, 0.73)
        assert_equal(lwr.P_NL, 0.98)
        assert_equal(lwr.target_BU, 50.0)
        assert_true(lwr.use_zeta)
        assert_equal(lwr.lattice_flag, "Cylindrical")
        assert_true(lwr.rescale_hydrogen_xs)
        assert_equal(lwr.r, 0.412)
        assert_equal(lwr.l, 1.33)
        assert_equal(lwr.S_O, 25.0)
        assert_equal(lwr.S_T, 289.0)

    def test_LightWaterReactor1G_6(self):
        lf = os.getenv("BRIGHT_DATA") + "/LWR.h5"
        rp = bright.lwr_defaults()
        rp.BUt = 50.0
        lwr = LightWaterReactor1G(libfile=lf, reactor_parameters=rp)
        assert_equal(lwr.libfile, lf)
        assert_equal(lwr.name, '')
        assert_equal(lwr.track_params, set(["ACT", "BUd", "FP", "LAN", "TRU", "U"]))
        assert_equal(lwr.B, 3)
        assert_equal(lwr.phi, 4.0*(10.0**14))
        assert_equal(lwr.fuel_chemical_form["IHM"], 1.0)
        assert_equal(lwr.fuel_chemical_form["O16"], 2.0)
        assert_equal(lwr.coolant_chemical_form["O16"], 1.0)
        assert_equal(lwr.coolant_chemical_form["H1"], 2.0)
        assert_equal(lwr.coolant_chemical_form["B10"], 0.199 * 550 * (10.0**-6))
        assert_equal(lwr.coolant_chemical_form["B11"], 0.801 * 550 * (10.0**-6))
        assert_equal(lwr.rhoF, 10.7)
        assert_equal(lwr.rhoC, 0.73)
        assert_equal(lwr.P_NL, 0.98)
        assert_equal(lwr.target_BU, 50.0)
        assert_true(lwr.use_zeta)
        assert_equal(lwr.lattice_flag, "Cylindrical")
        assert_true(lwr.rescale_hydrogen_xs)
        assert_equal(lwr.r, 0.412)
        assert_equal(lwr.l, 1.33)
        assert_equal(lwr.S_O, 25.0)
        assert_equal(lwr.S_T, 289.0)

    def test_LightWaterReactor1G_7(self):
        lf = os.getenv("BRIGHT_DATA") + "/LWR.h5"
        rp = bright.lwr_defaults()
        rp.BUt = 50.0
        lwr = LightWaterReactor1G(libfile=lf, reactor_parameters=rp, name='lwr')
        assert_equal(lwr.libfile, lf)
        assert_equal(lwr.name, 'lwr')
        assert_equal(lwr.track_params, set(["ACT", "BUd", "FP", "LAN", "TRU", "U"]))
        assert_equal(lwr.B, 3)
        assert_equal(lwr.phi, 4.0*(10.0**14))
        assert_equal(lwr.fuel_chemical_form["IHM"], 1.0)
        assert_equal(lwr.fuel_chemical_form["O16"], 2.0)
        assert_equal(lwr.coolant_chemical_form["O16"], 1.0)
        assert_equal(lwr.coolant_chemical_form["H1"], 2.0)
        assert_equal(lwr.coolant_chemical_form["B10"], 0.199 * 550 * (10.0**-6))
        assert_equal(lwr.coolant_chemical_form["B11"], 0.801 * 550 * (10.0**-6))
        assert_equal(lwr.rhoF, 10.7)
        assert_equal(lwr.rhoC, 0.73)
        assert_equal(lwr.P_NL, 0.98)
        assert_equal(lwr.target_BU, 50.0)
        assert_true(lwr.use_zeta)
        assert_equal(lwr.lattice_flag, "Cylindrical")
        assert_true(lwr.rescale_hydrogen_xs)
        assert_equal(lwr.r, 0.412)
        assert_equal(lwr.l, 1.33)
        assert_equal(lwr.S_O, 25.0)
        assert_equal(lwr.S_T, 289.0)


class TestLightWaterReactor1GAttributes(TestCase):
    """Tests that the fuel cycle component attributes work."""

    @classmethod
    def teardown_class(cls):
        general_teardown()

    def test_track_params(self):
        lwr = LightWaterReactor1G()
        assert_equal(lwr.track_params, set(["ACT", "BUd", "FP", "LAN", "TRU", "U"]))
        lwr.track_params = set(["Mass"])
        assert_equal(lwr.track_params, set(["Mass"]))

class TestLightWaterReactor1GMethods(TestCase):
    """Tests that the fuel cycle component methods work."""

    @classmethod
    def teardown_class(cls):
        general_teardown()

    def test_calc_params(self):
        lf = os.getenv("BRIGHT_DATA") + "/LWR.h5"
        bright.load_track_isos_hdf5(lf)
        rp = bright.lwr_defaults()
        rp.BUt = 50.0
        lwr = LightWaterReactor1G(libfile=lf, reactor_parameters=rp, name='lwr')
        lwr.calc(MassStream({922350: 0.05, 922380:0.95}))
        lwr.calc_params()
        assert_equal(lwr.params_prior_calc["BUd"],  0.0)
        assert_equal(lwr.params_after_calc["BUd"], lwr.BUd)
        assert_equal(lwr.params_prior_calc["U"],  lwr.ms_feed_u.mass)
        assert_equal(lwr.params_after_calc["U"], lwr.ms_prod_u.mass)
        assert_equal(lwr.params_prior_calc["TRU"],  lwr.ms_feed_tru.mass)
        assert_equal(lwr.params_after_calc["TRU"], lwr.ms_prod_tru.mass)
        assert_equal(lwr.params_prior_calc["ACT"],  lwr.ms_feed_act.mass)
        assert_equal(lwr.params_after_calc["ACT"], lwr.ms_prod_act.mass)
        assert_equal(lwr.params_prior_calc["LAN"],  lwr.ms_feed_lan.mass)
        assert_equal(lwr.params_after_calc["LAN"], lwr.ms_prod_lan.mass)
        assert_equal(lwr.params_prior_calc["FP"],  1.0 - lwr.ms_feed_act.mass - lwr.ms_feed_lan.mass)
        assert_equal(lwr.params_after_calc["FP"], 1.0 - lwr.ms_prod_act.mass - lwr.ms_prod_lan.mass)
        

# Put Integral tests here, if desired.


if __name__ == "__main__":
    nose.main()
