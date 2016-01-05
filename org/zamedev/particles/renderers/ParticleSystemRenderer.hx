package org.zamedev.particles.renderers;
import openfl.display.Tilesheet;
interface ParticleSystemRenderer {
    public function addParticleSystem(ps : ParticleSystem, ?tilesheet: Tilesheet, ?textureId : Float, ?textureWidth : Float) : ParticleSystemRenderer;
    public function removeParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer;
}
