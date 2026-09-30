//Program to generate an arp like pattern for 16 seconds using 4 different oscillators
SinOsc sin => dac;
TriOsc tri => dac;
SawOsc saw => dac;
SqrOsc sqr => dac;
//defining variables ^^
0 => sin.gain => tri.gain => saw.gain => sqr.gain; //<assigning gain values
768.0 => sin.freq;
670.0 => tri.freq;
440.0 => saw.freq; 
578.0 => sqr.freq;
//^^Assigning frequencies to waves
0.5 => float g;
//^^Gain Variable for loop
for(0 => int i; i<4 ; i++)//loop for repeating pattern 4 times
{
    for(0 => int j; j<4 ; j++)//loop which plays pattern
    {
        (j == 0) * (g+0.5) => sin.gain;
        (j == 1) * (g-0.2) => sqr.gain;
        (j == 2) * (g+0.4) => tri.gain;
        (j == 3) * (g-0.2) => saw.gain;
        
        //different gain levels to compliment the tonality and pitch of the waves
        1::second => now;
    }
}