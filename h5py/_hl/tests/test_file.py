from __future__ import with_statement

import os

from .common import ut, TestCase
from h5py.highlevel import File

class TestFileOpen(TestCase):

    """
        Feature: Opening files with Python-style modes.
    """

    def test_create(self):
        """ Mode 'w' opens file in overwrite mode """
        fname = self.mktemp()
        fid = File(fname, 'w')
        self.assertTrue(fid)
        fid.create_group('foo')
        fid.close()
        fid = File(fname, 'w')
        self.assertNotIn('foo', fid)
        fid.close()

    def test_create_exclusive(self):
        """ Mode 'w-' opens file in exclusive mode """
        fname = self.mktemp()
        fid = File(fname, 'w-')
        self.assert_(fid)
        fid.close()
        with self.assertRaises(IOError):
            File(fname, 'w-')

    def test_append(self):
        """ Mode 'a' opens file in append/readwrite mode, creating if necessary """
        fname = self.mktemp()
        fid = File(fname, 'a')
        self.assert_(fid)
        fid.create_group('foo')
        self.assert_('foo' in fid)
        fid.close()
        fid = File(fname, 'a')
        self.assert_('foo' in fid)
        fid.create_group('bar')
        self.assert_('bar' in fid)

    def test_readonly(self):
        """ Mode 'r' opens file in readonly mode """
        fname = self.mktemp()
        fid = File(fname, 'w')
        fid.close()
        self.assert_(not fid)
        fid = File(fname, 'r')
        self.assert_(fid)
        with self.assertRaises(ValueError):
            fid.create_group('foo')
        fid.close()

    def test_readwrite(self):
        """ Mode 'r+' opens existing file in readwrite mode """
        fname = self.mktemp()
        fid = File(fname, 'w')
        fid.create_group('foo')
        fid.close()
        fid = File(fname, 'r+')
        self.assert_('foo' in fid)
        fid.create_group('bar')
        self.assert_('bar' in fid)
        fid.close()
        
    def test_nonexistent_file(self):
        """ Modes 'r' and 'r+' do not create files """
        fname = self.mktemp()
        with self.assertRaises(IOError):
            File(fname, 'r')
        with self.assertRaises(IOError):
            File(fname, 'r+')

    def test_invalid_mode(self):
        """ Invalid modes raise ValueError """
        with self.assertRaises(ValueError):
            File(self.mktemp(), 'mongoose')

    def test_mode_attr(self):
        """ Mode equivalent can be retrieved via property """
        fname = self.mktemp()
        with File(fname, 'w') as f:
            self.assertEqual(f.mode, 'r+')
        with File(fname, 'r') as f:
            self.assertEqual(f.mode, 'r')

class TestDrivers(TestCase):

    """
        Feature: Files can be opened with low-level HDF5 drivers
    """

    @ut.skipUnless(os.name, 'posix')
    def test_stdio(self):
        """ Stdio driver is supported on posix """
        fid = File(self.mktemp(), 'w', driver='stdio')
        self.assertTrue(fid)
        self.assertEqual(fid.driver, 'stdio')
        fid.close()

    @ut.skipUnless(os.name, 'posix')
    def test_sec2(self):
        """ Sec2 driver is supported on posix """
        fid = File(self.mktemp(), 'w', driver='sec2')
        self.assert_(fid)
        self.assertEqual(fid.driver, 'sec2')
        fid.close()

    def test_core(self):
        """ Core driver is supported (no backing store) """
        fname = self.mktemp()
        fid = File(fname, 'w', driver='core', backing_store=False)
        self.assert_(fid)
        self.assertEqual(fid.driver, 'core')
        fid.close()
        self.assertFalse(os.path.exists(fname))

    def test_backing(self):
        """ Core driver saves to file when backing store used """
        fname = self.mktemp()
        fid = File(fname, 'w', driver='core', backing_store=True)
        fid.create_group('foo')
        fid.close()
        fid = File(fname, 'r')
        self.assert_('foo' in fid)
        fid.close()

    def test_readonly(self):
        """ Core driver can be used to open existing files """
        fname = self.mktemp()
        fid = File(fname, 'w')
        fid.create_group('foo')
        fid.close()
        fid = File(fname, 'r', driver='core')
        self.assert_(fid)
        self.assert_('foo' in fid)
        with self.assertRaises(ValueError):
            fid.create_group('bar')
        fid.close()
    
    def test_blocksize(self):
        """ Core driver supports variable block size """
        fname = self.mktemp()
        fid = File(fname, 'w', driver='core', block_size=1024,
                   backing_store=False)
        self.assert_(fid)
        fid.close()

    #TODO: family driver tests

class TestLibver(TestCase):

    """
        Feature: File format compatibility bounds can be specified when
        opening a file.
    """

    def test_single(self):
        """ Opening with single libver arg """
        f = File(self.mktemp(), 'w', libver='latest')
        self.assertEqual(f.libver, ('latest','latest'))
        f.close()

    def test_multiple(self):
        """ Opening with two libver args """
        f = File(self.mktemp(), 'w', libver=('earliest','latest'))
        self.assertEqual(f.libver, ('earliest', 'latest'))
        f.close()

    def test_none(self):
        """ Omitting libver arg results in maximum compatibility """
        f = File(self.mktemp(), 'w')
        self.assertEqual(f.libver, ('earliest', 'latest'))
        f.close()

class TestContextManager(TestCase):

    """
        Feature: File objects can be used as context managers
    """

    def test_context_manager(self):
        """ File objects can be used in with statements """
        with File(self.mktemp(), 'w') as fid:
            self.assertTrue(fid)
        self.assertTrue(not fid)

class TestUnicode(TestCase):

    """
        Feature: Unicode filenames are supported
    """

    def test_unicode(self):
        """ Unicode filenames can be used, and retrieved properly via .filename
        """
        fname = self.mktemp(prefix = u'\u201a')
        fid = File(fname, 'w')
        self.assertEqual(fid.filename, fname)
        self.assertIsInstance(fid.filename, unicode)

class TestFileProperty(TestCase):

    """
        Feature: A File object can be retrieved from any child object,
        via the .file property
    """

    def test_property(self):
        """ File object can be retrieved from subgroup """
        fname = self.mktemp()
        hfile = File(fname, 'w')
        hfile2 = hfile['/'].file
        self.assertEqual(hfile, hfile2)

    def test_close(self):
        """ All retrieved File objects are closed at the same time """
        fname = self.mktemp()
        hfile = File(fname, 'w')
        grp = hfile.create_group('foo')
        hfile2 = grp.file
        hfile3 = hfile['/'].file
        hfile2.close()
        self.assertFalse(hfile)
        self.assertFalse(hfile2)
        self.assertFalse(hfile3)

    def test_mode(self):
        """ Retrieved File objects have a meaningful mode attribute """
        hfile = File(self.mktemp(),'w')
        grp = hfile.create_group('foo')
        self.assertEqual(grp.file.mode, hfile.mode)


class TestClose(TestCase):

    """
        Feature: Files can be closed
    """

    def test_close(self):
        """ Close file via .close method """
        fid = File(self.mktemp())
        self.assert_(fid)
        fid.close()
        self.assert_(not fid)
      
    def test_closed_file(self):
        """ Trying to modify closed file raises ValueError """
        fid = File(self.mktemp(), 'w')
        fid.close()
        with self.assertRaises(ValueError):
            fid.create_group('foo')

class TestFlush(TestCase):

    """
        Feature: Files can be flushed
    """

    def test_flush(self):
        """ Flush via .flush method """
        fid = File(self.mktemp(), 'w')
        fid.flush()
        fid.close()


class TestRepr(TestCase):

    """
        Feature: File objects provide a helpful __repr__ string
    """

    def test_repr(self):
        """ __repr__ behaves itself when files are open and closed """
        fid = File(self.mktemp())
        self.assertIsInstance(repr(fid), basestring)
        fid.close()
        self.assertIsInstance(repr(fid), basestring)

class TestFilename(TestCase):

    """
        Feature: The name of a File object can be retrieved via .filename
    """

    def test_filename(self):
        """ .filename behaves properly for string data """
        fname = self.mktemp()
        fid = File(fname, 'w')
        self.assertEqual(fid.filename, fname)
        self.assertIsInstance(fid.filename, unicode)

class TestBackwardsCompat(TestCase):

    """
        Feauture: Deprecated attributes are included to support 1.3 code
    """

    def test_fid(self):
        """ File objects provide a .fid attribute aliased to the file ID """
        with File(self.mktemp(), 'w') as hfile:
            self.assertIs(hfile.fid, hfile.id)



















