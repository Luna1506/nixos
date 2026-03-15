// ─── hyprfrost – main.cpp ─────────────────────────────────────────────────────
#include "globals.hpp"
#include "FrostedGlassDecoration.hpp"

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/helpers/memory/Memory.hpp>
#include <hyprland/src/managers/HookSystemManager.hpp>

#include <string>
#include <any>

static void attachToWindow(PHLWINDOW pWindow);
static SP<HOOK_CALLBACK_FN> s_cbOpen;

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    PHANDLE = handle;

    const std::string COMPOSITOR_HASH = __hyprland_api_get_hash();
    const std::string CLIENT_HASH     = __hyprland_api_get_client_hash();

    if (COMPOSITOR_HASH != CLIENT_HASH) {
        HyprlandAPI::addNotification(PHANDLE,
            "[hyprfrost] hash mismatch: compositor=" + COMPOSITOR_HASH + " client=" + CLIENT_HASH,
            CHyprColor{1.0f, 0.8f, 0.0f, 1.0f}, 8000);
        // kein throw — wir schauen ob es trotzdem läuft
    }

    HyprlandAPI::addNotification(PHANDLE, "[hyprfrost] loaded!",
        CHyprColor{0.2f, 0.9f, 0.5f, 1.f}, 4000);

    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:enabled",      Hyprlang::INT{1});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:tint_r",       Hyprlang::FLOAT{0.12f});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:tint_g",       Hyprlang::FLOAT{0.12f});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:tint_b",       Hyprlang::FLOAT{0.18f});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:tint_alpha",   Hyprlang::FLOAT{0.55f});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:noise_amount", Hyprlang::FLOAT{0.04f});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:noise_scale",  Hyprlang::FLOAT{280.f});
    HyprlandAPI::addConfigValue(PHANDLE, "plugin:hyprfrost:rounding",     Hyprlang::INT{-1});

    s_cbOpen = g_pHookSystem->hookDynamic("openWindow",
        [](void*, SCallbackInfo&, std::any data) {
            auto pWindow = std::any_cast<PHLWINDOW>(data);
            if (pWindow)
                attachToWindow(pWindow);
        });

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

APICALL EXPORT void PLUGIN_EXIT() {
    s_cbOpen.reset();
}

static void attachToWindow(PHLWINDOW pWindow) {
    HyprlandAPI::addWindowDecoration(
        PHANDLE, pWindow,
        makeUnique<CFrostedGlassDecoration>(pWindow));
}
