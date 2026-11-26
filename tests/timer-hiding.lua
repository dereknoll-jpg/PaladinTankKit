local p,n=TEST_NS,0
local function check(value,message) assert(value,message);n=n+1 end
p.preview=true;p.previewStart=NOW;p:Render()
p:ToggleSettings();p:SelectSettingsPage("timers")
-- Discover attached controls rather than assuming their field names.
local frames={}
for _,frame in ipairs(FRAMES) do if frame.timerOption then frames[#frames+1]=frame end end
check(#frames==10,"Every timer, protection effect and cleanse reminder has a hide control")
local savedUsed=p.used
local savedMarking=p.marking
for _,frame in ipairs(frames) do
    local option=frame.timerOption
    p:RestoreTimers()
    frame.scripts.OnClick(frame,"LeftButton")
    check(p.db[option],"Left click does not hide "..option)
    COMBAT=true
    frame.scripts.OnClick(frame,"MiddleButton")
    check(p.db[option]==false and not frame:IsShown(),"Middle click hides in combat: "..option)
    check(p.used==savedUsed and p.marking==savedMarking,"Hide preserves tracking and marking")
    for _,other in ipairs(frames) do
        if other~=frame then check(p.db[other.timerOption],"Other timer remains enabled") end
    end
    p:RestoreTimers()
    check(p.db[option],"Restore re-enables "..option)
end
p.db.trackHoly=false;p.restoreTimersButton.scripts.OnClick()
check(p.db.trackHoly,"Restore all button restores hidden timers")
p.db.showForbearance=false;p:Command("restore")
check(p.db.showForbearance,"Slash command restores Forbearance")
p.preview=false;COMBAT=false;p:ClearUsedTimers();p:RestoreTimers();p:Render()
check(not p.holyTile:IsShown(),"Restoring unused timers does not invent active abilities")
print("PASS: "..n.." middle-click hiding and restoration checks.")
