function popupRadius(preset) {
    if (preset === "cleanGlass") return 16
    if (preset === "neonGamer") return 12
    return 10 // densePro
}

function popupBackground(preset) {
    if (preset === "cleanGlass") return "#182230"
    if (preset === "neonGamer") return "#111625"
    return "#141c26" // densePro
}

function popupBorder(preset, priority) {
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
    if (preset === "neonGamer") return "#f2f8ff"
    return "#ffffff"
}

function subtitleColor(preset) {
    if (preset === "cleanGlass") return "#a7b8cf"
    if (preset === "neonGamer") return "#9db4d9"
    return "#9aacc2"
}

function bodyColor(preset) {
    if (preset === "cleanGlass") return "#d8e4f2"
    if (preset === "neonGamer") return "#dbe8ff"
    return "#d2deeb"
}

function titleSize(preset) {
    if (preset === "densePro") return 13
    return 14
}

function subtitleSize(preset) {
    if (preset === "densePro") return 10
    return 11
}

function bodySize(preset) {
    if (preset === "densePro") return 12
    return 13
}

function badgeColor(priority, preset) {
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
    if (preset === "cleanGlass") return "#2d3746"
    if (preset === "neonGamer") return "#222a3e"
    return "#28313e"
}

function buttonHoverBackground(preset) {
    if (preset === "cleanGlass") return "#39475b"
    if (preset === "neonGamer") return "#2f3a56"
    return "#334052"
}

function buttonBorder(preset) {
    if (preset === "cleanGlass") return "#4a596f"
    if (preset === "neonGamer") return "#4f5a7f"
    return "#3c4758"
}

function buttonText(preset) {
    if (preset === "neonGamer") return "#e8f2ff"
    return "#e2ebf5"
}
