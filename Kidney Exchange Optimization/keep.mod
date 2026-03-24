set V;   # vertices in the original graph
param m; # number of cycles
set C := 0..m-1;
set CYCLE{C};   # vertices in each cycle

var x{C} binary;

maximize z: sum {c in C} card(CYCLE[c]) * x[c];

Packing {i in V}: sum {c in C: i in CYCLE[c]} x[c] <= 1;