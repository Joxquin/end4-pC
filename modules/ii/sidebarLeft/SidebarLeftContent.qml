import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.synchronizer

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 10
    anchors.fill: parent
    property bool aiChatEnabled: Config.options.policies.ai !== 0
    property bool translatorEnabled: Config.options.sidebar.translator.enable
    property bool animeEnabled: Config.options.policies.weeb !== 0
    property bool animeCloset: Config.options.policies.weeb === 2
    property bool mediaEnabled: Config.options.sidebar.media.enable
    property var tabButtonList: [
        ...(root.aiChatEnabled ? [{"icon": "neurology", "name": Translation.tr("Intelligence")}] : []),
        ...(root.translatorEnabled ? [{"icon": "translate", "name": Translation.tr("Translator")}] : []),
        ...(root.mediaEnabled ? [{"icon": "music_note", "name": Translation.tr("Media")}] : []),
        ...((root.animeEnabled && !root.animeCloset) ? [{"icon": "bookmark_heart", "name": Translation.tr("Anime")}] : [])
    ]
    property int tabCount: swipeView.count

    function focusActiveItem() {
        if (!swipeView.currentItem) return;
        if (swipeView.currentItem.item && typeof swipeView.currentItem.item.forceActiveFocus === "function") {
            swipeView.currentItem.item.forceActiveFocus();
        } else {
            swipeView.currentItem.forceActiveFocus();
        }
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                swipeView.incrementCurrentIndex()
                event.accepted = true;
            }
            else if (event.key === Qt.Key_PageUp) {
                swipeView.decrementCurrentIndex()
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: sidebarPadding
        }
        spacing: verticalTabBar.expanded ? -2 : 0

        VerticalTabBar {
            id: verticalTabBar
            visible: tabButtonList.length > 0
            Layout.fillWidth: true
            tabButtonList: root.tabButtonList
            currentIndex: swipeView.currentIndex
            onCurrentIndexChanged: swipeView.currentIndex = currentIndex
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: swipeView.implicitWidth
            implicitHeight: swipeView.implicitHeight
            topLeftRadius: 0
            bottomLeftRadius: Appearance.rounding.normal
            topRightRadius: 0
            bottomRightRadius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            SwipeView { // Content pages
                id: swipeView
                anchors.fill: parent
                spacing: 10
                currentIndex: tabBar.currentIndex

                clip: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: swipeView.width
                        height: swipeView.height
                        radius: Appearance.rounding.small
                    }
                }

                contentChildren: [
                    ...(root.aiChatEnabled ? [aiChatLoaderComp.createObject(swipeView)] : []),
                    ...(root.translatorEnabled ? [translatorLoaderComp.createObject(swipeView)] : []),
                    ...(root.mediaEnabled ? [mediaLoaderComp.createObject(swipeView)] : []),
                    ...((root.tabButtonList.length === 0 || (!root.aiChatEnabled && !root.translatorEnabled && root.animeCloset)) ? [placeholder.createObject(swipeView)] : []),
                    ...(root.animeEnabled ? [animeLoaderComp.createObject(swipeView)] : []),
                ]
            }
        }

        Component {
            id: aiChatLoaderComp
            Loader {
                id: aiLdr
                property bool visited: false
                active: visited || (swipeView.currentItem === aiLdr)
                Connections {
                    target: swipeView
                    function onCurrentItemChanged() {
                        if (swipeView.currentItem === aiLdr) {
                            aiLdr.visited = true;
                            aiLdr.active = true;
                        }
                    }
                }
                sourceComponent: AiChat {}
            }
        }
        Component {
            id: translatorLoaderComp
            Loader {
                id: transLdr
                property bool visited: false
                active: visited || (swipeView.currentItem === transLdr)
                Connections {
                    target: swipeView
                    function onCurrentItemChanged() {
                        if (swipeView.currentItem === transLdr) {
                            transLdr.visited = true;
                            transLdr.active = true;
                        }
                    }
                }
                sourceComponent: Translator {}
            }
        }
        Component {
            id: mediaLoaderComp
            Loader {
                id: mediaLdr
                property bool visited: false
                active: visited || (swipeView.currentItem === mediaLdr)
                Connections {
                    target: swipeView
                    function onCurrentItemChanged() {
                        if (swipeView.currentItem === mediaLdr) {
                            mediaLdr.visited = true;
                            mediaLdr.active = true;
                        }
                    }
                }
                sourceComponent: SidebarPlayerControl {}
            }
        }
        Component {
            id: animeLoaderComp
            Loader {
                id: animeLdr
                property bool visited: false
                active: visited || (swipeView.currentItem === animeLdr)
                Connections {
                    target: swipeView
                    function onCurrentItemChanged() {
                        if (swipeView.currentItem === animeLdr) {
                            animeLdr.visited = true;
                            animeLdr.active = true;
                        }
                    }
                }
                sourceComponent: Anime {}
            }
        }
        Component {
            id: placeholder
            Item {
                StyledText {
                    anchors.centerIn: parent
                    text: root.animeCloset ? Translation.tr("Nothing") : Translation.tr("Enjoy your empty sidebar...")
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}