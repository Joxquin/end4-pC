import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    required property var fileModelData
    property size sourceSize: Qt.size(width, height)

    readonly property bool isDir: fileModelData?.fileIsDir ?? false

    // If it's a directory, display a modern vector Material Symbol folder icon with theme colors
    MaterialSymbol {
        id: dirSymbol
        visible: root.isDir
        anchors.centerIn: parent
        iconSize: Math.min(parent.width, parent.height) * 0.55
        fill: 1
        text: {
            if (!root.isDir) return "draft";
            const p = fileModelData?.filePath ? FileUtils.trimFileProtocol(fileModelData.filePath) : "";
            if (p === FileUtils.trimFileProtocol(Directories.pictures) || p.endsWith("/Wallpapers")) return "wallpaper";
            if (p === FileUtils.trimFileProtocol(Directories.downloads)) return "download";
            if (p === FileUtils.trimFileProtocol(Directories.documents)) return "description";
            if (p === FileUtils.trimFileProtocol(Directories.music)) return "music_note";
            if (p === FileUtils.trimFileProtocol(Directories.videos)) return "movie";
            if (p === FileUtils.trimFileProtocol(Directories.home)) return "home";
            return "folder";
        }
        color: Appearance.colors.colPrimary
    }

    // If it's a non-image file, show system icon or generic file icon
    StyledImage {
        id: fileImage
        visible: !root.isDir
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        source: {
            if (root.isDir) return "";
            return Quickshell.iconPath("application-x-zerosize");
        }

        onStatusChanged: {
            if (status === Image.Error)
                source = Quickshell.iconPath("text-plain", "image-missing");
        }
    }

    Process {
        running: !root.isDir && !!fileModelData?.filePath
        command: ["file", "--mime", "-b", fileModelData?.filePath ?? ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.isDir) return;
                const mime = text.split(";")[0].replace("/", "-");
                fileImage.source = Images.validImageTypes.some(t => mime === `image-${t}`)
                    ? (fileModelData.fileUrl || `file://${fileModelData.filePath}`)
                    : Quickshell.iconPath(mime, "image-missing");
            }
        }
    }
}
