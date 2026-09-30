// --- INITIAL SETUP ---
145.0 => float baseBPM;
baseBPM => float BPM;
30.0 / BPM => float beatSeconds;
beatSeconds::second => dur BEAT;

SndBuf kick_1   => dac;
SndBuf snare_1 => dac;
SndBuf hihat_1 => dac;
SqrOsc sqr => LPF filter => ADSR amp => Gain level => dac;
SawOsc sawBuildup => HPF sawFilter => ADSR sawAmp => Gain sawLevel => dac;
0.24 => level.gain;
200.0 => filter.freq;
3.2 => filter.Q;
1200.0 => sawFilter.freq; // Brighter cutoff for the upper octave
3.2 => filter.Q;
2.0 => sawFilter.Q;
0.1 => sawLevel.gain;
Pan2 hihat_pan => dac;
hihat_1 => hihat_pan;
-0.7 => hihat_pan.pan;

me.dir() + "kick1.wav" => kick_1.read;
me.dir() + "snare1.wav"=> snare_1.read;
me.dir() + "hat1.wav"=> hihat_1.read;

[22,24,25,27,29,30,32,34] @=> int B[];
0.9 => kick_1.gain;
0.7 => snare_1.gain;
0.3 => hihat_1.gain;

// --- BUILDUP STATE CONTROL ---
1 => int running;
1 => int snareSubdiv;  // 1, 2, 4, 8, 16...
1 => int melodySubdiv; // 1, 2, 4, 8, 16...

0 => int snareActive;
0 => int melodyActive;

// --- MAIN BEAT LOOP (Sporked) ---
fun void mainLoop()
{
    0 => int Lo;
    2 => int Hi; 
    
    while(running)
    {
        // Dynamically update BEAT duration based on BPM changes
        30.0 / BPM => beatSeconds;
        beatSeconds::second => BEAT;
        
        0 => hihat_1.pos;
        BEAT => now;        
        // Original random rhythm logic
        0 => int Random;       
        Math.random2(Lo, Hi) => Random;
        if(Random == 0 || Random == 1)
        {
            0 => hihat_1.pos;
            0 => kick_1.pos;
            
            amp.set(50::ms, 5::ms, 0.5, 500::ms);
            amp.keyOn();
            90::ms => now;
            amp.keyOff();
            90::ms => now;
            Std.mtof(B[Math.random2(0, B.size()-1)]) => sqr.freq;
            BEAT => now;
        }
        else
        {
            0 => hihat_1.pos;
            0 => snare_1.pos;
            BEAT => now;
        }
    }
}
fun void snareRollLoop()
{
    while(running)
    {
        if(snareActive)
        {
            30.0 / BPM => float curBeatSec;
            curBeatSec / snareSubdiv => float subSec;
            
            for(0 => int s; s < snareSubdiv; s++)
            {
                0 => snare_1.pos;
                subSec::second => now;
            }
        }
        else
        {
            100::ms => now; // Sleep briefly when inactive
        }
    }
}

// --- 3. INDEPENDENT ACCELERATING SAW MELODY LOOP (1 Octave Higher) ---
fun void melodyRollLoop()
{
    while(running)
    {
        if(melodyActive)
        {
            30.0 / BPM => float curBeatSec;
            curBeatSec / melodySubdiv => float subSec;
            
            for(0 => int m; m < melodySubdiv; m++)
            {
                // Pick a note from B array and shift it +12 semitones (1 octave higher)
                Std.mtof(B[Math.random2(0, B.size()-1)] + 24) => sawBuildup.freq;
                
                sawAmp.set(15::ms, 20::ms, 0.01, subSec::second / 2.0);
                sawAmp.keyOn();
                (subSec::second / 2.0) => now;
                sawAmp.keyOff();
                (subSec::second / 2.0) => now;
            }
        }
        else
        {
            100::ms => now; // Sleep briefly when inactive
        }
    }
}

// Start the music loop in the background
spork ~ mainLoop();
spork ~ snareRollLoop();
spork ~ melodyRollLoop();

Hid keyboard;
HidMsg msg;

if(!keyboard.openKeyboard(0)){
    <<<"Keyboard failed to open!">>>;
    me.exit();
}
<<< "--- BUILDUP CONTROLS READY ---" >>>;
<<< "Press '1': Double Tempo" >>>;
<<< "Press '2': Start/Accelerate Snare Roll" >>>;
<<< "Press '3': Start/Accelerate Melody Roll" >>>;
<<< "Press '4': Stop Everything" >>>;

while(running)
{
    keyboard => now;
    
    while(keyboard.recv(msg))
    {
        if(msg.isButtonDown())
        {
            // Key '1' -> Double Tempo
            if(msg.ascii == '1')
            {
                2.0 * baseBPM => BPM;
                <<< "TEMPO DOUBLED to", BPM, "BPM" >>>;
            }
            // Key '2' -> Snare Roll Trigger & Acceleration
            else if(msg.ascii == '2')
            {
                if(!snareActive)
                {
                    1 => snareActive;
                    1 => snareSubdiv;
                    <<< "SNARE ROLL STARTED: 1 hit per beat" >>>;
                }
                else
                {
                    snareSubdiv * 2 => snareSubdiv;
                    <<< "SNARE ROLL ACCELERATED:", snareSubdiv, "hits per beat" >>>;
                }
            }
            // Key '3' -> Saw Melody Trigger & Acceleration
            else if(msg.ascii == '3')
            {
                if(!melodyActive)
                {
                    1 => melodyActive;
                    1 => melodySubdiv;
                    <<< "SAW MELODY STARTED: 1 hit per beat" >>>;
                }
                else
                {
                    melodySubdiv * 2 => melodySubdiv;
                    <<< "SAW MELODY ACCELERATED:", melodySubdiv, "hits per beat" >>>;
                }
            }
            // Key '4' -> Stop Everything
            else if(msg.ascii == '4')
            {
                0 => running;
                <<< "STOPPING ALL SOUND." >>>;
            }
        }
    }
}