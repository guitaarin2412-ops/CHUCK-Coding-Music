// =================================================================
// House Drum Sequencer (Hat & Cymbal Panning Added)
// =================================================================

fun void drums(string k, string s, string oh, string ch, string cym, string fx, float bpm, string sub) {
    dur d;
    if (sub == "1/1")      (60.0 / bpm) * 4.0::second => d;
    else if (sub == "1/2") (60.0 / bpm) * 2.0::second => d;
    else if (sub == "1/4") (60.0 / bpm) * 1.0::second => d;
    else if (sub == "1/8") (60.0 / bpm) * 0.5::second => d;
    else if (sub == "1/16")(60.0 / bpm) * 0.25::second => d;
    else if (sub == "1/32")(60.0 / bpm) * 0.125::second => d;
    else                   (60.0 / bpm) * 0.5::second => d;

    0 => int bar;

    while (true) {
        0 => int hit;

        // --- BAR 3 ---
        step(k, s, oh, ch, cym, fx, 2*d, 0, bar, hit);
        1 => hit;
        step(k, s, oh, ch, cym, fx, d, 1, bar, hit);
        step(k, s, oh, ch, cym, fx, d, 2, bar, hit);
        step(k, s, oh, ch, cym, fx, 2*d, 3, bar, hit);

        // --- BAR 2 ---
        bar++;
        0 => hit;
        step(k, s, oh, ch, cym, fx, d, 0, bar, hit);
        step(k, s, oh, ch, cym, fx, d, 1, bar, hit);
        step(k, s, oh, ch, cym, fx, d, 2, bar, hit);
        step(k, s, oh, ch, cym, fx, d + 30::ms, 3, bar, 1); 
        step(k, s, oh, ch, cym, fx, d, 4, bar, hit);
        step(k, s, oh, ch, cym, fx, d + 30::ms, 5, bar, 1);

        // --- BAR 1 ---
        bar++;
        0 => hit;
        step(k, s, oh, ch, cym, fx, d, 0, bar, hit);
        step(k, s, oh, ch, cym, fx, 2*d, 1, bar, hit);
        1 => hit;
        step(k, s, oh, ch, cym, fx, 2*d, 2, bar, hit);
        step(k, s, oh, ch, cym, fx, d, 3, bar, hit);

        // --- BAR 0 ---
        bar++;
        0 => hit;
        step(k, s, oh, ch, cym, fx, d, 0, bar, hit);
        step(k, s, oh, ch, cym, fx, d + 30::ms, 1, bar, 1);
        step(k, s, oh, ch, cym, fx, d, 2, bar, hit);
        step(k, s, oh, ch, cym, fx, d, 3, bar, hit);
        step(k, s, oh, ch, cym, fx, d + 30::ms, 4, bar, 1);

        0 => bar;
    }
}

// Step handler with panning applied to hats and cymbals
fun void step(string kp, string sp, string ohp, string chp, string cymp, string fxp, dur durVal, int idx, int b, int done) {
    
    // Check if cymbal is playing on this step (panned right: 0.4)
    0 => int cymbalPlaying;
    if (idx == 0 && (b % 2 == 1)) {
        spork ~ playPan(cymp, 0.9, 0.4); 
        1 => cymbalPlaying;
    }

    // Double Kicks (centered: 0.0)
    spork ~ playPan(kp, 1.0, 0.0);
    spork ~ playDoubleKick(kp, 1.0, durVal / 2.0);

    // Hats: Open on 1 and 4, Closed on 2, 3, 5, 6 (panned left: -0.3)
    if (cymbalPlaying == 0) {
        if (idx == 0 || idx == 3) {
            spork ~ playPan(ohp, 0.9, -0.3); // Open hat left
        } else {
            spork ~ playPan(chp, 0.7, -0.3); // First closed hat left
            spork ~ playDoubleHat(chp, 0.7, durVal / 2.0); // Doubled closed hat left
        }
    }

    // Snare (centered)
    if (done == 0 && (durVal > 100::ms)) {
        if (Std.rand2(0, 1) == 0) {
            spork ~ playPan(sp, 1.0, 0.0);
        } else {
            spork ~ playPan(ohp, 0.9, -0.3);
        }
    }

    // FX sample every 4 bars on the first step (centered)
    if (idx == 0 && b == 3) {
        spork ~ playPan(fxp, 1.0, 0.0);
    }

    durVal => now;
}

// Helper for doubled kick
fun void playDoubleKick(string path, float vol, dur delayTime) {
    delayTime => now;
    playPan(path, vol, 0.0);
}

// Helper for doubled closed hat (panned left)
fun void playDoubleHat(string path, float vol, dur delayTime) {
    delayTime => now;
    playPan(path, vol, -0.3);
}

// Sample player helper with Pan2 support
fun void playPan(string path, float vol, float panVal) {
    SndBuf b => Pan2 p => dac;
    path => b.read;
    0 => b.pos;
    vol => b.gain;
    panVal => p.pan;
    
    while(b.pos() < b.samples()) {
        1::ms => now;
    }
}

// Run the drum function using local sample paths via me.dir()
drums(
    me.dir() + "/Kick 909.wav",
    me.dir() + "/Snare EDM.wav",
    me.dir() + "/OH elec.wav",
    me.dir() + "/CH Elec.wav",
    me.dir() + "/Crash 909.wav",
    me.dir() + "/FX.wav",
    135.0,
    "1/8"
);