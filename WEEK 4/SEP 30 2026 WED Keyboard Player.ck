// --- NOTE & FREQUENCY SETUP (Flat Notation) ---
72 => int C;
73 => int Db;
74 => int D;
75 => int Eb;
76 => int E;
77 => int F;
78 => int Gb;
79 => int G;
80 => int Ab;
81 => int A;
82 => int Bb;
83 => int B;

// --- AUDIO SETUP ---
// Drums
SndBuf kick => dac;
SndBuf snare => dac;
SndBuf hat => dac;

me.dir() + "kick1.wav" => kick.read;
me.dir() + "snare1.wav" => snare.read;
me.dir() + "hat1.wav" => hat.read;

kick.samples() => kick.pos;
snare.samples() => snare.pos;
hat.samples() => hat.pos;

// --- SYNTHS & TRUE POLYPHONIC CHORD VOICES ---

// 1. Square Wave Bass (Monophonic, snappy)
SqrOsc bass => LPF bassFilter => ADSR bassEnv => dac;
180 => bassFilter.freq;
0.5 => bass.gain;
bassEnv.set(2::ms, 15::ms, 0.7, 20::ms);

// 2. Tri + Sine High Lead (Monophonic, snappy)
TriOsc leadTri => ADSR leadEnvTri => dac;
SinOsc leadSin => ADSR leadEnvSin => dac;
0.08 => leadTri.gain;
0.06 => leadSin.gain;
leadEnvTri.set(5::ms, 20::ms, 0.6, 50::ms);
leadEnvSin.set(5::ms, 20::ms, 0.6, 50::ms);

// 3. True Polyphonic Chords: 12 independent voices (one for each pitch in the octave)
12 => int NUM_CHORD_VOICES;
SawOsc chordSaw[NUM_CHORD_VOICES];
LPF chordFilter[NUM_CHORD_VOICES];
ADSR chordEnv[NUM_CHORD_VOICES];

for (0 => int i; i < NUM_CHORD_VOICES; i++) {
    chordSaw[i] => chordFilter[i] => chordEnv[i] => dac;
    900 => chordFilter[i].freq;
    0.05 => chordSaw[i].gain;
    chordEnv[i].set(30::ms, 40::ms, 0.5, 100::ms);
}

// Instrument Selector: 0 = Bass, 1 = Lead, 2 = Chords (True Polyphonic)
0 => int activeInstrument;
[ "BASS (Square)", "LEAD (Tri + Sine)", "CHORDS (True Polyphonic Saw)" ] @=> string instrumentNames[];

// Control variables
0 => int octaveOffset;
0 => int transposeOffset;

// Track key states (0 to 127 for HID key codes)
int keyStates[128];

// Mapping arrays for the 12 melody keys
int keyCodes[12];
4  => keyCodes[0];   // A -> C
26 => keyCodes[1];   // W -> Db
22 => keyCodes[2];   // S -> D
8  => keyCodes[3];   // E -> Eb
7  => keyCodes[4];   // D -> E
9  => keyCodes[5];   // F -> F
23 => keyCodes[6];   // T -> Gb
10 => keyCodes[7];   // G -> G
28 => keyCodes[8];   // Y -> Ab
11 => keyCodes[9];   // H -> A
24 => keyCodes[10];  // U -> Bb
13 => keyCodes[11];  // J -> B

int baseMidiNotes[12];
C  => baseMidiNotes[0];
Db => baseMidiNotes[1];
D  => baseMidiNotes[2];
Eb => baseMidiNotes[3];
E  => baseMidiNotes[4];
F  => baseMidiNotes[5];
Gb => baseMidiNotes[6];
G  => baseMidiNotes[7];
Ab => baseMidiNotes[8];
A  => baseMidiNotes[9];
Bb => baseMidiNotes[10];
B  => baseMidiNotes[11];

Hid hi;
HidMsg msg;

if (!hi.openKeyboard(0)) {
    <<< "Could not open keyboard! Check macOS Input Monitoring permissions.", "" >>>;
    me.exit();
}

<<< "===================================================", "" >>>;
<<< "Macbook Keyboard Sampler & True Polyphonic Chord Synth Ready!", "" >>>;
<<< "Drums: 1=Kick, 2=Snare, 5=Hat", "" >>>;
<<< "Melody Keys: A,W,S,E,D,F,T,G,Y,H,U,J (C to B)", "" >>>;
<<< "Instrument Selector: '/' key (Current: BASS)", "" >>>;
<<< "===================================================", "" >>>;

while (true) {
    hi => now;
    
    while (hi.recv(msg)) {
        if (msg.isButtonDown()) {
            if (msg.key >= 0 && msg.key < 128) {
                1 => keyStates[msg.key];
            }
            
            // --- DRUM TRIGGERS (1, 2, 5) ---
            if (msg.ascii == 49) { 0 => kick.pos; continue; }
            else if (msg.ascii == 50) { 0 => snare.pos; continue; }
            else if (msg.ascii == 53) { 0 => hat.pos; continue; }
            
            // --- INSTRUMENT SELECTOR ('/' key -> ASCII 47) ---
            else if (msg.ascii == 47) {
                (activeInstrument + 1) % 3 => activeInstrument;
                <<< ">>> ACTIVE INSTRUMENT:", instrumentNames[activeInstrument] >>>;
                continue;
            }
            
            // --- OCTAVE & TRANSPOSE CONTROLS (Mac Arrow Keys) ---
            else if (msg.key == 82) { octaveOffset++; <<< "Octave:", octaveOffset >>>; continue; }
            else if (msg.key == 81) { octaveOffset--; <<< "Octave:", octaveOffset >>>; continue; }
            else if (msg.key == 79) { transposeOffset++; <<< "Transpose:", transposeOffset >>>; continue; }
            else if (msg.key == 80) { transposeOffset--; <<< "Transpose:", transposeOffset >>>; continue; }
        }
        else if (msg.isButtonUp()) {
            if (msg.key >= 0 && msg.key < 128) {
                0 => keyStates[msg.key];
            }
        }
    }
    
    // Scan all 12 melody keys every loop cycle
    0 => int activeCount;
    
    for (0 => int i; i < 12; i++) {
        if (keyStates[keyCodes[i]] == 1) {
            activeCount++;
            baseMidiNotes[i] + (octaveOffset * 12) + transposeOffset => int noteMidi;
            Std.mtof(noteMidi) => float freq;
            
            if (activeInstrument == 0) {
                // Bass (Monophonic playback of latest held key)
                freq => bass.freq;
                1 => bassEnv.keyOn;
            }
            else if (activeInstrument == 1) {
                // Lead (Monophonic playback)
                freq => leadTri.freq;
                freq * 1.005 => leadSin.freq;
                1 => leadEnvTri.keyOn;
                1 => leadEnvSin.keyOn;
            }
            else if (activeInstrument == 2) {
                // True Polyphonic Chords: Each pitch index gets its own dedicated saw voice
                freq => chordSaw[i].freq;
                1 => chordEnv[i].keyOn;
            }
        } else {
            // If the chord instrument is active and this key is released, trigger its release phase
            if (activeInstrument == 2) {
                1 => chordEnv[i].keyOff;
            }
        }
    }
    
    // Handle release for monophonic instruments when no keys are held
    if (activeCount == 0) {
        1 => bassEnv.keyOff;
        1 => leadEnvTri.keyOff;
        1 => leadEnvSin.keyOff;
        2::ms => now;
    } else {
        40::ms => now;
    }
}