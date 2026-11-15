// =====================================================================
// IoT Smart Safety Device - TRANSMITTER ENCLOSURE
// Bambu printer / PLA-PETG / 0.4mm nozzle / 0.2mm layers
// Units: mm
// =====================================================================

$fn = 64;

// ---------------- GLOBAL PARAMETERS ----------------
WALL      = 3;        // enclosure wall thickness
EXT_L     = 172;       // external length (X)
EXT_W     = 112;       // external width  (Y)
CORNER_R  = 6;         // external corner fillet radius

BOTTOM_H  = 40;        // bottom shell internal depth (floor to rim top)
LID_WALL_H= 22;        // lid side-wall depth (rim to top surface)
TOP_T     = 2.6;       // top panel surface thickness
LIP_H     = 4;         // mating lip height
LIP_T     = 1.8;       // mating lip wall thickness
CLR       = 0.4;       // FDM clearance (lid lip vs bottom groove)

IN_L = EXT_L - 2*WALL; // usable internal length  = 166
IN_W = EXT_W - 2*WALL; // usable internal width   = 106

// ---------------- HELPER: rounded rectangle prism ----------------
module rrect(l, w, r) {
    hull() {
        for (x = [r, l-r])
            for (y = [r, w-r])
                translate([x, y, 0]) circle(r=r);
    }
}
module rbox(l, w, h, r) {
    linear_extrude(height=h) rrect(l, w, r);
}

// floor cradle: locates the lower edge of the standing HC-12 module so it
// can't swing side to side. Same X/Y as the lid's retaining ribs above.
module hc_floor_cradle() {
    cradle_h = 7;
    translate([HC_CENTER_X - HC_GAP/2 - HC_RIB_T, HC_Y, WALL])
        cube([HC_RIB_T, HC_STAND_W, cradle_h]);
    translate([HC_CENTER_X + HC_GAP/2, HC_Y, WALL])
        cube([HC_RIB_T, HC_STAND_W, cradle_h]);
}

module lip_gusset() {
    g = LIP_T;
    r = max(CORNER_R-WALL,1);
    difference() {
        translate([WALL-0.2, WALL-0.2, BOTTOM_H-g]) rbox(IN_L+0.4, IN_W+0.4, g+0.2, r);
        hull() {
            translate([WALL, WALL, BOTTOM_H-g-0.01]) rbox(IN_L, IN_W, 0.01, r);
            translate([WALL+g, WALL+g, BOTTOM_H]) rbox(IN_L-2*g, IN_W-2*g, 2, max(r-g,1));  // tall enough to clear the prism top
        }
    }
}

// =====================================================================
// BOTTOM SHELL
// =====================================================================
module bottom_shell() {
    difference() {
        union() {
            // outer shell
            rbox(EXT_L, EXT_W, BOTTOM_H, CORNER_R);
        }
        // hollow interior
        translate([WALL, WALL, WALL])
            rbox(IN_L, IN_W, BOTTOM_H, max(CORNER_R-WALL,1));
    }
    if (HC_STAND) translate([WALL, WALL, 0]) hc_floor_cradle();

    // 45-degree gusset under the lip so it is solidly attached to the wall
    // (without it the lip touches the wall only along an edge and prints floating)
    lip_gusset();

    // mating lip (ridge) around the inner rim, lid groove slides over this
    translate([0,0,BOTTOM_H-0.2])
    difference() {
        translate([WALL, WALL, 0])
            rbox(IN_L, IN_W, LIP_H+0.2, max(CORNER_R-WALL,1));
        translate([WALL+LIP_T, WALL+LIP_T, -1])
            rbox(IN_L-2*LIP_T, IN_W-2*LIP_T, LIP_H+2, max(CORNER_R-WALL-LIP_T,1));
    }

    // 4 small snap/friction nubs on the outer face of the lip.
    // Lid skirt inner face is CLR(0.4) outside the lip; NUB_R 0.7 gives ~0.3 mm grip.
    NUB_R = 0.7;
    nub_z = BOTTOM_H + LIP_H*0.55;
    nub_positions = [
        [WALL, EXT_W/2, nub_z],
        [EXT_L-WALL, EXT_W/2, nub_z],
        [EXT_L/2, WALL, nub_z],
        [EXT_L/2, EXT_W-WALL, nub_z]
    ];
    for (p = nub_positions)
        translate(p) sphere(r=NUB_R);
}

// =====================================================================
// USB ACCESS OPENING  (short end wall, X=0 side, aligned to ESP32)
// ESP32 is placed internally near the X=0 wall; connector faces outward.
// =====================================================================
module usb_cutout() {
    USB_W = 13;   // opening width
    USB_H = 8;    // opening height
    translate([-1, 28, WALL + 10])   // Y position lines up with ESP32 zone
        cube([WALL+2, USB_W, USB_H]);
}

module bottom_shell_final() {
    difference() {
        bottom_shell();
        usb_cutout();
    }
}

// =====================================================================
// TOP LID  (the active showcase panel)
// =====================================================================

// ---- Component cutout geometry (local XY, origin = lid inner corner) ----
// LCD  80 x 38  -> + clearance
LCD_W = 80 + 0.8;  LCD_D = 38 + 0.8;
LCD_X = (IN_L - LCD_W)/2;  LCD_Y = 6;
LCD_WIN_W = 72; LCD_WIN_D = 25;   // viewing opening only (7.2 x 2.5 cm), centred on the LCD board position

// DHT22 40 x 15
DHT_W = 40 + 0.8; DHT_D = 15 + 0.8;
// moved to the top-right corner (8 mm margin from the inner walls)
DHT_X = IN_L - 8 - DHT_W; DHT_Y = IN_W - 8 - DHT_D;
DHT_SENS_W = 20; DHT_SENS_D = 15;   // rectangular opening = DHT22 sensing grid only
DHT_SENS_DX = 14;                   // opening centre from the module's left edge (sensor end)

// MPU6050 20 x 15
MPU_W = 20 + 0.8; MPU_D = 15 + 0.8;
MPU_X = 60; MPU_Y = 55;

// HC-12 module: 30(L) x 13(W) x ~1.6mm(T, assumed PCB thickness incl. pin solder)
// MOUNTED STANDING UP: the 30mm length runs VERTICAL inside the box.
// Only the 13mm WIDTH shows on top, as a narrow slot/line - not the full
// 30x13 footprint anymore.
HC_CENTER_X = 111.4;  HC_CENTER_Y = 62.9;   // same spot as the old flat window
HC_STAND_W  = 13 + 0.8;   // visible slot length = module width + clearance
HC_SLOT_T   = 6;          // opening width in the top surface = 0.6 cm
HC_GAP      = 3.6;        // snug channel for the PCB (~1.6mm + pins + clearance), centred in the opening
HC_X = HC_CENTER_X - HC_SLOT_T/2;
HC_Y = HC_CENTER_Y - HC_STAND_W/2;
HC_RIB_T   = 2.2;    // thickness of each retaining rib beside the slot
HC_STAND = false;    // true = add the rib stand (floor cradle + lid ribs) for the HC-12
HC_STAND_H = 30;      // standing height of the module above its holder

// Gas sensor 35 x 20 (with vent holes)
GAS_W = 35 + 0.8; GAS_D = 20 + 0.8;
GAS_X = 8; GAS_Y = 80;
GAS_SENS_D  = 20;    // round opening = gas sensing element only (2 cm)
GAS_SENS_DX = 12;    // circle centre from the module's left edge (sensor end); change if your can is on the other end

// No antenna channel: the antenna is attached directly to the HC-12 module
// and stands/extends freely out of the HC-12 slot itself - no separate
// routed slot through the top panel.

CUT_Z0 = LID_WALL_H - 1;        // start cutouts just below the top surface
CUT_H  = TOP_T + 2;             // and cut fully through it

module lcd_cut()  { translate([LCD_X + (LCD_W - LCD_WIN_W)/2, LCD_Y + (LCD_D - LCD_WIN_D)/2, CUT_Z0]) cube([LCD_WIN_W, LCD_WIN_D, CUT_H]); }
module dht_cut()  { translate([DHT_X + DHT_SENS_DX - DHT_SENS_W/2, DHT_Y + DHT_D/2 - DHT_SENS_D/2, CUT_Z0]) cube([DHT_SENS_W, DHT_SENS_D, CUT_H]); }
module mpu_cut()  { translate([MPU_X, MPU_Y, CUT_Z0]) cube([MPU_W, MPU_D, CUT_H]); }
module hc_cut()   { translate([HC_X,  HC_Y,  CUT_Z0]) cube([HC_SLOT_T, HC_STAND_W, CUT_H]); }
module gas_cut()  { translate([GAS_X + GAS_SENS_DX, GAS_Y + GAS_D/2, CUT_Z0]) cylinder(d=GAS_SENS_D, h=CUT_H, $fn=64); }

// small 3mm ventilation holes flanking DHT22 and gas sensor
module vent_holes() {
    for (dy = [-6, 6])
        translate([DHT_X-6, DHT_Y+DHT_D/2+dy, CUT_Z0]) cylinder(h=CUT_H, d=3);
    for (dx = [-6, GAS_W+6])
        for (dy=[6, GAS_D-6])
            translate([GAS_X+dx, GAS_Y+dy, CUT_Z0]) cylinder(h=CUT_H, d=3);
}

// engraved label text (recessed 0.6mm so the panel prints flat, face-down)
module label(txt, x, y, size=4.2) {
    translate([x, y, LID_WALL_H+TOP_T-0.6])
        linear_extrude(height=1.2)
            text(txt, size=size, font="Liberation Sans:style=Bold", halign="left", valign="center");
}

module labels() {
    label("SMART SAFETY - TX", LCD_X, LCD_Y-3.5, 4.5);
    label("TEMP/HUM", DHT_X, DHT_Y-3.5, 3.4);
    label("MPU6050", MPU_X, MPU_Y-3.5, 3.2);
    label("HC-12", HC_X-10, HC_Y-3.5, 3.2);
    label("GAS", GAS_X, GAS_Y-3.5, 3.4);
}

// retaining ribs hanging from the lid's underside, forming a slot that the
// standing HC-12 PCB clips into (friction fit), so its top/width edge sits
// flush with the top-surface slot.
module hc_retainer_ribs() {
    rib_top = LID_WALL_H + 0.5;   // overlap slightly into the top surface
    rib_bot = LID_WALL_H - 14;    // ribs hang down ~14mm from the surface
    translate([HC_CENTER_X - HC_GAP/2 - HC_RIB_T, HC_Y, rib_bot])
        cube([HC_RIB_T, HC_STAND_W, rib_top-rib_bot]);
    translate([HC_CENTER_X + HC_GAP/2, HC_Y, rib_bot])
        cube([HC_RIB_T, HC_STAND_W, rib_top-rib_bot]);
}

module top_panel() {
    difference() {
        union() {
            // flat top surface
            translate([0,0,LID_WALL_H])
                rbox(EXT_L, EXT_W, TOP_T, CORNER_R);
            // side skirt (lid walls) going down to meet the bottom shell rim
            difference() {
                rbox(EXT_L, EXT_W, LID_WALL_H+TOP_T, CORNER_R);
                translate([WALL, WALL, -1])
                    rbox(IN_L, IN_W, LID_WALL_H+TOP_T+2, max(CORNER_R-WALL,1));
            }
            // HC-12 vertical retaining ribs (added material)
            if (HC_STAND) translate([WALL, WALL, 0]) hc_retainer_ribs();
        }
        // inner groove that receives the bottom shell's mating lip
        translate([WALL-CLR, WALL-CLR, -1])
            rbox(IN_L+2*CLR, IN_W+2*CLR, LIP_H+CLR+1, max(CORNER_R-WALL,1));

        // component cutouts, offset into the internal coordinate frame
        translate([WALL, WALL, 0]) {
            lcd_cut(); dht_cut(); mpu_cut(); hc_cut(); gas_cut();
            vent_holes();
            labels();
        }
    }
}

// =====================================================================
// LAYOUT FOR VIEWING / EXPORT
// =====================================================================
PART = "print"; // "print" (both parts, one plate) | "bottom" | "top" | "assembly"

if (PART == "bottom") bottom_shell_final();
else if (PART == "top") top_panel();
else if (PART == "assembly") {
    bottom_shell_final();
    translate([0,0,BOTTOM_H])
        color("SteelBlue", 0.9) top_panel();
} else {
    // one plate: bottom shell upright, top panel flipped (outer face on the bed)
    bottom_shell_final();
    translate([0, 2*EXT_W + 10, LID_WALL_H + TOP_T])
        rotate([180, 0, 0]) top_panel();
}
