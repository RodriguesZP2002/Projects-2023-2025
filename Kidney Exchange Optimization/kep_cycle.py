import time
from amplpy import AMPL, Environment, DataFrame


def normalize(cycle):
    cmin = min(cycle)
    while cycle[0] != cmin:
        v = cycle.pop(0)
        cycle.append(v)


def all_cycles(cycles, path, node, tovisit, adj,K):
    for i in adj[node]:
        if i == node:
            cycle = [node]
            cycles.add(tuple(cycle))
        elif i in path:
            j = path.index(i)
            cycle = path[j:]+[node]
            normalize(cycle)
            cycles.add(tuple(cycle))

        if i in tovisit:
            if K-1 > 0:
                all_cycles(cycles,path+[node],i,tovisit-set([i]),adj,K-1)
    return cycles


def get_all_cycles(adj,K):
    tovisit = set(adj.keys())
    visited = set()
    cycles = set()
    for i in tovisit:
        tmpvisit = set(tovisit)
        tmpvisit.remove(i)
        first = i
        all_cycles(cycles,[],first,tmpvisit,adj,K)
    return cycles


def kep_cycle(adj,cycles):
    ampl = AMPL()
    ampl.option['solver'] = 'gurobi'
    ampl.read("KEP_ex4.mod")
    ampl.readData("kep2.dat")
    ampl.set['V'] = list(adj)   # vertices are keys in 'adj'
    ampl.param['m'] = len(cycles)
    for i,c in enumerate(cycles):
        ampl.set['CYCLE'][i] = list(c)
   
    ampl.solve()
    assert ampl.getValue('solve_result') == "solved"

    z = ampl.obj['z']
    x = ampl.var['x']
    sol = []
    for i,c in enumerate(cycles):
        if x[i].value() > 0.5:
            sol.append(c)
    return z.value(), sol



if __name__ == "__main__":
    edges =  [(1,9),
(2,1), (2,2), (2,4), (2,5), (2,6), (2,7), (2,8), (2,10), (2,11), (2,12), (2,13), (2,14), (2,15),
(3,1), (3,2), (3,3), (3,4), (3,5), (3,6), (3,7), (3,8), (3,9), (3,10), (3,11), (3,12), (3,13), (3,14), (3,15),
(4,2), (4,4), (4,5), (4,6), (4,7), (4,8), (4,9), (4,10), (4,11), (4,12), (4,13), (4,14), (4,15),
(5,9), (5,13),
(7,1), (7,2), (7,5), (7,6), (7,7), (7,8), (7,9), (7,10), (7,11), (7,12), (7,13), (7,14), (7,15),
(9,13),
(10,9),
(14,4), (14,8), (14,9), (14,10),
(15,4), (15,8), (15,9), (15,10),
]


    
    adj = {}
    for (i,j) in edges:
        if i in adj:
            adj[i].append(j)
        else:
            adj[i] = [j]
        
    cycles = get_all_cycles(adj,3)
    
    for c in cycles:
        print(c)
    print(len(cycles), "cycles", time.process_time(), "s")
    z, sol = kep_cycle(adj,cycles)
    print("solution:", z, sol)
        

