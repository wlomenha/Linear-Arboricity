using DelimitedFiles, JuMP, Gurobi, Pkg, Graphs, GraphPlot, Colors, Cairo, Fontconfig


# Convert adjacency matrix to a list of edges
function adj_matrix_to_edges(A::Matrix{Int})
    n, m = size(A)
    edges = []
    for i in 1:n
        for j in i+1:m
            if A[i,j] == 1
                push!(edges, (i,j))
            end
        end
    end
    return edges
end

# Read the adjacency matrix from a text file
function read_adjacency_matrix(path::String)
    # Open the file for reading
    lines = readlines(path)
    
    # Extract values from each line and construct the adjacency matrix
    A = [parse(Int, v) for line in lines for v in split(replace(line, r"[\[\]]" => ""))]
    
    # Reshape the vector to a matrix
    n = Int(sqrt(length(A)))
    return reshape(A, n, n)
end


function linear_arboricity(A::Matrix{Int}, num_forest)
    edges = adj_matrix_to_edges(A)
    m = length(edges)
    K = 1:num_forest
    V = 1:size(A,1)
    
    model = Model(Gurobi.Optimizer)

    # Decision variables for edges (is edge e in set k?)
    @variable(model, b[e in edges, k in K])
    
    #Decision variables (flow sent by edge e to vertex u in set k)
    @variable(model , x[e in edges, k in K, u in V])
    
    #An edge belongs to exactly one set
    @constraint(model, [e in edges], sum(b[e,i] for i in K) == 1)
    
    #Each class has maximal degree 2
    @constraint(model, [i in K, v in V], sum(b[((v,u)),i] for u in V if (v,u) in edges) <= 2 )
        
    #no cycles 
    
    #In each set, each edges sends a flow of 2 if it is taken
    @constraint(model, [e in edges, i in K, v in V], x[e,i,e[1]] + x[e,i,e[2]]  <= 2*b[e,i])
    
    #Vertices receive stricktly less than 2
    @constraint(model,[k in K, v in V], sum(x[e,k,v] for e in edges) <= 2 - 2/14)
    
    optimize!(model)

    return model
end

function main(path::String, num_forest)
    A = read_adjacency_matrix(path)
    model = linear_arboricity(A,num_forest)

    for e in adj_matrix_to_edges(A)
        for k in 1:K
            if value(model[:b][e,i]) > 0.5
                println("Aresta ($(e[1]),$(e[2])) pertence a floresta ", k)
            end
        end
    end
end


path = "D:\\GitHub - Projects\\Linear Arboricity\\7_random_regular_graph.txt"
num_forest = 4

main(path,num_forest)