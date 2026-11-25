# 🐛 BUG LOG — World Clock
# Claude reads this to avoid repeating past mistakes and understand recurring failure patterns.
# Update this every time a bug is resolved. Never delete entries — patterns matter.

---

## HOW TO USE THIS
- **Claude:** Before touching any logic in this project, read this file. Cross-reference
  current work against past bugs to avoid reintroducing known issues.
- **Human:** After resolving a bug, paste the summary here using the format below.
- **Rule:** If the same class of bug appears twice, add a "PATTERN DETECTED" flag.

---

## BUG ENTRY FORMAT
```
### BUG-[number] | [Date] | Status: [Open / Resolved / Won't Fix]
**Component:** [Which file, function, or feature]
**Symptom:** [What the user/dev saw]
**Root Cause:** [What actually caused it]
**Fix Applied:** [What was done to resolve it]
**Prevention:** [What rule or check prevents this happening again]
**Pattern Flag:** [Yes / No — if Yes, see PATTERNS section below]
```

---

## BUG ENTRIES

### BUG-001 | 2026-11-06 | Status: Resolved
**Component:** `WorldClock.ps1` → `Attach()` / `TrayRects()`
**Symptom:** The clock attached to the taskbar but could not be seen.
**Root Cause:** It was placed just left of `TrayNotifyWnd`, where the Windows "News and interests" weather widget is drawn on top of it. Separately, `FindWindowEx(notify, 'TrayClockWClass')` returned nothing because the clock is not a direct child.
**Fix Applied:** Find `TrayClockWClass` with a recursive `EnumChildWindows` search (`W.FindDeep`) and place the window exactly over the stock clock.
**Prevention:** Check the taskbar window tree with an `EnumChildWindows` dump before assuming a parent/child layout.
**Pattern Flag:** No

### BUG-002 | 2026-11-06 | Status: Resolved
**Component:** Launching
**Symptom:** The clock vanished from the taskbar after a Claude Code session ended or restarted.
**Root Cause:** A process started from the session's shell is a child of the session and is killed with it.
**Fix Applied:** Launch with `explorer.exe "<Desktop>\World Clock.lnk"`, so Explorer becomes the parent.
**Prevention:** Never leave the "real" instance running from a session shell. Test instances are fine, but relaunch via the shortcut at the end.
**Pattern Flag:** No

### BUG-003 | 2026-11-06 | Status: Resolved
**Component:** `LayoutPop` → MonthCalendar position
**Symptom:** The calendar sat too far right and overlapped the dropdown's right edge.
**Root Cause:** `$cal.Width` was read before the control's handle existed, so it returned a smaller default width and the centring maths was wrong.
**Fix Applied:** Make it visible and touch `$cal.Handle` before reading `$cal.Width` / `$cal.Height`. Height is now taken from the control as well.
**Prevention:** Never size from a native control before its handle is created.
**Pattern Flag:** Yes (sizing, see PATTERNS)

### BUG-004 | 2026-11-06 | Status: Resolved
**Component:** MonthCalendar "Today: 11/6/2026" row
**Symptom:** Hovering highlighted only part of the year ("20" blue, "26" black), plus an odd empty box.
**Root Cause:** The native MonthCalendar today-link repaints only part of its area on hover.
**Fix Applied:** `ShowToday = $false`. Today stays ringed in the grid (`ShowTodayCircle`).
**Prevention:** n/a
**Pattern Flag:** No

### BUG-005 | 2026-11-06 | Status: Resolved
**Component:** `$pop` dropdown form
**Symptom:** A light-gray column on the right of the dropdown, partly off-screen, and the calendar not centred in what looked like the dropdown.
**Root Cause:** Adding the calendar replaced the line `$pop.Size = ... $popW ...`. The form fell back to WinForms' default 300px width while the controls were laid out for 250px.
**Fix Applied:** `LayoutPop` now sets `$pop.Size = New-Object Drawing.Size($popW, ($y+1))` every time.
**Prevention:** Set the form size in the single layout function, never only at creation. Measure the real window rect (`GetWindowRect`) when checking layout.
**Pattern Flag:** Yes (sizing, see PATTERNS)

### BUG-006 | 2026-11-25 | Status: Resolved
**Component:** `Update()` → taskbar label text
**Symptom:** The top of the time was cut off in the taskbar on some days.
**Root Cause:** On two-digit days the date ("Wed 25 Nov") is wider than the stock clock slot (~64px) at 9pt, so it wrapped onto a third line and the centred text overflowed the 40px taskbar. Single-digit days ("Fri 6 Nov") fit, so it only showed up later in the month.
**Fix Applied:** First tried shrinking the font to fit (`FitFont`, 9pt down to 6.5pt); Raza found it too small to read. Final fix: the second line is now `ddd d` ("Wed 25", no month), which fits at the full 9pt. `FitFont` stays as a safety net and normally picks 9pt. See DEC-007.
**Prevention:** Test text layout with the widest real values (two-digit day, "Wed", 12:xx PM), not just today's date.
**Pattern Flag:** Yes (sizing, see PATTERNS)

---

## RECURRING PATTERNS

### PATTERN DETECTED: sizes assumed instead of measured (BUG-003, BUG-005, BUG-006)
Both layout bugs came from trusting a size the code assumed (a control width before its handle existed, a form width set once and later dropped) instead of the size Windows actually used. When changing layout, measure the real window rect and check it against `$popW`, and keep all sizing in `LayoutPop`.
