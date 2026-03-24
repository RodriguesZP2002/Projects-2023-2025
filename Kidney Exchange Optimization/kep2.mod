set V;   # vertices in the original graph
param m; # number of cycles
set C := 0..m-1;
set CYCLE{C} ordered;   # vertices in each cycle
param life {V,V};
param w {c in C} := life[last(CYCLE[c]),first(CYCLE[c])] + sum {i in 2..card(CYCLE[c])} life[member(i-1,CYCLE[c]), member(i,CYCLE[c])]; 

var x{C} binary;

maximize z: sum {c in C} w[c] * x[c];

Packing {i in V}: sum {c in C: i in CYCLE[c]} x[c] <= 1;