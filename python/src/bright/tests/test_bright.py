"""Bright general tests"""

from unittest import TestCase
import nose 

from nose.tools import assert_equal, assert_not_equal, assert_raises, raises, \
    assert_almost_equal, assert_true, assert_false

import os
import warnings
import tables as tb
import numpy as np

import isoname
import bright

bright_config = bright.bright_config

class TestBright(TestCase):
    """Tests that the Bright general functions work."""

    def test_bright_start(self):
        current = os.getenv("BRIGHT_DATA")
        os.environ["BRIGHT_DATA"] = "/foo/bar"
        new = os.getenv("BRIGHT_DATA")
        bright.bright_start()
        assert_equal(new, "/foo/bar")
        os.environ["BRIGHT_DATA"] = current

    def test_track_isos(self):
        old_isolist = bright_config.track_isos
        new_isolist = isoname.mixed_2_zzaaam_List([92235, "H1"])
        bright_config.track_isos = set(new_isolist)
        assert_equal(bright_config.track_isos, set([10010, 922350]))
        bright_config.track_isos = old_isolist

    def test_verbosity(self):
        old_verbosity = bright_config.verbosity
        bright_config.verbosity = 100
        assert_equal(bright_config.verbosity, 100)
        bright.verbosity = old_verbosity

    def test_write_hdf5(self):
        old_write = bright_config.write_hdf5
        bright_config.write_hdf5 = False
        assert_false(bright_config.write_hdf5)
        bright_config.write_hdf5 = 1
        assert_true(bright_config.write_hdf5)
        bright_config.write_hdf5 = old_write

    def test_write_text(self):
        old_write = bright_config.write_text
        bright_config.write_text = False
        assert_false(bright_config.write_text)
        bright_config.write_text = 1
        assert_true(bright_config.write_text)
        bright_config.write_text = old_write
        
    def test_output_filename(self):
        assert_equal( bright_config.output_filename, 'fuel_cycle.h5')
        bright_config.output_filename = 'new_name.h5'
        assert_equal( bright_config.output_filename, 'new_name.h5')
        

class TestLoadFromHDF5(TestCase):
    """Tests track_isos can be loaded from an HDF5 file."""

    @classmethod
    def setup_class(cls):
        f = tb.openFile('isos.h5', 'w')
        f.createArray(f.root, "ToIsos", np.array([92235, 922380, 10010]), "ToIsos")
        f.createArray(f.root, "NotIsos", np.array([92235, 922380, 10010]), "NotIsos")
        f.close()

    @classmethod
    def teardown_class(cls):
        os.remove('isos.h5')

    def test_load_track_isos_hdf5_1(self):
        old_isos = bright_config.track_isos
        bright_config.track_isos = set([80160])
        bright.load_track_isos_hdf5('isos.h5')
        assert_equal(bright_config.track_isos, set([10010, 80160, 922350, 922380]))
        bright_config.track_isos = old_isos

    def test_load_track_isos_hdf5_2(self):
        old_isos = bright_config.track_isos
        bright_config.track_isos = set([80160])
        bright.load_track_isos_hdf5('isos.h5', '/NotIsos')
        assert_equal(bright_config.track_isos, set([10010, 80160, 922350, 922380]))
        bright_config.track_isos = old_isos

    def test_load_track_isos_hdf5_3(self):
        old_isos = bright_config.track_isos
        bright_config.track_isos = set([80160])
        bright.load_track_isos_hdf5('isos.h5', '', True)
        assert_equal(bright_config.track_isos, set([10010, 922350, 922380]))
        bright_config.track_isos = old_isos

    def test_load_track_isos_hdf5_4(self):
        old_isos = bright_config.track_isos
        bright_config.track_isos = set([80160])
        bright.load_track_isos_hdf5('isos.h5', '/NotIsos', True)
        assert_equal(bright_config.track_isos, set([10010, 922350, 922380]))
        bright_config.track_isos = old_isos

class TestLoadFromText(TestCase):
    """Tests track_isos can be loaded from a text file."""

    @classmethod
    def setup_class(cls):
        with open('isos.txt', 'w') as f:
            f.write('U-235, 922380\n10010}')

    @classmethod
    def teardown_class(cls):
        os.remove('isos.txt')

    def test_load_track_isos_text_1(self):
        old_isos = bright_config.track_isos
        bright_config.track_isos = set([80160])
        bright.load_track_isos_text('isos.txt')
        assert_equal(bright_config.track_isos, set([10010, 80160, 922350, 922380]))
        bright_config.track_isos = old_isos

    def test_load_track_isos_text_2(self):
        old_isos = bright_config.track_isos
        bright_config.track_isos = set([80160])
        bright.load_track_isos_text('isos.txt', True)
        assert_equal(bright_config.track_isos, set([10010, 922350, 922380]))
        bright_config.track_isos = old_isos

if __name__ == "__main__":
    nose.main()
