// ─── hyprfrost – main.cpp ─────────────────────────────────────────────────────
//
// Plugin entry / exit points + config registration + window-lifecycle hooks.
//
// How the plugin attaches itself
// ───────────────────────────────
//   • On load (PLUGIN_INIT) we register all config keys and hook into two
//     Hyprland events:
//       – "openWindow"    → attach decoration to every new window
//       – "closeWindow"   → nothing needed; decoration is cleaned up by
//                           Hyprland's normal decoration lifecycle
//   • We also iterate existing windows so the effect applies immediately
//     after the plugin is loaded at runtime (e.g. via `hyprpm`).

#include "globals.hpp"
#include "FrostedGlassDecoration.hpp"

#include <hyprland/src/Compositor.hpp>   // g_pCompositor
#include <hyprland/src/desktop/Window.hpp>

#include <string>
#include <memory>

// ── forward declarations ──────────────────────────────────────────────────────
static void onOpenWindow(void*, SCallbackInfo&, std::any);
static void attachToWindow(PHLWINDOW pWindow);

// ── static callback handles (keep alive for the plugin lifetime) ──────────────
static std::shared_ptr<HOOK_CALLBACK_FN> s_cbOpen;

// ─────────────────────────────────────────────────────────────────────────────
// PLUGIN_INIT
// ─────────────────────────────────────────────────────────────────────────────
APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    PHANDLE = handle;

    // ── Hyprland API version guard ────────────────────────────────────────────
    // Abort early with a helpful message if the API changed incompatibly.
    const std::string HYPR_API_VER = __hyprland_api_version;
    HyprlandAPI::addNotification(
        PHANDLE,
        "[hyprfrost] loaded (Hyprland API " + HYPR_API_VER + ")",
        CHyprColor{0.2f, 0.9f, 0.5f, 1.f},
        4000);

    // ── Register config values ────────────────────────────────────────────────
    // All keys live under the  plugin:hyprfrost  namespace so they don't
    // collide with Hyprland's own keys.  Users add them to hyprland.conf:
    //
    //   plugin {
    //     hyprfrost {
    //       enabled     = true
    //       tint_r      = 0.12
    //       tint_g      = 0.12
    //       tint_b      = 0.18
    //       tint_alpha  = 0.55
    //       noise_amount = 0.04
    //       noise_scale  = 280.0
    //       rounding     = -1      # -1 = inherit window's own rounding
    //     }
    //   }

    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:enabled",      Hyprlang::INT{1});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:tint_r",       Hyprlang::FLOAT{0.12f});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:tint_g",       Hyprlang::FLOAT{0.12f});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:tint_b",       Hyprlang::FLOAT{0.18f});
    // tint_alpha controls *both* the glass opacity and the noise layer opacity.
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:tint_alpha",   Hyprlang::FLOAT{0.55f});
    // noise_amount: strength of the procedural grain (0 = off, 0.04 = subtle)
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:noise_amount", Hyprlang::FLOAT{0.04f});
    // noise_scale: pixel scale of the noise grid (larger = coarser grain)
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:noise_scale",  Hyprlang::FLOAT{280.f});
    // rounding: corner radius in pixels; -1 = use window's decoration:rounding
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:rounding",     Hyprlang::INT{-1});

    // ── Hook: openWindow ──────────────────────────────────────────────────────
    s_cbOpen = HyprlandAPI::registerCallbackDynamic(
        PHANDLE, "openWindow", onOpenWindow);

    // ── Attach to already-open windows (hot-load support) ────────────────────
    for (auto& pWindow : g_pCompositor->m_vWindows) {
        if (pWindow && pWindow->m_bIsMapped && !pWindow->m_bHidden)
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
    // Hyprland removes all decorations registered by this plugin automatically
    // when the plugin is unloaded.  We just need to release our callback handle.
    s_cbOpen.reset();
}

// ─────────────────────────────────────────────────────────────────────────────
// helpers
// ─────────────────────────────────────────────────────────────────────────────
static void attachToWindow(PHLWINDOW pWindow) {
    HyprlandAPI::addWindowDecoration(
        PHANDLE, pWindow,
        std::make_shared<CFrostedGlassDecoration>(pWindow));
}

static void onOpenWindow(void* /*self*/, SCallbackInfo& /*info*/, std::any data) {
    auto pWindow = std::any_cast<PHLWINDOW>(data);
    if (!pWindow)
        return;
    attachToWindow(pWindow);
}
