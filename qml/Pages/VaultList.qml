/*
 * Copyright (C) 2022  walking-octopus
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * vaults-ut is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import "../Components/passwordEntropy.js" as Entropy

Page {
    anchors.fill: parent

    header: PageHeader {
        id: header
        title: !gocryptfs.isLoading ? i18n.tr("Vaults") : i18n.tr("Loading...")

        flickable: scrollView.flickableItem

        trailingActionBar.actions: [
            Action {
                text: i18n.tr("Add")
                iconName: "add"

                onTriggered: {
                    var popup = PopupUtils.open(newVaultPopup);
                    popup.accepted.connect(function(name, mountDir, dataDir, password) {
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
                onTriggered: print("PLACEHOLDER: App settings")
            },

            Action {
                text: i18n.tr("About")
                iconName: "info"
                onTriggered: pStack.push(Qt.resolvedUrl("./About.qml"));
            }
        ]
    }

    ListModel {
        id: vaultList

        function refresh() {
            gocryptfs.call('gocryptfs.get_data', [], function(vaults) {
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

                ListItemLayout {
                    anchors.centerIn: parent
                    title.text: name

                    Icon {
                        name: "document-open"
                        width: units.gu(2.5); height: width
                        visible: is_mounted
                        SlotsLayout.position: SlotsLayout.Trailing

                        TapHandler {
                            onTapped: {
                                var popup = PopupUtils.open(moveToVaultPopup);

                                popup.accepted.connect(function(location) {            
                                    gocryptfs.isLoading = true;
            
                                    gocryptfs.call('gocryptfs.mv', [location, mount_directory], function(status) {
                                        gocryptfs.isLoading = false;

                                        if (status != 0)
                                            toast.show(i18n.tr("Error moving the files into the vault"))
                                    });
                                });
                            }
                        }
                    }

                    Icon {
                        name: !is_mounted ? "lock" : "close"
                        width: units.gu(2.5); height: width
                        SlotsLayout.position: SlotsLayout.Trailing

                        TapHandler {
                            onTapped: {
                                gocryptfs.isLoading = true;

                                if (!is_mounted) {
                                    print(`Mounting ${encrypted_data_directory} at ${mount_directory}...`);

                                    var popup = PopupUtils.open(unlockVaultPopup);
                                    popup.accepted.connect(function(password) {
                                        gocryptfs.call('gocryptfs.mount', [id, password], function(status) {
                                            gocryptfs.isLoading = false;
                                            vaultList.refresh();

                                            // TODO: Convert status codes to errors

                                            switch (status) {
                                                case 0: {
                                                    print("Mounted!");
                                                    break;
                                                }
                                                case 12: {
                                                    toast.show(i18n.tr("Wrong password!"));
                                                    break;
                                                }
                                                default: {
                                                    print("GoCryptfs mount error: " + status);
                                                    toast.show(i18n.tr("GoCryptfs mount error: ") + status);                                                }
                                            }
                                        });
                                    });
                                } else {
                                    print(`Unmounting ${encrypted_data_directory} at ${mount_directory}...`);

                                    gocryptfs.call('gocryptfs.unmount', [id], function(status) {
                                        gocryptfs.isLoading = false;
                                        vaultList.refresh();

                                        if (status != 0) {
                                            print("Fusemount unmount error: " + status);
                                            toast.show(i18n.tr("Fusemount unmount error: ") + status);
                                        }
                                    });
                                }
                            }
                        }
                    }

                    // FIXME: This uses an extra trailing slot
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

                visible: vaultListView.count === 0 && !gocryptfs.isLoading

                Item { Layout.fillHeight: true }

                UbuntuShape {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: units.gu(16); Layout.preferredHeight: width
                    Layout.bottomMargin: units.gu(2)

                    radius: "medium"
                    source: Image {
                        source: Qt.resolvedUrl("../../assets/logo.png")
                    }
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
        id: moveToVaultPopup

        Dialog {
           id: moveToVaultDialog

           title: i18n.tr("Move into the vault")
           text: i18n.tr("Type a path to a file/folder to be moved into the vault.\nIf unsure, copy it in the File Manager and paste here.")

           signal accepted(string location)
           signal rejected()

           TextField {
               id: locationField
               placeholderText: "~/Documents/Important/"
               focus: true
               inputMethodHints: Qt.ImhNoPredictiveText
           }

           RowLayout {
               Button {
                   Layout.fillWidth: true

                   text: i18n.tr("Cancel")
                   color: theme.palette.normal.negative

                   onClicked: PopupUtils.close(moveToVaultDialog)
               }

               Button {
                   Layout.fillWidth: true

                   text: i18n.tr("Move")
                   color: theme.palette.normal.positive
                   
                   enabled: locationField.text != ""
                   onClicked: {
                       PopupUtils.close(moveToVaultDialog);
                       moveToVaultDialog.accepted(locationField.text);
                   }
               }
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
                    
                    enabled: passwordField.text != ""
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

                    enabled: passwordField.text == passwordRepeatField.text
                        && Entropy.passwordEntropy(passwordField.text) > 36
                        && nameField.text != ""
                        && mountDirField.text != ""
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
