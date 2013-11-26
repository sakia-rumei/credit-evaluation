(require 'schelog)
(require 'database)
(require 'selector)
(require 'knowledgebase)
(module explainer *
	(import chicken scheme extras r5rs schelog database selector knowledgebase)
;;explainer
(define (expl:collateral-explain client)
  (display "\tThe collateral rating of this client is \[")
  (display (cadaar (query-strip (%which (rate) (%collateral_rating client rate)))))
  (display "\] because:\n")
  (display "\tThe rule for collateral rating is:\n")
  (display "\t\t excellent if:\n")
  (display "\t\t first_class >= 100% OR\n")
  (display "\t\t first_class >= 70%, first_class + second_class >= 100%\n")
  (display "\t\t good if:\n")
  (display "\t\t 60% < first_class + second_class < 70%, first_class + second_class + illiquid >=100%\n")
  (display "\t\t moderate if:\n")
  (display "\t\t first_class + second_class <= 60%, first_class + second_class + illiquid >= 100%\n")
  (display "\t\t else it's bad\n")

  (display "\tAnd the three kinds of collateral ratio of the client are:\n")
  (let* ((query (%which (first_class second_class illiquid)
                      (%collateral_profile client first_class second_class illiquid)))
         (res (query-strip query)))
    (for-each (lambda(x) (display "\t\t") (display (car x)) (display " ") (display (cadr x)) (display "%") (newline)) (car res)))
   (newline)
   
   (display "\tThe ratio of each type of collateral is calculated by the formula:\n\t100*total-collateral-amount-of-this-type/requested-credit \(%\)\n")
   (display "\tThe amount of this client's first class collateral is:\n")
   (let* ((query (%which (collateral amount)
                      (%and (%collateral collateral 'first_class)
                            (%amount collateral client amount))))
          (res (query-strip query))
          )
     (for-each (lambda(x)
                 (display "\t\t")
                 (display (cadar x))
                 (display " ")
                 (display (cadadr x))
                 (newline))
               res))

   (display "\tAnd the amount of this client's second collateral is:\n")
   (let* ((query (%which (collateral amount)
                      (%and (%collateral collateral 'second_class)
                            (%amount collateral client amount))))
          (res (query-strip query))
          )
     (for-each (lambda(x)
                 (display "\t\t")
                 (display (cadar x))
                 (display " ")
                 (display (cadadr x))
                 (newline))
               res))

   (display "\tAnd the amount of this client's illiquid collateral is:\n")
   (let* ((query (%which (collateral amount)
                      (%and (%collateral collateral 'illiquid)
                            (%amount collateral client amount))))
          (res (query-strip query))
          )
     (for-each (lambda(x)
                 (display "\t\t")
                 (display (cadar x))
                 (display " ")
                 (display (cadadr x))
                 (newline))
               res))
   (display "\tAnd the requested credit of this client is:\n")
   (let* ((query (%which (requested-credit)
                         (%requested-credit client requested-credit)))   
          (res (caar (query-strip query))))
     (display "\t\t")
     (display (car res))
     (display " ")
     (display (cadr res))
     (newline))
  (newline)
  )

 
(define (expl:financial-explain client)
  (display "\tThe financial rating of this client is \[")
  (display (cadaar (query-strip (%which (rate)
                                        (%financial_rating client rate)))))
  (display "\] because:\n")
  (display "\tFirst of all, the financial factors considered and their respective weight are:\n")
  (display "\t\tnet_worth_per_assets = 5\n\t\tlast_year_sales_growth = 1\n\t\tgross_profits_on_sales = 5\n\t\tshort_term_debt_per_annual_sales = 2\n")
  (display "\tThe financial status of this client for each factor are:\n")
  (let* ((query (%which (financial-factor value)
                        (%value financial-factor client value)))
         (res (query-strip query))
         (fun (lambda(x)
                (display "\t\t")
                (display (cadar x))
                (display " = ")
                (display (cadadr x))
                (display "%")
                (newline))))
    (for-each fun res))
  (display "\tThus, the client's financial score, which is calculated by summing together\n\tall financial factors times their respective weight, is: ")
  (let* ((res (query-strip (%which (score)
                        (%let (factors)
                              (%and (%financial_factors factors)
                                    (%score factors client 0 score))))))
         (score (cadaar res))
         (rating (cadaar (query-strip (%which (rate)
                                      (%calibrate score rate)))))
         )
    (display (caaar res))
    (display " = ")
    (display score)
    (newline)
    (display "\tThe rule for calibrating the financial rating according to the client's score is:\n")
    (display "\t\t excellent if score >= 1000\n")
    (display "\t\t good if 150 <= score < 1000\n")
    (display "\t\t medium if -500 < score < 150\n")
    (display "\t\t bad if score <= -500")

    (newline)
    (display "\tThus the financial rating of the client is indeed \[")
    (display rating)
    (display "\]")
    (newline))
  )

(define (expl:explain client)
  (call/cc (lambda(return)
             (if (not (%which() (%ok-profile client 'ok)))
                 (begin
                   (display "Credit refused because the client has problematic profile\n")
                   (return "\[refuse credit\]"))
                 (let* ((sug-ls (query-strip (%which (suggest)
                                      (%let (prof coll fin ye)
                                            (%credit client prof coll fin ye suggest)))))
                       (sug (cadaar sug-ls))

                       (coll (cadaar (query-strip (%which (coll)
                                                     (%collateral_rating client coll)))))
                       (fin (cadaar (query-strip (%which (fin)
                                                     (%financial_rating client fin)))))
                       (yie (cadaar (query-strip (%which (yie)
                                                     (%bank-yield client yie)))))
                       (+yield (cadaar (query-strip (%which (+yield)
                                                     (%bankyield client +yield)))))
                       )
                   (newline)
                   (display "------------------------------------------\n")
                   (display "The suggestion for custormer \[")
                   (display client)
                   (display "\] is \[")
                   (display sug)
                   (display "\] because:\n")
                   (display "\tThe user has ok profile\n")
                   (display "\tThe user's collateral rating is \[")
                   (display coll)
                   (display "\]\n")
                   (display "\tThe user's financial rating is \[")
                   (display fin)
                   (display "\]\n")
                   (display "\tThe user's bank yield rating is \[")
                   (display yie)
                   (display "\]\n")
                   (newline)
                   (display "------------------------------------------\n")
                   (expl:collateral-explain client)
                   (newline)
                   (expl:financial-explain client)
                   (newline)
                   (display "------------------------------------------\n")
                   (display "\tThe user \[") (display client) (display "\]'s bank yield rating is \[")
                   (display yie)
                   (display "\] because:\n")
                   (display "\t The bank yield for this user is: ")
                   (display +yield)
                   (display "%")
                   (display "\n\t And the rule to determine the bank yield rating is:\n")
                   (display "\t\t excellent if yield >= 11.8%\n")
                   (display "\t\t reasonable if 5.3% <= yield < 11.8%\n")
                   (display "\t\t poor if yield < 5.3%\n")
                   (display "------------------------------------------\n")
                   (newline)
                   (return)
                   )))))
      
)  








