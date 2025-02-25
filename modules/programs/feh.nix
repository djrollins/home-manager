{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.feh;
  mkInstallOption = hm.options.mkInstallOptionWithDefault config.programs.installPackages;

  bindingsOf = t: with types; attrsOf (nullOr (either t (listOf t)));

  renderBindings = bindings:
    let
      enabled = filterAttrs (n: v: v != null) bindings;
      disabled = filterAttrs (n: v: v == null) bindings;
      render = mapAttrsToList renderBinding;
    in concatStringsSep "\n" (render disabled ++ render enabled);

  renderBinding = func: key:
    if key == null then
      func
    else if isList key then
      concatStringsSep " " ([ func ] ++ map toString key)
    else
      "${func} ${toString key}";

in {
  options.programs.feh = {
    enable = mkEnableOption "feh - a fast and light image viewer";

    install = mkInstallOption "feh";

    package = mkPackageOption pkgs "feh" { };

    buttons = mkOption {
      default = { };
      type = with types; bindingsOf (either str int);
      example = {
        zoom_in = 4;
        zoom_out = "C-4";
        prev_img = [ 3 "C-3" ];
      };
      description = ''
        Override feh's default mouse button mapping. If you want to disable an
        action, set its value to null. If you want to bind multiple buttons to
        an action, set its value to a list.
        See <https://man.finalrewind.org/1/feh/#x425554544f4e53> for
        default bindings and available commands.
      '';
    };

    keybindings = mkOption {
      default = { };
      type = bindingsOf types.str;
      example = {
        zoom_in = "plus";
        zoom_out = "minus";
        prev_img = [ "h" "Left" ];
      };
      description = ''
        Override feh's default keybindings. If you want to disable a keybinding
        set its value to null. If you want to bind multiple keys to an action,
        set its value to a list.
        See <https://man.finalrewind.org/1/feh/#x4b455953> for
        default bindings and available commands.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = ((filterAttrs (n: v: v == "") cfg.keybindings) == { });
      message =
        "To disable a keybinding, use `null` instead of an empty string.";
    }];

    home.packages = optional cfg.install cfg.package;

    xdg.configFile."feh/buttons" =
      mkIf (cfg.buttons != { }) { text = renderBindings cfg.buttons + "\n"; };

    xdg.configFile."feh/keys" = mkIf (cfg.keybindings != { }) {
      text = renderBindings cfg.keybindings + "\n";
    };
  };
}
