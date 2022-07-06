import QtQuick 2.9
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3

UbuntuShape {
    property var defaultTime: 3500
    property bool stateVisible: false

    id: toast
    anchors {
        top: parent.top
        margins: units.gu(2)
        topMargin: units.gu(8)
        horizontalCenter: parent.horizontalCenter
    }
    width: label.width + units.gu(2)
    height: label.height + units.gu(2)

    backgroundColor: (Theme.name == "Ubuntu.Components.Themes.Ambiance") ? "white" : "#202020"
    aspect: UbuntuShape.DropShadow
    radius: "large"
    visible: false
    z: 30

    states: [
        State { when: stateVisible;
            PropertyChanges {   target: toast; opacity: 1.0; anchors.topMargin: units.gu(8);   }
        },
        State { when: !stateVisible;
            PropertyChanges {   target: toast; opacity: 0.0; anchors.topMargin: 0;   }
        }
    ]

    transitions: Transition {
        SpringAnimation {
            spring: 2
            damping: 0.2
            properties: "anchors.topMargin"
        }
        NumberAnimation { property: "opacity"; duration: 250}
    }

    function show(str, time) {
        // print(str)

        if ( !time ) time = defaultTime

        var urlRegex = /(https?:\/\/[^\s]+)/g
        var tempText = str || " "
        if ( tempText === "" ) tempText = " "
        tempText = tempText.replace ( "&#60;", "<" )
        tempText = tempText.replace ( "&#62;", "<" )
        tempText = tempText.replace(urlRegex, function(url) {
            return '<a href="%1"><font color="#CCCCFF">%1</font></a>'.arg(url)
        })

        label.text = tempText

        var maxWidth = root.width - units.gu(6)
        if ( label.width > maxWidth ) label.width = maxWidth

        visible = true
        stateVisible = true
        function Timer() {
            return Qt.createQmlObject("import QtQuick 2.0; Timer {}", root)
        }
        var timer = new Timer()
        timer.interval = time
        timer.repeat = false
        timer.triggered.connect(function () {
            if ( label.text === str ) toast.stateVisible = false
        })
        timer.start();
    }

    Label {
        id: label
        //elide: Text.ElideMiddle
        anchors.centerIn: parent
        text: ""
        wrapMode: Text.Wrap
        onLinkActivated: Qt.openUrlExternally(link)
    }
}
