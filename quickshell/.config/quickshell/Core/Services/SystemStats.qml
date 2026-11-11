import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: root

    property string osName: "Linux"
    property string hostModel: ""
    property string kernel: "Загрузка…"
    property string hostname: "Загрузка…"
    property string username: "Загрузка…"
    property string shell: "Загрузка…"
    property string wm: "niri (Wayland)"
    property string packages: "Загрузка…"
    property string display: "Загрузка…"
    property string cpuModel: "Загрузка…"
    property string cpuCores: "Загрузка…"
    property string memTotal: "0 GB"
    property string diskTotal: "0 GB"
    property string gpuName: "None"
    property bool hasGpu: false
    property int avatarRevision: 0
    property bool hasAvatar: false
    readonly property url avatarSource: hasAvatar ? "file://" + Quickshell.env("HOME") + "/.face?v=" + avatarRevision : ""

    Component.onCompleted: {
        if (!staticInfoProc.running)
            staticInfoProc.running = true;

    }

    Process {
        // command output is parsed: keep it in English with dot decimals
        environment: ({"LC_ALL": "C.UTF-8"})

        id: staticInfoProc

        command: ["python3", Quickshell.shellDir + "/Scripts/system/get_system_info.py"]
        running: true
        onExited: (exitCode) => {
            if (exitCode === 0) {
                try {
                    let info = JSON.parse(staticStdout.text.trim());
                    root.osName = info.os || "Linux";
                    root.hostModel = info.host || "";
                    root.kernel = info.kernel || "";
                    root.hostname = info.hostname || "";
                    root.username = info.username || "";
                    root.hasAvatar = info.has_avatar === true || root.avatarRevision > 0;
                    root.shell = info.shell || "";
                    root.wm = info.wm || "niri (Wayland)";
                    root.packages = info.packages || "";
                    root.display = info.display || "";
                    root.cpuModel = info.cpu_model || "";
                    root.cpuCores = info.cpu_cores || "";
                    root.memTotal = info.ram_total || "0 GB";
                    root.diskTotal = info.disk_total || "0 GB";
                    root.gpuName = info.gpus || "None";
                    root.hasGpu = root.gpuName !== "" && root.gpuName !== "None" && root.gpuName !== "Integrated Graphics";
                } catch (e) {
                    console.error("Error parsing get_system_info.py JSON: " + e);
                }
            }
        }

        stdout: StdioCollector {
            id: staticStdout
        }

    }

}
