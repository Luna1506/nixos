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

Zu Beginn einmal first-run.sh ausführen

Danach in flake.nix den username und ggf auf die Alternative Nvidia config umstellen.
In ./modules/users.nix noch den ausgeschriebenen Namen anpassen

### Wallpaper einrichten:
In ./home/${username}/modules/hyprpaper.nix ggf den Monitornamen anpassen (hyprctl monitors zur Hilfe)
/home/${username}/.config/hypr/wallpapers anlegen
Gewünschtes Wallpaper dort ablegen und wallpaper1.jpg umbenennen und rebuilden
