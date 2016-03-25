With this application it's easy to add a real drive (USB or other) into a virtual machine (VirtualBox or QEMU) and boot from it.
It will temporary separate the drive from the host OS (dismount it) and, after the virtual machine is closed, it will mount it back. This way it will prevent data loss and the changes made to the drive in the virtual machine will be visible in the host OS too.

Requirements:

Host OS: Windows XP/Vista/7/8/8.1/10
VirtualBox (installed or portable) and/or QEMU



Use Delphi XE or newer to compile.

To change from portable version to install switch

isInstalledVersion := False;

to

isInstalledVersion := True;

in Main\Virtual_Machine_USB_Boot.dpr

Third party components (slightly modified from the originals):

TVirtualTree
TPNGImage

For installer you need Inno 5.3.3 Unicode (or newer) and some unofficial translations.
