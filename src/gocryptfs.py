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

def get_config() -> list:
    configFile = open(str(configFilePath), "r").read()
    if configFile == "":
        return []

    return json.loads(configFile)

vault_list = get_config()

def save_config():
    jsonVaults = json.dumps(vault_list)

    configFile = open(str(configFilePath), "w", encoding='utf-8')

    if jsonVaults != "[]":
        configFile.write(jsonVaults)
    else:
        configFile.write("")

    configFile.close()

def get_data():
    return json.dumps(vault_list)

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

def import_vault(vault_config: dict):
    if not os.path.exists(vault_config["encrypted_data_directory"]):
        raise CannotReadConfig()
        # FIXME: Read gocryptfs.conf
    
    vault_list.append(vault_config)
    save_config()

def init(vault_config: dict, password: str):
    vault_config["encrypted_data_directory"] = vault_config["encrypted_data_directory"].replace("~", os.getenv("HOME"))
    vault_config["mount_directory"] = vault_config["mount_directory"].replace("~", os.getenv("HOME"))

    if not os.path.exists(vault_config["encrypted_data_directory"]):
        os.makedirs(vault_config["encrypted_data_directory"])

    child = subprocess.Popen(["gocryptfs", "-init", vault_config["encrypted_data_directory"]],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True)

    child.communicate(password)

    vault_list.append(vault_config)
    save_config()

    if child.returncode != 0:
        status_to_error(child.returncode)

def mount(vault_config: dict, password: str):
    if not os.path.exists(vault_config["mount_directory"]):
        os.makedirs(vault_config["mount_directory"])

    child = subprocess.Popen(["gocryptfs", vault_config["encrypted_data_directory"], vault_config["mount_directory"]],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True)

    child.communicate(password)

    # FIXME: Use UUIDs for this
    [x for x in vault_list if x["name"] == vault_config["name"]][0]["is_mounted"] = True

    if child.returncode != 0:
        status_to_error(child.returncode)

def unmount(vault_config: dict):
    vault_config = [x for x in vault_list if x["name"] == vault_config["name"]][0]

    if not vault_config["is_mounted"]:
        return

    vault_config["is_mounted"] = False

    output = subprocess.run(["fusermount", "-u", vault_config["mount_directory"]], stdout=subprocess.DEVNULL)

    if output.returncode != 0:
        raise GenericError(output.returncode)

def remove(vault_config: dict):
    unmount(vault_config)

    # FIXME: Do not remove missing directories!

    shutil.rmtree(vault_config["encrypted_data_directory"])
    shutil.rmtree(vault_config["mount_directory"])

    vault_list.remove(vault_config)

    save_config()
