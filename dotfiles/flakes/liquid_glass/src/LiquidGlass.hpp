#pragma once

#include "GlassRenderer.hpp"

// Hyprland Plugin API >= 0.45
#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/desktop/Window.hpp>
#include <hyprland/src/helpers/Box.hpp>

// Forward
class CHyprPlugin;

class CLiquidGlassPlugin {
public:
    CLiquidGlassPlugin();
    ~CLiquidGlassPlugin();

    // Wird vom Plugin-System aufgerufen
    void onLoad(HANDLE handle);
    void onUnload();

    // Hook-Handler
    static void onRenderWindow(
        void* self,
        PHLWINDOW window,
        CMonitor* monitor,
        timespec* time,
        bool decorate,
        RenderPassType rtype,
        bool noDecoreHints,
        bool ignorePosition
    );

    static void onPreRender();
    static void onConfigReload();

    // Konfiguration neu einlesen
    void reloadConfig();

    static inline CLiquidGlassPlugin* s_instance = nullptr;

private:
    void registerHooks();
    void registerConfig();
    bool shouldApplyGlass(PHLWINDOW window) const;

    HANDLE          m_handle   = nullptr;
    CGlassRenderer  m_renderer;
    SGlassConfig    m_config;

    // Hook-Handles
    HOOK_CALLBACK_FN* m_renderHook    = nullptr;
    HOOK_CALLBACK_FN* m_preRenderHook = nullptr;
    HOOK_CALLBACK_FN* m_configHook    = nullptr;
};