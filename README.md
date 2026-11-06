# World Clock Raza

A small Windows taskbar clock that replaces the stock clock with Islamabad time and date. Click it to open a dropdown with Los Angeles, New York, London, Islamabad and Sydney, plus a month calendar and a link to Google Calendar.

No install and no dependencies: just PowerShell and the Windows window toolkit that ship with Windows 10/11.

## Run it

Double-click `WorldClock.vbs`. It launches `WorldClock.ps1` hidden and bypasses the execution policy for that one launch. To start it again after a restart, double-click it again (or put a shortcut to it on your desktop).

Right-click the clock and choose **Exit World Clock** to close it.

## How it works

- The clock is a borderless WinForms window re-parented into the taskbar (`Shell_TrayWnd`) and placed exactly over the system clock (`TrayClockWClass`). It re-attaches itself if Explorer restarts.
- Time zones use the Windows time zone database, so daylight saving is automatic.
- Click the clock for the dropdown. Click the "Calendar" bar to show or hide the month view; drag that bar sideways to move the dropdown (position saved in `%APPDATA%\WorldClockPopX.txt`).
- Errors are logged to `%TEMP%\worldclock-error.log`.

## Change the cities

Edit the `$zones` list at the top of `WorldClock.ps1` (name + Windows time zone ID). The home clock shown in the taskbar is `$homeZone` (currently `$zones[3]`, Islamabad).

## Files

- `WorldClock.ps1` – the taskbar clock
- `WorldClock.vbs` – hidden launcher
- `WorldClock-floating.ps1` – older always-on-top floating strip version
