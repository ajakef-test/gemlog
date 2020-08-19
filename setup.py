#! /usr/bin/env python
import pdb
try:
    import setuptools  # @UnusedImport # NOQA
except ImportError:
    pass

#import fnmatch
import glob
import inspect
import os
import sys
import platform
from distutils.util import change_root, convert_path

from setuptools import setup, find_packages
# The minimum python version which can be used to run ObsPy
MIN_PYTHON_VERSION = (3, 6)

# Fail fast if the user is on an unsupported version of python.
if sys.version_info < MIN_PYTHON_VERSION:
    msg = ("gemlog requires python version >= {}".format(MIN_PYTHON_VERSION) +
           " you are using python version {}".format(sys.version_info))
    print(msg, file=sys.stderr)
    sys.exit(1)

# Directory of the current file in the (hopefully) most reliable way
# possible, according to krischer
SETUP_DIRECTORY = os.path.dirname(os.path.abspath(inspect.getfile(
    inspect.currentframe())))
INSTALL_REQUIRES = [
    'obspy',
    'numpy>=1.15.0',
    'scipy>=1.0.0',
    'matplotlib>=3.2.0',
    'lxml',
    'setuptools',
    'sqlalchemy',
    'decorator',
    'requests']

EXTRAS_REQUIRE = []
ENTRY_POINTS = {
    'console_scripts': [
        'gem2ms = gemlog.gem2ms:main'
    ]
}

KEYWORDS = ['']
DOCSTRING = ['', '', '', '']
classifiers=[
    'Intended Audience :: Science/Research',
    'Intended Audience :: Developers',
    'License :: OSI Approved :: GNU GPL 3',
    'Operating System :: OS Independent',
    'Programming Language :: Python',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.7',
    'Programming Language :: Python :: 3.8',
    'Topic :: Scientific/Engineering',
    'Topic :: Scientific/Engineering :: Physics'
]

def setupPackage():
    # setup package
    setup(
        name='gemlog',
        version = version_dict['__version__'],
        packages=find_packages(),
        entry_points=ENTRY_POINTS
    )

version_dict = {}
version_path = convert_path('gemlog/version.py')
with open(version_path) as version_file:
    exec(version_file.read(), version_dict)

if __name__ == '__main__':
    # clean --all does not remove extensions automatically
    if 'clean' in sys.argv and '--all' in sys.argv:
        import shutil
        # delete complete build directory
        path = os.path.join(SETUP_DIRECTORY, 'build')
        try:
            shutil.rmtree(path)
        except Exception:
            pass
        # delete all shared libs from lib directory
        path = os.path.join(SETUP_DIRECTORY, 'gemlog', 'lib')
        for filename in glob.glob(path + os.sep + '*.pyd'):
            try:
                os.remove(filename)
            except Exception:
                pass
        for filename in glob.glob(path + os.sep + '*.so'):
            try:
                os.remove(filename)
            except Exception:
                pass
    else:
        setupPackage()

