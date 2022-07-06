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

UbuntuShape {
    property string headerText
    property string contentText
    property string url

    anchors {
        left: parent.left
        right: parent.right
        leftMargin: units.gu(3)
        rightMargin: units.gu(3)
    }

    radius: "small"
    // color: theme.palette.normal.raised
    height: (!!headerText ? headerLabel.contentHeight : 0) + contentLabel.contentHeight + (units.gu(2) * 2.5)

    Label {
        id: headerLabel

        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
            leftMargin: !!headerText ? units.gu(2) : 0
            topMargin: !!headerText ? units.gu(2) : -(height/3)
            rightMargin: !!headerText ? units.gu(2) : 0
        }
        height: implicitHeight
        visible: !!headerText

        text: headerText
        textSize: Label.Small
    }

    Label {
        id: contentLabel

        anchors {
            left: parent.left
            right: parent.right
            top: headerLabel.bottom
            topMargin: units.gu(2)/2
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
        }

        wrapMode: Text.Wrap

        text: contentText
    }

    Button {
        id: openUrlButton

        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            topMargin: units.gu(2)
            rightMargin: units.gu(2)
            bottomMargin: units.gu(2)
        }

        width: units.gu(4)

        color: "transparent"
        visible: !!url

        Icon {
            anchors.centerIn: parent
            width: units.gu(3); height: width
            name: "external-link"
        }

        onClicked: Qt.openUrlExternally(url);
    }
}
