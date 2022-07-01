import QtQuick 2.12
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

Page {
    anchors.fill: parent

    header: PageHeader {
        id: header
        title: "Vaults"

        flickable: scrollView.flickableItem

        trailingActionBar.actions: [
            Action {
                text: i18n.tr("Add")
                iconName: "add"

                onTriggered: {
                    var popup = PopupUtils.open(newVaultPopup)
                    popup.accepted.connect(function(name, mountDir, dataDir, password) {
                        print(name, mountDir, dataDir, password);

                        gocryptfs.isLoading = true;

                        let vault_config = {
                            "name": name,
                            "mount_directory": mountDir,
                            "encrypted_data_directory": dataDir,
                            "is_mounted": false,
                        }

                        gocryptfs.call('gocryptfs.init', [vault_config, password], function() {
                            gocryptfs.isLoading = false;
                            vaultList.refresh();
                        });
                    });
                }
            }
        ]

        leadingActionBar.actions: [
            Action {
                text: i18n.tr("Refresh")
                iconName: "view-refresh"
                onTriggered: vaultList.refresh()
            },

            Action {
                text: i18n.tr("Preferences")
                iconName: "settings"
                onTriggered: print("App settings")
            },

            Action {
                text: i18n.tr("About")
                iconName: "info"
                onTriggered: print("About page")
            }
        ]
    }

    ListModel {
        id: vaultList

        function refresh() {
            gocryptfs.call('gocryptfs.get_data', [], function(result) {
                let vaults = JSON.parse(result);

                vaultList.clear();
                vaults.forEach((vault) => {
                    vaultList.append(vault);
                });
            });
        }

        Component.onCompleted: refresh()
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent

        ListView {
            id: vaultListView
            anchors.fill: parent

            model: vaultList
            delegate: ListItem {
                id: vaultItemDelegate

                property QtObject modelData: model

                ListItemLayout {
                    anchors.centerIn: parent
                    title.text: name

                    Icon {
                        name: "folder-symbolic"
                        width: units.gu(2.5); height: width
                        visible: is_mounted
                        SlotsLayout.position: SlotsLayout.Trailing

                        TapHandler {
                            onTapped: print(`Opening ${mount_directory}...`)
                        }
                    }

                    Icon {
                        name: !is_mounted ? "lock" : "close"
                        width: units.gu(2.5); height: width
                        SlotsLayout.position: SlotsLayout.Trailing

                        TapHandler {
                            onTapped: {
                                let vault_config = {
                                    "name": name,
                                    "mount_directory": mount_directory,
                                    "encrypted_data_directory": encrypted_data_directory,
                                    "is_mounted": is_mounted,
                                }

                                gocryptfs.isLoading = true;

                                if (!is_mounted) {
                                    print(`Mounting ${encrypted_data_directory} at ${mount_directory}...`);

                                    var popup = PopupUtils.open(unlockVaultPopup);
                                    popup.accepted.connect(function(password) {
                                        gocryptfs.call('gocryptfs.mount', [vault_config, password], function() {
                                            gocryptfs.isLoading = false;
                                            vaultList.refresh();

                                            // The errors, including entering the wrong password, aren't handled
                                        });
                                    });
                                } else {
                                    print(`Unmounting ${encrypted_data_directory} at ${mount_directory}...`);

                                    gocryptfs.call('gocryptfs.unmount', [vault_config], function() {
                                        gocryptfs.isLoading = false;
                                        vaultList.refresh();
                                    });
                                }
                            }
                        }
                    }

                    // FIXME: This is hack that uses an extra trailing slot
                    Icon {
                        name: "settings"
                        width: units.gu(2.5); height: width
                        visible: !is_mounted
                        SlotsLayout.position: SlotsLayout.Trailing

                        TapHandler {
                            onTapped: print("Vault settings")
                        }
                    }
                }
            }
            focus: true

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: header.height
                spacing: units.gu(2)

                visible: vaultListView.count === 0 && !vaultList.loading

                Item { Layout.fillHeight: true }

                UbuntuShape {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: units.gu(16); Layout.preferredHeight: width
                    Layout.bottomMargin: units.gu(2)

                    radius: "medium"
                    color: UbuntuColors.orange
                }

                Label {
                    text: i18n.tr("Welcome to Vaults!")
                    textSize: Label.Large
                    font.bold: true
                    Layout.alignment: Qt.AlignCenter
                }

                Label {
                    text: i18n.tr("Add or Import a Vault")
                    Layout.alignment: Qt.AlignCenter
                }

                Item { Layout.fillHeight: true }
            }

        }
    }

    Component {
         id: unlockVaultPopup

         Dialog {
            id: unlockVaultDialog

            title: i18n.tr("Unlock the Vault") // TODO: Maybe add the vault title here...
            text: i18n.tr("Enter the password to unlock the Vault.")

            signal accepted(string password)
            signal rejected()

            TextField {
                id: passwordField
                placeholderText: i18n.tr("Password")
                echoMode: TextInput.Password
                focus: true
            }

            RowLayout {
                Button {
                    Layout.fillWidth: true

                    text: i18n.tr("Cancel")
                    color: theme.palette.normal.negative

                    onClicked: PopupUtils.close(unlockVaultDialog)
                }

                Button {
                    Layout.fillWidth: true

                    text: i18n.tr("Submit")
                    color: theme.palette.normal.positive

                    onClicked: {
                        PopupUtils.close(unlockVaultDialog);
                        unlockVaultDialog.accepted(passwordField.text);
                    }
                }
            }
         }
    }

    Component {
        id: newVaultPopup

        Dialog {
            id: newVaultDialog
            title: i18n.tr("New Vault")

            signal accepted(string name, string mountDir, string dataDir, string password)
            signal rejected()

            Label {
                text: nameField.placeholderText
                visible: nameField.visible
            }
            TextField {
                id: nameField
                placeholderText: i18n.tr("Name")
                focus: true
            }

            Label {
                text: passwordField.placeholderText
                visible: passwordField.visible
            }
            TextField {
                id: passwordField
                placeholderText: i18n.tr("Password")
                echoMode: TextInput.Password
            }

            Label {
                text: passwordRepeatField.placeholderText
                visible: passwordRepeatField.visible
            }
            TextField {
                id: passwordRepeatField
                placeholderText: i18n.tr("Confirm Password")
                echoMode: TextInput.Password
            }

            Label {
                text: mountDirField.placeholderText
                visible: mountDirField.visible
            }
            TextField {
                id: mountDirField
                placeholderText: i18n.tr("Folder location")
                text: `~/Documents/Vaults/${nameField.text}`
            }

            RowLayout {
                Button {
                    Layout.fillWidth: true

                    text: i18n.tr("Cancel")
                    color: theme.palette.normal.negative

                    onClicked: PopupUtils.close(newVaultDialog)
                }

                Button {
                    Layout.fillWidth: true

                    text: i18n.tr("Create")
                    color: theme.palette.normal.positive

                    // TODO: Add entropy checking
                    enabled: passwordField.text == passwordRepeatField.text
                        && passwordField.text.length > 6
                        && nameField.text.length != 0
                        && mountDirField.text.length != 0
                    onClicked: {
                        let dataDir = `~/.config/${root.applicationName}/data/${nameField.text}`
                        newVaultDialog.accepted(nameField.text, mountDirField.text, dataDir, passwordField.text)
                        PopupUtils.close(newVaultDialog)
                    }
                }
            }
        }
   }
}
