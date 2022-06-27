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
                    popup.accepted.connect(function(password) {
                    //     gocryptfs.isLoading = true;
                    //     gocryptfs.call('gocryptfs.install_fuse', [password], function() {
                    //         gocryptfs.isLoading = false;
                    //         pStack.pop()
                    //         pStack.push(Qt.resolvedUrl("./Pages/VaultList.qml"));
                    //     });
                    })
                }
            }
        ]
        
        leadingActionBar.actions: [
            Action {
                text: i18n.tr("Refresh")
                iconName: "view-refresh"
                onTriggered: print("Refresh data")
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

        Component.onCompleted: {
            gocryptfs.call('gocryptfs.get_data', [], function(result) {
                let vaults = JSON.parse(result);

                vaults.forEach((vault) => {
                    vaultList.append(vault);
                    print(vault.name)
                });
            });
        }
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
                            onTapped: print(`Mounting ${encrypted_data_directory} at ${mount_directory}...`)
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

            // TODO: Add a better placeholder item
            Label {
                id: emptyLabel
                anchors.centerIn: parent

                text: i18n.tr("Welcome to Vaults!\nAdd or import a vault")
                visible: vaultListView.count === 0 && !vaultList.loading
            }
        }
    }

    Component {
        id: newVaultPopup
        
        // TODO: Consider separating this into two dialogs.
        Dialog {
            id: newVaultDialog
            title: i18n.tr("New Vault")

            signal accepted(string name, string password)
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
                        newVaultDialog.accepted(nameField.text, passwordField.text)
                        PopupUtils.close(newVaultDialog)
                    }
                }
            }
        }
   }
}
