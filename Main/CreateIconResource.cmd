@echo After the resource file is created, you'll need to replace the icon
@echo from MainIcon.res with MainIcon_compressed.ico using a Resource editor
@pause
@brcc32 -foMainIcon.res MainIcon.rc
@if errorlevel 1 (
@pause
) else (
@echo All ok !
@echo Just remember to rebuild all with Shift-F9
@pause
)