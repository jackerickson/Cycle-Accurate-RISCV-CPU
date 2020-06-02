#!/usr/bin/tclsh
#
# simple example of using tcl with gtkwave:
# Query the dumpfile for signals with "clk" or [1:48] in the signal name
set nfacs [gtkwave::getNumFacs]
set dumpname [ gtkwave::getDumpFileName ]
set dmt [ gtkwave::getDumpType ]
puts "number of signals in dumpfile '$dumpname' of type $dmt: $nfacs"
set clk48 [list]
#puts $clk48
# Show input and output signals
lappend clk48 "top.c.x\[3:0\]"
lappend clk48 "top.c.z\[3:0\]"
set ll [ llength $clk48 ]
puts "number of signals found matching either 'clk' or '\[1:48\]': $ll"
# Add "INPUT" comment first
gtkwave::/Edit/Insert_Comment "INPUT"
# Add top.c.x and top.c.x signals
set num_added [ gtkwave::addSignalsFromList $clk48 ]
puts "num signals added: $num_added"
# Change color of singnal top.c.x to Orange
gtkwave::/Edit/Highlight_Regexp "x"
gtkwave::/Edit/Color_Format/Orange
gtkwave::/Edit/UnHighlight_All
# Add "OUTPUT" comment above top.c.z
gtkwave::/Edit/Highlight_Regexp "x"
gtkwave::/Edit/Insert_Comment "OUTPUT"
gtkwave::/Edit/UnHighlight_All
# Change color of singnal top.c.x to Yellow
gtkwave::/Edit/Highlight_Regexp "z"
gtkwave::/Edit/Color_Format/Yellow
gtkwave::/Edit/UnHighlight_All
gtkwave::/View/Show_Wave_Highlight
gtkwave::/Edit/Set_Trace_Max_Hier 0
# zoom full
gtkwave::/Time/Zoom/Zoom_Full