// Receiver enclosure - IoT Smart Safety Device
// NodeMCU ESP8266 + HC-12 + 1.8" SPI TFT
// Two parts, screw-free snap-fit lid. All dimensions in mm.
// mode: "print" (both parts flat), "assembled", "box", "lid"

mode = "print";

$fn = 48;

// ---------- component sizes ----------
nodemcu = [60, 35];
tft     = [60, 35];
hc12    = [28, 13];
tft_window = [40, 32];   // screen opening in the lid

// ---------- enclosure parameters ----------
wall  = 2.4;
floor_t = 2.4;
lid_t = 2.4;
Li = 106;                // inner length
Wi = 48;                 // inner width
Hi = 30;                 // inner height (wiring clearance)
R  = 4;                  // outer corner radius
clr = 0.3;               // lid-to-box clearance
lip_h = 5;
lip_w = 1.6;
gd = 0.8;                // snap groove depth
bump_d = 1.4;            // snap bump diameter
fit = 0.5;               // extra pocket clearance for boards

Lo = Li + 2*wall;
Wo = Wi + 2*wall;
Ho = floor_t + Hi;
// HC-12 mounted standing up (same as the transmitter): only its 13 mm width
// shows on top as a narrow slot; the antenna stands out of the slot.
hc_slot   = 6;            // opening width in the top surface = 0.6 cm
hc_len    = hc12[1] + 0.8; // slot length = module width + clearance
hc_gap    = 3.6;          // snug channel for the PCB, centred under the slot
hc_rib_t  = 2.2;          // thickness of each retaining rib
hc_stand  = false;        // true = add the retaining ribs for the HC-12 (removed, as on the transmitter)
hc_rib_h  = 14;           // ribs hang this far below the lid
hc_cx     = wall + 84;    // slot centre X (outer coords)
hc_cy     = Wo/2;         // slot centre Y

module rrect(l, w, h, r) {
    hull() for (x = [r, l-r], y = [r, w-r])
        translate([x, y, 0]) cylinder(r = r, h = h);
}

// ---------- BOX ----------
module box() {
    difference() {
        rrect(Lo, Wo, Ho, R);
        // cavity
        translate([wall, wall, floor_t]) rrect(Li, Wi, Hi + 1, R - wall + 1);
        // snap grooves (inner face of both long walls)
        for (gx = [Lo*0.25, Lo*0.75]) {
            translate([gx - 8, wall - gd, Ho - 4]) cube([16, gd + 0.01, 3]);
            translate([gx - 8, Wo - wall - 0.01, Ho - 4]) cube([16, gd + 0.01, 3]);
        }
        // micro-USB opening, short wall at NodeMCU end
        translate([-1, Wo/2 - 6.5, floor_t + 0.5])
            cube([wall + 2, 13, 8]);
    }
}

// ---------- LID (print orientation: outer face on the bed) ----------
module lid() {
    difference() {
        rrect(Lo, Wo, lid_t, R);
        // TFT window
        tx = wall + 2 + (tft[0] + fit - tft_window[0]) / 2;
        ty = Wo/2 - tft_window[1]/2;
        translate([tx, ty, -1]) cube([tft_window[0], tft_window[1], lid_t + 2]);
        // HC-12 standing slot
        translate([hc_cx - hc_slot/2, hc_cy - hc_len/2, -1])
            cube([hc_slot, hc_len, lid_t + 2]);
    }
    // inner lip with snap bumps
    translate([0, 0, lid_t]) difference() {
        translate([wall + clr, wall + clr, 0])
            rrect(Li - 2*clr, Wi - 2*clr, lip_h, R - wall);
        translate([wall + clr + lip_w, wall + clr + lip_w, -1])
            rrect(Li - 2*clr - 2*lip_w, Wi - 2*clr - 2*lip_w, lip_h + 2, 1);
    }
    for (gx = [Lo*0.25, Lo*0.75]) {
        translate([gx - 7, wall + clr, lid_t + lip_h - 2.5])
            rotate([0, 90, 0]) cylinder(d = bump_d, h = 14);
        translate([gx - 7, Wo - wall - clr, lid_t + lip_h - 2.5])
            rotate([0, 90, 0]) cylinder(d = bump_d, h = 14);
    }
    if (hc_stand) hc_ribs();
}

// two ribs hanging from the lid that the standing HC-12 PCB clips between
module hc_ribs() {
    difference() {
        union() {
            translate([hc_cx - hc_gap/2 - hc_rib_t, hc_cy - hc_len/2, lid_t - 0.5])
                cube([hc_rib_t, hc_len, hc_rib_h + 0.5]);
            translate([hc_cx + hc_gap/2, hc_cy - hc_len/2, lid_t - 0.5])
                cube([hc_rib_t, hc_len, hc_rib_h + 0.5]);
        }
        // keep the slot itself clear
        translate([hc_cx - hc_slot/2, hc_cy - hc_len/2 - 1, -1])
            cube([hc_slot, hc_len + 2, lid_t + 2]);
    }
}

// ---------- output ----------
if (mode == "box") box();
else if (mode == "lid") lid();
else if (mode == "assembled") {
    box();
    translate([0, Wo, Ho + lid_t]) rotate([180, 0, 0]) lid();
} else {
    box();
    translate([0, Wo + 15, 0]) lid();
}
