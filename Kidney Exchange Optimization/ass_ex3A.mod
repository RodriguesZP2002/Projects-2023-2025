param m integer > 0;                         # Number of surgeons
set P := {1..m};                       # Set of surgeons
set S;                               # Set of surgeries

param req {s in S};                  # Number of required surgeons per surgery
param comp {i in P, s in S} binary;  # Compatibility of surgeon i with surgery s

var assign {i in P, s in S} binary;  # 1 if surgeon i assigned to surgery s
var do_surgery {s in S} binary;      # 1 if surgery s is performed

# Each surgeon can only be assigned to one surgery
subject to 
OneTeamPerSurgeon {i in P}: sum {s in S} assign[i,s] <= 1;

# Only assign surgeons to surgeries they are compatible with
Compatibility {i in P, s in S}: assign[i,s] <= comp[i,s];

# A surgery can only be performed if it has enough assigned surgeons
SurgeryRequirements {s in S}: sum {i in P} assign[i,s] >= req[s] * do_surgery[s];

# Maximize number of surgeries performed
maximize TotalSurgeries: sum {s in S} do_surgery[s];
