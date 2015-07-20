#!/usr/bin/env

from setuptools import setup, find_packages
import imp

procdog = imp.load_source("procdog", "procdog")

setup(
  name="procdog",
  version=procdog.VERSION,
  packages=find_packages(),
  author="Joshua Levy",
  license="Apache 2",
  url="https://github.com/jlevy/procdog",
  download_url="https://github.com/jlevy/procdog/tarball/" + procdog.VERSION,
  scripts=["procdog"],
  install_requires=[],
  description=procdog.DESCRIPTION,
  long_description=procdog.LONG_DESCRIPTION,
  classifiers= [
    'Development Status :: 4 - Beta',
    'Environment :: Console',
    'Intended Audience :: End Users/Desktop',
    'Intended Audience :: System Administrators',
    'Intended Audience :: Developers',
    'License :: OSI Approved :: Apache Software License',
    'Operating System :: MacOS :: MacOS X',
    'Operating System :: POSIX',
    'Operating System :: Unix',
    'Programming Language :: Python :: 2.7',
    'Topic :: Utilities',
    'Topic :: Software Development'
  ],
)
