(* Initialize parameters *)
let current_fib_number = 43 in
let num_domains = 9 in
let max_num_domains = 12 in
let min_fib_number = 38 in
let max_fib_number = 45 in
let sequential_threshold = 38 in

(* Print the computation time for the 43rd Fibonacci number in a non-parallel method *)
print_endline "Printing 43-th Fibonacci number (non-parallel)...";
print_endline
  (string_of_float
     (Fib.FibonacciPerformanceAnalysis.fib_calculation_time current_fib_number));

(* Print the computation time for the 43rd Fibonacci number using parallel computation with 8 domains *)
print_endline "Printing 43-th Fibonacci number (parallel) with 8 domains...";
print_endline
  (string_of_float
     (Fib.FibonacciPerformanceAnalysis.par_fib_calculation_time ~num_domains
        ~sequential_threshold current_fib_number));

(* Print the computation times for calculating the 43rd Fibonacci number
   in a parallel manner to a CSV file with varying number of domains from 1 to 25 *)
print_endline
  "Printing parallel calculation times for 43-th Fibonacci number to csv with \
   number of domains ranging from 1 to 25... (this should take approx. 15 \
   seconds)";
Fib.FibonacciPerformanceAnalysis.par_calculation_time_num_domains_to_csv
  ~max_domains:max_num_domains ~sequential_threshold current_fib_number;

(* Print the computation times for calculating Fibonacci numbers from 38 to 45
   in a parallel manner to a CSV file with 8 domains, and sequential thresholds of 35 and 38 *)
print_endline
  "Printing parallel calculation times for Fibonacci numbers from 38 to 45 to \
   csv with 8 domains, lower seq threshold equal to 35 and upper equal to \
   38... (this should take approx. 30 seconds))";
Fib.FibonacciPerformanceAnalysis.par_calculation_time_fib_number_to_csv
  ~num_domains ~min_n:min_fib_number ~max_n:max_fib_number
