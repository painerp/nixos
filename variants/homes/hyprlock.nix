{
  programs.hyprlock = {
    enable = true;
    extraConfig = ''
      $text_color = rgba(E2E2E2FF)
      $entry_background_color = rgba(13131311)
      $entry_border_color = rgba(91919155)
      $entry_color = rgba(C6C6C6FF)
      $font_family = Gabarito
      $font_family_clock = Gabarito
      $font_material_symbols = Material Symbols Rounded

      general {
        hide_cursor = true
        immediate_render = true
        ignore_empty_input = true
        text_trim = true
      }
      background {
          color = rgba(13131377)
          path = screenshot
          blur_size = 7
          blur_passes = 4
      }
      input-field {
          monitor =
          size = 250, 50
          outline_thickness = 2
          dots_size = 0.1
          dots_spacing = 0.3
          outer_color = $entry_border_color
          inner_color = $entry_background_color
          font_color = $entry_color
          # fade_on_empty = true

          position = 0, 20
          halign = center
          valign = center
      }
      label { # Clock
          monitor =
          text = $TIME
          shadow_passes = 1
          shadow_boost = 0.5
          color = $text_color
          font_size = 65
          font_family = $font_family_clock

          position = 0, 300
          halign = center
          valign = center
      }
      label { # Greeting
          monitor =
          text = Welcome Back!
          shadow_passes = 1
          shadow_boost = 0.5
          color = $text_color
          font_size = 20
          font_family = $font_family

          position = 0, 240
          halign = center
          valign = center
      }
      label { # lock icon
          monitor =
          text = lock
          shadow_passes = 1
          shadow_boost = 0.5
          color = $text_color
          font_size = 21
          font_family = $font_material_symbols

          position = 0, 65
          halign = center
          valign = bottom
      }
      label { # "locked" text
          monitor =
          text = locked
          shadow_passes = 1
          shadow_boost = 0.5
          color = $text_color
          font_size = 14
          font_family = $font_family

          position = 0, 45
          halign = center
          valign = bottom
      }'';
  };
}
