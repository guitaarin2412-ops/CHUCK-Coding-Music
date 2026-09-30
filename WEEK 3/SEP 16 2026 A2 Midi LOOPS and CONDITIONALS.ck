// Kick Drum: Uses a sine wave with a frequency drop and an envelope
fun void Kick()
{
    SinOsc K => Envelope Env => dac;
    1.0 => K.gain;
    0.015::second => Env.duration;
    1 => Env.keyOn;
    70.0 => float freq;
    680.0 => K.freq; // Initial high frequency transient
    // Pitch drop loop to simulate acoustic kick thud
    while(freq > 35.0)
    {
        freq => K.freq;
        freq - 4.0 => freq;
        0.5::ms => now;
    }
    
    35.0 => K.freq;
    0.700::second => Env.duration;
    1 => Env.keyOff; 
}

// Snare Drum: Combines triangle wave, square wave, and noise for a snappy texture
fun void Snare()
{
    TriOsc SS => Envelope Env => dac;
    SqrOsc SWS => Env => dac;
    Noise NS => Env => dac;
    0.1 => SS.gain;
    0.010 => SWS.gain;
    0.025 => NS.gain;
    0.015::second => Env.duration;
    1 => Env.keyOn;
    300.0 => float freq;
    1000.0 => SS.freq;
    1000.0 => SWS.freq;
    // Frequency sweep for the tonal body of the snare
    while(freq > 150.0)
    {
        freq => SS.freq;
        freq - 4.0 => freq;
        0.5::ms => now;
    }
    150.0 => SS.freq;
    150.0 => SWS.freq;
    0.500::second => Env.duration;
    1 => Env.keyOff; 
}

// Hi-Hat: Uses noise and a high triangle wave panned slightly to the left
fun void Hat()
{
    Noise N => Envelope Env => Pan2 p => dac;
    TriOsc SH => Env => p => dac;
    -0.3 => p.pan; // Pan slightly left
    0.005 => N.gain;
    0.0015 => SH.gain;
    0.01::second => Env.duration;
    1 => Env.keyOn;
    3000.0 => float freq;
    9000.0 => SH.freq;
    // Frequency sweep down for crisp metallic hat character
    while(freq > 1500.0)
    {
        freq => SH.freq;
        freq - 4.0 => freq;
        0.5::ms => now;
    }
    1500.0 => SH.freq;
    0.005::second => Env.duration;
    1 => Env.keyOff; 
}

// Sawtooth bass synth routed through a Low-Pass Filter (LPF) and gain stage
SqrOsc bass => LPF filter => Gain level => dac;
0.05 => level.gain;
200.0 => filter.freq; // Filter cutoff frequency
3.2 => filter.Q;      

// Array of MIDI notes for the bassline melody
[40,41,43,45,47,48,50,52] @=> int MIDIb[];

1 => int i;
while(i < 81)
{
    // Beats 2, 4, 6, 8 (0-indexed based on modulo math): Play Hat and Bass note
    if(i%8 == 2 || i%8 == 4 || i%8 == 6 || i%8 == 0)
    {
        Hat();
        Std.mtof(MIDIb[Math.random2(0,MIDIb.size()-1)]) => bass.freq; // Convert Random MIDI to frequency for the bass
        100::ms => now;
    }
    // Beats 1, 3, 7: Play Kick, Hat, and Bass note
    else if(i%8 == 1 || i%8 == 3 || i%8 == 7)
    {
        Kick();
        Hat();
        Std.mtof(MIDIb[Math.random2(0,MIDIb.size()-1)]) => bass.freq;
        100::ms => now;
    }
    // Beat 5: Play Snare, Hat, and Bass note
    else if(i%8 == 5)
    {
        Snare();
        Hat();
        Std.mtof(MIDIb[Math.random2(0,MIDIb.size()-1)]) => bass.freq;
        100::ms => now;
    }
    i++; // Increment step counter
}

