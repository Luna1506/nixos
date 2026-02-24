{ lib
, fetchFromGitHub
, hyprlandPlugins
, pkg-config
,
}:

hyprlandPlugins.mkHyprlandPlugin (finalAttrs: {
  pluginName = "liquid-glass";
  version = "unstable-2026-02-24";

  src = fetchFromGitHub {
    owner = "purple-lines";
    repo = "liquid-glass-plugin-hyprpm";
    # Tipp: pinne auf einen Commit, damit es reproduzierbar ist
    rev = "main";
    # Erstmal Fake-Hash, dann rebuild -> Hash aus Fehlermeldung übernehmen
    hash = lib.fakeSha256;
  };

  nativeBuildInputs = [
    pkg-config
  ];

  # Falls das Repo "make all" erwartet: mkHyprlandPlugin kann i.d.R. cmake/make,
  # aber wenn es zickt, kann man später overrideBuildPhase ergänzen.
  meta = {
    homepage = "https://github.com/purple-lines/liquid-glass-plugin-hyprpm";
    description = "Liquid Glass effect plugin for Hyprland";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
