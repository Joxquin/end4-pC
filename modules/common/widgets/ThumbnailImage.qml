import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * Thumbnail image. Generates thumbnails on demand with automatic fallback to original image.
 * See Freedesktop's spec: https://specifications.freedesktop.org/thumbnail-spec/thumbnail-spec-latest.html
 */
StyledImage {
    id: root

    property bool generateThumbnail: true
    required property string sourcePath
    property string thumbnailSizeName: Images.thumbnailSizeNameForDimensions(sourceSize.width, sourceSize.height)
    property string thumbnailPath: {
        if (sourcePath.length == 0) return "";
        const resolvedUrlWithoutFileProtocol = FileUtils.trimFileProtocol(`${Qt.resolvedUrl(sourcePath)}`);
        const encodedUrlWithoutFileProtocol = resolvedUrlWithoutFileProtocol.split("/").map(part => encodeURIComponent(part)).join("/");
        const md5Hash = Qt.md5(`file://${encodedUrlWithoutFileProtocol}`);
        return `${Directories.genericCache}/thumbnails/${thumbnailSizeName}/${md5Hash}.png`;
    }
    
    // Attempt thumbnail first, fall back directly to original image path if thumbnail is missing or errors
    source: thumbnailPath

    asynchronous: true
    smooth: true
    mipmap: false

    opacity: status === Image.Ready ? 1 : 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    onStatusChanged: {
        if (status === Image.Error && source === thumbnailPath) {
            // Fallback directly to original file so image preview is never blank!
            source = sourcePath.startsWith("file://") ? sourcePath : `file://${sourcePath}`;
        }
    }

    onSourceSizeChanged: {
        if (!root.generateThumbnail) return;
        thumbnailGeneration.running = false;
        thumbnailGeneration.running = true;
    }

    Process {
        id: thumbnailGeneration
        running: !!root.generateThumbnail && !!root.sourcePath && !!root.thumbnailPath
        command: {
            const maxSize = Images.thumbnailSizes[root.thumbnailSizeName] || 256;
            const dest = FileUtils.trimFileProtocol(root.thumbnailPath);
            const src = FileUtils.trimFileProtocol(root.sourcePath);
            return ["bash", "-c", 
                `[ -f '${dest}' ] && exit 0 || { mkdir -p "$(dirname '${dest}')" && magick '${src}' -resize ${maxSize}x${maxSize} '${dest}' && exit 1; }`
            ]
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 1) { // Force reload with fresh thumbnail
                root.source = "";
                root.source = root.thumbnailPath;
            }
        }
    }
}
