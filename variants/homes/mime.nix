{ ... }:

let
  file-browser = "thunar.desktop";
  browser = "brave-browser.desktop";
  pdf-viewer = "okularApplication_pdf.desktop";
  text-editor = "org.kde.kate.desktop";
  archive-manager = "org.kde.ark.desktop";
  image-viewer = "org.nomacs.ImageLounge.desktop";
  video-player = "vlc.desktop";
in
{
  xdg = {
    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ file-browser ];
        "application/json" = [ text-editor ];
        "application/pdf" = [ pdf-viewer ];
        "application/x-extension-htm" = [ browser ];
        "application/x-extension-html" = [ browser ];
        "application/x-extension-shtml" = [ browser ];
        "application/x-extension-xht" = [ browser ];
        "application/x-extension-xhtml" = [ browser ];
        "application/xhtml+xml" = [ browser ];
        "application/zip" = [ archive-manager ];
        "audio/flac" = [ video-player ];
        "audio/mpeg" = [ video-player ];
        "audio/x-aiff" = [ video-player ];
        "image/gif" = [ image-viewer ];
        "image/jpeg" = [ image-viewer ];
        "image/jpg" = [ image-viewer ];
        "image/png" = [ image-viewer ];
        "image/webp" = [ image-viewer ];
        "image/x-portable-pixmap" = [ image-viewer ];
        "text/csv" = [ text-editor ];
        "text/html" = [ browser ];
        "text/plain" = [ text-editor ];
        "text/xml" = [ text-editor ];
        "video/mp4" = [ video-player ];
        "video/x-matroska" = [ video-player ];
        "x-scheme-handler/chrome" = [ browser ];
        "x-scheme-handler/http" = [ browser ];
        "x-scheme-handler/https" = [ browser ];
      };
    };
  };
}
