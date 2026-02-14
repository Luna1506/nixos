{ lib
, stdenv
, fetchurl
, makeWrapper
, autoPatchelfHook

, gtk3
, glib
, nss
, nspr
, alsa-lib
, libpulseaudio
, pipewire
, mesa
, libglvnd

, cairo
, pango
, atk
, at-spi2-atk
, at-spi2-core
, cups
, dbus
, expat
, fontconfig
, freetype
, libdrm
, libxkbcommon
, xorg
, libxcb
, libxshmfence
, libnotify

, libopus
, libsndfile
, libuuid
, libcap
, libsecret
}:

stdenv.mkDerivation rec {
  pname = "teamspeak6";
  version = "6.0.0-beta3.4";

  src = fetchurl {
    url = "https://files.teamspeak-services.com/pre_releases/client/${version}/teamspeak-client.tar.gz";
    sha256 = "b9ba408a0b58170ce32384fc8bba56800840d694bd310050cbadd09246d4bf27";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    gtk3
    glib
    nss
    nspr
    alsa-lib
    libpulseaudio
    pipewire
    mesa
    libglvnd
    cairo
    pango
    atk
    at-spi2-atk
    at-spi2-core
    cups
    dbus
    expat
    fontconfig
    freetype
    libdrm
    libxkbcommon
    libxcb
    libxshmfence
    libnotify
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libXScrnSaver
    xorg.libXtst

    # Audio/WebRTC runtime deps
    libopus
    libsndfile
    libuuid
    libcap
    libsecret
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt/teamspeak6"
    cp -r ./* "$out/opt/teamspeak6/"

    mkdir -p "$out/bin"
    makeWrapper "$out/opt/teamspeak6/TeamSpeak" "$out/bin/teamspeak6" \
      --chdir "$out/opt/teamspeak6" \
      --set TS3CLIENT_HOME "$out/opt/teamspeak6" \
      --set QT_QPA_PLATFORM xcb \
      --set PULSE_SERVER "unix:/run/user/1000/pulse/native" \
      --set PIPEWIRE_REMOTE "pipewire-0" \
      --set SDL_AUDIODRIVER "pulseaudio" \
      --set ALSA_CONFIG_PATH "${alsa-lib}/share/alsa/alsa.conf" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ mesa libglvnd pipewire libpulseaudio alsa-lib ]} \
      --add-flags "--no-sandbox" \
      --add-flags "--ozone-platform=x11" \
      --add-flags "--disable-gpu" \
      --add-flags "--disable-site-isolation-trials" \
      --add-flags "--disable-features=AudioServiceOutOfProcess,AudioServiceSandbox" \
      --add-flags "--enable-features=WebRTCPipeWireCapturer" \
      --add-flags "--enable-logging=stderr" \
      --add-flags "--v=1"

    # Desktop entry + icon for launchers (wofi, rofi, menus)
    mkdir -p \
      "$out/share/applications" \
      "$out/share/icons/hicolor/48x48/apps" \
      "$out/share/icons/hicolor/128x128/apps" \
      "$out/share/icons/hicolor/256x256/apps"

    # Icons shipped by TS6 tarball: logo-48.png / logo-128.png / logo-256.png
    if [ -f "$out/opt/teamspeak6/logo-48.png" ]; then
      cp "$out/opt/teamspeak6/logo-48.png" "$out/share/icons/hicolor/48x48/apps/teamspeak6.png"
    fi
    if [ -f "$out/opt/teamspeak6/logo-128.png" ]; then
      cp "$out/opt/teamspeak6/logo-128.png" "$out/share/icons/hicolor/128x128/apps/teamspeak6.png"
    fi
    if [ -f "$out/opt/teamspeak6/logo-256.png" ]; then
      cp "$out/opt/teamspeak6/logo-256.png" "$out/share/icons/hicolor/256x256/apps/teamspeak6.png"
    fi

    cat > "$out/share/applications/teamspeak6.desktop" <<'EOF'
    [Desktop Entry]
    Type=Application
    Name=TeamSpeak 6
    Comment=TeamSpeak Voice Client
    Exec=teamspeak6
    Icon=teamspeak6
    Terminal=false
    Categories=Network;Chat;
    StartupWMClass=TeamSpeak
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "TeamSpeak 6 Client (beta)";
    homepage = "https://www.teamspeak.com/";
    license = licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
    mainProgram = "teamspeak6";
  };
}
