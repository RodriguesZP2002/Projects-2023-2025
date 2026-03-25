param m integer > 0;                 # Number of surgeons
set P := {1..m};                     # Set of surgeons
set S;                               # Set of surgeries
set C within {P,P};                  # set of links to compatible physicians
set L := {i in P, j in P: (i,j) in C and (j,i) in C and i < j};

param a{(i,j) in C};                 # compatibility matrix: dots means incompatibility
param req {s in S};                  # Number of required surgeons per surgery
param comp {i in P, s in S} binary;  # Compatibility of surgeon i with surgery s

var assign {i in P, s in S} binary;  # 1 if surgeon i assigned to surgery s
var do_surgery {s in S} binary;      # 1 if surgery s is performed
var x{i in P, j in P : i < j} binary;# 1 if i,j are in a group
var weight >= 0;

# Each surgeon can only be assigned to one surgery
subject to 
OneTeamPerSurgeon {i in P}: sum {s in S} assign[i,s] <= 1;

# Only assign surgeons to surgeries they are compatible with
Compatibility {i in P, s in S}: assign[i,s] <= comp[i,s];

# A surgery can only be performed if it has enough assigned surgeons
SurgeryRequirements {s in S}: sum {i in P} assign[i,s] >= req[s] * do_surgery[s];

# Number of surgeries performed we found it was 3
TotalSurgeries: sum {s in S} do_surgery[s] = 3;

#i and j are assigned to the same surgery
Sameteam {(i,j) in L}: x[i,j] = sum {s in S} (assign[i,s] * assign[j,s]);

W: weight = sum {(i,j) in L}x[i,j]*(a[i,j] + a[j,i]);

NoIncompatiblePairs {i in P, j in P, s in S: i < j and (i,j) not in L}:
assign[i,s] + assign[j,s] <= 1;

minimize total_weight: weight;
