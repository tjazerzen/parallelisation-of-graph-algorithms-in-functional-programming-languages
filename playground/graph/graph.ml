#use "edge.ml"
#use "node.ml"

(* To run: #use "graph.ml";; *)

type 'a graph = {
  nodes: 'a node list;
  adjacency_list: edge list list; (*i-th element of the outer list is a list of neighbours to the i-th node*)
  lookup: ('a, int list) Hashtbl.t;  (*graph.lookup is a hash table with node's value as key and values as list of IDs to whom that value belongs*)
  is_directed: bool;  (*true, if the graph is directed; false if it isn't*)
  node_count: int;
}

(*O(1)*)
(* Helper function to create an empty graph *)
let create_empty_graph (is_directed : bool) : 'a graph = {
  nodes = [];
  adjacency_list = [];
  lookup = Hashtbl.create 16;
  is_directed;
  node_count = 0;
}

(*O(n) because of call node_count graph*)
(*Operations on Hashtables are O(1) amortized*)
(*Add node to existing graph with value content
   When adding node, an entirely new graph structure is created*)
let add_node_with_content (graph : 'a graph) (content : 'a) : 'a graph =
  (*Define new adjacency list*)
  let new_adjacency_list = [] :: graph.adjacency_list in
  (*Create new node with incremental ID and *)
  let new_node = create_node graph.node_count content in
  let new_nodes = new_node :: graph.nodes in
  let () =
    match Hashtbl.find_opt graph.lookup content with
    | Some ids -> Hashtbl.replace graph.lookup content (new_node.id :: ids)
    | None -> Hashtbl.add graph.lookup content [new_node.id]
  in
  (*Create the same graph but with updated nodes - new nodes; and updated adjacency list - new_adjacency_list *)
  { graph with nodes = new_nodes; adjacency_list = new_adjacency_list; node_count = graph.node_count + 1 }

(*O(n), due to List.map*)
  let update_node_ids (nodes : 'a node List.t) (removed_id : int) : 'a node List.t =
  List.map (
    fun node -> (if node.id > removed_id then { node with id = node.id - 1 } else node)
    ) nodes

(*O(n^2), because we iterate over the adjacency list // over the all edges*)
(*Remove the node from graph*)
let remove_node (graph : 'a graph) (node_to_remove : 'a node) : 'a graph =
  (* Check if the node_to_remove exists in the graph *)
  if not (List.exists (fun node -> node.id = node_to_remove.id) graph.nodes) then
    (* If the node doesn't exist, return the graph unmodified *)
    let () = Printf.eprintf "Warning: Node with ID %d is not present in the graph. Node will not be removed.\n" node_to_remove.id in
    graph
  else
    (* Remove the node from the nodes list *)
    let new_nodes = List.filter (fun node -> node.id <> node_to_remove.id) graph.nodes in
    (* Remove the corresponding adjacency list entry for the removed node *)
    let new_adjacency_list = List.filteri (fun i _ -> i <> node_to_remove.id) graph.adjacency_list in
    (* Update the adjacency list to remove any edges that were connected to the removed node *)
    let updated_adjacency_list =
      List.map
        (fun edges -> List.filter (fun edge -> edge.src_id <> node_to_remove.id && edge.dest_id <> node_to_remove.id) edges)
        new_adjacency_list
    in
    (* Update the node IDs in the nodes list *)
    let updated_nodes = update_node_ids new_nodes node_to_remove.id in
    (* Update the lookup hash table *)
    let () = Hashtbl.remove graph.lookup node_to_remove.value in
    {graph with nodes = updated_nodes; adjacency_list = updated_adjacency_list; node_count = graph.node_count - 1}


(*O(n), because List.exists and List.mapi both take O(n)*)
(* Connect two nodes in the graph *)
let connect_nodes (graph : 'a graph) (node1 : 'a node) (node2 : 'a node) : 'a graph =
  (* Check if either of the nodes is not present in the graph *)
  if not (List.exists (fun node -> node.id = node1.id) graph.nodes) || not (List.exists (fun node -> node.id = node2.id) graph.nodes) then
    (* If either node is not present, return the graph unmodified *)
    let () = Printf.eprintf "Warning: One or both nodes are not present in the graph. Nodes will not be connected.\n" in
    graph
  else
    let created_edge = create_edge_from_nodes node1.id node2.id graph.is_directed in
    (* Update the adjacency list to include the new edge *)
    let new_adjacency_list = List.mapi (fun i edges ->
      match (i = node1.id, i = node2.id) with
        (* If the current index is equal to node1's ID, add the edge to the list of edges *)
      | (true, _) -> created_edge :: edges
        (* If the graph is undirected and the current index is equal to node2's ID, add the edge to the list of edges *)
      | (_, true) when not graph.is_directed -> {created_edge with src_id=created_edge.dest_id; dest_id=created_edge.src_id} :: edges
        (* Otherwise *)      
      | _ -> edges
      ) graph.adjacency_list in
    { graph with adjacency_list = new_adjacency_list }

(*O(n), could be O(1) if the node list was implemented with array*)
let find_node_by_id (graph : 'a graph) (id : int) : 'a node option =
  List.find_opt (fun node -> node.id = id) graph.nodes
    
(*O(n)*)
let connect_nodes_with_id (graph : 'a graph) (node1_id : int) (node2_id : int) : 'a graph =
  match ((find_node_by_id graph node1_id), (find_node_by_id graph node2_id)) with
  | (Some node1, Some node2) -> connect_nodes graph node1 node2
  | (_, _) -> graph

(*O(n^2), because we iterate over the entire edges*)
let graph_to_string (graph : 'a graph) : string =
  (*Converts a list of edges to string*)
  let rec edges_to_string (edges: edge list) : string =
    match edges with
    | [] -> ""
    | edge :: [] -> edge_to_string edge (*edge_to_string method is implemented in edge.ml*)
    | edge :: rest -> Printf.sprintf "%s, %s" (edge_to_string edge) (edges_to_string rest)
  in
  (*Converts adjacency list to string*)
  let rec adjacency_list_to_string (idx : int) (adj_list : edge list list) : string =
    match adj_list with
    | [] -> ""
    | edges :: rest ->
      let node_string = Printf.sprintf "Node %d: %s" idx (edges_to_string edges) in
      let rest_string = adjacency_list_to_string (idx + 1) rest in
      if rest_string = "" then
        node_string
      else
        Printf.sprintf "%s\n%s" node_string rest_string
  in
  Printf.sprintf "%s %s" (adjacency_list_to_string 0 graph.adjacency_list) "\n"
