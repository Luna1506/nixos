// ─── hyprfrost – main.cpp ─────────────────────────────────────────────────────
//
// Plugin entry / exit points + config registration + window-lifecycle hooks.
//
// How the plugin attaches itself
// ───────────────────────────────
//   • On load (PLUGIN_INIT) we register all config keys and hook into
//     the window.open event via the EventBus signal API.
//   • We also iterate existing windows so the effect applies immediately
//     after the plugin is loaded at runtime (e.g. via `hyprpm`).

#include "globals.hpp"
#include "FrostedGlassDecoration.hpp"

#include <hyprland/src/Compositor.hpp>           // g_pCompositor
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/helpers/memory/Memory.hpp>

#include <string>

// ── forward declarations ──────────────────────────────────────────────────────
static void attachToWindow(PHLWINDOW pWindow);

// ── static signal listener (keep alive for the plugin lifetime) ───────────────
static CHyprSignalListener s_cbOpen;

// ─────────────────────────────────────────────────────────────────────────────
// PLUGIN_INIT
// ─────────────────────────────────────────────────────────────────────────────
APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    PHANDLE = handle;

    // ── Hyprland API version guard ────────────────────────────────────────────
    const std::string HYPR_API_VER = __hyprland_api_get_hash();
    HyprlandAPI::addNotification(
        PHANDLE,
        "[hyprfrost] loaded (Hyprland API " + HYPR_API_VER + ")",
        CHyprColor{0.2f, 0.9f, 0.5f, 1.f},
        4000);

    // ── Register config values ────────────────────────────────────────────────
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:enabled",      Hyprlang::INT{1});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:tint_r",       Hyprlang::FLOAT{0.12f});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:tint_g",       Hyprlang::FLOAT{0.12f});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:tint_b",       Hyprlang::FLOAT{0.18f});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:tint_alpha",   Hyprlang::FLOAT{0.55f});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:noise_amount", Hyprlang::FLOAT{0.04f});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:noise_scale",  Hyprlang::FLOAT{280.f});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:rounding",     Hyprlang::INT{-1});

    // ── Hook: window.open via EventBus ────────────────────────────────────────
    s_cbOpen = Event::bus()->m_events.window.open.listen([](PHLWINDOW pWindow) {
        if (pWindow)
            attachToWindow(pWindow);
    });

    // ── Attach to already-open windows (hot-load support) ────────────────────
    for (auto& pWindow : g_pCompositor->m_windows) {
        if (pWindow && pWindow->m_isMapped && !pWindow->isHidden())
            attachToWindow(pWindow);
    }

    return PLUGIN_DESCRIPTION_INFO{
        .name        = "hyprfrost",
        .description = "macOS-style frosted-glass effect for every Hyprland window",
        .author      = "hyprfrost contributors",
        .version     = "0.1.0",
    };
}

// ─────────────────────────────────────────────────────────────────────────────
// PLUGIN_EXIT
// ─────────────────────────────────────────────────────────────────────────────
APICALL EXPORT void PLUGIN_EXIT() {
    s_cbOpen.reset();
}

// ─────────────────────────────────────────────────────────────────────────────
// helpers
// ─────────────────────────────────────────────────────────────────────────────
static void attachToWindow(PHLWINDOW pWindow) {
    HyprlandAPI::addWindowDecoration(
        PHANDLE, pWindow,
        makeUnique<CFrostedGlassDecoration>(pWindow));
}
