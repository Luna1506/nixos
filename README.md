# Lunas Nixos Setup
## Setup anpassen
### Für das erste mal:
Projekt an die gewünschte stelle clonen mit 
```
git clone https://github.com/Luna1506/nixos.git
```
Danach das sich in dem Ordner nixos befindene Script update-setup.sh ausführen, welches ab sofort immer für weitere Updates verwendet werden sollte:
### Optionen:
#### Usage:
```
update-setup.sh --username <name>
```

#### Required:
```
--username <name>
```

#### Options:
```
--fullname "<Full Name>"
--repo <url>                 (default: https://github.com/Luna1506/dotfiles.git)
--dest <path>                (default: ~/nixos)
--branch <name>              (default: main)
--nvidia-alt <true|false>
--monitor <name>             (default: eDP-1)
--zoom <string>              (default: "1") e.g. "1.5"
--no-first-run
-h, --help
```

#### Example (imaginary person):
```
./update-setup.sh --username timp --fullname 'Tim Pagels' --nvidia-alt true --dest ~/src/nixos/dotfiles --monitor 'HDMI-A-1' --zoom '1.5'
```
#### Rebuilden (im nixos Directory):
```
rebuild
```
Beachte, dass beim ersten Laden des Systems der Alias noch nicht geht und stattdessen folgendes notwendig ist:
```
sudo nixos-rebuild switch --flake ./dotfiles#nixos
```

## Wallpaper einrichten:
```
mkdir /home/<username>/.config/hypr/wallpapers
```
Danach in dem Directory eine Datei mit folgendem Namen ablegen:
```
wallpaper1.jpg
```

## Weitere Aliases:
### Zum Rebuilden:
```
rebuild = "sudo nixos-rebuild switch --flake ./dotfiles#nixos";
```

### Zum Updaten aller Pakete:
```
update = "cd ./dotfiles && nix flake update && cd -";
```

### Zum Entfernen ungenutzer Dateien/Pakete:
```
garbage = "sudo nix-collect-garbage";
```

### Zum Aufräumen aller ungenutzen Nixos Generationen, bis auf die letzten 5:
```
clear_efi = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5";
```

### Führt garbage und clear_efi zusammen durch:
```
clean = ''
  sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5 &&
  sudo nix-collect-garbage
'';
```

### Nur für die imaginäre Person, weil sie faul ist:
```
setup_tim = "./update-setup.sh --username timp --fullname 'Tim Pagels' --nvidia-alt true --dest ~/src/nixos/dotfiles --monitor 'HDMI-A-1' --zoom '1.5'";
```
