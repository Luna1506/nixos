{ pkgs, lib, ... }:

let
  liquidGlassPlugin =
    pkgs.hyprlandPlugins.mkHyprlandPlugin (finalAttrs: {
      pluginName = "liquid-glass";
      version = "git";

      src = pkgs.fetchFromGitHub {
        owner = "purple-lines";
        repo = "liquid-glass-plugin-hyprpm";

        # Empfehlung: pinne auf einen Commit, nicht auf "main".
        # Beispiel: rev = "a1b2c3d4...";
        rev = "main";

        # Ersetze das nach dem ersten Build durch den echten sha256 aus der Fehlermeldung.
        hash = lib.fakeSha256;
      };

      nativeBuildInputs = with pkgs; [
        pkg-config
        gnumake
      ];

      # Das Repo baut via `make all` und erzeugt `liquid-glass.so` im Projektroot. :contentReference[oaicite:2]{index=2}
      buildPhase = ''
        runHook preBuild
        make all
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/lib
        # Hyprland erwartet ein .so im Output; Name ist hier egal, solange es ein plugin .so ist
        # und über `wayland.windowManager.hyprland.plugins` geladen wird.
        install -m755 liquid-glass.so $out/lib/liquid-glass.so
        runHook postInstall
      '';

      meta = with lib; {
        description = "Apple-style Liquid Glass effect plugin for Hyprland";
        homepage = "https://github.com/purple-lines/liquid-glass-plugin-hyprpm";
        license = licenses.mit;
        platforms = platforms.linux;
      };
    });
in
{
  # Export fürs Hyprland-Module
  config.hyprMacos.liquidGlassPlugin = liquidGlassPlugin;
}
