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
//import QtQuick.Controls 2.2
//import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import io.thp.pyotherside 1.4

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'vaults-ut.walking-octopus'
    automaticOrientation: true

    width: units.gu(80)
    height: units.gu(65)

    PageStack {
        id: pStack
        anchors.fill: parent
    }

    Connections {
        target: gocryptfs
        onReady: {
            if (!gocryptfs.isFuseInstalled) {
                pStack.push(Qt.resolvedUrl("./Pages/InstallFuse.qml"));
            } else {
                pStack.push(Qt.resolvedUrl("./Pages/VaultList.qml"));
            }
        }
    }

    Python {
        id: gocryptfs

        property bool isInstalled
        property bool isFuseInstalled

        property bool isLoading: false

        signal ready()

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));

            importModule('gocryptfs', function() {
                print('Module imported.');

                call('gocryptfs.is_available', [], function(areDependenciesInstalled) {
                    isInstalled = areDependenciesInstalled.gocryptfs;
                    isFuseInstalled = areDependenciesInstalled.fuse;
                    ready();
                });
            });
        }

        onError: print('Python error: ' + traceback)
    }
}
