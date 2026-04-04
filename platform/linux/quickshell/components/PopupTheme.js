function isProjectCore(preset) {
    return preset === "projectCore"
}

function isBatNoir(preset) {
    return preset === "batNoir"
}

function popupRadius(preset) {
    if (isBatNoir(preset)) return 16
    if (isProjectCore(preset)) return 14
    if (preset === "cleanGlass") return 16
    if (preset === "neonGamer") return 12
    return 10 // densePro
}

function popupBackground(preset, priority) {
    if (isBatNoir(preset)) {
        if (priority === "EMERGENCY") return "#2B151A"
        if (priority === "HIGH") return "#2E2A17"
        if (priority === "MEDIUM") return "#1A252C"
        return "#202227"
    }

    if (isProjectCore(preset)) {
        if (priority === "EMERGENCY") return "#F8DFDF"
        if (priority === "HIGH") return "#F7ECCC"
        if (priority === "MEDIUM") return "#DCEEEE"
        return "#EDEDED"
    }

    if (preset === "cleanGlass") return "#182230"
    if (preset === "neonGamer") return "#111625"
    return "#141c26" // densePro
}

function popupBorder(preset, priority) {
    if (isBatNoir(preset)) {
        if (priority === "EMERGENCY") return "#C44B52"
        if (priority === "HIGH") return "#E1B24A"
        if (priority === "MEDIUM") return "#4BA6C4"
        return "#5F636B"
    }

    if (isProjectCore(preset)) {
        if (priority === "EMERGENCY") return "#EBC7C7"
        if (priority === "HIGH") return "#E7D8AC"
        if (priority === "MEDIUM") return "#BCDADA"
        return "#E3E3E3"
    }

    if (preset === "cleanGlass") {
        if (priority === "EMERGENCY") return "#b94a57"
        if (priority === "HIGH") return "#c88a38"
        if (priority === "MEDIUM") return "#3f82c2"
        return "#3f4d5f"
    }

    if (preset === "neonGamer") {
        if (priority === "EMERGENCY") return "#ff4d8d"
        if (priority === "HIGH") return "#ff9a3c"
        if (priority === "MEDIUM") return "#40b8ff"
        return "#5f6b8a"
    }

    if (priority === "EMERGENCY") return "#8c3d47"
    if (priority === "HIGH") return "#926b35"
    if (priority === "MEDIUM") return "#376c9e"
    return "#334352"
}

function titleColor(preset) {
    if (isBatNoir(preset)) return "#F3F5F8"
    if (isProjectCore(preset)) return "#252A2E"
    if (preset === "neonGamer") return "#f2f8ff"
    return "#ffffff"
}

function subtitleColor(preset) {
    if (isBatNoir(preset)) return "#A5ACB6"
    if (isProjectCore(preset)) return "#7D858E"
    if (preset === "cleanGlass") return "#a7b8cf"
    if (preset === "neonGamer") return "#9db4d9"
    return "#9aacc2"
}

function bodyColor(preset) {
    if (isBatNoir(preset)) return "#D7DDE6"
    if (isProjectCore(preset)) return "#3E464F"
    if (preset === "cleanGlass") return "#d8e4f2"
    if (preset === "neonGamer") return "#dbe8ff"
    return "#d2deeb"
}

function titleSize(preset) {
    if (isProjectCore(preset)) return 14
    if (preset === "densePro") return 13
    return 14
}

function subtitleSize(preset) {
    if (isProjectCore(preset)) return 11
    if (preset === "densePro") return 10
    return 11
}

function bodySize(preset) {
    if (isProjectCore(preset)) return 13
    if (preset === "densePro") return 12
    return 13
}

function badgeColor(priority, preset) {
    if (isBatNoir(preset)) {
        if (priority === "EMERGENCY") return "#B63A42"
        if (priority === "HIGH") return "#C8962E"
        if (priority === "MEDIUM") return "#2F7FA0"
        return "#5A606B"
    }

    if (isProjectCore(preset)) {
        if (priority === "EMERGENCY") return "#BD3124"
        if (priority === "HIGH") return "#B56D00"
        if (priority === "MEDIUM") return "#1A6666"
        return "#767676"
    }

    if (preset === "neonGamer") {
        if (priority === "EMERGENCY") return "#ff3b83"
        if (priority === "HIGH") return "#ff8a20"
        if (priority === "MEDIUM") return "#00a8ff"
        return "#5f7389"
    }

    if (priority === "EMERGENCY") return "#d64045"
    if (priority === "HIGH") return "#e98622"
    if (priority === "MEDIUM") return "#2f88d9"
    return "#4b5f72"
}

function buttonBackground(preset) {
    if (isBatNoir(preset)) return "#1F232C"
    if (isProjectCore(preset)) return "#E8EBEE"
    if (preset === "cleanGlass") return "#2d3746"
    if (preset === "neonGamer") return "#222a3e"
    return "#28313e"
}

function buttonHoverBackground(preset) {
    if (isBatNoir(preset)) return "#2A3040"
    if (isProjectCore(preset)) return "#DCE1E6"
    if (preset === "cleanGlass") return "#39475b"
    if (preset === "neonGamer") return "#2f3a56"
    return "#334052"
}

function buttonBorder(preset) {
    if (isBatNoir(preset)) return "#394154"
    if (isProjectCore(preset)) return "#D0D6DD"
    if (preset === "cleanGlass") return "#4a596f"
    if (preset === "neonGamer") return "#4f5a7f"
    return "#3c4758"
}

function buttonText(preset) {
    if (isBatNoir(preset)) return "#E3E9F3"
    if (isProjectCore(preset)) return "#404850"
    if (preset === "neonGamer") return "#e8f2ff"
    return "#e2ebf5"
}

function panelBackground(preset) {
    if (isBatNoir(preset)) return "#151A24"
    if (isProjectCore(preset)) return "#F2F2F2"
    if (preset === "cleanGlass") return "#111b27"
    if (preset === "neonGamer") return "#0f1422"
    return "#111922"
}

function panelBorder(preset) {
    if (isBatNoir(preset)) return "#2B3242"
    if (isProjectCore(preset)) return "#D6DBE0"
    if (preset === "cleanGlass") return "#3b4b5f"
    if (preset === "neonGamer") return "#3f4a68"
    return "#2E3A4A"
}

function cardSurfaceBackground(preset, priority) {
    if (isProjectCore(preset)) {
        return popupBackground(preset, priority)
    }
    if (preset === "cleanGlass") return "#182430"
    if (preset === "neonGamer") return "#1a2235"
    return "#182430"
}

function cardSurfaceBorder(preset, priority) {
    if (isProjectCore(preset)) {
        return popupBorder(preset, priority)
    }
    if (preset === "cleanGlass") return "#304357"
    if (preset === "neonGamer") return "#43567a"
    return "#304357"
}

function countColorByPriority(preset, priority) {
    if (isBatNoir(preset)) {
        if (priority === "EMERGENCY") return "#E16972"
        if (priority === "HIGH") return "#F1C45C"
        if (priority === "MEDIUM") return "#76BED8"
        return "#A7ADB8"
    }

    if (isProjectCore(preset)) {
        if (priority === "EMERGENCY") return "#BD3124"
        if (priority === "HIGH") return "#B56D00"
        if (priority === "MEDIUM") return "#1A6666"
        return "#767676"
    }
    return badgeColor(priority, preset)
}
