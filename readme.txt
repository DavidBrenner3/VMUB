Use Delphi 10 Seattle to compile.

To change from portable version to install switch

isInstalledVersion := False;

to

isInstalledVersion := True;

in Main\Virtual_Machine_USB_Boot.dpr

Third party components (slightly modified from the originals):

TVirtualTree
TPNGImage

For installer you need Inno 5.3.3 Unicode (or newer) and some unofficial translations.