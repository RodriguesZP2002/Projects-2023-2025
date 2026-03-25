param m integer > 0; # number of physicians

set P := {1..m}; # set of physicians
set C within {P,P}; # set of links to compatible physicians
set S; # medical specialties to consider
param a{(i,j) in C}; # compatibility matrix: dots means incompatibility
# determine set of pairs with compatibility in both directions:
set L := {i in P, j in P: (i,j) in C and (j,i) in C and i < j};

var x {i in P, j in P : i < j} binary; # 1 if 'i' and 'j' are in the same team
var weight >= 0;

subject to
PACK {j in P}:
sum {i in P : (i,j) in L} x[i,j] + sum {k in P : (j,k) in L} x[j,k] <= 1;
INCOMPAT {i in P, j in P: i < j and (i,j) not in L}:
x[i,j] = 0;
CARD: sum {(i,j) in L} x[i,j] = 3;
W: weight = sum {(i,j) in L}x[i,j]*(a[i,j] + a[j,i]); 
Sec: x[2,5] = 0;
minimize total_weight: weight;
