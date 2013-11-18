;;sample data
(load "schelog.scm")
(define %bank-yield
  (%rel ()
        [('client1 'excellent)]))

(define %requested-credit
  (%rel ()
        [('client1 50000)]))

(define %amount
  (%rel ()
        [('local_currency_deposits 'client1 30000)]
        [('foreign_currency_deposits 'client1 20000)]
        [('bank_guarantees 'client1 3000)]
        [('negotiate_instruments 'client1 5000)]
        [('stocks 'client1 9000)]
        [('mortage 'client1 12000)]
        [('documents 'client1 14000)]))

(define %ok-profile
  (%rel () [('client1)]))

(define %value
  (%rel ()
         [('net_worth_per_assets 'client1 40)]
         [('last_year_sales_growth 'client1 20)]
         [('gross_profits_on_sales 'client1 45)]
         [('short_term_debt_per_annual_sales 'client1 9)]))
   

;;;;

;;(evaluate Profile Outcome)
(define (condition Type Test Rating)
  (vector 'condition Type Test Rating))

(define (profile C F Y) (vector 'profile C F Y))

;bank data and rules
(define %rule
  (%rel ()
        [( (list (condition 'collateral '>= 'excellent)
              (condition 'finances '>= 'good)
              (condition 'yield '>= 'reasonable))
           'give_credit)]
        [( (list (condition 'collateral '= 'good)
                 (condition 'finances '= 'good)
                 (condition 'yield '>= 'reasonable))
           'consult_superior)]
        [( (list (condition 'collateral '=< 'moderate)
                 (condition 'finances '=< 'medium))
           'refuse_credit)]))

(define %scale
  (%rel ()
        [('collateral (list 'excellent 'good 'moderate))]
        [('finances (list 'excellent 'good 'medium 'bad))]
        [('yield (list 'excellent 'reasonable 'poor))]))

(define %sumlist              
(letrec ((%sumlist-aux
    (%rel (x xs temp temp1 sum)
          [('() sum sum)]
          [((cons x xs) temp sum)
           (%is temp1 (+ temp x))
           (%sumlist-aux xs temp1 sum)])))
  (%rel (xs sum)
        [(xs sum) (%sumlist-aux xs 0 sum)])))
        
(define %select_value
  (%rel (C F Y)
        [('collateral (profile C F Y) C)]
        [('finances (profile C F Y) F)]
        [('yield (profile C F Y) Y)]))

(define %precedes
  (%rel (r1 r2 rs r)
        [((cons r1 rs) r1 r2)]
        [((cons r rs) r1 r2)
         (%/== r r2)
         (%precedes rs r1 r2)]))

(define %compare
  (%rel (scale rating rating1 rating2)
        [('= scale rating rating)]
        [('> scale rating1 rating2)
         (%precedes scale rating1 rating2)]
        [('>= scale rating1 rating2)
         (%or (%precedes scale rating1 rating2)
              (%== rating1 rating2))]
        [('< scale rating1 rating2)
         (%precedes scale rating2 rating1)]
        [('=< scale rating1 rating2)
         (%or (%precedes scale rating2 rating1)
              (%== rating1 rating2))]))
        
(define %verify
  (%rel (type test rating +conditions +profile fact +scale)
        [('() +profile)]
        [( (cons (condition type test rating) +conditions)
           +profile)
         (%scale type +scale)
         (%select_value type +profile fact)
         (%compare test +scale fact rating)
         (%verify +conditions +profile)]))

(define %evaluate
  (%rel (+profile answer +conditions)
        [(+profile answer)
         (%rule +conditions answer)
         (%verify +conditions +profile)]))

;; Bank data - Weighting Factors
(define %score
  (%rel (client score factor factors acc1 value acc weight)
        [('() client score score)]
        [( (cons (cons factor weight)
                 factors)
           client acc score)
         (%value factor client value)
         (%is acc1 (+ acc (* weight value)))
         (%score factors client acc1 score)]))

(define %financial_factors
  (%rel ()
        [( (list (cons 'net_worth_per_assets 5)
                 (cons 'last_year_sales_growth 1)
                 (cons 'gross_profits_on_sales 5)
                 (cons 'short_term_debt_per_annual_sales 2)))]))

(define %calibrate
  (%rel (score)
        [(score 'bad)
         (%<= score -500)]
        [(score 'medium)
         (%> score -500)
         (%< score 500)]
        [(score 'good)
         (%>= score 150)
         (%< score 1000)]
        [(score 'excellent)
         (%>= score 1000)]))

;;financial rating:
;;financial_rating(Rlient, Rating): qualitative description
;;assessing the financial record offered by Client to support
;;the request for credit

(define %financial_rating
  (%rel (client rating factors score)
        [(client rating)
         (%financial_factors factors)
         (%score factors client 0 score)
         (%calibrate score rating)]))
;;Bank data - classification of collateral

(define %collateral
  (%rel ()
        [('local_currency_deposits 'first_class)]
        [('foreign_currency_deposits 'first_class)]
        [('negotiate_instruments 'second_class)]
        [('mortage 'illiquid)]))
;;Evaluation rules

(define %collateral_evaluation
  (%rel (first_class second_class illiquid sum1 sum2)
        [(first_class second_class illiquid 'excellent)
         (%>= first_class 100)]
        [(first_class second_class illiquid 'excellent)
         (%>= first_class 70)
         (%< first_class 100)
         (%is sum1 (+ first_class second_class))
         (%>= sum1 100)]
        [(first_class second_class illiquid 'good)
         (%is sum1 (+ first_class second_class))
         (%is sum2 (+ first_class second_class illiquid))
         (%> sum1 60)
         (%< sum1 70)
         (%>= sum2 100)]

        [(first_class second_class illiquid 'medium)
         (%is sum1 (+ first_class second_class))
         (%is sum2 (+ first_class second_class illiquid))
         (%<= sum1 60)
         (%>= sum2 100)]

        [(first_class second_class illiquid 'bad)
         (%is sum1 (+ first_class second_class))
         (%is sum2 (+ first_class second_class illiquid))
         (%<= sum1 60)
         (%< sum2 100)]))


        
;;collateral rating

(define %collateral_percent
  (%rel (type client total collateral value x xs sum)
        [(type client total value)
         (%bag-of x (%and (%collateral collateral type)
                          (%amount collateral client x))
                  xs)
         (%sumlist xs sum)
         (%is value (/ (* sum 100)
                       total))]))

(define %collateral_profile
  (%rel (client first_class second_class illiquid credit)
         [(client first_class second_class illiquid)
          (%requested-credit client credit)
          (%collateral_percent 'first_class client credit first_class)
          (%collateral_percent 'second_class client credit second_class)
          (%collateral_percent 'illiquid client credit illiquid)]))

(define %collateral_rating
  (%rel (client rating first_class second_class illiquid)
        [(client rating)
         (%collateral_profile client first_class second_class illiquid)
         (%collateral_evaluation first_class second_class illiquid rating)]))
          
;;;Expert System main query
;;credit(Client, Answer/Suggestion)

(define %credit
  (%rel (client suggestion collateral-rating financial-rating +yield)
        [(client collateral-rating financial-rating +yield suggestion)
         (%ok-profile client)
         (%collateral_rating client collateral-rating)
         (%financial_rating client financial-rating)
         (%bank-yield client +yield)
         (%evaluate (profile collateral-rating financial-rating +yield)
                    suggestion)]))










