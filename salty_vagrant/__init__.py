'''
Utilities for using salt with vagrant.
'''


import tempfile
import uuid



def create_minion_id():
    """
    Create a random minion id.
    """
    return str(uuid.uuid1())


def gen_keys(temp_dir):
    """
    Generate salt minion keys.
    """
    try:
        import salt
    except ImportError:
        print "Preseeding minion keys requires a salt installation."
    return False
    


def place_minion_pub(pub_file, minion_id):
    """
    Copies the minion public key file to the accepted minion directory.
    """
    return False


def build_vagrantfile(temp_dir):
    """
    Build a Vagrantfile with salty vagrant parameters.
    """
    return False


def build_minion_config(temp_dir):
    """
    Build a minion config file with given parameters.
    """
    return False


def copy_salt_provisioner(temp_dir):
    """
    Copy salt_provisioner.rb to the bundle directory
    """
    return False


def archive(temp_dir):
    """
    Create an archive from the generated bundle.
    """
    return False


def bundle(master=None,
           preseed=False,
           minion_id=None,
           file_root=None,
           pillar_root=None,
           archive=True):
    """
    Create a Vagrantfile bundle to distribute to team members.

    master : None
        Hostname of master.

    preseed : False
        Whether or not to preseed the minion with an accepted key.

    minion_id : None
        Specify an id for the minion.

    file_root : None
        Directory with your state tree for masterless config.

    pillar_root : None
        Directory with your pillar tree for masterless config.

    archive : True
        Tar and gzip the new bundle.
    """
    if master and (file_root or pillar_root):
        raise Exception("Do not add file roots if you are using remote master")

    tempdir = tempfile.mkdtemp()
    if preseed:
        if minion_id == None:
            minion_id = create_minion_id()
        private, public = gen_keys(tempdir)
        place_minion_pub(public, minion_id)
    build_minion_config(tempdir, master, minion_id)
    copy_salt_provisioner(tempdir)
    build_vagrantfile(tempdir)
    destination = archive(tempdir)

    return "Archive is located at {0}".format(destination)
