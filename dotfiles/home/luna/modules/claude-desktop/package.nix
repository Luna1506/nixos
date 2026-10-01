{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gsettings-desktop-schemas,
  gtk3,
  libcap_ng,
  libdrm,
  libgbm,
  libGL,
  libnotify,
  libpulseaudio,
  libseccomp,
  libsecret,
  libuuid,
  libxkbcommon,
  nspr,
  nss,
  pango,
  pipewire,
  systemd,
  vulkan-loader,
  xdg-utils,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxtst,
  libxcb,
  libxshmfence,
}:

# Official Claude Desktop Linux build (beta), repackaged from Anthropic's apt
# repository. The pool keeps old versions, so pinned URLs stay valid.
# Update: bump version, then `nix store prefetch-file <url>` for the hash.
stdenv.mkDerivation (finalAttrs: {
  pname = "claude-desktop";
  version = "2.9939.4";

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${finalAttrs.version}_amd64.deb";
    hash = "sha256-PP3bI78pEeBeJ7TtOFa455XflGQ7LDW1nesxfPmVvKA=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libcap_ng # bundled virtiofsd (Cowork)
    libdrm
    libgbm
    libnotify
    libpulseaudio
    libseccomp # bundled virtiofsd (Cowork)
    libsecret
    libuuid
    libxkbcommon
    nspr
    nss
    pango
    systemd
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxtst
    libxcb
    libxshmfence
  ];

  # Loaded with dlopen at runtime, invisible to autoPatchelf.
  runtimeLibs = [
    libGL
    libpulseaudio
    pipewire # WebRTC screen sharing
    libnotify
    libsecret
    systemd
    vulkan-loader
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile $src | tar -x --no-same-owner --no-same-permissions
    runHook postUnpack
  '';

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin
    cp -r usr/lib/claude-desktop $out/lib/
    cp -r usr/share $out/share
    rm -rf $out/share/lintian

    # The setuid sandbox helper cannot be setuid in the store; Chromium falls
    # back to the user-namespace sandbox.
    rm $out/lib/claude-desktop/chrome-sandbox

    makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath finalAttrs.runtimeLibs} \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --prefix XDG_DATA_DIRS : ${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:${gtk3}/share/gsettings-schemas/${gtk3.name} \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

    substituteInPlace $out/share/applications/com.anthropic.Claude.desktop \
      --replace-fail "Exec=claude-desktop" "Exec=$out/bin/claude-desktop"

    runHook postInstall
  '';

  meta = {
    description = "Claude Desktop (official Linux beta build)";
    homepage = "https://claude.ai";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
  };
})
