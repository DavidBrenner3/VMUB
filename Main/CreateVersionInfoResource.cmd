@brcc32 -foVersionInfo.res VersionInfo.rc
@if errorlevel 1 (
@pause
) else (
@echo All ok :(
@pause
)