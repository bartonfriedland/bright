"""This module creates descriptions of C++ classes from source code, by using 
external parsers (GCC-XML, Clang AST) and the type system.

:author: Anthony Scopatz <scopatz@gmail.com>

Descriptions
============
A key component of API wrapper generation is having a a top-level, abstract 
representation of the software that is being wrapped.  In C++ there are three
basic constructs which may be wrapped: variables, functions, and classes.  
Here we restrict ourselves to wrapping classes (though ironically these are
the most complex of the three).  

The abstract representation of a C++ class is known as a **description** (abbr. 
*desc*).  This description is simply a Python dictionary with a specific structure.
This structure makes heavy use of the type system to declare the types of all needed
parameters.

Top-Level Keys
--------------
The following are valid top-level keys in a description dictionary: 
name, parents, namespace, attrs, methods, docstrings, and extra.

:name: str, the class name
:parents: list of strings, the immediate parents of the class (not grandparents)
:namespace: str or None, the namespace or module the class lives in.
:attrs: dict or dict-like, the names of the attributes (member variables) of the
    class mapped to their types, given in the format of the type system.
:methods: dict or dict-like, similar to the attrs except that the keys are now
    function signatures and the values are the method return types.  The signatures
    themselves are tuples. The first element of these tuples is the method name.
    The remaining elements (if any) are the function arguments.  Arguments are 
    themselves length-2 or -3 tuples whose first elements are the argument names, 
    the second element is the argument type, and the third element (if present) is
    the default value.  If the return type is None (as opposed to 'void'), then 
    this method is assumed to be a constructor or destructor.
:docstrings: dict, optional, this dictionary is meant for storing documentation 
    strings.  All values are thus either strings or dictionaries of strings.  
    Valid keys include: module, class, attrs, and methods.  The attrs and methods
    keys are dictionaries which may include keys that mirror the top-level keys of
    the same name.
:extra: dict, optional, this stores arbitrary metadata that may be used with 
    different backends. It is not added by any auto-describe routine but may be
    inserted later if needed.  One example use case is that the Cython generation
    looks for the pyx, pxd, and cpppxd keys for strings of supplemental Cython 
    code to insert directly into the wrapper.

Toaster Example
---------------
Suppose we have a C++ class called Toaster that takes bread and makes delicious 
toast.  A valid description dictionary for this class would be as follows::

    desc = {
        'name': 'Toaster',
        'parents': ['FCComp'],
        'namespace': 'bright',
        'attrs': {
            'n_slices': 'int32',
            'rate': 'float64',
            'toastiness': 'str',
            },
        'methods': {
            ('Toaster',): None,
            ('Toaster', ('name', 'str', '""')): None,
            ('Toaster', ('paramtrack', ('set', 'str')), ('name', 'str', '""')): None,
            ('~Toaster',): None, 
            ('tostring',): 'str', 
            ('calc',): 'Material',
            ('calc', ('incomp', ('map', 'int32', 'float64'))): 'Material',
            ('calc', ('mat', 'Material')): 'Material',
            ('write', ('filename', 'str', '"toaster.txt"')): 'void',
            ('write', ('filename', ('char' '*'), '"toaster.txt"')): 'void',
            },
        'docstrings': {
            'module': "This is where Toaster lives.",
            'class': "I am a toaster!",
            'attrs': {
                'n_slices': 'the number of slices',
                'rate': 'the toast rate',
                'toastiness': 'the toastiness level',
                },
            'methods': {
                'Toaster': "Make me a toaster!",
                '~Toaster': "Noooooo",
                'tostring': "string representation of the toaster",
                'calc': "actually makes the toast.",
                'write': "persists the toaster state."
                },
            },
        'extra': {
            'pyx': 'toaster = Toaster()  # make toaster singleton'
            },
        }

Automatic Description Generation
--------------------------------
The purpose of this module is to create description dictionaries like those
above by automatically parsing C++ classes.  In theory this parsing step may 
be handled by visiting any syntax tree of C++ code.  Two options were pursued here:
GCC-XML and the Python bindings to the Clang AST.  Unfortunately, the Clang AST
bindings lack exposure for template argument types.  These are needed to use any
standard library containers.  Thus while the Clang method was pursued to a mostly
working state, the GCC-XML version is the only fully functional automatic describer
for the moment.

Automatic Descriptions API
==========================
"""
import os
import re
from copy import deepcopy
import linecache
import subprocess
import itertools
from pprint import pprint, pformat

# CLang conditional imports
#try:
#    from clang import cindex
#except ImportError:
#    try:
#        from clang.v3_1 import cindex
#    except ImportError:
#        pass

# GCC-XML conditional imports
try:
    from lxml import etree
except ImportError:
    try:
        # Python 2.5
        import xml.etree.cElementTree as etree
    except ImportError:
        try:
          # Python 2.5
          import xml.etree.ElementTree as etree
        except ImportError:
            try:
                # normal cElementTree install
                import cElementTree as etree
            except ImportError:
                try:
                  # normal ElementTree install
                  import elementtree.ElementTree as etree
                except ImportError:
                    pass
import tempfile

# Other imports
import pyne

RE_INT = re.compile('^\d+$')
RE_FLOAT = re.compile('^[+-]?\.?\d+\.?\d*?(e[+-]?\d+)?$')


def describe(filename, classname=None, parser='gccxml', verbose=False):
    """Automatically describes a class in a file.  This is the main entry point.

    Parameters
    ----------
    filename : str
        The path to the file.
    classname : str or None, optional
        The classname, a 'None' value will attempt to infer this from the 
        filename.
    parser : str, optional
        The parser / AST to use to use for the C++ file.  Currently only
        'clang' and 'gccxml' are supported, though others may be 
        implemented in the future.
    verbose : bool, optional
        Flag to diplay extra information while describing the class.

    Returns
    -------
    desc : dict
        A dictionary describing the class which may be used to generate
        API bindings.
    """
    if classname is None:
        classname = os.path.split(filename)[-1].rsplit('.', 1)[0].capitalize()
    describers = {'clang': clang_describe, 'gccxml': gccxml_describe}
    describer = describers[parser]
    desc = describer(filename, classname, verbose=verbose)
    return desc


#
# GCC-XML Describers
#


def gccxml_describe(filename, classname, verbose=False):
    """Use GCC-XML to describe the class.

    Parameters
    ----------
    filename : str
        The path to the file.
    classname : str or None, optional
        The classname, a 'None' value will attempt to infer this from the 
        filename.
    verbose : bool, optional
        Flag to diplay extra information while describing the class.

    Returns
    -------
    desc : dict
        A dictionary describing the class which may be used to generate
        API bindings.
    """
    f = tempfile.NamedTemporaryFile()
    cmd = ['gccxml', filename, '-fxml=' + f.name, '-I' + pyne.includes]
    if verbose:
        print " ".join(cmd)
    subprocess.call(cmd)
    f.seek(0)
    root = etree.parse(f)
    onlyin = set([filename, filename.replace('.cpp', '.h')])
    #onlyin = set([filename.replace('.cpp', '.h')])
    describer = GccxmlClassDescriber(classname, root, onlyin=onlyin, verbose=verbose)
    describer.visit()
    f.close()
    return describer.desc


class GccxmlClassDescriber(object):
    """Class used to generate descriptions via GCC-XML output."""

    _integer_types = frozenset(['int32', 'int64', 'uint32', 'uint64'])

    def __init__(self, classname, root=None, onlyin=None, verbose=False):
        """Parameters
        -------------
        classname : str
            The classname, this may not have a None value.
        root : element tree node, optional
            The root element node of the class or struct to describe.  
        onlyin :  str, optional
            Filename the class or struct described must live in.  Prevents 
            finding classes of the same name coming from other libraries.
        verbose : bool, optional
            Flag to display extra information while visiting the class.

        """
        self.desc = {'name': classname, 'attrs': {}, 'methods': {}}
        self.classname = classname
        self.verbose = verbose
        self._root = root
        onlyin = [onlyin] if isinstance(onlyin, basestring) else onlyin
        onlyin = set() if onlyin is None else set(onlyin)
        self.onlyin = set([root.find("File[@name='{0}']".format(oi)).attrib['id'] \
                           for oi in onlyin])
        self._currfunc = []  # this must be a stack to handle nested functions
        self._currfuncsig = None
        self._currclass = []  # this must be a stack to handle nested classes  
        self._level = -1

    def __str__(self):
        return pformat(self.desc)

    def __del__(self):
        linecache.clearcache()

    def _pprint(self, node):
        if self.verbose:
            print("{0}{1} {2}: {3}".format(self._level * "  ", node.tag,
                                       node.attrib.get('id', ''),
                                       node.attrib.get('name', None)))

    def visit(self, node=None):
        """Visits the class node and all sub-nodes, generating the description
        dictionary as it goes.

        Parameters
        ----------
        node : element tree node, optional
            The element tree node to start from.  If this is None, then the 
            top-level class node is found and visited.

        """
        if node is None:
            node = self._root.find("Class[@name='{0}']".format(self.classname))
            if node is None:
                node = self._root.find("Struct[@name='{0}']".format(self.classname))
            assert node.attrib['file'] in self.onlyin
            self.visit_class(node)
        members = node.attrib.get('members', '').strip().split()
        children = [self._root.find(".//*[@id='{0}']".format(m)) for m in members]
        children = [c for c in children if c.attrib['access'] == 'public']
        self._level += 1
        for child in children:
            tag = child.tag.lower()
            meth_name = 'visit_' + tag
            meth = getattr(self, meth_name, None)
            if meth is not None:
                meth(child)
        self._level -= 1

    _template_args = {
        'array': ('value_type',),
        'deque': ('value_type',),
        'forward_list': ('value_type',),
        'list': ('value_type',),
        'map': ('key_type', 'mapped_type'),
        'multimap': ('key_type', 'mapped_type'),
        'set': ('key_type',),
        'multiset': ('key_type',),
        'unordered_map': ('key_type', 'mapped_type'),
        'unordered_multimap': ('key_type', 'mapped_type'),
        'unordered_set': ('key_type',),
        'unordered_multiset': ('key_type',),
        'vector': ('value_type',),
        }

    def _visit_template(self, node):
        name = node.attrib['name']
        members = node.attrib.get('members', '').strip().split()
        children = [child for m in members for child in \
                                self._root.iterfind(".//*[@id='{0}']".format(m))]
        tags = [child.tag for child in children]
        template_name = children[tags.index('Constructor')].attrib['name']  # 'map'
        if template_name == 'basic_string':
            return 'str'
        inst = [template_name]
        self._level += 1
        if template_name in self._template_args:
            for targ in self._template_args[template_name]:
                targ_nodes = [c for c in children if c.attrib['name'] == targ]
                targ_node = targ_nodes[0]
                targ_type = self.type(targ_node.attrib['id'])
                inst.append(targ_type)
        else:
            # fill in later with string parsing of node name if needed.
            pass
        self._level -= 1
        return tuple(inst)

    def visit_class(self, node):
        """visits a class or struct."""
        self._pprint(node)
        name = node.attrib['name']
        self._currclass.append(name)
        if name == self.classname:
            bases = node.attrib['bases'].split()
            bases = None if len(bases) == 0 else [self.type(b) for b in bases]
            self.desc['parents'] = bases
            ns = self.context(node.attrib['context'])
            if ns is not None:
                self.desc['namespace'] = ns
        if '<' in name and name.endswith('>'):
            name = self._visit_template(node)
        self._currclass.pop()
        return name

    visit_struct = visit_class

    def visit_base(self, node):
        """visits a base class."""
        self._pprint(node)
        self.visit(node)  # Walk farther down the tree

    def _visit_func(self, node):
        name = node.attrib['name']
        if name.startswith('_'):
            return
        self._currfunc.append(name)
        self._currfuncsig = []
        self._level += 1
        for child in node.iterfind('Argument'):
            self.visit_argument(child)
        self._level -= 1
        if node.tag == 'Constructor':
            rtntype = None
        elif node.tag == 'Destructor':
            rtntype = None
            self._currfunc[-1] = '~' + self._currfunc[-1]
        else: 
            rtntype = self.type(node.attrib['returns'])
        funcname = self._currfunc.pop()
        if self._currfuncsig is None:
            return 
        key = (funcname,) + tuple(self._currfuncsig)
        self.desc['methods'][key] = rtntype
        self._currfuncsig = None

    def visit_constructor(self, node):
        """visits a class constructor."""
        self._pprint(node)
        self._visit_func(node)

    def visit_destructor(self, node):
        """visits a class destructor."""
        self._pprint(node)
        self._visit_func(node)

    def visit_method(self, node):
        """visits a member function."""
        self._pprint(node)
        self._visit_func(node)

    def visit_argument(self, node):
        """visits a constructor, destructor, or method argument."""
        self._pprint(node)
        name = node.attrib.get('name', None)
        if name is None:
            self._currfuncsig = None
            return 
        tid = node.attrib['type']
        t = self.type(tid)
        default = node.attrib.get('default', None)
        if default is None:
            arg = (name, t)
        else:
            if t in self._integer_types:
                default = int(default)
            arg = (name, t, default)
        self._currfuncsig.append(arg)

    def visit_field(self, node):
        """visits a member variable."""
        self._pprint(node)
        context = self._root.find(".//*[@id='{0}']".format(node.attrib['context']))
        if context.attrib['name'] == self.classname:
            # assert this field is member of the class we are trying to parse
            name = node.attrib['name']
            t = self.type(node.attrib['type'])
            self.desc['attrs'][name] = t

    def visit_typedef(self, node):
        """visits a type definition anywhere."""
        self._pprint(node)
        name = node.attrib.get('name', None)
        if name == 'string':
            return 'str'
        else:
            return self.type(node.attrib['type'])

    _fundemntal_to_base = {
        'char': 'char', 
        'int': 'int32', 
        'long int': 'int64', 
        'unsigned int': 'uint32',
        'long unsigned int': 'uint64',
        'float': 'float32',
        'double': 'float64',
        'complex': 'complex128', 
        'void': 'void', 
        'bool': 'bool',
        }

    def visit_fundamentaltype(self, node):
        """visits a base C++ type, mapping it to the approriate type in the 
        type system."""
        self._pprint(node)
        tname = node.attrib['name']
        t = self._fundemntal_to_base.get(tname, None)
        return t

    def visit_arraytype(self, node):
        """visits an array type and maps it to a '*' refinement type."""
        self._pprint(node)
        baset = self.type(node.attrib['type'])
        # FIXME something involving the min, max, and/or size 
        # attribs needs to also go here.
        t = (baset, '*')
        return t

    def visit_referencetype(self, node):
        """visits a refernece and maps it to a '&' refinement type."""
        self._pprint(node)
        baset = self.type(node.attrib['type'])
        t = (baset, '&')
        return t

    def visit_pointertype(self, node):
        """visits a pointer and maps it to a '*' refinement type."""
        self._pprint(node)
        baset = self.type(node.attrib['type'])
        t = (baset, '*')
        return t

    def type(self, id):
        """Resolves the type from its id and information in the root element tree."""
        node = self._root.find(".//*[@id='{0}']".format(id))
        tag = node.tag.lower()
        meth_name = 'visit_' + tag
        meth = getattr(self, meth_name, None)
        t = None
        if meth is not None:
            self._level += 1
            t = meth(node)
            self._level -= 1
        return t

    def visit_namespace(self, node):
        """visits the namespace that a node is defined in."""
        self._pprint(node)
        name = node.attrib['name']
        return name

    def context(self, id):
        """Resolves the context from its id and information in the element tree."""
        node = self._root.find(".//*[@id='{0}']".format(id))
        tag = node.tag.lower()
        meth_name = 'visit_' + tag
        meth = getattr(self, meth_name, None)
        c = None
        if meth is not None:
            self._level += 1
            c = meth(node)
            self._level -= 1
        return c

#
# Clang Describers
#

def clang_describe(filename, classname, verbose=False):
    """Use clang to describe the class."""
    index = cindex.Index.create()
    tu = index.parse(filename, args=['-cc1', '-I' + pyne.includes])
    #onlyin = set([filename, filename.replace('.cpp', '.h')])
    onlyin = set([filename.replace('.cpp', '.h')])
    describer = ClangClassDescriber(classname, onlyin=onlyin, verbose=verbose)
    describer.visit(tu.cursor)
    from pprint import pprint; pprint(describer.desc)
    return describer.desc


def clang_is_loc_in_range(location, source_range):
    """Returns whether a given Clang location is part of a source file range."""
    if source_range is None or location is None:
        return False
    start = source_range.start
    stop = source_range.end
    file = location.file
    if file != start.file or file != stop.file:
        return False
    line = location.line
    if line < start.line or stop.line < line:
        return False
    return start.column <= location.column <= stop.column


def clang_range_str(source_range):
    """Get the text present on a source range."""
    start = source_range.start
    stop = source_range.end
    filename = start.file.name
    if filename != stop.file.name:
        msg = 'range spans multiple files: {0!r} & {1!r}'
        msg = msg.format(filename, stop.file.name)
        raise ValueError(msg)
    lines = [linecache.getline(filename, n) for n in range(start.line, stop.line+1)]
    lines[-1] = lines[-1][:stop.column-1]  # stop slice must come first for 
    lines[0] = lines[0][start.column-1:]   # len(lines) == 1
    s = "".join(lines)
    return s
    


class ClangClassDescriber(object):

    _funckinds = set(['function_decl', 'cxx_method', 'constructor', 'destructor'])

    def __init__(self, classname, root=None, onlyin=None, verbose=False):
        self.desc = {'name': classname, 'attrs': {}, 'methods': {}}
        self.classname = classname
        self.verbose = verbose
        onlyin = [onlyin] if isinstance(onlyin, basestring) else onlyin
        self.onlyin = set() if onlyin is None else set(onlyin)
        self._currfunc = []  # this must be a stack to handle nested functions
        self._currfuncsig = None
        self._currfuncarg = None
        self._currclass = []  # this must be a stack to handle nested classes  

    def __str__(self):
        return pformat(self.desc)

    def __del__(self):
        linecache.clearcache()

    def _pprint(self, node, typename):
        if self.verbose:
            print("{0}: {1}".format(typename, node.displayname))

    def visit(self, root):
        for node in root.get_children():
            if not node.location.file or node.location.file.name not in self.onlyin:
                continue  # Ignore AST elements not from the desired source files
            kind = node.kind.name.lower()
            meth_name = 'visit_' + kind
            meth = getattr(self, meth_name, None)
            if meth is not None:
                meth(node)
            if hasattr(node, 'get_children'):
                self.visit(node)

            # reset the current function and class
            if kind in self._funckinds and node.spelling == self._currfunc[-1]:
                _key, _value = self._currfuncsig
                _key = (_key[0],) + tuple([tuple(k) for k in _key[1:]])
                self.desc['methods'][_key] = _value
                self._currfunc.pop()
                self._currfuncsig = None
            elif 'class_decl' == kind and node.spelling == self._currclass[-1]:
                self._currclass.pop()
            elif 'unexposed_expr' == kind and node.spelling == self._currfuncarg:
                self._currfuncarg = None

    def visit_class_decl(self, node):
        self._pprint(node, "Class")
        self._currclass.append(node.spelling)  # This could also be node.displayname

    def visit_function_decl(self, node):
        self._pprint(node, "Function")
        self._currfunc.append(node.spelling)  # This could also be node.displayname
        rtntype = node.type.get_result()
        rtnname = ClangTypeVisitor(verbose=self.verbose).visit(rtntype)
        self._currfuncsig = ([node.spelling], rtnname)

    visit_cxx_method = visit_function_decl

    def visit_constructor(self, node):
        self._pprint(node, "Constructor")
        self._currfunc.append(node.spelling)  # This could also be node.displayname
        self._currfuncsig = ([node.spelling], None)

    def visit_destructor(self, node):
        self._pprint(node, "Destructor")
        self._currfunc.append(node.spelling)  # This could also be node.displayname
        self._currfuncsig = ([node.spelling], None)

    def visit_parm_decl(self, node):
        self._pprint(node, "Function Argument")
        name = node.spelling
        t = ClangTypeVisitor(verbose=self.verbose).visit(node)
        self._currfuncsig[0].append([name, t])
        self._currfuncarg = name

    def visit_field_decl(self, node):
        self._pprint(node, "Field")

    def visit_var_decl(self, node):
        self._pprint(node, "Variable")

    def visit_unexposed_expr(self, node):
        self._pprint(node, "Default Parameter (Unexposed Expression)")
        # a little hacky reading from the file, 
        # but Clang doesn't expose this data...
        if self._currfuncsig is None:
            return
        currarg = self._currfuncsig[0][-1]
        assert currarg[0] == self._currfuncarg
        r = node.extent
        default_val = clang_range_str(r)
        if 2 == len(currarg):
            currarg.append(default_val)
        elif 3 == len(currarg):
            currarg[2] = default_val

    ##########

    def visit_type_ref(self, cur):
        self._pprint(cur, "type ref")

    def visit_template_ref(self, cur):
        self._pprint(cur, "template ref")

    def visit_template_type_parameter(self, cur):
        self._pprint(cur, "template type param")

    def visit_template_non_type_parameter(self, cur):
        self._pprint(cur, "template non-type param")

    def visit_template_template_parameter(self, cur):
        self._pprint(cur, "template template param")

    def visit_class_template(self, cur):
        self._pprint(cur, "class template")

    def visit_class_template_partial_specialization(self, cur):
        self._pprint(cur, "class template partial specialization")


def clang_find_class(node, classname, namespace=None):
    """Find the node for a given class underneath the current node.
    """
    if namespace is None:
        nsdecls = [node]
    else:
        nsdecls = [n for n in clang_find_declarations(node) if n.spelling == namespace]
    classnode = None
    for nsnode in nsdecls[::-1]:
        decls = [n for n in clang_find_declarations(nsnode) if n.spelling == classname]
        if 0 < len(decls):
            assert 1 == len(decls)
            classnode = decls[0]
            break
    if classnode is None:
        msg = "the class {0} could not be found in {1}".format(classname, filename)
        raise ValueError(msg)
    return classnode


def clang_find_declarations(node):
    """Finds declarations one level below the Clang node."""
    return [n for n in node.get_children() if n.kind.is_declaration()]

def clang_find_attributes(node):
    """Finds attributes one level below the Clang node."""
    return [n for n in node.get_children() if n.kind.is_attribute()]


class ClangTypeVisitor(object):
    """For a Clang type located at a root node, compute the cooresponding 
    typesystem type.
    """

    def __init__(self, verbose=False):
        self.type = []
        self.verbose = verbose
        self.namespace = []  # this must be a stack to handle nested namespaces
        self._atrootlevel = True
        self._currtype = []

    def _pprint(self, node, typename):
        if self.verbose:
            msg = "{0}: {1}"
            if isinstance(node, cindex.Type):
                msg = msg.format(typename, node.kind.spelling)
            elif isinstance(node, cindex.Cursor):
                msg = msg.format(typename, node.displayname)
            else:
                msg = msg.format(typename, node)
            print(msg)

    def visit(self, root):
        """Takes a root type."""
        atrootlevel = self._atrootlevel

        if isinstance(root, cindex.Type):
            typekind = root.kind.name.lower()
            methname = 'visit_' + typekind
            meth = getattr(self, methname, None)
            if meth is not None and root.kind != cindex.TypeKind.INVALID:
                meth(root)
        elif isinstance(root, cindex.Cursor):
            self.visit(root.type)
            for child in root.get_children():
                kindname = child.kind.name.lower()
                methname = 'visit_' + kindname
                meth = getattr(self, methname, None)
                if meth is not None:
                    meth(child)
                if hasattr(child, 'get_children'):
                    self._atrootlevel = False
                    self.visit(child)
                    self._atrootlevel = atrootlevel
                else:
                    self.visit(child.type)

        if self._atrootlevel:
            currtype = self._currtype
            currtype = currtype[0] if 1 == len(currtype) else tuple(currtype)
            self.type = [self.type, currtype] if isinstance(self.type, basestring) \
                        else list(self.type) + [currtype]
            self._currtype = []
            self.type = self.type[0] if 1 == len(self.type) else tuple(self.type)
            return self.type

    def visit_void(self, typ):
        self._pprint(typ, "void")
        self._currtype.append("void")

    def visit_bool(self, typ):
        self._pprint(typ, "boolean")
        self._currtype.append("bool")

    def visit_char_u(self, typ):
        self._pprint(typ, "character")
        self._currtype.append("char")

    visit_uchar = visit_char_u

    def visit_uint(self, typ):
        self._pprint(typ, "unsigned integer, 32-bit")
        self._currtype.append("uint32")

    def visit_ulong(self, typ):
        self._pprint(typ, "unsigned integer, 64-bit")
        self._currtype.append("uint64")

    def visit_int(self, typ):
        self._pprint(typ, "integer, 32-bit")
        self._currtype.append("int32")

    def visit_long(self, typ):
        self._pprint(typ, "integer, 64-bit")
        self._currtype.append("int64")

    def visit_float(self, typ):
        self._pprint(typ, "float, 32-bit")
        self._currtype.append("float32")

    def visit_double(self, typ):
        self._pprint(typ, "float, 64-bit")
        self._currtype.append("float64")

    def visit_complex(self, typ):
        self._pprint(typ, "complex, 128-bit")
        self._currtype.append("complex128")

    def visit_unexposed(self, typ):
        self._pprint(typ, "unexposed")
        #typ = typ.get_canonical()
        decl = typ.get_declaration()
        self._currtype.append(decl.spelling)
        print "   canon: ",  typ.get_canonical().get_declaration().displayname
        #import pdb; pdb.set_trace()        
        #self.visit(decl)
        #self.visit(typ.get_canonical().get_declaration())
        #self.visit(typ.get_canonical())

    def visit_typedef(self, typ):
        self._pprint(typ, "typedef")
        decl = typ.get_declaration()
        t = decl.underlying_typedef_type
        #self.visit(t.get_canonical())

    def visit_record(self, typ):
        self._pprint(typ, "record")
        self.visit(typ.get_declaration())

    def visit_invalid(self, typ):
        self._pprint(typ, "invalid")
        self.visit(typ.get_declaration())

    def visit_namespace_ref(self, cur):
        self._pprint(cur, "namespace")
        if self._atrootlevel:
            self.namespace.append(cur.displayname)

    def visit_type_ref(self, cur):
        self._pprint(cur, "type ref")
        self._currtype.append(cur.displayname)
#        print "    cur type kin =", cur.type.kind
        #self.visit(cur.type)
        #self.visit(cur)

    def visit_template_ref(self, cur):
        self._pprint(cur, "template ref")
        self._currtype.append(cur.displayname)
        #self.visit(cur)

        #import pdb; pdb.set_trace()
#        self.visit(cur)
        print "   canon: ",  cur.type.get_canonical().get_declaration().displayname

    def visit_template_type_parameter(self, cur):
        self._pprint(cur, "template type param")

    def visit_template_non_type_parameter(self, cur):
        self._pprint(cur, "template non-type param")

    def visit_template_template_parameter(self, cur):
        self._pprint(cur, "template template param")

    def visit_function_template(self, cur):
        self._pprint(cur, "function template")

#    def visit_class_template(self, cur):
#        self._pprint(cur, "class template")

    def visit_class_template_partial_specialization(self, cur):
        self._pprint(cur, "class template partial specialization")

#    def visit_var_decl(self, cur):
#        self._pprint(cur, "variable")



def clang_canonize(t):
    kind = t.kind
    if kind in clang_base_typekinds:
        name = clang_base_typekinds[kind]
    elif kind == cindex.TypeKind.UNEXPOSED:
        name = t.get_declaration().spelling
    elif kind == cindex.TypeKind.TYPEDEF:
        print [n.displayname for n in t.get_declaration().get_children()]
        print [n.kind.name for n in t.get_declaration().get_children()]
        name = "<fixme>"
    else:
        name = "<error:{0}>".format(kind)
    return name



#
#  General utilities
#


def merge_descriptions(descriptions):
    """Given a sequence of descriptions, in order of increasing precedence, 
    merge them into a single description dictionary."""
    attrsmeths = frozenset(['attrs', 'methods'])
    desc = {}
    for description in descriptions:
        for key, value in description.items():
            if key not in desc:
                desc[key] = deepcopy(value)
                continue

            if key in attrsmeths:
                desc[key].update(value)
            elif key == 'docstrings':
                for dockey, docvalue in value.items():
                    if dockey in attrsmeths:
                        desc[key][dockey].update(docvalue)
                    else:
                        desc[key][dockey] = deepcopy(docvalue)
            else:
                desc[key] = deepcopy(value)
    # now sanitize methods
    name = desc['name']
    methods = desc['methods']
    for methkey, methval in methods.items():
        if methval is None and not methkey[0].endswith(name):
            del methods[methkey]  # constructor for parent
    return desc
