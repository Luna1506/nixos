cmake_minimum_required(VERSION 3.20)
project(hypr-liquid-glass VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Hyprland headers
if(DEFINED HYPRLAND_HEADERS)
    include_directories(${HYPRLAND_HEADERS})
else()
    include_directories(/usr/include/hyprland)
endif()

find_package(PkgConfig REQUIRED)
pkg_check_modules(DEPS REQUIRED
    wayland-client
    wayland-server
    gl
    cairo
    pango
    pangocairo
    pixman-1
)

include_directories(${DEPS_INCLUDE_DIRS})
link_directories(${DEPS_LIBRARY_DIRS})

# Shader als eingebetteten String kompilieren
file(READ src/shaders/liquid_glass.vert VERT_SHADER_SRC)
file(READ src/shaders/liquid_glass.frag FRAG_SHADER_SRC)

configure_file(
    ${CMAKE_SOURCE_DIR}/src/shaders/ShaderSources.hpp.in
    ${CMAKE_BINARY_DIR}/ShaderSources.hpp
    @ONLY
)

include_directories(${CMAKE_BINARY_DIR})

set(SOURCES
    src/main.cpp
    src/LiquidGlass.cpp
    src/GlassRenderer.cpp
)

add_library(hypr-liquid-glass SHARED ${SOURCES})

target_compile_options(hypr-liquid-glass PRIVATE
    -Wall
    -Wextra
    -O3
    -fPIC
    -flto
)

target_link_libraries(hypr-liquid-glass
    ${DEPS_LIBRARIES}
    GL
    pthread
)

set_target_properties(hypr-liquid-glass PROPERTIES
    PREFIX "lib"
    SUFFIX ".so"
    OUTPUT_NAME "hypr-liquid-glass"
)