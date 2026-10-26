// =================================================================
// Sub-Waveform FM Bassline with BPM and Note Subdivision Inputs
// =================================================================

fun void playBassline(float bpm, string subdivision) {
    // Set ChucK's global tempo (1 quarter note = 1 beat)
    // 60.0 / bpm gives the duration of 1 second per beat, or we can use standard beat scaling:
    // ChucK handles bpm via standard transport or manual duration math:
    // 1 beat = 60.0 / bpm seconds.
    
    // Calculate duration based on subdivision string
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
        // Default fallback to 1/16th if input isn't recognized
        (60.0 / bpm) * 0.25::second => noteDuration;
    }

    // 1. Define separate oscillators (Sine modulator for FM, Sawtooth carrier for grit)
    SinOsc mod => blackhole; 
    SqrOsc carrier => LPF filt => ADSR env => Gain distortion => dac;
    10 => distortion.op;
    30.0 => distortion.gain;
    
    // Patch settings for heavy sub-bass warmth
    0.01 => carrier.gain;
    5000.0 => filt.freq;  // Lowpass filter cutoff to tame harsh highs
    0.5 => filt.Q;      // Resonance peak for squelch

    // Snappy percussive envelope
    env.set(5::ms, 150::ms, 0.4, 100::ms);

    // Define note pools shifted down to C0 through C2 (MIDI 12 to 36)
    int cNotes[2]; 24 @=> cNotes[0]; 36 @=> cNotes[1]; // C0, C1, C2
    int aNotes[2]; 21 @=> aNotes[0]; 33 @=> aNotes[1]; // A-1, A0, A1
    int dNotes[2]; 26 @=> dNotes[0]; 38 @=> dNotes[1]; // D0, D1, D2
    int gNotes[2]; 19 @=> gNotes[0]; 31 @=> gNotes[1]; // G0, G1, G2
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

// Inner note player helper function
fun void playFmBassNote(SqrOsc carrier, SinOsc mod, LPF filt, ADSR env, int midiNote, dur duration) {
    Std.mtof(midiNote) => float baseFreq;
    
    // Set Carrier Frequency
    baseFreq => carrier.freq;
    
    // Set Modulator Frequency (1:2 ratio for aggressive bass timbre)
    baseFreq * 2 => mod.freq;
    
    // Trigger envelope
    1 => env.keyOn;
    
    // Run a control loop during the note duration to update FM depth & filter
    now + duration => time stopTime;
    while(now < stopTime) {
        // Dynamic modulation index scaled nicely for sub frequencies
        Std.rand2f(200,500) => float modDepth;
         
        // Modulate carrier frequency directly: Base + (Modulator_Output * Depth)
        baseFreq + (mod.last() * modDepth) => carrier.freq;
         
        0.1::ms => now; // Update rate
    }
    
    1 => env.keyOff;
    30::ms => now; // Release gap
}

// Example usage: 135 BPM playing tight 16th notes
spork ~ playBassline(135.0, "1/8");