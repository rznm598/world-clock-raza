# PROJECT MEMORY BANK (v3.0)
# Purpose: The "Save Game" — restores full architectural context at every session start.
# Location: Project Root Folder. Read first, update after every major commit or decision.

> **Last Updated:** 2026-11-25
> **Project:** World Clock

---

## 0. AGENTIC SYNC PROTOCOL (READ/WRITE RULES)
- **READ:** At the start of every session, or the moment "Context Drift" is detected.
- **WRITE:** Update sections 2, 3, 4, and 5 after every successful commit or major feature.
- **VERIFY:** If anything in this file conflicts with actual code, the code is the Source of Truth. Update this file immediately.

---

## 1. PROJECT OVERVIEW

| Field | Value |
|---|---|
| **App Name** | World Clock |
| **Owner** | rznm598 (Raza) |
| **Purpose** | Replace the Windows taskbar clock with Islamabad time; click it for a dropdown with five cities, a month calendar and a Google Calendar link |
| **Stack** | Windows PowerShell 5.1 + WinForms (.NET Framework), Win32 P/Invoke via `Add-Type`, VBScript launcher |
| **Entry Point** | `WorldClock.vbs` → runs `WorldClock.ps1` hidden with `-ExecutionPolicy Bypass` |
| **Port / URL** | n/a (desktop) |
| **Platform** | Windows 10 (built and tested on 19045, 1920x1080, auto-hide taskbar at the bottom) |
| **Repo** | github.com/rznm598/world-clock-raza (PUBLIC) |

---

## 2. ARCHITECTURE MAP

```
WorldClock.vbs            ← hidden launcher (no console window, bypasses .ps1 execution policy)
WorldClock.ps1            ← the whole app: taskbar label + dropdown + calendar
WorldClock-floating.ps1   ← retired v1: always-on-top floating strip (kept for reference)
README.md                 ← public readme
linkedin-post/            ← LinkedIn post images; git-excluded via .git/info/exclude (NOT in the repo)
```

### Core Flow
```
WorldClock.vbs → WorldClock.ps1
  → single-instance mutex (Local\RazaWorldClock)
  → $bar form re-parented into Shell_TrayWnd (WS_CHILD) and placed exactly over TrayClockWClass
  → 1s timer: update label (Islamabad time + date); every 2s Attach() re-parents/re-positions (survives Explorer restarts)
  → click label → Toggle(): $pop (250px topmost borderless form) shown above the taskbar
      → "Calendar" header: click = show/hide MonthCalendar + "Open Google Calendar" link; drag sideways = move dropdown
      → five city rows, blue = 07:00–19:00 local daytime
  → $pop.Deactivate → hide (click anywhere else closes it)
```

### Architectural Source of Truth
- **Naming & Patterns:** PowerShell script-scope state (`$script:`), event handlers as scriptblocks, Win32 calls through the `W` class in the `Add-Type` block.
- **Strict Vetoes:**
  - No installers, compiled binaries or third-party dependencies. It must run on stock Windows.
  - Do not change Windows settings (for example turning the system clock off). The app covers the stock clock instead.
  - No autostart. Raza launches it from the desktop shortcut on purpose.
  - Never size or centre controls from `MonthCalendar.Width` before its handle exists (see BUG-003).

---

## 3. PHASE / FEATURE STATUS

| Phase | Description | Status |
|---|---|---|
| v1 | Floating always-on-top strip with 5 clocks, drag + minimise to tab | ✅ Complete (retired) |
| v2 | Taskbar clock replacing the stock clock + city dropdown | ✅ Complete |
| v3 | Calendar in dropdown + Google Calendar link + movable dropdown | ✅ Complete |

---

## 4. KEY VARIABLES & DATA CONTRACTS

```
$zones              array of @{Name; Id}   # Id = Windows time zone ID, e.g. 'Pakistan Standard Time'
$homeZone           $zones[3]              # Islamabad, shown on the taskbar label
$popW = 250         int                    # dropdown width in px; MUST be applied via $pop.Size in LayoutPop
%APPDATA%\WorldClockPopX.txt   int         # dropdown horizontal offset from default (saved on drag)
%TEMP%\worldclock-error.log    text        # unhandled UI-thread exceptions
$env:WC_TEST = '1'                         # test mode: dropdown auto-opens with calendar and does not close on deactivate
```

---

## 5. SENIOR DECISIONS & "WHY" (CTO Ledger)
Full entries in DECISIONS_LOG.md.

| Date | Decision | Reason | Revisit Trigger |
|---|---|---|---|
| 2026-11-06 | PowerShell + WinForms, no install | Runs on stock Windows, one file to edit | Need for multi-monitor or Windows 11 support |
| 2026-11-06 | Child window of the taskbar, over the system clock | Floating strip covered other windows | A Windows update changes the taskbar classes |
| 2026-11-06 | Cover the stock clock, don't disable it | No system setting changes; exit restores it | Raza asks to hide it in Windows settings |
| 2026-11-06 | Built-in MonthCalendar + link to Google Calendar | No Google account access needed | Raza wants events shown inline |
| 2026-11-06 | No autostart | Raza's choice | Raza asks for it |

---

## 6. PENDING DEBT & REFACTORS

| Item | Priority | Notes |
|---|---|---|
| [ ] Taskbar on top/left/right edges | Low | `Attach()` only positions for a horizontal (bottom) taskbar |
| [ ] Multi-monitor | Low | Uses the primary screen and primary `Shell_TrayWnd` only |
| [ ] Windows 11 | Low | Untested; the Win11 taskbar does not use `TrayClockWClass` the same way |
| [ ] Taskbar colour sampled once | Low | Colour is taken at attach time; a theme change needs a relaunch |

---

## 7. RESOLVED ISSUES (Session History)
Full detail lives in BUG_LOG.md.

| ID | Session | Component | Fix Applied |
|---|---|---|---|
| BUG-001 | 2026-11-06 | taskbar placement | Sit over `TrayClockWClass` (found with recursive `FindDeep`) instead of left of the tray, where the weather widget covered it |
| BUG-002 | 2026-11-06 | launching | Launch via the desktop shortcut / `explorer.exe`, not from a Claude session shell |
| BUG-003 | 2026-11-06 | calendar centring | Force `$cal.Handle` before reading `$cal.Width` |
| BUG-004 | 2026-11-06 | MonthCalendar "Today" row | `ShowToday = $false` |
| BUG-005 | 2026-11-06 | dropdown width | Set `$pop.Size` to `$popW` in `LayoutPop` (form had fallen back to 300px) |
| BUG-006 | 2026-11-25 | taskbar label | Date line shortened to "Wed 25" (no month) so it fits at full size; FitFont kept as a guard |

---

## 8. EXTERNAL DEPENDENCIES

| Package / Service | Version Pin | Notes |
|---|---|---|
| Windows PowerShell | 5.1 | Ships with Windows 10 |
| .NET Framework WinForms | 4.x | `System.Windows.Forms`, `System.Drawing` |
| Explorer taskbar classes | Win10 | `Shell_TrayWnd`, `TrayNotifyWnd`, `TrayClockWClass`: placement breaks if these change |

---

## 9. RECENT GREP VERIFICATIONS
- **Last Successful Build / Run:** 2026-11-25, running from `03 - Projects\World_Clock` after the move (commit 4ad50a3 + template files)
- **Last Verified File:** `WorldClock.ps1` LayoutPop sets `$pop.Size=New-Object Drawing.Size($popW,($y+1))`; dropdown measured 250px wide, calendar centred

---

## NEXT SESSION PRIORITIES
1. Nothing pending. The project is in use.
2. If it misbehaves, read `%TEMP%\worldclock-error.log` first.
3. Pick from section 6 only if Raza asks.

---

## BOOTSTRAP PROMPT
*Paste this into a fresh session to initialize Claude on this project:*
> "Read memory.md, BUG_LOG.md, and DECISIONS_LOG.md. Confirm the current phase, active bugs, and next priority before accepting any new instructions. Then analyze the codebase and flag the three highest-risk items you can see."
