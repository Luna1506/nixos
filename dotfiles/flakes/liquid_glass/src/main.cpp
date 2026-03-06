#include "LiquidGlass.hpp"

#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/debug/Log.hpp>

// Globale Plugin-Instanz
static CLiquidGlassPlugin* g_plugin = nullptr;

// ── Pflicht-Exports für Hyprland Plugin-Loader ────────────────────────────────

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPR_API_VERSION;  // aus PluginAPI.hpp
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    g_plugin = new CLiquidGlassPlugin();
    g_plugin->onLoad(handle);

    return PLUGIN_DESCRIPTION_INFO{
        .name        = "Liquid Glass",
        .description = "macOS-style Liquid Glass window effect for Hyprland",
        .author      = "Luna1506",
        .version     = "0.1.0",
    };
}

APICALL EXPORT void PLUGIN_EXIT() {
    if (g_plugin) {
        g_plugin->onUnload();
        delete g_plugin;
        g_plugin = nullptr;
    }
}