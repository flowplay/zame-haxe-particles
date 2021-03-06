package org.zamedev.particles.renderers;

#if (openfl >= "4.0")
#error "ERROR: Tilesheet was removed from OpenFL 4"
#end

import openfl.display.Sprite;
import openfl.display.Tilesheet;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.gl.GL;

typedef DrawTilesParticleRendererData = {
    ps : ParticleSystem,
    tilesheet : Tilesheet,
    tileData : Array<Float>,
    updated : Bool,
    textureWidth : Float
};

class DrawTilesParticleRenderer extends Sprite implements ParticleSystemRenderer {
    private static inline var TILE_DATA_FIELDS = 9; // x, y, tileId, scale, rotation, red, green, blue, alpha

    private var dataList : Array<DrawTilesParticleRendererData> = [];

    private var _ethalonSize : Float;

#if (html5 && dom)
        private var styleIsDirty = true;
    #end

    public function new() {
        super();
        mouseEnabled = false;
    }

    public function addParticleSystem(ps : ParticleSystem, ?tilesheet : Tilesheet, ?textureId : Float, ?textureWidth : Float ) : ParticleSystemRenderer {
        if (dataList.length == 0) {
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        ps.__initialize();

        if(tilesheet == null) {
            tilesheet = new Tilesheet(ps.textureBitmapData);
            tilesheet.addTileRect(
                ps.textureBitmapData.rect.clone(),
                new Point(ps.textureBitmapData.rect.width / 2, ps.textureBitmapData.rect.height / 2)
            );

        tilesheet.addTileRect(
            ps.textureBitmapData.rect.clone(),
            new Point(ps.textureBitmapData.rect.width * 0.5, ps.textureBitmapData.rect.height * 0.5)
        );

        var tileData = new Array<Float>();

        for(i in 0...ps.maxParticles) {
            var tileIdIndex = Std.int(i * TILE_DATA_FIELDS + 2);
            tileData[Std.int(i * TILE_DATA_FIELDS + TILE_DATA_FIELDS - 1)] = 0.0;
            tileData[tileIdIndex] = textureId != null ? textureId : 0.0;
        }

        dataList.push({
            ps: ps,
            tilesheet: tilesheet,
            tileData: tileData,
            updated: false,
            textureWidth: textureWidth
        });

        return this;
    }

    public function removeParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        var index = 0;

        while (index < dataList.length) {
            if (dataList[index].ps == ps) {
                dataList.splice(index, 1);
            } else {
                index++;
            }
        }

        if (dataList.length == 0) {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            graphics.clear();
        }

        return this;
    }

    private function onEnterFrame(_) : Void {
        var updated = false;

        for (data in dataList) {
            if (data.updated = data.ps.__update()) {
                updated = true;
            }
        }

        #if (html5 && dom)
            if (styleIsDirty && __style != null) {
                __style.setProperty("pointer-events", "none", null);
            } else if (!styleIsDirty && __style == null) {
                styleIsDirty = true;
            }
        #end

        if (!updated) {
            return;
        }

        graphics.clear();

        for (data in dataList) {
            if (!data.updated) {
                continue;
            }

            var ps = data.ps;
            var tileData = data.tileData;
            var index : Int = 0;

            var flags = (ps.blendFuncSource == GL.SRC_ALPHA && ps.blendFuncDestination == GL.ONE
                ? Tilesheet.TILE_BLEND_ADD
                : Tilesheet.TILE_BLEND_NORMAL
            );

            for (i in 0 ... ps.__particleCount) {
                var particle = ps.__particleList[i];
                var scale = particle.particleSize / _ethalonSize * ps.particleScaleSize; // scale
                var scaledTextureSize = (data.textureWidth / 2) * scale;

                tileData[index] = particle.position.x * ps.particleScaleX  - scaledTextureSize; // x
                tileData[index + 1] = particle.position.y * ps.particleScaleY - scaledTextureSize; // y
                //tileData[index + 2] = 0.0; // tileId
                tileData[index + 3] = scale;
                tileData[index + 4] = particle.rotation; // rotation
                tileData[index + 5] = #if webgl particle.color.b #else particle.color.r #end;
                tileData[index + 6] = particle.color.g;
                tileData[index + 7] = #if webgl particle.color.r #else particle.color.b #end;
                tileData[index + 8] = particle.color.a; // a

                index += TILE_DATA_FIELDS;
            }

            data.tilesheet.drawTiles(
                graphics,
                tileData,
                true,
                Tilesheet.TILE_SCALE | Tilesheet.TILE_ROTATION | Tilesheet.TILE_RGB | Tilesheet.TILE_ALPHA | flags,
                index
            );
        }
    }
}
