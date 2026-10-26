// =================================================================
// Interactive ChucK Live Performance Script (Synth, Bass, Drums)
// Controls: Press '1' for Synth, '2' for Bass, '3' for Drums
// =================================================================

// Global Tempo and Subdivision Settings
135.0 => float globalBPM;
"1/8" => string globalSubdivision;

// Track running status of each instrument to toggle them on/off
0 => int synthRunning;
0 => int bassRunning;
0 => int drumsRunning;

// Shred handles to keep track of sporked functions
Shred @ synthShred;
Shred @ bassShred;
Shred @ drumsShred;

// Initialize HID Keyboard Connection
Hid hi;
HidMsg msg;

// Try keyboard device 0 (change index if needed)
if (!hi.openKeyboard(0)) {
    cherr <= "Error: Could not open keyboard device 0!\n";
    me.exit();
}
<<< "Keyboard connected! Press keys 1, 2, and 3 to trigger/stop parts." >>>;

// Main keyboard event loop
while (true) {
    hi => now;
    while (hi.recv(msg)) {
        if (msg.isButtonDown()) {
            // Key '1' -> Synth Chords
            if (msg.ascii == '1') {
                if (synthRunning == 0) {
                    spork ~ playSampleChords(me.dir() + "/Cmaj7.wav", globalBPM, globalSubdivision) @=> synthShred;
                    1 => synthRunning;
                    <<< ">>> Synth Chords: STARTED" >>>;
                } else {
                    synthShred.exit();
                    0 => synthRunning;
                    <<< ">>> Synth Chords: STOPPED" >>>;
                }
            }
            // Key '2' -> Bassline
            else if (msg.ascii == '2') {
                if (bassRunning == 0) {
                    spork ~ playBassline(globalBPM, globalSubdivision) @=> bassShred;
                    1 => bassRunning;
                    <<< ">>> Bassline: STARTED" >>>;
                } else {
                    bassShred.exit();
                    0 => bassRunning;
                    <<< ">>> Bassline: STOPPED" >>>;
                }
            }
            // Key '3' -> Drums
            else if (msg.ascii == '3') {
                if (drumsRunning == 0) {
                    spork ~ drums(
                        me.dir() + "/Kick 909.wav",
                        me.dir() + "/Snare EDM.wav",
                        me.dir() + "/OH elec.wav",
                        me.dir() + "/CH Elec.wav",
                        me.dir() + "/Crash 909.wav",
                        me.dir() + "/FX.wav",
                        globalBPM,
                        globalSubdivision
                    ) @=> drumsShred;
                    1 => drumsRunning;
                    <<< ">>> Drums: STARTED" >>>;
                } else {
                    drumsShred.exit();
                    0 => drumsRunning;
                    <<< ">>> Drums: STOPPED" >>>;
                }
            }
        }
    }
}


// =================================================================
// 1. Sub-Waveform FM Bassline Functions
// =================================================================

fun void playBassline(float bpm, string subdivision) {
    dur noteDuration;
    if (subdivision == "1/1") {
        (60.0 / bpm) * 4.0::second => noteDuration;
    } else if (subdivision == "1/2") {
        (60.0 / bpm) * 2.0::second => noteDuration;
    } else if (subdivision == "1/4") {
        (60.0 / bpm) * 1.0::second => noteDuration;
    } else if (subdivision == "1/8") {
        (60.0 / bpm) * 0.5::second => noteDuration;
    } else if (subdivision == "1/16") {
        (60.0 / bpm) * 0.25::second => noteDuration;
    } else if (subdivision == "1/32") {
        (60.0 / bpm) * 0.125::second => noteDuration;
    } else {
        (60.0 / bpm) * 0.25::second => noteDuration;
    }

    SinOsc mod => blackhole; 
    SqrOsc carrier => LPF filt => ADSR env => Gain distortion => dac;
    10 => distortion.op;
    30.0 => distortion.gain;
    
    0.01 => carrier.gain;
    5000.0 => filt.freq;
    0.5 => filt.Q;

    env.set(5::ms, 150::ms, 0.4, 100::ms);

    int cNotes[2]; 24 @=> cNotes[0]; 36 @=> cNotes[1];
    int aNotes[2]; 21 @=> aNotes[0]; 33 @=> aNotes[1];
    int dNotes[2]; 26 @=> dNotes[0]; 38 @=> dNotes[1];
    int gNotes[2]; 19 @=> gNotes[0]; 31 @=> gNotes[1];
    int allNotePools[4][2];
    cNotes @=> allNotePools[0];
    aNotes @=> allNotePools[1];
    dNotes @=> allNotePools[2];
    gNotes @=> allNotePools[3];

    0 => int i;
    ["c", "a", "d", "g"] @=> string letters[];

    Math.random2(0, letters.size() - 1) => int randomIndex;
    
    while (true) {
        if(i%4 == 3){
            playFmBassNote(carrier, mod, filt, env, allNotePools[Std.rand2(0,3)][Std.rand2(0, cNotes.cap() - 1)], 2*noteDuration);
            playFmBassNote(carrier, mod, filt, env, allNotePools[Std.rand2(0,3)][Std.rand2(0, aNotes.cap() - 1)], noteDuration);
            playFmBassNote(carrier, mod, filt, env, allNotePools[Std.rand2(0,3)][Std.rand2(0, dNotes.cap() - 1)], noteDuration);
            playFmBassNote(carrier, mod, filt, env, allNotePools[Std.rand2(0,3)][Std.rand2(0, gNotes.cap() - 1)], 2*noteDuration);
        }
        else if (i%4 == 2){
            playFmBassNote(carrier, mod, filt, env, allNotePools[0][Std.rand2(0, cNotes.cap() - 1)], noteDuration);
            playFmBassNote(carrier, mod, filt, env, allNotePools[1][Std.rand2(0, aNotes.cap() - 1)], noteDuration);
            playFmBassNote(carrier, mod, filt, env, allNotePools[2][Std.rand2(0, dNotes.cap() - 1)], noteDuration);
            noteDuration + 30::ms => now;
            playFmBassNote(carrier, mod, filt, env, allNotePools[3][Std.rand2(0, gNotes.cap() - 1)], noteDuration);
            noteDuration + 30::ms => now;
        }
        else if (i%4 == 1){
            playFmBassNote(carrier, mod, filt, env, allNotePools[0][Std.rand2(0, cNotes.cap() - 1)], noteDuration);
            playFmBassNote(carrier, mod, filt, env, allNotePools[1][Std.rand2(0, aNotes.cap() - 1)], 2*noteDuration);
            playFmBassNote(carrier, mod, filt, env, allNotePools[2][Std.rand2(0, dNotes.cap() - 1)], 2*noteDuration);
            playFmBassNote(carrier, mod, filt, env, allNotePools[3][Std.rand2(0, gNotes.cap() - 1)], noteDuration);
        }      
        else{    
            playFmBassNote(carrier, mod, filt, env, allNotePools[0][Std.rand2(0, cNotes.cap() - 1)], noteDuration);
            noteDuration + 30::ms => now;
            playFmBassNote(carrier, mod, filt, env, allNotePools[1][Std.rand2(0, aNotes.cap() - 1)], noteDuration);
            playFmBassNote(carrier, mod, filt, env, allNotePools[2][Std.rand2(0, dNotes.cap() - 1)], noteDuration);
            playFmBassNote(carrier, mod, filt, env, allNotePools[3][Std.rand2(0, gNotes.cap() - 1)], noteDuration);
            noteDuration + 30::ms => now;
        }
        i++;    
    }
}

fun void playFmBassNote(SqrOsc carrier, SinOsc mod, LPF filt, ADSR env, int midiNote, dur duration) {
    Std.mtof(midiNote) => float baseFreq;
    baseFreq => carrier.freq;
    baseFreq * 2 => mod.freq;
    1 => env.keyOn;
    
    now + duration => time stopTime;
    while(now < stopTime) {
        Std.rand2f(200,500) => float modDepth;
        baseFreq + (mod.last() * modDepth) => carrier.freq;
        0.1::ms => now;
    }
    
    1 => env.keyOff;
    30::ms => now;
}


// =================================================================
// 2. House Drum Sequencer Functions
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

fun void step(string kp, string sp, string ohp, string chp, string cymp, string fxp, dur durVal, int idx, int b, int done) {
    0 => int cymbalPlaying;
    if (idx == 0 && (b % 2 == 1)) {
        spork ~ playPan(cymp, 0.9, 0.4); 
        1 => cymbalPlaying;
    }

    spork ~ playPan(kp, 1.0, 0.0);
    spork ~ playDoubleKick(kp, 1.0, durVal / 2.0);

    if (cymbalPlaying == 0) {
        if (idx == 0 || idx == 3) {
            spork ~ playPan(ohp, 0.9, -0.3);
        } else {
            spork ~ playPan(chp, 0.7, -0.3);
            spork ~ playDoubleHat(chp, 0.7, durVal / 2.0);
        }
    }

    if (done == 0 && (durVal > 100::ms)) {
        if (Std.rand2(0, 1) == 0) {
            spork ~ playPan(sp, 1.0, 0.0);
        } else {
            spork ~ playPan(ohp, 0.9, -0.3);
        }
    }

    if (idx == 0 && b == 3) {
        spork ~ playPan(fxp, 1.0, 0.0);
    }

    durVal => now;
}

fun void playDoubleKick(string path, float vol, dur delayTime) {
    delayTime => now;
    playPan(path, vol, 0.0);
}

fun void playDoubleHat(string path, float vol, dur delayTime) {
    delayTime => now;
    playPan(path, vol, -0.3);
}

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


// =================================================================
// 3. Sample-Based House Stabs Functions
// =================================================================

fun void playSampleChords(string samplePath, float bpm, string subdivision) {
    dur noteDuration;
    if (subdivision == "1/1") {
        (60.0 / bpm) * 4.0::second => noteDuration;
    } else if (subdivision == "1/2") {
        (60.0 / bpm) * 2.0::second => noteDuration;
    } else if (subdivision == "1/4") {
        (60.0 / bpm) * 1.0::second => noteDuration;
    } else if (subdivision == "1/8") {
        (60.0 / bpm) * 0.5::second => noteDuration;
    } else if (subdivision == "1/16") {
        (60.0 / bpm) * 0.25::second => noteDuration;
    } else if (subdivision == "1/32") {
        (60.0 / bpm) * 0.125::second => noteDuration;
    } else {
        (60.0 / bpm) * 0.25::second => noteDuration;
    }
    
    float chordRates[4];
    1.0                     => chordRates[0];
    Math.pow(2.0, -3.0/12.0)=> chordRates[1];
    Math.pow(2.0,  2.0/12.0)=> chordRates[2];
    Math.pow(2.0, -5.0/12.0)=> chordRates[3];
    
    0 => int i;
    
    while (true) {
        if(i%4 == 3){
            playChordSample(samplePath, chordRates[Std.rand2(0,3)], 2*noteDuration);
            playChordSample(samplePath, chordRates[Std.rand2(0,3)], noteDuration);
            playChordSample(samplePath, chordRates[Std.rand2(0,3)], noteDuration);
            playChordSample(samplePath, chordRates[Std.rand2(0,3)], 2*noteDuration);
        }
        else if (i%4 == 2){
            playChordSample(samplePath, chordRates[0], noteDuration);
            playChordSample(samplePath, chordRates[1], noteDuration);
            playChordSample(samplePath, chordRates[2], noteDuration);
            noteDuration + 30::ms => now;
            playChordSample(samplePath, chordRates[3], noteDuration);
            noteDuration + 30::ms => now;
        }
        else if (i%4 == 1){
            playChordSample(samplePath, chordRates[0], noteDuration);
            playChordSample(samplePath, chordRates[1], 2*noteDuration);
            playChordSample(samplePath, chordRates[2], 2*noteDuration);
            playChordSample(samplePath, chordRates[3], noteDuration);
        }      
        else {    
            playChordSample(samplePath, chordRates[0], noteDuration);
            noteDuration + 30::ms => now;
            playChordSample(samplePath, chordRates[1], noteDuration);
            playChordSample(samplePath, chordRates[2], noteDuration);
            playChordSample(samplePath, chordRates[3], noteDuration);
            noteDuration + 30::ms => now;
        }
        i++;    
    }
}

fun void playChordSample(string path, float rate, dur duration) {
    SndBuf buf => dac;
    path => buf.read;
    0 => buf.pos;
    rate => buf.rate;
    duration + 30::ms => now;
}