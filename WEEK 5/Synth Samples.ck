// =================================================================
// Sample-Based House Stabs (Using SndBuf with Pitch-Shifted Rates)
// =================================================================

fun void playSampleChords(string samplePath, float bpm, string subdivision) {
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
        (60.0 / bpm) * 0.25::second => noteDuration;
    }
    
    // Define playback rate multipliers for each chord relative to Cmaj7
    // Cmaj7 = 0 semitones (1.0)
    // A7    = -3 semitones (Math.pow(2.0, -3.0/12.0))
    // D7    = +2 semitones (Math.pow(2.0,  2.0/12.0))
    // G7    = -5 semitones (Math.pow(2.0, -5.0/12.0))
    
    float chordRates[4];
    1.0                     => chordRates[0]; // Cmaj7
    Math.pow(2.0, -3.0/12.0)=> chordRates[1]; // A7  (-3 semitones)
    Math.pow(2.0,  2.0/12.0)=> chordRates[2]; // D7  (+2 semitones)
    Math.pow(2.0, -5.0/12.0)=> chordRates[3]; // G7  (-5 semitones)
    
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
            noteDuration + 30::ms => now; // Gap matching bassline
            playChordSample(samplePath, chordRates[3], noteDuration);
            noteDuration + 30::ms => now; // Gap matching bassline
        }
        else if (i%4 == 1){
            playChordSample(samplePath, chordRates[0], noteDuration);
            playChordSample(samplePath, chordRates[1], 2*noteDuration);
            playChordSample(samplePath, chordRates[2], 2*noteDuration);
            playChordSample(samplePath, chordRates[3], noteDuration);
        }      
        else {    
            playChordSample(samplePath, chordRates[0], noteDuration);
            noteDuration + 30::ms => now; // Gap matching bassline
            playChordSample(samplePath, chordRates[1], noteDuration);
            playChordSample(samplePath, chordRates[2], noteDuration);
            playChordSample(samplePath, chordRates[3], noteDuration);
            noteDuration + 30::ms => now; // Gap matching bassline
        }
        i++;    
    }
}

// Helper function to trigger the sample buffer at a specified rate
fun void playChordSample(string path, float rate, dur duration) {
    // SndBuf connected to DAC for sample playback
    SndBuf buf => dac;
    path => buf.read;
    
    // Set playhead back to the beginning
    0 => buf.pos;
    // Set pitch shift rate (changes playback speed & pitch together like a sampler)
    rate => buf.rate;
    
    // Advance time for the duration of the note + release gap
    duration + 30::ms => now;
}

// Example usage: Pass the file path to your Cmaj7 sample WAV file, BPM, and subdivision
spork ~ playSampleChords(me.dir() + "/Cmaj7.wav", 135.0, "1/8");