module Node : sig
  type t

  val create : int -> t
  val value : t -> int

  (* compare x y returns 0 if x is equal to y, a negative integer if x is less than y, and a positive integer if x is greater than y *)
  val compare : t -> t -> int
  val to_string : t -> string
  val id : t -> int
  val reset_ids : unit -> unit
end = struct
  type t = { id : int; value : int }

  let counter = ref 0

  let create value =
    let id = !counter in
    incr counter;
    { id; value }

  let value node = node.value
  let compare node1 node2 = Stdlib.compare node1.id node2.id

  let to_string node =
    Printf.sprintf "Node(id: %d, value: %d)" node.id node.value

  let id node = node.id
  let reset_ids () = counter := 0
end

module NodeSet = Set.Make (Node)
module NodeMap = Map.Make (Node)

module UnweightedGraph : sig
  type t (* graphs *)

  val empty : directed:bool -> t
  val add_node : Node.t -> t -> t
  val remove_node : Node.t -> t -> t
  val add_edge : Node.t -> Node.t -> t -> t
  val remove_edge : Node.t -> Node.t -> t -> t
  val nodes : t -> Node.t list
  val edges : t -> (Node.t * Node.t) list
  val to_string : t -> string
  val neighbours : Node.t -> t -> NodeSet.t
  val find_node_by_id : int -> t -> Node.t option
  val create_new_graph : num_nodes:int -> num_edges:int -> directed:bool -> t
end = struct
  type t = {
    edges : NodeSet.t NodeMap.t;
        (*edges are represented with a Map whoose keys are of type Node.t and values are NodeSet.t*)
    directed : bool;
  }

  let remove_node node graph =
    let edges =
      graph.edges |> NodeMap.remove node |> NodeMap.map (NodeSet.remove node)
    in
    { graph with edges }

  let add_edge node1 node2 graph =
    let add_directed_edge node1 node2 graph =
      let edges =
        graph.edges
        |> NodeMap.add node1
             (NodeSet.add node2 (NodeMap.find node1 graph.edges))
      in
      { graph with edges }
    in
    if graph.directed then add_directed_edge node1 node2 graph
    else add_directed_edge node1 node2 graph |> add_directed_edge node2 node1

  let remove_edge node1 node2 graph =
    let edges =
      graph.edges
      |> NodeMap.add node1
           (NodeSet.remove node2 (NodeMap.find node1 graph.edges))
    in
    let edges =
      if graph.directed then edges
      else
        edges
        |> NodeMap.add node2
             (NodeSet.remove node1 (NodeMap.find node2 graph.edges))
    in
    { graph with edges }

  let nodes graph = NodeMap.bindings graph.edges |> List.map fst
  let empty ~directed = { edges = NodeMap.empty; directed }

  let add_node node graph =
    let edges = NodeMap.add node NodeSet.empty graph.edges in
    { graph with edges }

  let to_string graph =
    let nodes =
      NodeMap.bindings graph.edges
      |> List.map fst
      |> List.map (fun node -> string_of_int (Node.value node))
      |> String.concat ", " |> Printf.sprintf "[%s]"
    in
    let edges =
      graph.edges |> NodeMap.bindings
      |> List.map (fun (node1, nodes) ->
             let nodes =
               NodeSet.elements nodes
               |> List.map (fun node -> string_of_int (Node.value node))
               |> String.concat ", "
               |> fun nodes -> "[" ^ nodes ^ "]"
             in
             "(" ^ string_of_int (Node.value node1) ^ ", " ^ nodes ^ ")")
      |> String.concat ", "
    in
    let edges = Printf.sprintf "[%s]" edges in
    Printf.sprintf "nodes: %s\nedges: %s" nodes edges

  let edges graph =
    graph.edges |> NodeMap.bindings
    |> List.map (fun (node1, nodes) ->
           NodeSet.fold (fun node2 acc -> (node1, node2) :: acc) nodes [])
    |> List.flatten

  let neighbours node graph = NodeMap.find node graph.edges

  let find_node_by_id id graph =
    let nodes = nodes graph in
    try Some (List.find (fun node -> Node.id node = id) nodes)
    with Not_found -> None

  let create_new_graph ~(num_nodes : int) ~(num_edges : int) ~(directed : bool)
      : t =
    if num_edges > num_nodes * (num_nodes - 1) / 2 then
      print_endline
        ("Number of nodes: " ^ string_of_int num_nodes ^ "\nNumber of edges: "
       ^ string_of_int num_edges ^ "\n");
    let graph = empty ~directed in
    let nodes = List.init num_nodes (fun i -> Node.create i) in
    let graph =
      List.fold_left (fun graph node -> add_node node graph) graph nodes
    in
    let rec add_edges graph num_edges =
      if num_edges = 0 then graph
      else
        let node1 = List.nth nodes (Random.int num_nodes) in
        let node2 = List.nth nodes (Random.int num_nodes) in
        if Node.compare node1 node2 <> 0 then
          let graph = add_edge node1 node2 graph in
          add_edges graph (num_edges - 1)
        else add_edges graph num_edges
    in
    let () = Node.reset_ids () in
    add_edges graph num_edges
end

module WeightedGraph : sig
  type t

  val empty : directed:bool -> t
  val add_node : Node.t -> t -> t
  val remove_node : Node.t -> t -> t
  val add_edge : Node.t -> Node.t -> float -> t -> t
  val remove_edge : Node.t -> Node.t -> t -> t
  val nodes : t -> Node.t list
  val to_string : t -> string
  val neighbours : Node.t -> t -> (Node.t * float) list
  val find_node_by_id : int -> t -> Node.t option
  val create_new_graph : num_nodes:int -> num_edges:int -> directed:bool -> t
  val edges : t -> float NodeMap.t NodeMap.t
end = struct
  type t = { edges : float NodeMap.t NodeMap.t; directed : bool }

  let empty ~directed = { edges = NodeMap.empty; directed }
  let edges graph = graph.edges

  let add_node (node : Node.t) (graph : t) : t =
    let edges = NodeMap.add node NodeMap.empty graph.edges in
    { graph with edges }

  let remove_node (node : Node.t) (graph : t) : t =
    let edges = NodeMap.remove node graph.edges in
    let edges = NodeMap.map (NodeMap.remove node) edges in
    { graph with edges }

  let add_edge (src : Node.t) (dst : Node.t) (weight : float) (graph : t) : t =
    let edges =
      NodeMap.update src
        (function
          | Some map -> Some (NodeMap.add dst weight map)
          | None -> Some (NodeMap.singleton dst weight))
        graph.edges
    in
    let edges =
      if graph.directed then edges
      else
        NodeMap.update dst
          (function
            | Some map -> Some (NodeMap.add src weight map)
            | None -> Some (NodeMap.singleton src weight))
          edges
    in
    { graph with edges }

  let remove_edge (src : Node.t) (dst : Node.t) (graph : t) : t =
    let edges =
      NodeMap.update src
        (function
          | Some map -> Some (NodeMap.remove dst map)
          | None -> assert false (* nodes should already exist in the graph *))
        graph.edges
    in
    let edges =
      if graph.directed then edges
      else
        NodeMap.update dst
          (function
            | Some map -> Some (NodeMap.remove src map)
            | None -> assert false (* nodes should already exist in the graph *))
          edges
    in
    { graph with edges }

  let nodes (graph : t) : Node.t list =
    NodeMap.bindings graph.edges |> List.map fst

  let to_string (graph : t) : string =
    let nodes_str =
      nodes graph
      |> List.map (fun node -> Node.to_string node)
      |> String.concat ", "
    in
    let edges_aux (graph : t) : (Node.t * Node.t * float) list =
      graph.edges |> NodeMap.bindings
      |> List.map (fun (node1, nodes) ->
             NodeMap.bindings nodes
             |> List.map (fun (node2, weight) -> (node1, node2, weight)))
      |> List.flatten
    in
    let edges_str =
      edges_aux graph
      |> List.map (fun (src, dst, weight) ->
             Printf.sprintf "(%s -> %s : %f)" (Node.to_string src)
               (Node.to_string dst) weight)
      |> String.concat ", "
    in
    Printf.sprintf "{ nodes: [%s]; edges: [%s] }" nodes_str edges_str

  let neighbours (node : Node.t) (graph : t) : (Node.t * float) list =
    try NodeMap.find node graph.edges |> NodeMap.bindings with Not_found -> []

  let find_node_by_id (id : int) (graph : t) : Node.t option =
    nodes graph |> List.find_opt (fun node -> Node.id node = id)

  let create_new_graph ~(num_nodes : int) ~(num_edges : int) ~(directed : bool)
      : t =
    if num_edges > num_nodes * (num_nodes - 1) / 2 then
      print_endline
        ("Number of nodes: " ^ string_of_int num_nodes ^ "\nNumber of edges: "
       ^ string_of_int num_edges ^ "\nGraph is more than full");
    let graph = empty ~directed in
    let nodes = List.init num_nodes (fun i -> Node.create i) in
    let graph =
      List.fold_left (fun graph node -> add_node node graph) graph nodes
    in
    let rec add_edges graph num_edges =
      if num_edges = 0 then graph
      else
        let node1 = List.nth nodes (Random.int num_nodes) in
        let node2 = List.nth nodes (Random.int num_nodes) in
        let edges_exist =
          try
            let _ = NodeMap.find node1 graph.edges |> NodeMap.find node2 in
            true
          with Not_found -> false
        in
        if Node.compare node1 node2 <> 0 && not edges_exist then
          let graph = add_edge node1 node2 (Random.float 10.0) graph in
          add_edges graph (num_edges - 1)
        else add_edges graph num_edges
    in
    let () = Node.reset_ids () in
    add_edges graph num_edges
end

module GraphUtils : sig
  val generate_graph_combinations :
    min_vertex:int ->
    max_vertex:int ->
    min_factor:float ->
    step:int ->
    (int * int) list
end = struct
  let generate_graph_combinations ~min_vertex ~max_vertex ~min_factor ~step =
    let rec generate_graph_combinations_helper current_vertex max_vertex
        min_factor step acc =
      if current_vertex > max_vertex then acc
      else
        let edge_count =
          current_vertex *. (current_vertex -. 1.0) *. min_factor /. 2.0
          |> int_of_float
        in
        generate_graph_combinations_helper
          (current_vertex +. float_of_int step)
          max_vertex min_factor step
          ((int_of_float current_vertex, edge_count) :: acc)
    in
    generate_graph_combinations_helper (float_of_int min_vertex)
      (float_of_int max_vertex) min_factor step []
end
