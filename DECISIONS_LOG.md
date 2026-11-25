# 📋 DECISIONS LOG — World Clock
# The CTO Ledger. Every significant architectural or technical decision lives here.
# Claude reads this before suggesting changes to prevent reversing past reasoning.

---

## HOW TO USE THIS
- **Claude:** Before proposing any architectural change, check this log. If a similar
  decision was already made, do not suggest reversing it unless you can explicitly
  argue why the original reasoning no longer applies.
- **Human:** After any Consultation Phase or major decision, record it here.
- **Rule:** "We'll remember this" is not a system. Write it down.

---

## DECISION ENTRY FORMAT
```
### DEC-[number] | [Date]
**Decision:** [What was decided]
**Context:** [What problem or situation triggered this decision]
**Options Considered:**
  - Option A: [description] — rejected because [reason]
  - Option B: [description] — rejected because [reason]
  - Chosen: [description]
**Reasoning:** [The "why" — the architectural justification]
**Impact:** [What this decision affects or constrains going forward]
**Revisit Trigger:** [Under what conditions should this be reconsidered?]
```

---

## DECISION ENTRIES

### DEC-001 | 2026-11-06
**Decision:** Build it as a PowerShell + WinForms script with a VBScript launcher.
**Context:** Raza wanted 5–6 time zones on the desktop. Windows' own "additional clocks" only allows 2.
**Options Considered:**
  - Option A: Rainmeter skin. Rejected because it's an extra install and fiddly to set up.
  - Option B: Compiled C#/Electron app. Rejected because of the build step and binaries in a public repo.
  - Chosen: PowerShell + WinForms. Everything ships with Windows 10.
**Reasoning:** No install, one readable file, easy to change cities.
**Impact:** Limited to Windows; UI built in code, not a designer.
**Revisit Trigger:** Need for Windows 11 / multi-monitor support that WinForms-in-PowerShell can't handle cleanly.

### DEC-002 | 2026-11-06
**Decision:** Put the clock inside the taskbar (child window of `Shell_TrayWnd`) instead of a floating window.
**Context:** v1 floated always-on-top and covered other windows. Raza uses an auto-hide taskbar.
**Options Considered:**
  - Option A: Floating strip with minimise-to-tab (v1). Rejected because the tab still sat over windows.
  - Option B: Tray (notification area) icon. Rejected because a 16px icon can't show a readable time.
  - Chosen: Re-parent a borderless form into the taskbar.
**Reasoning:** It shows and hides with the taskbar and never covers windows.
**Impact:** Depends on Explorer's taskbar window classes (`TrayClockWClass`), so `Attach()` re-checks every 2s.
**Revisit Trigger:** A Windows update changes the taskbar structure.

### DEC-003 | 2026-11-06
**Decision:** Cover the stock clock instead of turning it off in Windows settings.
**Context:** Raza suggested replacing the Windows clock.
**Options Considered:**
  - Option A: Turn the system clock off (Settings → system icons). Rejected because it's a system change and leaves no clock if the app isn't running.
  - Chosen: Sit exactly on top of `TrayClockWClass`.
**Reasoning:** Fully reversible. Exiting the app shows the stock clock again.
**Impact:** The stock calendar flyout can't be opened while the app runs, which is why DEC-004 exists.
**Revisit Trigger:** Raza asks to hide the stock clock permanently.

### DEC-004 | 2026-11-06
**Decision:** Calendar = built-in MonthCalendar plus an "Open Google Calendar" link.
**Context:** Covering the stock clock removed the Windows calendar flyout. Raza uses Google Calendar.
**Options Considered:**
  - Option A: Show Google Calendar events inside the dropdown. Rejected because it needs Google account access/OAuth, which is too heavy for this.
  - Chosen: Month grid plus a link that opens calendar.google.com.
**Reasoning:** Simple; Raza said not to over-complicate it.
**Impact:** No events are shown in the dropdown.
**Revisit Trigger:** Raza asks to see events inline.

### DEC-005 | 2026-11-06
**Decision:** No autostart; launch from the "World Clock" desktop shortcut.
**Context:** Offered twice; Raza declined.
**Chosen:** Desktop shortcut only.
**Revisit Trigger:** Raza asks for it.

### DEC-006 | 2026-11-06
**Decision:** The dropdown moves sideways only (drag the "Calendar" bar) and is always anchored just above the taskbar.
**Context:** Raza wanted it away from the right edge and adjustable.
**Options Considered:**
  - Option A: Free 2D dragging. Rejected because it conflicts with growing upward when the calendar opens.
  - Chosen: Horizontal offset saved in `%APPDATA%\WorldClockPopX.txt`; default 24px from the right edge.
**Revisit Trigger:** Taskbar moved to another edge.

### DEC-007 | 2026-11-25
**Decision:** The taskbar label shows the time and "Wed 25" (day + date, no month) at full 9pt.
**Context:** "Wed 25 Nov" wrapped in the 64px clock slot (BUG-006); shrinking the font made it unreadable.
**Options Considered:**
  - Option A: Widen over the notification bell for a two-column layout. Rejected by Raza; it would cover the bell.
  - Option B: Widen over the tray icons. Rejected because it hides wifi/volume icons.
  - Chosen: Stay in the stock clock slot and drop the month from the taskbar label (the dropdown still shows full dates).
**Reasoning:** Readable size, nothing covered.
**Impact:** Month isn't visible on the taskbar; it's one click away in the dropdown.
**Revisit Trigger:** Raza wants the month back on the taskbar.
