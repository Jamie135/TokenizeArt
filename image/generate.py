#!/usr/bin/env python3
"""Generate the 42Berry "Cross Coalition" NFT poster as a self-contained SVG."""
import base64, json, math, pathlib

S = pathlib.Path(__file__).parent
P = json.loads((S / "paths.json").read_text())
BB = {"order":(49.3,6.4,512.4,597.8),"alliance":(7.3,23.6,596.3,570.6),
      "assembly":(29.9,30.5,552.2,550.7),"federation":(4.2,26.5,602.6,563.5),
      "logo42":(32.0,-51.1,896.0,629.1)}

W, H = 1600, 2000
PX0, PY0, PX1, PY1 = 76, 76, 1524, 1934
CX, CY = 800, 985

TIPL, TIPR = (215, 325), (1385, 325)
ANG = math.degrees(math.atan2(1170, 1320))
SLEN = 1844

CREAM, INK, PAPER = "#F3E7CE", "#160406", "#E7DAC0"
COAL = {"order":("#8E1420","#E8404C"), "alliance":("#07684A","#22D28F"),
        "assembly":("#4A1E86","#A96BEF"), "federation":("#0D4590","#3D95EE")}
SLOTS = [("order",800,598,176), ("alliance",330,985,174),
         ("assembly",1270,985,174), ("federation",800,1385,176)]

o = []; add = o.append

def logo(name, cx, cy, box, fill, extra=""):
    bx, by, bw, bh = BB[name]
    k = box / max(bw, bh)
    return (f'<g transform="translate({cx},{cy}) scale({k:.5f}) '
            f'translate({-(bx+bw/2):.2f},{-(by+bh/2):.2f})" fill="{fill}" {extra}>'
            f'<path d="{P[name]}"/></g>')

add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
add('<title>42Berry &#8212; Cross Coalition</title>')

fb64 = base64.b64encode((S/"AlfaSlabOne-Regular.ttf").read_bytes()).decode()
add('<style type="text/css"><![CDATA[')
add("@font-face{font-family:'AlfaSlabOne';src:url(data:font/ttf;base64,%s) format('truetype');}" % fb64)
add(".disp{font-family:'AlfaSlabOne',Georgia,serif}")
add(".sans{font-family:'Ubuntu Sans','DejaVu Sans',Helvetica,Arial,sans-serif;font-weight:700}")
add(']]></style>')

# ------------------------------------------------------------------ defs
d = []; dfs = d.append
dfs('<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1">'
    '<stop offset="0" stop-color="#FCEDAE"/><stop offset=".28" stop-color="#F3C848"/>'
    '<stop offset=".54" stop-color="#D19B18"/><stop offset=".76" stop-color="#F5D264"/>'
    '<stop offset="1" stop-color="#9A6A0C"/></linearGradient>')
dfs('<linearGradient id="goldH" x1="0" y1="0" x2="1" y2="0">'
    '<stop offset="0" stop-color="#8A5C09"/><stop offset=".18" stop-color="#F0C743"/>'
    '<stop offset=".45" stop-color="#FDF0BC"/><stop offset=".7" stop-color="#E0AC28"/>'
    '<stop offset="1" stop-color="#8A5C09"/></linearGradient>')
dfs('<linearGradient id="steel" x1="0" y1="0" x2="1" y2="0">'
    '<stop offset="0" stop-color="#5B6873"/><stop offset=".16" stop-color="#98A6B1"/>'
    '<stop offset=".33" stop-color="#E8F0F5"/><stop offset=".46" stop-color="#FBFDFE"/>'
    '<stop offset=".62" stop-color="#A9B7C2"/><stop offset=".82" stop-color="#77848E"/>'
    '<stop offset=".93" stop-color="#D8E3EA"/><stop offset="1" stop-color="#F4F9FC"/>'
    '</linearGradient>')
dfs('<linearGradient id="wrap" x1="0" y1="0" x2="1" y2="0">'
    '<stop offset="0" stop-color="#12362A"/><stop offset=".4" stop-color="#2E6B52"/>'
    '<stop offset=".7" stop-color="#1B4635"/><stop offset="1" stop-color="#0C2A20"/>'
    '</linearGradient>')
dfs('<radialGradient id="panel" cx=".5" cy=".46" r=".78">'
    '<stop offset="0" stop-color="#961C26"/><stop offset=".42" stop-color="#6B111C"/>'
    '<stop offset="1" stop-color="#320610"/></radialGradient>')
dfs('<radialGradient id="paperg" cx=".5" cy=".5" r=".8">'
    '<stop offset="0" stop-color="#F0E5CE"/><stop offset="1" stop-color="#CBB894"/>'
    '</radialGradient>')
dfs('<radialGradient id="vig" cx=".5" cy=".46" r=".72">'
    '<stop offset=".45" stop-color="#000" stop-opacity="0"/>'
    '<stop offset="1" stop-color="#000" stop-opacity=".72"/></radialGradient>')
dfs('<radialGradient id="burst42" cx=".5" cy=".5" r=".5">'
    '<stop offset="0" stop-color="#FFD86B" stop-opacity=".55"/>'
    '<stop offset=".45" stop-color="#E8443A" stop-opacity=".28"/>'
    '<stop offset="1" stop-color="#E8443A" stop-opacity="0"/></radialGradient>')
for k,(dk,lt) in COAL.items():
    dfs(f'<radialGradient id="g_{k}" cx=".38" cy=".32" r=".85">'
        f'<stop offset="0" stop-color="{lt}"/><stop offset=".62" stop-color="{dk}"/>'
        f'<stop offset="1" stop-color="#150406"/></radialGradient>')
    dfs(f'<radialGradient id="h_{k}" cx=".5" cy=".5" r=".5">'
        f'<stop offset=".55" stop-color="{lt}" stop-opacity=".55"/>'
        f'<stop offset="1" stop-color="{lt}" stop-opacity="0"/></radialGradient>')
dfs('<filter id="ds" x="-40%" y="-40%" width="180%" height="180%">'
    '<feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#0A0203" flood-opacity=".7"/></filter>')
dfs('<filter id="ds2" x="-40%" y="-40%" width="180%" height="180%">'
    '<feDropShadow dx="0" dy="6" stdDeviation="8" flood-color="#0A0203" flood-opacity=".8"/></filter>')
dfs('<filter id="grain" x="0" y="0" width="100%" height="100%">'
    '<feTurbulence type="fractalNoise" baseFrequency=".9" numOctaves="4" stitchTiles="stitch"/>'
    '<feColorMatrix type="saturate" values="0"/></filter>')
dfs('<filter id="fibre" x="0" y="0" width="100%" height="100%">'
    '<feTurbulence type="fractalNoise" baseFrequency=".035 .9" numOctaves="5" stitchTiles="stitch"/>'
    '<feColorMatrix type="saturate" values="0"/></filter>')
dfs(f'<clipPath id="cpPanel"><rect x="{PX0}" y="{PY0}" width="{PX1-PX0}" height="{PY1-PY0}" rx="10"/></clipPath>')
dfs('<clipPath id="cpGrip"><rect x="-31" y="1414" width="62" height="396" rx="26"/></clipPath>')
add('<defs>' + "".join(d) + '</defs>')

# --------------------------------------------------------------- paper
add(f'<rect width="{W}" height="{H}" fill="url(#paperg)"/>')
add(f'<rect width="{W}" height="{H}" filter="url(#fibre)" opacity=".2" style="mix-blend-mode:multiply"/>')

# --------------------------------------------------------------- panel
add(f'<rect x="{PX0-14}" y="{PY0-14}" width="{PX1-PX0+28}" height="{PY1-PY0+28}" rx="6" '
    f'fill="none" stroke="#3B2A16" stroke-width="3" opacity=".55"/>')
add(f'<rect x="{PX0}" y="{PY0}" width="{PX1-PX0}" height="{PY1-PY0}" rx="10" fill="url(#panel)"/>')

add('<g clip-path="url(#cpPanel)">')
# sunburst rays from the crossing
rays = []
for i in range(48):
    a0 = i * 7.5; a1 = a0 + 3.75
    if i % 2: continue
    x0 = CX + 2900*math.cos(math.radians(a0)); y0 = CY + 2900*math.sin(math.radians(a0))
    x1 = CX + 2900*math.cos(math.radians(a1)); y1 = CY + 2900*math.sin(math.radians(a1))
    rays.append(f'M{CX},{CY} L{x0:.1f},{y0:.1f} L{x1:.1f},{y1:.1f} Z')
add(f'<path d="{" ".join(rays)}" fill="#FFD9A8" opacity=".075"/>')

# big-top valance
VY = PY0 + 24
vw = (PX1 - PX0 - 48) / 20.0
val, scall = [], [f"M{PX0+24},{VY+88}"]
for i in range(20):
    x = PX0 + 24 + i*vw
    col = CREAM if i % 2 == 0 else "#B81D2B"
    val.append(f'<path d="M{x:.1f},{VY} h{vw:.1f} v88 a{vw/2:.1f},{vw/2*0.6:.1f} 0 0 1 -{vw:.1f},0 Z" fill="{col}"/>')
    scall.append(f'a{vw/2:.1f},{vw/2*0.6:.1f} 0 0 1 -{vw:.1f},0'.replace("-", "") if False else
                 f'a{vw/2:.1f},{vw/2*0.6:.1f} 0 0 0 {vw:.1f},0')
add("".join(val))
add(f'<path d="{" ".join(scall)}" fill="none" stroke="url(#goldH)" stroke-width="7"/>')
add(f'<rect x="{PX0+24}" y="{VY}" width="{PX1-PX0-48}" height="14" fill="url(#goldH)"/>')

# gold sparkles filling the empty background
def spark(x, y, r, op):
    c = r*0.13
    d_ = (f"M{x},{y-r} C{x+c},{y-c} {x+c},{y-c} {x+r},{y} C{x+c},{y+c} {x+c},{y+c} {x},{y+r} "
          f"C{x-c},{y+c} {x-c},{y+c} {x-r},{y} C{x-c},{y-c} {x-c},{y-c} {x},{y-r} Z")
    return f'<path d="{d_}" fill="#F7D97E" opacity="{op}"/>'
SPARKS = [(168,385,22,.5),(246,489,13,.36),(150,615,17,.42),(138,857,12,.32),
          (140,1131,16,.46),(172,1273,14,.34),(302,1391,18,.4),
          (1432,385,22,.5),(1354,489,13,.36),(1450,615,17,.42),(1462,857,12,.32),
          (1460,1131,16,.46),(1428,1273,14,.34),(1298,1391,18,.4)]
add("".join(spark(*s) for s in SPARKS))

# ------------------------------------------------------- coalition glows
for k, cx, cy, R in SLOTS:
    add(f'<circle cx="{cx}" cy="{cy}" r="{R+62}" fill="url(#h_{k})" opacity=".5"/>')

# ---------------------------------------------------- coalition medallions
for k, cx, cy, R in SLOTS:
    ri = R - 26
    add(f'<g filter="url(#ds)">')
    add(f'<circle cx="{cx}" cy="{cy}" r="{R+6}" fill="{INK}"/>')
    add(f'<circle cx="{cx}" cy="{cy}" r="{R}" fill="none" stroke="url(#gold)" stroke-width="20"/>')
    add(f'<circle cx="{cx}" cy="{cy}" r="{R-11}" fill="url(#g_{k})"/>')
    add('</g>')
    add(f'<circle cx="{cx}" cy="{cy}" r="{ri}" fill="none" stroke="#F3C848" stroke-width="3" opacity=".5"/>')
    # gold rivets around the ring
    for j in range(12):
        a = math.radians(j*30 + 15)
        add(f'<circle cx="{cx+R*math.cos(a):.1f}" cy="{cy+R*math.sin(a):.1f}" r="6.5" '
            f'fill="url(#gold)" stroke="{INK}" stroke-width="1.6"/>')
    add(logo(k, cx, cy, 1.62*ri, CREAM, 'filter="url(#ds2)"'))

# ------------------------------------------------------------- the swords
def katana():
    g = []
    # blade: broad katana with a proper kissaki
    g.append('<path d="M-31,1310 L-26,112 C-26,64 -13,24 2,0 L29,96 L35,1310 Z" '
             'fill="url(#steel)" stroke="#170608" stroke-width="5" stroke-linejoin="round"/>')
    ham = ["M22,1300"]
    y = 1300
    while y > 130:
        ham.append(f"C16,{y-36} 27,{y-60} 20,{y-94}")
        y -= 94
    g.append(f'<path d="{" ".join(ham)}" fill="none" stroke="#FFFFFF" stroke-width="6" opacity=".4"/>')
    g.append('<path d="M-13,1300 L-9,140" fill="none" stroke="#3D4952" stroke-width="4" opacity=".5"/>')
    # habaki
    g.append('<rect x="-36" y="1308" width="73" height="40" rx="5" fill="url(#goldH)" '
             'stroke="#170608" stroke-width="4"/>')
    # tsuba: flared oval guard with horns
    g.append('<path d="M-104,1374 C-104,1348 -56,1336 0,1336 C56,1336 104,1348 104,1374 '
             'C104,1404 56,1418 0,1418 C-56,1418 -104,1404 -104,1374 Z" fill="url(#goldH)" '
             'stroke="#170608" stroke-width="5"/>')
    g.append('<path d="M-102,1366 C-115,1356 -117,1342 -110,1332 C-100,1341 -95,1352 -94,1362 Z" '
             'fill="url(#goldH)" stroke="#170608" stroke-width="4"/>')
    g.append('<path d="M102,1366 C115,1356 117,1342 110,1332 C100,1341 95,1352 94,1362 Z" '
             'fill="url(#goldH)" stroke="#170608" stroke-width="4"/>')
    g.append('<ellipse cx="0" cy="1377" rx="70" ry="24" fill="none" stroke="#8A5C09" '
             'stroke-width="4" opacity=".85"/>')
    # fuchi
    g.append('<rect x="-34" y="1410" width="68" height="26" rx="8" fill="url(#goldH)" '
             'stroke="#170608" stroke-width="4"/>')
    # tsuka + ito wrap
    g.append('<rect x="-31" y="1430" width="62" height="382" rx="24" fill="url(#wrap)" '
             'stroke="#170608" stroke-width="4.5"/>')
    wr = []
    for i in range(-2, 13):
        yy = 1420 + i*56
        wr.append(f'<path d="M-38,{yy} L38,{yy+62}" stroke="{CREAM}" stroke-width="13" opacity=".85"/>')
        wr.append(f'<path d="M38,{yy} L-38,{yy+62}" stroke="{CREAM}" stroke-width="13" opacity=".85"/>')
    g.append('<g clip-path="url(#cpGrip)" fill="none" stroke-linecap="round">' + "".join(wr) + '</g>')
    g.append('<rect x="-31" y="1430" width="62" height="382" rx="24" fill="none" '
             'stroke="#170608" stroke-width="4.5"/>')
    g.append('<circle cx="0" cy="1610" r="19" fill="url(#gold)" stroke="#170608" stroke-width="3.5"/>')
    # kashira
    g.append('<path d="M-34,1798 h68 v20 a34,26 0 0 1 -68,0 Z" fill="url(#goldH)" '
             'stroke="#170608" stroke-width="4.5"/>')
    return "".join(g)

K = katana()
add(f'<g filter="url(#ds)" transform="translate({TIPR[0]},{TIPR[1]}) rotate({ANG:.3f})">{K}</g>')
add(f'<g filter="url(#ds)" transform="translate({TIPL[0]},{TIPL[1]}) rotate({-ANG:.3f})">{K}</g>')

# ------------------------------------------------------------- the 42
add(f'<circle cx="{CX}" cy="{CY}" r="430" fill="url(#burst42)"/>')
L42 = 510.0
bx, by, bw, bh = BB["logo42"]
k42 = L42 / bw
add(f'<g transform="translate({CX},{CY}) scale({k42:.5f}) translate({-(bx+bw/2):.2f},{-(by+bh/2):.2f})" '
    f'filter="url(#ds)">')
add(f'<path d="{P["logo42"]}" fill="url(#gold)" stroke="{INK}" stroke-width="34" '
    f'stroke-linejoin="round" paint-order="stroke fill"/>')
add('</g>')

# ------------------------------------------------------------ the caption
add(f'<text class="disp" x="{CX}" y="1806" text-anchor="middle" font-size="54" '
    f'letter-spacing="21" fill="url(#goldH)" stroke="{INK}" stroke-width="11" '
    f'paint-order="stroke fill">CROSS COALITION</text>')

# --------------------------------------------------------------- footer
add(f'<text class="sans" x="{PX0+56}" y="1896" font-size="25" letter-spacing="6" '
    f'fill="{CREAM}" opacity=".78">ERC-721 &#183; SEPOLIA</text>')
add(f'<text class="sans" x="{PX1-56}" y="1896" text-anchor="end" font-size="25" '
    f'letter-spacing="6" fill="{CREAM}" opacity=".78">EDITION 1 / 42</text>')

# ------------------------------------------------------ vignette + grain
add(f'<rect x="{PX0}" y="{PY0}" width="{PX1-PX0}" height="{PY1-PY0}" fill="url(#vig)"/>')
add('</g>')  # /cpPanel

# gold keyline frame + corner diamonds
for ins, wdt, op in ((22, 3.5, .8), (32, 1.6, .45)):
    add(f'<rect x="{PX0+ins}" y="{PY0+ins}" width="{PX1-PX0-2*ins}" height="{PY1-PY0-2*ins}" '
        f'fill="none" stroke="#C99A2A" stroke-width="{wdt}" opacity="{op}"/>')
for qx, qy in ((PX0+22, PY0+22), (PX1-22, PY0+22), (PX0+22, PY1-22), (PX1-22, PY1-22)):
    add(f'<rect x="{qx-11}" y="{qy-11}" width="22" height="22" transform="rotate(45 {qx} {qy})" '
        f'fill="url(#gold)" stroke="{INK}" stroke-width="3"/>')

add(f'<rect x="{PX0}" y="{PY0}" width="{PX1-PX0}" height="{PY1-PY0}" rx="10" fill="none" '
    f'stroke="{INK}" stroke-width="7"/>')
add(f'<rect width="{W}" height="{H}" filter="url(#grain)" opacity=".13" '
    f'style="mix-blend-mode:overlay"/>')
add('</svg>')

(S / "42berry-cross-coalition.svg").write_text("\n".join(o))
print("svg bytes:", (S/"42berry-cross-coalition.svg").stat().st_size)
