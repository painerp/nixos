{
  home = {
    configFile."Thunar/uca.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <actions>
      <action>
      	<icon>utilities-terminal</icon>
      	<name>Open Kitty Here</name>
      	<submenu></submenu>
      	<unique-id>1723516010421836-1</unique-id>
      	<command>kitty --working-directory %f</command>
      	<description>Opens Kitty in the Directory</description>
      	<range></range>
      	<patterns>*</patterns>
      	<startup-notify/>
      	<directories/>
      </action>
      <action>
      	<icon>cloud-upload</icon>
      	<name>Upload to Cloud</name>
      	<submenu></submenu>
      	<unique-id>1743889909615975-1</unique-id>
      	<command>upload-file %f</command>
      	<description>Uploads a File to the Cloud</description>
      	<range>1-1</range>
      	<patterns>*</patterns>
      	<audio-files/>
      	<image-files/>
      	<other-files/>
      	<text-files/>
      	<video-files/>
      </action>
      </actions>
    '';

    xfconf.settings = {
      thunar = {
        "last-view" = "ThunarIconView";
        "last-icon-view-zoom-level" = "THUNAR_ZOOM_LEVEL_100_PERCENT";
        "last-window-maximized" = true;
        "last-menubar-visible" = true;
        "last-show-hidden" = true;
        "last-separator-position" = 170;
        "misc-single-click" = false;
        "last-image-preview-visible" = false;
        "misc-middle-click-in-tab" = true;
        "misc-thumbnail-mode" = "THUNAR_THUMBNAIL_MODE_ALWAYS";
        "last-side-pane" = "ThunarShortcutsPane";
        "last-toolbar-item-order" = "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17";
        "last-toolbar-visible-buttons" = "0,1,1,1,0,0,0,0,0,0,0,0,0,0,1,0,1,0";
        "last-details-view-zoom-level" = "THUNAR_ZOOM_LEVEL_38_PERCENT";
        "last-details-view-column-widths" = "50,50,110,50,50,50,50,50,134,50,50,72,50,734";
        "last-location-bar" = "ThunarLocationButtons";
        "hidden-bookmarks" = [
          "recent:///"
          "computer:///"
          "network:///"
        ];
      };
    };

    xdg.mimeApps = {
      defaultApplications = {
        "inode/directory" = [ "thunar.desktop" ];
      };
      associations.added = {
        "inode/directory" = [ "thunar.desktop" ];
      };
    };

    systemd.user.services.thunar = {
      Unit = {
        Description = "Thunar file manager";
        Documentation = "man:Thunar(1)";
      };
      Service = {
        Type = "dbus";
        ExecStart = "${thunar}/bin/Thunar --daemon";
        WantedBy = [ "graphical-session.target" ];
        BusName = "org.xfce.FileManager";
        KillMode = "process";
        PassEnvironment = [ "PATH" ];
      };
    };
  };
}
