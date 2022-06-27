from typing import List
import json
import subprocess
import os
import shutil
from pathlib import Path

HOME = os.path.expanduser("~")
XDG_CONFIG_HOME = os.environ.get("XDG_CONFIG_HOME", os.path.join(HOME, ".config"))
APP_CONFIG = Path.joinpath(Path(XDG_CONFIG_HOME), "vaults-ut.walking-octopus")

APP_CONFIG.mkdir(parents=True, exist_ok=True)

# TODO: Switch to a simple dictionary
class VaultConfig():
    name = ""
    is_mounted = False
    encrypted_data_directory = ""
    mount_directory = ""

    # def __getitem__(self, indices):
    #     if not isinstance(indices, tuple):
    #         indices = tuple(indices)

    def to_dict(self):
        if isinstance(self, VaultConfig):
            return {
                'name': self.name,
                'is_mounted': self.is_mounted,
                'encrypted_data_directory': self.encrypted_data_directory,
                'mount_directory': self.mount_directory
            }
        else:
            type_name = self.__class__.__name__
            raise TypeError("Unexpected type {0}".format(type_name))

    @staticmethod
    def from_json(json_dct):
      return VaultConfig(
          name=json_dct['name'],
          is_mounted=json_dct['is_mounted'],
          encrypted_data_directory=json_dct['encrypted_data_directory'],
          mount_directory=json_dct['mount_directory']
      )

    def __init__(self, **kv):
        self.__dict__.update(kv)

class GenericError(Exception): pass
class NonEmptyCipherDir(GenericError): pass
class NonEmptyMountPoint(GenericError): pass
class WrongPassword(GenericError): pass
class CannotReadConfig(GenericError): pass
class CannotWriteConfig(GenericError): pass
class FsckError(GenericError): pass

def status_to_error(status: int) -> str:
    GocryptfsExitStatus = {
        6: NonEmptyCipherDir,
        7: NonEmptyCipherDir,
        10: NonEmptyMountPoint,
        12: WrongPassword,
        22: WrongPassword,
        23: CannotReadConfig,
        24: CannotWriteConfig,
        26: FsckError,
    }

    if not status in GocryptfsExitStatus:
        raise GenericError(status)

    raise GocryptfsExitStatus[status]

configFilePath = Path.joinpath(APP_CONFIG, "knownVaults.json")
configFilePath.touch(exist_ok=True)


def get_config() -> List[VaultConfig]:
    configFile = open(str(configFilePath), "r").read()
    if configFile == "":
        return []

    print("Loading")
    return json.loads(configFile, object_hook=VaultConfig.from_json)

vault_list = get_config()

def save_config():
    jsonVaults = json.dumps(vault_list, default=VaultConfig.to_dict)

    configFile = open(str(configFilePath), "w", encoding='utf-8')

    if jsonVaults != "[]":
        configFile.write(jsonVaults)
    else:
        configFile.write("")

    configFile.close()

def get_data():
    return json.dumps(vault_list, default=VaultConfig.to_dict)

def is_available() -> dict:
    (gocryptfs_status, gocryptfs_version) = subprocess.getstatusoutput('gocryptfs --version')
    (fust_status, fust_version) = subprocess.getstatusoutput('fusermount -V')

    return { 'gocryptfs': gocryptfs_status == 0, 'fuse': fust_status == 0 }

# TODO: Stop using shell=True
def install_fuse(sudo_password: str):
    cmd1 = subprocess.Popen(['echo', sudo_password], stdout=subprocess.PIPE)
    cmd2 = subprocess.Popen("sudo -S sh -c 'mount -o rw,remount /; apt update; apt install fuse -y; mount -o ro,remount /'",
        stdin=cmd1.stdout,
        stdout=subprocess.PIPE,
        shell=True)

    cmd2.wait()

    if cmd2.returncode != 0:
        print(cmd2.returncode)

def import_vault(vault_config: VaultConfig):
    if not os.path.exists(vault_config.encrypted_data_directory):
        raise CannotReadConfig()
        # FIXME: Read gocryptfs.conf
    
    vault_list.append(vault_config)
    save_config()

def init(vault_config: VaultConfig, password: str):
    if not os.path.exists(vault_config.encrypted_data_directory):
        os.makedirs(vault_config.encrypted_data_directory)

    child = subprocess.Popen(["gocryptfs", "-init", vault_config.encrypted_data_directory],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True)

    child.communicate(password)

    vault_list.append(vault_config)
    save_config()

    if child.returncode != 0:
        status_to_error(child.returncode)

def mount(vault_config: VaultConfig, password: str):
    if not os.path.exists(vault_config.mount_directory):
        os.makedirs(vault_config.mount_directory)

    child = subprocess.Popen(["gocryptfs", vault_config.encrypted_data_directory, vault_config.mount_directory],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True)

    child.communicate(password)

    # FIXME: This ugly hack can lead to many issues!
    [x for x in vault_list if x.name == vault_config.name][0].is_mounted = True

    if child.returncode != 0:
        status_to_error(child.returncode)

def unmount(vault_config: VaultConfig):
    vault_config = [x for x in vault_list if x.name == vault_config.name][0]

    if not vault_config.is_mounted:
        return

    vault_config.is_mounted = False

    output = subprocess.run(["fusermount", "-u", vault_config.mount_directory], stdout=subprocess.DEVNULL)

    if output.returncode != 0:
        raise GenericError(output.returncode)

def remove(vault_config: VaultConfig):
    unmount(vault_config)

    shutil.rmtree(vault_config.encrypted_data_directory)
    shutil.rmtree(vault_config.mount_directory)

    vault_list.remove(vault_config)

    save_config()