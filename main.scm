(require 'schelog)
(require 'database)
(require 'selector)
(require 'knowledgebase)
(require 'explainer)
(require 'querier_
(import schelog database selector knowledgebase explainer querier)
(use readline)
(current-input-port (make-gnu-readline-port))
(read-db "data")
(display "List of current customers: ")
(display %user-list)
(newline)


