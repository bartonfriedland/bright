"""Generates a Cython wrapper for various Bright classes from either
description dictionaries or from header files.
"""
from copy import deepcopy

from bright.apigen.utils import indent, expand_default_args
from bright.apigen.typesystem import cython_ctype, cython_cimport_tuples, \
    cython_cimports, register_class, cython_cytype

AUTOGEN_WARNING = \
"""################################################
#                 Warning!                     #
# This file has been auto-generated by Bright. #
# Do not modify!!!                             #
#                                              #
#                                              #
#                    Come on, guys. I mean it! #
################################################
"""

_cpppxd_template = AUTOGEN_WARNING + \
"""{cimports}

cdef extern from "{header_filename}" namespace "{namespace}":

    cdef cppclass {name}({parents}):
        # constructors
{constructors_block}

        # attributes
{attrs_block}

        # methods
{methods_block}
"""


def gencpppxd(desc, exception_type='+'):
    """Generates a cpp_*.pxd Cython header file for exposing C/C++ data from to 
    other Cython wrappers based off of a dictionary (desc)ription.
    """
    d = {'parents': ', '.join(desc['parents']), }
    copy_from_desc = ['name', 'namespace', 'header_filename']
    for key in copy_from_desc:
        d[key] = desc[key]
    inc = set(['c'])

    alines = []
    cimport_tups = set()
    attritems = sorted(desc['attrs'].items())
    for aname, atype in attritems:
        if aname.startswith('_'):
            continue
        alines.append("{0} {1}".format(cython_ctype(atype), aname))
        cython_cimport_tuples(atype, cimport_tups, inc)
    d['attrs_block'] = indent(alines, 8)

    mlines = []
    clines = []
    estr = str() if exception_type is None else  ' except {0}'.format(exception_type)
    methitems = sorted(expand_default_args(desc['methods'].items()))
    for mkey, mrtn in methitems:
        mname, margs = mkey[0], mkey[1:]
        if mname.startswith('_'):
            continue
        argfill = ", ".join([cython_ctype(a[1]) for a in margs])
        for a in margs:
            cython_cimport_tuples(a[1], cimport_tups, inc)
        line = "{0}({1}){2}".format(mname, argfill, estr)
        if mrtn is None:
            # this must be a constructor
            clines.append(line)
        else:
            # this is a normal method
            rtype = cython_ctype(mrtn)
            cython_cimport_tuples(mrtn, cimport_tups, inc)
            line = rtype + " " + line
            mlines.append(line)
    d['methods_block'] = indent(mlines, 8)
    d['constructors_block'] = indent(clines, 8)

    d['cimports'] = "\n".join(sorted(cython_cimports(cimport_tups)))
    cpppxd = _cpppxd_template.format(**d)
    if 'cpppxd_filename' not in desc:
        desc['cpppxd_filename'] = 'cpp_{0}.pxd'.format(d['name'].lower())
    return cpppxd
    


_pxd_template = AUTOGEN_WARNING + \
"""{cimports}

cdef class {name}({parents}):
    cdef {name_type} * _inst
    cdef public bint _free_inst
"""


def genpxd(desc):
    """Generates a *.pxd Cython header file for exposing C/C++ data from to 
    other Cython wrappers based off of a dictionary (desc)ription.
    """
    if 'pxd_filename' not in desc:
        desc['pxd_filename'] = '{0}.pxd'.format(desc['name'].lower())

    d = {'parents': ', '.join([cython_cytype(p) for p in desc['parents']]), }
    copy_from_desc = ['name',]
    for key in copy_from_desc:
        d[key] = desc[key]

    cimport_tups = set()
    for parent in desc['parents']:
        cython_cimport_tuples(parent, cimport_tups, set(['cy']))

    from_cpppxd = desc['cpppxd_filename'].rsplit('.', 1)[0]
    register_class(desc['name'], cython_cimport=from_cpppxd,
                   cython_c_type="{0}.{1}".format(from_cpppxd, desc['name']),)
    d['name_type'] = cython_ctype(desc['name'])
    cython_cimport_tuples(desc['name'], cimport_tups, set(['c']))

    d['cimports'] = "\n".join(sorted(cython_cimports(cimport_tups)))
    pxd = _pxd_template.format(**d)
    return pxd
    

_pyx_template = AUTOGEN_WARNING + \
'''"""{module_docstring}
"""
{cimports}

{imports}

cdef class {name}({parents}):
{class_docstring}

    # constuctors
    def __cinit__(self, *args, **kwargs):
        self._inst = NULL
        self._free_inst = True


{pyconstructor}


    def __dealloc__(self):
        if self._free_inst:
            free(self._inst)


    # attributes
{attrs_block}


    # methods
{methods_block}
'''


def genpyx(desc):
    """Generates a *.pyx Cython wrapper implementation for exposing a C/C++ 
    class based off of a dictionary (desc)ription.
    """
    d = {'parents': ', '.join([cython_cytype(p) for p in desc['parents']]), }
    copy_from_desc = ['name', 'namespace', 'header_filename']
    for key in copy_from_desc:
        d[key] = desc[key]

    alines = []
    cimport_tups = set()
    attritems = sorted(desc['attrs'].items())
    for aname, atype in attritems:
        if aname.startswith('_'):
            continue
        alines.append("{0} {1}".format(cython_ctype(atype), aname))
        cython_cimport_tuples(atype, cimport_tups)    
    d['attrs_block'] = indent(alines, 8)

    mlines = []
    clines = []
    estr = str() if exception_type is None else  ' except {0}'.format(exception_type)
    methitems = sorted(expand_default_args(desc['methods'].items()))
    for mkey, mrtn in methitems:
        mname, margs = mkey[0], mkey[1:]
        if mname.startswith('_'):
            continue
        argfill = ", ".join([cython_ctype(a[1]) for a in margs])
        for a in margs:
            cython_cimport_tuples(a[1], cimport_tups)
        line = "{0}({1}){2}".format(mname, argfill, estr)
        if mrtn is None:
            # this must be a constructor
            clines.append(line)
        else:
            # this is a normal method
            rtype = cython_ctype(mrtn)
            cython_cimport_tuples(mrtn, cimport_tups)
            line = rtype + " " + line
            mlines.append(line)
    d['methods_block'] = indent(mlines, 8)
    d['constructors_block'] = indent(clines, 8)

    d['cimports'] = "\n".join(sorted(cython_cimports(cimport_tups)))
    cpppxd = _cpppxd_template.format(**d)
    if 'cpppxd_filename' not in desc:
        desc['cpppxd_filename'] = 'cpp_{0}.pxd'.format(d['name'].lower())
    return cpppxd
