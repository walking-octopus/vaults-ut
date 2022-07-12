import QtQuick 2.12
import io.thp.pyotherside 1.4

Item {
    id: gocryptfs

    property bool isInstalled
    property bool isFuseInstalled

    property var model: vaultsModel
    property bool isLoading: false

    signal ready()
    signal info(string message)
    signal error(string message)

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../src/'));

            importModule('gocryptfs', function() {
                call('gocryptfs.is_available', [], function(installedDeps) {
                    isInstalled = installedDeps.gocryptfs;
                    isFuseInstalled = installedDeps.fuse;
                    ready();
                });
            });
        }

        onError: {
            print('Python error: %s'.arg(traceback));
            error(i18n.tr("Unknown error. View the logs for more info."));
        }
    }

    ListModel {
        id: vaultsModel

        function refresh() {
            gocryptfs.isLoading = true;

            python.call('gocryptfs.get_data', [], function(vaults) {
                vaultsModel.clear();

                vaults.forEach((vault) => {
                    vaultsModel.append(vault);
                });
    
                gocryptfs.isLoading = false;
            });
        }
    }

    function init(name, mountDir, dataDir, password) {
        gocryptfs.isLoading = true;

        let vault_config = {
            "name": name,
            "mount_directory": mountDir,
            "encrypted_data_directory": dataDir,
            "is_mounted": false,
        }

        python.call('gocryptfs.init', [vault_config, password], function(status) {
            gocryptfs.isLoading = false;
            vaultsModel.refresh();

            if (status != 0)
                error(
                    i18n.tr("GoCryptFS error: %s").arg(status)
                );
        });
    }

    function mount(id, password) {
        gocryptfs.isLoading = true;

        python.call('gocryptfs.mount', [id, password], function(status) {
            vaultsModel.refresh();

            // TODO: Convert status codes to errors

            switch (status) {
                case 0: {
                    info(i18n.tr("Vault opened."));
                    break;
                }
                case 12: {
                    error(i18n.tr("Wrong password!"));
                    break;
                }
                default: {
                    error(
                        i18n.tr("GoCryptFS mount error: %s").arg(status)
                    );
                }
            }

            gocryptfs.isLoading = true;
        });
    }

    function unmount(id) {
        gocryptfs.isLoading = true;

        python.call('gocryptfs.unmount', [id], function(status) {
            gocryptfs.isLoading = false;
            vaultsModel.refresh();

            if (status != 0)
                error(
                    i18n.tr("FuseMount unmount error: %s").arg(status)
                );
        });
    }

    function mv(location, mount_directory) {
        gocryptfs.isLoading = true;
            
        python.call('gocryptfs.mv', [location, mount_directory], function(status) {
            gocryptfs.isLoading = false;

            if (status != 0)
                error(
                    i18n.tr("Error %s moving the files into the vault").arg(status)
                );
        });
    }
}