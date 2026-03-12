cmake_minimum_required(VERSION 3.19)
project(hyprfrost VERSION 0.1.0 LANGUAGES CXX)

# ── C++ standard ──────────────────────────────────────────────────────────────
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS  OFF)

# ── Required packages ─────────────────────────────────────────────────────────
find_package(PkgConfig REQUIRED)

# Hyprland exports a pkg-config file that gives us the right include paths
# and compiler flags.  The Nix flake sets PKG_CONFIG_PATH automatically.
pkg_check_modules(HYPRLAND REQUIRED hyprland)

# OpenGL ES (provided by Mesa on NixOS)
pkg_check_modules(EGL     REQUIRED egl)
pkg_check_modules(GLESV2  REQUIRED glesv2)

# ── Source files ──────────────────────────────────────────────────────────────
add_library(hyprfrost MODULE
    src/main.cpp
    src/FrostedGlassDecoration.cpp
)

# MODULE → .so without a "lib" prefix (Hyprland convention for plugins)
set_target_properties(hyprfrost PROPERTIES
    PREFIX         ""
    SUFFIX         ".so"
    POSITION_INDEPENDENT_CODE ON
)

# ── Include dirs ──────────────────────────────────────────────────────────────
# hyprland.pc provides three -I paths (include, include/hyprland/protocols,
# include/hyprland). We also add include/hyprland/src so that relative
# includes inside Hyprland headers (e.g. "desktop/DesktopTypes.hpp" from
# within render/OpenGL.hpp) resolve via the include search fallback.
pkg_get_variable(HYPRLAND_PREFIX hyprland prefix)
target_include_directories(hyprfrost PRIVATE
    ${HYPRLAND_INCLUDE_DIRS}
    ${HYPRLAND_PREFIX}/hyprland/src
    ${EGL_INCLUDE_DIRS}
    ${GLESV2_INCLUDE_DIRS}
)

# ── Compile flags ─────────────────────────────────────────────────────────────
target_compile_options(hyprfrost PRIVATE
    ${HYPRLAND_CFLAGS_OTHER}
    -Wall
    -Wextra
    -Wno-unused-parameter
    -O2
    -fvisibility=hidden    # only EXPORT symbols are visible
)

# ── Link ──────────────────────────────────────────────────────────────────────
# We do NOT link against Hyprland itself: plugins are dlopened into its process
# and resolve Hyprland symbols at runtime.  We only need EGL / GLESv2 for our
# own shader code.
target_link_libraries(hyprfrost PRIVATE
    ${EGL_LIBRARIES}
    ${GLESV2_LIBRARIES}
)

# ── Install ───────────────────────────────────────────────────────────────────
include(GNUInstallDirs)
install(TARGETS hyprfrost
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}/hyprfrost
)
