Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public class W {
  [DllImport("user32")] public static extern IntPtr FindWindow(string c,string t);
  [DllImport("user32")] public static extern IntPtr FindWindowEx(IntPtr p,IntPtr a,string c,string t);
  [DllImport("user32")] public static extern IntPtr SetParent(IntPtr c,IntPtr p);
  [DllImport("user32")] public static extern IntPtr GetParent(IntPtr h);
  [DllImport("user32")] public static extern bool GetWindowRect(IntPtr h,out RECT r);
  [DllImport("user32")] public static extern int GetWindowLong(IntPtr h,int i);
  [DllImport("user32")] public static extern int SetWindowLong(IntPtr h,int i,int v);
  [DllImport("user32")] public static extern bool SetWindowPos(IntPtr h,IntPtr a,int x,int y,int cx,int cy,uint f);
  [DllImport("user32")] public static extern bool SetProcessDPIAware();
  public struct RECT{public int Left,Top,Right,Bottom;}
  public delegate bool CB(IntPtr h, IntPtr l);
  [DllImport("user32")] public static extern bool EnumChildWindows(IntPtr p, CB cb, IntPtr l);
  [DllImport("user32")] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder s, int n);
  public static IntPtr FindDeep(IntPtr root, string cls){
    IntPtr found=IntPtr.Zero;
    EnumChildWindows(root,(h,l)=>{ var sb=new System.Text.StringBuilder(128); GetClassName(h,sb,128); if(sb.ToString()==cls){found=h; return false;} return true;},IntPtr.Zero);
    return found; }
}
"@
[void][W]::SetProcessDPIAware()
[Windows.Forms.Application]::EnableVisualStyles()

# one instance only
$script:mutex = New-Object Threading.Mutex($false,'Local\RazaWorldClock')
if(-not $script:mutex.WaitOne(0)){ exit }

$zones = @(
  @{Name='Los Angeles'; Id='Pacific Standard Time'},
  @{Name='New York';    Id='Eastern Standard Time'},
  @{Name='London';      Id='GMT Standard Time'},
  @{Name='Islamabad';   Id='Pakistan Standard Time'},
  @{Name='Sydney';      Id='AUS Eastern Standard Time'}
)
$homeZone = $zones[3]
$dayCol=[Drawing.Color]::FromArgb(40,70,110); $nightCol=[Drawing.Color]::FromArgb(24,28,34)
function ZoneTime($z){ [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow,[TimeZoneInfo]::FindSystemTimeZoneById($z.Id)) }

# ---------- taskbar button (child of the taskbar) ----------
$barW=96
$bar=New-Object Windows.Forms.Form
$bar.FormBorderStyle='None'; $bar.ShowInTaskbar=$false; $bar.StartPosition='Manual'
$bar.Size=New-Object Drawing.Size($barW,40); $bar.BackColor=[Drawing.Color]::FromArgb(32,32,32)
$lbl=New-Object Windows.Forms.Label
$lbl.Dock='Fill'; $lbl.TextAlign='MiddleCenter'; $lbl.Font=New-Object Drawing.Font('Segoe UI',9); $lbl.ForeColor=[Drawing.Color]::White; $lbl.Cursor='Hand'
$bar.Controls.Add($lbl)

# ---------- dropdown ----------
$rowH=48; $popW=250
$pop=New-Object Windows.Forms.Form
$pop.FormBorderStyle='None'; $pop.ShowInTaskbar=$false; $pop.StartPosition='Manual'; $pop.TopMost=$true
$pop.BackColor=[Drawing.Color]::FromArgb(60,64,72)
$hdrH=38; $calH=164; $gcH=34
$script:calOpen=$false
$hdr=New-Object Windows.Forms.Label; $hdr.Size=New-Object Drawing.Size(($popW-2),$hdrH)
$hdr.Font=New-Object Drawing.Font('Segoe UI Semibold',10); $hdr.ForeColor=[Drawing.Color]::White; $hdr.BackColor=[Drawing.Color]::FromArgb(50,56,66)
$hdr.TextAlign='MiddleLeft'; $hdr.Padding=New-Object Windows.Forms.Padding(14,0,0,0); $hdr.Cursor='Hand'
$cal=New-Object Windows.Forms.MonthCalendar; $cal.MaxSelectionCount=1; $cal.ShowToday=$false; $cal.ShowTodayCircle=$true
$cal.Location=New-Object Drawing.Point((1+[int](($popW-2-$cal.Width)/2)),0); $cal.Visible=$false
$gc=New-Object Windows.Forms.Label; $gc.Size=New-Object Drawing.Size(($popW-2),$gcH); $gc.Text='Open Google Calendar  '+[char]0x2197
$gc.Font=New-Object Drawing.Font('Segoe UI',9.5); $gc.ForeColor=[Drawing.Color]::FromArgb(138,180,248); $gc.BackColor=[Drawing.Color]::FromArgb(50,56,66)
$gc.TextAlign='MiddleCenter'; $gc.Cursor='Hand'; $gc.Visible=$false
$pop.Controls.Add($hdr); $pop.Controls.Add($cal); $pop.Controls.Add($gc)
$rows=@()
for($i=0;$i -lt $zones.Count;$i++){
  $nm=New-Object Windows.Forms.Label; $nm.Location=New-Object Drawing.Point(1,(1+$i*$rowH)); $nm.Size=New-Object Drawing.Size(($popW-2),$rowH)
  $nm.Font=New-Object Drawing.Font('Segoe UI',10); $nm.ForeColor=[Drawing.Color]::White; $nm.TextAlign='MiddleLeft'; $nm.Padding=New-Object Windows.Forms.Padding(14,0,0,0)
  $tm=New-Object Windows.Forms.Label; $tm.Size=New-Object Drawing.Size(120,$rowH); $tm.Location=New-Object Drawing.Point(($popW-121),(1+$i*$rowH))
  $tm.Font=New-Object Drawing.Font('Segoe UI Semibold',14); $tm.ForeColor=[Drawing.Color]::White; $tm.TextAlign='MiddleRight'; $tm.Padding=New-Object Windows.Forms.Padding(0,0,14,0)
  $pop.Controls.Add($tm); $pop.Controls.Add($nm); $tm.BringToFront()
  $rows+=@{Name=$nm;Time=$tm}
}
function LayoutPop {
  $bottom = if($pop.Visible){ $pop.Bottom } else { 0 }
  $y=1
  $hdr.Location=New-Object Drawing.Point(1,$y); $hdr.Text= $(if($script:calOpen){'Calendar  '+[char]0x25B4}else{'Calendar  '+[char]0x25BE}) ; $y+=$hdrH
  if($script:calOpen){ $cal.Visible=$true; [void]$cal.Handle; $cal.Location=New-Object Drawing.Point([int](($popW-$cal.Width)/2),($y+4)); $y+=($cal.Height+8)
    $gc.Location=New-Object Drawing.Point(1,$y); $gc.Visible=$true; $y+=$gcH } else { $cal.Visible=$false; $gc.Visible=$false }
  for($i=0;$i -lt $zones.Count;$i++){
    $rows[$i].Name.Top=$y; $rows[$i].Time.Top=$y; $y+=$rowH }
  $pop.Height=$y+1
  if($bottom -gt 0){ $pop.Top=$bottom-$pop.Height }
}
$posFile=Join-Path $env:APPDATA 'WorldClockPopX.txt'
$script:dx=0; if(Test-Path $posFile){ try{ $script:dx=[int](Get-Content $posFile) }catch{} }
$script:hd=$null
$hdr.Add_MouseDown({ if($_.Button -eq 'Left'){ $script:hd=[Windows.Forms.Cursor]::Position; $script:hx=$pop.Left; $script:hmoved=$false } })
$hdr.Add_MouseMove({ if($script:hd){ $n=[Windows.Forms.Cursor]::Position; $d=$n.X-$script:hd.X
  if([Math]::Abs($d) -gt 4){ $script:hmoved=$true }
  if($script:hmoved){ $pop.Left=[Math]::Max(0,[Math]::Min($script:hx+$d,[Windows.Forms.Screen]::PrimaryScreen.Bounds.Right-$popW)) } } })
$hdr.Add_MouseUp({ if($script:hd){ $script:hd=$null
  if($script:hmoved){ $r=TrayRects; $scr=[Windows.Forms.Screen]::PrimaryScreen.Bounds; $def=[Math]::Min($r.N.Right,$scr.Right)-$popW-24; $script:dx=$pop.Left-$def; "$($script:dx)" | Set-Content $posFile }
  else { $script:calOpen=-not $script:calOpen; if($script:calOpen){ $cal.SetDate((Get-Date)) }; LayoutPop } } })
$gc.Add_Click({ Start-Process 'https://calendar.google.com'; $pop.Hide() })
LayoutPop
$script:closedAt=[DateTime]::MinValue
$pop.Add_Deactivate({ if($pop.Visible -and -not $env:WC_TEST){ $pop.Hide(); $script:closedAt=Get-Date } })

function TrayRects {
  $tray=[W]::FindWindow('Shell_TrayWnd',$null)
  if($tray -eq [IntPtr]::Zero){ return $null }
  $notify=[W]::FindWindowEx($tray,[IntPtr]::Zero,'TrayNotifyWnd',$null)
  $t=New-Object W+RECT; $n=New-Object W+RECT; $c=New-Object W+RECT
  [void][W]::GetWindowRect($tray,[ref]$t)
  if($notify -ne [IntPtr]::Zero){ [void][W]::GetWindowRect($notify,[ref]$n) } else { $n=$t }
  $ck=[W]::FindDeep($tray,'TrayClockWClass')
  $hasClock=$false
  if($ck -ne [IntPtr]::Zero){ [void][W]::GetWindowRect($ck,[ref]$c); $hasClock=($c.Right-$c.Left -gt 30) }
  @{Tray=$tray;T=$t;N=$n;C=$c;HasClock=$hasClock}
}

function Attach {
  $r=TrayRects; if(-not $r){ return }
  $h=$bar.Handle
  if([W]::GetParent($h) -ne $r.Tray){
    # sample taskbar colour just left of our slot
    try{
      $sx=$r.N.Left+4; $sy=$r.T.Top+2
      $bmp=New-Object Drawing.Bitmap 1,1; $g=[Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($sx,$sy,0,0,$bmp.Size); $c=$bmp.GetPixel(0,0); $g.Dispose(); $bmp.Dispose()
      $bar.BackColor=[Drawing.Color]::FromArgb(255,$c.R,$c.G,$c.B)
      $lum=0.299*$c.R+0.587*$c.G+0.114*$c.B
      $lbl.ForeColor= if($lum -gt 150){[Drawing.Color]::Black}else{[Drawing.Color]::White}
    }catch{}
    $st=[W]::GetWindowLong($h,-16)
    $st=($st -band 0x7FFFFFFF) -bor 0x40000000   # drop WS_POPUP, add WS_CHILD
    [void][W]::SetWindowLong($h,-16,$st)
    [void][W]::SetParent($h,$r.Tray)
  }
  $th=$r.T.Bottom-$r.T.Top; $tw=$r.T.Right-$r.T.Left
  if($th -le $tw){   # horizontal taskbar
    if($r.HasClock){ $x=$r.C.Left-$r.T.Left; $w=$r.C.Right-$r.C.Left } else { $x=$r.N.Left-$r.T.Left-$barW; $w=$barW }
    [void][W]::SetWindowPos($h,[IntPtr]::Zero,$x,0,$w,$th,0x0040)  # HWND_TOP, SWP_SHOWWINDOW
  }
}

function Update {
  $h=ZoneTime $homeZone
  $lbl.Text=$h.ToString('h:mm tt')+"`r`n"+$h.ToString('ddd d MMM')
  if($pop.Visible){ FillRows }
}
function FillRows {
  for($i=0;$i -lt $zones.Count;$i++){
    $t=ZoneTime $zones[$i]
    $rows[$i].Name.Text=$zones[$i].Name+"`r`n"+$t.ToString('ddd d MMM')
    $rows[$i].Time.Text=$t.ToString('h:mm tt')
    $col= if($t.Hour -ge 7 -and $t.Hour -lt 19){$dayCol}else{$nightCol}
    $rows[$i].Name.BackColor=$col; $rows[$i].Time.BackColor=$col
  }
}
function Toggle {
  if($pop.Visible){ $pop.Hide(); return }
  if(((Get-Date)-$script:closedAt).TotalMilliseconds -lt 300){ return }
  FillRows
  $script:calOpen=$false; LayoutPop
  $r=TrayRects; $scr=[Windows.Forms.Screen]::PrimaryScreen.Bounds
  $x=[Math]::Min($r.N.Right,$scr.Right)-$popW-24+$script:dx
  $x=[Math]::Max($scr.Left,[Math]::Min($x,$scr.Right-$popW))
  $y=$r.T.Top-$pop.Height-4
  $pop.Location=New-Object Drawing.Point($x,$y)
  $pop.Show(); $pop.Activate()
}
$lbl.Add_MouseUp({ if($_.Button -eq 'Left'){ Toggle } })
$menu=New-Object Windows.Forms.ContextMenuStrip
$mx=$menu.Items.Add('Exit World Clock'); $mx.Add_Click({ $pop.Close(); $bar.Close() })
$lbl.ContextMenuStrip=$menu

$script:n=0
$timer=New-Object Windows.Forms.Timer; $timer.Interval=1000
$timer.Add_Tick({ Update; $script:n++; if($script:n % 2 -eq 0){ Attach } }); $timer.Start()

[Windows.Forms.Application]::SetUnhandledExceptionMode('CatchException')
[Windows.Forms.Application]::add_ThreadException({ param($sn,$e) try{ ('{0} {1}' -f (Get-Date),$e.Exception.ToString()) | Add-Content (Join-Path $env:TEMP 'worldclock-error.log') }catch{} })
$bar.Add_Shown({ Update; Attach
  if($env:WC_TEST){ $tt=New-Object Windows.Forms.Timer; $tt.Interval=2500; $tt.Add_Tick({ $tt.Stop(); Toggle; $script:calOpen=$true; $cal.SetDate((Get-Date)); LayoutPop }); $tt.Start() }
})
$bar.Add_FormClosed({ [Windows.Forms.Application]::Exit() })
[Windows.Forms.Application]::Run($bar)



