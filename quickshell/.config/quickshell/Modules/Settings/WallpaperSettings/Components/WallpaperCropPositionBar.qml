import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

SettingSegmented {
    id: positionBarRoot

    required property var previewRoot
    readonly property string currentPos: {
        let cur = NiriSettingsService.wpCropGravity;
        if (previewRoot.isWider) {
            if (cur.includes("left"))
                return "left";

            if (cur.includes("right"))
                return "right";

            return "center";
        } else {
            if (cur.includes("top"))
                return "top";

            if (cur.includes("bottom"))
                return "bottom";

            return "center";
        }
    }
    readonly property var optionsModel: {
        if (previewRoot.isWider)
            return [{
            "text": "Слева",
            "value": "left"
        }, {
            "text": "По центру",
            "value": "center"
        }, {
            "text": "Справа",
            "value": "right"
        }];
        else
            return [{
            "text": "Сверху",
            "value": "top"
        }, {
            "text": "По центру",
            "value": "center"
        }, {
            "text": "Снизу",
            "value": "bottom"
        }];
    }

    label: "Видимая часть"
    model: optionsModel
    currentValue: currentPos
    visible: previewRoot.isCropMode && (previewRoot.isWider || previewRoot.isTaller)
    onActivated: (val) => {
        previewRoot.selectPosition(val);
    }
}
