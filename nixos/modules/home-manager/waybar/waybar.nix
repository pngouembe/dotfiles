{ config, ... }:
{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        modules-left = ["wlr/workspaces"];
        modules-center = [];
        modules-right = ["pulseaudio" "clock" "tray" "custom/power"];

        "wlr/workspaces" = {
          disable-scroll = true;
          sort-by-name = true;
          format = "{icon}";
          format-icons = {default = "";};
        };

        pulseaudio = {
          format = " {icon} ";
          format-muted = " ";
          format-icons = ["" "" ""];
          tooltip = true;
          tooltip-format = "{volume}%";
        };

        backlight = {
          device = "intel_backlight";
          format = "{icon}";
          format-icons = ["" "" "" "" "" "" "" "" ""];
          tooltip = true;
          tooltip-format = "{percent}%";
        };

        "custom/power" = {
          tooltip = false;
          on-click = "powermenu";
          format = "";
        };

        clock = {
          tooltip-format = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
          format-alt = "{:%d-%m-%Y}";
          format = "{:%H:%M}";
        };

        tray = {
          icon-size = 21;
          spacing = 10;
        };
      };
    };

    style = builtins.readFile ./config/style.css;
  };

  home.file."${config.xdg.configHome}/waybar/mocha.css".source = ./config/mocha.css;
}