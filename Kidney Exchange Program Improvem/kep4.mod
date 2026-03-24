set V; # vertices in the original graph
param m; # number of cycles
set C := 0..m-1;
set CYCLE{C}; # vertices in each cycle
param weights{C} integer; # weights

var x{C} binary;

maximize z: sum {c in C} weights[c] * x[c];

subject to
Packing {i in V}: sum {c in C: i in CYCLE[c]} x[c] <= 1;
