# 建筑像素贴图

使用内置 ImageGen。每个建筑生成一张三列透明图，裁成独立 PNG，保存至 `assets/pixel/buildings/`。古驿站按废弃、修复中、启用命名。

## 统一提示词

Use case: stylized-concept. Production sprite sheet for Fantasy Town, a Godot single-hex settlement game, transparent PNG. Show exactly THREE isolated game object sprites ordered left to right in one horizontal row of three equal-width cells. Each object entirely inside its cell with generous empty gutters, nothing touching dividers or outside canvas; three ground contact points lie on a shared baseline. Orthographic three-quarter view, mostly front facade with smaller visible right side, overhead angle about 35 degrees; all same orientation and consistent scale, larger tiers add structure without excessive height. Hand-drawn authentic pixel art, hard clean pixel clusters at nominal 112px sprite resolution, inspired by classic detailed 2D fantasy settlement maps. Restrained earthy umber, ochre, worn warm timber and muted cool gray stone, from upper-left daylight, sparse dark-brown outline, distinct readable silhouettes at 80-100 px. Objects sit directly on invisible ground, a few fused ground-contact resources only, no base platforms or broad ground shadows. Background actual alpha transparency, no gradient, no lettering, title, frame, guide, UI, logo, watermark or people.

## 各组提示词

### 采石场

Three levels of a stone quarry on exposed gray-green rock, based on the same open-air silhouette. Left: stone blocks, low rough wooden lifting frame and one pick. Middle: prominent timber crane arm and stone-cutting bench. Right: terraced open stone working face, larger wooden gantry and squared block stock. It must resemble a surface quarry with no mine entrance.

### 采矿场

Three levels of an iron mine on the same rocky hillside. Left: small dark timber propped adit, a little russet iron ore. Middle: roofed dark mine entrance with hand winch, short tracks. Right: reinforced mine portal with timber headframe, ore cart and orderly short rails, same small hex-tile footprint. Main visual anchor is the dark mine opening and rust-brown ore.

### 铁匠铺

Three levels of the blacksmith's forge. Left: open lean-to above an anvil and small stone furnace visibly glowing orange. Middle: half-enclosed wooden smithy, masonry forge and chimney. Right: larger medieval half-timber and stone smithy with broad chimney, orange fire and rack of metal fittings, no weapons or people. Each level reads by anvil and warm furnace.

### 驿站

Three levels of a roadside coaching inn waystation. Left: timber roadside cabin, tall fingerpost without letters, brass lantern. Middle: same main building with covered porch, adjoining tiny stable bay and low fence. Right: tidy half-timber roadside inn with courtyard gate, stable and unloading crates, all tightly grouped. The tall fingerpost and lantern persist through upgrades. No road painted underneath.

### 商店

Three levels of a permanent medieval fantasy town shop. Left: timber booth with subdued burgundy cloth awning, hanging symbol of a brass coin (no lettering) and sale crate. Middle: half-timber storefront with same burgundy awning, open window, baskets, timber sign bracket. Right: proper merchant house, larger shopfront with matching awning, small attached covered unloading porch, stacked cargo. Keep the iron forge and this shop visually distinct.

### 古驿站

Exactly three states of ONE abandoned ancient waystation. Left ruined: ivy-covered broken slate roof and broken stone arch, faded bronze lantern, rubble. Middle undergoing reconstruction: identical distinctive arch and roof position, small wooden scaffold and beams, some rubble cleared. Right restored: rebuilt roof and original pale mossy arched stone gateway, small bronze wayfinding lantern shining softly, small repaired wooden door, recovered silhouette. Should look clearly older than the ordinary wood waystation.

### 渔埠

Three levels of a lakeshore fishery building. Left: modest timber fishing lean-to, baskets and short pier. Middle: small gray-brown clapboard fishing hut with a short attached timber jetty and drying net. Right: compact fishing dock hut with covered filleting area, net rack, small hoist and slightly larger short wharf. All pilings and pier end cleanly in transparency (water plane supplied by game), no drawn water, no scenery.

### 魔理沙的魔法工房

Three levels of a witch's magical research workshop for Marisa. Left: little shingled wooden study with brass telescope aimed up and subdued blue-purple light in window. Middle: same style half-timber workshop with taller brass telescope in angled cupola, bench with magical equipment, soft blue window. Right: compact observatory workshop, brass telescope and armillary on a little turret, stone and dark timber body, warmly lit entry with lavender accents. No character, keep subtle colors for a western fantasy village.

## 现有建筑的二、三级

每组以现有一级 PNG 作为图像参照。

Use case: precise-object-edit to derive visual variants. The supplied PNG is the existing level-one asset for Fantasy Town, a western-fantasy pixel-art PC settlement game. Produce a new transparent two-column sprite sheet containing only two separated game sprites, level two on the left and level three on the right. Preserve the original's front three-quarter viewing angle, muted color palette, lighting, scale logic and hard crisp authentic pixel clusters. Center each object inside its own cell with an empty transparent gutter between them. Ground points aligned on the same baseline; each sprite complete with empty margins, ready to cut. No lettering, number, shadows floating beyond feet, additional background, hex pedestal, gradients. Both fit a single tile footprint.

### 农田

Level 2: four recognizable timber-rimmed mixed vegetable beds with denser vegetables, the recognizable scarecrow slightly taller and a low trellis. Level 3: the same productive allotment has an extra neat raised bed, a larger trellis and a small attached harvest bench with wicker baskets. Do not turn it into a villa or greenhouse.

### 牧场

Level 2: same fence and olive roof feeding shed, with small second fenced pen and distinct sheep. Level 3: sheep pasture with bigger feeding shed, second stall and carefully arranged hay, still obvious active pasture rather than a house.

### 木工作坊

Level 2: olive-roof half-timber carpentry shop with added covered workbench, distinct sawhorse and log stack. Level 3: same carpentry shop with dedicated covered woodcutting bay, tidy plank rack, slightly larger main workshop; keep wooden beams and olive roof. No glowing furnace.

### 仓库

Level 2: same timber warehouse and its big double door and crane, covered crates with one annex. Level 3: reinforced larger timber storehouse with wide double doors, recognizable roof-side loading hoist and sorted pallets under a covered bay. Keep muted olive shingles and solid brown palette.

### 树场

Level 2: same small conifer nursery with more organized sapling groups of different sizes, and an orderly cut log stack. Level 3: conifer nursery with a tiny open-sided timber tool shelter, sapling beds, and recognizable neat pile of cut logs. Maintain low silhouette and show clear open ground through transparency. No external terrain.

### 桥梁

Level 2: thicker wooden bridge deck and handrails with stone abutments. Level 3: reinforced timber bridge with heavy stone masonry supports and iron-banded rails. Absolutely preserve the same horizontal left-to-right orientation and crossing width baseline, almost frontal three-quarter elevated view, no drawn river, no roads, no vegetation or islands, only the bridge.


