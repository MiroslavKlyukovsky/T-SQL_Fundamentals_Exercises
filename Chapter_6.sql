-- (1) Explain the difference between the UNION ALL and UNION operators.
--     In what cases are the two equivalent? When they are equivalent, which one should you use?

--     UNION ALL just adds rows without any filtration, UNION is an operator which
--     returns distinct rows after adding the first and second group of rows.

--     They are equivalent in cases when two groups of rows each has distinct rows, and those
--     rows are also distinct between the groups.

--     When they are equivalent UNION ALL should be used as it does not check for distinctness
--     and works faster because of it.
