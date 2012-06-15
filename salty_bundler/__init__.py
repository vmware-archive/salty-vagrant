'''
Utilities for using salt with vagrant.
'''

import tempfile
import uuid
import os
import shutil


def create_minion_id():
    """
    Create a random minion id.
    """
    return str(uuid.uuid1())


def gen_keys(temp_dir, minion_id):
    """
    Generate salt minion keys.
    """
    try:
        from salt.crypt import gen_keys
        key_dir = os.path.join(temp_dir, "salt", "key")
        gen_keys(key_dir, minion_id, 4096)
    except ImportError:
        print "Preseeding minion keys requires a salt installation."


def place_minion_pub(temp_dir, minion_id):
    """
    Copies the minion public key file to the accepted minion directory.
    """
    pub_key_path = os.path.join(temp_dir, "salt", "key", "{0}.pub".format(minion_id))
    dest = "/etc/salt/pki/minions/{0}".format(minion_id)
    if os.path.isfile(pub_key_path):
        shutil.copyfile(pub_key_path, dest)
    else:
        raise Exception("Minion pub key {0} not found.".format(pub_key_path))


def build_vagrantfile(temp_dir):
    """
    Build a Vagrantfile with salty vagrant parameters.
    """
    return False


def build_minion_config(temp_dir, master, minion_id):
    """
    Build a minion config file with given parameters.
    """
    minion_conf_path = os.path.join(temp_dir, "salt", "minion.conf")
    minion_conf = open(minion_conf_path, 'w')
    if master != None:
        minion_conf.write("master: {0}\n\n".format(master))
    minion_conf.write("id: {0}".format(minion_id))
    minion_conf.close()


def copy_salt_provisioner(temp_dir):
    """
    Copy salt_provisioner.rb to the bundle directory
    """
    provisioner_path = os.path.join(salty_vagrant.__path__[0], 'templates', 'temp_file')


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
        gen_keys(tempdir)
        place_minion_pub(tempdir, minion_id)
    build_minion_config(tempdir, master, minion_id)
    copy_salt_provisioner(tempdir)
    build_vagrantfile(tempdir)
    destination = archive(tempdir)

    return "Archive is located at {0}".format(destination)
