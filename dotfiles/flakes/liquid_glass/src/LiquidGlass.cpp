#include "LiquidGlass.hpp"

#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/helpers/Box.hpp>
#include <hyprland/src/debug/Log.hpp>

// ── Konstruktor / Destruktor ──────────────────────────────────────────────────

CLiquidGlassPlugin::CLiquidGlassPlugin()  = default;
CLiquidGlassPlugin::~CLiquidGlassPlugin() = default;

// ── Plugin-Lifecycle ──────────────────────────────────────────────────────────

void CLiquidGlassPlugin::onLoad(HANDLE handle) {
    m_handle    = handle;
    s_instance  = this;

    Debug::log(LOG, "[LiquidGlass] Plugin loading…");

    registerConfig();
    reloadConfig();

    if (!m_renderer.init()) {
        Debug::log(ERR, "[LiquidGlass] Renderer init failed – plugin disabled.");
        return;
    }

    registerHooks();
    Debug::log(LOG, "[LiquidGlass] Plugin loaded successfully.");
}

void CLiquidGlassPlugin::onUnload() {
    Debug::log(LOG, "[LiquidGlass] Plugin unloading…");

    if (m_renderHook)    HyprlandAPI::removeHook(m_handle, m_renderHook);
    if (m_preRenderHook) HyprlandAPI::removeHook(m_handle, m_preRenderHook);
    if (m_configHook)    HyprlandAPI::removeHook(m_handle, m_configHook);

    s_instance = nullptr;
}

// ── Konfiguration ─────────────────────────────────────────────────────────────

void CLiquidGlassPlugin::registerConfig() {
    // Konfigurationswerte in hyprland.conf über plugin:liquid_glass { … }
    HyprlandAPI::addConfigValue(m_handle,
        "plugin:liquid_glass:blur_strength",    Hyprlang::FLOAT{18.0f});
    HyprlandAPI::addConfigValue(m_handle,
        "plugin:liquid_glass:refraction",       Hyprlang::FLOAT{0.6f});
    HyprlandAPI::addConfigValue(m_handle,
        "plugin:liquid_glass:opacity",          Hyprlang::FLOAT{0.72f});
    HyprlandAPI::addConfigValue(m_handle,
        "plugin:liquid_glass:corner_radius",    Hyprlang::FLOAT{14.0f});
    HyprlandAPI::addConfigValue(m_handle,
        "plugin:liquid_glass:animate",          Hyprlang::INT{1});
    HyprlandAPI::addConfigValue(m_handle,
        "plugin:liquid_glass:tint_r",           Hyprlang::FLOAT{0.95f});
    HyprlandAPI::addConfigValue(m_handle,
        "plugin:liquid_glass:tint_g",           Hyprlang::FLOAT{0.95f});
    HyprlandAPI::addConfigValue(m_handle,
        "plugin:liquid_glass:tint_b",           Hyprlang::FLOAT{1.0f});
    HyprlandAPI::addConfigValue(m_handle,
        "plugin:liquid_glass:tint_a",           Hyprlang::FLOAT{0.08f});
}

void CLiquidGlassPlugin::reloadConfig() {
    auto getFloat = [&](const char* key, float def) -> float {
        auto* val = HyprlandAPI::getConfigValue(m_handle, key);
        if (!val) return def;
        return std::any_cast<Hyprlang::FLOAT>(val->getValue());
    };
    auto getInt = [&](const char* key, int def) -> int {
        auto* val = HyprlandAPI::getConfigValue(m_handle, key);
        if (!val) return def;
        return static_cast<int>(std::any_cast<Hyprlang::INT>(val->getValue()));
    };

    m_config.blurStrength   = getFloat("plugin:liquid_glass:blur_strength",  18.0f);
    m_config.refractionStr  = getFloat("plugin:liquid_glass:refraction",      0.6f);
    m_config.opacity        = getFloat("plugin:liquid_glass:opacity",         0.72f);
    m_config.cornerRadius   = getFloat("plugin:liquid_glass:corner_radius",   14.0f);
    m_config.animate        = getInt  ("plugin:liquid_glass:animate",         1) != 0;
    m_config.tintColor[0]   = getFloat("plugin:liquid_glass:tint_r",          0.95f);
    m_config.tintColor[1]   = getFloat("plugin:liquid_glass:tint_g",          0.95f);
    m_config.tintColor[2]   = getFloat("plugin:liquid_glass:tint_b",          1.0f);
    m_config.tintColor[3]   = getFloat("plugin:liquid_glass:tint_a",          0.08f);

    m_renderer.setConfig(m_config);
    Debug::log(LOG, "[LiquidGlass] Config reloaded.");
}

// ── Hooks registrieren ────────────────────────────────────────────────────────

void CLiquidGlassPlugin::registerHooks() {
    // renderWindow – nach dem normalen Fenster-Rendering einhaken
    m_renderHook = HyprlandAPI::registerCallbackDynamic(
        m_handle,
        "renderWindow",
        [](void* self, SCallbackInfo&, std::any data) {
            auto* window = std::any_cast<PHLWINDOW>(data);
            if (window && CLiquidGlassPlugin::s_instance)
                CLiquidGlassPlugin::s_instance->onRenderWindow(
                    self, window, nullptr, nullptr,
                    true, RenderPassType::PASS_ALL, false, false
                );
        }
    );

    // configReloaded – Konfiguration neu einlesen
    m_configHook = HyprlandAPI::registerCallbackDynamic(
        m_handle,
        "configReloaded",
        [](void*, SCallbackInfo&, std::any) {
            if (CLiquidGlassPlugin::s_instance)
                CLiquidGlassPlugin::s_instance->reloadConfig();
        }
    );

    Debug::log(LOG, "[LiquidGlass] Hooks registered.");
}

// ── Fenster rendern ───────────────────────────────────────────────────────────

bool CLiquidGlassPlugin::shouldApplyGlass(PHLWINDOW window) const {
    if (!window) return false;
    // Schwebende / floating Fenster bevorzugen, aber auch Tiles erlaubt
    // Sonderfenster (z.B. Systemleisten) ausschließen
    if (window->m_bIsX11 && window->m_iX11Type == 2) return false;
    return true;
}

void CLiquidGlassPlugin::onRenderWindow(
    void*,
    PHLWINDOW       window,
    CMonitor*,
    timespec*,
    bool,
    RenderPassType,
    bool,
    bool)
{
    if (!s_instance || !s_instance->m_renderer.isReady()) return;
    if (!s_instance->shouldApplyGlass(window)) return;

    const auto& geo = window->m_vRealPosition.value();
    const auto& siz = window->m_vRealSize.value();

    CBox box{
        static_cast<double>(geo.x),
        static_cast<double>(geo.y),
        static_cast<double>(siz.x),
        static_cast<double>(siz.y)
    };

    float alpha = window->m_fActiveInactiveAlpha.value();

    s_instance->m_renderer.renderWindow(
        window, box, alpha, s_instance->m_config
    );
}