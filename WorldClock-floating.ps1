Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$zones = @(
  @{Name='Los Angeles'; Id='Pacific Standard Time'},
  @{Name='New York';    Id='Eastern Standard Time'},
  @{Name='London';      Id='GMT Standard Time'},
  @{Name='Islamabad';   Id='Pakistan Standard Time'},
  @{Name='Sydney';      Id='AUS Eastern Standard Time'}
)
$cfgFile = Join-Path $env:APPDATA 'WorldClockCfg.txt'   # right,top,collapsed,topmost
$cw=118; $btnW=22; $tabW=34; $H=50
$fullW = $cw*$zones.Count + $btnW + 4
$wa=[Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$script:right = $wa.Right-8; $script:top = $wa.Bottom-$H-4; $script:collapsed=$false; $script:topmost=$true
if(Test-Path $cfgFile){ try{ $p=(Get-Content $cfgFile).Split(','); $script:right=[int]$p[0]; $script:top=[int]$p[1]; $script:collapsed=($p[2] -eq '1'); $script:topmost=($p[3] -ne '0') }catch{} }
function Save { "$($script:right),$($script:top),$(if($script:collapsed){1}else{0}),$(if($script:topmost){1}else{0})" | Set-Content $cfgFile }

$f = New-Object Windows.Forms.Form
$f.FormBorderStyle='None'; $f.ShowInTaskbar=$false; $f.StartPosition='Manual'
$f.BackColor=[Drawing.Color]::FromArgb(24,28,34); $f.TopMost=$script:topmost
$font2=New-Object Drawing.Font('Segoe UI Semibold',13)
$labs=@()
for($i=0;$i -lt $zones.Count;$i++){
  $l=New-Object Windows.Forms.Label
  $l.Location=New-Object Drawing.Point((2+$i*$cw),2); $l.Size=New-Object Drawing.Size($cw,($H-4))
  $l.TextAlign='MiddleCenter'; $l.ForeColor=[Drawing.Color]::White; $l.Font=$font2
  $labs+=$l; $f.Controls.Add($l)
}
# collapse button (right end of strip)
$btn=New-Object Windows.Forms.Label
$btn.Location=New-Object Drawing.Point((2+$cw*$zones.Count),2); $btn.Size=New-Object Drawing.Size($btnW,($H-4))
$btn.Text=[string][char]0x25B8; $btn.Font=New-Object Drawing.Font('Segoe UI',14); $btn.TextAlign='MiddleCenter'
$btn.ForeColor=[Drawing.Color]::Silver; $btn.BackColor=[Drawing.Color]::FromArgb(50,56,66); $btn.Cursor='Hand'
$f.Controls.Add($btn)
# collapsed tab
$tab=New-Object Windows.Forms.Label
$tab.Location=New-Object Drawing.Point(0,0); $tab.Size=New-Object Drawing.Size($tabW,$H)
$tab.Text=[string][char]0x25F7; $tab.Font=New-Object Drawing.Font('Segoe UI Symbol',16); $tab.TextAlign='MiddleCenter'
$tab.ForeColor=[Drawing.Color]::White; $tab.BackColor=[Drawing.Color]::FromArgb(40,70,110); $tab.Cursor='Hand'
$f.Controls.Add($tab)

function Layout {
  if($script:collapsed){ $f.Size=New-Object Drawing.Size($tabW,$H); $tab.Visible=$true; $btn.Visible=$false; foreach($l in $labs){$l.Visible=$false} }
  else { $f.Size=New-Object Drawing.Size($fullW,$H); $tab.Visible=$false; $btn.Visible=$true; foreach($l in $labs){$l.Visible=$true} }
  $f.Location=New-Object Drawing.Point(($script:right-$f.Width),$script:top)
}
function SetCollapsed($v){ $script:collapsed=$v; Layout; Save }

# menu
$menu=New-Object Windows.Forms.ContextMenuStrip
$miMin=$menu.Items.Add('Minimize to side tab'); $miMin.Add_Click({ SetCollapsed $true })
$miTop=New-Object Windows.Forms.ToolStripMenuItem('Stay on top of other windows'); $miTop.CheckOnClick=$true; $miTop.Checked=$script:topmost
$miTop.Add_Click({ $script:topmost=$miTop.Checked; $f.TopMost=$script:topmost; Save }); $null=$menu.Items.Add($miTop)
$miExit=$menu.Items.Add('Exit'); $miExit.Add_Click({ $f.Close() })
$ctrls=@($f)+$labs+@($btn,$tab)
foreach($c in $ctrls){ $c.ContextMenuStrip=$menu }

# drag (vertical+horizontal) ; click without moving = action
$script:drag=$null
$down={ if($_.Button -eq 'Left'){ $script:drag=[Windows.Forms.Cursor]::Position; $script:orig=$f.Location; $script:moved=$false } }
$move={ if($script:drag){ $n=[Windows.Forms.Cursor]::Position
  if([Math]::Abs($n.X-$script:drag.X)+[Math]::Abs($n.Y-$script:drag.Y) -gt 4){$script:moved=$true}
  if($script:moved){ $f.Location=New-Object Drawing.Point(($script:orig.X+$n.X-$script:drag.X),($script:orig.Y+$n.Y-$script:drag.Y)) } } }
$up={ if($script:drag){ $script:drag=$null
  if($script:moved){ $script:right=$f.Right; $script:top=$f.Top; Save } } }
foreach($c in $ctrls){ $c.Add_MouseDown($down); $c.Add_MouseMove($move); $c.Add_MouseUp($up) }
$btn.Add_MouseUp({ if(-not $script:moved -and $_.Button -eq 'Left'){ SetCollapsed $true } })
$tab.Add_MouseUp({ if(-not $script:moved -and $_.Button -eq 'Left'){ SetCollapsed $false } })

$tick={
  $utc=[DateTime]::UtcNow
  for($i=0;$i -lt $zones.Count;$i++){
    $tz=[TimeZoneInfo]::FindSystemTimeZoneById($zones[$i].Id)
    $t=[TimeZoneInfo]::ConvertTimeFromUtc($utc,$tz)
    $labs[$i].Text = $zones[$i].Name + "`r`n" + $t.ToString('h:mm tt') + '  ' + $t.ToString('ddd')
    $labs[$i].BackColor = if($t.Hour -ge 7 -and $t.Hour -lt 19){[Drawing.Color]::FromArgb(40,70,110)}else{[Drawing.Color]::FromArgb(24,28,34)}
  }
}
$tm=New-Object Windows.Forms.Timer; $tm.Interval=1000; $tm.Add_Tick($tick); $tm.Start(); & $tick
Layout
[Windows.Forms.Application]::Run($f)
