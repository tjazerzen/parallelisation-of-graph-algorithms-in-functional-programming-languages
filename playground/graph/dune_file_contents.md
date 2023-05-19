- `fib_examples.ml`:
```
(executable
 (name fib_examples)
 (promote (until-clean))
 (libraries domainslib unix fib)
 (modules fib_examples)
 )

(library
 (name fib)
 (modules fib)
 (libraries domainslib unix)
)
```

- `graph_examples.ml`:
```
(executable
 (name graph_examples)
 (libraries unix)
 (promote
  (until-clean)))
```

- `bfs.ml`:
```
(executable
  (name bfs)
  (libraries base stdio domainslib)
  (modules bfs graph)
  (flags :standard -w "-32-70") ; If needed - suppress warnings 32 and 70
)
```

- `bfs_examples.ml`:
```
(executable
  (name bfs_examples)
  (libraries base stdio domainslib)
  (modules bfs graph bfs_examples graph_examples)
  (promote (until-clean)))
```