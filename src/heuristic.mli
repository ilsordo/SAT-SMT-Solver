type t = Formule.formule -> Clause.literal option

type pol = Formule.formule -> Clause.variable -> bool

val polarite_next : pol

val polarite_rand : pol

val polarite_most_frequent : pol

val next : pol -> t

val rand : pol -> t

val moms : t

val dlis : t

val jewa : t

val dlcs : pol -> t





