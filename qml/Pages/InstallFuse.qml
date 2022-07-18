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

import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtQuick.Layouts 1.3

Page {
    anchors.fill: parent

    header: PageHeader {
        id: header
        title: gocryptfs.isLoading ? i18n.tr('Installing...') : i18n.tr('Attention!')
        flickable: contentFlickable
    }

    ScrollView {
        width: parent.width
        height: parent.height
        contentItem: contentFlickable
    }

    Flickable {
        id: contentFlickable
        width: parent.width; height: width
        contentHeight: warningColumn.height
        topMargin: units.gu(2)
        bottomMargin: units.gu(3)

        // I think some layout calculations could be done better.
        ColumnLayout {
            width: parent.width
            anchors.top: parent.top
            anchors.topMargin: units.gu(1)
            spacing: units.gu(2)
            
            id: warningColumn

            Item { Layout.fillHeight: true }

            Icon {
                id: warnIcon
                Layout.preferredWidth: (parent.width / 6) + units.gu(4)
                Layout.preferredHeight: Layout.preferredWidth
        
                Layout.maximumWidth: units.gu(15)

                Layout.alignment: Qt.AlignCenter

                name: "security-alert"
            }

            Text {
                id: warnText
                Layout.fillWidth: true
                color: theme.palette.normal.baseText

                text: i18n.tr(`This app requires the installation of additional system components: Fuse.\n
This may fail on some devices, due to the Root FS size.\n
If this breaks your system, try reinstalling UT without the Wipe option using the UBports Installer.\n
Keep in mind that this message will reappear after a system update.\n
GoCryptFs needs to run in the background, so it will add itself to app suspension exceptions.`)

                horizontalAlignment: Text.AlignHCenter

                Layout.leftMargin: parent.width / 6
                Layout.rightMargin: parent.width / 6
            }

            Button {
                id: acceptButton
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: (parent.width / 5) + units.gu(4)

                text: i18n.tr("Continue")
                color: theme.palette.normal.positive

                onClicked: {
                    var popup = PopupUtils.open(passwordPopup)
                    popup.accepted.connect(function(password) {

                        gocryptfs.isLoading = true;

                        gocryptfs.call('gocryptfs.disable_sleep', [root.applicationName], function() {
                            print("Disabled app suspention.");
                        });

                        gocryptfs.call('gocryptfs.install_fuse', [password], function(status) {
                            gocryptfs.isLoading = false;

                            if (status != 0) {
                                print(`Error installing Fuse: ${status}`);
                                toast.show(i18n.tr("Error installing Fuse: ") + status);
                                return;
                            }

                            print("Fuse installed.");
                            pStack.pop(); pStack.push(Qt.resolvedUrl("./VaultList.qml"));
                        });
                    })
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    Component {
        id: passwordPopup

        Dialog {
            id: passwordDialog
            title: i18n.tr("Enter password")
            text: i18n.tr("Your password is required for this action.")

            signal accepted(string password)
            signal rejected()

            TextField {
                id: passwordTextField
                placeholderText: i18n.tr("Password")
                echoMode: TextInput.Password
                focus: true
            }

            RowLayout {
                Button {
                    text: i18n.tr("Cancel")
                    color: theme.palette.normal.negative
                    Layout.fillWidth: true
        
                    onClicked: {
                        passwordDialog.rejected();
                        PopupUtils.close(passwordDialog)
                    }
                }

                Button {
                    text: i18n.tr("Install")
                    color: theme.palette.normal.positive
                    Layout.fillWidth: true

                    onClicked: {
                        passwordDialog.accepted(passwordTextField.text)
                        PopupUtils.close(passwordDialog)
                    }
                }

            }
        }
    }
}
