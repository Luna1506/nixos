### Setup anpassen
Zu Beginn einmal first-run.sh ausführen

Danach in flake.nix den username und ggf auf die Alternative Nvidia config umstellen.
In ./modules/users.nix noch den ausgeschriebenen Namen anpassen

### Wallpaper einrichten:
In ./home/${username}/modules/hyprpaper.nix ggf den Monitornamen anpassen (hyprctl monitors zur Hilfe)
/home/${username}/.config/hypr/wallpapers anlegen
Gewünschtes Wallpaper dort ablegen und wallpaper1.jpg umbenennen und rebuilden
