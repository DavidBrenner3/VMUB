@brcc32 -foVerWin.res VerWin.rc
@if errorlevel 1 (
@pause
) else (
@echo All ok !
@echo Just remember to rebuild all with Shift-F9
@pause
)